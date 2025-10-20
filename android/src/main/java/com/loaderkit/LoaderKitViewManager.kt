package com.loaderkit

import android.graphics.Color
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.annotations.ReactProp
import com.testrncompatview.LoaderKitViewManagerSpec
import com.wang.avi.AVLoadingIndicatorView;

@ReactModule(name = LoaderKitViewManager.NAME)
class LoaderKitViewManager : LoaderKitViewManagerSpec<AVLoadingIndicatorView>() {

  override fun getName(): String {
    return NAME
  }

  public override fun createViewInstance(context: ThemedReactContext): AVLoadingIndicatorView {
    return AVLoadingIndicatorView(context)
  }

  @ReactProp(name = "name")
  override fun setName(view: AVLoadingIndicatorView?, value: String?) {
    value?.let {
      view?.setIndicator("${it}Indicator")
    }
  }

  @ReactProp(name = "color", defaultInt = Color.WHITE)
  override fun setColor(view: AVLoadingIndicatorView?, value: Int) {
    view?.setIndicatorColor(value)
  }

  @ReactProp(name = "animationSpeedMultiplier", defaultFloat = 1f)
  override fun setAnimationSpeedMultiplier(view: AVLoadingIndicatorView?, value: Float) {
    view?.animationSpeedMultiplier = value
  }

  companion object {
    const val NAME = "LoaderKitView"
  }
}
