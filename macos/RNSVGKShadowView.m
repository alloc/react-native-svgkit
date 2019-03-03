#import "RNSVGKShadowView.h"

#import <React/RCTLog.h>

@implementation RNSVGKShadowView

- (BOOL)isYogaLeafNode
{
  return YES;
}

- (BOOL)canHaveSubviews
{
  return NO;
}

@end
