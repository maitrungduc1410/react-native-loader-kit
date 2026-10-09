package com.loaderkit

import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.viewmanagers.LoaderKitProgressViewManagerDelegate
import com.facebook.react.viewmanagers.LoaderKitProgressViewManagerInterface
import io.github.maitrungduc1410.loaderkit.ProgressStrokeCap
import io.github.maitrungduc1410.loaderkit.ProgressType
import io.github.maitrungduc1410.loaderkit.ProgressVariant

/**
 * Hosts the LoaderKit progress view for the `LoaderKitProgressView` Fabric component. The options
 * arrive resolved from JavaScript, which also lays out the view.
 */
@ReactModule(name = LoaderKitProgressViewManager.NAME)
class LoaderKitProgressViewManager :
  SimpleViewManager<LoaderKitProgressHostView>(),
  LoaderKitProgressViewManagerInterface<LoaderKitProgressHostView> {

  private val delegate = LoaderKitProgressViewManagerDelegate(this)

  override fun getDelegate(): ViewManagerDelegate<LoaderKitProgressHostView> = delegate

  override fun getName(): String = NAME

  override fun createViewInstance(context: ThemedReactContext): LoaderKitProgressHostView =
    LoaderKitProgressHostView(context)

  override fun prepareToRecycleView(
    reactContext: ThemedReactContext,
    view: LoaderKitProgressHostView,
  ): LoaderKitProgressHostView? {
    val recycled = super.prepareToRecycleView(reactContext, view) ?: return null
    recycled.reset()
    return recycled
  }

  // The props of an update arrive in no particular order, so the value waits for smooth and the
  // drawing options.
  override fun onAfterUpdateTransaction(view: LoaderKitProgressHostView) {
    super.onAfterUpdateTransaction(view)
    view.applyPendingValues()
  }

  override fun setValue(view: LoaderKitProgressHostView, value: Double) {
    view.setValue(value.takeIf { it >= 0 })
  }

  override fun setBuffer(view: LoaderKitProgressHostView, value: Double) {
    view.setBuffer(value.takeIf { it >= 0 })
  }

  override fun setSmooth(view: LoaderKitProgressHostView, value: Boolean) {
    view.progress.smooth = value
  }

  override fun setType(view: LoaderKitProgressHostView, value: String?) {
    view.progress.type = ProgressType.of(value)
  }

  override fun setVariant(view: LoaderKitProgressHostView, value: String?) {
    view.progress.variant = ProgressVariant.of(value)
  }

  override fun setThickness(view: LoaderKitProgressHostView, value: Double) {
    view.progress.thickness = value
  }

  override fun setTrackGap(view: LoaderKitProgressHostView, value: Double) {
    view.progress.trackGap = value
  }

  override fun setSegments(view: LoaderKitProgressHostView, value: Int) {
    view.progress.segments = value
  }

  override fun setShowLabel(view: LoaderKitProgressHostView, value: Boolean) {
    view.progress.showLabel = value
  }

  override fun setStopIndicator(view: LoaderKitProgressHostView, value: Boolean) {
    view.progress.stopIndicator = value
  }

  override fun setStrokeCap(view: LoaderKitProgressHostView, value: String?) {
    view.progress.strokeCap = ProgressStrokeCap.of(value) ?: ProgressStrokeCap.Round
  }

  override fun setAmplitude(view: LoaderKitProgressHostView, value: Double) {
    view.progress.amplitude = value
  }

  override fun setWavelength(view: LoaderKitProgressHostView, value: Double) {
    view.progress.wavelength = value
  }

  override fun setWaveSpeed(view: LoaderKitProgressHostView, value: Double) {
    view.progress.waveSpeed = value
  }

  override fun setSweepAngle(view: LoaderKitProgressHostView, value: Double) {
    view.progress.sweepAngle = value
  }

  override fun setCornerRadius(view: LoaderKitProgressHostView, value: Double) {
    view.progress.cornerRadius = value
  }

  override fun setSpeed(view: LoaderKitProgressHostView, value: Double) {
    view.progress.speed = value
  }

  override fun setColor(view: LoaderKitProgressHostView, value: Int?) {
    view.progress.color = value ?: view.defaultColor
  }

  override fun setTrackColor(view: LoaderKitProgressHostView, value: Int?) {
    view.progress.trackColor = value
  }

  override fun setLabelColor(view: LoaderKitProgressHostView, value: Int?) {
    view.progress.labelColor = value ?: view.defaultLabelColor
  }

  override fun setReduceMotion(view: LoaderKitProgressHostView, value: String?) {
    view.progress.respectsReduceMotion = value != "never"
  }

  override fun setProgressAccessibilityLabel(view: LoaderKitProgressHostView, value: String?) {
    view.progress.contentDescription = value?.takeIf { it.isNotEmpty() }
  }

  companion object {
    const val NAME = "LoaderKitProgressView"
  }
}
