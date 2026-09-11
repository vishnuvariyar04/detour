package com.brainpass.brainpass

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout

/**
 * The program half of GridBot: the blocks a child reads, taps and rearranges.
 *
 * A block is drawn, never typed, so the same chip means the same thing whether
 * it is sitting in a program, in an answer slot or in the tray underneath.
 */
object Blocks {

    val ARROWS = setOf("up", "down", "left", "right")

    fun word(token: String): String = when {
        token == "up" -> "UP"
        token == "down" -> "DOWN"
        token == "left" -> "LEFT"
        token == "right" -> "RIGHT"
        token == "pick" -> "PICK UP"
        token == "open" -> "OPEN"
        token == "?" -> "?"
        token == "end" -> "END"
        token == "else" -> "OR ELSE"
        // "repeat:3" is read by a child as "DO 3 TIMES" — "repeat" alone does
        // not say that the steps underneath are the ones being repeated.
        token.startsWith("repeat:") -> "DO ${token.substringAfter(':')} TIMES"
        token.startsWith("if:") -> "IF " + sensorWord(token.substringAfter(':'))
        // set:COINS:3 reads as SET COINS = 3, add:COINS:2 as ADD 2 TO COINS.
        token.startsWith("set:") || token.startsWith("add:") -> {
            val p = token.split(":")
            if (p.size == 3) {
                val n = p[2].toIntOrNull() ?: 0
                when {
                    p[0] == "set" -> "SET ${p[1]} = ${p[2]}"
                    // "ADD -3" is arithmetic notation, not something a child
                    // reads. Taking away is its own word.
                    n < 0 -> "TAKE ${-n} FROM ${p[1]}"
                    else -> "ADD $n TO ${p[1]}"
                }
            } else token.uppercase()
        }
        else -> token.uppercase()
    }

    /** Plain words for a sensor, so a child can check it by looking. */
    private fun sensorWord(cond: String): String {
        // "IF NO WALL UP" is neither English nor a description of the board.
        // A check has to read as the thing a child should go and look at, so
        // the negated wall checks get their own phrasing rather than a NO
        // bolted on the front.
        if (cond.startsWith("not-")) {
            val base = cond.substring(4)
            if (base.startsWith("wall-"))
                return "WAY " + base.substringAfter('-').uppercase() + " IS CLEAR"
            if (base == "star") return "NOT ON A STAR"
            return "NOT " + sensorWord(base)
        }
        return when {
            cond == "star" -> "ON A STAR"
            cond == "key" -> "HOLDING THE KEY"
            cond == "door" -> "AT THE DOOR"
            cond.startsWith("wall-") -> "WALL " + when (cond.substringAfter('-')) {
                "up" -> "ABOVE"
                "down" -> "BELOW"
                "left" -> "ON THE LEFT"
                else -> "ON THE RIGHT"
            }
            else -> cond.uppercase()
        }
    }

    fun isLoopOpen(token: String) =
        token.startsWith("repeat:") || token.startsWith("if:")
    fun isLoopClose(token: String) = token == "end"

    /**
     * How far each row is indented, so the steps inside a loop sit visibly
     * inside it. Returns one depth per token.
     */
    fun depths(program: List<String>): List<Int> {
        var d = 0
        return program.map { t ->
            when {
                isLoopClose(t) -> { d = (d - 1).coerceAtLeast(0); d }
                // OR ELSE belongs to the IF above it, so it lines up with it
                // rather than with the steps it guards.
                t == "else" -> (d - 1).coerceAtLeast(0)
                isLoopOpen(t) -> { val here = d; d++; here }
                else -> d
            }
        }
    }

    /** For chips too narrow for the full wording — the bank and option rows. */
    /**
     * The compact form for an option card, where a whole program has to fit on
     * one line beside two or three others.
     *
     * "DO 2 TIMES" is fine as a row of its own but far too wide as a chip — it
     * ran straight into the chip beside it. A loop reads as x2 here, which is
     * short enough to sit in a chip and still says how many times.
     */
    fun shortWord(token: String): String = when {
        token == "pick" -> "PICK"
        token == "end" -> "END"
        token == "else" -> "ELSE"
        token.startsWith("repeat:") -> "x" + token.substringAfter(':')
        token.startsWith("if:") -> "IF"
        token.startsWith("set:") || token.startsWith("add:") -> {
            val q = token.split(":")
            if (q.size == 3) {
                val n = q[2].toIntOrNull() ?: 0
                if (q[0] == "set") "=" + q[2] else (if (n < 0) "$n" else "+$n")
            } else token.uppercase()
        }
        else -> word(token)
    }

    /**
     * Draws one block's contents inside [box]: an arrow for a move, a word for
     * everything else. [color] is the ink; the caller owns the background.
     */
    /** DO N TIMES / OR ELSE / END / IF ... — the shape of the program, not a step. */
    private fun isScaffold(token: String) =
        isLoopOpen(token) || isLoopClose(token) || token == "else"

    fun paint(canvas: Canvas, box: RectF, token: String, fonts: Fonts, color: Int, ctx: Context) {
        val p = Paint(Paint.ANTI_ALIAS_FLAG)
        val text = word(token)
        p.color = color
        p.typeface = fonts.extra
        val cy = box.centerY()

        if (isScaffold(token)) {
            // Scaffolding is centred, which is what tells it apart from a step.
            p.textSize = ctx.dpf(if (text.length > 11) 11.5f else 13.5f)
            p.textAlign = Paint.Align.CENTER
            canvas.drawText(text, box.centerX(), cy - (p.descent() + p.ascent()) / 2f, p)
            return
        }

        // Every step starts at the same x whether or not it has an arrow.
        // PICK UP and ADD 3 TO COINS were centred while RIGHT sat on the left,
        // so a mixed list read as jumbled rather than as one column.
        if (token in ARROWS) {
            drawArrow(canvas, box.left + ctx.dpf(18f), cy, ctx.dpf(8f), token, color, ctx)
        }
        p.textSize = ctx.dpf(if (text.length > 12) 11.5f else 13.5f)
        p.textAlign = Paint.Align.LEFT
        canvas.drawText(text, box.left + ctx.dpf(31f),
            cy - (p.descent() + p.ascent()) / 2f, p)
    }

    fun drawArrow(
        canvas: Canvas, cx: Float, cy: Float, size: Float,
        token: String, color: Int, ctx: Context,
    ) {
        val p = Paint(Paint.ANTI_ALIAS_FLAG)
        p.color = color
        val path = Path()
        val (dx, dy) = when (token) {
            "up" -> 0f to -1f; "down" -> 0f to 1f
            "left" -> -1f to 0f; else -> 1f to 0f
        }
        // Head
        val hx = cx + dx * size; val hy = cy + dy * size
        val px = -dy; val py = dx // perpendicular
        path.moveTo(hx, hy)
        path.lineTo(cx + px * size * 0.72f, cy + py * size * 0.72f)
        path.lineTo(cx - px * size * 0.72f, cy - py * size * 0.72f)
        path.close()
        canvas.drawPath(path, p)
        // Tail
        p.strokeWidth = ctx.dpf(3.4f)
        p.strokeCap = Paint.Cap.ROUND
        canvas.drawLine(cx, cy, cx - dx * size, cy - dy * size, p)
    }
}

/**
 * The program listing shown beside the board: numbered blocks, top to bottom.
 *
 * It highlights the block currently running so "the program runs one line at a
 * time" is something a child watches rather than something they are told, and
 * it can be made tappable for the "which block fails?" questions.
 */
class ProgramListView(ctx: Context, private val fonts: Fonts) : View(ctx) {

    var program: List<String> = emptyList()
        set(v) { field = v; requestLayout(); invalidate() }

    /** Highlighted while that block runs; -1 for none. */
    var running = -1
        set(v) { field = v; invalidate() }

    var selectable = false
    var onBlockTap: ((Int) -> Unit)? = null

    private var selected = -1
    private var verdict: Int? = null

    private val fill = Paint(Paint.ANTI_ALIAS_FLAG)
    private val tp = Paint(Paint.ANTI_ALIAS_FLAG)
    private val box = RectF()

    fun select(i: Int) { selected = i; verdict = null; invalidate() }
    fun showVerdict(i: Int, correct: Boolean) {
        selected = i; verdict = if (correct) Ink.good else Ink.bad; invalidate()
    }
    fun clearVerdict() { verdict = null; invalidate() }
    fun reset() { selected = -1; verdict = null; running = -1; invalidate() }

    /** Screen point of row [i], for the on-device test driver. */
    fun rowOnScreen(i: Int): IntArray {
        val loc = IntArray(2); getLocationOnScreen(loc)
        return intArrayOf(loc[0] + width / 2,
            loc[1] + (i * (rowH + gap)) + rowH / 2)
    }

    /**
     * A demo's listing is read, not tapped, so its rows can be tighter — and
     * every dp saved there goes to the board, which is the thing being watched.
     */
    var compact = false
        set(v) { field = v; requestLayout(); invalidate() }

    private val rowH get() = if (compact) dp(34) else dp(44)
    private val gap get() = if (compact) dp(6) else dp(8)

    /**
     * A fixed column on the left for the row numbers.
     *
     * The numbers used to be drawn at a fixed x while the row box moved right
     * when indented, so on any loop body the number sat on the box edge or
     * outside it. Giving the numbers their own gutter keeps them in one clean
     * column and lets indentation happen entirely inside the box area.
     */
    private val gutter get() = dp(17)

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        val w = MeasureSpec.getSize(widthSpec)
        val h = if (program.isEmpty()) 0
        else program.size * rowH + (program.size - 1) * gap + dp(2)
        setMeasuredDimension(w, h)
    }

    override fun onDraw(canvas: Canvas) {
        val rad = context.dpf(12f)
        val depth = Blocks.depths(program)
        val indent = context.dpf(9f)
        program.forEachIndexed { i, token ->
            val top = (i * (rowH + gap)).toFloat()
            box.set(gutter + depth[i] * indent, top, width.toFloat(), top + rowH)

            val active = i == running
            val chosen = i == selected
            // IF / DO / OR ELSE / END are scaffolding, not moves. They all
            // share a ground so the shape of the program reads at a glance.
            val loopRow = Blocks.isLoopOpen(token) || Blocks.isLoopClose(token) ||
                token == "else"
            val face = when {
                verdict != null && chosen -> if (verdict == Ink.good) Ink.goodWash else Ink.badWash
                chosen -> 0xFFEDE6FF.toInt()
                active -> 0xFFFFF3CC.toInt()
                // Loop rows are scaffolding, not moves — a different ground
                // makes "these steps are inside it" readable at a glance.
                loopRow -> 0xFFF3EFFF.toInt()
                else -> Ink.surface
            }
            fill.color = face
            canvas.drawRoundRect(box, rad, rad, fill)

            val edge = when {
                verdict != null && chosen -> verdict!!
                chosen -> Ink.primary
                active -> Ink.accent
                else -> Ink.line
            }
            fill.style = Paint.Style.STROKE
            fill.strokeWidth = context.dpf(if (chosen || active) 2.5f else 1.5f)
            fill.color = edge
            canvas.drawRoundRect(box, rad, rad, fill)
            fill.style = Paint.Style.FILL

            // Row number, in its own gutter to the left of every box.
            tp.color = Ink.muted
            tp.typeface = fonts.body
            tp.textSize = context.dpf(12f)
            tp.textAlign = Paint.Align.CENTER
            canvas.drawText("${i + 1}", gutter / 2f,
                box.centerY() - (tp.descent() + tp.ascent()) / 2f, tp)

            val inner = RectF(box.left + context.dpf(8f), box.top, box.right, box.bottom)
            Blocks.paint(canvas, inner, token, fonts,
                if (loopRow) Ink.primary else Ink.text, context)
        }
    }

    override fun onTouchEvent(e: MotionEvent): Boolean {
        if (!selectable || program.isEmpty()) return false
        if (e.action != MotionEvent.ACTION_UP) return true
        @Suppress("UnnecessaryVariable")
        val i = (e.y / (rowH + gap)).toInt()
        if (i in program.indices) { performClick(); select(i); onBlockTap?.invoke(i) }
        return true
    }

    override fun performClick(): Boolean = super.performClick()
}

/**
 * The answer bank for "build the program" questions: a row of empty slots above
 * a tray of blocks.
 *
 * Blocks are placed by TAPPING, not dragging. On a phone held by a seven year
 * old a drag misses far more often than it lands, and a missed drag reads as the
 * app being broken rather than the answer being wrong.
 */
class BlockBankView(
    ctx: Context,
    private val fonts: Fonts,
) : LinearLayout(ctx) {

    private val slotRow = LinearLayout(ctx).apply { orientation = HORIZONTAL }
    private val trayRow = LinearLayout(ctx).apply { orientation = HORIZONTAL }

    private var tray: List<String> = emptyList()
    private val placed = mutableListOf<Int>()   // indices into [tray], in slot order
    private var slots = 0
    private var locked = false

    /**
     * A palette rather than a hand: chips stay available after being placed, so
     * the child can use RIGHT four times. "Reach the flag in exactly 5 steps"
     * needs this; "put these five steps in order" must not have it.
     */
    private var reusable = false

    /** Fires whenever the filled-in program changes, so the caller can enable Check. */
    var onChange: ((List<String>) -> Unit)? = null

    init {
        orientation = VERTICAL
        addView(slotRow, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT))
        addView(trayRow, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
            topMargin = dp(14)
        })
    }

    fun setBlocks(blocks: List<String>, slotCount: Int, palette: Boolean = false) {
        tray = blocks
        slots = slotCount
        reusable = palette
        placed.clear()
        locked = false
        rebuild()
    }

    /** Screen point of tray chip [i], for the on-device test driver. */
    fun chipOnScreen(i: Int): IntArray {
        val v = trayRow.getChildAt(i) ?: return intArrayOf(-1, -1)
        val loc = IntArray(2); v.getLocationOnScreen(loc)
        return intArrayOf(loc[0] + v.width / 2, loc[1] + v.height / 2)
    }

    /** The program the child has built so far. */
    fun program(): List<String> = placed.map { tray[it] }

    fun complete(): Boolean = placed.size == slots

    fun lock() { locked = true; rebuild() }

    fun tintVerdict(correct: Boolean) {
        locked = true
        rebuild()
        for (i in 0 until slotRow.childCount) {
            (slotRow.getChildAt(i) as? PushButton)?.tint(
                if (correct) Ink.goodWash else Ink.badWash,
                if (correct) Ink.good else Ink.bad, Ink.text,
            )
        }
    }

    private fun chip(token: String?, ghost: Boolean): PushButton =
        PushButton(context, fonts).apply {
            face = if (ghost) 0x00000000 else Ink.surface
            ledgeColor = if (ghost) 0x00000000 else Ink.ledge
            radius = 12f
            depth = if (ghost) 0 else 4
            painter = { c, box ->
                val p = Paint(Paint.ANTI_ALIAS_FLAG)
                if (ghost) {
                    // Dashed outline so an empty slot reads as "something goes here".
                    p.style = Paint.Style.STROKE
                    p.strokeWidth = context.dpf(2f)
                    p.color = Ink.ledge
                    p.pathEffect = android.graphics.DashPathEffect(
                        floatArrayOf(context.dpf(6f), context.dpf(5f)), 0f
                    )
                    val inset = context.dpf(1.5f)
                    c.drawRoundRect(
                        RectF(box.left + inset, box.top + inset,
                              box.right - inset, box.bottom - inset),
                        context.dpf(12f), context.dpf(12f), p
                    )
                }
                if (token != null) {
                    if (token in Blocks.ARROWS) {
                        Blocks.drawArrow(c, box.centerX(), box.centerY() - context.dpf(5f),
                            context.dpf(8f), token, Ink.text, context)
                        p.reset(); p.isAntiAlias = true
                        p.color = Ink.muted
                        p.typeface = fonts.body
                        p.textSize = context.dpf(10f)
                        p.textAlign = Paint.Align.CENTER
                        c.drawText(Blocks.word(token), box.centerX(),
                            box.bottom - context.dpf(7f), p)
                    } else {
                        p.color = Ink.text
                        p.typeface = fonts.extra
                        p.textSize = context.dpf(12f)
                        p.textAlign = Paint.Align.CENTER
                        c.drawText(Blocks.shortWord(token), box.centerX(),
                            box.centerY() - (p.descent() + p.ascent()) / 2f, p)
                    }
                }
            }
        }

    private fun rebuild() {
        slotRow.removeAllViews()
        trayRow.removeAllViews()
        val h = dp(58)

        for (s in 0 until slots) {
            val idx = placed.getOrNull(s)
            val v = chip(idx?.let { tray[it] }, ghost = idx == null)
            if (idx != null && !locked) v.onTap = { placed.removeAt(s); rebuild(); emit() }
            slotRow.addView(v, LayoutParams(0, h, 1f).apply {
                marginStart = if (s == 0) 0 else dp(6)
            })
        }

        tray.indices.forEach { i ->
            val used = !reusable && placed.contains(i)
            val full = placed.size >= slots
            val v = chip(tray[i], ghost = false)
            v.enabledLook = !used && !locked && !full
            if (!used && !locked) v.onTap = {
                if (placed.size < slots) { placed.add(i); rebuild(); emit() }
            }
            trayRow.addView(v, LayoutParams(0, h, 1f).apply {
                marginStart = if (i == 0) 0 else dp(6)
            })
        }
    }

    private fun emit() = onChange?.invoke(program())
}

/** Small helper so option rows and answer grids stack the same way everywhere. */
fun column(ctx: Context, gapDp: Int = 10): LinearLayout = LinearLayout(ctx).apply {
    orientation = LinearLayout.VERTICAL
    gravity = Gravity.CENTER_HORIZONTAL
    layoutParams = ViewGroup.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT
    )
    tag = gapDp
}


/**
 * A trace table: what is inside a named box after every step.
 *
 * This is the habit the unit is really teaching — when a program confuses you,
 * write down what each box holds at each step and the bug stops hiding. One row
 * is left blank for the child to work out.
 */
class TraceTableView(ctx: Context, private val fonts: Fonts) : View(ctx) {

    /** Row labels, one per step, in order. */
    var steps: List<String> = emptyList()
        set(v) { field = v; requestLayout(); invalidate() }

    /** The value after each step. Same length as [steps]. */
    var values: List<Int> = emptyList()
        set(v) { field = v; invalidate() }

    /** The row whose value is hidden, or -1 to show them all. */
    var gapRow = -1
        set(v) { field = v; invalidate() }

    var boxName = "COINS"

    private val fill = Paint(Paint.ANTI_ALIAS_FLAG)
    private val tp = Paint(Paint.ANTI_ALIAS_FLAG)
    private val r = RectF()

    private val rowH get() = dp(40)
    private val headH get() = dp(34)

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        val w = MeasureSpec.getSize(widthSpec)
        setMeasuredDimension(w, headH + steps.size * rowH + dp(4))
    }

    override fun onDraw(canvas: Canvas) {
        if (steps.isEmpty()) return
        val rad = context.dpf(14f)
        val split = width * 0.62f

        // Card
        fill.color = Ink.surface
        r.set(0f, 0f, width.toFloat(), (headH + steps.size * rowH).toFloat())
        canvas.drawRoundRect(r, rad, rad, fill)
        fill.style = Paint.Style.STROKE
        fill.strokeWidth = context.dpf(2f)
        fill.color = Ink.line
        canvas.drawRoundRect(r, rad, rad, fill)
        fill.style = Paint.Style.FILL

        // Header
        tp.typeface = fonts.black
        tp.textSize = context.dpf(11.5f)
        tp.color = Ink.muted
        tp.textAlign = Paint.Align.LEFT
        canvas.drawText("STEP", context.dpf(14f), headH * 0.66f, tp)
        tp.textAlign = Paint.Align.CENTER
        canvas.drawText(boxName, split + (width - split) / 2f, headH * 0.66f, tp)

        steps.forEachIndexed { i, label ->
            val top = headH + i * rowH.toFloat()
            if (i > 0) {
                fill.color = Ink.line
                canvas.drawRect(context.dpf(10f), top,
                    width - context.dpf(10f), top + context.dpf(1f), fill)
            }
            tp.typeface = fonts.body
            tp.textSize = context.dpf(13f)
            tp.color = Ink.text
            tp.textAlign = Paint.Align.LEFT
            canvas.drawText(label, context.dpf(14f),
                top + rowH * 0.5f - (tp.descent() + tp.ascent()) / 2f, tp)

            val cx = split + (width - split) / 2f
            if (i == gapRow) {
                // The blank the child fills in.
                fill.color = 0xFFF3EFFF.toInt()
                r.set(split + context.dpf(12f), top + context.dpf(6f),
                    width - context.dpf(14f), top + rowH - context.dpf(6f))
                canvas.drawRoundRect(r, context.dpf(9f), context.dpf(9f), fill)
                fill.style = Paint.Style.STROKE
                fill.strokeWidth = context.dpf(2f)
                fill.color = Ink.primary
                canvas.drawRoundRect(r, context.dpf(9f), context.dpf(9f), fill)
                fill.style = Paint.Style.FILL
                tp.typeface = fonts.black
                tp.color = Ink.primary
                tp.textAlign = Paint.Align.CENTER
                canvas.drawText("?", cx, top + rowH * 0.5f -
                    (tp.descent() + tp.ascent()) / 2f, tp)
            } else {
                tp.typeface = fonts.extra
                tp.textSize = context.dpf(15f)
                tp.color = Ink.text
                tp.textAlign = Paint.Align.CENTER
                canvas.drawText(
                    values.getOrElse(i) { 0 }.toString(), cx,
                    top + rowH * 0.5f - (tp.descent() + tp.ascent()) / 2f, tp
                )
            }
        }
    }
}


/**
 * The named boxes and the numbers inside them.
 *
 * A variables lesson without this on screen is a blank grid and a motionless
 * owl: the one thing the lesson is about — the number changing — is invisible.
 * The value ticks over as the demo steps through the rows, which is the whole
 * idea made watchable.
 */
class BoxesView(ctx: Context, private val fonts: Fonts) : View(ctx) {

    var boxes: List<Pair<String, Int>> = emptyList()
        set(v) { field = v; requestLayout(); invalidate() }

    private val fill = Paint(Paint.ANTI_ALIAS_FLAG)
    private val tp = Paint(Paint.ANTI_ALIAS_FLAG)
    private val r = RectF()

    private val boxH get() = dp(84)

    override fun onMeasure(widthSpec: Int, heightSpec: Int) {
        setMeasuredDimension(MeasureSpec.getSize(widthSpec), boxH + dp(4))
    }

    override fun onDraw(canvas: Canvas) {
        if (boxes.isEmpty()) return
        val gap = context.dpf(12f)
        val w = (width - gap * (boxes.size - 1)) / boxes.size
        val rad = context.dpf(18f)
        boxes.forEachIndexed { i, (name, value) ->
            val left = i * (w + gap)
            r.set(left, 0f, left + w, boxH.toFloat())
            fill.color = Ink.surface
            canvas.drawRoundRect(r, rad, rad, fill)
            fill.style = Paint.Style.STROKE
            fill.strokeWidth = context.dpf(2.5f)
            fill.color = Ink.primary
            canvas.drawRoundRect(r, rad, rad, fill)
            fill.style = Paint.Style.FILL

            tp.textAlign = Paint.Align.CENTER
            tp.typeface = fonts.black
            tp.color = Ink.muted
            tp.textSize = context.dpf(12f)
            tp.letterSpacing = 0.1f
            canvas.drawText(name, r.centerX(), r.top + context.dpf(24f), tp)
            tp.letterSpacing = 0f

            tp.color = Ink.primary
            tp.textSize = context.dpf(30f)
            canvas.drawText("$value", r.centerX(), r.bottom - context.dpf(18f), tp)
        }
    }
}
