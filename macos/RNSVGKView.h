#import <AppKit/AppKit.h>
#import <React/RCTBridge.h>
#import <React/RCTImageSource.h>

@interface RNSVGKView : NSView

- (instancetype)initWithBridge:(RCTBridge *)bridge NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) RCTImageSource *source;
@property (nonatomic, copy) NSColor *tintColor;

@end
