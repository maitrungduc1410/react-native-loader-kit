import { Platform } from 'react-native';

const defaultAnimations = [
  'BallPulse',
  'BallGridPulse',
  'BallClipRotate',
  'SquareSpin',
  'BallClipRotatePulse',
  'BallClipRotateMultiple',
  'BallPulseRise',
  'BallRotate',
  'CubeTransition',
  'BallZigZag',
  'BallZigZagDeflect',
  'BallTrianglePath',
  'BallScale',
  'LineScale',
  'LineScaleParty',
  'BallScaleMultiple',
  'BallPulseSync',
  'BallBeat',
  'LineScalePulseOut',
  'LineScalePulseOutRapid',
  'BallScaleRipple',
  'BallScaleRippleMultiple',
  'BallSpinFadeLoader',
  'LineSpinFadeLoader',
  'TriangleSkewSpin',
  'Pacman',
  'BallGridBeat',
  'SemiCircleSpin',
];

const iOSExtraAnimations = [
  'BallRotateChase',
  'Orbit',
  'AudioEqualizer',
  'CircleStrokeSpin',
  'BallDoubleBounce',
];

export default Platform.OS === 'ios'
  ? [...defaultAnimations, ...iOSExtraAnimations]
  : [...defaultAnimations];
