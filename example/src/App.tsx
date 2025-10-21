import { useState } from 'react';
import {
  View,
  StyleSheet,
  ScrollView,
  Text,
  TouchableOpacity,
  Platform,
  SafeAreaView,
  Dimensions,
} from 'react-native';
import {
  LoaderKitView,
  IOS_ONLY_INDICATORS,
  getAvailableIndicators,
  type IndicatorName,
} from 'react-native-loader-kit';

const { width: screenWidth } = Dimensions.get('window');

// Get indicators based on platform using typed exports
const getIndicators = (): readonly IndicatorName[] => {
  return getAvailableIndicators(Platform.OS as 'ios' | 'android');
};

// Generate display names
const getDisplayName = (name: IndicatorName) => {
  return name
    .replace(/([A-Z])/g, ' $1')
    .replace(/^./, (str) => str.toUpperCase())
    .trim();
};

export default function App() {
  const [speed, setSpeed] = useState(1.0);
  const indicators = getIndicators();

  const spacing = 10;
  const columns = 4;
  const itemWidth = (screenWidth - spacing * (columns + 1)) / columns;
  const itemHeight = itemWidth + 45; // Extra height for label

  const renderIndicator = (name: IndicatorName, index: number) => {
    const isIOSOnly = IOS_ONLY_INDICATORS.includes(name as any);
    const backgroundColor =
      isIOSOnly && Platform.OS === 'android'
        ? 'rgba(255, 255, 255, 0.3)'
        : 'transparent';

    return (
      <View
        key={name}
        style={[
          styles.indicatorContainer,
          {
            width: itemWidth,
            height: itemHeight,
            backgroundColor,
          },
        ]}
      >
        <View style={styles.indicatorWrapper}>
          <LoaderKitView
            name={name}
            color="blue"
            animationSpeedMultiplier={speed}
            style={styles.indicator}
          />
        </View>
        <Text style={styles.label}>
          {index + 1}. {getDisplayName(name)}
          {isIOSOnly && Platform.OS === 'ios' && (
            <Text style={styles.iosLabel}> (iOS)</Text>
          )}
        </Text>
      </View>
    );
  };

  return (
    <SafeAreaView style={styles.container}>
      {/* Speed Control */}
      <View style={styles.speedContainer}>
        <Text style={styles.speedLabel}>Speed: {speed.toFixed(1)}x</Text>
        <View style={styles.speedButtons}>
          <TouchableOpacity
            style={styles.speedButton}
            onPress={() => setSpeed(Math.max(0.1, speed - 0.1))}
          >
            <Text style={styles.speedButtonText}>-</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.speedButton}
            onPress={() => setSpeed(Math.min(3.0, speed + 0.1))}
          >
            <Text style={styles.speedButtonText}>+</Text>
          </TouchableOpacity>
        </View>
      </View>

      {/* Indicators Grid */}
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.scrollContent}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.grid}>
          {indicators.map((name, index) => renderIndicator(name, index))}
        </View>

        {/* Platform Info */}
        <View style={styles.infoContainer}>
          <Text style={styles.infoText}>
            Platform:{' '}
            {Platform.OS.charAt(0).toUpperCase() + Platform.OS.slice(1)}
          </Text>
          <Text style={styles.infoText}>
            Available Indicators: {indicators.length}
          </Text>
          {Platform.OS === 'ios' && IOS_ONLY_INDICATORS.length > 0 && (
            <Text style={styles.infoText}>
              iOS-Only: {IOS_ONLY_INDICATORS.length} indicators
            </Text>
          )}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#ed5565', // iOS-style red background
  },
  speedContainer: {
    backgroundColor: 'rgba(204, 43, 63, 0.9)',
    marginHorizontal: 20,
    marginTop: 10,
    padding: 15,
    borderRadius: 8,
    alignItems: 'center',
  },
  speedLabel: {
    color: 'white',
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 10,
  },
  speedButtons: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  speedButton: {
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    width: 40,
    height: 40,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    marginHorizontal: 10,
  },
  speedButtonText: {
    color: 'white',
    fontSize: 18,
    fontWeight: 'bold',
  },
  scrollView: {
    flex: 1,
    marginTop: 10,
  },
  scrollContent: {
    padding: 10,
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
  },
  indicatorContainer: {
    alignItems: 'center',
    marginBottom: 15,
    borderRadius: 8,
    padding: 5,
  },
  indicatorWrapper: {
    alignItems: 'center',
    justifyContent: 'center',
    flex: 1,
  },
  indicator: {
    width: 50,
    height: 50,
  },
  label: {
    color: 'white',
    fontSize: 10,
    textAlign: 'center',
    marginTop: 5,
    flexWrap: 'wrap',
  },
  iosLabel: {
    fontSize: 8,
    fontStyle: 'italic',
    opacity: 0.8,
  },
  infoContainer: {
    backgroundColor: 'rgba(255, 255, 255, 0.1)',
    margin: 10,
    padding: 15,
    borderRadius: 8,
    alignItems: 'center',
  },
  infoText: {
    color: 'white',
    fontSize: 12,
    marginVertical: 2,
  },
});
