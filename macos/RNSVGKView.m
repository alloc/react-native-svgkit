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
    // Avoid resizing before updating the image.
    _ignoreResize = YES;

    RCTBridge *bridge = _bridge;
    RCTExecuteOnUIManagerQueue(^{
      if (image.hasSize) {
        RCTShadowView *shadowView = [bridge.uiManager shadowViewForReactTag:self.reactTag];
        shadowView.intrinsicContentSize = image.size;
      }

      [bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,NSView *> *viewRegistry) {
        self->_ignoreResize = NO;
        if (image == self->_image) {
          [self updateImageView:image.SVGKImage];

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
        }
      }];

      // Run our UI block asap.
      [bridge.uiManager setNeedsLayout];
    });
  }
}

- (void)updateImageView:(SVGKImage *)image
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

  [self resizeImage];
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
    [self updateImageView:image];
  }
}

- (void)resizeImage
{
  RCTAssertMainQueue();
  if (_imageView) {
    NSSize maxSize = self.frame.size;

    // Fit the frame exactly by default.
    NSSize size = maxSize;
    CGFloat scale = 1;

    SVGKImage *image = _imageView.image;
    if (image.hasSize) {
      NSSize imageSize = image.size;

      CGFloat widthRatio = maxSize.width / imageSize.width;
      CGFloat heightRatio = maxSize.height / imageSize.height;

      if (widthRatio > heightRatio) {
        size = (CGSize){imageSize.width * heightRatio, maxSize.height};
      } else {
        size = (CGSize){maxSize.width, imageSize.height * widthRatio};
      }

      if (_tintColor) {
        scale = size.width / imageSize.width;
      }
    }

    _imageView.frame = (NSRect){
      { (maxSize.width - size.width) / 2,
        (maxSize.height - size.height) / 2 },
      size
    };

    // SVGKLayeredImageView does not scale its layers automatically.
    if (_tintColor) {
      [CALayer performWithoutAnimation:^{
        CALayer *layer = image.CALayerTree;
        layer.position = (NSPoint){size.width / 2, size.height / 2};
        layer.affineTransform = CGAffineTransformMakeScale(scale, scale);
      }];
    }
  }
}

- (void)setFrame:(NSRect)frame
{
  [super setFrame:frame];
  if (_ignoreResize == NO) {
    [self resizeImage];
  }
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
