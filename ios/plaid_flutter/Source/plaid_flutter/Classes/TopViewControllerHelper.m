#import "TopViewControllerHelper.h"

@implementation UIApplication (TopViewController)

- (UIViewController *)topViewControllerForWindow:(UIWindow *)window {
    UIViewController *topViewController = window.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }
    
    if ([topViewController isKindOfClass:[UINavigationController class]]) {
        topViewController = [(UINavigationController *)topViewController topViewController];
    } else if ([topViewController isKindOfClass:[UITabBarController class]]) {
        topViewController = [(UITabBarController *)topViewController selectedViewController];
    }
    
    return topViewController;
}

- (UIViewController *)topViewController {
    // Handle multi-window/scene
    UIScene *scene = [UIApplication sharedApplication].connectedScenes.anyObject;
    if ([scene isKindOfClass:[UIWindowScene class]]) {
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) {
                return [self topViewControllerForWindow:window];
            }
        }
    }
    return nil;
}

@end