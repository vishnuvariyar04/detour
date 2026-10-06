package com.brainpass.brainpass

/**
 * Which GATED activities are currently on screen (RESUMED and not yet
 * PAUSED/STOPPED/DESTROYED).
 *
 * Why this exists: the guard used to treat "the newest app that moved to the
 * foreground" as the only app in front. With a floating window / sidebar app /
 * split screen, two apps are resumed at once. Opening a floating app over a
 * locked one makes the floating app the "newest", the locked app never gets a
 * new event (it was never paused), and the lock was dropped while the locked app
 * stayed fully usable underneath. Remembering every gated activity that is still
 * resumed closes that gap.
 *
 * Pure Kotlin (no Android types) so it can be unit-tested on the JVM.
 *
 * ## Staying correct
 * The dangerous failure is a MISSED "paused" event: the app would look on-screen
 * forever and the lock would sit on top of the home screen. So the caller must
 * replay every event since the previous query, not just the last minute:
 *  - [beginQuery] returns where the next query must start. Normally that is the
 *    previous query's end minus [overlapMs] (the overlap absorbs OEMs that
 *    flush usage events late).
 *  - Replaying an overlapping window is harmless: for each activity only its
 *    LAST event in the window matters, and activities the window doesn't touch
 *    keep their state.
 *  - If the previous query is missing or older than [maxGapMs] (service was
 *    dead, screen off for a long time) continuity can't be trusted, so the set
 *    is cleared and the window restarts at `now - overlapMs`; the visible apps'
 *    RESUMED events re-populate it.
 */
class GatedVisibility(
    private val overlapMs: Long = 60_000L,
    private val maxGapMs: Long = 30 * 60_000L,
) {
    /** "package/class" -> time it was resumed. */
    private val resumed = HashMap<String, Long>()
    private var lastQueryEnd = 0L

    /** Start of the next `queryEvents` window. Clears state if continuity is lost. */
    fun beginQuery(now: Long): Long {
        val continuous = lastQueryEnd != 0L && now - lastQueryEnd in 0..maxGapMs
        if (!continuous) resumed.clear()
        return if (continuous) lastQueryEnd - overlapMs else now - overlapMs
    }

    /** Call once the query window has been fully applied. */
    fun endQuery(now: Long) {
        lastQueryEnd = now
    }

    fun onResumed(pkg: String, cls: String?, at: Long) {
        resumed[key(pkg, cls)] = at
    }

    fun onGone(pkg: String, cls: String?) {
        resumed.remove(key(pkg, cls))
    }

    fun clear() {
        resumed.clear()
    }

    /**
     * The package of the most recently resumed activity that is still on screen
     * and accepted by [keep] (used to re-check that the app is still gated).
     */
    fun newest(keep: (String) -> Boolean): String? {
        var best: String? = null
        var bestAt = Long.MIN_VALUE
        for ((k, at) in resumed) {
            val pkg = k.substringBefore('/')
            if (at >= bestAt && keep(pkg)) {
                best = pkg
                bestAt = at
            }
        }
        return best
    }

    private fun key(pkg: String, cls: String?) = "$pkg/${cls.orEmpty()}"
}
