package com.brainpass.brainpass

import android.content.Context
import android.graphics.Canvas
import android.graphics.DashPathEffect
import android.graphics.Paint

/**
 * The pictures multiplication, sharing and comparing are taught from.
 *
 * Counting says how many; these say how many groups, how much more, and how
 * the same whole can be cut different ways. They are the step where a child
 * stops counting one at a time because the picture offers a faster way.
 *
 * Every measurement here matches the reviewed design exactly — these were
 * agreed as drawings before a line of this file existed, so the phone shows
 * what was signed off rather than an approximation of it.
 */

/**
 * Rows and columns.
 *
 * The array is the picture multiplication is taught from because it answers
 * two questions at once: a child who counts every dot still gets 24, and a
 * child who counts one row and multiplies gets there sooner. Both are
 * progress, and the picture does not favour either.
 */
class ArrayGridView(ctx: Context) : NumberView(ctx) {

    var rows = 0
        set(v) { field = v; requestLayout(); invalidate() }
    var cols = 0
        set(v) { field = v; requestLayout(); invalidate() }
    var glyph: String = Glyphs.CIRCLE
        set(v) { field = v; invalidate() }

    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val anim = Anim(this)

    /** Lands row by row, so the rows are what a child sees first. */
    fun play() = anim.play(70L * (rows * cols).coerceIn(6, 16))
    fun settle() = anim.settle()

    private fun cellFor(w: Int) = minOf(
        w / (cols + 0.5f),
        context.dpf(46f),
        context.dpf(190f) / (rows + 0.5f),
    )

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        val w = MeasureSpec.getSize(widthSpec)
        setMeasuredDimension(w, (cellFor(w) * rows).toInt().coerceAtLeast(dp(40)))
    }

    override fun onDraw(canvas: Canvas) {
        if (rows <= 0 || cols <= 0) return
        val cell = cellFor(width)
        val ox = (width - cell * cols) / 2f
        val total = rows * cols
        for (i in 0 until rows) for (j in 0 until cols) {
            val prog = anim.stagger(i * cols + j, total)
            if (prog <= 0f) continue
            Glyphs.draw(canvas, glyph, ox + j * cell + cell / 2f,
                i * cell + cell / 2f,
                cell * 0.3f * overshoot(prog).coerceAtMost(1.08f),
                Ink.primary, Ink.primaryLedge, p)
        }
    }
}

/**
 * Equal groups: several bags with the same number in each.
 *
 * Read forwards it is multiplication. Read backwards — "these thirty shared
 * into five bags" — it is division, and it is deliberately the same picture,
 * because they are the same fact and a child who sees that has learned
 * something a rule cannot give them.
 */
class GroupsView(ctx: Context) : NumberView(ctx) {

    var groups = 0
        set(v) { field = v; requestLayout(); invalidate() }
    var per = 0
        set(v) { field = v; requestLayout(); invalidate() }
    var glyph: String = Glyphs.STAR
        set(v) { field = v; invalidate() }

    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val anim = Anim(this)

    fun play() = anim.play(80L * (groups * per).coerceIn(6, 16))
    fun settle() = anim.settle()

    private fun bagW(w: Int) =
        minOf((w - context.dpf(10f) * (groups - 1)) / groups.coerceAtLeast(1),
            context.dpf(96f))

    private val cols get() = if (per <= 4) 2 else 3

    private fun bagH(w: Int): Float {
        val rows = Math.ceil(per / cols.toDouble()).toInt().coerceAtLeast(1)
        return maxOf(context.dpf(64f), rows * bagW(w) / cols + context.dpf(18f))
    }

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        val w = MeasureSpec.getSize(widthSpec)
        setMeasuredDimension(w, bagH(w).toInt())
    }

    override fun onDraw(canvas: Canvas) {
        if (groups <= 0 || per <= 0) return
        val bw = bagW(width)
        val bh = bagH(width)
        val gap = context.dpf(10f)
        val ox = (width - (bw * groups + gap * (groups - 1))) / 2f
        for (g in 0 until groups) {
            val bx = ox + g * (bw + gap)
            p.style = Paint.Style.FILL
            p.color = 0xFFF7F6FC.toInt()
            canvas.drawRoundRect(bx, 0f, bx + bw, bh,
                context.dpf(14f), context.dpf(14f), p)
            p.style = Paint.Style.STROKE
            p.strokeWidth = context.dpf(2f)
            p.color = Ink.line
            canvas.drawRoundRect(bx, 0f, bx + bw, bh,
                context.dpf(14f), context.dpf(14f), p)
            p.style = Paint.Style.FILL
            val cw = bw / cols
            for (k in 0 until per) {
                val prog = anim.stagger(g * per + k, groups * per)
                if (prog <= 0f) continue
                Glyphs.draw(canvas, glyph,
                    bx + (k % cols) * cw + cw / 2f,
                    context.dpf(12f) + (k / cols) * cw + cw / 2f,
                    minOf(cw * 0.3f, context.dpf(13f)) *
                        overshoot(prog).coerceAtMost(1.1f),
                    Ink.primary, Ink.primaryLedge, p)
            }
        }
    }
}

/**
 * Two bars, drawn to the same scale.
 *
 * "How many more" is the question children find hardest to picture, because
 * nothing in the words says to compare. Two bars side by side put the answer
 * on the screen as the bit one has and the other does not — the arithmetic
 * only confirms what is already visible.
 */
class BarModelView(ctx: Context) : NumberView(ctx) {

    var a = 0
        set(v) { field = v; invalidate() }
    var b = 0
        set(v) { field = v; invalidate() }

    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val anim = Anim(this)

    /** The bars grow from nothing, so their difference arrives last. */
    fun play() = anim.play(560L)
    fun settle() = anim.settle()

    private val barH get() = context.dpf(34f)
    private val gap get() = context.dpf(16f)

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        setMeasuredDimension(MeasureSpec.getSize(widthSpec),
            (barH * 2 + gap).toInt())
    }

    override fun onDraw(canvas: Canvas) {
        val hi = maxOf(a, b, 1)
        val unit = (width - context.dpf(40f)) / hi
        listOf(Triple(a, Ink.primary, Ink.primaryLedge),
               Triple(b, Ink.accent, Ink.accentLedge)).forEachIndexed { i, t ->
            val (v, face, ledge) = t
            val by = i * (barH + gap)
            val len = v * unit * anim.t
            p.style = Paint.Style.FILL
            p.color = ledge
            canvas.drawRoundRect(0f, by + context.dpf(3f), len,
                by + barH + context.dpf(3f), context.dpf(9f), context.dpf(9f), p)
            p.color = face
            canvas.drawRoundRect(0f, by, len, by + barH,
                context.dpf(9f), context.dpf(9f), p)
            p.color = Ink.muted
            p.textSize = context.dpf(15f)
            p.textAlign = Paint.Align.LEFT
            canvas.drawText("$v", len + context.dpf(12f),
                by + barH / 2f - (p.descent() + p.ascent()) / 2f, p)
        }
    }
}

/**
 * Strips of one length, cut into different numbers of pieces.
 *
 * This is the picture that settles the misconception every child has: that
 * cutting into eight gives bigger pieces than cutting into four, because
 * eight is the bigger number. No amount of arithmetic argues them out of it;
 * seeing the strips side by side does it in a second.
 *
 * The top strip is the one being asked about and is drawn in the brand colour
 * with a rule beneath it; the strips to choose between sit below in the accent.
 */
class FractionWallView(ctx: Context) : NumberView(ctx) {

    /** Each strip as (pieces, coloured). */
    var strips: List<Pair<Int, Int>> = emptyList()
        set(v) { field = v; requestLayout(); invalidate() }

    /**
     * True when the first strip is the one being asked ABOUT rather than one
     * of the answers — "the top shows half, tap the other half".
     *
     * For "which has the biggest pieces" every strip is a candidate, and
     * treating the top one as a reference would make the right answer
     * untappable whenever it happened to be first.
     */
    var referenceTop = true
        set(v) { field = v; invalidate() }

    var selectable = false
    var picked: Int = -1
        private set

    var onPick: ((Int) -> Unit)? = null

    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val anim = Anim(this)

    fun play() = anim.play(90L * strips.size.coerceIn(3, 6))
    fun settle() = anim.settle()

    private val stripH get() = context.dpf(32f)
    private val gap get() = context.dpf(10f)

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        setMeasuredDimension(MeasureSpec.getSize(widthSpec),
            (strips.size * (stripH + gap)).toInt().coerceAtLeast(dp(60)))
    }

    override fun onDraw(canvas: Canvas) {
        strips.forEachIndexed { i, (pieces, on) ->
            val prog = anim.stagger(i, strips.size)
            if (prog <= 0f) return@forEachIndexed
            val by = i * (stripH + gap)
            val cw = width / pieces.toFloat()
            val chosen = selectable && picked == i
            for (k in 0 until pieces) {
                val bx = k * cw
                p.style = Paint.Style.FILL
                p.color = when {
                    k < on && i == 0 && referenceTop -> Ink.primary
                    k < on -> Ink.accent
                    else -> 0xFFF1EFFA.toInt()
                }
                canvas.drawRoundRect(bx + context.dpf(1.5f), by,
                    bx + cw - context.dpf(1.5f), by + stripH,
                    context.dpf(6f), context.dpf(6f), p)
                p.style = Paint.Style.STROKE
                p.strokeWidth = context.dpf(if (chosen) 2.5f else 1.5f)
                p.color = if (chosen) ink(true) else Ink.line
                canvas.drawRoundRect(bx + context.dpf(1.5f), by,
                    bx + cw - context.dpf(1.5f), by + stripH,
                    context.dpf(6f), context.dpf(6f), p)
            }
            // A rule under the first strip: it is the one being asked about,
            // not one of the answers.
            if (i == 0 && referenceTop) {
                p.style = Paint.Style.STROKE
                p.strokeWidth = context.dpf(2f)
                p.color = Ink.ledge
                p.pathEffect = DashPathEffect(
                    floatArrayOf(context.dpf(5f), context.dpf(5f)), 0f)
                canvas.drawLine(0f, by + stripH + gap / 2f,
                    width.toFloat(), by + stripH + gap / 2f, p)
                p.pathEffect = null
            }
        }
        p.style = Paint.Style.FILL
    }

    override fun onTouchEvent(e: android.view.MotionEvent): Boolean {
        if (!selectable || verdict != null || strips.isEmpty()) return false
        if (e.action == android.view.MotionEvent.ACTION_DOWN) return true
        if (e.action != android.view.MotionEvent.ACTION_UP) return false
        val i = (e.y / (stripH + gap)).toInt()
        // Only skip the first strip when it is the reference.
        val first = if (referenceTop) 1 else 0
        if (i in first until strips.size) {
            picked = i
            onPick?.invoke(i)
            invalidate()
        }
        performClick()
        return true
    }

    override fun performClick(): Boolean { super.performClick(); return true }

    /** Screen point of strip [i], for the on-device test driver. */
    fun stripOnScreen(i: Int): IntArray {
        val loc = IntArray(2)
        getLocationOnScreen(loc)
        return intArrayOf(loc[0] + width / 2,
            (loc[1] + i * (stripH + gap) + stripH / 2f).toInt())
    }
}
