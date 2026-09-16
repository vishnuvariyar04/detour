package com.brainpass.brainpass

import android.content.Context
import android.graphics.Canvas
import android.graphics.DashPathEffect
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.view.View
import kotlin.math.abs
import kotlin.math.cos
import kotlin.math.hypot
import kotlin.math.min
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * The visual vocabulary for Reasoning, the skill for ages 11-12.
 *
 * The younger skills can say everything flat. This one cannot: "which net folds
 * into this cube", "what shape is the cut", "is that the same solid turned" and
 * "what do you see from the right" are all questions about a thing in space,
 * and a child cannot reason about a solid they cannot see. So this file draws
 * in three dimensions — one isometric projection, used by every solid here so
 * they are all seen from the same place and can be compared.
 *
 * As with band b, these are ports of the review wall the questions were signed
 * off against (tools/curriculum/wall_template.html), and the solids are the
 * same solids rs_grade.py cuts: a unit cube, a 2x1x1 cuboid, prisms standing on
 * a triangle or a hexagon of radius 0.5, a square pyramid with its tip at
 * height 1, and a cylinder, cone and sphere of radius 0.5.
 */

/** The isometric view everything solid is drawn in. */
class Iso(private val ox: Float, private val oy: Float, private val s: Float) {
    private val a = s * 0.866f
    private val b = s * 0.5f
    fun x(X: Float, Y: Float) = ox + (X - Y) * a
    fun y(X: Float, Y: Float, Z: Float) = oy + (X + Y) * b - Z * s
    fun x(X: Int, Y: Int) = x(X.toFloat(), Y.toFloat())
    fun y(X: Int, Y: Int, Z: Int) = y(X.toFloat(), Y.toFloat(), Z.toFloat())
    val half get() = a
    val halfV get() = b
    val unit get() = s
}

/** Solids, cuts and the little drawings that go with them. */
object Solid {

    // The three face tints. Top lightest, front mid, right darkest: one light
    // source, so a stack of cubes reads as a stack and not as a flat mosaic.
    const val TOP = 0xFFEFE9FF.toInt()
    const val FRONT = 0xFFC9B6F8.toInt()
    const val RIGHT = 0xFF9F82EE.toInt()

    fun poly(
        c: Canvas, p: Paint, pts: List<Pair<Float, Float>>,
        fill: Int?, stroke: Int?, strokeWidth: Float = 1f,
    ) {
        if (pts.isEmpty()) return
        val path = Path()
        path.moveTo(pts[0].first, pts[0].second)
        for (i in 1 until pts.size) path.lineTo(pts[i].first, pts[i].second)
        path.close()
        if (fill != null) { p.style = Paint.Style.FILL; p.color = fill; c.drawPath(path, p) }
        if (stroke != null) {
            p.style = Paint.Style.STROKE; p.strokeWidth = strokeWidth; p.color = stroke
            c.drawPath(path, p)
            p.style = Paint.Style.FILL
        }
    }

    /** The screen box a set of little cubes will occupy, in isometric units. */
    private fun voxelBounds(cubes: List<Triple<Int, Int, Int>>): FloatArray {
        var minU = Float.MAX_VALUE; var minV = Float.MAX_VALUE
        var maxU = -Float.MAX_VALUE; var maxV = -Float.MAX_VALUE
        for (q in cubes) for (dx in 0..1) for (dy in 0..1) for (dz in 0..1) {
            val X = (q.first + dx).toFloat()
            val Y = (q.second + dy).toFloat()
            val Z = (q.third + dz).toFloat()
            val u = (X - Y) * 0.866f
            val v = (X + Y) * 0.5f - Z
            if (u < minU) minU = u; if (u > maxU) maxU = u
            if (v < minV) minV = v; if (v > maxV) maxV = v
        }
        return floatArrayOf(minU, minV, maxU, maxV)
    }

    /**
     * A shape made of unit cubes.
     *
     * Only the faces with nothing in front of them are drawn. Without that a
     * cube buried inside the shape paints its faces over its neighbours and the
     * solid comes out looking like a different solid — which, in a question
     * asking whether two solids are the same, is the whole answer.
     */
    fun voxels(
        c: Canvas, p: Paint, cubes: List<Triple<Int, Int, Int>>,
        x: Float, y: Float, w: Float, h: Float, maxUnit: Float,
    ) {
        if (cubes.isEmpty()) return
        val bb = voxelBounds(cubes)
        val spanU = (bb[2] - bb[0]).coerceAtLeast(0.001f)
        val spanV = (bb[3] - bb[1]).coerceAtLeast(0.001f)
        val s = minOf(w / spanU, h / spanV, maxUnit)
        val iso = Iso(x + (w - spanU * s) / 2f - bb[0] * s,
            y + (h - spanV * s) / 2f - bb[1] * s, s)
        val occupied = cubes.toHashSet()
        for (q in cubes.sortedBy { it.first + it.second + it.third }) {
            val (X, Y, Z) = q
            fun pt(dx: Int, dy: Int, dz: Int) =
                iso.x(X + dx, Y + dy) to iso.y(X + dx, Y + dy, Z + dz)
            if (Triple(X, Y, Z + 1) !in occupied) poly(c, p,
                listOf(pt(0, 0, 1), pt(1, 0, 1), pt(1, 1, 1), pt(0, 1, 1)),
                TOP, Ink.primaryLedge, 1.2f)
            if (Triple(X, Y + 1, Z) !in occupied) poly(c, p,
                listOf(pt(0, 1, 0), pt(1, 1, 0), pt(1, 1, 1), pt(0, 1, 1)),
                FRONT, Ink.primaryLedge, 1.2f)
            if (Triple(X + 1, Y, Z) !in occupied) poly(c, p,
                listOf(pt(1, 0, 0), pt(1, 1, 0), pt(1, 1, 1), pt(1, 0, 1)),
                RIGHT, Ink.primaryLedge, 1.2f)
        }
    }

    /** The faces of a solid, as corner lists. Null for the round ones. */
    fun mesh(kind: String): List<List<FloatArray>>? {
        fun box(W: Float): List<List<FloatArray>> {
            val v = listOf(
                floatArrayOf(0f, 0f, 0f), floatArrayOf(W, 0f, 0f),
                floatArrayOf(W, 1f, 0f), floatArrayOf(0f, 1f, 0f),
                floatArrayOf(0f, 0f, 1f), floatArrayOf(W, 0f, 1f),
                floatArrayOf(W, 1f, 1f), floatArrayOf(0f, 1f, 1f))
            return listOf(
                listOf(v[0], v[1], v[2], v[3]), listOf(v[4], v[5], v[6], v[7]),
                listOf(v[0], v[1], v[5], v[4]), listOf(v[1], v[2], v[6], v[5]),
                listOf(v[2], v[3], v[7], v[6]), listOf(v[3], v[0], v[4], v[7]))
        }
        fun prism(base: List<FloatArray>): List<List<FloatArray>> {
            val lo = base.map { floatArrayOf(it[0], it[1], 0f) }
            val hi = base.map { floatArrayOf(it[0], it[1], 1f) }
            val f = mutableListOf(lo.reversed(), hi)
            for (i in base.indices) {
                val j = (i + 1) % base.size
                f.add(listOf(lo[i], lo[j], hi[j], hi[i]))
            }
            return f
        }
        return when (kind) {
            "cube" -> box(1f)
            "cuboid" -> box(2f)
            "triprism" -> prism(listOf(
                floatArrayOf(0f, 0f), floatArrayOf(1f, 0f), floatArrayOf(0.5f, 0.866f)))
            "hexprism" -> prism((0 until 6).map {
                val t = it * Math.PI / 3
                floatArrayOf(0.5f + 0.5f * cos(t).toFloat(), 0.5f + 0.5f * sin(t).toFloat())
            })
            "pyramid" -> {
                val t = floatArrayOf(0.5f, 0.5f, 1f)
                val v = listOf(
                    floatArrayOf(0f, 0f, 0f), floatArrayOf(1f, 0f, 0f),
                    floatArrayOf(1f, 1f, 0f), floatArrayOf(0f, 1f, 0f))
                listOf(listOf(v[3], v[2], v[1], v[0]), listOf(v[0], v[1], t),
                    listOf(v[1], v[2], t), listOf(v[2], v[3], t), listOf(v[3], v[0], t))
            }
            else -> null
        }
    }

    /**
     * A solid with the cutting plane through it.
     *
     * The plane is drawn as a plain square sheet centred on the solid. It used
     * to be the plane clipped to a box around the solid, and that outline IS
     * the answer: the question asking what shape a corner-to-corner cut of a
     * cube makes drew a yellow hexagon over the cube.
     */
    fun solidCut(
        c: Canvas, p: Paint, pic: Curriculum.Pic,
        x: Float, y: Float, w: Float, h: Float,
    ) {
        val W = if (pic.solid == "cuboid") 2f else 1f
        val m = 0.22f
        var minU = Float.MAX_VALUE; var minV = Float.MAX_VALUE
        var maxU = -Float.MAX_VALUE; var maxV = -Float.MAX_VALUE
        for (i in 0 until 8) {
            val X = if (i and 1 != 0) W + m else -m
            val Y = if (i and 2 != 0) 1f + m else -m
            val Z = if (i and 4 != 0) 1f + m else -m
            val u = (X - Y) * 0.866f
            val v = (X + Y) * 0.5f - Z
            if (u < minU) minU = u; if (u > maxU) maxU = u
            if (v < minV) minV = v; if (v > maxV) maxV = v
        }
        val s = min(w / (maxU - minU), h / (maxV - minV))
        val iso = Iso(x + (w - (maxU - minU) * s) / 2f - minU * s,
            y + (h - (maxV - minV) * s) / 2f - minV * s, s)
        fun proj(q: FloatArray) = iso.x(q[0], q[1]) to iso.y(q[0], q[1], q[2])
        val mesh = mesh(pic.solid)
        val centre = floatArrayOf(W / 2f, 0.5f, 0.5f)

        /** Every face turned towards the viewer, optionally filled. */
        fun faces(filled: Boolean) {
            for (f in mesh!!) {
                val e1 = floatArrayOf(f[1][0] - f[0][0], f[1][1] - f[0][1], f[1][2] - f[0][2])
                val e2 = floatArrayOf(f[2][0] - f[0][0], f[2][1] - f[0][1], f[2][2] - f[0][2])
                var n = floatArrayOf(
                    e1[1] * e2[2] - e1[2] * e2[1],
                    e1[2] * e2[0] - e1[0] * e2[2],
                    e1[0] * e2[1] - e1[1] * e2[0])
                val fc = FloatArray(3) { k -> f.sumOf { it[k].toDouble() }.toFloat() / f.size }
                if (n[0] * (fc[0] - centre[0]) + n[1] * (fc[1] - centre[1]) +
                    n[2] * (fc[2] - centre[2]) < 0
                ) n = floatArrayOf(-n[0], -n[1], -n[2])
                // In this projection a face is visible exactly when its outward
                // normal leans towards the viewer, which is x + y + z > 0.
                if (n[0] + n[1] + n[2] <= 1e-9f) continue
                val len = hypot(hypot(n[0], n[1]), n[2])
                val up = n[2] / len
                val tint = if (up > 0.5f) TOP else if (n[0] > n[1]) RIGHT else FRONT
                poly(c, p, f.map { proj(it) }, if (filled) tint else null,
                    Ink.primaryLedge, 1.3f)
            }
        }

        val rx = sqrt(2f) * 0.5f * iso.half
        val ry = sqrt(2f) * 0.5f * iso.halfV

        /** The round solids, which have no flat faces to sort. */
        fun round(filled: Boolean) {
            val bcx = iso.x(0.5f, 0.5f); val bcy = iso.y(0.5f, 0.5f, 0f)
            val tcx = iso.x(0.5f, 0.5f); val tcy = iso.y(0.5f, 0.5f, 1f)
            if (pic.solid == "sphere") {
                val ccx = iso.x(0.5f, 0.5f); val ccy = iso.y(0.5f, 0.5f, 0.5f)
                val r = 0.5f * iso.unit * 1.2247f
                if (filled) {
                    p.style = Paint.Style.FILL
                    p.shader = RadialGradient(ccx - r * 0.35f, ccy - r * 0.35f, r,
                        0xFFF3EEFF.toInt(), 0xFFA98BF0.toInt(), Shader.TileMode.CLAMP)
                    c.drawCircle(ccx, ccy, r, p)
                    p.shader = null
                }
                p.style = Paint.Style.STROKE; p.strokeWidth = 1.3f; p.color = Ink.primaryLedge
                c.drawCircle(ccx, ccy, r, p)
                if (filled) {
                    // The equator, so the ball reads as a ball and not a disc.
                    p.pathEffect = DashPathEffect(floatArrayOf(4f, 4f), 0f)
                    c.drawOval(RectF(ccx - rx, ccy - ry, ccx + rx, ccy + ry), p)
                    p.pathEffect = null
                }
                p.style = Paint.Style.FILL
                return
            }
            val body = Path()
            body.moveTo(bcx - rx, bcy)
            if (pic.solid == "cylinder") {
                body.lineTo(tcx - rx, tcy); body.lineTo(tcx + rx, tcy)
            } else {
                body.lineTo(tcx, tcy)
            }
            body.lineTo(bcx + rx, bcy)
            body.arcTo(RectF(bcx - rx, bcy - ry, bcx + rx, bcy + ry), 0f, 180f)
            body.close()
            if (filled) { p.style = Paint.Style.FILL; p.color = FRONT; c.drawPath(body, p) }
            p.style = Paint.Style.STROKE; p.strokeWidth = 1.3f; p.color = Ink.primaryLedge
            c.drawPath(body, p)
            if (pic.solid == "cylinder") {
                val lid = RectF(tcx - rx, tcy - ry, tcx + rx, tcy + ry)
                if (filled) { p.style = Paint.Style.FILL; p.color = TOP; c.drawOval(lid, p) }
                p.style = Paint.Style.STROKE; p.color = Ink.primaryLedge
                c.drawOval(lid, p)
            }
            p.style = Paint.Style.FILL
        }

        if (mesh != null) faces(true) else round(true)

        // ---- the cutting plane
        val nm = pic.normal
        if (nm.size >= 3 && pic.point.size >= 3) {
            val len = hypot(hypot(nm[0], nm[1]), nm[2]).coerceAtLeast(1e-6f)
            val N = floatArrayOf(nm[0] / len, nm[1] / len, nm[2] / len)
            val off = (centre[0] - pic.point[0]) * N[0] +
                (centre[1] - pic.point[1]) * N[1] + (centre[2] - pic.point[2]) * N[2]
            val cp = floatArrayOf(
                centre[0] - off * N[0], centre[1] - off * N[1], centre[2] - off * N[2])
            val U: FloatArray
            val V: FloatArray
            if (abs(N[2]) > 0.99f) {
                U = floatArrayOf(1f, 0f, 0f); V = floatArrayOf(0f, 1f, 0f)
            } else {
                val v0 = floatArrayOf(-N[2] * N[0], -N[2] * N[1], 1f - N[2] * N[2])
                val lv = hypot(hypot(v0[0], v0[1]), v0[2]).coerceAtLeast(1e-6f)
                V = floatArrayOf(v0[0] / lv, v0[1] / lv, v0[2] / lv)
                U = floatArrayOf(
                    V[1] * N[2] - V[2] * N[1],
                    V[2] * N[0] - V[0] * N[2],
                    V[0] * N[1] - V[1] * N[0])
            }
            val hs = 0.85f + 0.35f * (W - 1f)
            fun corner(a: Float, b: Float): Pair<Float, Float> {
                val q = floatArrayOf(
                    cp[0] + a * hs * U[0] + b * hs * V[0],
                    cp[1] + a * hs * U[1] + b * hs * V[1],
                    cp[2] + a * hs * U[2] + b * hs * V[2])
                return proj(q)
            }
            poly(c, p, listOf(corner(-1f, -1f), corner(1f, -1f), corner(1f, 1f), corner(-1f, 1f)),
                0x57FDC703, Ink.accentLedge, 1.6f)
        }

        // The solid's outline again over the sheet, so its shape stays readable
        // through the yellow.
        val saved = p.alpha
        p.alpha = 191
        if (mesh != null) faces(false) else round(false)
        p.alpha = saved
    }

    /**
     * The squares of a cube net.
     *
     * The square the question is about is washed yellow, so "the face opposite
     * the star" has a star the child can point at rather than one they have to
     * find first.
     */
    fun netCells(
        c: Canvas, p: Paint, fonts: Fonts, d: Float,
        cells: List<Pair<Int, Int>>, x: Float, y: Float, w: Float, h: Float,
        maxSize: Float, marks: List<String>, target: String, fill: Int?,
    ): Float {
        if (cells.isEmpty()) return 0f
        val cols = cells.maxOf { it.first } + 1
        val rows = cells.maxOf { it.second } + 1
        val size = minOf(maxSize, w / cols, h / rows)
        val ox = x + (w - cols * size) / 2f
        val oy = y + (h - rows * size) / 2f
        cells.forEachIndexed { i, q ->
            val bx = ox + q.first * size
            val by = oy + q.second * size
            val hit = marks.getOrNull(i) != null && marks[i] == target
            val face = if (hit) 0xFFFFF3C4.toInt() else (fill ?: Ink.surface)
            val r = RectF(bx + 1f * d, by + 1f * d, bx + size - 1f * d, by + size - 1f * d)
            p.style = Paint.Style.FILL; p.color = face
            c.drawRoundRect(r, 5f * d, 5f * d, p)
            p.style = Paint.Style.STROKE; p.strokeWidth = 1.5f * d; p.color = Ink.primary
            c.drawRoundRect(r, 5f * d, 5f * d, p)
            p.style = Paint.Style.FILL
            marks.getOrNull(i)?.let { mark ->
                Glyphs.draw(c, mark, bx + size / 2f, by + size / 2f, size * 0.27f,
                    Ink.primary, Ink.primaryLedge, p)
            }
        }
        return rows * size
    }

    /** A flat shape, for "what shape is the cut" answers. */
    fun flat(c: Canvas, p: Paint, name: String, cx: Float, cy: Float, r: Float) {
        val path = Path()
        when (name) {
            "circle" -> path.addCircle(cx, cy, r, Path.Direction.CW)
            "oval" -> path.addOval(
                RectF(cx - r * 1.35f, cy - r * 0.75f, cx + r * 1.35f, cy + r * 0.75f),
                Path.Direction.CW)
            "square" -> path.addRect(
                cx - r * 0.9f, cy - r * 0.9f, cx + r * 0.9f, cy + r * 0.9f, Path.Direction.CW)
            "rectangle" -> path.addRect(
                cx - r * 1.35f, cy - r * 0.72f, cx + r * 1.35f, cy + r * 0.72f, Path.Direction.CW)
            "triangle" -> {
                path.moveTo(cx, cy - r)
                path.lineTo(cx + r * 0.95f, cy + r * 0.7f)
                path.lineTo(cx - r * 0.95f, cy + r * 0.7f)
                path.close()
            }
            "hexagon" -> {
                for (i in 0 until 6) {
                    val t = i * Math.PI / 3
                    val px = cx + r * cos(t).toFloat()
                    val py = cy + r * sin(t).toFloat()
                    if (i == 0) path.moveTo(px, py) else path.lineTo(px, py)
                }
                path.close()
            }
            else -> return
        }
        p.style = Paint.Style.FILL; p.color = FRONT; c.drawPath(path, p)
        p.style = Paint.Style.STROKE; p.strokeWidth = 1.6f; p.color = Ink.primaryLedge
        c.drawPath(path, p)
        p.style = Paint.Style.FILL
    }
}

/**
 * A view that draws one Reasoning picture.
 *
 * Same arrangement as [PuzzlePicView]: none of these is tapped, all of them
 * size themselves from their content, so one view switches on the kind rather
 * than eighteen that would each repeat the wiring.
 */
class ReasonPicView(ctx: Context, private val fonts: Fonts) : NumberView(ctx) {

    var pic: Curriculum.Pic? = null
        set(v) { field = v; requestLayout(); invalidate() }

    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val d get() = context.dpf(1f)

    companion object {
        private val DRAWN = setOf(
            "sequence", "claim", "clues", "truth", "grid", "binary", "binaryAsk",
            "shift", "symbols", "letters", "mirrorAlpha", "example", "net",
            "roll", "stack", "polycube", "turnCube", "section",
        )

        /** Whether [pic] has a drawing. netPick and sectionWhich have none: for
         *  those the four ANSWERS are the picture, and drawing a fifth solid
         *  above them would be a thing to compare against that is not in play. */
        fun draws(pic: Curriculum.Pic?): Boolean = pic != null && pic.kind in DRAWN

        private const val ALPHA = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    }

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        val w = MeasureSpec.getSize(widthSpec)
        setMeasuredDimension(w, heightFor(w.toFloat()).toInt().coerceAtLeast(dp(40)))
    }

    private fun heightFor(w: Float): Float {
        val pic = pic ?: return 0f
        return when (pic.kind) {
            "sequence" ->
                if (pic.askPosition > 0 || pic.askValue != Int.MIN_VALUE) 102f * d else 64f * d
            "claim", "clues", "truth" -> Draw.clueCardHeight(p, fonts, d, pic.lines, w)
            "grid" -> Draw.clueCardHeight(p, fonts, d, pic.lines, w) +
                (if (pic.people.size == 3) 112f * d else 0f)
            "binary" -> 118f * d
            "binaryAsk" -> 150f * d
            "shift", "mirrorAlpha" -> 150f * d
            "symbols" -> {
                val rows = Math.ceil(pic.symKey.size / 5.0).toInt()
                (rows * 40f + 12f + 54f) * d
            }
            "letters" -> 70f * d
            "example" -> 112f * d
            "net" -> {
                val rows = (pic.netCells.maxOfOrNull { it.second } ?: 0) + 1
                val cols = (pic.netCells.maxOfOrNull { it.first } ?: 0) + 1
                val size = minOf(46f * d, w / cols, 150f * d / rows)
                rows * size + 8f * d
            }
            "roll" -> maxOf(pic.gridH * 38f * d, 104f * d) + 10f * d
            "stack" -> {
                val hs = pic.heights
                if (hs.isEmpty()) 0f else {
                    val top = hs.maxOf { r -> r.maxOrNull() ?: 0 }
                    ((hs[0].size + hs.size) * 12f + top * 24f + 30f) * d
                }
            }
            "polycube" -> 150f * d
            "turnCube" -> (132f + 22f * pic.stepLines.size) * d
            "section" -> 170f * d
            else -> 0f
        }
    }

    override fun onDraw(canvas: Canvas) {
        val pic = pic ?: return
        val w = width.toFloat()
        when (pic.kind) {
            "sequence" -> sequence(canvas, pic, w)
            "claim", "clues", "truth" -> Draw.clueCard(canvas, p, fonts, d, pic.lines, 0f, 0f, w)
            "grid" -> deduce(canvas, pic, w)
            "binary", "binaryAsk" -> bulbs(canvas, pic, w)
            "shift" -> shift(canvas, pic, w)
            "mirrorAlpha" -> mirrorAlpha(canvas, pic, w)
            "symbols" -> symbols(canvas, pic, w)
            "letters" -> letters(canvas, pic, w)
            "example" -> example(canvas, pic, w)
            "net" -> net(canvas, pic, w)
            "roll" -> roll(canvas, pic, w)
            "stack" -> stack(canvas, pic, w)
            "polycube" -> Solid.voxels(canvas, p, pic.cubes, w * 0.2f, 0f, w * 0.6f, 140f * d, 30f * d)
            "turnCube" -> turnCube(canvas, pic, w)
            "section" -> Solid.solidCut(canvas, p, pic, w * 0.15f, 0f, w * 0.7f, 160f * d)
        }
    }

    // ------------------------------------------------------------- sequences

    /** A run of numbers, with the gap, and which position is being asked. */
    private fun sequence(c: Canvas, pic: Curriculum.Pic, w: Float) {
        val t = pic.terms
        val n = t.size.coerceAtLeast(1); val gap = 6f * d
        val box = minOf(56f * d, (w - gap * (n - 1)) / n)
        val ox = (w - (box * n + gap * (n - 1))) / 2f
        val numbered = pic.askPosition > 0 || pic.askValue != Int.MIN_VALUE
        t.forEachIndexed { i, v ->
            val bx = ox + i * (box + gap)
            val hole = v == null
            Draw.rrect(c, p, bx, 4f * d, box, 44f * d, 12f * d, Ink.ledge)
            Draw.rrect(c, p, bx, 0f, box, 44f * d, 12f * d,
                if (hole) 0xFFF1ECFF.toInt() else Ink.surface,
                if (hole) Ink.primary else Ink.line, (if (hole) 2f else 1.5f) * d)
            val lab = v?.toString() ?: "?"
            val z = Draw.fitSize(p, fonts, lab, box - 6f * d, 20f * d, 11f * d)
            Draw.text(c, p, fonts, lab, bx + box / 2f, 22f * d, z,
                if (hole) Ink.primary else Ink.text, 900, Paint.Align.CENTER)
            // The positions are only labelled when the question is ABOUT a
            // position. Otherwise they are five more numbers to read past.
            if (numbered) {
                Draw.text(c, p, fonts, Draw.ordinal(i + 1), bx + box / 2f, 56f * d,
                    10f * d, Ink.muted, 700, Paint.Align.CENTER)
            }
        }
        if (pic.askPosition > 0) {
            Draw.text(c, p, fonts, "${Draw.ordinal(pic.askPosition)} number  =  ?",
                w / 2f, 84f * d, 18f * d, Ink.primary, 900, Paint.Align.CENTER)
        } else if (pic.askValue != Int.MIN_VALUE) {
            Draw.text(c, p, fonts, "?  position  =  ${pic.askValue}",
                w / 2f, 84f * d, 18f * d, Ink.primary, 900, Paint.Align.CENTER)
        }
    }

    /** The clues, and an empty grid to think on. */
    private fun deduce(c: Canvas, pic: Curriculum.Pic, w: Float) {
        val h = Draw.clueCard(c, p, fonts, d, pic.lines, 0f, 0f, w)
        if (pic.people.size != 3) return
        val gy = h + 10f * d
        val lw = 84f * d
        val cw = (w - lw) / 3f
        pic.things.forEachIndexed { i, t ->
            val label = "$t ${pic.noun}".trim()
            val z = Draw.fitSize(p, fonts, label, cw - 6f * d, 12f * d, 9f * d, 800)
            Draw.text(c, p, fonts, label, lw + i * cw + cw / 2f, gy + 12f * d, z,
                Ink.muted, 800, Paint.Align.CENTER)
        }
        pic.people.forEachIndexed { r, name ->
            val ry = gy + 24f * d + r * 26f * d
            Draw.text(c, p, fonts, name, 6f * d, ry + 13f * d, 13f * d, Ink.text, 800)
            for (i in 0 until 3) {
                Draw.rrect(c, p, lw + i * cw + 3f * d, ry + 2f * d, cw - 6f * d, 22f * d,
                    6f * d, Ink.surface, Ink.line, 1.2f * d)
            }
        }
    }

    // ---------------------------------------------------------------- binary

    /** A row of bulbs over their place values. */
    private fun bulbRow(
        c: Canvas, values: List<Int>, on: List<Boolean>?,
        x: Float, y: Float, w: Float, labels: Boolean,
    ) {
        val n = values.size.coerceAtLeast(1)
        val cell = w / n
        val r = minOf(cell * 0.3f, 20f * d)
        values.forEachIndexed { i, v ->
            val cx = x + i * cell + cell / 2f
            if (labels) {
                Draw.text(c, p, fonts, "$v", cx, y + 12f * d, 13f * d,
                    Ink.muted, 800, Paint.Align.CENTER)
            }
            val cy = y + if (labels) 44f * d else r + 4f * d
            val lit = on?.getOrNull(i) == true
            if (lit) {
                // A glow, so a lit bulb reads as lit at a glance and the child
                // is reading a number rather than counting outlines.
                p.style = Paint.Style.FILL; p.color = 0x47FDC703
                c.drawCircle(cx, cy, r + 6f * d, p)
            }
            p.style = Paint.Style.FILL
            p.color = if (lit) Ink.accent else 0xFFE4E6EF.toInt()
            c.drawCircle(cx, cy, r, p)
            p.style = Paint.Style.STROKE; p.strokeWidth = 1.5f * d
            p.color = if (lit) Ink.accentLedge else Ink.ledge
            c.drawCircle(cx, cy, r, p)
            p.style = Paint.Style.FILL
        }
    }

    private fun bulbs(c: Canvas, pic: Curriculum.Pic, w: Float) {
        if (pic.kind == "binaryAsk") {
            Draw.text(c, p, fonts, "${pic.targetNum}", w / 2f, 26f * d, 34f * d,
                Ink.primary, 900, Paint.Align.CENTER)
            bulbRow(c, pic.bulbValues, null, 0f, 62f * d, w, true)
            return
        }
        bulbRow(c, pic.bulbValues, pic.on, 0f, 0f, w, true)
        if (pic.askPlus) {
            Draw.text(c, p, fonts, "Now add one to this number", w / 2f, 96f * d,
                13f * d, Ink.muted, 700, Paint.Align.CENTER)
        }
    }

    // ----------------------------------------------------------------- codes

    /** The word or code being worked on, under an alphabet table. */
    private fun codeWord(c: Canvas, pic: Curriculum.Pic, w: Float, wy: Float) {
        val label = if (pic.mode == "encode") "Word" else "Code"
        val word = pic.word
        if (word.isEmpty()) return
        val lw = 38f * d; val gap = 6f * d
        val cellW = minOf(40f * d, (w - lw - gap * word.length) / word.length)
        Draw.text(c, p, fonts, label, 0f, wy + 20f * d, 13f * d, Ink.muted, 800)
        for (i in word.indices) {
            val bx = lw + i * (cellW + gap)
            Draw.rrect(c, p, bx, wy, cellW, 40f * d, 10f * d,
                if (pic.mode == "encode") Ink.surface else 0xFFF1ECFF.toInt(),
                Ink.primary, 1.5f * d)
            Draw.text(c, p, fonts, word[i].toString(), bx + cellW / 2f, wy + 20f * d, 20f * d,
                if (pic.mode == "encode") Ink.text else Ink.primary, 900, Paint.Align.CENTER)
        }
    }

    /** The whole alphabet with its shifted partner under each letter. */
    private fun shift(c: Canvas, pic: Curriculum.Pic, w: Float) {
        val bw = w / 13f
        for (i in 0 until 26) {
            val col = i % 13; val row = i / 13
            val bx = col * bw; val by = row * 46f * d
            Draw.rrect(c, p, bx + 1f * d, by, bw - 2f * d, 42f * d, 6f * d,
                Ink.surface, Ink.line, 1f * d)
            Draw.text(c, p, fonts, ALPHA[i].toString(), bx + bw / 2f, by + 12f * d,
                12f * d, Ink.text, 800, Paint.Align.CENTER)
            Draw.text(c, p, fonts, ALPHA[(i + pic.shift).mod(26)].toString(),
                bx + bw / 2f, by + 31f * d, 12f * d, Ink.primary, 900, Paint.Align.CENTER)
        }
        codeWord(c, pic, w, 100f * d)
    }

    /** The alphabet against itself back to front. */
    private fun mirrorAlpha(c: Canvas, pic: Curriculum.Pic, w: Float) {
        val bw = w / 13f
        for (i in 0 until 13) {
            val bx = i * bw
            Draw.rrect(c, p, bx + 1f * d, 0f, bw - 2f * d, 56f * d, 6f * d,
                Ink.surface, Ink.line, 1f * d)
            Draw.text(c, p, fonts, ALPHA[i].toString(), bx + bw / 2f, 15f * d,
                13f * d, Ink.text, 900, Paint.Align.CENTER)
            Draw.text(c, p, fonts, "↕", bx + bw / 2f, 29f * d,
                10f * d, Ink.muted, 900, Paint.Align.CENTER)
            Draw.text(c, p, fonts, ALPHA[25 - i].toString(), bx + bw / 2f, 43f * d,
                13f * d, Ink.primary, 900, Paint.Align.CENTER)
        }
        Draw.text(c, p, fonts, "Each letter swaps with the one below it.",
            w / 2f, 74f * d, 12f * d, Ink.muted, 700, Paint.Align.CENTER)
        codeWord(c, pic, w, 96f * d)
    }

    /** A key of symbols, then the word written in them. */
    private fun symbols(c: Canvas, pic: Curriculum.Pic, w: Float) {
        val per = 5
        val cw = w / per
        val rows = Math.ceil(pic.symKey.size / per.toDouble()).toInt()
        pic.symKey.forEachIndexed { i, k ->
            val cx = (i % per) * cw + cw / 2f
            val cy = 20f * d + (i / per) * 40f * d
            Glyphs.draw(c, k.glyph, cx - 14f * d, cy, 10f * d,
                colourOf(k.colour), ledgeOf(k.colour), p)
            Draw.text(c, p, fonts, "= ${k.letter}", cx + 12f * d, cy, 15f * d,
                Ink.text, 900, Paint.Align.CENTER)
        }
        val wy = rows * 40f * d + 12f * d
        val sz = 46f * d; val gap = 8f * d
        val word = pic.symWord
        if (word.isEmpty()) return
        val ox = (w - (word.size * sz + (word.size - 1) * gap)) / 2f
        word.forEachIndexed { i, g ->
            val bx = ox + i * (sz + gap)
            Draw.rrect(c, p, bx, wy, sz, sz, 12f * d, 0xFFF1ECFF.toInt(), Ink.primary, 1.5f * d)
            Glyphs.draw(c, g.glyph, bx + sz / 2f, wy + sz / 2f, 14f * d,
                colourOf(g.colour), ledgeOf(g.colour), p)
        }
    }

    private fun colourOf(k: String) = when (k) {
        "accent" -> Ink.accent; "good" -> Ink.good; else -> Ink.primary
    }

    private fun ledgeOf(k: String) = when (k) {
        "accent" -> Ink.accentLedge; "good" -> Ink.good; else -> Ink.primaryLedge
    }

    /** Numbers standing in for letters, e.g. 2 - 1 - 7. */
    private fun letters(c: Canvas, pic: Curriculum.Pic, w: Float) {
        val items = if (pic.codes.isNotEmpty()) pic.codes else pic.word.map { it.toString() }
        if (items.isEmpty()) return
        val sz = 48f * d
        val gap = (if (pic.codes.isNotEmpty()) 18f else 8f) * d
        val ox = (w - (items.size * sz + (items.size - 1) * gap)) / 2f
        items.forEachIndexed { i, v ->
            val bx = ox + i * (sz + gap)
            Draw.rrect(c, p, bx, 6f * d, sz, sz, 12f * d, Ink.surface, Ink.primary, 1.5f * d)
            Draw.text(c, p, fonts, v, bx + sz / 2f, 30f * d, 22f * d,
                Ink.text, 900, Paint.Align.CENTER)
            if (pic.codes.isNotEmpty() && i < items.size - 1) {
                Draw.text(c, p, fonts, "-", bx + sz + gap / 2f, 30f * d, 20f * d,
                    Ink.muted, 900, Paint.Align.CENTER)
            }
        }
    }

    /** One worked example of an unknown code, then the word to crack. */
    private fun example(c: Canvas, pic: Curriculum.Pic, w: Float) {
        if (pic.example.size < 2) return
        val cw = 30f * d; val px = 14f * d
        Draw.rrect(c, p, 0f, 0f, w, 104f * d, 16f * d,
            0xFFFFFCEF.toInt(), 0xFFF2E3B3.toInt(), 1.5f * d)
        Draw.text(c, p, fonts, "Example", 14f * d, 14f * d, 12f * d, Ink.muted, 800)
        val lw = Draw.letterRow(c, p, fonts, d, pic.example[0], px, 26f * d, cw,
            Ink.surface, Ink.text)
        Draw.text(c, p, fonts, "→", px + lw + 18f * d, 44f * d, 20f * d,
            Ink.muted, 900, Paint.Align.CENTER)
        Draw.letterRow(c, p, fonts, d, pic.example[1], px + lw + 36f * d, 26f * d, cw,
            0xFFF1ECFF.toInt(), Ink.primary)
        val qy = 66f * d
        val l2 = Draw.letterRow(c, p, fonts, d, pic.word, px, qy, cw, Ink.surface, Ink.text)
        Draw.text(c, p, fonts, "→", px + l2 + 18f * d, qy + 18f * d, 20f * d,
            Ink.muted, 900, Paint.Align.CENTER)
        Draw.rrect(c, p, px + l2 + 36f * d, qy, cw * 1.4f, 36f * d, 9f * d,
            0xFFF1ECFF.toInt(), Ink.primary, 1.8f * d)
        Draw.text(c, p, fonts, "?", px + l2 + 36f * d + cw * 0.7f, qy + 18f * d, 20f * d,
            Ink.primary, 900, Paint.Align.CENTER)
    }

    // -------------------------------------------------------------- in space

    /** The squares of a cube net, with what is drawn on each. */
    private fun net(c: Canvas, pic: Curriculum.Pic, w: Float) {
        val cells = pic.netCells
        if (cells.isEmpty()) return
        val cols = cells.maxOf { it.first } + 1
        val rows = cells.maxOf { it.second } + 1
        val size = minOf(46f * d, w / cols, 150f * d / rows)
        Solid.netCells(c, p, fonts, d, cells, 0f, 0f, w, rows * size, 46f * d,
            pic.marks, pic.target, null)
    }

    /** The floor a dice rolls over, the path, and the dice itself. */
    private fun roll(c: Canvas, pic: Curriculum.Pic, w: Float) {
        val cell = 38f * d
        val gw = pic.gridW * cell
        for (r in 0 until pic.gridH) for (q in 0 until pic.gridW) {
            Draw.rrect(c, p, q * cell + 1f * d, r * cell + 1f * d, cell - 2f * d, cell - 2f * d,
                6f * d, if ((q + r) % 2 != 0) Ink.tileAlt else Ink.tile, Ink.line, 1f * d)
        }
        var cx = pic.startCell?.first ?: 0
        var cy = pic.startCell?.second ?: 0
        fun ctr(q: Int, r: Int) = (q * cell + cell / 2f) to (r * cell + cell / 2f)
        val (sx, sy) = ctr(cx, cy)
        p.style = Paint.Style.FILL; p.color = Ink.primary
        c.drawCircle(sx, sy, 7f * d, p)
        for (m in pic.moves) {
            val (ax, ay) = ctr(cx, cy)
            when (m) {
                "right" -> cx++; "left" -> cx--; "up" -> cy--; "down" -> cy++
            }
            val (bx, by) = ctr(cx, cy)
            p.style = Paint.Style.STROKE; p.color = Ink.primary; p.strokeWidth = 3f * d
            c.drawLine(ax, ay, bx - (bx - ax) * 0.3f, by - (by - ay) * 0.3f, p)
            p.style = Paint.Style.FILL
            Draw.arrow(c, p, (ax + bx) / 2f + (bx - ax) * 0.18f,
                (ay + by) / 2f + (by - ay) * 0.18f, 6f * d, m, Ink.primary)
        }
        val dx = gw + (w - gw) / 2f
        val dy = 46f * d
        isoCube(c, dx, dy, 32f * d, "${pic.faceTop}", "${pic.faceFront}", "${pic.faceRight}")
        Draw.text(c, p, fonts, "front", dx - 22f * d, dy + 44f * d, 11f * d,
            Ink.muted, 800, Paint.Align.CENTER)
        Draw.text(c, p, fonts, "right", dx + 22f * d, dy + 44f * d, 11f * d,
            Ink.muted, 800, Paint.Align.CENTER)
    }

    /** One cube seen from a corner, with a label on each of its three faces. */
    private fun isoCube(
        c: Canvas, cx: Float, cy: Float, s: Float,
        top: String, front: String, right: String,
    ) {
        val a = s * 0.866f; val b = s * 0.5f
        val faces = listOf(
            Triple(listOf(cx to cy - s, cx + a to cy - b, cx to cy, cx - a to cy - b),
                Solid.TOP, top),
            Triple(listOf(cx - a to cy - b, cx to cy, cx to cy + s, cx - a to cy + b),
                Solid.FRONT, front),
            Triple(listOf(cx to cy, cx + a to cy - b, cx + a to cy + b, cx to cy + s),
                Solid.RIGHT, right))
        for ((pts, fill, label) in faces) {
            Solid.poly(c, p, pts, fill, Ink.primaryLedge, 1.5f * d)
            val mx = pts.sumOf { it.first.toDouble() }.toFloat() / 4f
            val my = pts.sumOf { it.second.toDouble() }.toFloat() / 4f
            Draw.text(c, p, fonts, label, mx, my, 17f * d, Ink.text, 900, Paint.Align.CENTER)
        }
    }

    /** A pile of cubes on a floor, seen from a corner. */
    private fun stack(c: Canvas, pic: Curriculum.Pic, w: Float) {
        val hs = pic.heights
        if (hs.isEmpty() || hs[0].isEmpty()) return
        val depth = hs.size; val wide = hs[0].size
        val s = 24f * d; val a = s * 0.866f; val b = s * 0.5f
        val top = hs.maxOf { r -> r.maxOrNull() ?: 0 }
        val iso = Iso((w - (wide + depth) * a) / 2f + depth * a, 8f * d + top * s, s)
        fun pt(X: Int, Y: Int, Z: Int) = iso.x(X, Y) to iso.y(X, Y, Z)

        val cubes = mutableListOf<Triple<Int, Int, Int>>()
        for (Y in 0 until depth) for (X in 0 until wide) for (Z in 0 until hs[Y][X]) {
            cubes.add(Triple(X, Y, Z))
        }
        // Painter's order: the far cubes first, so the near ones cover them.
        for (q in cubes.sortedWith(compareBy({ it.first + it.second }, { it.third }))) {
            val (X, Y, Z) = q
            Solid.poly(c, p, listOf(pt(X, Y, Z + 1), pt(X + 1, Y, Z + 1),
                pt(X + 1, Y + 1, Z + 1), pt(X, Y + 1, Z + 1)),
                Solid.TOP, Ink.primaryLedge, 1f * d)
            Solid.poly(c, p, listOf(pt(X, Y + 1, Z), pt(X + 1, Y + 1, Z),
                pt(X + 1, Y + 1, Z + 1), pt(X, Y + 1, Z + 1)),
                Solid.FRONT, Ink.primaryLedge, 1f * d)
            Solid.poly(c, p, listOf(pt(X + 1, Y, Z), pt(X + 1, Y + 1, Z),
                pt(X + 1, Y + 1, Z + 1), pt(X + 1, Y, Z + 1)),
                Solid.RIGHT, Ink.primaryLedge, 1f * d)
        }
        if (pic.side.isNotEmpty()) {
            val fx = iso.x(wide / 2f, depth.toFloat())
            val fy = iso.y(wide / 2f, depth.toFloat(), 0f)
            val rx = iso.x(wide.toFloat(), depth / 2f)
            val ry = iso.y(wide.toFloat(), depth / 2f, 0f)
            Draw.text(c, p, fonts, "FRONT", fx - 16f * d, fy + 16f * d, 11f * d,
                if (pic.side == "front") Ink.primary else Ink.muted, 900, Paint.Align.CENTER)
            Draw.text(c, p, fonts, "RIGHT", rx + 18f * d, ry + 16f * d, 11f * d,
                if (pic.side == "right") Ink.primary else Ink.muted, 900, Paint.Align.CENTER)
        }
    }

    /** A marked cube, and the turns to make in words. */
    private fun turnCube(c: Canvas, pic: Curriculum.Pic, w: Float) {
        val cx = w / 2f; val cy = 62f * d; val s = 46f * d
        val a = s * 0.866f; val b = s * 0.5f
        val faces = listOf(
            listOf(cx to cy - s, cx + a to cy - b, cx to cy, cx - a to cy - b) to Solid.TOP,
            listOf(cx - a to cy - b, cx to cy, cx to cy + s, cx - a to cy + b) to Solid.FRONT,
            listOf(cx to cy, cx + a to cy - b, cx + a to cy + b, cx to cy + s) to Solid.RIGHT)
        faces.forEachIndexed { i, (pts, fill) ->
            Solid.poly(c, p, pts, fill, Ink.primaryLedge, 1.5f * d)
            val mx = pts.sumOf { it.first.toDouble() }.toFloat() / 4f
            val my = pts.sumOf { it.second.toDouble() }.toFloat() / 4f
            pic.marks.getOrNull(i)?.let { mark ->
                // Drawn white first and smaller in colour over it: the darkest
                // face is nearly the mark's own colour, and a mark that cannot
                // be told apart from its face is the question gone.
                Glyphs.draw(c, mark, mx, my, 12f * d, 0xFFFFFFFF.toInt(), null, p)
                Glyphs.draw(c, mark, mx, my, 10f * d, Ink.accentLedge, null, p)
            }
        }
        pic.stepLines.forEachIndexed { i, t ->
            val label = if (pic.stepLines.size > 1) "${i + 1}. $t" else t
            Draw.text(c, p, fonts, label, w / 2f, 132f * d + i * 22f * d, 14f * d,
                Ink.text, 800, Paint.Align.CENTER)
        }
    }
}
