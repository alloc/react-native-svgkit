#import "RNSVGKViewManager.h"
#import "RNSVGKShadowView.h"
#import "RNSVGKView.h"

@implementation RNSVGKViewManager

RCT_EXPORT_MODULE()

- (RCTShadowView *)shadowView
{
  return [RNSVGKShadowView new];
}

- (NSView *)view
{
  return [[RNSVGKView alloc] initWithBridge:self.bridge];
}

RCT_EXPORT_VIEW_PROPERTY(data, NSData)
RCT_EXPORT_VIEW_PROPERTY(source, RCTImageSource)
RCT_EXPORT_VIEW_PROPERTY(tintColor, NSColor)

RCT_EXPORT_VIEW_PROPERTY(onLoadStart, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onError, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onLoad, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onLoadEnd, RCTDirectEventBlock)

@end
