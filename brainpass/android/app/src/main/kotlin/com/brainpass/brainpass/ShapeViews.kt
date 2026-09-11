package com.brainpass.brainpass

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PointF
import android.view.MotionEvent

/**
 * The playful half of the ages 5-8 skill: shapes, patterns and odd-one-out.
 *
 * Counting teaches how many. These teach a child to LOOK — that a big triangle
 * has smaller triangles hiding in it, that a run of shapes has a rule, that one
 * of these four is not like the others. None of it needs reading, all of it is
 * answered by pointing, and a child who is enjoying themselves keeps going.
 */

/**
 * One piece of a figure: a polygon in the view's own coordinates, which the
 * child can tap.
 *
 * [kind] is what the piece actually is ("triangle", "square"), so a question can
 * ask for all the triangles and grade by kind rather than by index.
 */
class HuntPart(
    val kind: String,
    val points: List<PointF>,
    /** Drawn filled when false — outline-only pieces read as part of the whole. */
    val outlineOnly: Boolean = false,
)

/**
 * Shapes hidden inside a bigger shape.
 *
 * The figure is drawn as one object, and every piece a child can find is a
 * tappable polygon on top of it. The pleasure is in noticing that the big
 * triangle is also four small ones — which is the same idea as a number being
 * made of other numbers, arriving through the eyes instead.
 */
class ShapeHuntView(ctx: Context) : NumberView(ctx) {

    /**
     * The figure's polygons, supplied by the question.
     *
     * These used to be a table inside this file, copied again into the checker
     * and again into the review page. The three drifted, and four pieces the
     * table called squares measured as rectangles — so "tap every square" on
     * the house had no correct answer at all. There is one source now and it
     * arrives with the data.
     */
    fun setParts(list: List<Pair<String, List<Pair<Float, Float>>>>) {
        recipe = list
        parts = null
        invalidate()
    }

    private var recipe: List<Pair<String, List<Pair<Float, Float>>>> = emptyList()

    var multi = true
    var picked = mutableSetOf<Int>()
        private set

    var onPick: ((Set<Int>) -> Unit)? = null

    private var parts: List<HuntPart>? = null
    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val path = Path()
    private val anim = Anim(this)

    /**
     * The figure assembles piece by piece.
     *
     * Watching a big triangle built out of four small ones is the lesson; a
     * finished figure only ever looks like one shape.
     */
    fun play() = anim.play(120L * (recipe.size).coerceIn(3, 6))

    fun reset() { picked.clear(); clearVerdict(); invalidate() }

    /** The kind of each piece, so a caller can grade "all the triangles". */
    fun kinds(): List<String> = recipe.map { it.first }

    private fun build(): List<HuntPart> {
        parts?.let { return it }
        val w = width.toFloat()
        val h = height.toFloat()
        if (w <= 0f || h <= 0f || recipe.isEmpty()) return emptyList()
        val s = minOf(w, h) * 0.86f
        val ox = (w - s) / 2f
        val oy = (h - s) / 2f
        val out = recipe.map { (kind, pts) ->
            HuntPart(kind, pts.map { PointF(ox + it.first * s, oy + it.second * s) })
        }
        parts = out
        return out
    }

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        val w = MeasureSpec.getSize(widthSpec)
        setMeasuredDimension(w, minOf(w, dp(260)))
    }

    override fun onSizeChanged(w: Int, h: Int, ow: Int, oh: Int) {
        parts = null
    }

    override fun onDraw(canvas: Canvas) {
        val ps = build()
        ps.forEachIndexed { i, part ->
            if (anim.stagger(i, ps.size) <= 0f) return@forEachIndexed
            path.reset()
            part.points.forEachIndexed { k, pt ->
                if (k == 0) path.moveTo(pt.x, pt.y) else path.lineTo(pt.x, pt.y)
            }
            path.close()
            val on = i in picked
            // A wireframe reads as a diagram; a child needs an object. The
            // pieces are filled and the lines are heavy enough to look drawn
            // rather than measured.
            p.style = Paint.Style.FILL
            p.color = if (on) wash(true) else 0xFFF3F1FB.toInt()
            canvas.drawPath(path, p)
            p.style = Paint.Style.STROKE
            p.strokeJoin = Paint.Join.ROUND
            p.strokeCap = Paint.Cap.ROUND
            p.strokeWidth = context.dpf(if (on) 5f else 3.5f)
            p.color = if (on) ink(true) else Ink.ledge
            canvas.drawPath(path, p)
        }
        p.style = Paint.Style.FILL
    }

    override fun onTouchEvent(e: MotionEvent): Boolean {
        if (verdict != null) return false
        if (e.action == MotionEvent.ACTION_DOWN) return true
        if (e.action != MotionEvent.ACTION_UP) return false
        val ps = build()
        // Later pieces sit on top, so search backwards for the one tapped.
        for (i in ps.indices.reversed()) {
            if (Glyphs.inside(ps[i].points, e.x, e.y)) {
                if (!multi) picked.clear()
                if (i in picked) picked.remove(i) else picked.add(i)
                onPick?.invoke(picked)
                invalidate()
                break
            }
        }
        performClick()
        return true
    }

    override fun performClick(): Boolean { super.performClick(); return true }

    /**
     * A screen point that really does select piece [i], for the test driver.
     *
     * The centroid is not good enough: pieces overlap, a tap goes to the
     * topmost one, and the house's body square has its middle inside the door.
     * Aiming at the centroid selected the door instead — and on the second tap
     * unselected it again. So this returns a point inside the piece that no
     * later piece covers.
     */
    fun partOnScreen(i: Int): IntArray {
        val ps = build()
        if (i !in ps.indices) return intArrayOf(-1, -1)
        val loc = IntArray(2)
        getLocationOnScreen(loc)
        val pts = ps[i].points

        fun free(x: Float, y: Float): Boolean {
            if (!Glyphs.inside(pts, x, y)) return false
            for (j in i + 1 until ps.size) {
                if (Glyphs.inside(ps[j].points, x, y)) return false
            }
            return true
        }

        fun out(x: Float, y: Float) =
            intArrayOf((loc[0] + x).toInt(), (loc[1] + y).toInt())

        val cx = pts.map { it.x }.average().toFloat()
        val cy = pts.map { it.y }.average().toFloat()
        if (free(cx, cy)) return out(cx, cy)

        val minX = pts.minOf { it.x }
        val maxX = pts.maxOf { it.x }
        val minY = pts.minOf { it.y }
        val maxY = pts.maxOf { it.y }
        val steps = 28
        for (b in 1 until steps) for (a in 1 until steps) {
            val x = minX + (maxX - minX) * a / steps
            val y = minY + (maxY - minY) * b / steps
            if (free(x, y)) return out(x, y)
        }
        return out(cx, cy)
    }
}

/** One cell of a pattern: a shape, a colour and a turn. */
class Cell(
    val kind: String,
    val color: Int,
    val rotation: Float = 0f,
)

/**
 * A run of shapes with one cell left blank.
 *
 * Seeing that red-star, blue-heart, red-star must continue with blue-heart is a
 * child's first taste of a rule that keeps going — the same muscle a loop uses
 * in the older skill, learned years earlier and without a word of it.
 */
class PatternStripView(ctx: Context, private val fonts: Fonts) : NumberView(ctx) {

    var cells: List<Cell> = emptyList()
        set(v) { field = v; requestLayout(); invalidate() }

    /** Index drawn as a question mark; -1 for none. */
    var gapAt: Int = -1
        set(v) { field = v; invalidate() }

    /** Filled into the gap once the child has chosen. */
    var answer: Cell? = null
        set(v) { field = v; invalidate() }

    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val anim = Anim(this)

    /**
     * The run builds left to right.
     *
     * A pattern is a rule that keeps going, and watching it lay itself down in
     * order is what makes the rule visible — all five at once is just a row.
     */
    fun play() = anim.play(130L * cells.size.coerceIn(3, 6))

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        val w = MeasureSpec.getSize(widthSpec)
        setMeasuredDimension(w, cellFor(w).toInt() + dp(8))
    }

    private fun cellFor(w: Int): Float {
        val n = cells.size.coerceAtLeast(1)
        return minOf((w - context.dpf(8f)) / n, context.dpf(76f))
    }

    override fun onDraw(canvas: Canvas) {
        if (cells.isEmpty()) return
        val cell = cellFor(width)
        val ox = (width - cell * cells.size) / 2f
        val cy = height / 2f
        cells.forEachIndexed { i, c ->
            val prog = anim.stagger(i, cells.size)
            if (prog <= 0f) return@forEachIndexed
            val cx = ox + i * cell + cell / 2f
            val r = cell * 0.31f * overshoot(prog).coerceAtMost(1.1f)
            if (i == gapAt && answer == null) {
                p.style = Paint.Style.STROKE
                p.strokeWidth = context.dpf(3f)
                p.color = ink(true)
                p.pathEffect = android.graphics.DashPathEffect(
                    floatArrayOf(context.dpf(7f), context.dpf(6f)), 0f)
                canvas.drawRoundRect(cx - r * 1.25f, cy - r * 1.25f,
                    cx + r * 1.25f, cy + r * 1.25f, r * 0.4f, r * 0.4f, p)
                p.pathEffect = null
                p.style = Paint.Style.FILL
                p.color = ink(true)
                p.typeface = fonts.black
                p.textSize = r * 1.15f
                p.textAlign = Paint.Align.CENTER
                canvas.drawText("?", cx, cy - (p.descent() + p.ascent()) / 2f, p)
            } else {
                val show = if (i == gapAt) answer!! else c
                Glyphs.draw(canvas, show.kind, cx, cy, r, show.color,
                    ledgeFor(show.color), p, show.rotation)
            }
        }
    }

    private fun ledgeFor(face: Int) = when (face) {
        Ink.primary -> Ink.primaryLedge
        Ink.accent -> Ink.accentLedge
        Ink.good -> Ink.goodLedge
        Ink.bad -> Ink.badLedge
        else -> null
    }
}

/**
 * Four things, one of which does not belong.
 *
 * The rule is never stated — it might be colour, shape, or how many corners —
 * so the child has to work out what the others have in common before they can
 * say which one breaks it.
 */
class OddOneOutView(ctx: Context) : NumberView(ctx) {

    var cells: List<Cell> = emptyList()
        set(v) { field = v; requestLayout(); invalidate() }

    var picked: Int = -1
        private set

    var onPick: ((Int) -> Unit)? = null

    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val anim = Anim(this)

    /** The four land one after another, so each is looked at on its own. */
    fun play() = anim.play(110L * cells.size.coerceIn(3, 5))

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        val w = MeasureSpec.getSize(widthSpec)
        setMeasuredDimension(w, tileFor(w).toInt() + dp(10))
    }

    private fun tileFor(w: Int): Float {
        val n = cells.size.coerceAtLeast(1)
        return minOf((w - context.dpf(10f) * (n - 1)) / n, context.dpf(84f))
    }

    override fun onDraw(canvas: Canvas) {
        if (cells.isEmpty()) return
        val tile = tileFor(width)
        val gap = context.dpf(10f)
        val total = tile * cells.size + gap * (cells.size - 1)
        val ox = (width - total) / 2f
        val cy = height / 2f
        cells.forEachIndexed { i, c ->
            val prog = anim.stagger(i, cells.size)
            if (prog <= 0f) return@forEachIndexed
            val left = ox + i * (tile + gap)
            val on = i == picked
            p.style = Paint.Style.FILL
            p.color = wash(on)
            canvas.drawRoundRect(left, cy - tile / 2f, left + tile, cy + tile / 2f,
                context.dpf(16f), context.dpf(16f), p)
            p.style = Paint.Style.STROKE
            p.strokeWidth = context.dpf(if (on) 3.5f else 2f)
            p.color = if (on) ink(true) else Ink.line
            canvas.drawRoundRect(left, cy - tile / 2f, left + tile, cy + tile / 2f,
                context.dpf(16f), context.dpf(16f), p)
            p.style = Paint.Style.FILL
            Glyphs.draw(canvas, c.kind, left + tile / 2f, cy,
                tile * 0.28f * overshoot(prog).coerceAtMost(1.08f),
                c.color, null, p, c.rotation)
        }
    }

    override fun onTouchEvent(e: MotionEvent): Boolean {
        if (verdict != null || cells.isEmpty()) return false
        if (e.action == MotionEvent.ACTION_DOWN) return true
        if (e.action != MotionEvent.ACTION_UP) return false
        val tile = tileFor(width)
        val gap = context.dpf(10f)
        val total = tile * cells.size + gap * (cells.size - 1)
        val ox = (width - total) / 2f
        val i = ((e.x - ox) / (tile + gap)).toInt()
        if (i in cells.indices) {
            picked = i
            onPick?.invoke(i)
            invalidate()
        }
        performClick()
        return true
    }

    override fun performClick(): Boolean { super.performClick(); return true }

    /** Screen point of tile [i], for the on-device test driver. */
    fun tileOnScreen(i: Int): IntArray {
        val loc = IntArray(2)
        getLocationOnScreen(loc)
        val tile = tileFor(width)
        val gap = context.dpf(10f)
        val total = tile * cells.size + gap * (cells.size - 1)
        val ox = (width - total) / 2f
        return intArrayOf((loc[0] + ox + i * (tile + gap) + tile / 2f).toInt(),
            loc[1] + height / 2)
    }
}
