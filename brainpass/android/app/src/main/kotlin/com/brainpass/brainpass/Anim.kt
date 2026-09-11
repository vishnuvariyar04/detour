package com.brainpass.brainpass

import android.animation.ValueAnimator
import android.view.View
import android.view.animation.DecelerateInterpolator

/**
 * The small amount of motion these drawings need.
 *
 * Motion here is not decoration. Counters that land one after another ARE the
 * count; a marker that hops four times along the line IS "add four". A child
 * who watches the thing happen has already half-answered the question, which is
 * the difference between a picture of an idea and the idea itself.
 *
 * Everything is short — under a second — because it plays before every question
 * and a wait that is charming the first time is an obstacle the fortieth.
 */
class Anim(private val view: View) {

    /** 0 while the animation is at its start, 1 when it has finished. */
    var t = 1f
        private set

    private var animator: ValueAnimator? = null

    val running get() = animator?.isRunning == true

    /** Restart from zero. [ms] is the whole run, however many items it covers. */
    fun play(ms: Long = 520L, onEnd: (() -> Unit)? = null) {
        animator?.cancel()
        t = 0f
        animator = ValueAnimator.ofFloat(0f, 1f).apply {
            duration = ms
            interpolator = DecelerateInterpolator(1.4f)
            addUpdateListener {
                t = it.animatedValue as Float
                view.invalidate()
            }
            addListener(object : android.animation.AnimatorListenerAdapter() {
                override fun onAnimationEnd(a: android.animation.Animator) {
                    t = 1f
                    view.invalidate()
                    onEnd?.invoke()
                }
            })
            start()
        }
    }

    /** Jump to the finished state, for a redraw that should not re-animate. */
    fun settle() {
        animator?.cancel()
        animator = null
        t = 1f
        view.invalidate()
    }

    fun cancel() {
        animator?.cancel()
        animator = null
    }

    /**
     * The progress of item [i] of [n], as a staggered slice of the whole run.
     *
     * Each item takes [overlap] of the total and they start evenly apart, so a
     * row of counters lands one after another rather than all at once.
     */
    fun stagger(i: Int, n: Int, overlap: Float = 0.45f): Float {
        if (n <= 1) return t
        val step = (1f - overlap) / (n - 1)
        val start = i * step
        return ((t - start) / overlap).coerceIn(0f, 1f)
    }
}

/** Overshoot easing: a shape that pops past its size and settles looks alive. */
fun overshoot(x: Float, amount: Float = 1.9f): Float {
    if (x <= 0f) return 0f
    if (x >= 1f) return 1f
    val u = x - 1f
    return 1f + u * u * ((amount + 1f) * u + amount)
}
