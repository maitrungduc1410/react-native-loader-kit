import { useMemo } from 'react';
import LoaderKitViewNativeComponent from './LoaderKitViewNativeComponent';
import { serializeSpec, toNativeProps } from './nativeProps';
import type { LoaderKitViewProps } from './nativeProps';

function LoaderKitView(props: LoaderKitViewProps) {
  const { spec } = props;
  const specJson = useMemo(() => serializeSpec(spec), [spec]);
  return <LoaderKitViewNativeComponent {...toNativeProps(props, specJson)} />;
}

export default LoaderKitView;
export { LoaderKitView };
export type { LoaderKitViewProps, ReduceMotion } from './nativeProps';
export { LoaderKitProgress } from './LoaderKitProgress';
export type {
  LoaderKitProgressProps,
  ProgressReduceMotion,
} from './progressProps';

export {
  BUILTIN_INDICATOR_NAMES,
  InvalidIndicatorError,
  PROGRESS_TYPES,
  defineIndicator,
  param,
  progressVariants,
  validate,
} from '@loader-kit/spec/lite';
export type {
  BuiltinIndicatorName,
  Easing,
  GroupTrack,
  IndicatorDefinition,
  IndicatorSpec,
  Layout,
  Part,
  ProgressOptions,
  ProgressStrokeCap,
  ProgressType,
  ProgressVariant,
  Shape,
  Track,
} from '@loader-kit/spec/lite';
