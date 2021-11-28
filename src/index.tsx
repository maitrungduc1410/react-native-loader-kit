import {
  requireNativeComponent,
  UIManager,
  Platform,
  ViewStyle,
} from 'react-native';

const LINKING_ERROR =
  `The package 'react-native-loader-kit' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo managed workflow\n';

type LoaderKitProps = {
  color: string;
  style: ViewStyle;
};

const ComponentName = 'LoaderKitView';

export const LoaderKitView =
  UIManager.getViewManagerConfig(ComponentName) != null
    ? requireNativeComponent<LoaderKitProps>(ComponentName)
    : () => {
        throw new Error(LINKING_ERROR);
      };
