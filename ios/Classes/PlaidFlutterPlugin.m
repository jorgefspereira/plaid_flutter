#import "PlaidFlutterPlugin.h"
// Plaid Link Framework
#import <LinkKit/LinkKit.h>

@interface PlaidFlutterPlugin (PLKPlaidLinkViewDelegate) <PLKPlaidLinkViewDelegate>
@end

@implementation PlaidFlutterPlugin {
    UIViewController *_rootViewController;
    FlutterMethodChannel *_channel;
    PLKPlaidLinkViewController *_linkViewController;
    PLKConfiguration *_linkConfiguration;
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

- (void)dealloc {
  [_channel setMethodCallHandler:nil];
  _channel = nil;
  _rootViewController = nil;
  _linkViewController = nil;
  _linkConfiguration = nil;
}

//MARK:-

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    
  if ([@"create" isEqualToString:call.method]) {
      
      NSString* clientName = call.arguments[@"clientName"];
      NSString* publicKey = call.arguments[@"publicKey"];
      NSString* webhook = call.arguments[@"webhook"];
      NSString* oauthRedirectUri = call.arguments[@"oauthRedirectUri"];
      NSString* oauthNonce = call.arguments[@"oauthNonce"];
      NSString* linkCustomizationName = call.arguments[@"linkCustomizationName"];
      NSString* language = call.arguments[@"language"];
      NSArray<NSString*>* countryCodes = call.arguments[@"countryCodes"];
      NSDictionary<NSString*, NSArray<NSString*>*>* accountSubtypes = call.arguments[@"accountSubtypes"];
      

      PLKEnvironment env = PLKEnvironmentFromString(call.arguments[@"env"]);
      PLKProduct product = PLKProductFromArray(call.arguments[@"products"]);
      
      @try {
          _linkConfiguration = [[PLKConfiguration alloc] initWithKey:publicKey
                                                                env:env
                                                            product:product];

          _linkConfiguration.clientName = clientName;
          
      }
      @catch (NSException *exception) {
          NSLog(@"Invalid configuration: %@", exception);
      }
      
      if([oauthRedirectUri isKindOfClass:[NSString class]]) {
        _linkConfiguration.oauthRedirectUri = [NSURL URLWithString:oauthRedirectUri];
      }

      if([oauthNonce isKindOfClass:[NSString class]]) {
        _linkConfiguration.oauthNonce = oauthNonce;
      }

      if([accountSubtypes isKindOfClass:[NSDictionary class]]) {
        _linkConfiguration.accountSubtypes = accountSubtypes;
      }
                
      if([webhook isKindOfClass:[NSString class]]) {
        _linkConfiguration.webhook = [NSURL URLWithString:webhook];
      }

      if([linkCustomizationName isKindOfClass:[NSString class]]) {
        _linkConfiguration.linkCustomizationName = linkCustomizationName;
      }
      
      if ([language isKindOfClass:[NSString class]]) {
        _linkConfiguration.language = language;
      }

      if ([countryCodes isKindOfClass:[NSArray class]]) {
        _linkConfiguration.countryCodes = countryCodes;
      }
      
  }
  else if ([@"open" isEqualToString:call.method]) {
      
      id<PLKPlaidLinkViewDelegate> linkViewDelegate  = self;
      
      NSString* userLegalName = call.arguments[@"userLegalName"];
      NSString* userEmailAddress = call.arguments[@"userEmailAddress"];
      NSString* userPhoneNumber = call.arguments[@"userPhoneNumber"];
      
      NSString* publicToken = call.arguments[@"publicToken"];
      NSString* institution = call.arguments[@"institution"];
      NSString* paymentToken = call.arguments[@"paymentToken"];
      NSString* oauthStateId = call.arguments[@"oauthStateId"];

      if([userLegalName isKindOfClass:[NSString class]]) {
        _linkConfiguration.userLegalName = userLegalName;
      }

      if([userEmailAddress isKindOfClass:[NSString class]]) {
        _linkConfiguration.userEmailAddress = userEmailAddress;
      }

      if ([userPhoneNumber isKindOfClass:[NSString class]]) {
        _linkConfiguration.userPhoneNumber = userPhoneNumber;
      }
      
      
      if ([publicToken isKindOfClass:[NSString class]]) {
         if ([publicToken hasPrefix:@"item-add-"]) {
             _linkViewController = [[PLKPlaidLinkViewController alloc] initWithItemAddToken:publicToken
                                                                              configuration:_linkConfiguration
                                                                                   delegate:linkViewDelegate];
         } else {
             _linkViewController = [[PLKPlaidLinkViewController alloc] initWithPublicToken:publicToken
                                                                             configuration:_linkConfiguration
                                                                                  delegate:linkViewDelegate];
         }
      }
      else if ([institution isKindOfClass:[NSString class]]) {
          _linkViewController = [[PLKPlaidLinkViewController alloc] initWithInstitution:institution
                                                                          configuration:_linkConfiguration
                                                                               delegate:linkViewDelegate];
      }
      else if ([paymentToken isKindOfClass:[NSString class]] && [oauthStateId isKindOfClass:[NSString class]]) {
          _linkViewController = [[PLKPlaidLinkViewController alloc] initWithPaymentToken:paymentToken
                                                                            oauthStateId:oauthStateId
                                                                           configuration:_linkConfiguration
                                                                                delegate:linkViewDelegate];
      }
      else if ([oauthStateId isKindOfClass:[NSString class]]) {
          _linkViewController = [[PLKPlaidLinkViewController alloc] initWithOAuthStateId:oauthStateId
                                                                           configuration:_linkConfiguration
                                                                                delegate:linkViewDelegate];
      }
      else {
          _linkViewController = [[PLKPlaidLinkViewController alloc] initWithConfiguration:_linkConfiguration
                                                                                 delegate:linkViewDelegate];
      }

      if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
          _linkViewController.modalPresentationStyle = UIModalPresentationFormSheet;
      }

      [_rootViewController presentViewController:_linkViewController animated:YES completion:nil];
      
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
        self->_linkViewController.delegate = nil;
        self->_linkViewController = nil;
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
        }
        
        self->_linkViewController.delegate = nil;
        self->_linkViewController = nil;
    }];
    
}

- (void)linkViewController:(PLKPlaidLinkViewController*)linkViewController
            didHandleEvent:(NSString*)event
                  metadata:(NSDictionary<NSString*,id>* _Nullable)metadata {
    [_channel invokeMethod:@"onEvent" arguments:@{@"event": event, @"metadata" : metadata}];
}

@end



