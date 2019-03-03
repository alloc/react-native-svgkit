#import "SVGKImageView+Tint.h"

@implementation SVGKImageView (Tint)

- (void)setTintColor:(NSColor *)tintColor
{
  CALayer *rootLayer = self.image.CALayerTree;
  if (rootLayer) {
    [self _applyTintColor:tintColor toLayers:rootLayer.sublayers];
  }
}

- (void)_applyTintColor:(NSColor *)tintColor toLayers:(NSArray<CALayer *> *)layers
{
  for (CALayer *layer in layers) {
    if ([layer isKindOfClass:[CAShapeLayer class]]) {
      CAShapeLayer *shape = (CAShapeLayer *)layer;
      if (shape.strokeColor) {
        shape.strokeColor = tintColor.CGColor;
      }
      if (shape.fillColor) {
        shape.fillColor = tintColor.CGColor;
      }
    }
    [self _applyTintColor:tintColor toLayers:layer.sublayers];
  }
}

@end
