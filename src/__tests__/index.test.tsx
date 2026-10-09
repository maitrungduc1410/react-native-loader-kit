import {
  BUILTIN_INDICATOR_NAMES,
  InvalidIndicatorError,
  LoaderKitProgress,
  LoaderKitView,
  PROGRESS_TYPES,
  defineIndicator,
  param,
} from '../index';
import { serializeParams, serializeSpec, toNativeProps } from '../nativeProps';
import { progressLayoutStyle, toProgressViews } from '../progressProps';
import type { LoaderKitProgressProps } from '../progressProps';
import { resolveProgress } from '@loader-kit/spec/lite';
import { StyleSheet } from 'react-native';

const custom = defineIndicator({
  name: 'Blink',
  duration: 1,
  params: { low: 0.2 },
  layout: { type: 'row', count: 3, gap: 0.1 },
  shape: { type: 'circle' },
  stagger: { each: 0.2 },
  tracks: [
    {
      property: 'opacity',
      keyTimes: [0, 0.5, 1],
      values: [1, param('low'), 1],
    },
  ],
});

describe('toNativeProps', () => {
  it('defaults to BallPulse on its clock', () => {
    expect(toNativeProps({}, '')).toEqual({
      name: 'BallPulse',
      specJson: '',
      paramsJson: '',
      colors: undefined,
      cycleProgress: -1,
    });
  });

  it('passes playback props through and clamps cycleProgress', () => {
    const props = toNativeProps(
      {
        name: 'SquareSpin',
        color: 'red',
        colors: ['red', 'blue'],
        speed: 2,
        animating: false,
        hidesWhenStopped: true,
        cycleProgress: 1.5,
        reduceMotion: 'never',
        testID: 'loader',
      },
      ''
    );
    expect(props).toMatchObject({
      name: 'SquareSpin',
      color: 'red',
      colors: ['red', 'blue'],
      speed: 2,
      animating: false,
      hidesWhenStopped: true,
      cycleProgress: 1,
      reduceMotion: 'never',
      testID: 'loader',
    });
    expect(toNativeProps({ cycleProgress: -0.5 }, '').cycleProgress).toBe(0);
    expect(toNativeProps({ cycleProgress: Number.NaN }, '').cycleProgress).toBe(
      -1
    );
  });

  it('does not forward the spec object', () => {
    const props = toNativeProps({ spec: custom }, serializeSpec(custom));
    expect(props).not.toHaveProperty('spec');
    expect(JSON.parse(props.specJson!)).toEqual(custom);
  });
});

describe('serializeParams', () => {
  it('is stable regardless of key order', () => {
    expect(serializeParams({ b: 2, a: 1 })).toBe('{"a":1,"b":2}');
    expect(serializeParams({ a: 1, b: 2 })).toBe('{"a":1,"b":2}');
    expect(serializeParams({})).toBe('');
    expect(serializeParams(undefined)).toBe('');
  });
});

describe('serializeSpec', () => {
  it('reports invalid specs in development', () => {
    const error = jest.spyOn(console, 'error').mockImplementation(() => {});
    serializeSpec({ ...custom, duration: 0 });
    expect(error).toHaveBeenCalledWith(
      expect.stringContaining('invalid spec "Blink"')
    );
    error.mockRestore();
  });
});

describe('built-in indicators', () => {
  it('keeps every name of version 4', () => {
    expect(BUILTIN_INDICATOR_NAMES).toEqual(
      expect.arrayContaining([
        'AudioEqualizer',
        'BallBeat',
        'BallClipRotate',
        'BallClipRotateMultiple',
        'BallClipRotatePulse',
        'BallDoubleBounce',
        'BallGridBeat',
        'BallGridPulse',
        'BallPulse',
        'BallPulseRise',
        'BallPulseSync',
        'BallRotate',
        'BallRotateChase',
        'BallScale',
        'BallScaleMultiple',
        'BallScaleRipple',
        'BallScaleRippleMultiple',
        'BallSpinFadeLoader',
        'BallTrianglePath',
        'BallZigZag',
        'BallZigZagDeflect',
        'CircleStrokeSpin',
        'CubeTransition',
        'LineScale',
        'LineScaleParty',
        'LineScalePulseOut',
        'LineScalePulseOutRapid',
        'LineSpinFadeLoader',
        'Orbit',
        'Pacman',
        'SemiCircleSpin',
        'SquareSpin',
        'TriangleSkewSpin',
      ])
    );
  });
});

describe('toProgressViews', () => {
  const drawing = (props: LoaderKitProgressProps) =>
    toProgressViews(props).drawing;

  it('defaults to an indeterminate circular indicator', () => {
    expect(toProgressViews({})).toEqual({
      container: {
        style: [
          {
            width: 48,
            height: 48,
            alignItems: 'center',
            justifyContent: 'center',
          },
          undefined,
        ],
      },
      drawing: {
        style: StyleSheet.absoluteFill,
        pointerEvents: 'none',
        value: -1,
        buffer: -1,
        smooth: true,
        type: 'circular',
        variant: 'flat',
        thickness: 4,
        trackGap: 4,
        segments: 1,
        showLabel: false,
        stopIndicator: true,
        strokeCap: 'round',
        amplitude: 2,
        wavelength: 15,
        waveSpeed: 1,
        sweepAngle: 270,
        cornerRadius: 12,
        speed: 1,
        progressAccessibilityLabel: '',
      },
    });
  });

  it('clamps values and treats NaN and null as none', () => {
    expect(drawing({ value: 1.4, buffer: -2 })).toMatchObject({
      value: 1,
      buffer: 0,
    });
    expect(drawing({ value: Number.NaN, buffer: null })).toMatchObject({
      value: -1,
      buffer: -1,
    });
    expect(drawing({ value: 0 }).value).toBe(0);
  });

  it('resolves the options of the type', () => {
    expect(
      drawing({
        type: 'gauge',
        variant: 'wavy',
        segments: 2.6,
        sweepAngle: 500,
        thickness: Number.NaN,
      })
    ).toMatchObject({
      type: 'gauge',
      variant: 'flat',
      segments: 3,
      sweepAngle: 350,
      thickness: resolveProgress({ type: 'gauge' }).thickness,
    });
  });

  it('sends what was resolved, so native code resolves it to the same options', () => {
    for (const type of PROGRESS_TYPES) {
      const props = drawing({ type, showLabel: true, sweepAngle: 200 });
      expect(resolveProgress(props as never)).toEqual(
        resolveProgress({ type, showLabel: true, sweepAngle: 200 })
      );
    }
  });

  it('lays out each type', () => {
    expect(toProgressViews({ type: 'bars', size: 40 }).container.style).toEqual(
      [
        {
          width: 40,
          height: 30,
          alignItems: 'center',
          justifyContent: 'center',
        },
        undefined,
      ]
    );
    expect(
      progressLayoutStyle(resolveProgress({ type: 'battery' }), Number.NaN)
    ).toMatchObject({
      width: 48,
      height: 24,
    });
    expect(
      progressLayoutStyle(resolveProgress({ type: 'linear', thickness: 6 }), 10)
    ).toEqual({
      height: 10,
    });
    expect(
      progressLayoutStyle(
        resolveProgress({ type: 'border', thickness: 3, trackGap: 2 }),
        10
      )
    ).toEqual({ padding: 5 });
  });

  it('gives the View props to the container and the label to the drawing', () => {
    const style = { margin: 4 };
    const onPress = () => {};
    const { container, drawing: native } = toProgressViews({
      accessibilityLabel: 'Uploading',
      color: 'red',
      reduceMotion: 'never',
      style,
      testID: 'upload',
      pointerEvents: 'box-none',
      onTouchEnd: onPress,
    });
    expect(container).toMatchObject({
      testID: 'upload',
      pointerEvents: 'box-none',
      onTouchEnd: onPress,
    });
    expect((container.style as unknown[])[1]).toBe(style);
    for (const key of ['accessibilityLabel', 'color', 'reduceMotion']) {
      expect(container).not.toHaveProperty(key);
    }
    expect(native).toMatchObject({
      progressAccessibilityLabel: 'Uploading',
      color: 'red',
      reduceMotion: 'never',
    });
    expect(native).not.toHaveProperty('testID');
    expect(
      drawing({
        'aria-label': 'Saving',
        'accessibilityLabel': 'x',
      }).progressAccessibilityLabel
    ).toBe('Saving');
  });

  it('keeps the children out of the container props', () => {
    const views = toProgressViews({ size: 64, children: 'Stop' });
    expect(views.children).toBe('Stop');
    expect(views.container).not.toHaveProperty('children');
    expect(views.container).not.toHaveProperty('size');
    expect(views.drawing).not.toHaveProperty('size');
  });
});

describe('exports', () => {
  it('exposes the component and the spec helpers', () => {
    expect(typeof LoaderKitView).toBe('function');
    expect(typeof LoaderKitProgress).toBe('function');
    expect(BUILTIN_INDICATOR_NAMES).toContain('BallPulse');
    expect(() =>
      defineIndicator({
        duration: -1,
        layout: { type: 'single' },
        shape: { type: 'circle' },
        tracks: [],
      })
    ).toThrow(InvalidIndicatorError);
  });

  // Metro bundles every module it reaches, so the main spec entry would add every built-in spec
  // and the progress drawing code to the app.
  it('imports only the lite entry of the spec', () => {
    const fs = jest.requireActual<typeof import('fs')>('fs');
    const path = jest.requireActual<typeof import('path')>('path');
    const dir = path.join(__dirname, '..');
    for (const file of fs
      .readdirSync(dir)
      .filter((name) => /\.tsx?$/.test(name))) {
      const source = fs.readFileSync(path.join(dir, file), 'utf8');
      expect([
        file,
        /['"]@loader-kit\/spec(?!\/lite['"])/.test(source),
      ]).toEqual([file, false]);
    }
  });
});
