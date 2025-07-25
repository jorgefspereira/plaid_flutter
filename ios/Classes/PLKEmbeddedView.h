#import <Flutter/Flutter.h>
#import "PLKEventEmitterProtocol.h"

@interface PLKEmbeddedViewFactory : NSObject <FlutterPlatformViewFactory>
- (instancetype _Nullable)initWithMessenger:(NSObject<FlutterBinaryMessenger>* _Nullable)messenger emitter:(id<PLKEventEmitter>_Nonnull)emitter;
@end

@interface PLKEmbeddedView : NSObject <FlutterPlatformView>

- (instancetype _Nullable)initWithFrame:(CGRect)frame
                         viewIdentifier:(int64_t)viewId
                              arguments:(id _Nullable)args
                        binaryMessenger:(NSObject<FlutterBinaryMessenger>* _Nullable)messenger
                                emitter:(id<PLKEventEmitter>_Nonnull)emitter;

- (UIView* _Nonnull)view;
@end
