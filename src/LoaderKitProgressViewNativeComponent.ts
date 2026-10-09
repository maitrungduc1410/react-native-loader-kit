import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';
import type { ColorValue, HostComponent, ViewProps } from 'react-native';
import type {
  Double,
  Int32,
  WithDefault,
} from 'react-native/Libraries/Types/CodegenTypes';

/** Every option arrives resolved by `resolveProgress`, so native code never applies defaults. */
export interface NativeProps extends ViewProps {
  /** Progress in [0, 1]; negative shows the indeterminate animation. */
  value?: WithDefault<Double, -1.0>;
  /** Buffer in [0, 1]; negative draws none. */
  buffer?: WithDefault<Double, -1.0>;
  smooth?: WithDefault<boolean, true>;
  type?: WithDefault<string, 'circular'>;
  variant?: WithDefault<string, 'flat'>;
  thickness?: WithDefault<Double, 4.0>;
  trackGap?: WithDefault<Double, 4.0>;
  segments?: WithDefault<Int32, 1>;
  showLabel?: WithDefault<boolean, false>;
  stopIndicator?: WithDefault<boolean, true>;
  strokeCap?: WithDefault<string, 'round'>;
  amplitude?: WithDefault<Double, 2.0>;
  wavelength?: WithDefault<Double, 15.0>;
  waveSpeed?: WithDefault<Double, 1.0>;
  /** In degrees. */
  sweepAngle?: WithDefault<Double, 270.0>;
  cornerRadius?: WithDefault<Double, 12.0>;
  speed?: WithDefault<Double, 1.0>;
  /** Unset takes the platform accent color. */
  color?: ColorValue;
  /** Unset draws the track in `color` at 24% opacity. */
  trackColor?: ColorValue;
  /** Unset takes the platform text color. */
  labelColor?: ColorValue;
  reduceMotion?: WithDefault<'system' | 'never', 'system'>;
  /** What screen readers announce; empty means the platform default. */
  progressAccessibilityLabel?: WithDefault<string, ''>;
}

export default codegenNativeComponent<NativeProps>(
  'LoaderKitProgressView'
) as HostComponent<NativeProps>;
