package com.brainpass.brainpass

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.view.MotionEvent
import android.view.View

/**
 * The visual vocabulary for Number Sense, the skill for ages 5-8.
 *
 * Think Like a Coder could say everything with one picture: a grid and a list
 * of steps. Early number cannot. "How many" wants countable things, "ten and
 * three" wants a ten frame, "where does 7 sit" wants a line, and "6 is 4 and 2"
 * wants a bond. Each is a different claim about what a number is, so each gets
 * its own drawing rather than a numeral in a box.
 *
 * A five year old may not read, so nothing here leans on words: the picture
 * carries the question and the answer is a tap.
 */

/** Shared verdict handling, so every number view marks right and wrong alike. */
abstract class NumberView(ctx: Context) : View(ctx) {
    protected var verdict: Int? = null

    fun showVerdict(correct: Boolean) {
        verdict = if (correct) Ink.good else Ink.bad
        invalidate()
    }

    fun clearVerdict() { verdict = null; invalidate() }

    protected fun ink(selected: Boolean) = when {
        verdict != null && selected -> verdict!!
        selected -> Ink.primary
        else -> Ink.line
    }

    protected fun wash(selected: Boolean) = when {
        verdict == Ink.good && selected -> Ink.goodWash
        verdict == Ink.bad && selected -> Ink.badWash
        selected -> 0xFFF1EBFF.toInt()
        else -> Ink.surface
    }
}

/**
 * Things to count, laid out in rows of five.
 *
 * Five is the largest group a child can see without counting, so two rows read
 * as "five and three" at a glance. That is the idea being taught, and it comes
 * from the layout rather than from a sentence about it.
 */
class CountGroupView(ctx: Context) : NumberView(ctx) {

    var count: Int = 0
        set(v) { field = v; requestLayout(); invalidate() }

    /** Counters from this index on take the second colour: "4 red and 2 yellow". */
    var splitAt: Int = -1
        set(v) { field = v; invalidate() }

    /** What the counters look like. Stars and hearts beat grey dots at five. */
    var glyph: String = Glyphs.STAR
        set(v) { field = v; invalidate() }

    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val anim = Anim(this)

    /** Counters land one after another: the landing IS the count. */
    fun play() = anim.play(60L * count.coerceIn(4, 12))
    fun settle() = anim.settle()

    private val perRow get() = 5
    private val rows get() = if (count <= 0) 0 else (count + perRow - 1) / perRow

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        val w = MeasureSpec.getSize(widthSpec)
        val cell = cellFor(w)
        setMeasuredDimension(w, (rows * cell).toInt().coerceAtLeast(dp(48)))
    }

    private fun cellFor(w: Int): Float = minOf(w / perRow.toFloat(), context.dpf(62f))

    override fun onDraw(canvas: Canvas) {
        if (count <= 0) return
        val cell = cellFor(width)
        val r = cell * 0.33f
        val totalW = minOf(count, perRow) * cell
        val ox = (width - totalW) / 2f
        for (i in 0 until count) {
            val cx = ox + (i % perRow) * cell + cell / 2f
            val cy = (i / perRow) * cell + cell / 2f
            val prog = anim.stagger(i, count)
            if (prog <= 0f) continue
            val second = splitAt in 0..i
            Glyphs.draw(canvas, glyph, cx, cy,
                r * overshoot(prog).coerceAtMost(1.12f),
                if (second) Ink.accent else Ink.primary,
                if (second) Ink.accentLedge else Ink.primaryLedge, p)
        }
    }
}

/**
 * A ten frame: two rows of five, filled from the top left.
 *
 * The empty cells are the point. A child who can see three gaps can say "seven
 * and three more make ten" without being told, which is the bridge from
 * counting to place value.
 */
class TenFrameView(ctx: Context) : NumberView(ctx) {

    var filled: Int = 0
        set(v) { field = v; invalidate() }

    /** A second frame, for teen numbers: a full ten and then these. */
    var secondFilled: Int = -1
        set(v) { field = v; requestLayout(); invalidate() }

    /** Matches CountGroupView, so a ten frame and a pile look like one family. */
    var glyph: String = Glyphs.CIRCLE
        set(v) { field = v; invalidate() }

    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val box = RectF()
    private val anim = Anim(this)

    /** Fills one cell at a time, so the gaps left over are felt, not read. */
    fun play() = anim.play(60L * (filled + maxOf(secondFilled, 0)).coerceIn(5, 14))
    fun settle() = anim.settle()

    private val frames get() = if (secondFilled >= 0) 2 else 1

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        val w = MeasureSpec.getSize(widthSpec)
        val cell = cellFor(w)
        val h = frames * (cell * 2) + (frames - 1) * context.dpf(14f)
        setMeasuredDimension(w, h.toInt())
    }

    private fun cellFor(w: Int) = minOf((w - context.dpf(8f)) / 5f, context.dpf(56f))

    override fun onDraw(canvas: Canvas) {
        val cell = cellFor(width)
        val gap = context.dpf(14f)
        val frameW = cell * 5
        val ox = (width - frameW) / 2f
        for (f in 0 until frames) {
            val oy = f * (cell * 2 + gap)
            val n = if (f == 0) minOf(filled, 10) else secondFilled
            val before = if (f == 0) 0 else minOf(filled, 10)
            drawFrame(canvas, ox, oy, cell, n, if (f == 1) Ink.accent else Ink.primary,
                if (f == 1) Ink.accentLedge else Ink.primaryLedge, before)
        }
    }

    private fun drawFrame(
        c: Canvas, ox: Float, oy: Float, cell: Float, n: Int, dot: Int, ledge: Int,
        before: Int,
    ) {
        val total = (filled + maxOf(secondFilled, 0)).coerceAtLeast(1)
        val inset = context.dpf(3f)
        val rad = context.dpf(9f)
        for (i in 0 until 10) {
            val x = ox + (i % 5) * cell
            val y = oy + (i / 5) * cell
            box.set(x + inset, y + inset, x + cell - inset, y + cell - inset)
            p.style = Paint.Style.FILL
            p.color = Ink.surface
            c.drawRoundRect(box, rad, rad, p)
            p.style = Paint.Style.STROKE
            p.strokeWidth = context.dpf(2f)
            p.color = Ink.line
            c.drawRoundRect(box, rad, rad, p)
            if (i < n) {
                val prog = anim.stagger(before + i, total)
                if (prog > 0f) {
                    p.style = Paint.Style.FILL
                    Glyphs.draw(c, glyph, box.centerX(), box.centerY(),
                        cell * 0.27f * overshoot(prog).coerceAtMost(1.1f), dot, ledge, p)
                }
            }
        }
        p.style = Paint.Style.FILL
    }
}

/**
 * A number line with a tappable position.
 *
 * Counting says how many; the line says where. That 7 is past 5, and one step
 * from 8, is a different fact from "there are seven of them", and it is the one
 * that makes later arithmetic feel like movement rather than recitation.
 */
class NumberLineView(ctx: Context, private val fonts: Fonts) : NumberView(ctx) {

    var from = 0
        set(v) { field = v; invalidate() }
    var to = 10
        set(v) { field = v; invalidate() }

    /** Label every nth tick; the ends are always labelled. */
    var labelEvery = 1
        set(v) { field = v; invalidate() }

    /** Shown as a fixed marker rather than an answer. */
    var marker: Int? = null
        set(v) { field = v; invalidate() }

    var selectable = false
    var picked: Int? = null
        private set

    var onPick: ((Int) -> Unit)? = null

    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val anim = Anim(this)

    /** Where a hop starts from; the marker walks from here to [marker]. */
    var hopFrom: Int? = null
        set(v) { field = v; invalidate() }

    /**
     * Hops one whole number at a time from [hopFrom] to [marker].
     *
     * Counting on is a movement before it is a sum, and four hops look like
     * "add four" in a way that a jump straight to the answer never does.
     */
    fun play() {
        val steps = marker?.let { m -> hopFrom?.let { Math.abs(m - it) } } ?: 0
        anim.play(if (steps > 0) (170L * steps).coerceAtMost(1100L) else 420L)
    }

    fun settle() = anim.settle()

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        setMeasuredDimension(MeasureSpec.getSize(widthSpec), dp(104))
    }

    private val pad get() = context.dpf(24f)

    private fun xFor(n: Int): Float {
        val span = width - pad * 2
        val steps = (to - from).coerceAtLeast(1)
        return pad + span * (n - from) / steps.toFloat()
    }

    override fun onDraw(canvas: Canvas) {
        val y = height * 0.42f
        p.style = Paint.Style.STROKE
        p.strokeWidth = context.dpf(3f)
        p.color = Ink.line
        canvas.drawLine(xFor(from), y, xFor(to), y, p)

        for (n in from..to) {
            val x = xFor(n)
            val labelled = n == from || n == to || (n - from) % labelEvery == 0
            p.style = Paint.Style.STROKE
            p.strokeWidth = context.dpf(2f)
            p.color = Ink.ledge
            val len = context.dpf(if (labelled) 9f else 5f)
            canvas.drawLine(x, y - len, x, y + len, p)
            if (labelled) {
                p.style = Paint.Style.FILL
                p.color = Ink.muted
                p.typeface = fonts.extra
                p.textSize = context.dpf(13f)
                p.textAlign = Paint.Align.CENTER
                canvas.drawText("$n", x, y + context.dpf(32f), p)
            }
        }

        p.style = Paint.Style.FILL
        marker?.let { m ->
            val start = hopFrom
            var mx = xFor(m)
            var lift = 0f
            if (start != null && start != m) {
                val steps = Math.abs(m - start)
                val walked = anim.t * steps
                val whole = Math.floor(walked.toDouble()).toFloat()
                val frac = walked - whole
                val dir = if (m > start) 1f else -1f
                val at = start + dir * whole
                val next = at + dir * (if (whole < steps) 1f else 0f)
                mx = xFor(0) + (at + (next - at) * frac - from) *
                    ((xFor(to) - xFor(from)) / (to - from).coerceAtLeast(1))
                // A hop arcs; a slide would read as one long move, not four steps.
                lift = -Math.sin(frac * Math.PI).toFloat() * context.dpf(22f)
                if (whole >= steps) lift = 0f
            }
            p.color = Ink.accentLedge
            canvas.drawCircle(mx, y + lift + context.dpf(1.5f), context.dpf(10f), p)
            p.color = Ink.accent
            canvas.drawCircle(mx, y + lift, context.dpf(10f), p)
        }
        picked?.let {
            p.color = ink(true)
            canvas.drawCircle(xFor(it), y, context.dpf(13f), p)
            p.color = wash(true)
            canvas.drawCircle(xFor(it), y, context.dpf(8f), p)
        }
    }

    override fun onTouchEvent(e: MotionEvent): Boolean {
        if (!selectable || verdict != null) return false
        if (e.action == MotionEvent.ACTION_DOWN) return true
        if (e.action != MotionEvent.ACTION_UP) return false
        val span = width - pad * 2
        val steps = (to - from).coerceAtLeast(1)
        val n = Math.round((e.x - pad) / span * steps) + from
        picked = n.coerceIn(from, to)
        onPick?.invoke(picked!!)
        invalidate()
        performClick()
        return true
    }

    override fun performClick(): Boolean { super.performClick(); return true }

    /** Screen point of tick [n], for the on-device test driver. */
    fun tickOnScreen(n: Int): IntArray {
        val loc = IntArray(2)
        getLocationOnScreen(loc)
        return intArrayOf((loc[0] + xFor(n)).toInt(), (loc[1] + height * 0.42f).toInt())
    }
}

/**
 * A number bond: one whole above, two parts below.
 *
 * Drawn as a whole splitting rather than as "4 + 2 = 6", because the idea is
 * that a number is made of other numbers. The notation comes later and means
 * less at five.
 */
class NumberBondView(ctx: Context, private val fonts: Fonts) : NumberView(ctx) {

    var whole: Int? = null
        set(v) { field = v; invalidate() }
    var left: Int? = null
        set(v) { field = v; invalidate() }
    var right: Int? = null
        set(v) { field = v; invalidate() }

    /** Which node is blank: "whole", "left" or "right". */
    var gap: String = "right"
        set(v) { field = v; invalidate() }

    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val anim = Anim(this)

    /** The parts rise into the whole, so the joining is something you watch. */
    fun play() = anim.play(560L)
    fun settle() = anim.settle()

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        setMeasuredDimension(MeasureSpec.getSize(widthSpec), dp(196))
    }

    override fun onDraw(canvas: Canvas) {
        val r = minOf(context.dpf(38f), width / 6.5f)
        val cx = width / 2f
        val topY = r + context.dpf(4f)
        val botY = height - r - context.dpf(4f)
        val dx = minOf(width / 4f, context.dpf(88f))

        p.style = Paint.Style.STROKE
        p.strokeWidth = context.dpf(3f)
        p.color = Ink.line
        canvas.drawLine(cx, topY + r * 0.9f, cx - dx, botY - r * 0.9f, p)
        canvas.drawLine(cx, topY + r * 0.9f, cx + dx, botY - r * 0.9f, p)

        node(canvas, cx, topY, r, whole, gap == "whole")
        node(canvas, cx - dx, botY, r, left, gap == "left")
        node(canvas, cx + dx, botY, r, right, gap == "right")
    }

    private fun node(c: Canvas, cx: Float, cy: Float, r: Float, v: Int?, isGap: Boolean) {
        p.style = Paint.Style.FILL
        p.color = if (isGap) wash(true) else Ink.surface
        c.drawCircle(cx, cy, r, p)
        p.style = Paint.Style.STROKE
        p.strokeWidth = context.dpf(if (isGap) 3f else 2f)
        p.color = if (isGap) ink(true) else Ink.line
        c.drawCircle(cx, cy, r, p)

        p.style = Paint.Style.FILL
        p.typeface = fonts.black
        p.textSize = r * 0.9f
        p.textAlign = Paint.Align.CENTER
        p.color = if (isGap) ink(true) else Ink.text
        c.drawText(v?.toString() ?: "?", cx, cy - (p.descent() + p.ascent()) / 2f, p)
    }
}
