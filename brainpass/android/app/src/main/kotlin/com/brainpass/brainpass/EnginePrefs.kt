package com.brainpass.brainpass

import android.content.Context
import android.content.SharedPreferences
import java.security.MessageDigest
import java.util.Calendar

/**
 * Native, on-device state for the gating engine. EVERYTHING is tracked PER APP —
 * each gated app has its own rule (questions / minutes / daily cap) and its own
 * runtime counters. Nothing is shared across apps.
 *
 * Time is "active time": minutes are only consumed while the app is in the
 * foreground (the accessibility service settles elapsed time on every app
 * switch). Counters reset at local midnight.
 *
 * Nothing here leaves the device (build spec §4).
 */
object EnginePrefs {
    private const val FILE = "brainpass_engine"
    private const val KEY_GATED = "gatedApps"
    private const val KEY_MASTER = "masterEnabled"
    private const val KEY_DAY = "dayStamp"
    private const val KEY_BAND = "ageBand"
    private const val KEY_PIN_HASH = "pinHash"
    private const val KEY_PIN_SALT = "pinSalt"

    // Per-app config
    private const val Q = "q_"        // Int: questions to earn
    private const val MIN = "min_"    // Int: minutes earned per solve
    private const val CAP = "cap_"    // Int: daily cap minutes (0 = none)
    private const val NAME = "name_"  // String: friendly display name
    // Per-app runtime (all reset at midnight)
    private const val REM = "rem_"    // Long: earned-but-unused active ms remaining
    private const val USED = "used_"  // Long: active ms used today
    private const val CAPX = "capx_"  // Int: extra cap minutes granted by parent today

    private fun p(c: Context): SharedPreferences =
        c.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    // ---- parent config (pushed from Flutter) ----
    fun setAgeBand(c: Context, b: String) = p(c).edit().putString(KEY_BAND, b).apply()
    fun ageBand(c: Context): String = p(c).getString(KEY_BAND, "b") ?: "b"

    fun setPin(c: Context, hash: String, salt: String) =
        p(c).edit().putString(KEY_PIN_HASH, hash).putString(KEY_PIN_SALT, salt).apply()

    /** Verify the parent PIN against the stored salted SHA-256 (matches pin.dart). */
    fun verifyPin(c: Context, pin: String): Boolean {
        val hash = p(c).getString(KEY_PIN_HASH, null) ?: return false
        val salt = p(c).getString(KEY_PIN_SALT, null) ?: return false
        val digest = MessageDigest.getInstance("SHA-256").digest("$salt:$pin".toByteArray())
        val hex = digest.joinToString("") { "%02x".format(it) }
        return hex == hash
    }

    // ---- master + gated set ----
    fun setMasterEnabled(c: Context, v: Boolean) = p(c).edit().putBoolean(KEY_MASTER, v).apply()
    fun masterEnabled(c: Context): Boolean = p(c).getBoolean(KEY_MASTER, true)
    fun gatedApps(c: Context): Set<String> = p(c).getStringSet(KEY_GATED, emptySet()) ?: emptySet()
    fun isGated(c: Context, pkg: String): Boolean = gatedApps(c).contains(pkg)

    /**
     * Replace all per-app rules. [rules] is a list of maps with keys:
     * package (String), questions (Int), minutes (Int), cap (Int).
     */
    fun setRules(c: Context, rules: List<Map<String, Any?>>) {
        val pref = p(c)
        val e = pref.edit()
        val pkgs = mutableSetOf<String>()
        for (r in rules) {
            val pkg = r["package"] as? String ?: continue
            pkgs.add(pkg)
            e.putInt(Q + pkg, (r["questions"] as? Number)?.toInt() ?: 3)
            e.putInt(MIN + pkg, (r["minutes"] as? Number)?.toInt() ?: 15)
            e.putInt(CAP + pkg, (r["cap"] as? Number)?.toInt() ?: 0)
            e.putString(NAME + pkg, (r["name"] as? String) ?: pkg)
        }
        // Prune every per-app key for apps that are no longer gated (clears stale
        // configs/counters and legacy "window_" keys from older versions).
        val prefixes = listOf(Q, MIN, CAP, NAME, REM, USED, CAPX, "window_")
        for (k in pref.all.keys) {
            for (pre in prefixes) {
                if (k.startsWith(pre)) {
                    if (!pkgs.contains(k.substring(pre.length))) e.remove(k)
                    break
                }
            }
        }
        e.putStringSet(KEY_GATED, pkgs)
        e.apply()
    }

    // ---- per-app config getters ----
    fun nameOf(c: Context, pkg: String): String = p(c).getString(NAME + pkg, pkg) ?: pkg
    fun questions(c: Context, pkg: String): Int = p(c).getInt(Q + pkg, 3)
    fun minutes(c: Context, pkg: String): Int = p(c).getInt(MIN + pkg, 15)
    fun minutesMs(c: Context, pkg: String): Long = minutes(c, pkg) * 60_000L
    private fun rawCapMinutes(c: Context, pkg: String): Int = p(c).getInt(CAP + pkg, 0)

    /** Effective daily cap in ms (configured cap + any parent overrides today). */
    fun capMs(c: Context, pkg: String): Long {
        val base = rawCapMinutes(c, pkg)
        if (base <= 0) return 0L // no cap
        val extra = p(c).getInt(CAPX + pkg, 0)
        return (base + extra) * 60_000L
    }

    // ---- per-app runtime ----
    fun remMs(c: Context, pkg: String): Long = p(c).getLong(REM + pkg, 0L)
    fun usedMs(c: Context, pkg: String): Long = p(c).getLong(USED + pkg, 0L)

    /** Add one earned block of active time. */
    fun addEarned(c: Context, pkg: String) {
        p(c).edit().putLong(REM + pkg, remMs(c, pkg) + minutesMs(c, pkg)).apply()
    }

    /** Parent override: grant a block AND lift the cap by one block for today. */
    fun addOverride(c: Context, pkg: String) {
        val extra = p(c).getInt(CAPX + pkg, 0) + minutes(c, pkg)
        p(c).edit()
            .putInt(CAPX + pkg, extra)
            .putLong(REM + pkg, remMs(c, pkg) + minutesMs(c, pkg))
            .apply()
    }

    /** Consume [elapsed] ms of active time: drains remaining, adds to used. */
    fun consume(c: Context, pkg: String, elapsed: Long) {
        if (elapsed <= 0) return
        val rem = (remMs(c, pkg) - elapsed).coerceAtLeast(0L)
        p(c).edit()
            .putLong(REM + pkg, rem)
            .putLong(USED + pkg, usedMs(c, pkg) + elapsed)
            .apply()
    }

    fun capReached(c: Context, pkg: String): Boolean {
        val cap = capMs(c, pkg)
        return cap > 0 && usedMs(c, pkg) >= cap
    }

    /** Active ms the child may still spend right now (bounded by cap). */
    fun effectiveBudget(c: Context, pkg: String): Long {
        var e = remMs(c, pkg)
        val cap = capMs(c, pkg)
        if (cap > 0) e = e.coerceAtMost(cap - usedMs(c, pkg))
        return e.coerceAtLeast(0L)
    }

    // ---- midnight rollover ----
    private fun today(): String {
        val cal = Calendar.getInstance()
        return "${cal.get(Calendar.YEAR)}-${cal.get(Calendar.MONTH)}-${cal.get(Calendar.DAY_OF_MONTH)}"
    }

    /**
     * Clear leftover earned budgets (rem_) so a freshly-changed rule applies
     * immediately. Keeps used_ so daily-cap progress is preserved.
     */
    fun clearBudgets(c: Context) {
        val pref = p(c)
        val e = pref.edit()
        for (k in pref.all.keys) {
            if (k.startsWith(REM)) e.remove(k)
        }
        e.apply()
    }

    /** Clear all per-app runtime counters when the day changes. */
    fun rollDayIfNeeded(c: Context) {
        val pref = p(c)
        if (pref.getString(KEY_DAY, "") == today()) return
        val e = pref.edit()
        for (k in pref.all.keys) {
            if (k.startsWith(REM) || k.startsWith(USED) || k.startsWith(CAPX)) e.remove(k)
        }
        e.putString(KEY_DAY, today()).apply()
    }
}
