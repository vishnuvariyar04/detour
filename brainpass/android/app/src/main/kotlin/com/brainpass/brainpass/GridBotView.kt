package com.brainpass.brainpass

import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.DashPathEffect
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Rect
import android.graphics.RectF
import android.view.MotionEvent
import android.view.View
import android.view.animation.DecelerateInterpolator
import kotlin.math.min

/**
 * GridBot: the board every Think Like a Coder question is asked on.
 *
 * The whole skill has one visual, so a child learns to read it once and then
 * spends every stop thinking about the program instead of the interface. Nupo
 * stands on a tile, a program moves him, and walls, stars, a key and a door are
 * the only other things that exist.
 *
 * The simulation lives in [Curriculum.Sim] — this view only draws and animates
 * what the simulator says happened, so what a child sees and what gets graded
 * can never drift apart.
 */
class GridBotView(ctx: Context) : View(ctx) {

    /** What a tap on the board means right now. */
    enum class Mode { INERT, PICK_CELL }

    var mode = Mode.INERT
    var onCellTap: ((Int, Int) -> Unit)? = null

    /** Slows to a crawl of instant jumps when the system asks for less motion. */
    var reducedMotion = false

    private var board: Curriculum.Board? = null
    private var selected: Pair<Int, Int>? = null
    private var verdict: Int? = null           // tint for the selected tile
    private var trail: List<Pair<Int, Int>> = emptyList()

    // Nupo's animated position, in tile units, so he can slide between tiles.
    private var botX = 0f
    private var botY = 0f
    private var botSquash = 0f                 // 0 = round, 1 = fully squashed
    private var botShake = 0f                  // px offset for a wall bump
    private var animator: ValueAnimator? = null

    private val fill = Paint(Paint.ANTI_ALIAS_FLAG)
    private val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE }
    private val dots = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
        color = Ink.trail
    }
    private val r = RectF()
    private val path = Path()
    private val src = Rect()

    // The launcher icon has a yellow rounded-square badge baked into it, which
    // reads as a game tile rather than a character. focused.png is the bare
    // sprite on transparency.
    private val nupo: Bitmap? = sequenceOf(
        "flutter_assets/assets/nupo/focused.png",
        "flutter_assets/assets/icon/nupo.png",
    ).mapNotNull { path ->
        runCatching { ctx.assets.open(path).use { BitmapFactory.decodeStream(it) } }.getOrNull()
    }.firstOrNull()

    // ------------------------------------------------------------------ setup

    fun setBoard(b: Curriculum.Board?, showPath: Boolean = false) {
        animator?.cancel()
        board = b
        selected = null
        verdict = null
        botSquash = 0f
        botShake = 0f
        botX = (b?.start?.first ?: 0).toFloat()
        botY = (b?.start?.second ?: 0).toFloat()
        trail = if (showPath && b?.program?.isNotEmpty() == true) {
            Curriculum.Sim.run(b, b.program).path
        } else emptyList()
        invalidate()
    }

    fun select(cell: Pair<Int, Int>?) { selected = cell; verdict = null; invalidate() }

    fun showVerdict(cell: Pair<Int, Int>, correct: Boolean) {
        selected = cell
        verdict = if (correct) Ink.good else Ink.bad
        invalidate()
    }

    fun clearVerdict() { verdict = null; invalidate() }

    /** Put Nupo back on the start tile without animating. */
    fun rewind() {
        animator?.cancel()
        val b = board ?: return
        botX = b.start.first.toFloat(); botY = b.start.second.toFloat()
        botSquash = 0f; botShake = 0f; trail = emptyList()
        invalidate()
    }

    // -------------------------------------------------------------- animation

    /**
     * Walks [program] one block at a time, calling [onStep] with the index of the
     * block currently running so the caller can highlight it, then [onDone].
     *
     * A blocked move plays as a bump: Nupo leans into the wall, squashes and
     * springs back, and the program carries on — matching the simulator, which
     * skips the move rather than aborting.
     */
    fun play(
        program: List<String>,
        onStep: (Int) -> Unit = {},
        onDone: (Curriculum.Sim.Result) -> Unit = {},
    ) {
        val b = board ?: return
        animator?.cancel()
        val result = Curriculum.Sim.run(b, program)
        rewind()
        trail = listOf(b.start)

        // Loops are unrolled before animating: a "do 3 times" row lights up
        // three separate times, which is exactly what makes a loop legible.
        val moves = result.moves
        val origin = result.origin

        val stepMs = if (reducedMotion) 0L else 280L
        fun step(i: Int) {
            if (i >= moves.size) {
                postDelayed({ onDone(result) }, if (reducedMotion) 0 else 260)
                return
            }
            onStep(origin.getOrElse(i) { i })
            // Defensive: a crash inside the overlay takes the whole gate down
            // and leaves the child with no way forward, so never index blind.
            val from = result.path.getOrElse(i) { botX.toInt() to botY.toInt() }
            val to = result.path.getOrElse(i + 1) { from }
            val blocked = from == to && moves[i] in MOVES

            if (reducedMotion) {
                botX = to.first.toFloat(); botY = to.second.toFloat()
                trail = trail + to
                invalidate()
                post { step(i + 1) }
                return
            }

            animator = ValueAnimator.ofFloat(0f, 1f).apply {
                duration = stepMs
                interpolator = DecelerateInterpolator(1.4f)
                addUpdateListener { a ->
                    val t = a.animatedValue as Float
                    if (blocked) {
                        // Lean a fifth of a tile into the wall and bounce back.
                        val lean = if (t < 0.5f) t * 2f else (1f - t) * 2f
                        val d = DELTA[moves[i]] ?: (0 to 0)
                        botX = from.first + d.first * lean * 0.2f
                        botY = from.second + d.second * lean * 0.2f
                        botSquash = lean
                        botShake = if (t > 0.5f) (1f - t) * 2f else 0f
                    } else {
                        botX = from.first + (to.first - from.first) * t
                        botY = from.second + (to.second - from.second) * t
                        botSquash = if (t < 0.25f) t * 1.2f else 0f
                    }
                    invalidate()
                }
                addListener(object : android.animation.AnimatorListenerAdapter() {
                    override fun onAnimationEnd(a: android.animation.Animator) {
                        botSquash = 0f; botShake = 0f
                        if (!blocked) trail = trail + to
                        invalidate()
                        postDelayed({ step(i + 1) }, 60)
                    }
                })
                start()
            }
        }
        postDelayed({ step(0) }, 220)
    }

    fun stop() { animator?.cancel(); animator = null }

    // ----------------------------------------------------------------- layout

    private var cell = 0f
    private var ox = 0f
    private var oy = 0f

    override fun onDraw(canvas: Canvas) {
        val b = board ?: return
        val pad = context.dpf(6f)
        cell = min((width - pad * 2) / b.w, (height - pad * 2) / b.h)
        ox = (width - cell * b.w) / 2f
        oy = (height - cell * b.h) / 2f

        drawTiles(canvas, b)
        drawTrail(canvas, b)
        drawPieces(canvas, b)
        drawBot(canvas, b)
    }

    /**
     * Screen point of tile (x,y), for the on-device test driver.
     *
     * The driver cannot read a Canvas, so the view reports where its own cells
     * landed rather than having the test guess from pixels.
     */
    fun cellOnScreen(cx: Int, cy: Int): IntArray {
        val b = board ?: return intArrayOf(-1, -1)
        val loc = IntArray(2); getLocationOnScreen(loc)
        val pad = context.dpf(6f)
        val c = minOf((width - pad * 2) / b.w, (height - pad * 2) / b.h)
        val x0 = (width - c * b.w) / 2f
        val y0 = (height - c * b.h) / 2f
        return intArrayOf(
            (loc[0] + x0 + (cx + 0.5f) * c).toInt(),
            (loc[1] + y0 + (b.h - 1 - cy + 0.5f) * c).toInt())
    }

    /** Screen rect of tile (x,y), y counting up from the bottom row. */
    private fun tile(b: Curriculum.Board, x: Float, y: Float, inset: Float = 0f): RectF {
        val left = ox + x * cell
        val top = oy + (b.h - 1 - y) * cell
        r.set(left + inset, top + inset, left + cell - inset, top + cell - inset)
        return r
    }

    private fun drawTiles(canvas: Canvas, b: Curriculum.Board) {
        val inset = context.dpf(2f)
        val rad = context.dpf(8f)
        for (y in 0 until b.h) for (x in 0 until b.w) {
            val c = x to y
            if (b.walls.contains(c)) continue
            fill.color = if ((x + y) % 2 == 0) Ink.tile else Ink.tileAlt
            canvas.drawRoundRect(tile(b, x.toFloat(), y.toFloat(), inset), rad, rad, fill)

            if (selected == c) {
                val col = verdict ?: Ink.primary
                fill.color = (col and 0x00FFFFFF) or 0x33000000
                canvas.drawRoundRect(tile(b, x.toFloat(), y.toFloat(), inset), rad, rad, fill)
                stroke.color = col
                stroke.strokeWidth = context.dpf(3f)
                canvas.drawRoundRect(tile(b, x.toFloat(), y.toFloat(), inset), rad, rad, stroke)
            }
        }
        // Walls last so their raised lip overlaps the tile below.
        for (c in b.walls) drawWall(canvas, b, c)
    }

    private fun drawWall(canvas: Canvas, b: Curriculum.Board, c: Pair<Int, Int>) {
        val inset = context.dpf(2f)
        val rad = context.dpf(8f)
        val lip = cell * 0.16f
        fill.color = Ink.wall
        canvas.drawRoundRect(tile(b, c.first.toFloat(), c.second.toFloat(), inset), rad, rad, fill)
        val body = RectF(r)
        fill.color = Ink.wallTop
        r.set(body.left, body.top, body.right, body.bottom - lip)
        canvas.drawRoundRect(r, rad, rad, fill)
    }

    private fun drawTrail(canvas: Canvas, b: Curriculum.Board) {
        if (trail.size < 2) return
        path.reset()
        trail.forEachIndexed { i, c ->
            val t = tile(b, c.first.toFloat(), c.second.toFloat())
            if (i == 0) path.moveTo(t.centerX(), t.centerY())
            else path.lineTo(t.centerX(), t.centerY())
        }
        dots.strokeWidth = context.dpf(4f)
        dots.pathEffect = DashPathEffect(
            floatArrayOf(context.dpf(2f), context.dpf(9f)), 0f
        )
        canvas.drawPath(path, dots)
    }

    private fun drawPieces(canvas: Canvas, b: Curriculum.Board) {
        b.stars.forEach { drawStar(canvas, tile(b, it.first.toFloat(), it.second.toFloat())) }
        b.key?.let { drawKey(canvas, tile(b, it.first.toFloat(), it.second.toFloat())) }
        b.door?.let { drawDoor(canvas, tile(b, it.first.toFloat(), it.second.toFloat())) }
        b.goal?.let { drawFlag(canvas, tile(b, it.first.toFloat(), it.second.toFloat())) }
    }

    private fun drawStar(canvas: Canvas, t: RectF) {
        val cx = t.centerX(); val cy = t.centerY(); val rad = t.width() * 0.28f
        path.reset()
        for (i in 0 until 10) {
            val rr = if (i % 2 == 0) rad else rad * 0.45f
            val a = Math.toRadians(-90.0 + i * 36.0)
            val px = cx + (rr * Math.cos(a)).toFloat()
            val py = cy + (rr * Math.sin(a)).toFloat()
            if (i == 0) path.moveTo(px, py) else path.lineTo(px, py)
        }
        path.close()
        fill.color = Ink.accent
        canvas.drawPath(path, fill)
        stroke.color = Ink.accentLedge
        stroke.strokeWidth = context.dpf(2f)
        canvas.drawPath(path, stroke)
    }

    private fun drawFlag(canvas: Canvas, t: RectF) {
        val poleX = t.centerX() - t.width() * 0.16f
        val top = t.centerY() - t.height() * 0.28f
        val bottom = t.centerY() + t.height() * 0.3f
        stroke.color = Ink.muted
        stroke.strokeWidth = context.dpf(3f)
        stroke.strokeCap = Paint.Cap.ROUND
        canvas.drawLine(poleX, top, poleX, bottom, stroke)
        path.reset()
        path.moveTo(poleX, top)
        path.lineTo(poleX + t.width() * 0.34f, top + t.height() * 0.11f)
        path.lineTo(poleX, top + t.height() * 0.22f)
        path.close()
        fill.color = Ink.good
        canvas.drawPath(path, fill)
    }

    private fun drawKey(canvas: Canvas, t: RectF) {
        val cx = t.centerX() - t.width() * 0.14f
        val cy = t.centerY()
        val rad = t.width() * 0.13f
        stroke.color = Ink.accentLedge
        stroke.strokeWidth = context.dpf(3.5f)
        stroke.strokeCap = Paint.Cap.ROUND
        canvas.drawCircle(cx, cy, rad, stroke)
        canvas.drawLine(cx + rad, cy, cx + t.width() * 0.36f, cy, stroke)
        canvas.drawLine(cx + t.width() * 0.3f, cy, cx + t.width() * 0.3f, cy + rad * 0.8f, stroke)
    }

    private fun drawDoor(canvas: Canvas, t: RectF) {
        val w = t.width() * 0.46f
        val h = t.height() * 0.62f
        r.set(t.centerX() - w / 2, t.centerY() - h / 2, t.centerX() + w / 2, t.centerY() + h / 2)
        fill.color = 0xFFC59A6B.toInt()
        canvas.drawRoundRect(r, w * 0.3f, w * 0.3f, fill)
        stroke.color = 0xFF9A7448.toInt()
        stroke.strokeWidth = context.dpf(2f)
        canvas.drawRoundRect(r, w * 0.3f, w * 0.3f, stroke)
        fill.color = Ink.accent
        canvas.drawCircle(r.right - w * 0.22f, r.centerY(), context.dpf(3f), fill)
    }

    private fun drawBot(canvas: Canvas, b: Curriculum.Board) {
        val t = tile(b, botX, botY)
        // A bump squashes him: shorter and wider, pivoting on his feet.
        val sy = 1f - botSquash * 0.22f
        val sx = 1f + botSquash * 0.22f
        val size = t.width() * 0.66f
        val shake = botShake * context.dpf(3f)
        val cx = t.centerX() + shake
        val feet = t.centerY() + size / 2f
        r.set(
            cx - size * sx / 2f, feet - size * sy,
            cx + size * sx / 2f, feet,
        )
        // Shadow keeps him planted on the tile rather than floating over it.
        fill.color = 0x22000000
        canvas.drawOval(
            cx - size * 0.34f, t.bottom - context.dpf(9f),
            cx + size * 0.34f, t.bottom - context.dpf(3f), fill
        )
        val bmp = nupo
        if (bmp != null) {
            src.set(0, 0, bmp.width, bmp.height)
            // Fit the sprite inside the box at its own aspect ratio, standing on
            // the same baseline, so a squash animation stretches it rather than
            // the artwork being permanently distorted.
            val ar = bmp.width.toFloat() / bmp.height
            val boxAr = r.width() / r.height()
            val dst = RectF(r)
            if (ar > boxAr) {
                val h = r.width() / ar
                dst.top = r.bottom - h
            } else {
                val w = r.height() * ar
                dst.left = r.centerX() - w / 2
                dst.right = r.centerX() + w / 2
            }
            canvas.drawBitmap(bmp, src, dst, null)
        } else {
            fill.color = Ink.primary
            canvas.drawRoundRect(r, size * 0.3f, size * 0.3f, fill)
            fill.color = Color.WHITE
            canvas.drawCircle(r.centerX() - size * 0.16f, r.centerY(), size * 0.09f, fill)
            canvas.drawCircle(r.centerX() + size * 0.16f, r.centerY(), size * 0.09f, fill)
        }
    }

    // ------------------------------------------------------------------ input

    override fun onTouchEvent(e: MotionEvent): Boolean {
        val b = board ?: return false
        if (mode != Mode.PICK_CELL) return false
        if (e.action != MotionEvent.ACTION_UP) return true
        val col = ((e.x - ox) / cell).toInt()
        val row = ((e.y - oy) / cell).toInt()
        val y = b.h - 1 - row
        if (col !in 0 until b.w || y !in 0 until b.h) return true
        if (b.walls.contains(col to y)) return true
        performClick()
        select(col to y)
        onCellTap?.invoke(col, y)
        return true
    }

    override fun performClick(): Boolean = super.performClick()

    companion object {
        private val MOVES = setOf("up", "down", "left", "right")
        private val DELTA = mapOf(
            "up" to (0 to 1), "down" to (0 to -1),
            "left" to (-1 to 0), "right" to (1 to 0),
        )
    }
}
