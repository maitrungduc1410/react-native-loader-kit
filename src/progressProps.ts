import {
  PROGRESS_DEFAULT_SIZE,
  progressContentInset,
  progressIntrinsicSize,
  resolveProgress,
} from '@loader-kit/spec/lite';
import type { ProgressOptions, ResolvedProgress } from '@loader-kit/spec/lite';
import type { ReactNode } from 'react';
import { StyleSheet } from 'react-native';
import type { ColorValue, ViewProps, ViewStyle } from 'react-native';
import type { NativeProps } from './LoaderKitProgressViewNativeComponent';
import type { ReduceMotion } from './nativeProps';

/** The progress views have no `always`: they follow the system or keep their motion. */
export type ProgressReduceMotion = Exclude<ReduceMotion, 'always'>;

export interface LoaderKitProgressProps extends ProgressOptions, ViewProps {
  /** Progress in [0, 1]; null or undefined shows the indeterminate animation. */
  value?: number | null;
  /** Buffer of linear `flat` and `wavy`, in [0, 1]. */
  buffer?: number | null;
  /**
   * Move to a new value along a curve that follows the rhythm of the updates and never passes
   * the real value, rather than jump to it. Default true.
   */
  smooth?: boolean;
  /** Width of every type but linear and border. Default 48. */
  size?: number;
  /** Default: the accent color of the platform. */
  color?: ColorValue;
  /** Default: `color` at 24% opacity. */
  trackColor?: ColorValue;
  /** Color of the percentage. Default: the text color of the platform. */
  labelColor?: ColorValue;
  /**
   * `system` (default) jumps to new values, stops the waves, stripes and sheens and slows the
   * indeterminate animation while the system asks for reduced motion; `never` keeps the motion.
   */
  reduceMotion?: ProgressReduceMotion;
  /**
   * Drawn over the progress. The types with a `size` center them (a stop button in a circular
   * progress, for example); border frames them.
   */
  children?: ReactNode;
}

/** In [0, 1], or -1 for none: NaN and nullish values mean none. */
function fraction(value: number | null | undefined): number {
  if (value === null || value === undefined || Number.isNaN(value)) return -1;
  return Math.min(1, Math.max(0, value));
}

/** The box of each type, which React lays out: native code fills whatever box it gets. */
export function progressLayoutStyle(
  p: ResolvedProgress,
  size: number | undefined
): ViewStyle {
  const intrinsic = progressIntrinsicSize(p);
  if (p.type === 'linear') return { height: intrinsic.height ?? 0 };
  if (p.type === 'border') return { padding: progressContentInset(p) };
  const width =
    size !== undefined && Number.isFinite(size) && size >= 0
      ? size
      : PROGRESS_DEFAULT_SIZE;
  const ratio = (intrinsic.height ?? 1) / (intrinsic.width ?? 1);
  return {
    width,
    height: width * ratio,
    alignItems: 'center',
    justifyContent: 'center',
  };
}

export interface ProgressViews {
  /** Props of the container `View`: the View props of LoaderKitProgress, with the box of the type. */
  container: ViewProps;
  /** Props of the native drawing, which fills the container behind the children. */
  drawing: NativeProps;
  children?: ReactNode;
}

export function toProgressViews(props: LoaderKitProgressProps): ProgressViews {
  const {
    value,
    buffer,
    smooth,
    size,
    type,
    variant,
    thickness,
    trackGap,
    segments,
    showLabel,
    stopIndicator,
    strokeCap,
    amplitude,
    wavelength,
    waveSpeed,
    sweepAngle,
    cornerRadius,
    speed,
    accessibilityLabel,
    'aria-label': ariaLabel,
    color,
    trackColor,
    labelColor,
    reduceMotion,
    style,
    children,
    ...rest
  } = props;
  const p = resolveProgress({
    type,
    variant,
    thickness,
    trackGap,
    segments,
    showLabel,
    stopIndicator,
    strokeCap,
    amplitude,
    wavelength,
    waveSpeed,
    sweepAngle,
    cornerRadius,
    speed,
  });
  const drawing: NativeProps = {
    style: StyleSheet.absoluteFill,
    pointerEvents: 'none',
    value: fraction(value),
    buffer: fraction(buffer),
    smooth: smooth ?? true,
    type: p.type,
    variant: p.variant,
    thickness: p.thickness,
    trackGap: p.trackGap,
    segments: p.segments,
    showLabel: p.showLabel,
    stopIndicator: p.stopIndicator,
    strokeCap: p.strokeCap,
    amplitude: p.amplitude,
    wavelength: p.wavelength,
    waveSpeed: p.waveSpeed,
    // Back to degrees, rounded so 350 does not arrive as 349.99999999999994.
    sweepAngle: Math.round((p.sweepAngle * 180 * 1e9) / Math.PI) / 1e9,
    cornerRadius: p.cornerRadius,
    speed: p.speed,
    color,
    trackColor,
    labelColor,
    reduceMotion,
    // The label goes to the drawing, which screen readers read as a progress bar, rather than to
    // the container, which would hide the children from them.
    progressAccessibilityLabel: ariaLabel ?? accessibilityLabel ?? '',
  };
  return {
    container: { ...rest, style: [progressLayoutStyle(p, size), style] },
    drawing,
    children,
  };
}
