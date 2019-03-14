#import "RNSVGKImageCache.h"

#import <React/RCTNetworking.h>

typedef void (^RNSVGKParseCallback)(SVGKImage *image, NSError *error);
typedef void (^RNSVGKLoadCallback)(RNSVGKImage *image, NSError *error);

#pragma mark -

@interface RNSVGKImage ()

- (instancetype)initWithData:(NSData *)data
                    cacheKey:(NSString *)key
                       cache:(RNSVGKImageCache *)cache;

- (instancetype)initWithSource:(RCTImageSource *)source
                      cacheKey:(NSString *)key
                         cache:(RNSVGKImageCache *)cache;

@end

#pragma mark -

@interface RNSVGKImageCache () <RNSVGKImageObserver>
@end

@implementation RNSVGKImageCache
{
  NSMutableDictionary<NSString *, RNSVGKImage *> *_images;
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(preloadSvg:(NSDictionary *)json)
{
  RNSVGKImage *image;
  NSString *key = json[@"key"];

  if (json[@"data"]) {
    RCTAssert(key && _images[key] == nil, @"A unique cache key is required");
    image = [[RNSVGKImage alloc] initWithData:[RCTConvert NSData:json[@"data"]]
                                     cacheKey:key
                                        cache:self];
  } else {
    RCTImageSource *source = [RCTConvert RCTImageSource:json];
    RCTAssert(source, @"Malformed image source");
    if (key == nil) {
      key = source.request.URL.absoluteString;
    }
    RCTAssert(_images[key] == nil, @"A unique cache key is required");
    image = [[RNSVGKImage alloc] initWithSource:source
                                       cacheKey:key
                                          cache:self];
  }

  _images[key] = image;
  [image addObserver:self]; // Ensure the image stays cached.
}

RCT_EXPORT_METHOD(unloadSvg:(NSString *)key)
{
  [_images[key] removeObserver:self];
}

- (RNSVGKImage *)loadSource:(RCTImageSource *)source
                   cacheKey:(NSString *)key
{
  RCTAssert(source, @"An image source is required");
  if (key == nil) {
    key = source.request.URL.absoluteString;
  }
  if (_images[key] == nil) {
    _images[key] = [[RNSVGKImage alloc] initWithSource:source cacheKey:key cache:self];
  }
  return _images[key];
}

@synthesize bridge = _bridge;

- (instancetype)init
{
  if (self = [super init]) {
    _images = [NSMutableDictionary new];
  }
  return self;
}

- (RNSVGKImage *)parseSvg:(NSData *)data
                 cacheKey:(NSString *)key
{
  if (key == nil) {
    return [[RNSVGKImage alloc] initWithData:data cacheKey:nil cache:nil];
  }
  if (_images[key] == nil) {
    _images[key] = [[RNSVGKImage alloc] initWithData:data cacheKey:key cache:self];
  }
  return _images[key];
}

- (NSDictionary<NSString *, RNSVGKImage *> *)images
{
  return _images;
}

- (void)removeImage:(NSString *)key
{
  [_images removeObjectForKey:key];
}

- (void)svgImageDidLoad:(RNSVGKImage *)image
{
  // Do nothing.
}

@end

#pragma mark -

@implementation RNSVGKImage
{
  RNSVGKImageCache *_cache;
  RCTNetworkTask *_loading;
  SVGKImage *_image;
  NSMutableArray<id<RNSVGKImageObserver>> *_observers;
}

- (instancetype)initWithData:(NSData *)data
                    cacheKey:(NSString *)key
                       cache:(RNSVGKImageCache *)cache
{
  if (self = [super init]) {
    _key = key;
    _cache = cache;
    _observers = [NSMutableArray new];

    [self _parseSvg:data];
  }
  return self;
}

- (instancetype)initWithSource:(RCTImageSource *)source
                      cacheKey:(NSString *)key
                         cache:(RNSVGKImageCache *)cache
{
  if (self = [super init]) {
    _key = key;
    _cache = cache;
    _observers = [NSMutableArray new];

    [self _loadSource:source];
  }
  return self;
}

- (BOOL)isLoaded
{
  return _image != nil || _error != nil;
}

- (BOOL)hasSize
{
  return _image.hasSize;
}

- (NSSize)size
{
  return _image.size;
}

- (SVGKImage *)SVGKImage
{
  RCTAssert(_error == nil, @"Malformed <svg> has no image");
  return [[SVGKImage alloc] initWithParsedSVG:_image.parseErrorsAndWarnings
                                     fromSource:_image.source];
}

- (void)addObserver:(id<RNSVGKImageObserver>)observer
{
  [_observers addObject:observer];
}

- (void)removeObserver:(id<RNSVGKImageObserver>)observer
{
  [_observers removeObject:observer];
  if (_observers.count == 0) {
    [_loading cancel];
    if (_key) {
      [_cache removeImage:_key];
    }
  }
}

- (void)_loadSource:(RCTImageSource *)source
{
  _loading = [_cache.bridge.networking
    networkTaskWithRequest:source.request
    completionBlock:^(__unused NSURLResponse *response, NSData *data, NSError *error) {
      self->_loading = nil;
      if (data) {
        return [self _parseSvg:data];
      }
      RCTExecuteOnMainQueue(^{
        self->_error = error;
        for (id<RNSVGKImageObserver> observer in self->_observers) {
          [observer svgImageDidLoad:self];
        }
      });
    }];

  [_loading start];
}

- (void)_parseSvg:(NSData *)data
{
  // Avoid parsing on the main thread.
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    SVGKImage *image = [SVGKImage imageWithData:data];
    RCTExecuteOnMainQueue(^{
      NSArray<NSError *> *errors = image.parseErrorsAndWarnings.errorsFatal;
      if (errors.count > 0) {
        self->_error = errors[0];
      } else {
        self->_image = image;
      }
      for (id<RNSVGKImageObserver> observer in self->_observers) {
        [observer svgImageDidLoad:self];
      }
    });
  });
}

@end

#pragma mark -

@implementation RCTBridge (RNSVGKImageCache)

- (RNSVGKImageCache *)svgCache
{
  return [self moduleForClass:[RNSVGKImageCache class]];
}

@end
