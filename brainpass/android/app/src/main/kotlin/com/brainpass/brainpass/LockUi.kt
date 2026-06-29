package com.brainpass.brainpass

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.GridLayout
import android.widget.LinearLayout
import android.widget.TextView

/**
 * The kid-facing lock, rendered ENTIRELY as native Android views inside the
 * guard's overlay window (no Flutter, no launched Activity). An overlay only
 * needs "Draw over other apps", which works on every phone — so this is the
 * universal lock (no per-OEM background-launch permission).
 *
 * Mirrors lib/screens/earn_screen.dart: star progress, a big question card,
 * numeric keypad (math/pattern) or 3 option buttons (GK), gentle wrong-answer
 * handling (reveal answer, new question, no star lost), a discreet "Parent" PIN
 * bypass, and the "all done for today" screen.
 */
class LockUi(
    private val ctx: Context,
    private val mode: String, // "earn" | "done"
    private val band: Band,
    private val target: Int,
    private val minutes: Int,
    private val onEarned: () -> Unit,
    private val onOverride: () -> Unit,
) {
    // colors
    private val kidTop = 0xFF6D8BFF.toInt()
    private val kidBottom = 0xFF8E6CFF.toInt()
    private val correct = 0xFF2FBF71.toInt()
    private val wrong = 0xFFFF6B6B.toInt()
    private val accent = 0xFFFFC83D.toInt()
    private val textDark = 0xFF1F2333.toInt()
    private val bgGrey = 0xFFF6F7FB.toInt()

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

    val root: FrameLayout = FrameLayout(ctx).apply {
        background = GradientDrawable(
            GradientDrawable.Orientation.TOP_BOTTOM, intArrayOf(kidTop, kidBottom)
        )
    }

    init {
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

    // ---- EARN ----
    private fun buildEarn() {
        val col = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(20), dp(52), dp(20), dp(24))
        }
        starsRow = LinearLayout(ctx).apply { gravity = Gravity.CENTER }
        col.addView(starsRow)
        col.addView(TextView(ctx).apply {
            text = "Solve $target to play!"
            setTextColor(Color.WHITE); textSize = 18f
            setPadding(0, dp(6), 0, 0)
        })
        contentCol = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
        }
        col.addView(contentCol, LinearLayout.LayoutParams(match, 0, 1f))
        root.addView(col, FrameLayout.LayoutParams(match, match))
        renderQuestion()
    }

    private fun renderStars() {
        val row = starsRow ?: return
        row.removeAllViews()
        for (i in 0 until target) {
            row.addView(TextView(ctx).apply {
                text = if (i < solved) "★" else "☆"
                setTextColor(accent); textSize = 32f
                setPadding(dp(4), 0, dp(4), 0)
            })
        }
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
            background = rounded(Color.WHITE, dp(28))
            setPadding(dp(24), dp(24), dp(24), dp(24))
        }
        card.addView(TextView(ctx).apply {
            text = current.prompt
            setTextColor(textDark); textSize = 32f
            setTypeface(null, Typeface.BOLD)
            gravity = Gravity.CENTER
        })
        if (!current.isMultipleChoice) {
            typedView = TextView(ctx).apply {
                text = " "
                setTextColor(textDark); textSize = 28f
                setTypeface(null, Typeface.BOLD)
                gravity = Gravity.CENTER
                background = rounded(bgGrey, dp(16))
                setPadding(0, dp(12), 0, dp(12))
            }
            card.addView(typedView, LinearLayout.LayoutParams(match, wrap).apply { topMargin = dp(16) })
        }
        feedbackView = TextView(ctx).apply {
            text = ""; textSize = 15f; gravity = Gravity.CENTER
            setPadding(0, dp(10), 0, 0)
            visibility = View.GONE
        }
        card.addView(feedbackView)

        val cardWrap = LinearLayout(ctx).apply { gravity = Gravity.CENTER }
        cardWrap.addView(card, LinearLayout.LayoutParams(match, wrap))
        col.addView(spacer())
        col.addView(cardWrap, LinearLayout.LayoutParams(match, wrap))
        col.addView(spacer())

        // input area
        if (current.isMultipleChoice) col.addView(buildOptions()) else col.addView(buildKeypad())
    }

    private fun buildKeypad(): View {
        val grid = GridLayout(ctx).apply { columnCount = 3 }
        val keys = listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "del", "0", "ok")
        for (k in keys) {
            val btn = TextView(ctx).apply {
                gravity = Gravity.CENTER
                textSize = if (k.length > 1) 18f else 26f
                setTypeface(null, Typeface.BOLD)
                text = when (k) { "del" -> "⌫"; "ok" -> "✓"; else -> k }
                setTextColor(if (k == "ok") Color.WHITE else textDark)
                background = rounded(if (k == "ok") correct else Color.WHITE, dp(18))
                setOnClickListener { if (!busy) onKey(k) }
            }
            val lp = GridLayout.LayoutParams().apply {
                width = 0; columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f)
                height = dp(56)
                setMargins(dp(5), dp(5), dp(5), dp(5))
            }
            grid.addView(btn, lp)
        }
        return grid
    }

    private fun buildOptions(): View {
        val box = LinearLayout(ctx).apply { orientation = LinearLayout.VERTICAL }
        for (opt in current.options ?: emptyList()) {
            box.addView(TextView(ctx).apply {
                text = opt
                gravity = Gravity.CENTER; textSize = 20f
                setTypeface(null, Typeface.BOLD)
                setTextColor(textDark)
                background = rounded(Color.WHITE, dp(18))
                setPadding(0, dp(18), 0, dp(18))
                setOnClickListener { if (!busy) submit(opt) }
            }, LinearLayout.LayoutParams(match, wrap).apply { setMargins(0, dp(7), 0, dp(7)) })
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
            renderStars()
            if (solved >= target) {
                feedback("You earned your time! 🎉", correct)
                handler.postDelayed({ onEarned() }, 1100)
            } else {
                feedback("Great job! 🎉", correct)
                handler.postDelayed({ busy = false; nextQuestion() }, 650)
            }
        } else {
            busy = true
            feedback("Try again — the answer was ${current.answer}", wrong)
            handler.postDelayed({ busy = false; nextQuestion() }, 1400)
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

    // ---- DONE FOR TODAY ----
    private fun buildDone() {
        val col = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(28), dp(28), dp(28), dp(28))
        }
        col.addView(TextView(ctx).apply { text = "🌙"; textSize = 64f; gravity = Gravity.CENTER })
        col.addView(TextView(ctx).apply {
            text = "All done for today!"
            setTextColor(Color.WHITE); textSize = 28f
            setTypeface(null, Typeface.BOLD); gravity = Gravity.CENTER
            setPadding(0, dp(16), 0, dp(8))
        })
        col.addView(TextView(ctx).apply {
            text = "You've used all your screen time.\nSee you tomorrow! 👋"
            setTextColor(Color.WHITE); textSize = 17f; gravity = Gravity.CENTER
        })
        root.addView(col, FrameLayout.LayoutParams(match, match))
    }

    // ---- PARENT PIN ENTRY ----
    private fun showPinEntry() {
        val overlay = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            background = GradientDrawable(
                GradientDrawable.Orientation.TOP_BOTTOM, intArrayOf(kidTop, kidBottom)
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
        // Every cell (including the blank bottom-left) uses identical weighted
        // params, so all 3 columns are equal width — a placeholder with a fixed
        // width was collapsing the first column.
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
            }, cellLp())
        }
        overlay.addView(grid, LinearLayout.LayoutParams(match, wrap).apply { topMargin = dp(16) })
        // a small back chip
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
}
