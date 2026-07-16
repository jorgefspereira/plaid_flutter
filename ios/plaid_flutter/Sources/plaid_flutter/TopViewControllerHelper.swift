import UIKit

extension UIApplication {
  var plaidTopViewController: UIViewController? {
    let foregroundScenes =
      connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { $0.activationState == .foregroundActive }

    let window =
      foregroundScenes
      .compactMap { scene in
        scene.windows.first(where: { $0.isKeyWindow })
          ?? scene.windows.first(where: { !$0.isHidden })
      }
      .first

    return window?.rootViewController?.plaidTopViewController
  }
}

extension UIViewController {
  var plaidTopViewController: UIViewController {
    if let presentedViewController,
      !presentedViewController.isBeingDismissed
    {
      return presentedViewController.plaidTopViewController
    }

    if let navigationController = self as? UINavigationController,
      let visibleViewController = navigationController.visibleViewController
    {
      return visibleViewController.plaidTopViewController
    }

    if let tabBarController = self as? UITabBarController,
      let selectedViewController = tabBarController.selectedViewController
    {
      return selectedViewController.plaidTopViewController
    }

    if let splitViewController = self as? UISplitViewController,
      let lastViewController = splitViewController.viewControllers.last
    {
      return lastViewController.plaidTopViewController
    }

    return self
  }
}

extension UIView {
  var plaidOwningViewController: UIViewController? {
    var responder: UIResponder? = self
    while let nextResponder = responder?.next {
      if let viewController = nextResponder as? UIViewController {
        return viewController
      }
      responder = nextResponder
    }
    return nil
  }
}
