package com.brainpass.brainpass

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import android.widget.TextView

/**
 * The whole gating engine, in ONE reliable place.
 *
 * Why this design (rewired for Xiaomi/HyperOS):
 *  - A foreground service is the component the OS is least likely to kill (with
 *    battery exemption + Autostart), and it RESTARTS itself (START_STICKY).
 *  - We detect the foreground app with UsageStatsManager — a *query*, not a live
 *    listener — so the OS can't silently "disable" it the way it disables an
 *    Accessibility Service. This was the root cause of "no gating".
 *  - Time is booked INCREMENTALLY to disk (~1s per tick), so if the process is
 *    killed and restarted mid-session it resumes exactly where it left off — no
 *    more "timer lost track / drifted".
 *  - The 1s loop only runs while the screen is on (no battery cost otherwise).
 */
class GuardService : Service() {

    companion object {
        private const val TAG = "BrainPassGuard"
        private const val CHANNEL = "brainpass_guard"
        private const val NOTIF_ID = 4201

        fun start(ctx: Context) {
            try {
                val i = Intent(ctx, GuardService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) ctx.startForegroundService(i)
                else ctx.startService(i)
            } catch (e: Throwable) {
                Log.e(TAG, "start failed", e)
            }
        }

        /** Does the app hold the "Usage access" special permission? */
        fun hasUsageAccess(ctx: Context): Boolean {
            return try {
                val usm = ctx.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                val now = System.currentTimeMillis()
                // If we can read any events, access is granted.
                val ev = usm.queryEvents(now - 60_000, now)
                ev.hasNextEvent() || run {
                    // No events in the last minute doesn't prove denial; fall back
                    // to a usage-stats query which returns empty when denied.
                    usm.queryUsageStats(UsageStatsManager.INTERVAL_DAILY, now - 86_400_000, now)
                        .isNotEmpty()
                }
            } catch (e: Throwable) {
                false
            }
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var wm: WindowManager? = null
    private var chip: TextView? = null

    private var trackedPkg: String? = null
    private var lastFg: String? = null // last known foreground app (persists between events)
    private var lastTickAt: Long = 0L
    private var lockedPkg: String? = null
    private var lockCooldownUntil: Long = 0L
    private var ticking = false

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(c: Context?, i: Intent?) {
            when (i?.action) {
                Intent.ACTION_SCREEN_ON -> startTicking()
                Intent.ACTION_SCREEN_OFF -> stopTicking()
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        wm = getSystemService(WINDOW_SERVICE) as WindowManager
        createChannel()
        try {
            startForeground(NOTIF_ID, buildNotification())
        } catch (e: Throwable) {
            Log.e(TAG, "startForeground failed", e)
        }
        try {
            registerReceiver(screenReceiver, IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_SCREEN_OFF)
            })
        } catch (_: Throwable) {
        }
        startTicking()
        Log.d(TAG, "guard service started")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startTicking()
        return START_STICKY
    }

    override fun onDestroy() {
        stopTicking()
        try {
            unregisterReceiver(screenReceiver)
        } catch (_: Throwable) {
        }
        Log.w(TAG, "guard service destroyed")
        super.onDestroy()
    }

    private fun startTicking() {
        if (ticking) return
        ticking = true
        lastTickAt = 0L
        handler.post(tick)
    }

    private fun stopTicking() {
        ticking = false
        handler.removeCallbacks(tick)
        trackedPkg = null
        hideChip()
    }

    private val tick = object : Runnable {
        override fun run() {
            try {
                doTick()
            } catch (e: Throwable) {
                Log.e(TAG, "tick error", e)
            }
            if (ticking) handler.postDelayed(this, 1000)
        }
    }

    private fun doTick() {
        val now = System.currentTimeMillis()
        val delta = if (lastTickAt > 0L) (now - lastTickAt).coerceIn(0, 2000) else 0
        lastTickAt = now

        EnginePrefs.rollDayIfNeeded(this)

        if (!EnginePrefs.masterEnabled(this)) {
            idle(); return
        }
        val pkg = currentForegroundApp() ?: return
        if (pkg == packageName) { idle(); return }       // our own lock screen
        if (!EnginePrefs.isGated(this, pkg)) { idle(); return }

        if (EnginePrefs.capReached(this, pkg)) {
            idle(); lock(pkg, "done"); return
        }
        if (EnginePrefs.remMs(this, pkg) <= 0L) {
            idle(); lock(pkg, "earn"); return
        }

        // Allowed and has time: count it down.
        if (pkg != trackedPkg) {
            trackedPkg = pkg
            showChip() // just entered; start the clock next tick
        } else {
            EnginePrefs.consume(this, pkg, delta) // book ~1s to disk (restart-safe)
            if (EnginePrefs.remMs(this, pkg) <= 0L) {
                // Time's up: just CLOSE the app (go home) — NO questions here.
                // Questions appear only when the child next OPENS the app (the
                // entry-lock branch above). Briefly suppress that entry-lock so
                // the lingering foreground frame doesn't pop questions before
                // home takes effect.
                hideChip()
                trackedPkg = null
                lockedPkg = pkg
                lockCooldownUntil = System.currentTimeMillis() + 2500
                Log.d(TAG, "$pkg time up -> home (questions on next open)")
                goHome()
                return
            }
        }
        updateChip(
            "${EnginePrefs.nameOf(this, pkg)}   ${fmt(EnginePrefs.remMs(this, pkg))} left" +
                "   •   ${EnginePrefs.usedMs(this, pkg) / 60_000} min used"
        )
    }

    private fun idle() {
        trackedPkg = null
        hideChip()
    }

    /**
     * The current foreground app. We scan recent "moved to foreground" events and
     * only UPDATE [lastFg] when a newer one is found — otherwise we keep the last
     * known app. This is essential: once you've been in an app for a while there
     * are no new foreground events, so a naive query returns null and the
     * countdown would freeze. Keeping [lastFg] makes the clock keep running until
     * a DIFFERENT app actually comes forward.
     */
    private fun currentForegroundApp(): String? {
        try {
            val usm = getSystemService(USAGE_STATS_SERVICE) as UsageStatsManager
            val end = System.currentTimeMillis()
            // Overlapping 12s window; with 1s ticks every event is seen ~12 times,
            // so we never miss an app switch.
            val ev = usm.queryEvents(end - 12_000, end)
            val e = UsageEvents.Event()
            var newestPkg: String? = null
            var newestT = 0L
            while (ev.hasNextEvent()) {
                ev.getNextEvent(e)
                if (e.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                    if (e.timeStamp >= newestT) {
                        newestT = e.timeStamp
                        newestPkg = e.packageName
                    }
                }
            }
            if (newestPkg != null) lastFg = newestPkg
        } catch (e: Throwable) {
            Log.e(TAG, "usage query failed", e)
        }
        return lastFg
    }

    private fun goHome() {
        try {
            startActivity(
                Intent(Intent.ACTION_MAIN)
                    .addCategory(Intent.CATEGORY_HOME)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
        } catch (e: Throwable) {
            Log.e(TAG, "go home failed", e)
        }
    }

    /** Show the earn/done screen when a gated app is OPENED with no time left. */
    private fun lock(pkg: String, mode: String) {
        val now = System.currentTimeMillis()
        if (pkg == lockedPkg && now < lockCooldownUntil) return // don't relaunch repeatedly
        lockedPkg = pkg
        lockCooldownUntil = now + 3000

        val q = EnginePrefs.questions(this, pkg)
        val min = EnginePrefs.minutes(this, pkg)
        val intent = Intent(this, MainActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
            addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
            putExtra("lock_package", pkg)
            putExtra("lock_mode", mode)
            putExtra("lock_questions", q)
            putExtra("lock_minutes", min)
        }
        try {
            startActivity(intent)
            Log.d(TAG, "lock launched: $pkg ($mode)")
        } catch (e: Throwable) {
            Log.e(TAG, "lock launch failed", e)
            lockedPkg = null
        }
    }

    // ---- floating countdown chip ----
    private fun showChip() {
        if (chip != null) return
        if (!Settings.canDrawOverlays(this)) return
        try {
            val tv = TextView(this).apply {
                background = GradientDrawable().apply {
                    cornerRadius = 60f
                    setColor(0xE61F2333.toInt())
                }
                setTextColor(Color.WHITE)
                textSize = 13f
                setPadding(40, 18, 40, 18)
            }
            val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE
            val lp = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                type,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                PixelFormat.TRANSLUCENT
            ).apply {
                gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
                y = 28
            }
            wm?.addView(tv, lp)
            chip = tv
        } catch (e: Throwable) {
            Log.e(TAG, "showChip failed", e)
        }
    }

    private fun updateChip(text: String) {
        chip?.text = text
    }

    private fun hideChip() {
        val c = chip ?: return
        chip = null
        try {
            wm?.removeView(c)
        } catch (_: Throwable) {
        }
    }

    private fun fmt(ms: Long): String {
        val s = (ms / 1000).coerceAtLeast(0)
        return "%d:%02d".format(s / 60, s % 60)
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val ch = NotificationChannel(
                CHANNEL, "BrainPass active", NotificationManager.IMPORTANCE_MIN
            ).apply { description = "Keeps screen-time gating running." }
            (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
                .createNotificationChannel(ch)
        }
    }

    private fun buildNotification(): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL)
        } else {
            @Suppress("DEPRECATION") Notification.Builder(this)
        }
        return builder
            .setContentTitle("BrainPass is active")
            .setContentText("Protecting your child's screen time.")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setOngoing(true)
            .build()
    }
}
