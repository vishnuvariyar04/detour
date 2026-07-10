package com.brainpass.brainpass

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log

/**
 * Self-healing watchdog. A repeating alarm wakes us every few minutes and:
 *   1. ensures the guard service is running (restarts it if the OS killed it),
 *   2. checks the required permissions are still granted, and if not, posts a
 *      visible warning notification so gating never fails SILENTLY.
 *
 * Alarms are held by the system, so this fires and restarts the guard even after
 * the app process was killed — provided the OEM allows the background start
 * (which is exactly what enabling Autostart unlocks; see [Autostart]).
 */
class WatchdogReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "NupoWatchdog"
        private const val REQ = 7011
        private const val INTERVAL = 3 * 60 * 1000L // 3 minutes
        private const val WARN_CHANNEL = "brainpass_warning"
        private const val WARN_ID = 4202

        /** Schedule the next watchdog wake-up. */
        fun schedule(ctx: Context, delay: Long = INTERVAL) {
            try {
                val am = ctx.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                am.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    System.currentTimeMillis() + delay,
                    pending(ctx)
                )
            } catch (e: Throwable) {
                Log.e(TAG, "schedule failed", e)
            }
        }

        private fun pending(ctx: Context): PendingIntent {
            val i = Intent(ctx, WatchdogReceiver::class.java).setAction("brainpass.WATCHDOG")
            val flags = PendingIntent.FLAG_UPDATE_CURRENT or
                (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            return PendingIntent.getBroadcast(ctx, REQ, i, flags)
        }

        /**
         * Post (or refresh) the "needs attention" warning right now. Callable
         * from anywhere — GuardService uses this for an INSTANT alert the
         * moment it notices a permission is gone, rather than waiting up to
         * [INTERVAL] for the next scheduled alarm.
         */
        fun warnNow(ctx: Context) {
            try {
                val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    nm.createNotificationChannel(
                        NotificationChannel(
                            WARN_CHANNEL, "Nupo alerts", NotificationManager.IMPORTANCE_HIGH
                        ).apply { description = "Warns you if Nupo's lessons stop working." }
                    )
                }
                val tap = PendingIntent.getActivity(
                    ctx, 1,
                    Intent(ctx, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                    (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
                )
                val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    Notification.Builder(ctx, WARN_CHANNEL) else @Suppress("DEPRECATION") Notification.Builder(ctx)
                val notif = builder
                    .setContentTitle("Nupo needs attention")
                    .setContentText("A permission is off — tap to fix.")
                    .setSmallIcon(android.R.drawable.stat_notify_error)
                    .setContentIntent(tap)
                    .setAutoCancel(true)
                    .setOngoing(true)
                    .build()
                nm.notify(WARN_ID, notif)
            } catch (e: Throwable) {
                Log.e(TAG, "warnNow failed", e)
            }
        }

        fun cancelWarningNow(ctx: Context) {
            try {
                (ctx.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancel(WARN_ID)
            } catch (_: Throwable) {
            }
        }
    }

    override fun onReceive(ctx: Context, intent: Intent) {
        schedule(ctx) // chain the next wake-up

        // Only act once the parent has set the app up.
        if (EnginePrefs.gatedApps(ctx).isEmpty()) return

        val usage = GuardService.hasUsageAccess(ctx)
        val overlay = Settings.canDrawOverlays(ctx)
        if (usage && overlay) {
            GuardService.start(ctx) // ensure / restart the guard
            cancelWarningNow(ctx)
        } else {
            warnNow(ctx)
        }
    }

}
