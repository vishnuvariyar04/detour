package com.brainpass.brainpass

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * Replays usage-event sequences the way GuardService does: each "tick" queries
 * the window [GatedVisibility.beginQuery] asks for and applies the events in it.
 * The event orders below are copied from a real phone (HyperOS, 2026-09-19).
 */
class GatedVisibilityTest {

    private enum class T { RESUMED, PAUSED, STOPPED }
    private data class Ev(val at: Long, val type: T, val pkg: String, val cls: String = "Main")

    private val calc = "com.miui.calculator"
    private val chat = "com.openai.chatgpt"
    private val home = "com.miui.home"
    private val gated = setOf(calc)
    private val s = 1000L

    /** One service tick at [now]: query the requested window and apply it. */
    private fun tick(v: GatedVisibility, all: List<Ev>, now: Long, gatedSet: Set<String> = gated) {
        val begin = v.beginQuery(now)
        for (e in all.filter { it.at in begin until now }.sortedBy { it.at }) {
            when (e.type) {
                T.RESUMED -> if (e.pkg in gatedSet) v.onResumed(e.pkg, e.cls, e.at)
                else -> v.onGone(e.pkg, e.cls)
            }
        }
        v.endQuery(now)
    }

    private fun front(v: GatedVisibility, gatedSet: Set<String> = gated) = v.newest { it in gatedSet }

    /** The bug: a floating ChatGPT opens over a locked Calculator that is never paused. */
    @Test
    fun floatingWindowOverGatedAppKeepsItVisible() {
        val ev = listOf(
            Ev(0, T.PAUSED, home), Ev(0, T.RESUMED, calc),          // calculator opened
            Ev(6 * s, T.RESUMED, chat),                            // sidebar float opens
            Ev(11 * s, T.PAUSED, chat), Ev(11 * s, T.STOPPED, chat), // float closed
        )
        val v = GatedVisibility()
        for (sec in 1L..20L) {
            tick(v, ev, sec * s)
            assertEquals("calculator must stay in front at ${sec}s", calc, front(v))
        }
    }

    @Test
    fun leavingForHomeReleasesTheApp() {
        val ev = listOf(
            Ev(0, T.RESUMED, calc),
            Ev(5 * s, T.PAUSED, calc), Ev(5 * s, T.RESUMED, home), Ev(6 * s, T.STOPPED, calc),
        )
        val v = GatedVisibility()
        tick(v, ev, 3 * s); assertEquals(calc, front(v))
        tick(v, ev, 8 * s); assertNull(front(v))
    }

    @Test
    fun switchingToAnotherFullscreenAppReleasesTheApp() {
        val ev = listOf(
            Ev(0, T.RESUMED, calc),
            Ev(5 * s, T.PAUSED, calc), Ev(5 * s, T.RESUMED, chat), Ev(6 * s, T.STOPPED, calc),
        )
        val v = GatedVisibility()
        tick(v, ev, 3 * s); assertEquals(calc, front(v))
        tick(v, ev, 8 * s); assertNull(front(v))
    }

    @Test
    fun stoppedAloneAlsoReleases() {
        val ev = listOf(Ev(0, T.RESUMED, calc), Ev(5 * s, T.STOPPED, calc))
        val v = GatedVisibility()
        tick(v, ev, 3 * s); assertEquals(calc, front(v))
        tick(v, ev, 8 * s); assertNull(front(v))
    }

    @Test
    fun sameActivityResumedAgainAfterPauseIsVisible() {
        val ev = listOf(
            Ev(0, T.RESUMED, calc), Ev(4 * s, T.PAUSED, calc), Ev(6 * s, T.RESUMED, calc),
        )
        val v = GatedVisibility()
        tick(v, ev, 5 * s); assertNull(front(v))
        tick(v, ev, 8 * s); assertEquals(calc, front(v))
    }

    @Test
    fun newestOfSeveralGatedAppsWins() {
        val two = setOf(calc, "com.instagram.android")
        val ev = listOf(Ev(0, T.RESUMED, calc), Ev(3 * s, T.RESUMED, "com.instagram.android"))
        val v = GatedVisibility()
        tick(v, ev, 5 * s, two)
        assertEquals("com.instagram.android", front(v, two))
    }

    @Test
    fun ungatedAppsAreNeverTracked() {
        val ev = listOf(Ev(0, T.RESUMED, chat))
        val v = GatedVisibility()
        tick(v, ev, 5 * s)
        assertNull(front(v))
    }

    @Test
    fun appNoLongerGatedIsIgnoredEvenIfStillTracked() {
        val ev = listOf(Ev(0, T.RESUMED, calc))
        val v = GatedVisibility()
        tick(v, ev, 5 * s)
        assertNull("parent un-gated the app", front(v, emptySet()))
    }

    /**
     * The dangerous case: the service stops ticking while the screen is off, so a
     * PAUSED that happens in that gap must still be applied afterwards — otherwise
     * the lock would sit on top of the home screen.
     */
    @Test
    fun pauseDuringScreenOffGapIsNotMissed() {
        val ev = listOf(
            Ev(0, T.RESUMED, calc),
            Ev(10 * s, T.PAUSED, calc), Ev(11 * s, T.STOPPED, calc), // screen off, no ticks
            Ev(600 * s, T.RESUMED, home),                             // woke on the home screen
        )
        val v = GatedVisibility()
        tick(v, ev, 5 * s); assertEquals(calc, front(v))
        tick(v, ev, 601 * s) // first tick after a 10 minute gap
        assertNull("stale entry would lock the home screen", front(v))
    }

    @Test
    fun gapLongerThanMaximumResetsStateInsteadOfTrustingIt() {
        val ev = listOf(
            Ev(0, T.RESUMED, calc),
            Ev(60 * s, T.PAUSED, calc), // happens while nobody is watching
        )
        val v = GatedVisibility()
        tick(v, ev, 5 * s); assertEquals(calc, front(v))
        val wake = 3 * 3600 * s // 3 hours later, e.g. overnight
        val begin = v.beginQuery(wake)
        assertEquals("window restarts at now - overlap", wake - 60 * s, begin)
        assertNull("state cleared: can't trust it", front(v))
    }

    @Test
    fun visibleAppIsRepopulatedByItsResumedEventAfterAReset() {
        val wake = 3 * 3600 * s
        val ev = listOf(Ev(wake - 2 * s, T.RESUMED, calc))
        val v = GatedVisibility()
        tick(v, ev, wake)
        assertEquals(calc, front(v))
    }

    @Test
    fun continuousTicksUseThePreviousEndMinusOverlap() {
        val v = GatedVisibility(overlapMs = 60_000, maxGapMs = 30 * 60_000)
        v.beginQuery(1_000_000); v.endQuery(1_000_000)
        assertEquals(1_000_000 - 60_000, v.beginQuery(1_001_000))
    }

    /** OEMs can flush usage events late; the overlap must still catch a late PAUSED. */
    @Test
    fun lateStampedPauseWithinOverlapIsCaught() {
        val v = GatedVisibility()
        val calcResumed = Ev(0, T.RESUMED, calc)
        tick(v, listOf(calcResumed), 30 * s); assertEquals(calc, front(v))
        // The PAUSED is stamped 25s but only becomes visible to queries at 31s.
        val ev = listOf(calcResumed, Ev(25 * s, T.PAUSED, calc))
        tick(v, ev, 31 * s)
        assertNull(front(v))
    }

    /** Replaying the same overlapping window again must not change the result. */
    @Test
    fun replayingOverlappingWindowsIsIdempotent() {
        val ev = listOf(
            Ev(0, T.RESUMED, calc), Ev(6 * s, T.RESUMED, chat),
            Ev(11 * s, T.PAUSED, chat), Ev(11 * s, T.STOPPED, chat),
        )
        val v = GatedVisibility()
        repeat(50) { i -> tick(v, ev, (12 + i) * s); assertEquals(calc, front(v)) }
    }
}
