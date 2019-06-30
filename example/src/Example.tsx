import { PreloadExample } from './PreloadExample'
import { View } from 'react-native'
import React from 'react'

const containerStyle = {
  flex: 1,
  flexDirection: 'row',
  alignItems: 'center',
  justifyContent: 'center',
  padding: 10,
  backgroundColor: 'yellow',
} as const

export const Example = () => (
  <View style={containerStyle}>
    <PreloadExample />
  </View>
)
