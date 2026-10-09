import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';
import type { ColorValue, HostComponent, ViewProps } from 'react-native';
import type {
  Float,
  WithDefault,
} from 'react-native/Libraries/Types/CodegenTypes';

export interface NativeProps extends ViewProps {
  /** Built-in indicator, used when `specJson` is empty. */
  name?: WithDefault<string, 'BallPulse'>;
  /** A custom spec serialized as JSON; empty means `name`. */
  specJson?: WithDefault<string, ''>;
  /** Param overrides serialized as a JSON object; empty means none. */
  paramsJson?: WithDefault<string, ''>;
  color?: ColorValue;
  colors?: ReadonlyArray<ColorValue>;
  speed?: WithDefault<Float, 1.0>;
  animating?: WithDefault<boolean, true>;
  hidesWhenStopped?: WithDefault<boolean, false>;
  /** A frozen point of the cycle in [0, 1]; negative means the indicator runs on its clock. */
  cycleProgress?: WithDefault<Float, -1.0>;
  reduceMotion?: WithDefault<'system' | 'never' | 'always', 'system'>;
}

export default codegenNativeComponent<NativeProps>(
  'LoaderKitView'
) as HostComponent<NativeProps>;
