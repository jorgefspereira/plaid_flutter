#import <UIKit/UIKit.h>

@interface UIApplication (TopViewController)

- (UIViewController *)topViewController;
- (UIViewController *)topViewControllerForWindow:(UIWindow *)window;

@end