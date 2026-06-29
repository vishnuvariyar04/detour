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
import android.graphics.BitmapFactory
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
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.TextView

/**
 * The whole gating engine in one foreground service. Detection via
 * UsageStatsManager polling (1s, screen-on only); time booked to disk each tick.
 *
 * IMPORTANT cross-OEM design: the LOCK is a full-screen **overlay** (a window),
 * NOT a background-launched Activity. Many OEMs (notably Xiaomi/MIUI via the
 * hidden "display pop-up windows while running in background" permission) block
 * background Activity starts, so the old approach showed nothing until the app
 * was foregrounded. An overlay only needs "Draw over other apps" (already
 * granted, since the countdown chip works), so it appears instantly everywhere.
 * The overlay also tries to launch the Flutter earn Activity (for the questions
 * UI); if that's blocked, tapping the overlay launches it (a user gesture is
 * always allowed).
 */
class GuardService : Service() {

    companion object {
        private const val TAG = "NupoGuard"
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

        fun hasUsageAccess(ctx: Context): Boolean {
            return try {
                val usm = ctx.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
                val now = System.currentTimeMillis()
                usm.queryEvents(now - 60_000, now).hasNextEvent() ||
                    usm.queryUsageStats(
                        UsageStatsManager.INTERVAL_DAILY, now - 86_400_000, now
                    ).isNotEmpty()
            } catch (e: Throwable) {
                false
            }
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var wm: WindowManager? = null
    private var chip: TextView? = null
    private var lockView: View? = null
    private var lockPkg: String? = null

    private var trackedPkg: String? = null
    private var lastFg: String? = null
    private var lastTickAt: Long = 0L
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
        WatchdogReceiver.schedule(this) // self-healing wake-ups
        Log.d(TAG, "guard service started")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startTicking()
        return START_STICKY
    }

    /** Swiped from recents — schedule a quick restart so gating resumes. */
    override fun onTaskRemoved(rootIntent: Intent?) {
        WatchdogReceiver.schedule(this, 1500)
        super.onTaskRemoved(rootIntent)
    }

    override fun onDestroy() {
        stopTicking()
        hideLock()
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
            idle(); hideLock(); return
        }
        val pkg = currentForegroundApp() ?: return

        // Our own parent app is open — not gated; remove any lock.
        if (pkg == packageName) { idle(); hideLock(); return }

        // Child left the gated app (home / another app) — free them.
        if (!EnginePrefs.isGated(this, pkg)) { idle(); hideLock(); return }

        // Gated app with no time -> show the native lock overlay.
        if (EnginePrefs.capReached(this, pkg)) { idle(); showLock(pkg, "done"); return }
        if (EnginePrefs.remMs(this, pkg) <= 0L) { idle(); showLock(pkg, "earn"); return }

        // Gated app with time -> remove any lock and count down.
        hideLock()
        if (pkg != trackedPkg) {
            trackedPkg = pkg
            showChip()
        } else {
            EnginePrefs.consume(this, pkg, delta)
            if (EnginePrefs.remMs(this, pkg) <= 0L) {
                hideChip()
                trackedPkg = null
                Log.d(TAG, "$pkg time up -> home (lock on next open)")
                goHome() // just close to home; questions appear on next open
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

    private fun currentForegroundApp(): String? {
        try {
            val usm = getSystemService(USAGE_STATS_SERVICE) as UsageStatsManager
            val end = System.currentTimeMillis()
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

    /**
     * Show the kid lock as a native full-screen overlay (questions rendered by
     * [LockUi]). An overlay only needs "Draw over other apps" — works on every
     * phone, no per-OEM background-launch permission, no Activity.
     */
    private fun showLock(pkg: String, mode: String) {
        if (lockView != null && lockPkg == pkg) return // already showing for this app
        hideLock()
        if (!Settings.canDrawOverlays(this)) return
        lockPkg = pkg

        val band = bandFromString(EnginePrefs.ageBand(this))
        val target = EnginePrefs.questions(this, pkg)
        val minutes = EnginePrefs.minutes(this, pkg)
        val ui = LockUi(
            this, mode, band, target, minutes,
            onEarned = { EnginePrefs.addEarned(this, pkg); hideLock() },
            onOverride = { EnginePrefs.addOverride(this, pkg); hideLock() },
        )

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        else
            @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE
        // FLAG_NOT_FOCUSABLE => touchable (our buttons work) but doesn't grab
        // keys; covers + blocks the app behind. No Activity needed.
        val lp = WindowManager.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.OPAQUE
        )
        // Force the lock to portrait so the keypad always fits (a kid might be
        // in a landscape game when it pops).
        lp.screenOrientation = android.content.pm.ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        try {
            wm?.addView(ui.root, lp)
            lockView = ui.root
            Log.d(TAG, "native lock shown: $pkg ($mode)")
        } catch (e: Throwable) {
            Log.e(TAG, "showLock failed", e)
            lockPkg = null
        }
    }

    private fun hideLock() {
        val v = lockView ?: return
        lockView = null
        lockPkg = null
        try {
            wm?.removeView(v)
        } catch (_: Throwable) {
        }
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

    // ---- countdown chip ----
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
                CHANNEL, "Nupo active", NotificationManager.IMPORTANCE_MIN
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
        builder
            .setContentTitle("Nupo is active")
            .setContentText("Protecting your child's screen time.")
            .setSmallIcon(R.drawable.ic_stat_nupo)
            .setOngoing(true)
        appIconBitmap()?.let { builder.setLargeIcon(it) }
        return builder.build()
    }

    /** The colour Nupo owl (bundled Flutter asset) for the notification's large icon. */
    private fun appIconBitmap(): android.graphics.Bitmap? = try {
        assets.open("flutter_assets/assets/icon/nupo.png").use { BitmapFactory.decodeStream(it) }
    } catch (e: Throwable) {
        null
    }
}
