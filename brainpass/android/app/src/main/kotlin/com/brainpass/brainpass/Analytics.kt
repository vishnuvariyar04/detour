package com.brainpass.brainpass

import android.content.Context
import android.os.Bundle
import android.util.Log
import android.content.pm.PackageManager
import com.google.firebase.analytics.FirebaseAnalytics
import com.posthog.PostHog
import com.posthog.PersonProfiles
import com.posthog.android.PostHogAndroid
import com.posthog.android.PostHogAndroidConfig
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
 *
 * ## PostHog (Cloud EU), alongside Firebase
 *
 * Every event goes to both. PostHog is started by [startPostHog], called from
 * PostHogInit at process start, and the Flutter side (lib/analytics.dart)
 * reports through the same SDK instance. Child-directed settings: no session
 * replay, no autocapture, no screen-view or deep-link capture, no feature-flag
 * calls. Lifecycle events (Application Opened / Installed / Updated) stay on;
 * they carry nothing personal. With no token in the build, PostHog is
 * simply never started and every PostHog call below is a no-op.
 */
object Analytics {
    private const val TAG = "NupoAnalytics"
    private const val PREFS = "nupo_analytics"
    private const val KEY_ACTIVE_DAY = "lastActiveDay"

    private var fa: FirebaseAnalytics? = null

    @Volatile private var posthogOn = false

    /** Start PostHog once for this process. Safe to call more than once. */
    @Synchronized
    fun startPostHog(ctx: Context) {
        if (posthogOn) return
        try {
            val app = ctx.applicationContext
            val meta = app.packageManager
                .getApplicationInfo(app.packageName, PackageManager.GET_META_DATA).metaData
            val host = meta?.getString("app.nupo.posthog.HOST").orEmpty().trim().trimEnd('/')
            val token = meta?.getString("app.nupo.posthog.TOKEN").orEmpty().trim()
            if (host.isEmpty() || token.isEmpty()) {
                Log.i(TAG, "PostHog not configured; Firebase only")
                return
            }
            val config = PostHogAndroidConfig(token, host).apply {
                captureApplicationLifecycleEvents = true
                captureScreenViews = false     // Flutter reports its own screens
                captureDeepLinks = false
                sessionReplay = false          // never record a child's screen
                preloadFeatureFlags = false
                sendFeatureFlagEvent = false
                personProfiles = PersonProfiles.ALWAYS
                debug = (app.applicationInfo.flags and
                    android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0
            }
            PostHogAndroid.setup(app, config)
            posthogOn = true
        } catch (t: Throwable) {
            Log.w(TAG, "PostHog unavailable", t)
        }
    }

    private fun analytics(ctx: Context): FirebaseAnalytics? {
        fa?.let { return it }
        return try {
            FirebaseAnalytics.getInstance(ctx.applicationContext).also { fa = it }
        } catch (t: Throwable) {
            Log.w(TAG, "analytics unavailable", t)
            null
        }
    }

    /** One event to both Firebase and PostHog. Values are String, Int or Boolean. */
    private fun log(ctx: Context, name: String, vararg params: Pair<String, Any>) {
        try {
            analytics(ctx)?.logEvent(name, Bundle().apply {
                for ((k, v) in params) when (v) {
                    is Int -> putInt(k, v)
                    is Long -> putLong(k, v)
                    is Boolean -> putInt(k, if (v) 1 else 0)  // GA4 has no booleans
                    else -> putString(k, v.toString().take(100))
                }
            })
        } catch (t: Throwable) {
            Log.w(TAG, "logEvent $name failed", t)
        }
        if (!posthogOn) startPostHog(ctx)
        if (!posthogOn) return
        try {
            PostHog.capture(name, properties = mapOf("surface" to "kid_gate") + params.toMap())
        } catch (t: Throwable) {
            Log.w(TAG, "PostHog capture $name failed", t)
        }
    }

    /**
     * A gated app was opened and the lock went up. [mode] is "earn" (a lesson)
     * or "done" (the daily cap is spent). [target] is how many questions this
     * app is configured to ask.
     */
    fun lessonShown(ctx: Context, pkg: String, mode: String, target: Int) {
        dailyActive(ctx)
        log(ctx, "lesson_shown", "app" to pkg, "mode" to mode, "target" to target)
    }

    /**
     * The child answered enough questions and the app unlocked. The ratio of
     * this to [lessonShown] is the one number that says whether the questions
     * are the right difficulty — a low ratio means kids give up.
     */
    fun lessonEarned(ctx: Context, pkg: String, minutes: Int) {
        log(ctx, "lesson_earned", "app" to pkg, "minutes" to minutes)
    }

    /**
     * A parent typed the PIN to skip the lesson. A high rate here means the
     * gate is annoying the parent, which is churn one step early.
     */
    fun parentOverride(ctx: Context, pkg: String) {
        log(ctx, "parent_override", "app" to pkg)
    }

    /** The guard started (boot, app update, watchdog, or setup finishing). */
    fun guardStarted(ctx: Context) = log(ctx, "guard_started")

    /**
     * The lock could not be drawn because the overlay permission is gone —
     * the app is installed and configured but silently doing NOTHING. This
     * is the most important failure event in the app.
     */
    fun overlayMissing(ctx: Context) = log(ctx, "overlay_missing")

    // ------------------------------------------------------------------
    // Learning, from inside the gate (CoderGate). Ids only: the skill id, the
    // stop id ("2.1.3") and the question's shape. Never the question text,
    // never what the child tapped.

    /** A stop's "New idea" card was shown: the child met a new idea. */
    fun teachShown(ctx: Context, skill: String, stop: String) =
        log(ctx, "teach_shown", "skill" to skill, "stop" to stop)

    /** The child asked for the hint. */
    fun hintOpened(ctx: Context, skill: String, stop: String, shape: String) =
        log(ctx, "hint_opened", "skill" to skill, "stop" to stop, "shape" to shape)

    /**
     * One question answered. Right/wrong per stop and per shape is how a
     * question that is too hard, or a teach card that does not teach, shows up.
     * [seconds] is time from the question appearing to the answer.
     */
    fun questionAnswered(
        ctx: Context, skill: String, stop: String, shape: String, boss: Boolean,
        correct: Boolean, hintUsed: Boolean, review: Boolean, seconds: Int,
    ) = log(ctx, "question_answered",
        "skill" to skill, "stop" to stop, "shape" to shape, "boss" to boss,
        "correct" to correct, "hint_used" to hintUsed, "review" to review,
        "seconds" to seconds)

    /** A lesson session reached its end screen. */
    fun sessionFinished(ctx: Context, skill: String, asked: Int, correct: Int) =
        log(ctx, "lesson_session_done", "skill" to skill, "asked" to asked, "correct" to correct)

    /** The child moved onto a new stop of the ladder. */
    fun stopReached(ctx: Context, skill: String, stop: String, position: Int) =
        log(ctx, "stop_reached", "skill" to skill, "stop" to stop, "position" to position)

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
