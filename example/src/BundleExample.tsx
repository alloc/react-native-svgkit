import { SVGKView } from 'react-native-svgkit'
import { View } from 'react-native'
import React, { useRef } from 'react'

const bundledSvg = require('./icons/bulma.svg')

export const BundleExample = () => {
  const loadTime = useRef(0)
  return (
    <View style={{ height: 150 }}>
      <SVGKView
        tintColor="white"
        source={bundledSvg}
        onLoadStart={() => (loadTime.current = Date.now())}
        onLoadEnd={() =>
          console.log(
            'Loaded bundledSvg in %O ms',
            Date.now() - loadTime.current,
          )
        }
      />
    </View>
  )
}
