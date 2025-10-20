package com.testrncompatview

import android.view.View

import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.viewmanagers.LoaderKitViewManagerDelegate
import com.facebook.react.viewmanagers.LoaderKitViewManagerInterface

abstract class LoaderKitViewManagerSpec<T : View> : SimpleViewManager<T>(), LoaderKitViewManagerInterface<T> {
  private val mDelegate: ViewManagerDelegate<T> = LoaderKitViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<T>? {
    return mDelegate
  }
}
