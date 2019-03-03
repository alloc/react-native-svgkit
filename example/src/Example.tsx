import { SVGKView } from 'react-native-svgkit'
import { View } from 'react-native'
import * as React from 'react'

import rawSvgData from './icons/apple-logo'
const bundledSvg = require('./icons/bulma.svg')
const remoteSvgURL =
  'https://raw.githubusercontent.com/alloc/react-native-svgkit/master/example/src/icons/bulma.svg'

let bundledLoadTime = 0
let remoteLoadTime = 0

export const Example = () => (
  <View
    style={{
      flex: 1,
      padding: 10,
      backgroundColor: 'yellow'
    }}
  >
    <SVGKView
      data={rawSvgData}
      tintColor="white"
      style={{ height: 200, backgroundColor: 'purple' }}
    />
    <View style={{ height: 150 }}>
      <SVGKView
        tintColor="white"
        source={bundledSvg}
        onLoadStart={() => (bundledLoadTime = Date.now())}
        onLoadEnd={() =>
          console.log(
            'Loaded bundledSvg in %O ms',
            Date.now() - bundledLoadTime
          )
        }
      />
    </View>
    <SVGKView
      source={{ uri: remoteSvgURL, cache: 'reload' }}
      style={{ minHeight: 200, backgroundColor: 'red' }}
      onLoadStart={() => (remoteLoadTime = Date.now())}
      onLoadEnd={() =>
        console.log('Loaded remoteSvg in %O ms', Date.now() - remoteLoadTime)
      }
    />
  </View>
)
