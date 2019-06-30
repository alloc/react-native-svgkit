import { SVGKView } from 'react-native-svgkit'
import React, { useRef } from 'react'

const remoteSvgURL =
  'https://raw.githubusercontent.com/alloc/react-native-svgkit/master/example/src/icons/bulma.svg'

export const RawExample = () => {
  const loadTime = useRef(0)
  return (
    <SVGKView
      source={{ uri: remoteSvgURL, cache: 'reload' }}
      style={{ minHeight: 200, backgroundColor: 'red' }}
      onLoadStart={() => (loadTime.current = Date.now())}
      onLoadEnd={() =>
        console.log('Loaded remoteSvg in %O ms', Date.now() - loadTime.current)
      }
    />
  )
}
