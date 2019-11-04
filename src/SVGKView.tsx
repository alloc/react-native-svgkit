import * as React from 'react'
import {
  Image,
  ImageURISource,
  ImageRequireSource,
  NativeSyntheticEvent,
  requireNativeComponent,
  StyleSheet,
  ShadowStyleIOS,
  FlexStyle,
  StyleProp,
  EventProps,
  NativeMethodsMixin,
  PointPropType,
} from 'react-native'
import { SVGKPreloadOptions, preloadSvg } from './SVGKCache'

export type SVGErrorEvent = NativeSyntheticEvent<{ error: string }>
export type SVGLoadEvent = NativeSyntheticEvent<{
  source: { height: number; width: number; url: string }
}>

interface Style extends FlexStyle, ShadowStyleIOS {
  opacity?: number
  backfaceVisibility?: boolean
  shouldRasterizeIOS?: boolean
}

interface Props extends EventProps {
  data?: string
  source?: ImageURISource | ImageRequireSource
  cacheKey?: string
  tintColor?: string
  anchorPoint?: PointPropType
  style?: StyleProp<Style>
  onLoadStart?: () => void
  onError?: (event: SVGErrorEvent) => void
  onLoad?: (event: SVGLoadEvent) => void
  onLoadEnd?: () => void
}

const RNSVGKView = requireNativeComponent('RNSVGKView')

export type SVGKView = React.ForwardRefExoticComponent<
  Props & React.RefAttributes<NativeMethodsMixin>
> & {
  preload: (
    options: SVGKPreloadOptions & {
      style?: Style
      tintColor?: string
      anchorPoint?: PointPropType
    },
  ) => React.SFC<Props>
}

export const SVGKView = React.forwardRef<NativeMethodsMixin, Props>(
  (props, ref) => (
    <RNSVGKView
      onError={console.error}
      {...props}
      source={props.source && Image.resolveAssetSource(props.source)}
      style={computeStyle(props)}
      ref={ref}
    />
  ),
) as SVGKView

SVGKView.displayName = 'SVGKView'

/**
 * Create a component that renders the given <svg> source and preloads it.
 */
SVGKView.preload = options => {
  const cacheKey = preloadSvg(options)
  return props => (
    <SVGKView
      anchorPoint={options.anchorPoint}
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
