package com.loaderkit

import android.content.Context
import android.widget.FrameLayout
import androidx.annotation.ColorInt
import com.facebook.react.uimanager.PointerEvents
import com.facebook.react.uimanager.ReactPointerEventsView
import io.github.maitrungduc1410.loaderkit.LoaderKitProgressView

/**
 * The view of the `LoaderKitProgressView` Fabric component: the LoaderKit progress view, filling
 * the box React gives it. The React children of `LoaderKitProgress` are siblings drawn above it.
 */
class LoaderKitProgressHostView(context: Context) :
  FrameLayout(context),
  ReactPointerEventsView {
  val progress = LoaderKitProgressView(context)

  // Touches go to the container of LoaderKitProgress, or through it with `box-none`.
  override val pointerEvents: PointerEvents = PointerEvents.NONE

  @ColorInt
  val defaultColor: Int = progress.color

  @ColorInt
  val defaultLabelColor: Int = progress.labelColor

  private var pendingValue: Double? = null
  private var pendingBuffer: Double? = null
  private var hasPendingValue = false
  private var hasPendingBuffer = false

  init {
    addView(progress, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
  }

  /** Applied by [applyPendingValues], once the other props of the same update are set. */
  fun setValue(value: Double?) {
    pendingValue = value
    hasPendingValue = true
  }

  fun setBuffer(value: Double?) {
    pendingBuffer = value
    hasPendingBuffer = true
  }

  /** Sets the value and buffer, without gliding to them before the view is on screen. */
  fun applyPendingValues() {
    if (!hasPendingValue && !hasPendingBuffer) return
    val smooth = progress.smooth
    if (!isAttachedToWindow) progress.smooth = false
    try {
      if (hasPendingBuffer) progress.buffer = pendingBuffer
      if (hasPendingValue) progress.value = pendingValue
    } finally {
      progress.smooth = smooth
      hasPendingValue = false
      hasPendingBuffer = false
    }
  }

  fun reset() {
    hasPendingValue = false
    hasPendingBuffer = false
    progress.reset()
    progress.contentDescription = null
  }

  override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
    val width = right - left
    val height = bottom - top
    progress.measure(
      MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY),
      MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY),
    )
    progress.layout(0, 0, width, height)
  }
}
