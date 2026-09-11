package com.brainpass.brainpass

import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.PointF

/**
 * The little drawn shapes everything visual is built from.
 *
 * A five year old counting plain grey dots is doing an exercise; the same child
 * counting stars and hearts is playing. The shapes are drawn as paths rather
 * than emoji so they stay crisp at any size, take the app's own colours, and
 * look like one family instead of a ransom note of borrowed art.
 *
 * Every glyph is drawn inside a unit box centred on (cx, cy) with radius r, so
 * any of them can stand in for any other without the layout shifting.
 */
object Glyphs {

    const val CIRCLE = "circle"
    const val SQUARE = "square"
    const val TRIANGLE = "triangle"
    const val STAR = "star"
    const val HEART = "heart"
    const val DIAMOND = "diamond"
    const val HEXAGON = "hexagon"
    const val FLOWER = "flower"
    const val RECTANGLE = "rectangle"

    val COUNTABLE = listOf(STAR, HEART, CIRCLE, FLOWER, HEXAGON)
    val PLAIN = listOf(CIRCLE, SQUARE, TRIANGLE, DIAMOND, HEXAGON, STAR,
                       RECTANGLE)

    private val path = Path()

    /**
     * Draws [kind] with a soft ledge underneath, the same trick the buttons and
     * the board pieces use — it is what stops a flat colour looking like a
     * placeholder.
     */
    fun draw(
        c: Canvas, kind: String, cx: Float, cy: Float, r: Float,
        face: Int, ledge: Int?, p: Paint, rotation: Float = 0f,
    ) {
        if (ledge != null) {
            p.color = ledge
            shape(c, kind, cx, cy + r * 0.13f, r, p, rotation)
        }
        p.color = face
        shape(c, kind, cx, cy, r, p, rotation)
    }

    private fun shape(
        c: Canvas, kind: String, cx: Float, cy: Float, r: Float, p: Paint, rot: Float,
    ) {
        p.style = Paint.Style.FILL
        if (rot != 0f) {
            c.save()
            c.rotate(rot, cx, cy)
        }
        when (kind) {
            CIRCLE -> c.drawCircle(cx, cy, r, p)
            SQUARE -> {
                val q = r * 0.9f
                c.drawRoundRect(cx - q, cy - q, cx + q, cy + q, r * 0.26f, r * 0.26f, p)
            }
            // A rectangle has to look unmistakably unlike a square, or the
            // shape it is teaching is the one thing it fails to show.
            RECTANGLE -> {
                val hw = r * 1.15f
                val hh = r * 0.66f
                c.drawRoundRect(cx - hw, cy - hh, cx + hw, cy + hh,
                    r * 0.2f, r * 0.2f, p)
            }
            TRIANGLE -> polygon(c, cx, cy, r, 3, -90f, p)
            DIAMOND -> polygon(c, cx, cy, r, 4, -90f, p)
            HEXAGON -> polygon(c, cx, cy, r, 6, -90f, p)
            STAR -> star(c, cx, cy, r, p)
            HEART -> heart(c, cx, cy, r, p)
            FLOWER -> flower(c, cx, cy, r, p)
            else -> c.drawCircle(cx, cy, r, p)
        }
        if (rot != 0f) c.restore()
    }

    /** Regular polygon, corners rounded a little so nothing is sharp to a child. */
    fun polygon(c: Canvas, cx: Float, cy: Float, r: Float, n: Int, startDeg: Float, p: Paint) {
        path.reset()
        for (i in 0 until n) {
            val a = Math.toRadians((startDeg + i * 360f / n).toDouble())
            val x = cx + r * Math.cos(a).toFloat()
            val y = cy + r * Math.sin(a).toFloat()
            if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }
        path.close()
        c.drawPath(path, p)
    }

    private fun star(c: Canvas, cx: Float, cy: Float, r: Float, p: Paint) {
        path.reset()
        val inner = r * 0.46f
        for (i in 0 until 10) {
            val rad = if (i % 2 == 0) r else inner
            val a = Math.toRadians((-90f + i * 36f).toDouble())
            val x = cx + rad * Math.cos(a).toFloat()
            val y = cy + rad * Math.sin(a).toFloat()
            if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }
        path.close()
        c.drawPath(path, p)
    }

    private fun heart(c: Canvas, cx: Float, cy: Float, r: Float, p: Paint) {
        path.reset()
        val top = cy - r * 0.42f
        path.moveTo(cx, cy + r * 0.78f)
        path.cubicTo(cx - r * 1.35f, cy - r * 0.15f, cx - r * 0.62f, top - r * 0.62f, cx, top)
        path.cubicTo(cx + r * 0.62f, top - r * 0.62f, cx + r * 1.35f, cy - r * 0.15f,
            cx, cy + r * 0.78f)
        path.close()
        c.drawPath(path, p)
    }

    private fun flower(c: Canvas, cx: Float, cy: Float, r: Float, p: Paint) {
        for (i in 0 until 6) {
            val a = Math.toRadians((i * 60f).toDouble())
            c.drawCircle(cx + r * 0.55f * Math.cos(a).toFloat(),
                cy + r * 0.55f * Math.sin(a).toFloat(), r * 0.45f, p)
        }
        c.drawCircle(cx, cy, r * 0.42f, p)
    }

    /** The corner points of [kind], for hit-testing a tap inside it. */
    fun corners(kind: String, cx: Float, cy: Float, r: Float): List<PointF> {
        val n = when (kind) {
            TRIANGLE -> 3
            SQUARE, DIAMOND, RECTANGLE -> 4
            HEXAGON -> 6
            else -> 0
        }
        if (n == 0) return emptyList()
        return (0 until n).map {
            val a = Math.toRadians((-90f + it * 360f / n).toDouble())
            PointF(cx + r * Math.cos(a).toFloat(), cy + r * Math.sin(a).toFloat())
        }
    }

    /** True when (x, y) falls inside the polygon [pts]. Ray casting. */
    fun inside(pts: List<PointF>, x: Float, y: Float): Boolean {
        var hit = false
        var j = pts.size - 1
        for (i in pts.indices) {
            val a = pts[i]
            val b = pts[j]
            if ((a.y > y) != (b.y > y) &&
                x < (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x
            ) hit = !hit
            j = i
        }
        return hit
    }
}
