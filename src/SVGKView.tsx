import * as React from 'react'
import {
  Image,
  ImageURISource,
  ImageRequireSource,
  NativeSyntheticEvent,
  requireNativeComponent,
  StyleSheet,
  ViewProps,
} from 'react-native-macos'
import { SVGKPreloadOptions, preloadSvg } from './SVGKCache'

export type SVGErrorEvent = NativeSyntheticEvent<{ error: string }>
export type SVGLoadEvent = NativeSyntheticEvent<{
  source: { height: number; width: number; url: string }
}>

interface Props extends ViewProps {
  data?: string
  source?: ImageURISource | ImageRequireSource
  cacheKey?: string
  tintColor?: string
  onLoadStart?: () => void
  onError?: (event: SVGErrorEvent) => void
  onLoad?: (event: SVGLoadEvent) => void
  onLoadEnd?: () => void
}

const RNSVGKView = requireNativeComponent('RNSVGKView')

export const SVGKView = (props: Props) => (
  <RNSVGKView
    {...props}
    source={props.source && Image.resolveAssetSource(props.source)}
    style={computeStyle(props)}
  />
)

SVGKView.displayName = 'SVGKView'

/**
 * Create a component that renders the given <svg> source and preloads it.
 */
SVGKView.preload = (
  options: SVGKPreloadOptions & {
    style?: ViewProps['style']
    tintColor?: string
  },
): React.SFC<Props> => {
  const cacheKey = preloadSvg(options)
  return props => (
    <SVGKView
      tintColor={options.tintColor}
      {...props}
      style={[props.style, options.style]}
      cacheKey={cacheKey}
    />
  )
}

function computeStyle(props: Props) {
  const style = StyleSheet.flatten(props.style) || {}
  if (style.width == null && style.height == null) {
    if (style.flex == null) {
      style.flex = 1
    }
  }
  return style
}
