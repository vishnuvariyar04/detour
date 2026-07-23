package com.brainpass.brainpass

import android.content.Context
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.View
import android.view.WindowManager

/**
 * "Bring me back" helper for the permission steps. The parent taps "Turn it
 * on", lands in system settings, flips the toggle — and instead of hunting the
 * back button, Nupo pops right back on its own.
 *
 * How: we poll the permission (the app process stays alive while settings is
 * in front). The moment it's granted we add an invisible 1-px overlay window —
 * a visible overlay window is one of Android's documented exemptions to the
 * background-activity-launch block (verified via ActivityTaskManager logs on
 * HyperOS: `callingUidHasNonAppVisibleWindow` flips the decision) — and then
 * relaunch our own task. The probe is removed right after.
 *
 * Works for "overlay" (grants SAW itself) and "usage" (runs after the overlay
 * step, so SAW is already held). Battery uses a dialog and needs no return.
 */
object PermissionReturn {
    private const val TAG = "NupoPermReturn"
    private val handler = Handler(Looper.getMainLooper())
    private var watching = false

    fun watch(ctx: Context, kind: String) {
        val ac = ctx.applicationContext
        if (watching) return
        watching = true
        val startedAt = System.currentTimeMillis()
        lateinit var poll: Runnable
        poll = Runnable {
            val granted = when (kind) {
                "overlay" -> Settings.canDrawOverlays(ac)
                "usage" -> GuardService.hasUsageAccess(ac)
                else -> true // unknown kind: stop watching
            }
            when {
                granted -> {
                    watching = false
                    bringToFront(ac)
                }
                System.currentTimeMillis() - startedAt > 120_000 -> watching = false
                else -> handler.postDelayed(poll, 500)
            }
        }
        handler.postDelayed(poll, 800)
    }

    private fun bringToFront(ctx: Context) {
        var probe: View? = null
        try {
            if (Settings.canDrawOverlays(ctx)) {
                val wm = ctx.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                else
                    @Suppress("DEPRECATION") WindowManager.LayoutParams.TYPE_PHONE
                probe = View(ctx)
                wm.addView(
                    probe,
                    WindowManager.LayoutParams(
                        1, 1, type,
                        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                            WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                        PixelFormat.TRANSLUCENT
                    )
                )
            }
        } catch (e: Throwable) {
            Log.e(TAG, "probe failed", e)
            probe = null
        }
        // Give the probe a beat to attach (the exemption needs a VISIBLE window).
        handler.postDelayed({
            try {
                val i = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)
                    ?.addFlags(
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                            Intent.FLAG_ACTIVITY_SINGLE_TOP
                    )
                if (i != null) ctx.startActivity(i)
            } catch (e: Throwable) {
                Log.e(TAG, "return launch failed", e)
            }
            val p = probe
            if (p != null) {
                handler.postDelayed({
                    try {
                        (ctx.getSystemService(Context.WINDOW_SERVICE) as WindowManager)
                            .removeView(p)
                    } catch (_: Throwable) {
                    }
                }, 1500)
            }
        }, if (probe != null) 300L else 0L)
    }
}
