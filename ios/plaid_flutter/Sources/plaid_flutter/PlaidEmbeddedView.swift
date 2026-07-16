import Flutter
import LinkKit
import UIKit

final class PlaidEmbeddedViewFactory: NSObject, FlutterPlatformViewFactory {
  private weak var emitter: PlaidEventEmitter?

  init(emitter: PlaidEventEmitter) {
    self.emitter = emitter
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    PlaidEmbeddedView(frame: frame, arguments: args, emitter: emitter)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

final class PlaidEmbeddedView: NSObject, FlutterPlatformView {
  private let rootView: UIView
  private weak var emitter: PlaidEventEmitter?
  private var embeddedView: EmbeddedSearchUIView?

  init(frame: CGRect, arguments: Any?, emitter: PlaidEventEmitter?) {
    rootView = UIView(frame: frame)
    self.emitter = emitter
    super.init()

    rootView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    guard let arguments = arguments as? [String: Any],
      let token = arguments["token"] as? String,
      !token.isEmpty
    else {
      sendCreationError(
        code: "INVALID_TOKEN",
        message: "A non-empty link token is required for Embedded Link."
      )
      return
    }

    createEmbeddedView(token: token)
  }

  func view() -> UIView {
    rootView
  }

  private func createEmbeddedView(token: String) {
    let configuration = EmbeddedLinkTokenConfiguration(
      token: token,
      onSuccess: { [weak self] success in
        var payload = success.plaidDictionary
        payload["type"] = "success"
        self?.emitter?.sendEvent(payload)
      },
      onExit: { [weak self] exit in
        var payload = exit.plaidDictionary
        payload["type"] = "exit"
        self?.emitter?.sendEvent(payload)
      },
      onEvent: { [weak self] event in
        var payload = event.plaidDictionary
        payload["type"] = "event"
        self?.emitter?.sendEvent(payload)
      }
    )

    let presentationMethod = PresentationMethod.custom(
      { [weak self] linkViewController in
        guard let self,
          let presentingViewController = rootView.plaidOwningViewController
            ?? UIApplication.shared.plaidTopViewController
        else {
          return
        }
        presentingViewController.present(linkViewController, animated: true)
      },
      { linkViewController in
        linkViewController.presentingViewController?.dismiss(animated: true)
      }
    )

    do {
      let embeddedView = try Plaid.createEmbeddedLinkUIView(
        configuration: configuration,
        presentationMethod: presentationMethod
      )
      embeddedView.translatesAutoresizingMaskIntoConstraints = false
      rootView.addSubview(embeddedView)
      NSLayoutConstraint.activate([
        embeddedView.topAnchor.constraint(equalTo: rootView.topAnchor),
        embeddedView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
        embeddedView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
        embeddedView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
      ])
      self.embeddedView = embeddedView
      emitter?.sendEvent(["type": "onload"])
    } catch {
      let error = error as NSError
      sendCreationError(
        code: error.code == 0 ? "EMBEDDED_SESSION_CREATE_ERROR" : String(error.code),
        message: error.localizedDescription
      )
    }
  }

  private func sendCreationError(code: String, message: String) {
    emitter?.sendEvent([
      "type": "exit",
      "error": [
        "errorDisplayMessage": message,
        "errorCode": code,
        "errorType": "Creation error",
        "errorMessage": message,
      ],
      "metadata": [
        "status": "",
        "institution": Institution.plaidEmptyDictionary,
        "requestId": "",
        "linkSessionId": "",
        "metadataJson": "",
      ],
    ])
  }
}
