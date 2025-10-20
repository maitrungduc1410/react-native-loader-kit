package com.testrncompatview

import android.view.View
import com.facebook.react.uimanager.SimpleViewManager

abstract class LoaderKitViewManagerSpec<T : View> : SimpleViewManager<T>() {
  abstract fun setColor(view: T?, value: Int)
  abstract fun setName(view: T?, value: String?)
  abstract fun setAnimationSpeedMultiplier(view: T?, value: Float)
}
