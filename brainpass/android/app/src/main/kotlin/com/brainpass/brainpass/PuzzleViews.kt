package com.brainpass.brainpass

import android.content.Context
import android.graphics.Canvas
import android.graphics.DashPathEffect
import android.graphics.Paint
import android.graphics.Typeface
import android.view.View

/**
 * The visual vocabulary for Puzzles and Logic, the skill for ages 7-8.
 *
 * Number Sense could answer everything by showing a quantity. This skill asks
 * about ORDER, POSITION, RELATION and RULE, none of which is a quantity: "who
 * is tallest" wants the clues laid out, "who is third from the back" wants a
 * queue you can count along, "what is Raj to Riya" wants the sentences kept in
 * view while you work, and "which shape is left of the heart" wants a shelf.
 *
 * Each drawing here is a port of the one on the review wall the questions were
 * signed off against (tools/curriculum/wall_template.html), so what a parent
 * approved on the page is what the child meets on the phone. The wall's numbers
 * are CSS pixels at a 360-wide card; they are read here as dp, which is the
 * same size on a real screen.
 */

/** The drawing primitives the wall uses, in Android terms. */
object Draw {

    /** Weight to typeface, the way the wall's font strings map onto Nunito. */
    fun face(fonts: Fonts, weight: Int): Typeface = when {
        weight >= 900 -> fonts.black
        weight >= 800 -> fonts.extra
        weight >= 700 -> fonts.bold
        else -> fonts.body
    }

    fun rrect(
        c: Canvas, p: Paint, x: Float, y: Float, w: Float, h: Float, r: Float,
        fill: Int?, stroke: Int? = null, strokeWidth: Float = 1.5f,
    ) {
        if (fill != null) {
            p.style = Paint.Style.FILL; p.color = fill
            c.drawRoundRect(x, y, x + w, y + h, r, r, p)
        }
        if (stroke != null) {
            p.style = Paint.Style.STROKE; p.strokeWidth = strokeWidth; p.color = stroke
            c.drawRoundRect(x, y, x + w, y + h, r, r, p)
            p.style = Paint.Style.FILL
        }
    }

    /**
     * Text whose [y] is its MIDDLE, not its baseline.
     *
     * The wall draws with textBaseline="middle" and every y in the ported
     * layouts is written that way. Centring here rather than at each call site
     * is what keeps the two drawings the same picture.
     */
    fun text(
        c: Canvas, p: Paint, fonts: Fonts, s: String, x: Float, y: Float,
        size: Float, color: Int, weight: Int = 700, align: Paint.Align = Paint.Align.LEFT,
    ) {
        p.style = Paint.Style.FILL
        p.typeface = face(fonts, weight)
        p.textSize = size
        p.color = color
        p.textAlign = align
        c.drawText(s, x, y - (p.descent() + p.ascent()) / 2f, p)
    }

    /** The largest size at or below [size] that fits [maxW], never below [min]. */
    fun fitSize(
        p: Paint, fonts: Fonts, s: String, maxW: Float, size: Float,
        min: Float, weight: Int = 900,
    ): Float {
        p.typeface = face(fonts, weight)
        var z = size
        p.textSize = z
        while (z > min && p.measureText(s) > maxW) {
            z -= 1f; p.textSize = z
        }
        return z
    }

    /** [s] broken into lines that each fit [maxW]. */
    fun lineBreaks(
        p: Paint, fonts: Fonts, s: String, maxW: Float, size: Float, weight: Int = 700,
    ): List<String> {
        p.typeface = face(fonts, weight)
        p.textSize = size
        val out = mutableListOf<String>()
        var line = ""
        for (w in s.split(" ")) {
            val t = if (line.isEmpty()) w else "$line $w"
            if (p.measureText(t) > maxW && line.isNotEmpty()) { out.add(line); line = w }
            else line = t
        }
        if (line.isNotEmpty()) out.add(line)
        return out
    }

    /** A number or word in a raised box; [hole] is the one being asked for. */
    fun tokenBox(
        c: Canvas, p: Paint, fonts: Fonts, d: Float, label: String,
        x: Float, y: Float, w: Float, h: Float, hole: Boolean,
    ) {
        rrect(c, p, x, y + 3f * d, w, h, 12f * d, Ink.ledge)
        rrect(c, p, x, y, w, h, 12f * d,
            if (hole) 0xFFF1ECFF.toInt() else Ink.surface,
            if (hole) Ink.primary else Ink.line, (if (hole) 2f else 1.5f) * d)
        val z = fitSize(p, fonts, label, w - 8f * d, 24f * d, 12f * d)
        text(c, p, fonts, label, x + w / 2f, y + h / 2f, z,
            if (hole) Ink.primary else Ink.text, 900, Paint.Align.CENTER)
    }

    /** One letter per cell, the way a code question lines a word up. */
    fun letterRow(
        c: Canvas, p: Paint, fonts: Fonts, d: Float, word: String,
        x: Float, y: Float, cellW: Float, fill: Int, color: Int,
    ): Float {
        for (i in word.indices) {
            val bx = x + i * (cellW + 4f * d)
            rrect(c, p, bx, y, cellW, 36f * d, 9f * d, fill, Ink.primary, 1.4f * d)
            text(c, p, fonts, word[i].toString(), bx + cellW / 2f, y + 18f * d,
                17f * d, color, 900, Paint.Align.CENTER)
        }
        return word.length * (cellW + 4f * d) - 4f * d
    }

    /** A space-separated code as a row of number cells. */
    fun numRow(
        c: Canvas, p: Paint, fonts: Fonts, d: Float, s: String, x: Float, y: Float,
    ): Float {
        val parts = s.trim().split(" ").filter { it.isNotEmpty() }
        val cw = 30f * d
        parts.forEachIndexed { i, v ->
            val bx = x + i * (cw + 4f * d)
            rrect(c, p, bx, y, cw, 36f * d, 9f * d, 0xFFF1ECFF.toInt(), Ink.primary, 1.4f * d)
            text(c, p, fonts, v, bx + cw / 2f, y + 18f * d, 16f * d,
                Ink.primary, 900, Paint.Align.CENTER)
        }
        return parts.size * (cw + 4f * d) - 4f * d
    }

    fun arrow(c: Canvas, p: Paint, cx: Float, cy: Float, size: Float, dir: String, color: Int) {
        c.save()
        c.translate(cx, cy)
        c.rotate(when (dir) { "down" -> 90f; "left" -> 180f; "up" -> 270f; else -> 0f })
        p.color = color
        p.strokeWidth = size * 0.42f
        p.strokeCap = Paint.Cap.ROUND
        p.style = Paint.Style.STROKE
        c.drawLine(-size, 0f, size * 0.25f, 0f, p)
        p.style = Paint.Style.FILL
        val path = android.graphics.Path().apply {
            moveTo(size * 1.05f, 0f)
            lineTo(size * 0.1f, -size * 0.72f)
            lineTo(size * 0.1f, size * 0.72f)
            close()
        }
        c.drawPath(path, p)
        c.restore()
    }

    fun ordinal(n: Int): String {
        val t = n % 100
        if (t in 10..20) return "${n}th"
        return n.toString() + when (n % 10) { 1 -> "st"; 2 -> "nd"; 3 -> "rd"; else -> "th" }
    }

    /**
     * The clue card: the sentences the question is about, kept on screen while
     * the child works. Cream rather than white, so it reads as "what you were
     * told" and not as another thing to tap.
     */
    fun clueCard(
        c: Canvas, p: Paint, fonts: Fonts, d: Float,
        lines: List<String>, x: Float, y: Float, w: Float,
    ): Float {
        val rows = lines.flatMap { lineBreaks(p, fonts, it, w - 28f * d, 15f * d) }
        val h = (28f + 22f * rows.size) * d
        rrect(c, p, x, y, w, h, 16f * d, 0xFFFFFCEF.toInt(), 0xFFF2E3B3.toInt(), 1.5f * d)
        rows.forEachIndexed { i, r ->
            text(c, p, fonts, r, x + 14f * d, y + (14f + 11f + i * 22f) * d, 15f * d, Ink.text, 700)
        }
        return h
    }

    /** The height a clue card will take, without drawing it. */
    fun clueCardHeight(
        p: Paint, fonts: Fonts, d: Float, lines: List<String>, w: Float,
    ): Float {
        val rows = lines.flatMap { lineBreaks(p, fonts, it, w - 28f * d, 15f * d) }
        return (28f + 22f * rows.size) * d
    }
}

/**
 * A view that draws one [Curriculum.Pic] from this skill.
 *
 * The band's drawings differ in what they show but not in how they behave:
 * none of them is tapped (the answer is always a button underneath), and all
 * of them size themselves from their content. So one view switches on the
 * picture's kind rather than fourteen views each wiring up the same things.
 */
class PuzzlePicView(ctx: Context, private val fonts: Fonts) : NumberView(ctx) {

    var pic: Curriculum.Pic? = null
        set(v) { field = v; requestLayout(); invalidate() }

    companion object {
        /**
         * The picture kinds that have a drawing.
         *
         * An odd-one-out has none on purpose. Its four things are already the
         * four answer buttons, so drawing them again above would show the same
         * four words twice, in two different orders (the buttons are shuffled
         * so the answer is not always in the same place). A child would have
         * to match one list against the other before they could even start.
         */
        private val DRAWN = setOf(
            "card", "equation", "bars", "series", "line", "shelf", "compass",
            "wordPairs", "numPairs", "letter", "example", "numExample", "clock",
        )

        /** Whether [pic] has anything to draw, so the gate can leave it out. */
        fun draws(pic: Curriculum.Pic?): Boolean = pic != null && pic.kind in DRAWN
    }

    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val d get() = context.dpf(1f)

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        val w = MeasureSpec.getSize(widthSpec)
        setMeasuredDimension(w, heightFor(w.toFloat()).toInt().coerceAtLeast(dp(40)))
    }

    /** Height is asked for before the draw, so every renderer reports its own. */
    private fun heightFor(w: Float): Float {
        val pic = pic ?: return 0f
        return when (pic.kind) {
            "card" -> Draw.clueCardHeight(p, fonts, d, pic.lines, w)
            "equation" -> 70f * d
            "bars" -> 124f * d
            "series" -> 64f * d
            "line" -> (if (pic.names.isNotEmpty()) 128f else 110f) * d
            "shelf" -> 84f * d
            // The S sits 11 below the circle and is drawn from its middle, so
            // the wall's 128 cut the bottom off the letter. Measured, not guessed.
            "compass" -> Draw.clueCardHeight(p, fonts, d, pic.lines, w) + 140f * d
            "wordPairs" -> 112f * d
            "numPairs" -> (44f * pic.numPairs.size + 12f) * d
            "letter" -> 70f * d
            "example", "numExample" -> 112f * d
            "clock" -> 140f * d +
                (if (pic.lines.isNotEmpty()) Draw.clueCardHeight(p, fonts, d, pic.lines, w) + 10f * d else 0f)
            else -> 0f
        }
    }

    override fun onDraw(canvas: Canvas) {
        val pic = pic ?: return
        val w = width.toFloat()
        when (pic.kind) {
            "card" -> Draw.clueCard(canvas, p, fonts, d, pic.lines, 0f, 0f, w)
            "equation" -> equation(canvas, pic, w)
            "bars" -> bars(canvas, pic, w)
            "series" -> series(canvas, pic, w)
            "line" -> queue(canvas, pic, w)
            "shelf" -> shelf(canvas, pic, w)
            "compass" -> compass(canvas, pic, w)
            "wordPairs" -> wordPairs(canvas, pic, w)
            "numPairs" -> numPairs(canvas, pic, w)
            "letter" -> letterHint(canvas, pic, w)
            "example" -> example(canvas, pic, w)
            "numExample" -> numExample(canvas, pic, w)
            "clock" -> clock(canvas, pic, w)
        }
    }

    // ---------------------------------------------------------------- number

    /** `27 + [?] = 45`, with the unknown drawn as an empty box. */
    private fun equation(c: Canvas, pic: Curriculum.Pic, w: Float) {
        val toks = listOf(
            Triple(if (pic.hide == "left") "?" else "${pic.left ?: 0}", true, pic.hide == "left"),
            Triple(if (pic.op == "-") "−" else "+", false, false),
            Triple(if (pic.hide == "right") "?" else "${pic.right ?: 0}", true, pic.hide == "right"),
            Triple("=", false, false),
            Triple(if (pic.hide == "result") "?" else "${pic.result}", true, pic.hide == "result"),
        )
        val bw = 58f * d; val ow = 28f * d; val gap = 8f * d
        var cx = (w - (3 * bw + 2 * ow + 4 * gap)) / 2f
        for ((label, isBox, hole) in toks) {
            if (isBox) {
                Draw.tokenBox(c, p, fonts, d, label, cx, 8f * d, bw, 52f * d, hole)
                cx += bw + gap
            } else {
                Draw.text(c, p, fonts, label, cx + ow / 2f, 34f * d, 26f * d,
                    Ink.muted, 900, Paint.Align.CENTER)
                cx += ow + gap
            }
        }
    }

    /**
     * Two bars and the gap between them.
     *
     * The bracket under the ends is what makes "how many more" a thing you can
     * see: dashed guides run down from each bar's end so the bracket reads as
     * the piece the longer bar has and the shorter one does not.
     */
    private fun bars(c: Canvas, pic: Curriculum.Pic, w: Float) {
        if (pic.values.size < 2 || pic.names.size < 2) return
        val nameW = 56f * d
        val maxW = w - nameW - 44f * d
        val top = pic.values[0].toFloat(); val low = pic.values[1].toFloat()
        if (top <= 0f) return
        val scale = maxW / top
        val rows = listOf(
            Triple(pic.names[0], top, pic.shownTop) to 0xFFC9B6F8.toInt(),
            Triple(pic.names[1], low, pic.shownLow) to 0xFFFDE68A.toInt(),
        )
        rows.forEachIndexed { i, (r, colour) ->
            val by = (10f + i * 50f) * d
            Draw.text(c, p, fonts, r.first, 0f, by + 17f * d, 14f * d, Ink.text, 800)
            Draw.rrect(c, p, nameW, by, r.second * scale, 34f * d, 8f * d,
                colour, Ink.primaryLedge, 1.2f * d)
            Draw.text(c, p, fonts, r.third?.toString() ?: "?",
                nameW + r.second * scale / 2f, by + 17f * d, 18f * d,
                if (r.third == null) Ink.primary else Ink.text, 900, Paint.Align.CENTER)
        }
        val gx0 = nameW + low * scale; val gx1 = nameW + top * scale
        val gy = (60f + 34f + 8f) * d
        p.style = Paint.Style.STROKE; p.color = Ink.primary; p.strokeWidth = 2f * d
        p.pathEffect = null
        c.drawLine(gx0, gy - 6f * d, gx0, gy, p)
        c.drawLine(gx0, gy, gx1, gy, p)
        c.drawLine(gx1, gy, gx1, gy - 6f * d, p)
        Draw.text(c, p, fonts, pic.shownDiff?.toString() ?: "?", (gx0 + gx1) / 2f, gy + 12f * d,
            16f * d, if (pic.shownDiff == null) Ink.primary else Ink.text, 900, Paint.Align.CENTER)
        p.style = Paint.Style.STROKE
        p.color = Ink.muted; p.strokeWidth = 1.2f * d
        p.pathEffect = DashPathEffect(floatArrayOf(4f * d, 4f * d), 0f)
        c.drawLine(gx1, (10f + 34f) * d, gx1, gy - 6f * d, p)
        c.drawLine(gx0, (60f + 34f) * d, gx0, gy - 6f * d, p)
        p.pathEffect = null
        p.style = Paint.Style.FILL
    }

    /** A run of numbers with one box left empty. */
    private fun series(c: Canvas, pic: Curriculum.Pic, w: Float) {
        val t = pic.terms
        val n = t.size.coerceAtLeast(1); val gap = 6f * d
        val box = minOf(56f * d, (w - gap * (n - 1)) / n)
        val ox = (w - (box * n + gap * (n - 1))) / 2f
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
        }
    }

    // -------------------------------------------------------------- position

    /** A line of children, front at the left, with one of them marked. */
    private fun queue(c: Canvas, pic: Curriculum.Pic, w: Float) {
        val n = pic.n.coerceAtLeast(1)
        val sp = w / n
        val r = minOf(11f * d, sp * 0.28f)
        val base = 62f * d
        Draw.text(c, p, fonts, "FRONT", 2f * d, 10f * d, 11f * d, Ink.primary, 900)
        Draw.text(c, p, fonts, "BACK", w - 2f * d, 10f * d, 11f * d, Ink.muted, 900,
            Paint.Align.RIGHT)
        for (i in 0 until n) {
            val cx = sp * i + sp / 2f
            val marked = pic.mark == i + 1
            val colour = if (marked) Ink.accent else 0xFFC9B6F8.toInt()
            p.style = Paint.Style.FILL; p.color = colour
            c.drawCircle(cx, base - 26f * d, r, p)
            Draw.rrect(c, p, cx - r * 1.1f, base - 13f * d, r * 2.2f, r * 2.6f, r * 0.8f, colour)
            pic.names.getOrNull(i)?.let { nm ->
                val z = Draw.fitSize(p, fonts, nm, sp - 2f * d, 12f * d, 8f * d, 800)
                Draw.text(c, p, fonts, nm, cx, base + 30f * d, z, Ink.text, 800, Paint.Align.CENTER)
            }
        }
        if (pic.mark > 0 && pic.name.isNotEmpty()) {
            val cx = sp * (pic.mark - 1) + sp / 2f
            Draw.text(c, p, fonts, pic.name, cx, base - 48f * d, 13f * d, Ink.text, 900,
                Paint.Align.CENTER)
        }
    }

    /** A row of shapes, so "just left of the heart" points at something. */
    private fun shelf(c: Canvas, pic: Curriculum.Pic, w: Float) {
        val items = pic.items
        if (items.isEmpty()) return
        val gap = 8f * d
        val tile = minOf(58f * d, (w - gap * (items.size - 1)) / items.size)
        val ox = (w - (tile * items.size + gap * (items.size - 1))) / 2f
        items.forEachIndexed { i, k ->
            val bx = ox + i * (tile + gap)
            Draw.rrect(c, p, bx, 14f * d, tile, tile, 12f * d, Ink.surface, Ink.line, 1.5f * d)
            Glyphs.draw(c, k, bx + tile / 2f, 14f * d + tile / 2f, tile * 0.28f,
                Ink.primary, Ink.primaryLedge, p)
        }
        Draw.text(c, p, fonts, "left", 4f * d, 6f * d, 11f * d, Ink.muted, 800)
        Draw.text(c, p, fonts, "right", w - 4f * d, 6f * d, 11f * d, Ink.muted, 800,
            Paint.Align.RIGHT)
    }

    /** North at the top and an arrow showing which way the child is facing. */
    private fun compass(c: Canvas, pic: Curriculum.Pic, w: Float) {
        val h = Draw.clueCard(c, p, fonts, d, pic.lines, 0f, 0f, w)
        val cy = h + 10f * d + 59f * d
        val cx = w / 2f
        val radius = 46f * d
        p.style = Paint.Style.FILL; p.color = Ink.surface
        c.drawCircle(cx, cy, radius, p)
        p.style = Paint.Style.STROKE; p.strokeWidth = 1.5f * d; p.color = Ink.line
        c.drawCircle(cx, cy, radius, p)
        for ((name, dx, dy) in listOf(
            Triple("N", 0f, -1f), Triple("E", 1f, 0f),
            Triple("S", 0f, 1f), Triple("W", -1f, 0f),
        )) {
            Draw.text(c, p, fonts, name, cx + dx * (radius + 11f * d),
                cy + dy * (radius + 11f * d), 13f * d, Ink.primary, 900, Paint.Align.CENTER)
            p.style = Paint.Style.STROKE; p.color = Ink.line; p.strokeWidth = 1.5f * d
            c.drawLine(cx + dx * (radius - 4f * d), cy + dy * (radius - 4f * d),
                cx + dx * radius, cy + dy * radius, p)
        }
        val (ax, ay) = when (pic.start) {
            "East" -> 1f to 0f; "South" -> 0f to 1f; "West" -> -1f to 0f; else -> 0f to -1f
        }
        val dir = when (pic.start) {
            "East" -> "right"; "South" -> "down"; "West" -> "left"; else -> "up"
        }
        Draw.arrow(c, p, cx + ax * radius * 0.35f, cy + ay * radius * 0.35f,
            12f * d, dir, Ink.accentLedge)
        p.style = Paint.Style.FILL; p.color = Ink.primary
        c.drawCircle(cx, cy, 6f * d, p)
    }

    // -------------------------------------------------------------- relation

    /** `cow -> calf`, then `dog -> ?`. */
    private fun wordPairs(c: Canvas, pic: Curriculum.Pic, w: Float) {
        Draw.rrect(c, p, 0f, 0f, w, 104f * d, 16f * d,
            0xFFFFFCEF.toInt(), 0xFFF2E3B3.toInt(), 1.5f * d)
        pic.wordPairs.forEachIndexed { i, pr ->
            val ry = (14f + i * 46f) * d
            val bw = (w - 80f * d) / 2f
            Draw.tokenBox(c, p, fonts, d, pr.first ?: "?", 14f * d, ry, bw, 36f * d, pr.first == null)
            Draw.text(c, p, fonts, "→", w / 2f, ry + 18f * d, 20f * d,
                Ink.muted, 900, Paint.Align.CENTER)
            Draw.tokenBox(c, p, fonts, d, pr.second ?: "?", w - 14f * d - bw, ry, bw, 36f * d,
                pr.second == null)
        }
    }

    /** The same idea with numbers: two worked pairs, then one to finish. */
    private fun numPairs(c: Canvas, pic: Curriculum.Pic, w: Float) {
        val bw = 70f * d
        pic.numPairs.forEachIndexed { i, pr ->
            val ry = (6f + i * 44f) * d
            val ox = (w - (bw * 2 + 60f * d)) / 2f
            Draw.tokenBox(c, p, fonts, d, pr.first?.toString() ?: "?", ox, ry, bw, 34f * d,
                pr.first == null)
            Draw.text(c, p, fonts, "→", ox + bw + 30f * d, ry + 17f * d, 20f * d,
                Ink.muted, 900, Paint.Align.CENTER)
            Draw.tokenBox(c, p, fonts, d, pr.second?.toString() ?: "?", ox + bw + 60f * d, ry,
                bw, 34f * d, pr.second == null)
        }
    }

    /** The letter before or after, shown as a gap in the alphabet. */
    private fun letterHint(c: Canvas, pic: Curriculum.Pic, w: Float) {
        val seq = when (pic.offset) {
            1 -> listOf(pic.base, "?")
            -1 -> listOf("?", pic.base)
            2 -> listOf(pic.base, "", "?")
            else -> listOf("?", "", pic.base)
        }
        val bw = 56f * d; val gap = 10f * d
        val ox = (w - (seq.size * bw + (seq.size - 1) * gap)) / 2f
        seq.forEachIndexed { i, v ->
            Draw.tokenBox(c, p, fonts, d, v, ox + i * (bw + gap), 8f * d, bw, 52f * d, v == "?")
        }
    }

    // ------------------------------------------------------------------ code

    /** One worked example of the code, then the word to put through it. */
    private fun example(c: Canvas, pic: Curriculum.Pic, w: Float) {
        if (pic.example.size < 2) return
        val cw = 30f * d
        Draw.rrect(c, p, 0f, 0f, w, 104f * d, 16f * d,
            0xFFFFFCEF.toInt(), 0xFFF2E3B3.toInt(), 1.5f * d)
        Draw.text(c, p, fonts, "Example", 14f * d, 14f * d, 12f * d, Ink.muted, 800)
        val px = 14f * d
        val lw = Draw.letterRow(c, p, fonts, d, pic.example[0], px, 26f * d, cw, Ink.surface, Ink.text)
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

    /** The same, where the code is numbers: `BAD -> 2 1 4`. */
    private fun numExample(c: Canvas, pic: Curriculum.Pic, w: Float) {
        if (pic.example.size < 2) return
        val cw = 30f * d; val px = 14f * d
        Draw.rrect(c, p, 0f, 0f, w, 104f * d, 16f * d,
            0xFFFFFCEF.toInt(), 0xFFF2E3B3.toInt(), 1.5f * d)
        Draw.text(c, p, fonts, "Example", 14f * d, 14f * d, 12f * d, Ink.muted, 800)
        val lw = Draw.letterRow(c, p, fonts, d, pic.example[0], px, 26f * d, cw, Ink.surface, Ink.text)
        Draw.text(c, p, fonts, "→", px + lw + 18f * d, 44f * d, 20f * d,
            Ink.muted, 900, Paint.Align.CENTER)
        Draw.numRow(c, p, fonts, d, pic.example[1], px + lw + 36f * d, 26f * d)
        val qy = 66f * d
        if (pic.mode == "encode") {
            val l2 = Draw.letterRow(c, p, fonts, d, pic.word, px, qy, cw, Ink.surface, Ink.text)
            Draw.text(c, p, fonts, "→", px + l2 + 18f * d, qy + 18f * d, 20f * d,
                Ink.muted, 900, Paint.Align.CENTER)
            Draw.rrect(c, p, px + l2 + 36f * d, qy, cw * 1.4f, 36f * d, 9f * d,
                0xFFF1ECFF.toInt(), Ink.primary, 1.8f * d)
            Draw.text(c, p, fonts, "?", px + l2 + 36f * d + cw * 0.7f, qy + 18f * d, 20f * d,
                Ink.primary, 900, Paint.Align.CENTER)
        } else {
            val l2 = Draw.numRow(c, p, fonts, d, pic.word, px, qy)
            Draw.text(c, p, fonts, "→", px + l2 + 18f * d, qy + 18f * d, 20f * d,
                Ink.muted, 900, Paint.Align.CENTER)
            Draw.rrect(c, p, px + l2 + 36f * d, qy, cw * 1.4f, 36f * d, 9f * d,
                Ink.surface, Ink.primary, 1.8f * d)
            Draw.text(c, p, fonts, "?", px + l2 + 36f * d + cw * 0.7f, qy + 18f * d, 20f * d,
                Ink.primary, 900, Paint.Align.CENTER)
        }
    }

    // ----------------------------------------------------------------- logic

    /** A clock face with real hands, so the time is read and not told. */
    private fun clock(c: Canvas, pic: Curriculum.Pic, w: Float) {
        val cx = w / 2f; val cy = 68f * d; val radius = 58f * d
        p.style = Paint.Style.FILL; p.color = Ink.surface
        c.drawCircle(cx, cy, radius, p)
        p.style = Paint.Style.STROKE; p.color = Ink.primaryLedge; p.strokeWidth = 3f * d
        c.drawCircle(cx, cy, radius, p)
        for (i in 1..12) {
            val a = i * Math.PI / 6
            Draw.text(c, p, fonts, "$i",
                cx + (Math.sin(a) * (radius - 13f * d)).toFloat(),
                cy - (Math.cos(a) * (radius - 13f * d)).toFloat(),
                11f * d, Ink.text, 800, Paint.Align.CENTER)
        }
        val ha = ((pic.h % 12) + pic.m / 60.0) * Math.PI / 6
        val ma = pic.m * Math.PI / 30
        p.style = Paint.Style.STROKE; p.strokeCap = Paint.Cap.ROUND
        p.color = Ink.text; p.strokeWidth = 5f * d
        c.drawLine(cx, cy, cx + (Math.sin(ha) * radius * 0.48).toFloat(),
            cy - (Math.cos(ha) * radius * 0.48).toFloat(), p)
        // 0.78 of the radius is exactly where the hour numbers sit, so at
        // o'clock the minute hand landed on top of the 12. It stops short now.
        p.color = Ink.primary; p.strokeWidth = 3f * d
        c.drawLine(cx, cy, cx + (Math.sin(ma) * radius * 0.66).toFloat(),
            cy - (Math.cos(ma) * radius * 0.66).toFloat(), p)
        p.style = Paint.Style.FILL; p.color = Ink.text
        c.drawCircle(cx, cy, 4f * d, p)
        if (pic.lines.isNotEmpty()) {
            Draw.clueCard(c, p, fonts, d, pic.lines, 0f, 140f * d, w)
        }
    }
}
