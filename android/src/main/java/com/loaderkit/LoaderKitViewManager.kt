package com.loaderkit

import android.graphics.Color
import android.util.Log
import com.facebook.react.bridge.ColorPropConverter
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.common.build.ReactBuildConfig
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.viewmanagers.LoaderKitViewManagerDelegate
import com.facebook.react.viewmanagers.LoaderKitViewManagerInterface
import io.github.maitrungduc1410.loaderkit.LoaderKitView
import org.json.JSONException
import org.json.JSONObject
import java.util.WeakHashMap

/**
 * Hosts the LoaderKit core view for the `LoaderKitView` Fabric component, with the semantics and
 * defaults of the React props, which differ from those of the core view.
 */
@ReactModule(name = LoaderKitViewManager.NAME)
class LoaderKitViewManager :
  SimpleViewManager<LoaderKitView>(),
  LoaderKitViewManagerInterface<LoaderKitView> {

  private val delegate = LoaderKitViewManagerDelegate(this)

  /** Props that combine before they reach the core view. */
  private class Playback {
    var cycleProgress = -1f
    var reduceMotion = ReduceMotion.System
  }

  private enum class ReduceMotion { System, Never, Always }

  private val playback = WeakHashMap<LoaderKitView, Playback>()

  override fun getDelegate(): ViewManagerDelegate<LoaderKitView> = delegate

  override fun getName(): String = NAME

  override fun createViewInstance(context: ThemedReactContext): LoaderKitView =
    LoaderKitView(context).apply {
      onError = { error -> debugLog(error.message.orEmpty()) }
      applyReactDefaults(this)
    }

  override fun prepareToRecycleView(reactContext: ThemedReactContext, view: LoaderKitView): LoaderKitView? {
    val recycled = super.prepareToRecycleView(reactContext, view) ?: return null
    recycled.reset()
    applyReactDefaults(recycled)
    return recycled
  }

  private fun applyReactDefaults(view: LoaderKitView) {
    playback[view] = Playback()
    view.color = Color.WHITE
    view.hidesWhenStopped = false
  }

  private fun playbackOf(view: LoaderKitView): Playback = playback.getOrPut(view, ::Playback)

  override fun setName(view: LoaderKitView, value: String?) {
    view.indicator = value ?: LoaderKitView.DEFAULT_INDICATOR
  }

  override fun setSpecJson(view: LoaderKitView, value: String?) {
    view.setSpecJson(value?.takeIf { it.isNotEmpty() })
  }

  override fun setParamsJson(view: LoaderKitView, value: String?) {
    view.params = parseParams(value)
  }

  override fun setColor(view: LoaderKitView, value: Int?) {
    view.color = value ?: Color.WHITE
  }

  override fun setColors(view: LoaderKitView, value: ReadableArray?) {
    val items = value?.toArrayList().orEmpty()
    val colors = items.map { item ->
      try {
        ColorPropConverter.getColor(item, view.context) ?: Color.WHITE
      } catch (error: RuntimeException) {
        debugLog("colors: $item is not a color, white is used (${error.message})")
        Color.WHITE
      }
    }
    view.colors = colors.takeIf { it.isNotEmpty() }?.toIntArray()
  }

  override fun setSpeed(view: LoaderKitView, value: Float) {
    view.speed = value.toDouble()
  }

  override fun setAnimating(view: LoaderKitView, value: Boolean) {
    view.isAnimating = value
  }

  override fun setHidesWhenStopped(view: LoaderKitView, value: Boolean) {
    view.hidesWhenStopped = value
  }

  override fun setCycleProgress(view: LoaderKitView, value: Float) {
    playbackOf(view).cycleProgress = value
    applyCycleProgress(view)
  }

  override fun setReduceMotion(view: LoaderKitView, value: String?) {
    val mode = when (value) {
      "never" -> ReduceMotion.Never
      "always" -> ReduceMotion.Always
      else -> ReduceMotion.System
    }
    playbackOf(view).reduceMotion = mode
    view.respectsReduceMotion = mode == ReduceMotion.System
    applyCycleProgress(view)
  }

  private fun applyCycleProgress(view: LoaderKitView) {
    val state = playbackOf(view)
    view.cycleProgress = when {
      state.cycleProgress >= 0 -> state.cycleProgress.toDouble()
      state.reduceMotion == ReduceMotion.Always -> 0.0
      else -> null
    }
  }

  /** A JSON object of numbers; anything else is ignored, entry by entry. */
  private fun parseParams(json: String?): Map<String, Double> {
    if (json.isNullOrEmpty()) return emptyMap()
    val entries = try {
      JSONObject(json)
    } catch (error: JSONException) {
      debugLog("paramsJson is not a JSON object: $json")
      return emptyMap()
    }
    val params = mutableMapOf<String, Double>()
    val invalid = mutableListOf<String>()
    for (key in entries.keys()) {
      val value = entries.opt(key)
      if (value is Number) params[key] = value.toDouble() else invalid += key
    }
    if (invalid.isNotEmpty()) debugLog("params must be numbers, ignored: ${invalid.sorted().joinToString()}")
    return params
  }

  private fun debugLog(message: String) {
    if (ReactBuildConfig.DEBUG) Log.w(NAME, message)
  }

  companion object {
    const val NAME = "LoaderKitView"
  }
}
