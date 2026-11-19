package com.liveactivitiesdemo.liveactivity

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import kotlin.math.max

/** Static order info (fixed for the whole order). Mirrors OrderActivityAttributes on iOS. */
data class OrderInfo(
  val orderNumber: String,
  val storeName: String,
  val itemsSummary: String,
)

/** Changing state. Mirrors OrderActivityAttributes.ContentState on iOS. */
data class OrderState(
  /** 0 = confirmed, 1 = preparing, 2 = on the way, 3 = delivered */
  val step: Int,
  val statusText: String,
  /** Estimated arrival, epoch millis */
  val etaTimestamp: Long,
)

/**
 * Builds the Android counterpart of an iOS Live Activity.
 *
 * - Android 16+ (API 36): a promoted "Live Update" using Notification.ProgressStyle,
 *   shown expanded on the lock screen with a status-bar chip.
 * - Older versions: a regular ongoing notification with a progress bar.
 */
object OrderNotification {
  const val CHANNEL_ID = "order_live_updates"
  private const val STEPS = 4
  private const val ORANGE = 0xFFFF8C00.toInt()

  fun ensureChannel(context: Context) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
    val manager = context.getSystemService(NotificationManager::class.java)
    if (manager.getNotificationChannel(CHANNEL_ID) != null) return
    // Live Updates are not allowed on IMPORTANCE_MIN channels.
    val channel = NotificationChannel(
      CHANNEL_ID,
      "Order updates",
      NotificationManager.IMPORTANCE_DEFAULT,
    ).apply {
      description = "Live progress of your current order"
      setSound(null, null)
    }
    manager.createNotificationChannel(channel)
  }

  fun build(context: Context, order: OrderInfo, state: OrderState, isFinal: Boolean): Notification =
    if (Build.VERSION.SDK_INT >= 36) {
      buildLiveUpdate(context, order, state, isFinal)
    } else {
      buildLegacy(context, order, state, isFinal)
    }

  // Android 16+: Live Update with ProgressStyle
  @RequiresApi(36)
  private fun buildLiveUpdate(
    context: Context,
    order: OrderInfo,
    state: OrderState,
    isFinal: Boolean,
  ): Notification {
    val segmentLength = 100 / STEPS
    val style = Notification.ProgressStyle()
      .setStyledByProgress(true)
      .setProgressSegments(
        List(STEPS) { Notification.ProgressStyle.Segment(segmentLength).setColor(ORANGE) },
      )
      .setProgressPoints(
        (1 until STEPS).map {
          Notification.ProgressStyle.Point(it * segmentLength).setColor(ORANGE)
        },
      )
      .setProgress(progressFor(state.step))

    val builder = Notification.Builder(context, CHANNEL_ID)
      .setSmallIcon(android.R.drawable.ic_dialog_info) // replace with your monochrome app icon
      .setContentTitle(state.statusText)
      .setContentText("${order.storeName} · Order #${order.orderNumber}")
      .setSubText(order.itemsSummary)
      .setContentIntent(openOrderIntent(context, order))
      .setStyle(style)
      .setOnlyAlertOnce(true)

    val delivered = state.step >= STEPS - 1
    if (isFinal || delivered) {
      // Final state: no longer ongoing, so it is a normal, dismissible notification.
      builder.setOngoing(false).setAutoCancel(true)
    } else {
      builder
        .setOngoing(true)
        .setRequestPromotedOngoing(true)
        // Live countdown in the status-bar chip, rendered by the system
        .setWhen(state.etaTimestamp)
        .setShowWhen(true)
        .setUsesChronometer(true)
        .setChronometerCountDown(true)
        .setShortCriticalText(minutesLeftText(state.etaTimestamp))
    }
    return builder.build()
  }

  // Android 15 and below: ongoing notification with a progress bar
  private fun buildLegacy(
    context: Context,
    order: OrderInfo,
    state: OrderState,
    isFinal: Boolean,
  ): Notification {
    val delivered = isFinal || state.step >= STEPS - 1
    return NotificationCompat.Builder(context, CHANNEL_ID)
      .setSmallIcon(android.R.drawable.ic_dialog_info)
      .setContentTitle(state.statusText)
      .setContentText(
        if (delivered) "${order.storeName} · Order #${order.orderNumber}"
        else "Arriving in ${minutesLeftText(state.etaTimestamp)} · ${order.storeName}",
      )
      .setSubText("Order #${order.orderNumber}")
      .setColor(ORANGE)
      .setProgress(100, progressFor(state.step), false)
      .setContentIntent(openOrderIntent(context, order))
      .setOnlyAlertOnce(true)
      .setOngoing(!delivered)
      .setAutoCancel(delivered)
      .setCategory(NotificationCompat.CATEGORY_PROGRESS)
      .setPriority(NotificationCompat.PRIORITY_DEFAULT)
      .build()
  }

  private fun progressFor(step: Int): Int =
    if (step >= STEPS - 1) 100 else (step.coerceAtLeast(0) * (100 / STEPS)) + (100 / STEPS) / 2

  private fun minutesLeftText(etaMillis: Long): String {
    val minutes = max(0L, (etaMillis - System.currentTimeMillis()) / 60_000L)
    return if (minutes <= 0) "now" else "$minutes min"
  }

  /** Tapping the notification deep-links back into the order screen. */
  private fun openOrderIntent(context: Context, order: OrderInfo): PendingIntent {
    val intent = Intent(Intent.ACTION_VIEW, Uri.parse("liveactivitiesdemo://order/${order.orderNumber}"))
      .setPackage(context.packageName)
      .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
    return PendingIntent.getActivity(
      context,
      order.orderNumber.hashCode(),
      intent,
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
  }
}
