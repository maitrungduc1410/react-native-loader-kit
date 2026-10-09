import { useEffect, useState } from 'react';
import {
  Dimensions,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import {
  BUILTIN_INDICATOR_NAMES,
  LoaderKitProgress,
  LoaderKitView,
  defineIndicator,
  param,
  type BuiltinIndicatorName,
} from 'react-native-loader-kit';

const { width: screenWidth } = Dimensions.get('window');

const Blink = defineIndicator({
  name: 'Blink',
  duration: 0.9,
  params: { count: 4, low: 0.15 },
  layout: { type: 'row', count: param('count'), gap: 0.08 },
  shape: { type: 'rect', cornerRadius: 0.25 },
  stagger: { each: 0.15 },
  tracks: [
    {
      property: 'opacity',
      keyTimes: [0, 0.5, 1],
      values: [1, param('low'), 1],
      easing: 'easeInOut',
    },
    {
      property: 'scaleY',
      keyTimes: [0, 0.5, 1],
      values: [1, 0.5, 1],
      easing: 'easeInOut',
    },
  ],
});

const displayName = (name: string) => name.replace(/([A-Z])/g, ' $1').trim();

/** Progress of a fake download: uneven steps, then a pause before it starts again. */
function useDownload(running: boolean) {
  const [value, setValue] = useState(0);
  useEffect(() => {
    if (!running) return;
    const timer = setInterval(() => {
      setValue((v) => (v >= 1 ? 0 : Math.min(1, v + Math.random() * 0.12)));
    }, 400);
    return () => clearInterval(timer);
  }, [running]);
  return value;
}

function Button({ label, onPress }: { label: string; onPress: () => void }) {
  return (
    <TouchableOpacity style={styles.button} onPress={onPress}>
      <Text style={styles.buttonText}>{label}</Text>
    </TouchableOpacity>
  );
}

export default function App() {
  const [speed, setSpeed] = useState(1);
  const [animating, setAnimating] = useState(true);
  const [cycleProgress, setCycleProgress] = useState<number | undefined>(
    undefined
  );
  const [multicolor, setMulticolor] = useState(false);
  const [count, setCount] = useState(4);
  const [indeterminate, setIndeterminate] = useState(false);
  const download = useDownload(!indeterminate);
  const progressValue = indeterminate ? null : download;

  const columns = 3;
  const spacing = 10;
  const itemWidth = (screenWidth - spacing * (columns + 1)) / columns;

  const common = {
    speed,
    animating,
    cycleProgress,
    color: 'white',
    colors: multicolor ? ['#ffce54', '#a0d468', '#4fc1e9'] : undefined,
    style: styles.indicator,
  };

  const renderBuiltin = (name: BuiltinIndicatorName, index: number) => (
    <View key={name} style={[styles.cell, { width: itemWidth }]}>
      <LoaderKitView name={name} {...common} />
      <Text style={styles.label}>
        {index + 1}. {displayName(name)}
      </Text>
    </View>
  );

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.controls}>
        <Text style={styles.controlLabel}>Speed {speed.toFixed(1)}x</Text>
        <View style={styles.row}>
          <Button
            label="-"
            onPress={() => setSpeed((s) => Math.max(0.1, s - 0.1))}
          />
          <Button
            label="+"
            onPress={() => setSpeed((s) => Math.min(3, s + 0.1))}
          />
          <Button
            label={animating ? 'Stop' : 'Start'}
            onPress={() => setAnimating((a) => !a)}
          />
          <Button
            label={multicolor ? 'One color' : 'Colors'}
            onPress={() => setMulticolor((m) => !m)}
          />
        </View>
        <Text style={styles.controlLabel}>
          Cycle progress{' '}
          {cycleProgress === undefined ? 'off' : cycleProgress.toFixed(2)}
        </Text>
        <View style={styles.row}>
          <Button label="Off" onPress={() => setCycleProgress(undefined)} />
          {[0, 0.25, 0.5, 0.75].map((value) => (
            <Button
              key={value}
              label={String(value)}
              onPress={() => setCycleProgress(value)}
            />
          ))}
        </View>
      </View>

      <ScrollView contentContainerStyle={styles.scrollContent}>
        <View style={styles.grid}>
          {BUILTIN_INDICATOR_NAMES.map(renderBuiltin)}
        </View>

        <View style={styles.custom}>
          <Text style={styles.controlLabel}>
            Progress {indeterminate ? 'indeterminate' : download.toFixed(2)}
          </Text>
          <Button
            label={indeterminate ? 'Determinate' : 'Indeterminate'}
            onPress={() => setIndeterminate((i) => !i)}
          />
          <LoaderKitProgress
            type="linear"
            value={progressValue}
            color="white"
            style={styles.linear}
          />
          <LoaderKitProgress
            type="linear"
            variant="wavy"
            value={progressValue}
            color="white"
            style={styles.linear}
          />
          <LoaderKitProgress
            type="linear"
            variant="striped"
            thickness={16}
            showLabel
            value={progressValue}
            color="white"
            labelColor="#ed5565"
            style={styles.linear}
          />
          <View style={styles.row}>
            <LoaderKitProgress value={progressValue} color="white" />
            <LoaderKitProgress
              variant="wavy"
              value={progressValue}
              color="white"
            />
            <LoaderKitProgress type="pie" value={progressValue} color="white" />
            <LoaderKitProgress
              type="gauge"
              value={progressValue}
              showLabel
              size={64}
              color="white"
              labelColor="white"
            />
            <LoaderKitProgress
              type="liquid"
              value={progressValue}
              showLabel
              size={64}
              color="white"
              labelColor="white"
            />
            <LoaderKitProgress
              type="battery"
              value={progressValue}
              showLabel
              size={64}
              color="white"
              labelColor="white"
            />
            <LoaderKitProgress
              value={progressValue}
              color="white"
              accessibilityLabel="Downloading"
            >
              <TouchableOpacity
                accessibilityLabel="Stop"
                style={styles.stop}
                onPress={() => setIndeterminate(true)}
              />
            </LoaderKitProgress>
            <LoaderKitProgress
              type="border"
              value={progressValue}
              color="white"
            >
              <Button label="Upload" onPress={() => setIndeterminate(false)} />
            </LoaderKitProgress>
          </View>
        </View>

        <View style={styles.custom}>
          <Text style={styles.controlLabel}>
            Custom spec: Blink, count {count}
          </Text>
          <LoaderKitView spec={Blink} params={{ count }} {...common} />
          <View style={styles.row}>
            <Button
              label="-"
              onPress={() => setCount((c) => Math.max(1, c - 1))}
            />
            <Button
              label="+"
              onPress={() => setCount((c) => Math.min(8, c + 1))}
            />
          </View>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#ed5565',
  },
  controls: {
    backgroundColor: 'rgba(204, 43, 63, 0.9)',
    marginHorizontal: 16,
    marginTop: 10,
    padding: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  controlLabel: {
    color: 'white',
    fontSize: 14,
    fontWeight: 'bold',
    marginVertical: 6,
  },
  row: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'center',
  },
  button: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    paddingHorizontal: 12,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
    margin: 4,
  },
  buttonText: {
    color: 'white',
    fontSize: 14,
    fontWeight: 'bold',
  },
  scrollContent: {
    padding: 10,
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
  },
  cell: {
    alignItems: 'center',
    marginBottom: 16,
  },
  indicator: {
    width: 50,
    height: 50,
    marginVertical: 8,
  },
  label: {
    color: 'white',
    fontSize: 11,
    textAlign: 'center',
  },
  linear: {
    alignSelf: 'stretch',
    marginVertical: 8,
  },
  stop: {
    width: 14,
    height: 14,
    borderRadius: 3,
    backgroundColor: 'white',
  },
  custom: {
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 8,
    padding: 12,
    marginTop: 8,
  },
});
