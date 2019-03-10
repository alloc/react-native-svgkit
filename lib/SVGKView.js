"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
var React = require("react");
var react_native_macos_1 = require("react-native-macos");
var RNSVGKView = react_native_macos_1.requireNativeComponent('RNSVGKView');
exports.SVGKView = function (props) { return (<RNSVGKView {...props} source={props.source && react_native_macos_1.Image.resolveAssetSource(props.source)} style={computeStyle(props)}/>); };
function computeStyle(props) {
    var style = react_native_macos_1.StyleSheet.flatten(props.style) || {};
    if (style.width == null && style.height == null) {
        if (style.flex == null) {
            style.flex = 1;
        }
    }
    return style;
}
