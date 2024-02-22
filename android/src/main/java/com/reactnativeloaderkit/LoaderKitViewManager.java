package com.reactnativeloaderkit;

import android.graphics.Color;
import android.view.View;

import androidx.annotation.NonNull;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.wang.avi.AVLoadingIndicatorView;

public class LoaderKitViewManager extends SimpleViewManager<AVLoadingIndicatorView> {
  public static final String REACT_CLASS = "LoaderKitView";

  @Override
  @NonNull
  public String getName() {
    return REACT_CLASS;
  }

  @Override
  public AVLoadingIndicatorView createViewInstance(ThemedReactContext context) {
    return new AVLoadingIndicatorView(context, null, com.wang.avi.R.style.AVLoadingIndicatorView);
  }

  @ReactProp(name = "name")
  public void setName(AVLoadingIndicatorView view, String name) {
    view.setIndicator(name != null ? name + "Indicator" : "BallPulseIndicator");
  }

  @ReactProp(name = "color", defaultInt = Color.WHITE)
  public void setColor(AVLoadingIndicatorView view, int color) {
    view.setIndicatorColor(color);
  }
}
