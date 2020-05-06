package com.reactlibrary;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.wang.avi.AVLoadingIndicatorView;

public class LoaderKitManager extends SimpleViewManager<AVLoadingIndicatorView> {
    public static final String REACT_CLASS = "LoaderKit";

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @Override
    public AVLoadingIndicatorView createViewInstance(ThemedReactContext context) {
        AVLoadingIndicatorView avi = new AVLoadingIndicatorView(context, null, R.style.AVLoadingIndicatorView);
        return avi;
    }

    @ReactProp(name = "name")
    public void setName(AVLoadingIndicatorView view, String name) {
        view.setIndicator(name + "Indicator");
    }

    @ReactProp(name = "color")
    public void setColor(AVLoadingIndicatorView view, int color) {
        view.setIndicatorColor(color);
    }
}
