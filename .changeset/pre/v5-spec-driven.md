---
'react-native-loader-kit': major
---

Version 5 renders every indicator from a LoaderKit spec, with the same engine on iOS and Android, so indicators now look and move the same on both platforms. It requires the New Architecture and React Native 0.76 or newer (version 4 stays available as `react-native-loader-kit@v4-lts`). New props: `spec` for custom indicators made with `defineIndicator`, `params`, `colors`, `animating`, `hidesWhenStopped`, `cycleProgress` and `reduceMotion`. `animationSpeedMultiplier` is renamed to `speed`, and `IndicatorName` to `BuiltinIndicatorName`. All 33 indicators of version 4 keep their names and now work on both platforms, including `BallRotateChase` and `CircleStrokeSpin`, which were iOS-only. Writing your own spec is experimental in 5.x.
