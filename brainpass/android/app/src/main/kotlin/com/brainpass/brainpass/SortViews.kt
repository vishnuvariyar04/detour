package com.brainpass.brainpass

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.view.MotionEvent

/**
 * Sorting, ordering and fractions — the last three pictures in the kit.
 *
 * All three are answered by tapping, never by dragging. A drag on a phone held
 * by a five year old misses far more often than it lands, and a missed drag
 * reads as the app being broken rather than the answer being wrong. The same
 * rule already governs the block bank in the older skill.
 */

/**
 * Things to put into two groups.
 *
 * Sorting is where a child first has to say what a rule IS: these are round and
 * those are not, these are yellow and those are not. Tapping an item sends it to
 * the other tray, so the whole puzzle is one gesture repeated.
 */
class SortTrayView(ctx: Context, private val fonts: Fonts) : NumberView(ctx) {

    /** The things being sorted, in their starting order. */
    var items: List<Cell> = emptyList()
        set(v) { field = v; side = IntArray(v.size); requestLayout(); invalidate() }

    /** Names for the two trays; short enough for a beginning reader. */
    var leftLabel = "ROUND"
    var rightLabel = "NOT ROUND"

    /** Which tray each item is in: 0 = left, 1 = right. */
    var side = IntArray(0)
        private set

    var onChange: ((IntArray) -> Unit)? = null

    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val anim = Anim(this)

    fun play() = anim.play(520L)
    fun reset() { side = IntArray(items.size); clearVerdict(); invalidate() }

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        setMeasuredDimension(MeasureSpec.getSize(widthSpec), dp(210))
    }

    private fun trayRect(i: Int): FloatArray {
        val gap = context.dpf(12f)
        val w = (width - gap) / 2f
        val top = context.dpf(34f)
        return floatArrayOf(i * (w + gap), top, i * (w + gap) + w, height.toFloat())
    }

    override fun onDraw(canvas: Canvas) {
        for (t in 0 until 2) {
            val r = trayRect(t)
            p.style = Paint.Style.FILL
            p.color = 0xFFF7F6FC.toInt()
            canvas.drawRoundRect(r[0], r[1], r[2], r[3],
                context.dpf(16f), context.dpf(16f), p)
            p.style = Paint.Style.STROKE
            p.strokeWidth = context.dpf(2f)
            p.color = Ink.line
            canvas.drawRoundRect(r[0], r[1], r[2], r[3],
                context.dpf(16f), context.dpf(16f), p)

            p.style = Paint.Style.FILL
            p.color = Ink.muted
            p.typeface = fonts.extra
            p.textSize = context.dpf(12f)
            p.textAlign = Paint.Align.CENTER
            p.letterSpacing = 0.08f
            canvas.drawText(if (t == 0) leftLabel else rightLabel,
                (r[0] + r[2]) / 2f, context.dpf(22f), p)
            p.letterSpacing = 0f
        }

        // Items sit in their tray in the order they were dropped there.
        val perTray = IntArray(2)
        items.forEachIndexed { i, c ->
            val t = side.getOrElse(i) { 0 }
            val slot = perTray[t]++
            val r = trayRect(t)
            val cols = 3
            val cell = (r[2] - r[0]) / cols
            val cx = r[0] + (slot % cols) * cell + cell / 2f
            val cy = r[1] + context.dpf(16f) + (slot / cols) * cell + cell / 2f
            val prog = anim.stagger(i, items.size.coerceAtLeast(1))
            if (prog <= 0f) return@forEachIndexed
            Glyphs.draw(canvas, c.kind, cx, cy,
                cell * 0.28f * overshoot(prog).coerceAtMost(1.1f),
                c.color, ledgeFor(c.color), p, c.rotation)
        }
    }

    private fun ledgeFor(face: Int) = when (face) {
        Ink.primary -> Ink.primaryLedge
        Ink.accent -> Ink.accentLedge
        else -> null
    }

    override fun onTouchEvent(e: MotionEvent): Boolean {
        if (verdict != null || items.isEmpty()) return false
        if (e.action == MotionEvent.ACTION_DOWN) return true
        if (e.action != MotionEvent.ACTION_UP) return false
        // Find which drawn item was hit, using the same layout as onDraw.
        val perTray = IntArray(2)
        items.forEachIndexed { i, _ ->
            val t = side.getOrElse(i) { 0 }
            val slot = perTray[t]++
            val r = trayRect(t)
            val cols = 3
            val cell = (r[2] - r[0]) / cols
            val cx = r[0] + (slot % cols) * cell + cell / 2f
            val cy = r[1] + context.dpf(16f) + (slot / cols) * cell + cell / 2f
            if (Math.hypot((e.x - cx).toDouble(), (e.y - cy).toDouble()) < cell * 0.42f) {
                side[i] = 1 - side[i]
                onChange?.invoke(side)
                invalidate()
                return@forEachIndexed
            }
        }
        performClick()
        return true
    }

    override fun performClick(): Boolean { super.performClick(); return true }

    /** Screen point of item [i], for the on-device test driver. */
    fun itemOnScreen(i: Int): IntArray {
        val loc = IntArray(2); getLocationOnScreen(loc)
        val perTray = IntArray(2)
        var out = intArrayOf(-1, -1)
        items.forEachIndexed { k, _ ->
            val t = side.getOrElse(k) { 0 }
            val slot = perTray[t]++
            if (k == i) {
                val r = trayRect(t)
                val cols = 3
                val cell = (r[2] - r[0]) / cols
                out = intArrayOf(
                    (loc[0] + r[0] + (slot % cols) * cell + cell / 2f).toInt(),
                    (loc[1] + r[1] + context.dpf(16f) + (slot / cols) * cell + cell / 2f).toInt())
            }
        }
        return out
    }
}

/**
 * The same shape at different sizes, to be tapped smallest first.
 *
 * Ordering is its own skill: a child can count perfectly and still not see that
 * these five belong in a line. The numbers are never shown, so the only way
 * through is to compare.
 */
class SizeOrderView(ctx: Context) : NumberView(ctx) {

    /** Relative sizes, in the order they are drawn (not the answer order). */
    var sizes: List<Float> = emptyList()
        set(v) { field = v; requestLayout(); invalidate() }

    var kind: String = Glyphs.STAR
    var color: Int = Ink.primary

    /** Tap order so far, as indices into [sizes]. */
    var order = mutableListOf<Int>()
        private set

    var onPick: ((List<Int>) -> Unit)? = null

    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val anim = Anim(this)

    fun play() = anim.play(560L)
    fun reset() { order.clear(); clearVerdict(); invalidate() }

    /** The indices in smallest-to-largest order: what a correct run looks like. */
    fun answer(): List<Int> = sizes.indices.sortedBy { sizes[it] }

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        setMeasuredDimension(MeasureSpec.getSize(widthSpec), dp(150))
    }

    private fun slotFor(i: Int): Pair<Float, Float> {
        val n = sizes.size.coerceAtLeast(1)
        val cell = width / n.toFloat()
        return (i * cell + cell / 2f) to (height / 2f)
    }

    override fun onDraw(canvas: Canvas) {
        val n = sizes.size
        if (n == 0) return
        val cell = width / n.toFloat()
        val maxR = minOf(cell * 0.42f, context.dpf(46f))
        sizes.forEachIndexed { i, s ->
            val (cx, cy) = slotFor(i)
            val prog = anim.stagger(i, n)
            if (prog <= 0f) return@forEachIndexed
            val r = maxR * s * overshoot(prog).coerceAtMost(1.06f)
            val rank = order.indexOf(i)
            Glyphs.draw(canvas, kind, cx, cy, r,
                if (rank >= 0) Ink.accent else color,
                if (rank >= 0) Ink.accentLedge else Ink.primaryLedge, p)
            if (rank >= 0) {
                // The number shows the order chosen, not the size.
                p.color = Ink.text
                p.textSize = context.dpf(15f)
                p.textAlign = Paint.Align.CENTER
                canvas.drawText("${rank + 1}", cx, cy + maxR + context.dpf(20f), p)
            }
        }
    }

    override fun onTouchEvent(e: MotionEvent): Boolean {
        if (verdict != null || sizes.isEmpty()) return false
        if (e.action == MotionEvent.ACTION_DOWN) return true
        if (e.action != MotionEvent.ACTION_UP) return false
        val cell = width / sizes.size.toFloat()
        val i = (e.x / cell).toInt()
        if (i in sizes.indices) {
            if (i in order) order.remove(i) else order.add(i)
            onPick?.invoke(order)
            invalidate()
        }
        performClick()
        return true
    }

    override fun performClick(): Boolean { super.performClick(); return true }

    /** Screen point of item [i], for the on-device test driver. */
    fun itemOnScreen(i: Int): IntArray {
        val loc = IntArray(2); getLocationOnScreen(loc)
        val (cx, cy) = slotFor(i)
        return intArrayOf((loc[0] + cx).toInt(), (loc[1] + cy).toInt())
    }
}

/**
 * A circle cut into equal slices, with some of them shaded.
 *
 * Halves and quarters are the first fractions a child meets, and they meet them
 * as cake and pizza rather than as notation. The slices are drawn equal and the
 * cuts are visible, because "half" only means anything if the two parts can be
 * seen to match.
 */
class FractionView(ctx: Context) : NumberView(ctx) {

    var slices = 4
        set(v) { field = v; invalidate() }
    var shaded = 1
        set(v) { field = v; invalidate() }

    /** A second circle beside the first, for comparing two fractions. */
    var otherSlices = 0
    var otherShaded = 0

    var selectable = false
    var picked = -1
        private set

    var onPick: ((Int) -> Unit)? = null

    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val anim = Anim(this)

    fun play() = anim.play(560L)

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        setMeasuredDimension(MeasureSpec.getSize(widthSpec), dp(176))
    }

    private val two get() = otherSlices > 0

    override fun onDraw(canvas: Canvas) {
        val r = minOf(context.dpf(72f), (if (two) width / 4.6f else width / 2.6f))
        val cy = height / 2f
        if (two) {
            pie(canvas, width * 0.28f, cy, r, slices, shaded, 0)
            pie(canvas, width * 0.72f, cy, r, otherSlices, otherShaded, 1)
        } else {
            pie(canvas, width / 2f, cy, r, slices, shaded, 0)
        }
    }

    private fun pie(c: Canvas, cx: Float, cy: Float, r: Float, n: Int, on: Int, which: Int) {
        val sweep = 360f / n
        val sel = selectable && picked == which
        for (i in 0 until n) {
            val lit = i < on
            val prog = if (lit) anim.stagger(i, n.coerceAtLeast(1)) else 1f
            p.style = Paint.Style.FILL
            p.color = when {
                lit && prog > 0f -> if (which == 0) Ink.primary else Ink.accent
                else -> 0xFFF3F1FB.toInt()
            }
            val rr = if (lit) r * (0.65f + 0.35f * prog) else r
            c.drawArc(cx - rr, cy - rr, cx + rr, cy + rr,
                -90f + i * sweep, sweep, true, p)
        }
        // Cuts and rim last, so the slices read as parts of one circle.
        p.style = Paint.Style.STROKE
        p.strokeWidth = context.dpf(2.5f)
        p.color = if (sel) Ink.primary else Ink.ledge
        for (i in 0 until n) {
            val a = Math.toRadians((-90f + i * sweep).toDouble())
            c.drawLine(cx, cy, cx + r * Math.cos(a).toFloat(),
                cy + r * Math.sin(a).toFloat(), p)
        }
        p.strokeWidth = context.dpf(if (sel) 4f else 3f)
        c.drawCircle(cx, cy, r, p)
        p.style = Paint.Style.FILL
    }

    override fun onTouchEvent(e: MotionEvent): Boolean {
        if (!selectable || verdict != null) return false
        if (e.action == MotionEvent.ACTION_DOWN) return true
        if (e.action != MotionEvent.ACTION_UP) return false
        picked = if (two && e.x > width / 2f) 1 else 0
        onPick?.invoke(picked)
        invalidate()
        performClick()
        return true
    }

    override fun performClick(): Boolean { super.performClick(); return true }
}
