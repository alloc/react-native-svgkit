import {
  NativeModules,
  ImageRequireSource,
  ImageURISource,
  Image,
} from 'react-native'
import { useEffect, useMemo } from 'react'

const { RNSVGKImageCache: nativeCache } = NativeModules

export type SVGKPreloadOptions = {
  key?: string
  data?: string
  source?: ImageURISource | ImageRequireSource
}

// Track the user count of each cache key.
const userCounts: { [cacheKey: string]: number } = {}

export function useSvg(options: SVGKPreloadOptions) {
  const cacheKey = useMemo(
    () => (options.data || options.source ? preloadSvg(options) : void 0),
    Object.values(options),
  )
  useEffect(() => {
    if (cacheKey) {
      return () => unloadSvg(cacheKey)
    }
  }, [cacheKey])
  return cacheKey
}

/** Preload an `<svg>` into memory. Returns the cache key. */
export function preloadSvg(options: SVGKPreloadOptions) {
  if (!options.key && !options.source) {
    throw Error('Cannot preload an <svg> string without a cache key')
  }

  const source = options.source
    ? Image.resolveAssetSource(options.source)
    : void 0

  const cacheKey = options.key || source!.uri
  if (!userCounts[cacheKey]) {
    userCounts[cacheKey] = 1
    nativeCache.preloadSvg({
      ...(source || { data: options.data }),
      key: options.key,
    })
  } else {
    userCounts[cacheKey]++
  }
  return cacheKey
}

/**
 * Reclaim memory taken by cached `<svg>` data.
 *
 * Does not affect views which are using the cached data.
 */
export function unloadSvg(cacheKey: string) {
  if (userCounts[cacheKey]) {
    if (userCounts[cacheKey] == 1) {
      delete userCounts[cacheKey]
      nativeCache.unloadSvg(cacheKey)
    } else {
      userCounts[cacheKey]--
    }
  }
}
