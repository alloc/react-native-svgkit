#import "RNSVGKView.h"
#import "RNSVGKImageCache.h"
#import "SVGKImageView+Tint.h"
#import "SVGKit.h"

#import <React/NSView+React.h>
#import <React/RCTNetworking.h>
#import <React/RCTShadowView.h>
#import <React/RCTUIManager.h>
#import <React/RCTUIManagerUtils.h>

@interface RNSVGKView () <RNSVGKImageObserver>

@property (nonatomic, copy) RCTDirectEventBlock onLoadStart;
@property (nonatomic, copy) RCTDirectEventBlock onError;
@property (nonatomic, copy) RCTDirectEventBlock onLoad;
@property (nonatomic, copy) RCTDirectEventBlock onLoadEnd;

@end

@implementation RNSVGKView
{
  RCTBridge *_bridge;
  RNSVGKImage *_image;
  SVGKImageView *_imageView;
  BOOL _isMeasuringImage;
  BOOL _isImageMeasured;
  BOOL _ignoreResize;
}

- (instancetype)initWithBridge:(RCTBridge *)bridge
{
  if (self = [super initWithFrame:NSZeroRect]) {
    _bridge = bridge;
  }
  return self;
}

RCT_NOT_IMPLEMENTED(- (instancetype)initWithCoder:(NSCoder *)decoder)
RCT_NOT_IMPLEMENTED(- (instancetype)initWithFrame:(NSRect)frameRect)

- (void)didSetProps:(NSArray<NSString *> *)changedProps
{
  RNSVGKImage *image;

  // The "data" prop always overrides the "source" prop.
  if (_data) {
    if ([changedProps containsObject:@"data"]) {
      image = [_bridge.svgCache parseSvg:_data cacheKey:_cacheKey];
    }
  } else if (_source) {
    if ([changedProps containsObject:@"source"]) {
      image = [_bridge.svgCache loadSource:_source cacheKey:_cacheKey];
      if (_onLoadStart) {
        _onLoadStart(nil);
      }
    }
  } else if (_cacheKey) {
    if ([changedProps containsObject:@"cacheKey"]) {
      image = _bridge.svgCache.images[_cacheKey];
    }
  }

  // Remove the previous image while loading.
  if (!image || !image.isLoaded) {
    [self removeImage];
  }

  if (image) {
    _image = image;
    [image addObserver:self];

    // Display instantly if cached.
    if (image.isLoaded) {
      [self svgImageDidLoad:image];
    }
  }
}

- (void)svgImageDidLoad:(RNSVGKImage *)image
{
  RCTAssertMainQueue();

  // Ensure the source didn't change while loading.
  if (image != _image) {
    return;
  }

  if (image.error) {
    if (_onError) {
      _onError(@{
        @"error": image.error.localizedDescription,
      });
    }
    if (_source && _onLoadEnd) {
      _onLoadEnd(nil);
    }
  } else {
    _isImageMeasured = NO;

    SVGKImage *rawImage = image.SVGKImage;
    void (^didLoad)(void) = ^{
      [self renderImage:rawImage];

      RCTImageSource *source = self->_source;
      if (source == nil) {
        return;
      }

      if (self->_onLoad) {
        self->_onLoad(@{
          @"source": @{
            @"width": @(source.size.width),
            @"height": @(source.size.height),
            @"url": source.request.URL.absoluteString,
          },
        });
      }
      if (self->_onLoadEnd) {
        self->_onLoadEnd(nil);
      }
    };

    if (CGSizeEqualToSize(self.frame.size, CGSizeZero)) {
      return didLoad();
    }

    // Disable "setFrame:" sync while measuring the image.
    _ignoreResize = YES;
    [self measureImage:rawImage
       sizeConstraints:self.frame.size
      completionBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,NSView *> *viewRegistry) {
        self->_ignoreResize = NO;
        if (image == self->_image) {
          didLoad();
        }
      }];
  }
}

- (void)measureImage:(SVGKImage *)image
     sizeConstraints:(NSSize)parentSize
     completionBlock:(RCTViewManagerUIBlock)uiBlock
{
  RCTAssertMainQueue();
  _isMeasuringImage = YES;

  RCTBridge *bridge = _bridge;
  RCTExecuteOnUIManagerQueue(^{
    if (image.hasSize) {
      RCTShadowView *shadowView = [bridge.uiManager shadowViewForReactTag:self.reactTag];

      BOOL isWidthZero = (YGFloatIsUndefined(shadowView.width.value) && parentSize.width == 0);
      BOOL isHeightZero = (YGFloatIsUndefined(shadowView.height.value) && parentSize.height == 0);
      if (isWidthZero != isHeightZero && (isWidthZero || isHeightZero)) {
        shadowView.intrinsicContentSize = [self getImageSize:image
                                                     maxSize:parentSize
                                                       scale:nil];

        RCTLog(@"RNSVGKView(%p).intrinsicContentSize = %@", self, NSStringFromSize(shadowView.intrinsicContentSize));
      }
    }

    [bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,NSView *> *viewRegistry) {
      self->_isMeasuringImage = NO;
      self->_isImageMeasured = YES;
      uiBlock(uiManager, viewRegistry);
    }];

    // Run our UI block asap.
    [bridge.uiManager setNeedsLayout];
  });
}

- (void)renderImage:(SVGKImage *)image
{
  RCTAssertMainQueue();
  if (_imageView.superview) {
    [_imageView removeFromSuperview];
  }

  if (_tintColor) {
    _imageView = [[SVGKLayeredImageView alloc] initWithSVGKImage:image];
    [_imageView setTintColor:_tintColor];
  } else {
    _imageView = [[SVGKFastImageView alloc] initWithSVGKImage:image];
  }

  [self resizeImageView];
  [self addSubview:_imageView];
}

- (void)setTintColor:(NSColor *)tintColor
{
  BOOL wasTinted = _tintColor != nil;
  _tintColor = tintColor;

  if (_imageView) {
    SVGKImage *image = _imageView.image;

    if (wasTinted) {
      if (tintColor) {
        // Retint the current image view.
        [_imageView setTintColor:tintColor];
        return;
      }
      // Clone the image to create an untinted CALayer tree.
      image = _image.SVGKImage;
    }

    // Replace the image view when tint is added or removed.
    [self renderImage:image];
  }
}

- (void)resizeImageView
{
  RCTAssertMainQueue();
  if (_imageView) {
    CGFloat scale = 1;
    NSSize maxSize = self.frame.size;
    NSSize size = [self getImageSize:_imageView.image
                             maxSize:maxSize
                               scale:&scale];

    _imageView.frame = (NSRect){
      { MAX(0, (maxSize.width - size.width) / 2),
        MAX(0, (maxSize.height - size.height) / 2) },
      size
    };

    // SVGKLayeredImageView does not scale its layers automatically.
    if (_tintColor) {
      [CALayer performWithoutAnimation:^{
        CALayer *layer = self->_imageView.image.CALayerTree;
        layer.position = (NSPoint){size.width / 2, size.height / 2};
        layer.affineTransform = CGAffineTransformMakeScale(scale, scale);
      }];
    }
  }
}

- (NSSize)getImageSize:(SVGKImage *)image maxSize:(NSSize)maxSize scale:(CGFloat *)scale
{
  if (image.hasSize) {
    NSSize size = image.size;
    CGFloat imageWidth = size.width;

    if (maxSize.width == 0) {
      maxSize.width = INFINITY;
    }
    if (maxSize.height == 0) {
      maxSize.height = INFINITY;
    }

    if (maxSize.width < INFINITY || maxSize.height < INFINITY) {
      CGFloat widthRatio = maxSize.width / size.width;
      CGFloat heightRatio = maxSize.height / size.height;

      if (widthRatio > heightRatio) {
        size = (CGSize){size.width * heightRatio, maxSize.height};
      } else {
        size = (CGSize){maxSize.width, size.height * widthRatio};
      }
    }

    if (scale) {
      *scale = size.width / imageWidth;
    }
    return size;
  }

  // Fit the frame exactly by default.
  return maxSize;
}

- (void)setFrame:(NSRect)frame
{
  [super setFrame:frame];
  if (_isMeasuringImage) {
    return;
  }
  if (_isImageMeasured) {
    return [self resizeImageView];
  }
  if (CGSizeEqualToSize(frame.size, CGSizeZero)) {
    return; // No point in measuring without a size constraint.
  }
  RNSVGKImage *image = _image;
  [self measureImage:_imageView.image
     sizeConstraints:frame.size
    completionBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,NSView *> *viewRegistry) {
      if (image == self->_image) {
        if (CGRectEqualToRect(frame, self.frame)) {
          [self resizeImageView];
        } else {
          self->_isImageMeasured = NO;
          self.frame = self.frame;
        }
      }
    }];
}

- (void)removeImage
{
  RCTAssertMainQueue();
  if (_image) {
    [_image removeObserver:self];
    _image = nil;

    if (_imageView) {
      [_imageView removeFromSuperview];
      _imageView = nil;
    }
  }
}

- (void)viewDidMoveToWindow
{
  if (self.window == nil) {
    [_image removeObserver:self];
  }
}

@end
