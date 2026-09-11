package com.brainpass.brainpass

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.view.MotionEvent

/**
 * More ways to show a number, because 324 questions need more than four
 * pictures.
 *
 * Variety here is not garnish. A child who meets the same ten frame forty times
 * stops looking at it and starts pattern-matching the answer, and a skill that
 * can be beaten without thinking has stopped teaching. Each of these says
 * something the others cannot: the scale says which is heavier without naming
 * either number, the rods say what a ten IS, the dice say a number can be known
 * without counting, the mirror says a shape can be folded.
 */

/**
 * A balance scale that tips towards the heavier side.
 *
 * Comparing without numerals: a child sees which side goes down before they can
 * read "7 > 4", and the tipping does the explaining. When the two sides match
 * it settles level, which is a better picture of "the same" than an equals sign.
 */
class BalanceScaleView(ctx: Context) : NumberView(ctx) {

    var leftCount = 0
        set(v) { field = v; invalidate() }
    var rightCount = 0
        set(v) { field = v; invalidate() }
    var glyph: String = Glyphs.STAR
        set(v) { field = v; invalidate() }

    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val anim = Anim(this)

    /** Starts level and tips, so the child sees the comparison happen. */
    fun play() = anim.play(620L)
    fun settle() = anim.settle()

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        setMeasuredDimension(MeasureSpec.getSize(widthSpec), dp(196))
    }

    override fun onDraw(canvas: Canvas) {
        val w = width.toFloat()
        val cx = w / 2f
        // The beam sits high enough that a tipped pan and its load still fit,
        // and low enough that the card is not mostly empty above it.
        val pivotY = height * 0.36f
        val armW = minOf(w * 0.78f, context.dpf(300f)) / 2f

        // The heavier pan goes DOWN. A larger y is lower on the canvas, so a
        // heavier left needs a LARGER ly — negating this lifted the heavy side
        // and taught every child the opposite of how a balance works.
        val diff = (leftCount - rightCount).coerceIn(-3, 3) / 3f
        val tilt = diff * context.dpf(30f) * anim.t

        // Post and base.
        p.style = Paint.Style.FILL
        p.color = Ink.ledge
        canvas.drawRoundRect(cx - context.dpf(7f), pivotY - context.dpf(4f),
            cx + context.dpf(7f), height - context.dpf(14f),
            context.dpf(5f), context.dpf(5f), p)
        canvas.drawRoundRect(cx - context.dpf(46f), height - context.dpf(18f),
            cx + context.dpf(46f), height - context.dpf(4f),
            context.dpf(7f), context.dpf(7f), p)

        // Beam.
        val ly = pivotY + tilt
        val ry = pivotY - tilt
        p.style = Paint.Style.STROKE
        p.strokeCap = Paint.Cap.ROUND
        p.strokeWidth = context.dpf(8f)
        p.color = Ink.primary
        canvas.drawLine(cx - armW, ly, cx + armW, ry, p)
        p.style = Paint.Style.FILL
        p.color = Ink.primaryLedge
        canvas.drawCircle(cx, pivotY, context.dpf(11f), p)

        pan(canvas, cx - armW, ly, leftCount, Ink.primary, Ink.primaryLedge)
        pan(canvas, cx + armW, ry, rightCount, Ink.accent, Ink.accentLedge)
    }

    private fun pan(c: Canvas, x: Float, y: Float, n: Int, face: Int, ledge: Int) {
        val panW = context.dpf(80f)
        // Far enough below the beam that a second row of counters clears it.
        // At 32dp a five-counter load put its top star through the beam, which
        // read as a broken picture rather than a heavy pan.
        val panTop = y + context.dpf(42f)
        p.style = Paint.Style.STROKE
        p.strokeWidth = context.dpf(2.5f)
        p.color = Ink.ledge
        c.drawLine(x, y, x, panTop, p)
        p.style = Paint.Style.FILL
        p.color = Ink.line
        c.drawRoundRect(x - panW / 2f, panTop, x + panW / 2f,
            panTop + context.dpf(9f), context.dpf(5f), context.dpf(5f), p)

        // The load STANDS ON the pan and stacks upward, three to a row.
        //
        // Drawing it from the beam downward put the counters above the beam and
        // through it, so a pan of six looked like scattered stars rather than a
        // load — which is the one thing the picture has to say.
        val r = context.dpf(8f)
        // Four to a row keeps the biggest load in this skill (eight) to two
        // rows, which is what stops the top row reaching the beam.
        val perRow = 4
        for (i in 0 until n.coerceAtMost(9)) {
            val col = i % perRow
            val row = i / perRow
            val cols = minOf(n - row * perRow, perRow)
            c.save()
            Glyphs.draw(c, glyph,
                x + (col - (cols - 1) / 2f) * r * 2.15f,
                panTop - r * 1.05f - row * r * 2.05f,
                r, face, ledge, p)
            c.restore()
        }
    }
}

/**
 * Base-ten rods: tens as sticks of ten, ones as loose cubes.
 *
 * "Twenty-three" is a word until a child sees two full rods and three spare
 * cubes. The rod is drawn as ten joined squares rather than a plain bar,
 * because a bar has to be taken on trust and a row of ten can be checked.
 */
class RodsView(ctx: Context) : NumberView(ctx) {

    var value = 0
        set(v) { field = v; requestLayout(); invalidate() }

    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val anim = Anim(this)

    fun play() = anim.play(640L)
    fun settle() = anim.settle()

    private val tens get() = value / 10
    private val ones get() = value % 10

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        setMeasuredDimension(MeasureSpec.getSize(widthSpec), dp(200))
    }

    override fun onDraw(canvas: Canvas) {
        // Sized from the height so a rod fills the card. At 13dp the blocks
        // were a thin strip in a mostly empty box — unreadable for the one
        // thing being asked, which is to count them.
        val unit = minOf(context.dpf(18f), height / 11.5f, width / 14f)
        val rodH = unit * 10
        val gap = unit * 0.7f
        val cols = tens + (if (ones > 0) 1 else 0)
        if (cols == 0) return
        val totalW = cols * unit + (cols - 1) * gap
        val ox = (width - totalW) / 2f
        val oy = (height - rodH) / 2f

        for (t in 0 until tens) {
            val prog = anim.stagger(t, cols)
            val x = ox + t * (unit + gap)
            for (k in 0 until 10) {
                cube(canvas, x, oy + k * unit, unit, prog, Ink.primary, Ink.primaryLedge)
            }
        }
        if (ones > 0) {
            val prog = anim.stagger(tens, cols)
            val x = ox + tens * (unit + gap)
            for (k in 0 until ones) {
                cube(canvas, x, oy + rodH - (k + 1) * unit, unit, prog,
                    Ink.accent, Ink.accentLedge)
            }
        }
    }

    private fun cube(
        c: Canvas, x: Float, y: Float, u: Float, prog: Float, face: Int, ledge: Int,
    ) {
        if (prog <= 0f) return
        val s = u * 0.9f * overshoot(prog).coerceAtMost(1.05f)
        val cx = x + u / 2f
        val cy = y + u / 2f
        p.style = Paint.Style.FILL
        p.color = ledge
        c.drawRoundRect(cx - s / 2f, cy - s / 2f + u * 0.08f, cx + s / 2f,
            cy + s / 2f + u * 0.08f, u * 0.22f, u * 0.22f, p)
        p.color = face
        c.drawRoundRect(cx - s / 2f, cy - s / 2f, cx + s / 2f, cy + s / 2f,
            u * 0.22f, u * 0.22f, p)
    }
}

/**
 * Dice and domino faces.
 *
 * A child who has to count five dots every time is still counting; one who
 * knows the five-face at sight has started to hold numbers whole. The arranged
 * face is what makes that possible, so the dot positions are the standard ones
 * rather than anything prettier.
 */
class DiceView(ctx: Context) : NumberView(ctx) {

    /** One or two faces; two reads as a domino, and as an addition. */
    var faces: List<Int> = listOf(5)
        set(v) { field = v; requestLayout(); invalidate() }

    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val anim = Anim(this)

    fun play() = anim.play(500L)
    fun settle() = anim.settle()

    private val spots = mapOf(
        1 to listOf(1 to 1),
        2 to listOf(0 to 0, 2 to 2),
        3 to listOf(0 to 0, 1 to 1, 2 to 2),
        4 to listOf(0 to 0, 2 to 0, 0 to 2, 2 to 2),
        5 to listOf(0 to 0, 2 to 0, 1 to 1, 0 to 2, 2 to 2),
        6 to listOf(0 to 0, 2 to 0, 0 to 1, 2 to 1, 0 to 2, 2 to 2),
    )

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        val w = MeasureSpec.getSize(widthSpec)
        setMeasuredDimension(w, faceFor(w).toInt() + dp(12))
    }

    private fun faceFor(w: Int): Float {
        val n = faces.size.coerceAtLeast(1)
        return minOf((w - context.dpf(16f) * (n - 1)) / n, context.dpf(112f))
    }

    override fun onDraw(canvas: Canvas) {
        val face = faceFor(width)
        val gap = context.dpf(16f)
        val total = face * faces.size + gap * (faces.size - 1)
        val ox = (width - total) / 2f
        val oy = (height - face) / 2f

        faces.forEachIndexed { fi, n ->
            val left = ox + fi * (face + gap)
            p.style = Paint.Style.FILL
            p.color = Ink.ledge
            canvas.drawRoundRect(left, oy + context.dpf(4f), left + face,
                oy + face + context.dpf(4f), face * 0.2f, face * 0.2f, p)
            p.color = Ink.surface
            canvas.drawRoundRect(left, oy, left + face, oy + face,
                face * 0.2f, face * 0.2f, p)
            p.style = Paint.Style.STROKE
            p.strokeWidth = context.dpf(2f)
            p.color = Ink.line
            canvas.drawRoundRect(left, oy, left + face, oy + face,
                face * 0.2f, face * 0.2f, p)
            p.style = Paint.Style.FILL

            val dot = face * 0.11f
            val step = face * 0.27f
            val c0 = left + face / 2f
            val r0 = oy + face / 2f
            val colour = if (fi == 0) Ink.primary else Ink.accent
            val ledge = if (fi == 0) Ink.primaryLedge else Ink.accentLedge
            spots[n.coerceIn(1, 6)]?.forEachIndexed { di, (gx, gy) ->
                val prog = anim.stagger(di, spots[n.coerceIn(1, 6)]!!.size)
                if (prog <= 0f) return@forEachIndexed
                val r = dot * overshoot(prog).coerceAtMost(1.08f)
                Glyphs.draw(canvas, Glyphs.CIRCLE,
                    c0 + (gx - 1) * step, r0 + (gy - 1) * step, r, colour, ledge, p)
            }
        }
    }
}

/**
 * A shape on one side of a mirror line, to be completed on the other.
 *
 * Symmetry is the first idea a child meets where the answer is a whole picture
 * rather than a number, and it is genuinely satisfying to finish. The grid keeps
 * it tappable: fill the squares that make the two halves match.
 */
class MirrorView(ctx: Context) : NumberView(ctx) {

    var cols = 6
    var rows = 5

    /** Cells filled on the left, as (col, row) with col < cols / 2. */
    var given: Set<Pair<Int, Int>> = emptySet()
        set(v) { field = v; invalidate() }

    var picked = mutableSetOf<Pair<Int, Int>>()
        private set

    var onPick: ((Set<Pair<Int, Int>>) -> Unit)? = null

    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val anim = Anim(this)

    fun play() = anim.play(560L)
    fun reset() { picked.clear(); clearVerdict(); invalidate() }

    /** The cells that would make the picture symmetrical. */
    fun answer(): Set<Pair<Int, Int>> =
        given.map { (c, r) -> (cols - 1 - c) to r }.toSet()

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        val w = MeasureSpec.getSize(widthSpec)
        val cell = minOf(w / cols.toFloat(), context.dpf(46f))
        setMeasuredDimension(w, (cell * rows).toInt())
    }

    override fun onDraw(canvas: Canvas) {
        val cell = minOf(width / cols.toFloat(), context.dpf(46f))
        val ox = (width - cell * cols) / 2f
        val inset = context.dpf(2.5f)

        for (r in 0 until rows) for (c in 0 until cols) {
            val on = (c to r) in given || (c to r) in picked
            val isGiven = (c to r) in given
            val x = ox + c * cell
            val y = r * cell
            p.style = Paint.Style.FILL
            p.color = if (on) Ink.surface else 0xFFF7F6FC.toInt()
            canvas.drawRoundRect(x + inset, y + inset, x + cell - inset,
                y + cell - inset, context.dpf(7f), context.dpf(7f), p)
            p.style = Paint.Style.STROKE
            p.strokeWidth = context.dpf(1.5f)
            p.color = Ink.line
            canvas.drawRoundRect(x + inset, y + inset, x + cell - inset,
                y + cell - inset, context.dpf(7f), context.dpf(7f), p)
            if (on) {
                p.style = Paint.Style.FILL
                val prog = if (isGiven) anim.t else 1f
                val rr = cell * 0.3f * overshoot(prog).coerceAtMost(1.06f)
                Glyphs.draw(canvas, Glyphs.SQUARE, x + cell / 2f, y + cell / 2f, rr,
                    if (isGiven) Ink.primary else Ink.accent,
                    if (isGiven) Ink.primaryLedge else Ink.accentLedge, p)
            }
        }

        // The fold, drawn last so it sits over the grid.
        val mx = ox + cell * cols / 2f
        p.style = Paint.Style.STROKE
        p.strokeWidth = context.dpf(3f)
        p.color = Ink.primary
        p.pathEffect = android.graphics.DashPathEffect(
            floatArrayOf(context.dpf(9f), context.dpf(7f)), 0f)
        canvas.drawLine(mx, 0f, mx, cell * rows, p)
        p.pathEffect = null
        p.style = Paint.Style.FILL
    }

    override fun onTouchEvent(e: MotionEvent): Boolean {
        if (verdict != null) return false
        if (e.action == MotionEvent.ACTION_DOWN) return true
        if (e.action != MotionEvent.ACTION_UP) return false
        val cell = minOf(width / cols.toFloat(), context.dpf(46f))
        val ox = (width - cell * cols) / 2f
        val c = ((e.x - ox) / cell).toInt()
        val r = (e.y / cell).toInt()
        // Only the empty half is answerable; the given half is the question.
        if (c in cols / 2 until cols && r in 0 until rows) {
            val k = c to r
            if (k in picked) picked.remove(k) else picked.add(k)
            onPick?.invoke(picked)
            invalidate()
        }
        performClick()
        return true
    }

    override fun performClick(): Boolean { super.performClick(); return true }

    /** Screen point of cell (c, r), for the on-device test driver. */
    fun cellOnScreen(c: Int, r: Int): IntArray {
        val cell = minOf(width / cols.toFloat(), context.dpf(46f))
        val ox = (width - cell * cols) / 2f
        val loc = IntArray(2)
        getLocationOnScreen(loc)
        return intArrayOf((loc[0] + ox + (c + 0.5f) * cell).toInt(),
            (loc[1] + (r + 0.5f) * cell).toInt())
    }
}
