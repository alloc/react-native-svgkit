/// <reference types="react" />
import { ImageURISource, ImageRequireSource, NativeSyntheticEvent, ViewProps } from 'react-native-macos';
export declare type SVGErrorEvent = NativeSyntheticEvent<{
    error: string;
}>;
export declare type SVGLoadEvent = NativeSyntheticEvent<{
    source: {
        height: number;
        width: number;
        url: string;
    };
}>;
interface Props extends ViewProps {
    data?: string;
    source?: ImageURISource | ImageRequireSource;
    tintColor?: string;
    onLoadStart?: () => void;
    onError?: (event: SVGErrorEvent) => void;
    onLoad?: (event: SVGLoadEvent) => void;
    onLoadEnd?: () => void;
}
export declare const SVGKView: (props: Props) => JSX.Element;
export {};
