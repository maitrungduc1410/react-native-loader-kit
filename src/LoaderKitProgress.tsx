import { View } from 'react-native';
import LoaderKitProgressViewNativeComponent from './LoaderKitProgressViewNativeComponent';
import { toProgressViews } from './progressProps';
import type { LoaderKitProgressProps } from './progressProps';

/**
 * A progress indicator: linear, circular, pie, gauge, liquid, border, bars, grid or battery.
 *
 * Linear fills the width it gets; border wraps its children plus its stroke; the other types are
 * `size` wide unless `style` sizes them. It is a `View` holding the drawing and, above it, the
 * children, so every View prop applies to it.
 */
export function LoaderKitProgress(props: LoaderKitProgressProps) {
  const { container, drawing, children } = toProgressViews(props);
  return (
    <View {...container}>
      <LoaderKitProgressViewNativeComponent {...drawing} />
      {children}
    </View>
  );
}
