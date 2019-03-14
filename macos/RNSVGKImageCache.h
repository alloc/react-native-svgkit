#import "SVGKImageView.h"
#import "SVGKit.h"

#import <React/RCTBridge.h>
#import <React/RCTImageSource.h>

@protocol RNSVGKImageObserver;

#pragma mark -

@interface RNSVGKImage : NSObject

@property (readonly) NSString *key;
@property (readonly) NSData *data;
@property (readonly) RCTImageSource *source;
@property (readonly) BOOL isLoaded;
@property (readonly) BOOL hasSize;
@property (readonly) NSSize size;

/** Returns a fresh copy when accessed. */
@property (readonly) SVGKImage *SVGKImage;
@property (readonly) NSError *error;

- (void)addObserver:(id<RNSVGKImageObserver>)observer;
- (void)removeObserver:(id<RNSVGKImageObserver>)observer;

@end

#pragma mark -

@protocol RNSVGKImageObserver

- (void)svgImageDidLoad:(RNSVGKImage *)image;

@end

#pragma mark -

@interface RNSVGKImageCache : NSObject <RCTBridgeModule>

@property (readonly) NSDictionary<NSString *, RNSVGKImage *> *images;

- (RNSVGKImage *)parseSvg:(NSData *)data
                 cacheKey:(NSString *)key;

- (RNSVGKImage *)loadSource:(RCTImageSource *)source
                   cacheKey:(NSString *)key;

@end

#pragma mark -

@interface RCTBridge (RNSVGKImageCache)

@property (nonatomic, readonly) RNSVGKImageCache *svgCache;

@end
