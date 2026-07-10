package com.brainpass.brainpass

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.animation.OvershootInterpolator
import android.widget.FrameLayout
import android.widget.GridLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView

/**
 * The kid-facing "learning moment", rendered ENTIRELY as native Android views
 * inside the guard's overlay window (no Flutter, no launched Activity). An
 * overlay only needs "Draw over other apps", which works on every phone.
 *
 * Framed as a GIFT, not a lock: a cheering owl, big bouncy stars, colourful
 * answer buttons, confetti-emoji celebrations on every correct answer, and a
 * gentle "try again" that never takes a star away. A discreet "Parent" PIN
 * bypass lives in the corner, and a happy "all done for today" screen closes it.
 */
@SuppressLint("ClickableViewAccessibility")
class LockUi(
    private val ctx: Context,
    private val mode: String, // "earn" | "done"
    private val band: Band,
    private val target: Int,
    private val minutes: Int,
    private val onEarned: () -> Unit,
    private val onOverride: () -> Unit,
) {
    // colours — bright and playful
    private val bgTop = 0xFF7A50F0.toInt()
    private val bgBottom = 0xFF4E86F7.toInt()
    private val correct = 0xFF2FBF71.toInt()
    private val wrong = 0xFFFF6B6B.toInt()
    private val accent = 0xFFFFC83D.toInt()
    private val accentDeep = 0xFFB98600.toInt()
    private val accentSoft = 0xFFFFF2CC.toInt()
    private val textDark = 0xFF1F2333.toInt()
    private val optionColors = intArrayOf(
        0xFFFF7A7A.toInt(), 0xFF35C9B0.toInt(), 0xFFFFB020.toInt(), 0xFF9B7BFF.toInt()
    )
    private val celebrateEmojis = listOf("🎉", "⭐", "🌟", "🚀", "✨", "🏆", "💫")

    private val handler = Handler(Looper.getMainLooper())
    private val plan = Questions.buildEarnPlan(target)
    private var solved = 0
    private var current = Questions.generateOne(band, plan.getOrElse(0) { QuestionKind.MATH })
    private var typed = ""
    private var busy = false // disable input during feedback/animation

    // live view refs
    private var starsRow: LinearLayout? = null
    private var contentCol: LinearLayout? = null
    private var typedView: TextView? = null
    private var feedbackView: TextView? = null
    private var cardView: View? = null
    private var owlView: ImageView? = null

    val root: FrameLayout = FrameLayout(ctx).apply {
        background = GradientDrawable(
            GradientDrawable.Orientation.TL_BR, intArrayOf(bgTop, bgBottom)
        )
    }

    init {
        addBubbles()
        if (mode == "done") buildDone() else buildEarn()
        // discreet parent link (top-right)
        root.addView(
            TextView(ctx).apply {
                text = "Parent"
                setTextColor(0xB3FFFFFF.toInt())
                textSize = 14f
                setPadding(dp(16), dp(14), dp(20), dp(14))
                setOnClickListener { showPinEntry() }
            },
            FrameLayout.LayoutParams(wrap, wrap).apply { gravity = Gravity.TOP or Gravity.END }
        )
    }

    /** Big translucent circles behind everything for a playful feel. */
    private fun addBubbles() {
        fun bubble(size: Int, alpha: Int, g: Int, mx: Int, my: Int) {
            root.addView(View(ctx).apply {
                background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL; setColor((alpha shl 24) or 0xFFFFFF)
                }
            }, FrameLayout.LayoutParams(dp(size), dp(size)).apply {
                gravity = g; setMargins(dp(mx), dp(my), dp(mx), dp(my))
            })
        }
        bubble(220, 0x1F, Gravity.TOP or Gravity.START, -60, -40)
        bubble(160, 0x1A, Gravity.BOTTOM or Gravity.END, -40, -20)
        bubble(90, 0x1A, Gravity.TOP or Gravity.END, 30, 120)
    }

    // ---- EARN ----
    private fun buildEarn() {
        val col = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(20), dp(44), dp(20), dp(24))
        }
        // Cheering owl
        owlBitmap()?.let { bmp ->
            owlView = ImageView(ctx).apply { setImageBitmap(bmp) }
            col.addView(owlView, LinearLayout.LayoutParams(dp(96), dp(96)))
        }
        col.addView(TextView(ctx).apply {
            text = "Here's your learning moment!"
            setTextColor(Color.WHITE); textSize = 20f
            setTypeface(null, Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(0, dp(6), 0, dp(10))
        })
        starsRow = LinearLayout(ctx).apply { gravity = Gravity.CENTER }
        col.addView(starsRow)
        contentCol = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
        }
        col.addView(contentCol, LinearLayout.LayoutParams(match, 0, 1f))
        root.addView(col, FrameLayout.LayoutParams(match, match))
        renderQuestion()
    }

    private fun renderStars(popLast: Boolean = false) {
        val row = starsRow ?: return
        row.removeAllViews()
        var lastFilled: TextView? = null
        for (i in 0 until target) {
            val tv = TextView(ctx).apply {
                text = if (i < solved) "★" else "☆"
                setTextColor(if (i < solved) accent else 0x66FFFFFF)
                textSize = 34f
                setPadding(dp(5), 0, dp(5), 0)
            }
            row.addView(tv)
            if (i == solved - 1) lastFilled = tv
        }
        if (popLast) lastFilled?.let { popIn(it) }
    }

    private fun renderQuestion() {
        renderStars()
        val col = contentCol ?: return
        col.removeAllViews()
        typed = ""

        // question card
        val card = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            background = rounded(Color.WHITE, dp(30))
            elevation = dp(8).toFloat()
            setPadding(dp(24), dp(22), dp(24), dp(24))
        }
        // "Question X of Y" pill
        card.addView(TextView(ctx).apply {
            text = "Question ${solved + 1} of $target"
            setTextColor(accentDeep); textSize = 13f
            setTypeface(null, Typeface.BOLD)
            background = rounded(accentSoft, dp(20))
            setPadding(dp(14), dp(6), dp(14), dp(6))
        })
        card.addView(TextView(ctx).apply {
            text = current.prompt
            setTextColor(textDark); textSize = 34f
            setTypeface(null, Typeface.BOLD)
            gravity = Gravity.CENTER
            setPadding(0, dp(16), 0, 0)
        })
        if (!current.isMultipleChoice) {
            typedView = TextView(ctx).apply {
                text = " "
                setTextColor(textDark); textSize = 30f
                setTypeface(null, Typeface.BOLD)
                gravity = Gravity.CENTER
                background = rounded(0xFFF2F1FA.toInt(), dp(16))
                setPadding(0, dp(12), 0, dp(12))
            }
            card.addView(typedView, LinearLayout.LayoutParams(match, wrap).apply { topMargin = dp(16) })
        }
        feedbackView = TextView(ctx).apply {
            text = ""; textSize = 16f; gravity = Gravity.CENTER
            setTypeface(null, Typeface.BOLD)
            setPadding(0, dp(12), 0, 0)
            visibility = View.GONE
        }
        card.addView(feedbackView)
        cardView = card

        val cardWrap = LinearLayout(ctx).apply { gravity = Gravity.CENTER }
        cardWrap.addView(card, LinearLayout.LayoutParams(match, wrap))
        col.addView(spacer())
        col.addView(cardWrap, LinearLayout.LayoutParams(match, wrap))
        col.addView(spacer())
        popIn(card)

        // input area
        if (current.isMultipleChoice) col.addView(buildOptions()) else col.addView(buildKeypad())
    }

    private fun buildKeypad(): View {
        val grid = GridLayout(ctx).apply { columnCount = 3 }
        val keys = listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "del", "0", "ok")
        for (k in keys) {
            val bg = when (k) { "ok" -> correct; "del" -> 0x33FFFFFF; else -> Color.WHITE }
            val btn = TextView(ctx).apply {
                gravity = Gravity.CENTER
                textSize = if (k.length > 1) 20f else 27f
                setTypeface(null, Typeface.BOLD)
                text = when (k) { "del" -> "⌫"; "ok" -> "✓"; else -> k }
                setTextColor(if (k == "ok" || k == "del") Color.WHITE else textDark)
                background = rounded(bg, dp(20))
                if (k != "del") elevation = dp(3).toFloat()
                setOnClickListener { if (!busy) onKey(k) }
                pressable(this)
            }
            val lp = GridLayout.LayoutParams().apply {
                width = 0; columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f)
                height = dp(58)
                setMargins(dp(6), dp(6), dp(6), dp(6))
            }
            grid.addView(btn, lp)
        }
        return grid
    }

    private fun buildOptions(): View {
        val box = LinearLayout(ctx).apply { orientation = LinearLayout.VERTICAL }
        (current.options ?: emptyList()).forEachIndexed { i, opt ->
            box.addView(TextView(ctx).apply {
                text = opt
                gravity = Gravity.CENTER; textSize = 21f
                setTypeface(null, Typeface.BOLD)
                setTextColor(Color.WHITE)
                background = rounded(optionColors[i % optionColors.size], dp(22))
                elevation = dp(4).toFloat()
                setPadding(0, dp(18), 0, dp(18))
                setOnClickListener { if (!busy) submit(opt) }
                pressable(this)
            }, LinearLayout.LayoutParams(match, wrap).apply { setMargins(0, dp(8), 0, dp(8)) })
        }
        return box
    }

    private fun onKey(k: String) {
        when (k) {
            "del" -> if (typed.isNotEmpty()) typed = typed.dropLast(1)
            "ok" -> { if (typed.isNotEmpty()) submit(typed); return }
            else -> if (typed.length < 6) typed += k
        }
        typedView?.text = if (typed.isEmpty()) " " else typed
    }

    private fun submit(given: String) {
        if (busy) return
        if (Questions.isCorrect(current, given)) {
            busy = true
            solved++
            renderStars(popLast = true)
            bounceOwl()
            celebrate()
            if (solved >= target) {
                feedback("You did it! 🎉", correct)
                handler.postDelayed({ onEarned() }, 1250)
            } else {
                feedback("Great job! 🎉", correct)
                handler.postDelayed({ busy = false; nextQuestion() }, 800)
            }
        } else {
            busy = true
            cardView?.let { shake(it) }
            feedback("Oops! It was ${current.answer} 🙈", wrong)
            handler.postDelayed({ busy = false; nextQuestion() }, 1500)
        }
    }

    private fun nextQuestion() {
        val idx = if (solved < plan.size) solved else plan.size - 1
        current = Questions.generateOne(band, plan[idx])
        renderQuestion()
    }

    private fun feedback(text: String, color: Int) {
        feedbackView?.apply {
            this.text = text
            setTextColor(color)
            visibility = View.VISIBLE
        }
    }

    // ---- celebrations / animations ----
    private fun celebrate() {
        val emoji = TextView(ctx).apply {
            text = celebrateEmojis.random()
            textSize = 92f
            gravity = Gravity.CENTER
        }
        root.addView(emoji, FrameLayout.LayoutParams(wrap, wrap).apply { gravity = Gravity.CENTER })
        emoji.scaleX = 0.3f; emoji.scaleY = 0.3f; emoji.alpha = 0f
        emoji.animate().scaleX(1.7f).scaleY(1.7f).alpha(1f)
            .setDuration(260).setInterpolator(OvershootInterpolator())
            .withEndAction {
                emoji.animate().alpha(0f).scaleX(2.1f).scaleY(2.1f)
                    .translationYBy(dp(-40).toFloat()).setDuration(420)
                    .withEndAction { try { root.removeView(emoji) } catch (_: Throwable) {} }
                    .start()
            }.start()
    }

    private fun popIn(v: View) {
        v.scaleX = 0.6f; v.scaleY = 0.6f
        v.animate().scaleX(1f).scaleY(1f).setDuration(300)
            .setInterpolator(OvershootInterpolator()).start()
    }

    private fun bounceOwl() {
        val v = owlView ?: return
        v.animate().scaleX(1.18f).scaleY(1.18f).rotationBy(6f).setDuration(140)
            .withEndAction {
                v.animate().scaleX(1f).scaleY(1f).rotation(0f).setDuration(160)
                    .setInterpolator(OvershootInterpolator()).start()
            }.start()
    }

    private fun shake(v: View) {
        val d = dp(14).toFloat()
        v.animate().translationX(-d).setDuration(60).withEndAction {
            v.animate().translationX(d).setDuration(70).withEndAction {
                v.animate().translationX(-d * 0.6f).setDuration(60).withEndAction {
                    v.animate().translationX(0f).setDuration(60).start()
                }.start()
            }.start()
        }.start()
    }

    // ---- DONE FOR TODAY ----
    private fun buildDone() {
        val col = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(28), dp(28), dp(28), dp(28))
        }
        owlBitmap()?.let { bmp ->
            col.addView(ImageView(ctx).apply { setImageBitmap(bmp) },
                LinearLayout.LayoutParams(dp(130), dp(130)).apply { bottomMargin = dp(4) })
        }
        col.addView(TextView(ctx).apply {
            text = "You're a star today! 🌟"
            setTextColor(Color.WHITE); textSize = 27f
            setTypeface(null, Typeface.BOLD); gravity = Gravity.CENTER
            setPadding(0, dp(8), 0, dp(8))
        })
        col.addView(TextView(ctx).apply {
            text = "Great learning today.\nSee you tomorrow! 👋"
            setTextColor(0xE6FFFFFF.toInt()); textSize = 17f; gravity = Gravity.CENTER
        })
        root.addView(col, FrameLayout.LayoutParams(match, match))
    }

    // ---- PARENT PIN ENTRY ----
    private fun showPinEntry() {
        val overlay = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            background = GradientDrawable(
                GradientDrawable.Orientation.TL_BR, intArrayOf(bgTop, bgBottom)
            )
            setPadding(dp(24), dp(24), dp(24), dp(24))
        }
        overlay.addView(TextView(ctx).apply {
            text = "Parent PIN"
            setTextColor(Color.WHITE); textSize = 22f
            setTypeface(null, Typeface.BOLD); gravity = Gravity.CENTER
            setPadding(0, 0, 0, dp(20))
        })
        val dots = TextView(ctx).apply {
            setTextColor(Color.WHITE); textSize = 28f; gravity = Gravity.CENTER
            text = "● ● ● ●".replace("●", "○")
        }
        overlay.addView(dots)
        val err = TextView(ctx).apply {
            setTextColor(0xFFFFE0E0.toInt()); textSize = 14f; gravity = Gravity.CENTER
            setPadding(0, dp(8), 0, dp(8))
        }
        overlay.addView(err)

        var pin = ""
        fun refresh() {
            dots.text = (0 until 4).joinToString(" ") { if (it < pin.length) "●" else "○" }
        }
        val grid = GridLayout(ctx).apply { columnCount = 3 }
        fun cellLp() = GridLayout.LayoutParams().apply {
            width = 0
            columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f)
            height = dp(54)
            setMargins(dp(6), dp(6), dp(6), dp(6))
        }
        for (k in listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "del")) {
            if (k.isEmpty()) { grid.addView(View(ctx), cellLp()); continue }
            grid.addView(TextView(ctx).apply {
                text = if (k == "del") "⌫" else k
                gravity = Gravity.CENTER; textSize = if (k == "del") 18f else 24f
                setTypeface(null, Typeface.BOLD); setTextColor(textDark)
                background = rounded(Color.WHITE, dp(16))
                setOnClickListener {
                    if (k == "del") { if (pin.isNotEmpty()) pin = pin.dropLast(1) }
                    else if (pin.length < 4) pin += k
                    refresh()
                    if (pin.length == 4) {
                        if (EnginePrefs.verifyPin(ctx, pin)) onOverride()
                        else { err.text = "Wrong PIN"; pin = ""; refresh() }
                    }
                }
                pressable(this)
            }, cellLp())
        }
        overlay.addView(grid, LinearLayout.LayoutParams(match, wrap).apply { topMargin = dp(16) })
        overlay.addView(TextView(ctx).apply {
            text = "← Back"
            setTextColor(0xCCFFFFFF.toInt()); textSize = 15f; gravity = Gravity.CENTER
            setPadding(0, dp(20), 0, 0)
            setOnClickListener { root.removeView(this.parent as View) }
        })
        refresh()
        root.addView(overlay, FrameLayout.LayoutParams(match, match))
    }

    // ---- helpers ----
    private val match get() = ViewGroup.LayoutParams.MATCH_PARENT
    private val wrap get() = ViewGroup.LayoutParams.WRAP_CONTENT
    private fun dp(v: Int): Int = (v * ctx.resources.displayMetrics.density).toInt()
    private fun spacer(): View = View(ctx).apply {
        layoutParams = LinearLayout.LayoutParams(match, 0, 1f)
    }
    private fun rounded(color: Int, radius: Int): GradientDrawable =
        GradientDrawable().apply { cornerRadius = radius.toFloat(); setColor(color) }

    private fun pressable(v: View) {
        v.setOnTouchListener { view, ev ->
            when (ev.actionMasked) {
                MotionEvent.ACTION_DOWN ->
                    view.animate().scaleX(0.93f).scaleY(0.93f).setDuration(80).start()
                MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL ->
                    view.animate().scaleX(1f).scaleY(1f).setDuration(120).start()
            }
            false
        }
    }

    private fun owlBitmap(): android.graphics.Bitmap? = try {
        ctx.assets.open("flutter_assets/assets/mascot_opening.png")
            .use { BitmapFactory.decodeStream(it) }
    } catch (_: Throwable) {
        null
    }
}
