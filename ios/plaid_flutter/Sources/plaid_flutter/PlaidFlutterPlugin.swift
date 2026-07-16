import Flutter
import LinkKit
import UIKit

protocol PlaidEventEmitter: AnyObject {
  func sendEvent(_ arguments: Any?)
}

private enum PlaidSessionType: String {
  case standard
  case layer
  case headless
}

private enum PlaidSession {
  case standard(PlaidLinkSession)
  case layer(PlaidLayerSession)
  case headless(any PlaidHeadlessSession)
}

private struct LayerSubmissionData: SubmissionData {
  let phoneNumber: String?
  let dateOfBirth: String?
  let params: [String: String]?
}

public final class PlaidFlutterPlugin: NSObject, FlutterPlugin, FlutterStreamHandler,
  PlaidEventEmitter
{
  private enum Channel {
    static let method = "plugins.flutter.io/plaid_flutter"
    static let event = "plugins.flutter.io/plaid_flutter/events"
    static let embeddedView = "plaid/embedded-view"
  }

  private enum EventType {
    static let success = "success"
    static let exit = "exit"
    static let event = "event"
    static let onLoad = "onload"
  }

  private var eventSink: FlutterEventSink?
  private var session: PlaidSession?
  private var sessionType: PlaidSessionType?
  private var sessionCreationError: Error?
  private var sessionIsReady = false
  private var pendingCreateResult: FlutterResult?
  private var sessionGeneration = 0
  private weak var presentedViewController: UIViewController?
  private var presentedSessionGeneration: Int?
  private var dismissingSessionGenerations: Set<Int> = []
  private var receivedHandoff = false
  private weak var flutterViewController: UIViewController?

  private init(viewController: UIViewController?) {
    flutterViewController = viewController
    super.init()
  }

  @objc public static func sdkVersion() -> String {
    "6.0.0"
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(
      name: Channel.method,
      binaryMessenger: registrar.messenger()
    )
    let eventChannel = FlutterEventChannel(
      name: Channel.event,
      binaryMessenger: registrar.messenger()
    )

    let instance = PlaidFlutterPlugin(viewController: registrar.viewController)
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
    registrar.register(
      PlaidEmbeddedViewFactory(emitter: instance),
      withId: Channel.embeddedView
    )
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "create":
      create(arguments: call.arguments, result: result)
    case "open":
      open(result: result)
    case "close":
      close(result: result)
    case "submit":
      submit(arguments: call.arguments, result: result)
    case "syncFinanceKit":
      syncFinanceKit(arguments: call.arguments, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  public func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    return nil
  }

  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  func sendEvent(_ arguments: Any?) {
    onMain { [weak self] in
      self?.eventSink?(arguments)
    }
  }

  private func create(arguments: Any?, result: @escaping FlutterResult) {
    guard let arguments = arguments as? [String: Any],
      let token = arguments["token"] as? String,
      !token.isEmpty
    else {
      result(
        FlutterError(
          code: "INVALID_TOKEN",
          message: "A non-empty link token is required.",
          details: nil
        )
      )
      return
    }

    let rawSessionType = arguments["sessionType"] as? String ?? PlaidSessionType.standard.rawValue
    guard let requestedSessionType = PlaidSessionType(rawValue: rawSessionType) else {
      result(
        FlutterError(
          code: "INVALID_SESSION_TYPE",
          message: "Unsupported Plaid Link session type: \(rawSessionType).",
          details: nil
        )
      )
      return
    }

    sessionGeneration &+= 1
    let generation = sessionGeneration
    resetSessionForCreate()
    sessionType = requestedSessionType
    pendingCreateResult = result

    let onSuccess: OnSuccessHandler = { [weak self] success in
      self?.handleSuccess(success, generation: generation)
    }
    let onExit: OnExitHandler = { [weak self] exit in
      self?.handleExit(exit, generation: generation)
    }
    let onEvent: OnEventHandler = { [weak self] event in
      self?.handleEvent(event, generation: generation)
    }
    let onLoad: OnLoadHandler = { [weak self] in
      self?.sessionDidBecomeReady(generation: generation)
    }

    do {
      switch requestedSessionType {
      case .standard:
        let configuration = LinkTokenConfiguration(
          token: token,
          onSuccess: onSuccess,
          onExit: onExit,
          onEvent: onEvent,
          onLoad: onLoad
        )
        let linkSession = try Plaid.createPlaidLinkSession(
          configuration: configuration
        )
        linkSession.showGradientBackground =
          arguments["showGradientBackground"] as? Bool ?? false
        if generation == sessionGeneration, sessionType == .standard {
          session = .standard(linkSession)
        }
      case .layer:
        let configuration = LayerTokenConfiguration(
          token: token,
          onSuccess: onSuccess,
          onExit: onExit,
          onEvent: onEvent
        )
        let layerSession = try Plaid.createPlaidLayerSession(configuration: configuration)
        if generation == sessionGeneration, sessionType == .layer {
          session = .layer(layerSession)
          // Layer can accept Extended Autofill submissions before it becomes
          // ready to present, so return the session to Dart immediately. The
          // LAYER_READY event separately controls whether open() is allowed.
          finishCreate(with: nil)
        }
      case .headless:
        let configuration = LinkTokenConfiguration(
          token: token,
          onSuccess: onSuccess,
          onExit: onExit,
          onEvent: onEvent,
          onLoad: onLoad
        )
        let headlessSession = try Plaid.createHeadlessSession(configuration: configuration)
        if generation == sessionGeneration, sessionType == .headless {
          session = .headless(headlessSession)
        }
      }
    } catch {
      sessionCreationError = error
      session = nil
      sessionType = nil
      finishCreate(with: flutterError(from: error, fallbackCode: "SESSION_CREATE_ERROR"))
    }
  }

  private func open(result: @escaping FlutterResult) {
    guard let session else {
      let error = missingSessionFlutterError()
      sendEvent(creationFailureEvent(from: error))
      result(error)
      return
    }

    guard sessionIsReady else {
      result(
        FlutterError(
          code: "SESSION_NOT_READY",
          message:
            "The Plaid Link session is still loading. Await PlaidLink.create() before opening it.",
          details: nil
        )
      )
      return
    }

    switch session {
    case .headless(let headlessSession):
      headlessSession.start()
      result(nil)
    case .standard(let linkSession):
      present(linkSession: linkSession, result: result)
    case .layer(let layerSession):
      present(layerSession: layerSession, result: result)
    }
  }

  private func present(linkSession: PlaidLinkSession, result: @escaping FlutterResult) {
    guard let presentingViewController = plaidPresentingViewController else {
      result(noViewControllerFlutterError())
      return
    }

    linkSession.open(
      using: presentationMethod(
        from: presentingViewController,
        generation: sessionGeneration
      )
    )
    result(nil)
  }

  private func present(layerSession: PlaidLayerSession, result: @escaping FlutterResult) {
    guard let presentingViewController = plaidPresentingViewController else {
      result(noViewControllerFlutterError())
      return
    }

    layerSession.open(
      using: presentationMethod(
        from: presentingViewController,
        generation: sessionGeneration
      )
    )
    result(nil)
  }

  private func presentationMethod(
    from presentingViewController: UIViewController,
    generation: Int
  )
    -> PresentationMethod
  {
    .custom(
      { [weak self, weak presentingViewController] linkViewController in
        guard let self,
          generation == sessionGeneration,
          let presentingViewController
        else { return }
        presentedViewController = linkViewController
        presentedSessionGeneration = generation
        presentingViewController.present(linkViewController, animated: true)
      },
      { [weak self] linkViewController in
        self?.dismiss(
          viewController: linkViewController,
          generation: generation
        )
      }
    )
  }

  private func close(result: @escaping FlutterResult) {
    dismissPresentedViewController {
      result(nil)
    }
  }

  private func submit(arguments: Any?, result: @escaping FlutterResult) {
    guard case .layer(let layerSession) = session else {
      result(
        FlutterError(
          code: "PLAID_NO_LAYER_SESSION",
          message: "Create a Layer session before submitting Layer data.",
          details: nil
        )
      )
      return
    }

    let arguments = arguments as? [String: Any] ?? [:]
    let params = (arguments["params"] as? [AnyHashable: Any])?.reduce(
      into: [String: String](),
      { result, entry in
        if let key = entry.key as? String,
          let value = entry.value as? String
        {
          result[key] = value
        }
      }
    )
    let submissionData = LayerSubmissionData(
      phoneNumber: arguments["phoneNumber"] as? String,
      dateOfBirth: arguments["dateOfBirth"] as? String,
      params: params
    )

    layerSession.submit(data: submissionData)
    result(nil)
  }

  private func syncFinanceKit(arguments: Any?, result: @escaping FlutterResult) {
    guard let arguments = arguments as? [String: Any],
      let token = arguments["token"] as? String,
      !token.isEmpty
    else {
      result(
        FlutterError(
          code: "INVALID_TOKEN",
          message: "A non-empty link token is required.",
          details: nil
        )
      )
      return
    }

    guard #available(iOS 17.4, *) else {
      result(
        FlutterError(
          code: "UNSUPPORTED_IOS_VERSION",
          message: "FinanceKit requires iOS 17.4 or later.",
          details: nil
        )
      )
      return
    }

    let requestAuthorizationIfNeeded =
      arguments["requestAuthorizationIfNeeded"] as? Bool ?? false
    let simulatedBehavior = arguments["simulatedBehavior"] as? Bool ?? false
    let syncBehavior: PlaidFinanceKit.SyncBehavior =
      simulatedBehavior ? .simulated : .live

    PlaidFinanceKit.sync(
      token: token,
      requestAuthorizationIfNeeded: requestAuthorizationIfNeeded,
      syncBehavior: syncBehavior
    ) { syncResult in
      onMain {
        switch syncResult {
        case .success:
          result(nil)
        case .failure(let error):
          result(
            FlutterError(
              code: error.plaidFlutterErrorCode,
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }
    }
  }

  private func handleSuccess(_ success: LinkSuccess, generation: Int) {
    onMain { [weak self] in
      guard let self, generation == sessionGeneration else { return }
      var payload = success.plaidDictionary
      payload["type"] = EventType.success
      dismissPresentedViewController()
      sendEvent(payload)

      if sessionType != .standard {
        session = nil
        sessionType = nil
        sessionIsReady = false
      }
    }
  }

  private func handleExit(_ exit: LinkExit, generation: Int) {
    onMain { [weak self] in
      guard let self, generation == sessionGeneration else { return }
      var payload = exit.plaidDictionary
      payload["type"] = EventType.exit
      dismissPresentedViewController()
      sendEvent(payload)

      if pendingCreateResult != nil {
        let error =
          exit.error.map {
            FlutterError(
              code: $0.errorCode.plaidErrorCode,
              message: $0.errorMessage,
              details: $0.plaidDictionary
            )
          }
          ?? FlutterError(
            code: "SESSION_EXITED_BEFORE_READY",
            message: "The Plaid Link session exited before it became ready.",
            details: nil
          )
        finishCreate(with: error)
      }

      session = nil
      sessionType = nil
      sessionIsReady = false
    }
  }

  private func handleEvent(_ event: LinkEvent, generation: Int) {
    onMain { [weak self] in
      guard let self, generation == sessionGeneration else { return }
      var payload = event.plaidDictionary
      payload["type"] = EventType.event
      sendEvent(payload)

      if sessionType == .layer, event.eventName == .layerReady {
        sessionDidBecomeReady(generation: generation)
      }

      if sessionType == .standard, event.eventName == .handoff {
        receivedHandoff = true
        releaseStandardSessionIfFinishedPresenting(generation: generation)
      }
    }
  }

  private func sessionDidBecomeReady(generation: Int) {
    onMain { [weak self] in
      guard let self,
        generation == sessionGeneration,
        !sessionIsReady
      else { return }
      sessionIsReady = true
      sendEvent(["type": EventType.onLoad])
      finishCreate(with: nil)
    }
  }

  private func finishCreate(with value: Any?) {
    guard let result = pendingCreateResult else { return }
    pendingCreateResult = nil
    result(value)
  }

  private func dismissPresentedViewController(completion: (() -> Void)? = nil) {
    guard let presentedViewController,
      let generation = presentedSessionGeneration
    else {
      presentedSessionGeneration = nil
      completion?()
      releaseStandardSessionIfFinishedPresenting(generation: sessionGeneration)
      return
    }

    dismiss(
      viewController: presentedViewController,
      generation: generation,
      completion: completion
    )
  }

  private func dismiss(
    viewController: UIViewController,
    generation: Int,
    completion: (() -> Void)? = nil
  ) {
    guard presentedViewController === viewController,
      presentedSessionGeneration == generation
    else {
      completion?()
      return
    }

    presentedViewController = nil
    presentedSessionGeneration = nil
    dismissingSessionGenerations.insert(generation)

    let didDismiss = { [weak self] in
      guard let self else {
        completion?()
        return
      }
      dismissingSessionGenerations.remove(generation)
      releaseStandardSessionIfFinishedPresenting(generation: generation)
      completion?()
    }

    if let presentingViewController = viewController.presentingViewController {
      presentingViewController.dismiss(animated: true, completion: didDismiss)
    } else {
      didDismiss()
    }
  }

  private func releaseStandardSessionIfFinishedPresenting(generation: Int) {
    guard generation == sessionGeneration,
      receivedHandoff,
      presentedViewController == nil,
      !dismissingSessionGenerations.contains(generation)
    else { return }
    session = nil
    sessionType = nil
    sessionIsReady = false
    receivedHandoff = false
  }

  private func resetSessionForCreate() {
    if pendingCreateResult != nil {
      finishCreate(
        with: FlutterError(
          code: "SESSION_REPLACED",
          message: "The pending Plaid Link session was replaced by a new create call.",
          details: nil
        )
      )
    }
    dismissPresentedViewController()
    session = nil
    sessionType = nil
    sessionCreationError = nil
    sessionIsReady = false
    receivedHandoff = false
  }

  private func missingSessionFlutterError() -> FlutterError {
    if let sessionCreationError {
      return flutterError(from: sessionCreationError, fallbackCode: "SESSION_CREATE_ERROR")
    }
    return FlutterError(
      code: "-1",
      message: "PlaidLink.create() was not called.",
      details: "Unable to create a Plaid Link session."
    )
  }

  private func flutterError(from error: Error, fallbackCode: String) -> FlutterError {
    let error = error as NSError
    let code = error.code == 0 ? fallbackCode : String(error.code)
    return FlutterError(
      code: code,
      message: error.localizedDescription,
      details: nil
    )
  }

  private func creationFailureEvent(from error: FlutterError) -> [String: Any] {
    [
      "type": EventType.exit,
      "error": [
        "errorDisplayMessage": error.message ?? "",
        "errorCode": error.code,
        "errorType": "Creation error",
        "errorMessage": error.message ?? "",
      ],
      "metadata": [
        "status": "",
        "institution": Institution.plaidEmptyDictionary,
        "requestId": "",
        "linkSessionId": "",
        "metadataJson": "",
      ],
    ]
  }

  private func noViewControllerFlutterError() -> FlutterError {
    FlutterError(
      code: "PLAID_NO_VIEW_CONTROLLER",
      message: "Could not find a foreground view controller for Plaid Link.",
      details: nil
    )
  }

  private var plaidPresentingViewController: UIViewController? {
    flutterViewController?.plaidTopViewController
      ?? UIApplication.shared.plaidTopViewController
  }
}

private func onMain(_ block: @escaping () -> Void) {
  if Thread.isMainThread {
    block()
  } else {
    DispatchQueue.main.async(execute: block)
  }
}
