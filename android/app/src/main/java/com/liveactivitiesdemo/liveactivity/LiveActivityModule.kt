package com.liveactivitiesdemo.liveactivity

import android.app.NotificationManager
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

/**
 * Android side of the same JavaScript API as the iOS LiveActivityModule.
 * Each "activity" is an ongoing notification (a Live Update on Android 16+).
 */
class LiveActivityModule(private val reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  companion object {
    const val NAME = "LiveActivityModule"
    private val nextId = AtomicInteger(1000)
    private val orders = ConcurrentHashMap<Int, OrderInfo>()
  }

  override fun getName() = NAME

  private val notifications get() = NotificationManagerCompat.from(reactContext)

  @ReactMethod
  fun isSupported(promise: Promise) {
    promise.resolve(notifications.areNotificationsEnabled())
  }

  /** Extra Android detail: can this app post promoted Live Updates (Android 16+)? */
  @ReactMethod
  fun getAndroidCapabilities(promise: Promise) {
    val result = Arguments.createMap()
    result.putBoolean("notificationsEnabled", notifications.areNotificationsEnabled())
    val canPromote = if (Build.VERSION.SDK_INT >= 36) {
      reactContext.getSystemService(NotificationManager::class.java).canPostPromotedNotifications()
    } else {
      false
    }
    result.putBoolean("liveUpdatesSupported", Build.VERSION.SDK_INT >= 36)
    result.putBoolean("liveUpdatesEnabled", canPromote)
    promise.resolve(result)
  }

  /** Opens the system screen where the user can turn Live Updates on for this app (Android 16+). */
  @ReactMethod
  fun openLiveUpdateSettings(promise: Promise) {
    val intent = if (Build.VERSION.SDK_INT >= 36) {
      Intent(Settings.ACTION_MANAGE_APP_PROMOTED_NOTIFICATIONS)
    } else {
      Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
    }
      .putExtra(Settings.EXTRA_APP_PACKAGE, reactContext.packageName)
      .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    reactContext.startActivity(intent)
    promise.resolve(null)
  }

  @ReactMethod
  fun start(order: ReadableMap, state: ReadableMap, promise: Promise) {
    if (!notifications.areNotificationsEnabled()) {
      promise.reject("DISABLED", "Notifications are turned off for this app")
      return
    }
    try {
      OrderNotification.ensureChannel(reactContext)
      val info = order.toOrderInfo()
      val id = nextId.incrementAndGet()
      orders[id] = info
      post(id, info, state.toOrderState(), isFinal = false)
      promise.resolve(id.toString())
    } catch (e: Exception) {
      promise.reject("START_FAILED", e.message, e)
    }
  }

  @ReactMethod
  fun update(activityId: String, state: ReadableMap, promise: Promise) {
    val id = activityId.toIntOrNull()
    val info = id?.let { orders[it] }
    if (id == null || info == null) {
      promise.reject("NOT_FOUND", "No live update with id $activityId")
      return
    }
    post(id, info, state.toOrderState(), isFinal = false)
    promise.resolve(null)
  }

  @ReactMethod
  fun end(activityId: String, finalState: ReadableMap?, promise: Promise) {
    val id = activityId.toIntOrNull()
    if (id == null) {
      promise.resolve(null)
      return
    }
    val info = orders.remove(id)
    if (finalState != null && info != null) {
      // Leave a normal, dismissible "Delivered" notification behind
      post(id, info, finalState.toOrderState(), isFinal = true)
    } else {
      notifications.cancel(id)
    }
    promise.resolve(null)
  }

  @ReactMethod
  fun endAll(promise: Promise) {
    orders.keys.forEach { notifications.cancel(it) }
    orders.clear()
    promise.resolve(null)
  }

  @Suppress("MissingPermission") // checked via areNotificationsEnabled() before start
  private fun post(id: Int, info: OrderInfo, state: OrderState, isFinal: Boolean) {
    if (!notifications.areNotificationsEnabled()) return
    notifications.notify(id, OrderNotification.build(reactContext, info, state, isFinal))
  }

  private fun ReadableMap.str(key: String) = if (hasKey(key)) getString(key) ?: "" else ""

  private fun ReadableMap.toOrderInfo() = OrderInfo(
    orderNumber = str("orderNumber"),
    storeName = str("storeName"),
    itemsSummary = str("itemsSummary"),
  )

  private fun ReadableMap.toOrderState() = OrderState(
    step = if (hasKey("step")) getInt("step") else 0,
    statusText = str("statusText"),
    etaTimestamp = if (hasKey("etaTimestamp")) getDouble("etaTimestamp").toLong()
    else System.currentTimeMillis(),
  )
}
