import React from 'react';
import { processColor } from 'react-native';
import type { ColorValue, ViewProps } from 'react-native';
import LoaderKitViewNativeComponent from './LoaderKitViewNativeComponent';
import type { IndicatorName } from './types';

interface LoaderKitViewProps extends ViewProps {
  name: IndicatorName;
  color?: ColorValue;
  animationSpeedMultiplier?: number; // Default is 1.0
}

const LoaderKitView: React.FC<LoaderKitViewProps> = (props) => {
  return (
    <LoaderKitViewNativeComponent
      {...props}
      color={processColor(props.color) as number}
    />
  );
};

export default LoaderKitView;
export { LoaderKitView };
export type { LoaderKitViewProps };

// Export types and utilities for type-safe usage
export type {
  IndicatorName,
  CommonIndicatorName,
  IOSOnlyIndicatorName,
} from './types';

export {
  COMMON_INDICATORS,
  IOS_ONLY_INDICATORS,
  ALL_INDICATORS,
  isIndicatorAvailableOnPlatform,
  getAvailableIndicators,
} from './types';
