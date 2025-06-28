/**
 * Available loader indicator names for LoaderKit
 */

// Common indicators available on both iOS and Android
export type CommonIndicatorName =
  | 'BallPulse'
  | 'BallGridPulse'
  | 'BallClipRotate'
  | 'SquareSpin'
  | 'BallClipRotatePulse'
  | 'BallClipRotateMultiple'
  | 'BallPulseRise'
  | 'BallRotate'
  | 'CubeTransition'
  | 'BallZigZag'
  | 'BallZigZagDeflect'
  | 'BallTrianglePath'
  | 'BallScale'
  | 'LineScale'
  | 'LineScaleParty'
  | 'BallScaleMultiple'
  | 'BallPulseSync'
  | 'BallBeat'
  | 'LineScalePulseOut'
  | 'LineScalePulseOutRapid'
  | 'BallScaleRipple'
  | 'BallScaleRippleMultiple'
  | 'BallSpinFadeLoader'
  | 'LineSpinFadeLoader'
  | 'TriangleSkewSpin'
  | 'Pacman'
  | 'BallGridBeat'
  | 'SemiCircleSpin'
  | 'Orbit'
  | 'AudioEqualizer'
  | 'BallDoubleBounce';

// iOS-only indicators (not available on Android)
export type IOSOnlyIndicatorName = 'BallRotateChase' | 'CircleStrokeSpin';

// All available indicator names
export type IndicatorName = CommonIndicatorName | IOSOnlyIndicatorName;

/**
 * Helper arrays for runtime checks and platform detection
 */
export const COMMON_INDICATORS: readonly CommonIndicatorName[] = [
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
  'Orbit',
  'AudioEqualizer',
  'BallDoubleBounce',
] as const;

export const IOS_ONLY_INDICATORS: readonly IOSOnlyIndicatorName[] = [
  'BallRotateChase',
  'CircleStrokeSpin',
] as const;

export const ALL_INDICATORS: readonly IndicatorName[] = [
  ...COMMON_INDICATORS,
  ...IOS_ONLY_INDICATORS,
] as const;

/**
 * Type guard to check if an indicator is available on the current platform
 */
export const isIndicatorAvailableOnPlatform = (
  indicator: IndicatorName,
  platform: 'ios' | 'android'
): boolean => {
  if (platform === 'ios') {
    return true; // All indicators are available on iOS
  }

  // On Android, only common indicators are available
  return COMMON_INDICATORS.includes(indicator as CommonIndicatorName);
};

/**
 * Get all available indicators for a specific platform
 */
export const getAvailableIndicators = (
  platform: 'ios' | 'android'
): readonly IndicatorName[] => {
  if (platform === 'ios') {
    return ALL_INDICATORS;
  }
  return COMMON_INDICATORS;
};
