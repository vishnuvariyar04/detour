package com.brainpass.brainpass

import android.content.Context
import android.os.Bundle
import android.util.Log
import com.google.firebase.analytics.FirebaseAnalytics
import java.util.Calendar

/**
 * Kid-side analytics, logged from the GUARD SERVICE.
 *
 * ## Why this is not in Dart
 *
 * The learning moment is 100% native (GuardService + LockUi) — Flutter is only
 * the parent's settings app, and a happy parent opens it once and never again.
 * So retention measured from Flutter would be retention of a settings screen:
 * it would read near-zero even for a family using Nupo perfectly every day.
 *
 * The events here are the real product usage, and [dailyActive] in particular
 * is the honest D1/D7/D30 signal — a device that showed a lesson today.
 *
 * ## Child-directed rules (Play Families)
 *
 * Nothing personal is logged: no answers the child gave, no question text, no
 * names, no device identifiers beyond the app instance id Firebase already
 * uses. The advertising id is stripped in AndroidManifest.xml. Package names
 * of GATED apps are the parent's own configuration, already declared in
 * `legal/DATA_SAFETY.md`.
 *
 * ## Fail-safe
 *
 * Every call is wrapped: analytics must never take the guard down. Firebase
 * self-initialises through its ContentProvider on process start, and the guard
 * runs in the main process, so no explicit init is needed here.
 */
object Analytics {
    private const val TAG = "NupoAnalytics"
    private const val PREFS = "nupo_analytics"
    private const val KEY_ACTIVE_DAY = "lastActiveDay"

    private var fa: FirebaseAnalytics? = null

    private fun analytics(ctx: Context): FirebaseAnalytics? {
        fa?.let { return it }
        return try {
            FirebaseAnalytics.getInstance(ctx.applicationContext).also { fa = it }
        } catch (t: Throwable) {
            Log.w(TAG, "analytics unavailable", t)
            null
        }
    }

    private fun log(ctx: Context, name: String, build: Bundle.() -> Unit = {}) {
        try {
            analytics(ctx)?.logEvent(name, Bundle().apply(build))
        } catch (t: Throwable) {
            Log.w(TAG, "logEvent $name failed", t)
        }
    }

    /**
     * A gated app was opened and the lock went up. [mode] is "earn" (a lesson)
     * or "done" (the daily cap is spent). [target] is how many questions this
     * app is configured to ask.
     */
    fun lessonShown(ctx: Context, pkg: String, mode: String, target: Int) {
        dailyActive(ctx)
        log(ctx, "lesson_shown") {
            putString("app", pkg)
            putString("mode", mode)
            putInt("target", target)
        }
    }

    /**
     * The child answered enough questions and the app unlocked. The ratio of
     * this to [lessonShown] is the one number that says whether the questions
     * are the right difficulty — a low ratio means kids give up.
     */
    fun lessonEarned(ctx: Context, pkg: String, minutes: Int) {
        log(ctx, "lesson_earned") {
            putString("app", pkg)
            putInt("minutes", minutes)
        }
    }

    /**
     * A parent typed the PIN to skip the lesson. A high rate here means the
     * gate is annoying the parent, which is churn one step early.
     */
    fun parentOverride(ctx: Context, pkg: String) {
        log(ctx, "parent_override") { putString("app", pkg) }
    }

    /** The guard started (boot, app update, watchdog, or setup finishing). */
    fun guardStarted(ctx: Context) = log(ctx, "guard_started")

    /**
     * The lock could not be drawn because the overlay permission is gone —
     * the app is installed and configured but silently doing NOTHING. This
     * is the most important failure event in the app.
     */
    fun overlayMissing(ctx: Context) = log(ctx, "overlay_missing")

    /**
     * Fires at most once per calendar day, the first time a lesson is shown.
     * Use it as the retention/active-user metric: cohorts of `first_open`
     * against `kid_active_day` give true D1 / D7 / D30 for the FAMILY, not
     * for the parent's settings screen.
     */
    private fun dailyActive(ctx: Context) {
        try {
            val prefs = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val today = todayStamp()
            if (prefs.getInt(KEY_ACTIVE_DAY, 0) == today) return
            prefs.edit().putInt(KEY_ACTIVE_DAY, today).apply()
            log(ctx, "kid_active_day")
        } catch (t: Throwable) {
            Log.w(TAG, "dailyActive failed", t)
        }
    }

    /** Local calendar day as yyyyMMdd — same convention as EnginePrefs. */
    private fun todayStamp(): Int {
        val c = Calendar.getInstance()
        return c.get(Calendar.YEAR) * 10000 +
            (c.get(Calendar.MONTH) + 1) * 100 +
            c.get(Calendar.DAY_OF_MONTH)
    }
}
