#import "TopViewControllerHelper.h"
#import "PlaidFlutterPlugin.h"
#import <LinkKit/LinkKit.h>

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
static NSString* const kSimulatedBehavior = @"simulatedBehavior";

@interface PlaidFlutterPlugin () <FlutterStreamHandler>
@end

@implementation PlaidFlutterPlugin {
    FlutterEventSink _eventSink;
    id<PLKHandler> _linkHandler;
    NSError *_creationError;
    UIViewController *_presentedViewController;
}

+ (NSString *)sdkVersion {
  return @"5.0.3"; // Update this version with every SDK release.
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
    FlutterMethodChannel *methodChannel = [FlutterMethodChannel methodChannelWithName:@"plugins.flutter.io/plaid_flutter"
                                                                binaryMessenger:[registrar messenger]];

    FlutterEventChannel *eventChannel = [FlutterEventChannel eventChannelWithName:@"plugins.flutter.io/plaid_flutter/events"
                                                                  binaryMessenger:[registrar messenger]];

    PlaidFlutterPlugin *instance = [[PlaidFlutterPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:methodChannel];
    [eventChannel setStreamHandler:instance];
}

- (void)dealloc {
  _linkHandler = nil;
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([@"create" isEqualToString:call.method])
        [self createWithArguments: call.arguments withResult:result];
    else if ([@"open" isEqualToString:call.method])
        [self openWithResult:result];
    else if ([@"close" isEqualToString:call.method])
        [self closeWithResult:result];
    else if([@"resumeAfterTermination" isEqualToString:call.method])
        [self resumeAfterTermination:call.arguments withResult:result];
    else if([@"submit" isEqualToString:call.method])
        [self submit:call.arguments withResult:result];
    else if([@"syncFinanceKit" isEqualToString:call.method])
        [self syncFinanceKit:call.arguments withResult:result];
    else
        result(FlutterMethodNotImplemented);

}

#pragma mark FlutterStreamHandler implementation

- (void) sendEventWithArguments:(id _Nullable)arguments {
    if (!_eventSink)
        return;

    _eventSink(arguments);
}

- (FlutterError *)onListenWithArguments:(id)arguments
                              eventSink:(FlutterEventSink)eventSink {
    _eventSink = eventSink;
    return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments {
    _eventSink = nil;
    return nil;
}

#pragma mark Exposed methods

- (void) createWithArguments: (id _Nullable)arguments withResult:(FlutterResult)result {
    NSString* token = arguments[kTokenKey];
    BOOL noLoadingState = arguments[kNoLoadingStateKey];
    BOOL showGradientBackground = arguments[kShowGradientBackground];
    
    __weak typeof(self) weakSelf = self;

    PLKOnSuccessHandler successHandler = ^(PLKLinkSuccess *success) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf close];
        [strongSelf sendEventWithArguments: @{kTypeKey: kOnSuccessType,
                                              kPublicTokenKey: success.publicToken ?: @"",
                                              kMetadataKey : [PlaidFlutterPlugin dictionaryFromSuccessMetadata:success.metadata]}];
    };

    PLKOnExitHandler exitHandler = ^(PLKLinkExit *exit) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf close];
        // No HANDOFF event for exit so we can deallocate this right away.
        strongSelf->_linkHandler = nil;

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

        // If the HANDOFF event is received.                                             
        if (event.eventName.value == PLKEventNameValueHandoff) {
            // Only deallocate the handler if the view controller is no longer presented.
            if (strongSelf->_presentedViewController == nil) {
                strongSelf->_linkHandler = nil;
            }
        }
    };

    PLKLinkTokenConfiguration *config = [self getLinkTokenConfigurationWithToken:token onSuccessHandler:successHandler];
    config.onEvent = eventHandler;
    config.onExit = exitHandler;
    config.noLoadingState = noLoadingState;
    config.showGradientBackground = showGradientBackground;

    NSError *error = nil;
    _linkHandler = [PLKPlaid createWithLinkTokenConfiguration:config
                                                       onLoad:^{
                                                            result(nil);
                                                        }
                                                        error:&error];
    _creationError = error;
    
    if (error) {
        result([FlutterError errorWithCode:[@(error.code) stringValue]
                                   message:error.localizedDescription details: nil]);
    }
}

- (void) openWithResult:(FlutterResult)result {
    if (_linkHandler) {
        __block bool didPresent = NO;
        __weak typeof(self) weakSelf = self;
        ///
        void(^presentationHandler)(UIViewController *) = ^(UIViewController *linkViewController) {
            __strong typeof(self) strongSelf = weakSelf;
            if (strongSelf) {
                UIViewController *topViewController = [[UIApplication sharedApplication] topViewController];
                [topViewController presentViewController:linkViewController animated:YES completion:nil];
                strongSelf->_presentedViewController = linkViewController;
                didPresent = YES;
            }
        };

        void(^dismissalHandler)(UIViewController *) = ^(UIViewController *linkViewController) {
            __strong typeof(self) strongSelf = weakSelf;
            if (strongSelf && didPresent) {
                [weakSelf close];
                didPresent = NO;
            }
        };

        [_linkHandler openWithPresentationHandler:presentationHandler dismissalHandler:dismissalHandler];
        result(nil);

    } else {
        
        NSString *errorMessage = _creationError ? _creationError.userInfo[@"message"] : @"Create was not called.";
        NSString *errorCode = _creationError ? [@(_creationError.code) stringValue] : @"-1";
        NSString *errorDetails = @"Unable to create PLKHandler";
        NSString *errorType = @"Creation error";

        NSDictionary *exitEvent = @{
            kTypeKey: kOnExitType,
            kErrorKey : @{
                @"errorDisplayMessage": errorMessage,
                @"errorCode": errorCode,
                @"errorType": errorType,
                @"errorMessage": errorMessage,
            },
            kMetadataKey: @{
                @"status": @"",
                @"institution": @{
                    @"name": @"",
                    @"id": @"",
                },
                @"requestId": @"",
                @"linkSessionId": @"",
                @"metadataJson": @"",
            },
        };

        [self sendEventWithArguments: exitEvent];
        result([FlutterError errorWithCode: errorCode message: errorMessage details: errorDetails]);
    }
}

- (void) close {
    if (_presentedViewController) {
        [_presentedViewController dismissViewControllerAnimated:YES completion:nil];
        _presentedViewController = nil; // Reset after dismissal
    }
}

- (void) closeWithResult:(FlutterResult)result {
    [self close];
    result(nil);
}

- (void) resumeAfterTermination: (id _Nullable)arguments withResult:(FlutterResult)result{
    NSString* redirectUriString = arguments[kContinueRedirectUriKey];
    NSURL *redirectUriURL = (id)redirectUriString == [NSNull null] ? nil : [NSURL URLWithString:redirectUriString];

    if (redirectUriURL && _linkHandler) {
        [_linkHandler resumeAfterTermination:redirectUriURL];
    }

    result(nil);
}

- (void) submit: (id _Nullable)arguments withResult:(FlutterResult)result{
    NSString* phoneNumber = arguments[kPhoneNumberKey];
    
    if (_linkHandler && phoneNumber) {
        PLKSubmissionData *data = [[PLKSubmissionData alloc] init];
        data.phoneNumber = phoneNumber;
        [_linkHandler submit: data];
    }
    
    result(nil);
}

-(void) syncFinanceKit: (id _Nullable)arguments withResult: (FlutterResult)result {
    NSString* token = arguments[kTokenKey];
    BOOL requestAuthorizationIfNeeded = arguments[kRequestAuthorizationIfNeeded];
    BOOL simulatedBehavior = arguments[kSimulatedBehavior];
    
    if (@available(iOS 17.4, *)) {
        
        [PLKPlaid syncFinanceKitWithToken:token requestAuthorizationIfNeeded:requestAuthorizationIfNeeded simulatedBehavior:simulatedBehavior onSuccess:^{
            result(nil);
        } onError:^(NSError *error) {
            result([FlutterError errorWithCode:[@(error.code) stringValue]
                                       message:error.localizedDescription details: nil]);
        }];
    } else {
        result([FlutterError errorWithCode:@"1001" message: @"FinanceKit Requires iOS >= 17.4" details: nil]);
    }
}

#pragma mark PLKConfiguration

- (PLKLinkTokenConfiguration*)getLinkTokenConfigurationWithToken: (NSString *)token onSuccessHandler:(PLKOnSuccessHandler)successHandler{
    return [PLKLinkTokenConfiguration createWithToken:token onSuccess:successHandler];
}

#pragma mark PLKConfiguration Parsing

+ (NSArray<NSNumber *> *)productsArrayFromProductsStringArray:(NSArray<NSString *> *)productsStringArray {
    NSMutableArray<NSNumber *> *results = [NSMutableArray arrayWithCapacity:productsStringArray.count];

    for (NSString *productString in productsStringArray) {
        NSNumber *product = [PlaidFlutterPlugin productFromProductString:productString];
        if (product) {
            [results addObject:product];
        }
    }

    return [results copy];
}

+ (NSNumber * __nullable)productFromProductString:(NSString *)productString {
    NSDictionary *productStringMap = @{
        @"auth": @(PLKProductAuth),
        @"identity": @(PLKProductIdentity),
        @"income": @(PLKProductIncome),
        @"transactions": @(PLKProductTransactions),
        @"assets": @(PLKProductAssets),
        @"liabilities": @(PLKProductLiabilities),
        @"investments": @(PLKProductInvestments),
        @"deposit_switch": @(PLKProductDepositSwitch),
        @"payment_initiation": @(PLKProductPaymentInitiation),
    };
    return productStringMap[productString.lowercaseString];
}

+ (NSArray<id<PLKAccountSubtype>> *)accountSubtypesArrayFromAccountSubtypeDictionaries:(NSArray<NSDictionary<NSString *, NSString *> *> *)accountSubtypeDictionaries {
    __block NSMutableArray<id<PLKAccountSubtype>> *results = [NSMutableArray array];

    for (NSDictionary *accountSubtypeDictionary in accountSubtypeDictionaries) {
        NSString *type = accountSubtypeDictionary[@"type"];
        NSString *subtype = accountSubtypeDictionary[@"subtype"];
        id<PLKAccountSubtype> result = [PlaidFlutterPlugin accountSubtypeFromTypeString:type subtypeString:subtype];
        if (result) {
            [results addObject:result];
        }
    }

    return [results copy];
}

+ (id<PLKAccountSubtype>)accountSubtypeFromTypeString:(NSString *)typeString
                                        subtypeString:(NSString *)subtypeString {
    NSString *normalizedTypeString = typeString.lowercaseString;
    NSString *normalizedSubtypeString = subtypeString.lowercaseString;
    if ([normalizedTypeString isEqualToString:@"other"]) {
        if ([normalizedSubtypeString isEqualToString:@"all"]) {
            return [PLKAccountSubtypeOther createWithValue:PLKAccountSubtypeValueOtherAll];
        } else if ([normalizedSubtypeString isEqualToString:@"other"]) {
            return [PLKAccountSubtypeOther createWithValue:PLKAccountSubtypeValueOtherOther];
        } else {
            return [PLKAccountSubtypeOther createWithRawStringValue:normalizedSubtypeString];
        }
    } else if ([normalizedTypeString isEqualToString:@"credit"]) {
        if ([normalizedSubtypeString isEqualToString:@"all"]) {
            return [PLKAccountSubtypeCredit createWithValue:PLKAccountSubtypeValueCreditAll];
        } else if ([normalizedSubtypeString isEqualToString:@"credit card"]) {
            return [PLKAccountSubtypeCredit createWithValue:PLKAccountSubtypeValueCreditCreditCard];
        } else if ([normalizedSubtypeString isEqualToString:@"paypal"]) {
            return [PLKAccountSubtypeCredit createWithValue:PLKAccountSubtypeValueCreditPaypal];
        } else {
            return [PLKAccountSubtypeCredit createWithUnknownValue:subtypeString];
        }
    } else if ([normalizedTypeString isEqualToString:@"loan"]) {
        if ([normalizedSubtypeString isEqualToString:@"all"]) {
            return [PLKAccountSubtypeLoan createWithValue:PLKAccountSubtypeValueLoanAll];
        } else if ([normalizedSubtypeString isEqualToString:@"auto"]) {
            return [PLKAccountSubtypeLoan createWithValue:PLKAccountSubtypeValueLoanAuto];
        } else if ([normalizedSubtypeString isEqualToString:@"business"]) {
            return [PLKAccountSubtypeLoan createWithValue:PLKAccountSubtypeValueLoanBusiness];
        } else if ([normalizedSubtypeString isEqualToString:@"commercial"]) {
            return [PLKAccountSubtypeLoan createWithValue:PLKAccountSubtypeValueLoanCommercial];
        } else if ([normalizedSubtypeString isEqualToString:@"construction"]) {
            return [PLKAccountSubtypeLoan createWithValue:PLKAccountSubtypeValueLoanConstruction];
        } else if ([normalizedSubtypeString isEqualToString:@"consumer"]) {
            return [PLKAccountSubtypeLoan createWithValue:PLKAccountSubtypeValueLoanConsumer];
        } else if ([normalizedSubtypeString isEqualToString:@"home equity"]) {
            return [PLKAccountSubtypeLoan createWithValue:PLKAccountSubtypeValueLoanHomeEquity];
        } else if ([normalizedSubtypeString isEqualToString:@"line of credit"]) {
            return [PLKAccountSubtypeLoan createWithValue:PLKAccountSubtypeValueLoanLineOfCredit];
        } else if ([normalizedSubtypeString isEqualToString:@"loan"]) {
            return [PLKAccountSubtypeLoan createWithValue:PLKAccountSubtypeValueLoanLoan];
        } else if ([normalizedSubtypeString isEqualToString:@"mortgage"]) {
            return [PLKAccountSubtypeLoan createWithValue:PLKAccountSubtypeValueLoanMortgage];
        } else if ([normalizedSubtypeString isEqualToString:@"overdraft"]) {
            return [PLKAccountSubtypeLoan createWithValue:PLKAccountSubtypeValueLoanOverdraft];
        } else if ([normalizedSubtypeString isEqualToString:@"student"]) {
            return [PLKAccountSubtypeLoan createWithValue:PLKAccountSubtypeValueLoanStudent];
        } else {
            return [PLKAccountSubtypeLoan createWithUnknownValue:subtypeString];
        }
    } else if ([normalizedTypeString isEqualToString:@"depository"]) {
        if ([normalizedSubtypeString isEqualToString:@"all"]) {
            return [PLKAccountSubtypeDepository createWithValue:PLKAccountSubtypeValueDepositoryAll];
        } else if ([normalizedSubtypeString isEqualToString:@"cash management"]) {
            return [PLKAccountSubtypeDepository createWithValue:PLKAccountSubtypeValueDepositoryCashManagement];
        } else if ([normalizedSubtypeString isEqualToString:@"cd"]) {
            return [PLKAccountSubtypeDepository createWithValue:PLKAccountSubtypeValueDepositoryCd];
        } else if ([normalizedSubtypeString isEqualToString:@"checking"]) {
            return [PLKAccountSubtypeDepository createWithValue:PLKAccountSubtypeValueDepositoryChecking];
        } else if ([normalizedSubtypeString isEqualToString:@"ebt"]) {
            return [PLKAccountSubtypeDepository createWithValue:PLKAccountSubtypeValueDepositoryEbt];
        } else if ([normalizedSubtypeString isEqualToString:@"hsa"]) {
            return [PLKAccountSubtypeDepository createWithValue:PLKAccountSubtypeValueDepositoryHsa];
        } else if ([normalizedSubtypeString isEqualToString:@"money market"]) {
            return [PLKAccountSubtypeDepository createWithValue:PLKAccountSubtypeValueDepositoryMoneyMarket];
        } else if ([normalizedSubtypeString isEqualToString:@"paypal"]) {
            return [PLKAccountSubtypeDepository createWithValue:PLKAccountSubtypeValueDepositoryPaypal];
        } else if ([normalizedSubtypeString isEqualToString:@"prepaid"]) {
            return [PLKAccountSubtypeDepository createWithValue:PLKAccountSubtypeValueDepositoryPrepaid];
        } else if ([normalizedSubtypeString isEqualToString:@"savings"]) {
            return [PLKAccountSubtypeDepository createWithValue:PLKAccountSubtypeValueDepositorySavings];
        } else {
            return [PLKAccountSubtypeDepository createWithUnknownValue:subtypeString];
        }

    } else if ([normalizedTypeString isEqualToString:@"investment"]) {
        if ([normalizedSubtypeString isEqualToString:@"all"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentAll];
        } else if ([normalizedSubtypeString isEqualToString:@"401a"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestment401a];
        } else if ([normalizedSubtypeString isEqualToString:@"401k"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestment401k];
        } else if ([normalizedSubtypeString isEqualToString:@"403B"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestment403B];
        } else if ([normalizedSubtypeString isEqualToString:@"457b"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestment457b];
        } else if ([normalizedSubtypeString isEqualToString:@"529"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestment529];
        } else if ([normalizedSubtypeString isEqualToString:@"brokerage"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentBrokerage];
        } else if ([normalizedSubtypeString isEqualToString:@"cash isa"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentCashIsa];
        } else if ([normalizedSubtypeString isEqualToString:@"education savings account"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentEducationSavingsAccount];
        } else if ([normalizedSubtypeString isEqualToString:@"fixed annuity"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentFixedAnnuity];
        } else if ([normalizedSubtypeString isEqualToString:@"gic"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentGic];
        } else if ([normalizedSubtypeString isEqualToString:@"health reimbursement arrangement"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentHealthReimbursementArrangement];
        } else if ([normalizedSubtypeString isEqualToString:@"hsa"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentHsa];
        } else if ([normalizedSubtypeString isEqualToString:@"ira"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentIra];
        } else if ([normalizedSubtypeString isEqualToString:@"isa"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentIsa];
        } else if ([normalizedSubtypeString isEqualToString:@"keogh"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentKeogh];
        } else if ([normalizedSubtypeString isEqualToString:@"lif"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentLif];
        } else if ([normalizedSubtypeString isEqualToString:@"lira"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentLira];
        } else if ([normalizedSubtypeString isEqualToString:@"lrif"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentLrif];
        } else if ([normalizedSubtypeString isEqualToString:@"lrsp"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentLrsp];
        } else if ([normalizedSubtypeString isEqualToString:@"mutual fund"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentMutualFund];
        } else if ([normalizedSubtypeString isEqualToString:@"non-taxable brokerage account"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentNonTaxableBrokerageAccount];
        } else if ([normalizedSubtypeString isEqualToString:@"pension"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentPension];
        } else if ([normalizedSubtypeString isEqualToString:@"plan"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentPlan];
        } else if ([normalizedSubtypeString isEqualToString:@"prif"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentPrif];
        } else if ([normalizedSubtypeString isEqualToString:@"profit sharing plan"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentProfitSharingPlan];
        } else if ([normalizedSubtypeString isEqualToString:@"rdsp"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentRdsp];
        } else if ([normalizedSubtypeString isEqualToString:@"resp"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentResp];
        } else if ([normalizedSubtypeString isEqualToString:@"retirement"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentRetirement];
        } else if ([normalizedSubtypeString isEqualToString:@"rlif"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentRlif];
        } else if ([normalizedSubtypeString isEqualToString:@"roth 401k"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentRoth401k];
        } else if ([normalizedSubtypeString isEqualToString:@"roth"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentRoth];
        } else if ([normalizedSubtypeString isEqualToString:@"rrif"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentRrif];
        } else if ([normalizedSubtypeString isEqualToString:@"rrsp"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentRrsp];
        } else if ([normalizedSubtypeString isEqualToString:@"sarsep"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentSarsep];
        } else if ([normalizedSubtypeString isEqualToString:@"sep ira"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentSepIra];
        } else if ([normalizedSubtypeString isEqualToString:@"simple ira"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentSimpleIra];
        } else if ([normalizedSubtypeString isEqualToString:@"sipp"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentSipp];
        } else if ([normalizedSubtypeString isEqualToString:@"stock plan"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentStockPlan];
        } else if ([normalizedSubtypeString isEqualToString:@"tfsa"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentTfsa];
        } else if ([normalizedSubtypeString isEqualToString:@"thrift savings plan"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentThriftSavingsPlan];
        } else if ([normalizedSubtypeString isEqualToString:@"trust"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentTrust];
        } else if ([normalizedSubtypeString isEqualToString:@"ugma"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentUgma];
        } else if ([normalizedSubtypeString isEqualToString:@"utma"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentUtma];
        } else if ([normalizedSubtypeString isEqualToString:@"variable annuity"]) {
          return [PLKAccountSubtypeInvestment createWithValue:PLKAccountSubtypeValueInvestmentVariableAnnuity];
        } else {
          return [PLKAccountSubtypeInvestment createWithUnknownValue:subtypeString];
        }
    }

    return [PLKAccountSubtypeUnknown createWithRawTypeStringValue:typeString rawSubtypeStringValue:subtypeString];
}

#pragma mark Metadata Parsing

+ (NSDictionary *)dictionaryFromSuccessMetadata:(PLKSuccessMetadata *)metadata {
    return @{
        @"linkSessionId": metadata.linkSessionID ?: @"",
        @"institution": [PlaidFlutterPlugin dictionaryFromInstitution:metadata.institution] ?: @"",
        @"accounts": [PlaidFlutterPlugin accountsDictionariesFromAccounts:metadata.accounts] ?: @[],
        @"metadataJson": metadata.metadataJSON ?: @"",
    };
}

+ (NSDictionary *)dictionaryFromEventMetadata:(PLKEventMetadata *)metadata {
    return @{
        @"errorType": [PlaidFlutterPlugin errorTypeStringFromError:metadata.error] ?: @"",
        @"errorCode": [PlaidFlutterPlugin errorCodeStringFromError:metadata.error] ?: @"",
        @"errorMessage": [PlaidFlutterPlugin errorMessageFromError:metadata.error] ?: @"",
        @"exitStatus": [PlaidFlutterPlugin stringForExitStatus:metadata.exitStatus] ?: @"",
        @"institutionId": metadata.institutionID ?: @"",
        @"institutionName": metadata.institutionName ?: @"",
        @"institutionSearchQuery": metadata.institutionSearchQuery ?: @"",
        @"linkSessionId": metadata.linkSessionID ?: @"",
        @"mfaType": [PlaidFlutterPlugin stringForMfaType:metadata.mfaType] ?: @"",
        @"requestId": metadata.requestID ?: @"",
        @"timestamp": [PlaidFlutterPlugin iso8601StringFromDate:metadata.timestamp] ?: @"",
        @"viewName": [PlaidFlutterPlugin stringForViewName:metadata.viewName] ?: @"",
        @"metadataJson": metadata.metadataJSON ?: @"",
        @"accountNumberMask": metadata.accountNumberMask ?: @"",
        @"isUpdateMode": metadata.isUpdateMode ?: @"",
        @"matchReason": metadata.matchReason ?: @"",
        @"routingNumber": metadata.routingNumber ?: @"",
        @"selection": metadata.selection ?: @"",
    };
}

+ (NSDictionary *)dictionaryFromExitMetadata:(PLKExitMetadata *)metadata {
    return @{
        @"status": [PlaidFlutterPlugin stringForExitStatus:metadata.status] ?: @"",
        @"institution": [PlaidFlutterPlugin dictionaryFromInstitution:metadata.institution],
        @"requestId": metadata.requestID ?: @"",
        @"linkSessionId": metadata.linkSessionID ?: @"",
        @"metadataJson": metadata.metadataJSON ?: @"",
    };
}

+ (NSDictionary *)dictionaryFromError:(PLKExitError *)error {
    return @{
        @"errorType": [PlaidFlutterPlugin errorTypeStringFromError:error] ?: @"",
        @"errorCode": [PlaidFlutterPlugin errorCodeStringFromError:error] ?: @"",
        @"errorMessage": [PlaidFlutterPlugin errorMessageFromError:error] ?: @"",
        @"errorDisplayMessage": [PlaidFlutterPlugin errorDisplayMessageFromError:error] ?: @"",
    };
}

+ (NSDictionary *)dictionaryFromInstitution:(PLKInstitution *)institution {
    return @{
        @"name": institution.name ?: @"",
        @"id": institution.ID ?: @"",
    };
}

+ (NSDictionary *)dictionaryFromAccount:(PLKAccount *)account {
    return @{
        @"id": account.ID ?: @"",
        @"name": account.name ?: @"",
        @"mask": account.mask ?: @"",
        @"subtype": [PlaidFlutterPlugin subtypeNameForAccountSubtype:account.subtype] ?: @"",
        @"type": [PlaidFlutterPlugin typeNameForAccountSubtype:account.subtype] ?: @"",
        @"verificationStatus": [PlaidFlutterPlugin stringForVerificationStatus:account.verificationStatus] ?: @"",
    };
}

+ (NSArray<NSDictionary *> *)accountsDictionariesFromAccounts:(NSArray<PLKAccount *> *)accounts {
    NSMutableArray<NSDictionary *> *results = [NSMutableArray arrayWithCapacity:accounts.count];

    for (PLKAccount *account in accounts) {
        NSDictionary *accountDictionary = [PlaidFlutterPlugin dictionaryFromAccount:account];
        [results addObject:accountDictionary];
    }

    return [results copy];
}

+ (NSString *)typeNameForAccountSubtype:(id<PLKAccountSubtype>)accountSubtype {
    if ([accountSubtype isKindOfClass:[PLKAccountSubtypeUnknown class]]) {
        return ((PLKAccountSubtypeUnknown *)accountSubtype).rawStringValue;
    } else if ([accountSubtype isKindOfClass:[PLKAccountSubtypeOther class]]) {
        return @"other";
    } else if ([accountSubtype isKindOfClass:[PLKAccountSubtypeCredit class]]) {
        return @"credit";
    }  else if ([accountSubtype isKindOfClass:[PLKAccountSubtypeLoan class]]) {
        return @"loan";
    }  else if ([accountSubtype isKindOfClass:[PLKAccountSubtypeDepository class]]) {
        return @"depository";
    }  else if ([accountSubtype isKindOfClass:[PLKAccountSubtypeInvestment class]]) {
        return @"investment";
    }
    return @"unknown";
}

+ (NSString *)subtypeNameForAccountSubtype:(id<PLKAccountSubtype>)accountSubtype {
    if ([accountSubtype isKindOfClass:[PLKAccountSubtypeUnknown class]]) {
        return ((PLKAccountSubtypeUnknown *)accountSubtype).rawSubtypeStringValue;
    }
    return accountSubtype.rawStringValue;
}

+ (NSString *)stringForEventName:(PLKEventName *)eventName {
    if (!eventName) {
        return @"";
    }

    if (eventName.unknownStringValue) {
        return eventName.unknownStringValue;
    }

    switch (eventName.value) {
        case PLKEventNameValueNone:
            return @"";
        case PLKEventNameValueBankIncomeInsightsCompleted:
            return @"BANK_INCOME_INSIGHTS_COMPLETED";
        case PLKEventNameValueCloseOAuth:
            return @"CLOSE_OAUTH";
        case PLKEventNameValueError:
            return @"ERROR";
        case PLKEventNameValueExit:
            return @"EXIT";
        case PLKEventNameValueFailOAuth:
            return @"FAIL_OAUTH";
        case PLKEventNameValueHandoff:
            return @"HANDOFF";
        case PLKEventNameValueIdentityVerificationStartStep:
            return @"IDENTITY_VERIFICATION_START_STEP";
        case PLKEventNameValueIdentityVerificationPassStep:
            return @"IDENTITY_VERIFICATION_PASS_STEP";
        case PLKEventNameValueIdentityVerificationFailStep:
            return @"IDENTITY_VERIFICATION_FAIL_STEP";
        case PLKEventNameValueIdentityVerificationPendingReviewStep:
            return @"IDENTITY_VERIFICATION_PENDING_REVIEW_STEP";
        case PLKEventNameValueIdentityVerificationCreateSession:
            return @"IDENTITY_VERIFICATION_CREATE_SESSION";
        case PLKEventNameValueIdentityVerificationResumeSession:
            return @"IDENTITY_VERIFICATION_RESUME_SESSION";
        case PLKEventNameValueIdentityVerificationPassSession:
            return @"IDENTITY_VERIFICATION_PASS_SESSION";
        case PLKEventNameValueIdentityVerificationFailSession:
            return @"IDENTITY_VERIFICATION_FAIL_SESSION";
        case PLKEventNameValueIdentityVerificationOpenUI:
            return @"IDENTITY_VERIFICATION_OPEN_UI";
        case PLKEventNameValueIdentityVerificationResumeUI:
            return @"IDENTITY_VERIFICATION_RESUME_UI";
        case PLKEventNameValueIdentityVerificationCloseUI:
            return @"IDENTITY_VERIFICATION_CLOSE_UI";
        case PLKEventNameValueMatchedSelectInstitution:
            return @"MATCHED_SELECT_INSTITUTION";
        case PLKEventNameValueMatchedSelectVerifyMethod:
            return @"MATCHED_SELECT_VERIFY_METHOD";
        case PLKEventNameValueOpen:
            return @"OPEN";
        case PLKEventNameValueOpenMyPlaid:
            return @"OPEN_MY_PLAID";
        case PLKEventNameValueOpenOAuth:
            return @"OPEN_OAUTH";
        case PLKEventNameValueSearchInstitution:
            return @"SEARCH_INSTITUTION";
        case PLKEventNameValueSelectInstitution:
            return @"SELECT_INSTITUTION";
        case PLKEventNameValueSubmitCredentials:
            return @"SUBMIT_CREDENTIALS";
        case PLKEventNameValueSubmitMFA:
            return @"SUBMIT_MFA";
        case PLKEventNameValueTransitionView:
            return @"TRANSITION_VIEW";
        case PLKEventNameValueSelectDegradedInstitution:
            return @"SELECT_DEGRADED_INSTITUTION";
        case PLKEventNameValueSelectDownInstitution:
            return @"SELECT_DOWN_INSTITUTION";
        case PLKEventNameValueIdentityVerificationPendingReviewSession:
            return @"IDENTITY_VERIFICATION_PENDING_REVIEW_SESSION";
        case PLKEventNameValueSelectFilteredInstitution:
            return @"SELECT_FILTERED_INSTITUTION";
        case PLKEventNameValueSelectBrand:
            return @"SELECT_BRAND";
        case PLKEventNameValueSelectAuthType:
            return @"SELECT_AUTH_TYPE";
        case PLKEventNameValueSubmitAccountNumber:
            return @"SUBMIT_ACCOUNT_NUMBER";
        case PLKEventNameValueSubmitDocuments:
            return @"SUBMIT_DOCUMENTS";
        case PLKEventNameValueSubmitDocumentsSuccess:
            return @"SUBMIT_DOCUMENTS_SUCCESS";
        case PLKEventNameValueSubmitDocumentsError:
            return @"SUBMIT_DOCUMENTS_ERROR";
        case PLKEventNameValueSubmitRoutingNumber:
            return @"SUBMIT_ROUTING_NUMBER";
        case PLKEventNameValueViewDataTypes:
            return @"VIEW_DATA_TYPES";
        case PLKEventNameValueSubmitPhone:
            return @"SUBMIT_PHONE";
        case PLKEventNameValueSkipSubmitPhone:
            return @"SKIP_SUBMIT_PHONE";
        case PLKEventNameValueVerifyPhone:
            return @"VERIFY_PHONE";
        case PLKEventNameValueConnectNewInstitution:
            return @"CONNECT_NEW_INSTITUTION";
        case PLKEventNameValueProfileEligibilityCheckReady:
            return @"PROFILE_ELIGIBILITY_CHECK_READY";
        case PLKEventNameValueProfileEligibilityCheckError:
            return @"PROFILE_ELIGIBILITY_CHECK_ERROR";
        case PLKEventNameValueSubmitOTP:
            return @"SUBMIT_OTP";
        case PLKEventNameValueLayerReady:
            return @"LAYER_READY";
        case PLKEventNameValueLayerNotAvailable:
            return @"LAYER_NOT_AVAILABLE";
        case PLKEventNameValueSubmitEmail:
            return @"SUBMIT_EMAIL";
        case PLKEventNameValueSkipSubmitEmail:
            return @"SKIP_SUBMIT_EMAIL";
        case PLKEventNameValueRememberMeEnabled:
            return @"REMEMBER_ME_ENABLED";
        case PLKEventNameValueRememberMeDisabled:
            return @"REMEMBER_ME_DISABLED";
        case PLKEventNameValueRememberMeHoldout:
            return @"REMEMBER_ME_HOLDOUT";
        case PLKEventNameValueSelectSavedInstitution:
            return @"SELECT_SAVED_INSTITUTION";
        case PLKEventNameValueSelectSavedAccount:
            return @"SELECT_SAVED_ACCOUNT";
        case PLKEventNameValueAutoSelectSavedInstitution:
            return @"AUTO_SELECT_SAVED_INSTITUTION";
        case PLKEventNameValuePlaidCheckPane:
            return @"PLAID_CHECK_PANE";
        case PLKEventNameValueAutoSubmitPhone:
            return @"AUTO_SUBMIT_PHONE";
        case PLKEventNameValueIdentityMatchPassed:
            return @"IDENTITY_MATCH_PASSED";
        case PLKEventNameValueIdentityMatchFailed:
            return @"IDENTITY_MATCH_FAILED";
        case PLKEventNameValueIssueFollowed:
            return @"ISSUE_FOLLOWED";
        case PLKEventNameValueSelectAccount:
            return @"SELECT_ACCOUNT";
        case PLKEventNameValueLayerAutoFillNotAvailable:
            return @"LAYER_AUTO_FILL_NOT_AVAILABLE";

    }
     return @"unknown";
}

+ (NSString *)stringForMfaType:(PLKMFAType)mfaType {
    switch (mfaType) {
        case PLKMFATypeNone:
            return @"";
        case PLKMFATypeCode:
            return @"code";
        case PLKMFATypeDevice:
            return @"device";
        case PLKMFATypeQuestions:
            return @"questions";
        case PLKMFATypeSelections:
            return @"selections";
    }

    return @"unknown";
}

+ (NSString *)stringForExitStatus:(PLKExitStatus *)exitStatus {
    if (!exitStatus) {
        return @"";
    }

    if (exitStatus.unknownStringValue) {
        return exitStatus.unknownStringValue;
    }

    switch (exitStatus.value) {
        case PLKExitStatusValueNone:
            return @"";
        case PLKExitStatusValueRequiresQuestions:
            return @"requires_questions";
        case PLKExitStatusValueRequiresSelections:
            return @"requires_selections";
        case PLKExitStatusValueRequiresCode:
            return @"requires_code";
        case PLKExitStatusValueChooseDevice:
            return @"choose_device";
        case PLKExitStatusValueRequiresCredentials:
            return @"requires_credentials";
        case PLKExitStatusValueInstitutionNotFound:
            return @"institution_not_found";
        case PLKExitStatusValueRequiresAccountSelection:
            return @"requires_account_selection";
        case PLKExitStatusValueContinueToThridParty:
            return @"continue_to_thrid_party";
    }
    return @"unknown";
}

+ (NSString *)stringForViewName:(PLKViewName *)viewName {
    if (!viewName) {
        return @"";
    }

    if (viewName.unknownStringValue) {
        return viewName.unknownStringValue;
    }

    switch (viewName.value) {
        case PLKViewNameValueNone:
            return @"";
        case PLKViewNameValueAcceptTOS:
            return @"ACCEPT_TOS";
        case PLKViewNameValueConnected:
            return @"CONNECTED";
        case PLKViewNameValueConsent:
            return @"CONSENT";
        case PLKViewNameValueCredential:
            return @"CREDENTIAL";
        case PLKViewNameValueDocumentaryVerification:
            return @"DOCUMENTARY_VERIFICATION";
        case PLKViewNameValueError:
            return @"ERROR";
        case PLKViewNameValueExit:
            return @"EXIT";
        case PLKViewNameValueKYCCheck:
            return @"KYC_CHECK";
        case PLKViewNameValueLoading:
            return @"LOADING";
        case PLKViewNameValueMatchedConsent:
            return @"MATCHED_CONSENT";
        case PLKViewNameValueMatchedCredential:
            return @"MATCHED_CREDENTIAL";
        case PLKViewNameValueMatchedMFA:
            return @"MATCHED_MFA";
        case PLKViewNameValueMFA:
            return @"MFA";
        case PLKViewNameValueNumbers:
            return @"NUMBERS";
        case PLKViewNameValueOauth:
            return @"OAUTH";
        case PLKViewNameValueRecaptcha:
            return @"RECAPTCHA";
        case PLKViewNameValueRiskCheck:
            return @"RISK_CHECK";
        case PLKViewNameValueScreening:
            return @"SCREENING";
        case PLKViewNameValueSelectAccount:
            return @"SELECT_ACCOUNT";
        case PLKViewNameValueSelectInstitution:
            return @"SELECT_INSTITUTION";
        case PLKViewNameValueSelfieCheck:
            return @"SELFIE_CHECK";
        case PLKViewNameValueSubmitDocuments:
            return @"SUBMIT_DOCUMENTS";
        case PLKViewNameValueSubmitDocumentsSuccess:
            return @"SUBMIT_DOCUMENTS_SUCCESS";
        case PLKViewNameValueSubmitDocumentsError:
            return @"SUBMIT_DOCUMENTS_ERROR";
        case PLKViewNameValueUploadDocuments:
            return @"UPLOAD_DOCUMENTS";
        case PLKViewNameValueVerifySMS:
            return @"VERIFY_SMS";
        case PLKViewNameValueDataTransparency:
            return @"DATA_TRANSPARENCY";
        case PLKViewNameValueDataTransparencyConsent:
            return @"DATA_TRANSPARENCY_CONSENT";
        case PLKViewNameValueSelectAuthType:
            return @"SELECT_AUTH_TYPE";
        case PLKViewNameValueSelectBrand:
            return @"SELECT_BRAND";
        case PLKViewNameValueNumbersSelectInstitution:
            return @"NUMBERS_SELECT_INSTITUTION";
        case PLKViewNameValueSubmitPhone:
            return @"SUBMIT_PHONE";
        case PLKViewNameValueVerifyPhone:
            return @"VERIFY_PHONE";
        case PLKViewNameValueSelectSavedInstitution:
            return @"SELECT_SAVED_INSTITUTION";
        case PLKViewNameValueSelectSavedAccount:
            return @"SELECT_SAVED_ACCOUNT";
        case PLKViewNameValueProfileDataReview:
            return @"PROFILE_DATA_REVIEW";
        case PLKViewNameValueSubmitEmail:
            return @"SUBMIT_EMAIL";
        case PLKViewNameValueVerifyEmail:
            return @"VERIFY_EMAIL";
    }

    return @"unknown";
}

+ (NSString *)stringForVerificationStatus:(PLKVerificationStatus *)verificationStatus {
    if (!verificationStatus) {
        return @"";
    }

    if (verificationStatus.unknownStringValue) {
        return verificationStatus.unknownStringValue;
    }

    switch (verificationStatus.value) {
        case PLKVerificationStatusValueNone:
            return @"";
        case PLKVerificationStatusValuePendingAutomaticVerification:
            return @"pending_automatic_verification";
        case PLKVerificationStatusValuePendingManualVerification:
            return @"pending_manual_verification";
        case PLKVerificationStatusValueManuallyVerified:
            return @"manually_verified";
    }

    return @"unknown";
}

+ (NSString *)errorDisplayMessageFromError:(PLKExitError *)error {
    return error.userInfo[kPLKExitErrorDisplayMessageKey] ?: @"";
}

+ (NSString *)errorTypeStringFromError:(PLKExitError *)error {
    NSString *errorDomain = error.domain;
    if (!error || !errorDomain) {
        return @"";
    }

    NSString *normalizedErrorDomain = errorDomain;

    return @{
        kPLKExitErrorInvalidRequestDomain: @"INVALID_REQUEST",
        kPLKExitErrorInvalidInputDomain: @"INVALID_INPUT",
        kPLKExitErrorInstitutionErrorDomain: @"INSTITUTION_ERROR",
        kPLKExitErrorRateLimitExceededDomain: @"RATE_LIMIT_EXCEEDED",
        kPLKExitErrorApiDomain: @"API_ERROR",
        kPLKExitErrorItemDomain: @"ITEM_ERROR",
        kPLKExitErrorAuthDomain: @"AUTH_ERROR",
        kPLKExitErrorAssetReportDomain: @"ASSET_REPORT_ERROR",
        kPLKExitErrorInternalDomain: @"INTERNAL",
        kPLKExitErrorUnknownDomain: error.userInfo[kPLKExitErrorUnknownTypeKey] ?: @"UNKNOWN",
    }[normalizedErrorDomain] ?: @"UNKNOWN";
}

+ (NSString *)errorCodeStringFromError:(PLKExitError *)error {
   NSString *errorDomain = error.domain;

    if (!error || !errorDomain) {
        return @"";
    }
    return error.userInfo[kPLKExitErrorCodeKey];
}

+ (NSString *)errorMessageFromError:(PLKExitError *)error {
    return error.userInfo[kPLKExitErrorMessageKey] ?: @"";
}

+ (NSString *)iso8601StringFromDate:(NSDate *)date {
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithAbbreviation: @"GMT"];
    NSISO8601DateFormatOptions options = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithDashSeparatorInDate | NSISO8601DateFormatWithColonSeparatorInTime | NSISO8601DateFormatWithTimeZone;

    return [NSISO8601DateFormatter stringFromDate:date timeZone:timeZone formatOptions:options];
}

@end
