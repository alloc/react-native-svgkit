import { SVGKView } from 'react-native-svgkit'
import React from 'react'

import rawSvgData from './icons/apple-logo'

export const RawExample = () => (
  <SVGKView
    data={rawSvgData}
    tintColor="white"
    style={{ height: 200, backgroundColor: 'purple' }}
  />
)
