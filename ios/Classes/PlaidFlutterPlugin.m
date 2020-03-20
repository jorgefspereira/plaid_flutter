#import "PlaidFlutterPlugin.h"
// Plaid Link Framework
#import <LinkKit/LinkKit.h>

@interface PlaidFlutterPlugin (PLKPlaidLinkViewDelegate) <PLKPlaidLinkViewDelegate>
@end

@implementation PlaidFlutterPlugin {
    UIViewController *_rootViewController;
    FlutterMethodChannel *_channel;
    PLKPlaidLinkViewController *_linkViewController;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@"plugins.flutter.io/plaid_flutter"
                                                                binaryMessenger:[registrar messenger]];
    UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
    PlaidFlutterPlugin *instance = [[PlaidFlutterPlugin alloc] initWithRootViewController:rootViewController channel:channel];
    [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController channel:(FlutterMethodChannel*)channel{
    self = [super init];
    if (self) {
        _rootViewController = rootViewController;
        _channel = channel;
    }
    return self;
}

//MARK:-

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"open" isEqualToString:call.method]) {
      PLKConfiguration* linkConfiguration;
      
      NSString* clientName = call.arguments[@"clientName"];
      NSString* publicKey = call.arguments[@"publicKey"];
      NSString* webhook = call.arguments[@"webhook"];
      NSString* oauthRedirectUri = call.arguments[@"oauthRedirectUri"];
      NSString* oauthNonce = call.arguments[@"oauthNonce"];
      NSDictionary<NSString*, NSArray<NSString*>*>* accountSubtypes = call.arguments[@"accountSubtypes"];
      

      PLKEnvironment env = PLKEnvironmentFromString(call.arguments[@"env"]);
      PLKProduct product = PLKProductFromArray(call.arguments[@"products"]);
      
      @try {
          linkConfiguration = [[PLKConfiguration alloc] initWithKey:publicKey
                                                                env:env
                                                            product:product];

          linkConfiguration.clientName = clientName;
          

          if([oauthRedirectUri isKindOfClass:[NSString class]]) {
            linkConfiguration.oauthRedirectUri = [NSURL URLWithString:oauthRedirectUri];
          }

          if([oauthNonce isKindOfClass:[NSString class]]) {
            linkConfiguration.oauthNonce = oauthNonce;
          }

          if([accountSubtypes isKindOfClass:[NSDictionary class]]) {
            linkConfiguration.accountSubtypes = accountSubtypes;
          }
                    
          if([webhook isKindOfClass:[NSString class]]) {
              linkConfiguration.webhook = [NSURL URLWithString:webhook];
          }

          id<PLKPlaidLinkViewDelegate> linkViewDelegate  = self;
          _linkViewController = [[PLKPlaidLinkViewController alloc] initWithConfiguration:linkConfiguration delegate:linkViewDelegate];
          
          if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
              _linkViewController.modalPresentationStyle = UIModalPresentationFormSheet;
          }
          
          [_rootViewController presentViewController:_linkViewController animated:YES completion:nil];
      }
      @catch (NSException *exception) {
          NSLog(@"Invalid configuration: %@", exception);
      }
  }
  else {
    result(FlutterMethodNotImplemented);
  }
}

//MARK:- PLKPlaidLinkViewDelegate

- (void)linkViewController:(PLKPlaidLinkViewController*)linkViewController
 didSucceedWithPublicToken:(NSString*)publicToken
                  metadata:(NSDictionary<NSString*,id>* _Nullable)metadata {
    [_rootViewController dismissViewControllerAnimated:YES completion:^{
        [self->_channel invokeMethod:@"onAccountLinked" arguments:@{@"publicToken": publicToken, @"metadata" : metadata}];
    }];
}

- (void)linkViewController:(PLKPlaidLinkViewController*)linkViewController
          didExitWithError:(NSError* _Nullable)error
                  metadata:(NSDictionary<NSString*,id>* _Nullable)metadata {

    [_rootViewController dismissViewControllerAnimated:YES completion:^{
        if (error) {
            [self->_channel invokeMethod:@"onAccountLinkError" arguments:@{@"error": [error localizedDescription], @"metadata" : metadata}];
        }
        else {
            [self->_channel invokeMethod:@"onExit" arguments:@{@"metadata" : metadata}];
            self->_linkViewController.delegate = nil;
            self->_linkViewController = nil;
        }
    }];
    
}

- (void)linkViewController:(PLKPlaidLinkViewController*)linkViewController
            didHandleEvent:(NSString*)event
                  metadata:(NSDictionary<NSString*,id>* _Nullable)metadata {
    [_channel invokeMethod:@"onEvent" arguments:@{@"event": event, @"metadata" : metadata}];
}

@end



