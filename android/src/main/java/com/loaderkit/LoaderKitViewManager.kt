package com.loaderkit

import android.graphics.Color
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.LoaderKitViewManagerInterface
import com.facebook.react.viewmanagers.LoaderKitViewManagerDelegate
import com.wang.avi.AVLoadingIndicatorView;

@ReactModule(name = LoaderKitViewManager.NAME)
class LoaderKitViewManager : SimpleViewManager<AVLoadingIndicatorView>(),
  LoaderKitViewManagerInterface<AVLoadingIndicatorView> {
  private val mDelegate: ViewManagerDelegate<AVLoadingIndicatorView>

  init {
    mDelegate = LoaderKitViewManagerDelegate(this)
  }

  override fun getDelegate(): ViewManagerDelegate<AVLoadingIndicatorView>? {
    return mDelegate
  }

  override fun getName(): String {
    return NAME
  }

  public override fun createViewInstance(context: ThemedReactContext): AVLoadingIndicatorView {
    return AVLoadingIndicatorView(context)
  }

  @ReactProp(name = "name")
  override fun setName(view: AVLoadingIndicatorView?, name: String?) {
    name?.let {
      view?.setIndicator("${it}Indicator")
    }
  }

  @ReactProp(name = "color", defaultInt = Color.WHITE)
  override fun setColor(view: AVLoadingIndicatorView?, color: Int) {
    view?.setIndicatorColor(color)
  }

  @ReactProp(name = "animationSpeedMultiplier", defaultFloat = 1f)
  override fun setAnimationSpeedMultiplier(view: AVLoadingIndicatorView?, value: Float) {
    view?.animationSpeedMultiplier = value
  }

  companion object {
    const val NAME = "LoaderKitView"
  }
}
