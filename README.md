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
</h1>

<p align="center">
  <a href="https://maitrungduc1410.github.io/loader-kit/guide/indicators">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="https://maitrungduc1410.github.io/loader-kit/readme/indicators-dark.gif">
      <img alt="The 50 built-in indicators, animating" src="https://maitrungduc1410.github.io/loader-kit/readme/indicators-light.gif" width="100%">
    </picture>
  </a>
</p>

<p align="center">
  All 50 built-in indicators, the same on Android and iOS. <a href="https://maitrungduc1410.github.io/loader-kit/guide/indicators">Open the gallery</a> to try them and copy the React Native code.
</p>

Native loading indicators for React Native. Every indicator is a small JSON spec rendered by
[LoaderKit](https://github.com/maitrungduc1410/loader-kit), the same engine on iOS and Android,
so an indicator looks and moves the same on both platforms. You can tweak the built-in
indicators with params, write your own (experimental), and control playback (speed, pause, a
frozen frame, reduced motion). `LoaderKitProgress` shows the progress of a task in 9 types,
from linear and circular bars to gauges, liquid and batteries.

**Documentation: [maitrungduc1410.github.io/loader-kit/platforms/react-native](https://maitrungduc1410.github.io/loader-kit/platforms/react-native)**

# Requirements

| Version | React Native | Architecture | Maintained on |
| --- | --- | --- | --- |
| 5.x | 0.76 or newer | New Architecture only | `master`, npm `latest` |
| 4.x | see the [v4 README](https://github.com/maitrungduc1410/react-native-loader-kit/tree/v4#readme) | New and old architecture | `v4` branch, npm `v4-lts` |

Version 5 needs the New Architecture (the default since React Native 0.76). An app built with
`newArchEnabled=false` (Android) or `RCT_NEW_ARCH_ENABLED=0` (iOS) fails at build time with a
message pointing to version 4, which you install with `npm install react-native-loader-kit@v4-lts`.

Upgrading from version 4? See [Migrating from version 4](https://maitrungduc1410.github.io/loader-kit/platforms/react-native#migrating-from-v4).

# Installation

```sh
npm install react-native-loader-kit
# or
yarn add react-native-loader-kit
```

iOS:

```sh
cd ios && pod install
```

Expo: run `npx expo prebuild`, then restart the project. Expo Go is not supported.

# Usage

```tsx
import { LoaderKitView, LoaderKitProgress } from 'react-native-loader-kit';

// One of the 50 built-in indicators
<LoaderKitView name="BallPulse" color="#7c3aed" style={{ width: 50, height: 50 }} />

// The progress of a task, from 0 to 1 (null for indeterminate)
<LoaderKitProgress value={progress} />
```

# Documentation

The [React Native page](https://maitrungduc1410.github.io/loader-kit/platforms/react-native) covers every prop of `LoaderKitView` and
`LoaderKitProgress`, custom specs and troubleshooting. The rest of the site applies as is:

- [Built-in indicators](https://maitrungduc1410.github.io/loader-kit/guide/indicators): the 50 names and their params, with a live gallery
  that copies React Native code.
- [Progress indicators](https://maitrungduc1410.github.io/loader-kit/guide/progress): the 9 types and 30 designs.
- [Customizing](https://maitrungduc1410.github.io/loader-kit/guide/customizing) and [Playback](https://maitrungduc1410.github.io/loader-kit/guide/playback): colors, size,
  speed, stopping and reduced motion.
- [Custom indicators](https://maitrungduc1410.github.io/loader-kit/spec/): the spec format (experimental).

# Demo

A fully working demo is located in the [example folder](./example/src/App.tsx).

# Thanks

The indicators of version 4 reproduce the work of
[NVActivityIndicatorView](https://github.com/ninjaprox/NVActivityIndicatorView) and
[loaders.css](https://github.com/ConnorAtherton/loaders.css); `ChasingDots` and `SquareGridWave`
reproduce [SpinKit](https://github.com/tobiasahlin/SpinKit). Version 4 used
[AVLoadingIndicatorView](https://github.com/81813780/AVLoadingIndicatorView) on Android.
