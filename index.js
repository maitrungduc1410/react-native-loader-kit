import React from 'react'
import PropTypes from 'prop-types'
import { requireNativeComponent, processColor, Platform } from 'react-native'
import animations from './animations'

const LoaderKitNative = requireNativeComponent('LoaderKit')

const LoaderKit = (props) => {
  return (
    <LoaderKitNative
      {...props}
      color={props.color && processColor(props.color)}
    />
  )
}

LoaderKit.propTypes = {
  name: PropTypes.oneOf(animations),
  color: PropTypes.string,
  size: Platform.OS === 'ios' ? PropTypes.number.isRequired : PropTypes.number
}

export default LoaderKit
