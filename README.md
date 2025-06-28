<h1 align="center">
  <div>
    React Native Loader Kit
  </div>
  <div>
  <a href="https://www.npmjs.com/package/react-native-loader-kit" target="_blank">
    <img src="https://img.shields.io/npm/dw/react-native-loader-kit" />
  </a>

  <a href="https://www.npmjs.com/package/react-native-loader-kit" target="_blank">
    <img src="https://img.shields.io/npm/v/react-native-loader-kit" />
  </a>

  <a href="https://github.com/maitrungduc1410/react-native-loader-kit" target="_blank">
    <img src="https://img.shields.io/github/license/maitrungduc1410/react-native-loader-kit" />
  </a>

  </div>
  <br>
  <div align="center">
    <img src="./images/demo_android.gif" style="margin-right: 30px;" />
    <img src="./images/demo_ios.gif" />
  </div>
</h1>

# Table of Contents
1. [Installation](#installation)
2. [Usage](#usage)
3. [List animations](#list-animations)
4. [Demo](#demo)

# Installation
With npm:
```sh
# new arch
npm install react-native-loader-kit

# old arch
npm install react-native-loader-kit@^2.0.0
```

With yarn:
```sh
# new arch
yarn add react-native-loader-kit

# old arch
yarn add react-native-loader-kit@^2.0.0
```

## For iOS (React Native CLI project)
Run the following command to setup for iOS:
```sh
cd ios && pod install

# or
npx pod-install ios
```
## For Expo project
You need to run `prebuild` in order for native code takes effect:
```
npx expo prebuild
```
Then you need to restart your project to make changes take effect

# Usage
```js
// v3
import {
  LoaderKitView,
} from 'react-native-loader-kit';

// v2
import LoaderKitView from 'react-native-loader-kit'

<LoaderKitView
  style={{ width: 50, height: 50 }}
  name={'BallPulse'}
  animationSpeedMultiplier={1.0} // speed up/slow down animation, default: 1.0, larger is faster
  color={'red'} // Optional: color can be: 'red', 'green',... or '#ddd', '#ffffff',...
/>
```

> `animationSpeedMultiplier` is only supported from v3

# List animations

Common:
- BallPulse
- BallGridPulse
- BallClipRotate
- SquareSpin
- BallClipRotatePulse
- BallClipRotateMultiple
- BallPulseRise
- BallRotate
- CubeTransition
- BallZigZag
- BallZigZagDeflect
- BallTrianglePath
- BallScale
- LineScale
- LineScaleParty
- BallScaleMultiple
- BallPulseSync
- BallBeat
- LineScalePulseOut
- LineScalePulseOutRapid
- BallScaleRipple
- BallScaleRippleMultiple
- BallSpinFadeLoader
- LineSpinFadeLoader
- TriangleSkewSpin
- Pacman
- BallGridBeat
- SemiCircleSpin
- Orbit
- AudioEqualizer
- BallDoubleBounce

iOS only:
- BallRotateChase
- CircleStrokeSpin

# Troubleshooting
## uses-sdk:minSdkVersion XX cannot be smaller than version YY

You can override sdk version to use any version in your `android/build.gradle` > `buildscript` > `ext`
```gradle
buildscript {
    ext {
        LoaderKit_kotlinVersion=2.0.21
        LoaderKit_minSdkVersion=24
        LoaderKit_targetSdkVersion=34
        LoaderKit_compileSdkVersion=35
        LoaderKit_ndkVersion=27.1.12297006
    }
}
```

# Demo
A fully working demo is located at [example folder](./example/src/App.tsx)

# Thanks
Big thanks to [81813780](https://github.com/81813780/AVLoadingIndicatorView) and [ninjaprox](https://github.com/ninjaprox/NVActivityIndicatorView) for their great works