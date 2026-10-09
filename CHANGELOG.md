# react-native-loader-kit

## 5.0.0-rc.0

### Major Changes

- ccde85f: Version 5 renders every indicator from a LoaderKit spec, with the same engine on iOS and Android, so indicators now look and move the same on both platforms. It requires the New Architecture and React Native 0.76 or newer (version 4 stays available as `react-native-loader-kit@v4-lts`). New props: `spec` for custom indicators made with `defineIndicator`, `params`, `colors`, `animating`, `hidesWhenStopped`, `cycleProgress` and `reduceMotion`. `animationSpeedMultiplier` is renamed to `speed`, and `IndicatorName` to `BuiltinIndicatorName`. All 33 indicators of version 4 keep their names and now work on both platforms, including `BallRotateChase` and `CircleStrokeSpin`, which were iOS-only. Writing your own spec is experimental in 5.x.

### Minor Changes

- ccde85f: `LoaderKitProgress` shows the progress of a task on iOS and Android, drawn by LoaderKit: linear, circular, pie, gauge, liquid, border, bars, grid and battery, with variants such as `wavy`, `segmented`, `striped` and `gradient`. Without a `value` (or with null) it shows the indeterminate animation, and new values glide smoothly unless `smooth` is false. Children are drawn over the indicator (a stop button in a circular progress, for example) or, with `border`, inside it, and screen readers announce a progress bar with its percentage. LoaderKit 1.0.0-rc.1 also adds 17 built-in indicators, 50 in total.
