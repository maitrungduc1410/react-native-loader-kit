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

  <a href="https://github.com/maitrungduc1410/react-native-loader-kit" target="_blank">
    <img src="https://img.shields.io/github/stars/maitrungduc1410/react-native-loader-kit?style=social" />
  </a>
  
  </div>
  <br>
  <div align="center">
    <img src="./images/demo_android.gif" style="margin-right: 30px;" />
    <img src="./images/demo_ios.gif" />
  </div>
  <h2 align="center">
    If you like this project, encourage me by giving a ⭐️. Happy hacking
  </h2>
</h1>

# Table of Contents
1. [Installation](#Installation)
2. [Usage](#usage)
3. [List animations](#list-animations)
4. [Demo](#demo)

# Installation
With npm:
`$ npm install react-native-loader-kit --save`

With yarn:
`$ yarn add react-native-loader-kit`

## For iOS
Run the following command to setup for iOS:
```
npx pod-install ios
```
## For Expo
You need to run `prebuild` in order for native code takes effect:
```
npx expo prebuild
```
# Usage
```js
import LoaderKit from 'react-native-loader-kit'

<LoaderKit
  style={{ width: 50, height: 50 }}
  name={'BallPulse'} // Optional: see list of animations below
  color={'red'} // Optional: color can be: 'red', 'green',... or '#ddd', '#ffffff',...
/>
```
# List animations
As shown in the demo above, animations are as follows: 
## Default animations (both Android and iOS)
```json
  '1': 'BallPulse',
  '2': 'BallGridPulse',
  '3': 'BallClipRotate',
  '4': 'SquareSpin',
  '5': 'BallClipRotatePulse',
  '6': 'BallClipRotateMultiple',
  '7': 'BallPulseRise',
  '8': 'BallRotate',
  '9': 'CubeTransition',
  '10': 'BallZigZag',
  '11': 'BallZigZagDeflect',
  '12': 'BallTrianglePath',
  '13': 'BallScale',
  '14': 'LineScale',
  '15': 'LineScaleParty',
  '16': 'BallScaleMultiple',
  '17': 'BallPulseSync',
  '18': 'BallBeat',
  '19': 'LineScalePulseOut',
  '20': 'LineScalePulseOutRapid',
  '21': 'BallScaleRipple',
  '22': 'BallScaleRippleMultiple',
  '23': 'BallSpinFadeLoader',
  '24': 'LineSpinFadeLoader',
  '25': 'TriangleSkewSpin',
  '26': 'Pacman',
  '27': 'BallGridBeat',
  '28': 'SemiCircleSpin'
```
## iOS extra animations
```json
  '29': 'BallRotateChase',
  '30': 'Orbit',
  '31': 'AudioEqualizer',
  '32': 'CircleStrokeSpin',
  '33': 'BallDoubleBounce'
```
# Demo
A fully working demo is located at [example folder](./example/src/App.tsx)

# Thanks
Big thanks to [81813780](https://github.com/81813780/AVLoadingIndicatorView) and [ninjaprox](https://github.com/ninjaprox/NVActivityIndicatorView) for their great works