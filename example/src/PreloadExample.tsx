import { SVGKView } from 'react-native-svgkit'
import React, { useState } from 'react'
import useInterval from './utils/useInterval'
import { View } from 'react-native'

const CameraIcon = SVGKView.preload({
  source: require('./icons/camera.svg'),
})
const VideoIcon = SVGKView.preload({
  source: require('./icons/video.svg'),
})

export const PreloadExample = () => {
  const [Icon, setIcon] = useState(() => CameraIcon)
  useInterval(() => {
    setIcon(() => (Icon == CameraIcon ? VideoIcon : CameraIcon))
  }, 1000)
  return (
    <View style={{ width: '10%', height: '10%', backgroundColor: 'pink' }}>
      <Icon key="test" tintColor="black" style={{ width: '100%' }} />
    </View>
  )
}
