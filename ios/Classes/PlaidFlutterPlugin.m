#import "PlaidFlutterPlugin.h"
/// Plaid Link Framework
#import <LinkKit/LinkKit.h>

/// PLKConfiguration
static NSString* const kClientNameKey = @"clientName";
static NSString* const kEnvKey = @"env";
static NSString* const kProductsKey = @"products";
static NSString* const kPublicKeyKey = @"publicKey";
static NSString* const kWebhookKey = @"webhook";
static NSString* const kOAuthRedirectUriKey = @"oauthRedirectUri";
static NSString* const kOAuthNonceKey = @"oauthNonce";
static NSString* const kLinkCustomizationName = @"linkCustomizationName";
static NSString* const kAccountSubtypes = @"accountSubtypes";
static NSString* const kCountryCodesKey = @"countryCodes";
static NSString* const kLanguageKey = @"language";
static NSString* const kUserLegalNameKey = @"userLegalName";
static NSString* const kUserEmailAddressKey = @"userEmailAddress";
static NSString* const kUserPhoneNumberKey = @"userPhoneNumber";

/// PLKPlaidLinkViewController
static NSString* const kLinkTokenKey = @"linkToken";
static NSString* const kPaymentTokenKey = @"paymentToken";
static NSString* const kInstitutionKey = @"institution";
static NSString* const kOAuthStateIdKey = @"oauthStateId";

/// PLKPlaidLinkViewDelegate
static NSString* const kOnSuccessMethod = @"onSuccess";
static NSString* const kOnExitMethod = @"onExit";
static NSString* const kOnEventMethod = @"onEvent";
static NSString* const kErrorKey = @"error";
static NSString* const kMetadataKey = @"metadata";
static NSString* const kPublicTokenKey = @"publicToken";
static NSString* const kEventKey = @"event";
   
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

- (void)dealloc {
  [_channel setMethodCallHandler:nil];
  _channel = nil;
  _rootViewController = nil;
  _linkViewController = nil;
}

//MARK:-

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    
    if ([@"open" isEqualToString:call.method]) {
      
        NSString* institution = call.arguments[kInstitutionKey];
        NSString* paymentToken = call.arguments[kPaymentTokenKey];
        NSString* oauthStateId = call.arguments[kOAuthStateIdKey];
        NSString* linkToken = call.arguments[kLinkTokenKey];
      
        id<PLKPlaidLinkViewDelegate> linkViewDelegate  = self;
        BOOL usingLinkToken = [linkToken isKindOfClass:[NSString class]];
        PLKConfiguration* linkConfiguration = usingLinkToken ?
                                            [self getNewLinkConfigurationWithArguments:call.arguments] :
                                            [self getLegacyLinkConfigurationWithArguments:call.arguments];
        
        if (usingLinkToken) {
            if ([linkToken hasPrefix:@"link-"]) {
                _linkViewController = [[PLKPlaidLinkViewController alloc] initWithLinkToken:linkToken
                                                                               oauthStateId:oauthStateId
                                                                              configuration:linkConfiguration
                                                                                   delegate:linkViewDelegate];
            }
            else if ([linkToken hasPrefix:@"item-add-"]) {
                _linkViewController = [[PLKPlaidLinkViewController alloc] initWithItemAddToken:linkToken
                                                                                 configuration:linkConfiguration
                                                                                      delegate:linkViewDelegate];
            } else {
                _linkViewController = [[PLKPlaidLinkViewController alloc] initWithPublicToken:linkToken
                                                                                configuration:linkConfiguration
                                                                                     delegate:linkViewDelegate];
            }
        }
        else if ([institution isKindOfClass:[NSString class]]) {
            _linkViewController = [[PLKPlaidLinkViewController alloc] initWithInstitution:institution
                                                                            configuration:linkConfiguration
                                                                                 delegate:linkViewDelegate];
        }
        else if ([paymentToken isKindOfClass:[NSString class]] && [oauthStateId isKindOfClass:[NSString class]]) {
            _linkViewController = [[PLKPlaidLinkViewController alloc] initWithPaymentToken:paymentToken
                                                                              oauthStateId:oauthStateId
                                                                             configuration:linkConfiguration
                                                                                  delegate:linkViewDelegate];
        }
        else if ([oauthStateId isKindOfClass:[NSString class]]) {
            _linkViewController = [[PLKPlaidLinkViewController alloc] initWithOAuthStateId:oauthStateId
                                                                             configuration:linkConfiguration
                                                                                  delegate:linkViewDelegate];
        }
        else {
            _linkViewController = [[PLKPlaidLinkViewController alloc] initWithConfiguration:linkConfiguration
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


//MARK:- PLKConfiguraiton

- (PLKConfiguration*)getNewLinkConfigurationWithArguments:(id _Nullable)arguments {
    NSString* linkToken = arguments[kLinkTokenKey];
    NSString* oauthRedirectUri = arguments[kOAuthRedirectUriKey];
    NSString* oauthNonce = arguments[kOAuthNonceKey];

    PLKConfiguration* linkConfiguration = [[PLKConfiguration alloc] initWithLinkToken:linkToken];

    if ([oauthRedirectUri isKindOfClass:[NSString class]]) {
        linkConfiguration.oauthRedirectUri = [NSURL URLWithString:oauthRedirectUri];
    }
    
    if ([oauthNonce isKindOfClass:[NSString class]]) {
        linkConfiguration.oauthNonce = oauthNonce;
    }
    
    return linkConfiguration;
}

- (PLKConfiguration*)getLegacyLinkConfigurationWithArguments:(id _Nullable)arguments {
    NSString* userLegalName = arguments[kUserLegalNameKey];
    NSString* userEmailAddress = arguments[kUserEmailAddressKey];
    NSString* userPhoneNumber = arguments[kUserPhoneNumberKey];
    NSString* oauthRedirectUri = arguments[kOAuthRedirectUriKey];
    NSString* oauthNonce = arguments[kOAuthNonceKey];
    NSString* clientName = arguments[kClientNameKey];
    NSString* publicKey = arguments[kPublicKeyKey];
    NSString* webhook = arguments[kWebhookKey];
    NSString* linkCustomizationName = arguments[kLinkCustomizationName];
    NSString* language = arguments[kLanguageKey];
    NSArray<NSString*>* countryCodes = arguments[kCountryCodesKey];
    NSDictionary<NSString*, NSArray<NSString*>*>* accountSubtypes = arguments[kAccountSubtypes];
    

    PLKEnvironment env = PLKEnvironmentFromString(arguments[kEnvKey]);
    PLKProduct product = PLKProductFromArray(arguments[kProductsKey]);
    PLKConfiguration *linkConfiguration;
    
    @try {
        linkConfiguration = [[PLKConfiguration alloc] initWithKey:publicKey
                                                              env:env
                                                          product:product];
        
    }
    @catch (NSException *exception) {
        NSLog(@"Invalid configuration: %@", exception);
    }
    
    if([clientName isKindOfClass:[NSString class]]) {
        linkConfiguration.clientName = clientName;
    }
        
    if([userLegalName isKindOfClass:[NSString class]]) {
        linkConfiguration.userLegalName = userLegalName;
    }

    if([userEmailAddress isKindOfClass:[NSString class]]) {
        linkConfiguration.userEmailAddress = userEmailAddress;
    }

    if ([userPhoneNumber isKindOfClass:[NSString class]]) {
        linkConfiguration.userPhoneNumber = userPhoneNumber;
    }
    
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

    if([linkCustomizationName isKindOfClass:[NSString class]]) {
        linkConfiguration.linkCustomizationName = linkCustomizationName;
    }
    
    if ([language isKindOfClass:[NSString class]]) {
        linkConfiguration.language = language;
    }

    if ([countryCodes isKindOfClass:[NSArray class]]) {
      linkConfiguration.countryCodes = countryCodes;
    }
    
    return linkConfiguration;
}

//MARK:- PLKPlaidLinkViewDelegate

- (void)linkViewController:(PLKPlaidLinkViewController*)linkViewController
 didSucceedWithPublicToken:(NSString*)publicToken
                  metadata:(NSDictionary<NSString*,id>* _Nullable)metadata {
    [_rootViewController dismissViewControllerAnimated:YES completion:^{
        [self->_channel invokeMethod:kOnSuccessMethod arguments:@{kPublicTokenKey: publicToken, kMetadataKey : metadata}];
        self->_linkViewController.delegate = nil;
        self->_linkViewController = nil;
    }];
}

- (void)linkViewController:(PLKPlaidLinkViewController*)linkViewController
          didExitWithError:(NSError* _Nullable)error
                  metadata:(NSDictionary<NSString*,id>* _Nullable)metadata {

    [_rootViewController dismissViewControllerAnimated:YES completion:^{
        NSMutableDictionary* arguments = [[NSMutableDictionary alloc] init];
        [arguments setObject:metadata forKey:kMetadataKey];
        
        if(error) {
            [arguments setObject:[error localizedDescription] forKey:kErrorKey];
        }
        
        [self->_channel invokeMethod:kOnExitMethod arguments:arguments];
        self->_linkViewController.delegate = nil;
        self->_linkViewController = nil;
    }];
    
}

- (void)linkViewController:(PLKPlaidLinkViewController*)linkViewController
            didHandleEvent:(NSString*)event
                  metadata:(NSDictionary<NSString*,id>* _Nullable)metadata {
    [_channel invokeMethod:kOnEventMethod arguments:@{kEventKey: event, kMetadataKey : metadata}];
}

@end

