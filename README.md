# @alloc/react-native-svgkit

SVG support for [react-native-macos](https://github.com/ptmt/react-native-macos)

TypeScript definitions included!

&nbsp;

## Install

```sh
npm install @alloc/react-native-svgkit
```

1. Add `macos/RNSVGKit.xcodeproj` to your project

2. Add these frameworks to your project:
  - libxml2.tbd
  - AppKit.framework
  - QuartzCore.framework
  - CoreGraphics.framework
  - ./SVGKit/3rd-party-frameworks/CocoaLumberjack-2.2.0/Mac/CocoaLumberjack.framework

3. Add `CocoaLumberjack.framework` to "General > Embedded Binaries" under your target

&nbsp;

## Usage

```ts
import {SVGKView} from '@alloc/react-native-svgkit'

// Control the width without needing to know the aspect ratio.
<SVGKView style={{width: 50}} data="..." />

// Explicit size is optional.
<SVGKView source={require('./foo.svg')} />
```

Any `<View>` prop can be passed to `<SVGKView>`.

When neither `props.style.width` nor `props.style.height` is defined, the `<SVGKView>` fills its parent (while preserving its aspect ratio).

### props.data

The string of SVG markup. This always overrides the `source` prop.

Loading of the `source` prop is cancelled when the `data` prop is set.

### props.source

The reference to an SVG, either local or remote.

For local SVGs: `require('./foo.svg')`

For remote SVGs: `{ uri: 'https://foo.com/bar.svg' }`

Loading is cancelled whenever the `source` prop changes.

The previous image is cleared immediately whenever the `data` or `source` props change.

### props.tintColor

Override the `fillColor` and/or `strokeColor` of every shape in the SVG.

### props.onLoadStart

Called when the `source` prop begins loading.

### props.onError

Called when either (1) the `source` prop failed to load, or (2) the SVG markup has a syntax error.

Syntax errors in the `data` prop are included.

Passed an object like `{ nativeEvent: { error: string } }`

### props.onLoad

Called once the `source` prop has been loaded and rendered without error.

### props.onLoadEnd

Called when the `source` prop either (1) fails to load or (2) is rendered.
