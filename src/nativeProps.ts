import { validate } from '@loader-kit/spec/lite';
import type {
  BuiltinIndicatorName,
  IndicatorSpec,
} from '@loader-kit/spec/lite';
import type { ColorValue, ViewProps } from 'react-native';
import type { NativeProps } from './LoaderKitViewNativeComponent';

export type ReduceMotion = 'system' | 'never' | 'always';

interface CommonProps extends ViewProps {
  /** Overrides for the params of the indicator, by name. Unknown names are ignored. */
  params?: Readonly<Record<string, number>>;
  /** Color of every element. Default white. */
  color?: ColorValue;
  /** One color per element, repeated when there are more elements than colors. Wins over `color`. */
  colors?: readonly ColorValue[];
  /** Playback speed, default 1. Changing it never makes the animation jump. */
  speed?: number;
  /** Default true. Stopping freezes the current frame. */
  animating?: boolean;
  /** Draw nothing while stopped. Default false. */
  hidesWhenStopped?: boolean;
  /**
   * Freeze the indicator at this point of its animation cycle, in [0, 1]. It is not the progress
   * of a task: 0.5 is the middle of one loop.
   */
  cycleProgress?: number;
  /**
   * `system` (default) shows a still frame when the system asks for reduced motion, `never`
   * always animates, `always` never animates.
   */
  reduceMotion?: ReduceMotion;
}

export type LoaderKitViewProps = CommonProps &
  (
    | {
        /** A built-in indicator. Default `BallPulse`. */
        name?: BuiltinIndicatorName;
        spec?: undefined;
      }
    | {
        /** A custom indicator, usually made with `defineIndicator()`. */
        spec: IndicatorSpec;
        name?: undefined;
      }
  );

export function serializeSpec(spec: IndicatorSpec | undefined): string {
  if (spec === undefined) return '';
  if (__DEV__) {
    const errors = validate(spec);
    if (errors.length > 0) {
      console.error(
        `LoaderKitView: invalid spec "${spec.name}", nothing is drawn:\n- ${errors.join('\n- ')}`
      );
    }
  }
  return JSON.stringify(spec);
}

/** Sorted keys, so equal params always give the same string and do not reach native again. */
export function serializeParams(
  params: Readonly<Record<string, number>> | undefined
): string {
  if (params === undefined) return '';
  const keys = Object.keys(params).sort();
  if (keys.length === 0) return '';
  return JSON.stringify(params, keys);
}

export function toNativeProps(
  props: LoaderKitViewProps,
  specJson: string
): NativeProps {
  const { name, params, cycleProgress, colors, ...rest } = props;
  delete (rest as { spec?: IndicatorSpec }).spec;
  return {
    ...rest,
    name: name ?? 'BallPulse',
    specJson,
    paramsJson: serializeParams(params),
    colors: colors === undefined ? undefined : [...colors],
    cycleProgress:
      cycleProgress === undefined || Number.isNaN(cycleProgress)
        ? -1
        : Math.min(1, Math.max(0, cycleProgress)),
  };
}
