#import <Flutter/Flutter.h>
#import <LinkKit/LinkKit.h>

@interface PlaidFlutterPlugin : NSObject<FlutterPlugin>

+ (NSDictionary *_Nonnull)dictionaryFromSuccessMetadata:(PLKSuccessMetadata *_Nonnull)metadata;
+ (NSDictionary *_Nonnull)dictionaryFromEventMetadata:(PLKEventMetadata *_Nonnull)metadata;
+ (NSDictionary *_Nonnull)dictionaryFromExitMetadata:(PLKExitMetadata *_Nonnull)metadata;
+ (NSDictionary *_Nonnull)dictionaryFromError:(PLKExitError *_Nonnull)error;
+ (NSString *_Nonnull)stringForEventName:(PLKEventName *_Nonnull)eventName;
@end
