#import <AppKit/AppKit.h>
#import <React/RCTBridge.h>
#import <React/RCTImageSource.h>
#import <React/RCTResizeMode.h>

@interface RNSVGKView : NSView

- (instancetype)initWithBridge:(RCTBridge *)bridge NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) RCTImageSource *source;
@property (nonatomic, assign) RCTResizeMode resizeMode;
@property (nonatomic, assign) NSPoint anchorPoint;
@property (nonatomic, copy) NSColor *tintColor;
@property (nonatomic, copy) NSString *cacheKey;

@end
