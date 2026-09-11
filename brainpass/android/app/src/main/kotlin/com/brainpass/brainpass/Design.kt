package com.brainpass.brainpass

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.TextView

/**
 * The visual language of the kid-facing gate.
 *
 * The old gate was a purple gradient with floating bubbles and text floating on
 * top of it. This is the opposite: a light, flat ground so the puzzle itself is
 * the only thing with colour, and controls that read as physical objects — a
 * solid face sitting on a darker ledge that compresses when pressed. That is
 * what makes Duolingo and Brilliant feel tactile rather than decorated.
 *
 * Everything here is drawn in code. The gate runs in the guard's overlay window,
 * so there is no Activity, no theme, and no XML to inflate.
 */
object Ink {
    // Ground
    val bg = 0xFFF6F7FB.toInt()
    val surface = 0xFFFFFFFF.toInt()
    val line = 0xFFE3E6F0.toInt()
    val ledge = 0xFFD3D8E6.toInt()

    // Type
    val text = 0xFF181B26.toInt()
    val muted = 0xFF757B8C.toInt()

    // Brand
    val primary = 0xFF7A50F0.toInt()
    val primaryLedge = 0xFF5E36CC.toInt()
    val accent = 0xFFFDC703.toInt()
    val accentLedge = 0xFFD9A600.toInt()

    // Verdict
    val good = 0xFF2FBF71.toInt()
    val goodLedge = 0xFF23994F.toInt()
    val goodWash = 0xFFE6F8EE.toInt()
    val bad = 0xFFFF5C5C.toInt()
    val badLedge = 0xFFD93B3B.toInt()
    val badWash = 0xFFFFECEC.toInt()

    // Board pieces
    val tile = 0xFFFFFFFF.toInt()
    val tileAlt = 0xFFF0F2F9.toInt()
    val wall = 0xFF9AA1B5.toInt()
    val wallTop = 0xFFB4BACB.toInt()
    val trail = 0xFFB9A6F5.toInt()
}

/** Nunito, loaded from the Flutter bundle so the gate matches the brand. */
class Fonts(private val ctx: Context) {
    private fun load(name: String) = runCatching {
        Typeface.createFromAsset(ctx.assets, "flutter_assets/assets/fonts/$name")
    }.getOrNull()

    val bold = load("Nunito-Bold.ttf") ?: Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
    val extra = load("Nunito-ExtraBold.ttf") ?: bold
    val black = load("Nunito-Black.ttf") ?: bold
    val body = load("Nunito-SemiBold.ttf") ?: Typeface.DEFAULT
}

fun View.dp(v: Int): Int = (v * resources.displayMetrics.density).toInt()
fun Context.dpf(v: Float): Float = v * resources.displayMetrics.density

/** A rounded solid fill, optionally outlined. */
fun roundRect(color: Int, radius: Float, strokeColor: Int? = null, strokeWidth: Int = 0) =
    GradientDrawable().apply {
        shape = GradientDrawable.RECTANGLE
        cornerRadius = radius
        setColor(color)
        if (strokeColor != null) setStroke(strokeWidth, strokeColor)
    }

/**
 * A chunky pressable control: a coloured face resting on a darker ledge. On
 * press the face slides down onto the ledge, which is the whole trick — the
 * button feels like a key rather than a rectangle.
 *
 * Used for every tappable thing in the gate: answers, options, the run button
 * and the continue bar, so pressing anything feels the same.
 */
class PushButton(
    ctx: Context,
    private val fonts: Fonts,
) : View(ctx) {

    var label: String = ""
        set(v) { field = v; invalidate() }

    /** Secondary line under the label, used by option cards. */
    var sub: String? = null
        set(v) { field = v; invalidate() }

    var face = Ink.surface
    var ledgeColor = Ink.ledge
    var textColor = Ink.text
    var textSize = 18f
    var radius = 16f
    var depth = 5
    var enabledLook = true
        set(v) { field = v; alpha = if (v) 1f else 0.45f; invalidate() }

    /** Draws content instead of the label — the board pieces and block glyphs. */
    var painter: ((Canvas, RectF) -> Unit)? = null

    var onTap: (() -> Unit)? = null

    private var pressed = false
    private val fill = Paint(Paint.ANTI_ALIAS_FLAG)
    private val tp = Paint(Paint.ANTI_ALIAS_FLAG).apply { textAlign = Paint.Align.CENTER }
    private val r = RectF()

    init {
        isClickable = true
        setOnTouchListener { _, e ->
            if (!enabledLook) return@setOnTouchListener false
            when (e.action) {
                MotionEvent.ACTION_DOWN -> { pressed = true; invalidate() }
                MotionEvent.ACTION_CANCEL -> { pressed = false; invalidate() }
                MotionEvent.ACTION_UP -> {
                    val inside = e.x >= 0 && e.y >= 0 && e.x <= width && e.y <= height
                    pressed = false; invalidate()
                    if (inside) onTap?.invoke()
                }
            }
            true
        }
    }

    override fun onDraw(canvas: Canvas) {
        val d = dp(depth).toFloat()
        val rad = context.dpf(radius)
        val drop = if (pressed) d else 0f

        // Ledge: the full body, visible as a lip under the face.
        fill.color = ledgeColor
        r.set(0f, 0f, width.toFloat(), height.toFloat())
        canvas.drawRoundRect(r, rad, rad, fill)

        // Face
        fill.color = face
        r.set(0f, drop, width.toFloat(), height - d + drop)
        canvas.drawRoundRect(r, rad, rad, fill)

        val p = painter
        if (p != null) { p(canvas, r); return }

        tp.color = textColor
        tp.typeface = fonts.extra
        tp.textSize = context.dpf(textSize)
        val cx = width / 2f
        if (sub == null) {
            canvas.drawText(label, cx, r.centerY() - (tp.descent() + tp.ascent()) / 2f, tp)
        } else {
            val gap = context.dpf(2f)
            val h1 = -(tp.descent() + tp.ascent())
            canvas.drawText(label, cx, r.centerY() - gap, tp)
            tp.typeface = fonts.body
            tp.textSize = context.dpf(13f)
            tp.color = Ink.muted
            canvas.drawText(sub!!, cx, r.centerY() + h1 - gap, tp)
        }
    }

    /** Repaint in a verdict colour without changing layout. */
    fun tint(faceColor: Int, ledge: Int, text: Int = Color.WHITE) {
        face = faceColor; ledgeColor = ledge; textColor = text; invalidate()
    }
}

/** A TextView preset for the gate. */
fun label(
    ctx: Context, fonts: Fonts, text: String, size: Float,
    color: Int = Ink.text, black: Boolean = false, align: Int = android.view.Gravity.START,
): TextView = TextView(ctx).apply {
    this.text = text
    setTextColor(color)
    textSize = size
    typeface = if (black) fonts.black else fonts.extra
    gravity = align
    includeFontPadding = false
    layoutParams = ViewGroup.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT
    )
}
