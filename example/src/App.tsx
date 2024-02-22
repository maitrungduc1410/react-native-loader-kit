import React from 'react';
import {
  StyleSheet,
  Text,
  View,
  StatusBar,
  SafeAreaView,
  Dimensions,
} from 'react-native';
import LoaderKit, { animations } from 'react-native-loader-kit';

const { height } = Dimensions.get('window');

const App = () => {
  const renderLoaders = animations.map((item, index) => (
    <View style={{ margin: 10 }} key={index}>
      <Text style={{ color: 'white', textAlign: 'center' }}>{index + 1}</Text>
      <LoaderKit style={{ width: 50, height: 50, marginTop: 3 }} name={item} />
    </View>
  ));

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle={'light-content'} backgroundColor={'#ed5565'} />
      {renderLoaders}
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#ed5565',
    flexDirection: 'row',
    flexWrap: 'wrap',
    height,
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default App;
