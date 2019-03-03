#import "RNSVGKView.h"
#import "SVGKit.h"
#import "SVGKImageView+Tint.h"

#import <React/NSView+React.h>
#import <React/RCTNetworking.h>
#import <React/RCTShadowView.h>
#import <React/RCTUIManager.h>
#import <React/RCTUIManagerUtils.h>

@interface RNSVGKView ()

@property (nonatomic, copy) RCTDirectEventBlock onLoadStart;
@property (nonatomic, copy) RCTDirectEventBlock onError;
@property (nonatomic, copy) RCTDirectEventBlock onLoad;
@property (nonatomic, copy) RCTDirectEventBlock onLoadEnd;

@end

@implementation RNSVGKView
{
  RCTBridge *_bridge;
  SVGKImage *_image;
  SVGKImageView *_imageView;
  RCTNetworkTask *_pendingImage;
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
  BOOL sourceChanged = [changedProps containsObject:@"source"];
  if (sourceChanged && _source == nil) {
    [self stopLoading];
  }

  // The "data" prop always overrides the "source" prop.
  if (_data) {
    if ([changedProps containsObject:@"data"]) {
      [self removeImage];
      [self renderImage:_data fromSource:nil];
    }
  } else {
    if (_image) {
      [self removeImage];
    }
    if (sourceChanged && _source) {
      [self loadSource:_source];
    }
  }
}

- (void)loadSource:(RCTImageSource *)source
{
  [_pendingImage cancel];

  if (_onLoadStart) {
    _onLoadStart(nil);
  }

  _pendingImage = [_bridge.networking
    networkTaskWithRequest:source.request
    completionBlock:^(__unused NSURLResponse *response, NSData *data, NSError *error) {
      RCTExecuteOnMainQueue(^{
        [self onSourceLoaded:source data:data error:error];
      });
    }];

  [_pendingImage start];
}

- (void)onSourceLoaded:(RCTImageSource *)source data:(NSData *)data error:(NSError *)error
{
  RCTAssertMainQueue();
  if (source != _source || _data) {
    return; // The source changed while it was loading.
  }

  _pendingImage = nil;

  if (error) {
    if (_onError) {
      _onError(@{
        @"error": error.localizedDescription,
      });
    }
    if (_onLoadEnd) {
      _onLoadEnd(nil);
    }
  } else if (data) {
    [self renderImage:data fromSource:source];
  }
}

- (void)renderImage:(NSData *)data fromSource:(RCTImageSource *__nullable)source
{
  // Avoid parsing on the main thread.
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    SVGKImage *image = [SVGKImage imageWithData:data];
    RCTExecuteOnMainQueue(^{
      // The source may have changed while we were parsing.
      if (source ? source == self->_source && !self->_data : data == self->_data) {
        self.image = image;
      }
    });
  });
}

- (void)setImage:(SVGKImage *)image
{
  RCTAssertMainQueue();

  NSArray<NSError *> *errors = image.parseErrorsAndWarnings.errorsFatal;
  if (errors.count > 0) {
    if (_onError) {
      _onError(@{
        @"error": errors[0].localizedDescription,
      });
    }
    if (_source && _onLoadEnd) {
      _onLoadEnd(nil);
    }
  } else {
    _image = image;

    NSSize size = image.size;
    RCTBridge *bridge = _bridge;
    RCTExecuteOnUIManagerQueue(^{
      RCTShadowView *shadowView = [bridge.uiManager shadowViewForReactTag:self.reactTag];
      shadowView.intrinsicContentSize = size;

      [bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,NSView *> *viewRegistry) {
        if (image == self->_image) {
          [self updateImageView:image];

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
  RCTAssert(self.subviews.count == 0, @"Previous image must be removed from its superview");

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
    if (wasTinted) {
      if (tintColor) {
        // Retint the current image view.
        [_imageView setTintColor:tintColor];
        return;
      }
      // Clone the image to create an untinted CALayer tree.
      _image = [[SVGKImage alloc] initWithParsedSVG:_image.parseErrorsAndWarnings
                                         fromSource:_image.source];
    }

    // Replace the image view when tint is added or removed.
    [_imageView removeFromSuperview];
    [self updateImageView:_image];
  }
}

- (void)resizeImage
{
  if (_imageView) {
    NSSize maxSize = self.frame.size;

    // Fit the frame exactly by default.
    NSSize size = maxSize;
    CGFloat scale = 1;

    if (_image.hasSize) {
      NSSize imageSize = _image.size;

      CGFloat widthRatio = maxSize.width / imageSize.width;
      CGFloat heightRatio = maxSize.height / imageSize.height;

      size = imageSize;
      if (widthRatio > heightRatio) {
        size.width *= heightRatio;
        size.height = maxSize.height;
      } else {
        size.width = maxSize.width;
        size.height *= widthRatio;
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
      CALayer *layer = _image.CALayerTree;
      layer.position = (NSPoint){size.width / 2, size.height / 2};
      layer.affineTransform = CGAffineTransformMakeScale(scale, scale);
    }
  }
}

NSString *RCTPrintLayerTree(CALayer *layer, int depth) {
  NSString *indent = [@"" stringByPaddingToLength:(depth * 2) withString:@"  " startingAtIndex:0];
  NSString *result = [NSString stringWithFormat:@"\n%@%@ (position = %@, bounds = %@)", indent, layer, NSStringFromPoint(layer.position), NSStringFromRect(layer.bounds)];
  for (CALayer *childLayer in layer.sublayers) {
    result = [result stringByAppendingString:RCTPrintLayerTree(childLayer, depth + 1)];
  }
  return result;
}

- (void)setFrame:(NSRect)frame
{
  [super setFrame:frame];
  [self resizeImage];
}

- (void)removeImage
{
  [_imageView removeFromSuperview];

  _image = nil;
  _imageView = nil;
}

- (void)stopLoading
{
  if (_pendingImage) {
    [_pendingImage cancel];
    _pendingImage = nil;
  }
}

- (void)viewDidMoveToWindow
{
  if (self.window == nil) {
    [self stopLoading];
  }
}

@end
