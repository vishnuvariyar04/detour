package com.brainpass.brainpass

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.view.View
import android.widget.ImageView
import android.widget.LinearLayout

/**
 * The lesson's chrome, October 2026: the pieces around a question rather than
 * the question itself — the owl that asks it, the speech bubble it asks in, the
 * light bulb on the hint, and the badge on a verdict.
 *
 * Duolingo and Brilliant both put a character beside the prompt and keep help
 * docked by the answer rather than pushing the question down, and that is the
 * pattern here. Nothing in this file decides what is right or wrong.
 */
object Mascot {
    private val cache = HashMap<String, Bitmap?>()

    /** One of the owl poses bundled for the Flutter app (assets/nupo/<pose>.png). */
    fun bitmap(ctx: Context, pose: String): Bitmap? = cache.getOrPut(pose) {
        runCatching {
            ctx.assets.open("flutter_assets/assets/nupo/$pose.png")
                .use { BitmapFactory.decodeStream(it) }
        }.getOrNull()
    }

    fun view(ctx: Context, pose: String, widthDp: Int): ImageView = ImageView(ctx).apply {
        bitmap(ctx, pose)?.let { setImageBitmap(it) }
        adjustViewBounds = true
        scaleType = ImageView.ScaleType.FIT_CENTER
        layoutParams = LinearLayout.LayoutParams(
            (widthDp * ctx.resources.displayMetrics.density).toInt(),
            LinearLayout.LayoutParams.WRAP_CONTENT,
        )
    }
}

/**
 * A white speech bubble with a tail pointing left at the owl. Content goes in
 * as children; the bubble is drawn behind them.
 */
class SpeechBubble(ctx: Context) : LinearLayout(ctx) {
    private val tail = ctx.dpf(9f)
    private val fill = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Ink.surface }
    private val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Ink.line
        style = Paint.Style.STROKE
        strokeWidth = ctx.dpf(2f)
        strokeJoin = Paint.Join.ROUND
    }
    private val path = Path()
    private val r = RectF()

    init {
        orientation = VERTICAL
        setWillNotDraw(false)
        val d = ctx.resources.displayMetrics.density
        setPadding((tail + 14 * d).toInt(), (12 * d).toInt(), (14 * d).toInt(), (13 * d).toInt())
    }

    override fun onDraw(canvas: Canvas) {
        val s = stroke.strokeWidth / 2
        val rad = context.dpf(18f)
        r.set(tail + s, s, width - s, height - s)
        path.reset()
        path.addRoundRect(r, rad, rad, Path.Direction.CW)
        // The tail, low on the left edge, where the owl's beak is.
        val ty = minOf(height * 0.5f, context.dpf(30f))
        val tailPath = Path().apply {
            moveTo(tail + s + 1, ty - context.dpf(8f))
            lineTo(s, ty + context.dpf(2f))
            lineTo(tail + s + 1, ty + context.dpf(8f))
            close()
        }
        path.op(tailPath, Path.Op.UNION)
        canvas.drawPath(path, fill)
        canvas.drawPath(path, stroke)
    }
}

/** A small yellow light bulb: the sign for a hint everywhere in the lesson. */
object Bulb {
    private val p = Paint(Paint.ANTI_ALIAS_FLAG)

    /** Draws a bulb of height [h] whose centre is ([cx], [cy]). */
    fun draw(c: Canvas, cx: Float, cy: Float, h: Float, glass: Int = Ink.accent) {
        val r = h * 0.34f
        val top = cy - h / 2
        p.style = Paint.Style.FILL
        p.color = glass
        c.drawCircle(cx, top + r, r, p)
        // the neck narrowing into the base
        val neck = Path().apply {
            moveTo(cx - r * 0.75f, top + r * 1.5f)
            lineTo(cx + r * 0.75f, top + r * 1.5f)
            lineTo(cx + r * 0.5f, top + h * 0.78f)
            lineTo(cx - r * 0.5f, top + h * 0.78f)
            close()
        }
        c.drawPath(neck, p)
        p.color = 0xFF6B6F80.toInt()
        val bw = r * 1.0f
        c.drawRoundRect(cx - bw / 2, top + h * 0.8f, cx + bw / 2, top + h, h * 0.06f, h * 0.06f, p)
        // a highlight on the glass
        p.color = 0x99FFFFFF.toInt()
        c.drawCircle(cx - r * 0.35f, top + r * 0.75f, r * 0.28f, p)
    }
}

/** A bulb on its own, for rows built from views. */
class BulbView(ctx: Context) : View(ctx) {
    override fun onDraw(canvas: Canvas) =
        Bulb.draw(canvas, width / 2f, height / 2f, height.toFloat())
}

/** The round mark on a verdict: a tick for right, a cross for not yet. */
class VerdictBadge(ctx: Context, private val correct: Boolean) : View(ctx) {
    private val p = Paint(Paint.ANTI_ALIAS_FLAG)

    override fun onDraw(canvas: Canvas) {
        val w = width.toFloat()
        p.style = Paint.Style.FILL
        p.color = if (correct) Ink.goodLedge else Ink.badLedge
        canvas.drawCircle(w / 2, w / 2 + context.dpf(1.5f), w / 2 - context.dpf(1.5f), p)
        p.color = if (correct) Ink.good else Ink.bad
        canvas.drawCircle(w / 2, w / 2 - context.dpf(1f), w / 2 - context.dpf(1.5f), p)
        p.color = 0xFFFFFFFF.toInt()
        p.style = Paint.Style.STROKE
        p.strokeWidth = w * 0.12f
        p.strokeCap = Paint.Cap.ROUND
        p.strokeJoin = Paint.Join.ROUND
        val c = w / 2
        val y = c - context.dpf(1f)
        if (correct) {
            val path = Path().apply {
                moveTo(c - w * 0.2f, y)
                lineTo(c - w * 0.05f, y + w * 0.15f)
                lineTo(c + w * 0.22f, y - w * 0.13f)
            }
            canvas.drawPath(path, p)
        } else {
            val k = w * 0.16f
            canvas.drawLine(c - k, y - k, c + k, y + k, p)
            canvas.drawLine(c + k, y - k, c - k, y + k, p)
        }
    }
}

/** A thin cross, for closing the hint. */
class CloseMark(ctx: Context) : View(ctx) {
    private val p = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
        color = 0xFF8A6100.toInt()
    }

    override fun onDraw(canvas: Canvas) {
        p.strokeWidth = context.dpf(2.6f)
        val c = width / 2f
        val k = context.dpf(5.5f)
        canvas.drawLine(c - k, height / 2f - k, c + k, height / 2f + k, p)
        canvas.drawLine(c + k, height / 2f - k, c - k, height / 2f + k, p)
    }
}
