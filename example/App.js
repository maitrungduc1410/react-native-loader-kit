import React from 'react';
import { StyleSheet, Text, View, StatusBar, SafeAreaView, Dimensions } from 'react-native';
import LoaderKit from 'react-native-loader-kit';
import animations from '../animations'

const { height } = Dimensions.get('window')

const App = (props) => {
  const renderLoaders = animations.map((item,  index) => (
    <View style={{ margin: 10 }} key={index}>
      <Text style={{ color: 'white', textAlign: 'center' }}>{index + 1}</Text>
      <LoaderKit
        style={{ width: 50, height: 50, marginTop: 3 }}
        name={item}
        size={50}
      />
    </View>
  ))
  
  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle={"light-content"} backgroundColor={'#ed5565'} />
      {renderLoaders}
    </SafeAreaView>
  )
}

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#ed5565',
    flexDirection: 'row',
    flexWrap: 'wrap',
    height,
    justifyContent: 'center',
    alignItems: 'center'
  },
});

export default App