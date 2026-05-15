#import <LinkKit/LinkKit.h>
#import "PLKEmbeddedView.h"
#import "PlaidFlutterPlugin.h"
#import "TopViewControllerHelper.h"
#import "PLKEventEmitterProtocol.h"

@implementation PLKEmbeddedViewFactory {
    __weak id<PLKEventEmitter> _emitter;
    NSObject<FlutterBinaryMessenger>* _Nullable _messenger;
}

- (instancetype _Nullable)initWithMessenger:(NSObject<FlutterBinaryMessenger>* _Nullable)messenger emitter:(id<PLKEventEmitter>_Nonnull)emitter {
      self = [super init];
      if (self) {
          _messenger = messenger;
          _emitter = emitter;
      }
      return self;
}

- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
    return [[PLKEmbeddedView alloc] initWithFrame:frame
                                   viewIdentifier:viewId
                                        arguments:args
                                  binaryMessenger:_messenger
                                          emitter:_emitter];
    
}

/// Implementing this method is only necessary when the `arguments` in `createWithFrame` is not `nil`.
- (NSObject<FlutterMessageCodec>*)createArgsCodec {
    return [FlutterStandardMessageCodec sharedInstance];
}

@end

static NSString *const kEmbeddedEventNameKey = @"embeddedEventName";
static NSString* const kTokenKey = @"token";
static NSString* const kPhoneNumberKey = @"phoneNumber";
static NSString* const kContinueRedirectUriKey = @"redirectUri";
static NSString* const kNoLoadingStateKey = @"noLoadingState";
static NSString* const kOnSuccessType = @"success";
static NSString* const kOnExitType = @"exit";
static NSString* const kOnEventType = @"event";
static NSString* const kErrorKey = @"error";
static NSString* const kMetadataKey = @"metadata";
static NSString* const kPublicTokenKey = @"publicToken";
static NSString* const kNameKey = @"name";
static NSString* const kTypeKey = @"type";
static NSString* const kRequestAuthorizationIfNeeded = @"requestAuthorizationIfNeeded";
static NSString* const kShowGradientBackground = @"showGradientBackground";

@implementation PLKEmbeddedView {
    UIView *_rootView;
    id<PLKHandler> _linkHandler;
    NSString* _token;
    id<PLKEventEmitter> _emitter;
}

- (instancetype)initWithFrame:(CGRect)frame
               viewIdentifier:(int64_t)viewId
                    arguments:(id _Nullable)args
              binaryMessenger:(NSObject<FlutterBinaryMessenger>* _Nullable)messenger
                      emitter:(id<PLKEventEmitter>)emitter {
    if (self = [super init]) {
        _rootView = [[UIView alloc] initWithFrame:frame];
        _rootView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _token = args[@"token"];
        _emitter =  emitter;
        
        [self createNativeEmbeddedView];
    }
    return self;
}


- (void)createNativeEmbeddedView
{
    __weak typeof(self) weakSelf = self;
        
    PLKOnSuccessHandler successHandler = ^(PLKLinkSuccess *success) {
        __strong typeof(self) strongSelf = weakSelf;
        
        [strongSelf sendEventWithArguments: @{ kTypeKey: kOnSuccessType,
                                        kPublicTokenKey: success.publicToken ?: @"",
                                           kMetadataKey: [PlaidFlutterPlugin dictionaryFromSuccessMetadata:success.metadata]}];
    };
    
    PLKOnExitHandler exitHandler = ^(PLKLinkExit *exit) {
        __strong typeof(self) strongSelf = weakSelf;
        
        
        NSMutableDictionary* arguments = [[NSMutableDictionary alloc] init];
        [arguments setObject:kOnExitType forKey:kTypeKey];
        [arguments setObject:[PlaidFlutterPlugin dictionaryFromExitMetadata: exit.metadata] forKey:kMetadataKey];

        if(exit.error) {
            [arguments setObject:[PlaidFlutterPlugin dictionaryFromError:exit.error] ?: @{} forKey:kErrorKey];
        }
        
        [strongSelf sendEventWithArguments: arguments];
    };

    PLKOnEventHandler eventHandler = ^(PLKLinkEvent *event) {
        __strong typeof(self) strongSelf = weakSelf;
    
        [strongSelf sendEventWithArguments:@{kTypeKey: kOnEventType,
                                             kNameKey: [PlaidFlutterPlugin stringForEventName: event.eventName] ?: @"",
                                         kMetadataKey: [PlaidFlutterPlugin dictionaryFromEventMetadata: event.eventMetadata]}];
        
    };
    
    PLKLinkTokenConfiguration *config = [PLKLinkTokenConfiguration createWithToken:_token onSuccess:successHandler];
    config.onEvent = eventHandler;
    config.onExit = exitHandler;

    NSError *error = nil;
    _linkHandler = [PLKPlaid createWithLinkTokenConfiguration:config error:&error];
     
    UIViewController *topViewController = [[UIApplication sharedApplication] topViewController];
    UIView *embeddedLinkView = [_linkHandler createEmbeddedView:topViewController];
    embeddedLinkView.translatesAutoresizingMaskIntoConstraints = NO;
    [_rootView addSubview:embeddedLinkView];

    [NSLayoutConstraint activateConstraints:@[
        [embeddedLinkView.topAnchor constraintEqualToAnchor:_rootView.topAnchor],
        [embeddedLinkView.leadingAnchor constraintEqualToAnchor:_rootView.leadingAnchor],
        [embeddedLinkView.trailingAnchor constraintEqualToAnchor:_rootView.trailingAnchor],
        [embeddedLinkView.bottomAnchor constraintEqualToAnchor:_rootView.bottomAnchor],
    ]];
}

- (UIView* _Nonnull)view {
  return _rootView;
}

- (void)sendEventWithArguments:(id)arguments {
    [_emitter sendEventWithArguments:arguments];
}

@end
