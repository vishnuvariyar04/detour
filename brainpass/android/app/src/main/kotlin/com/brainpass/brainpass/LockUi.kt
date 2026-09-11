package com.brainpass.brainpass

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.media.AudioAttributes
import android.media.SoundPool
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
 * The kid-facing "learning moment" v2 — 100% native views in the guard's
 * overlay window (no Flutter, no Activity — works on every phone).
 *
 * v2 design: ten ways to answer (engine in Questions.kt), a session arc with a
 * Boss finale, streak combos, rotating affirmations, Nunito everywhere, and a
 * hand-drawn shape/tile visual system (ShapeTileView) instead of emoji —
 * stickers drop in later via flutter_assets/assets/stickers/<name>.png.
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
) : GateUi {
    // colours — bright and playful
    private val bgTop = 0xFF7A50F0.toInt()
    private val bgBottom = 0xFF4E86F7.toInt()
    private val correct = 0xFF2FBF71.toInt()
    private val wrong = 0xFFFF6B6B.toInt()
    private val accent = 0xFFFFC83D.toInt()
    private val textDark = 0xFF1F2333.toInt()
    private val optionColors = intArrayOf(
        0xFFFF7A7A.toInt(), 0xFF35C9B0.toInt(), 0xFFFFB020.toInt(), 0xFF9B7BFF.toInt()
    )
    private val celebrateEmojis = listOf("🎉", "⭐", "🌟", "🚀", "✨", "🏆", "💫")
    private val affirmations = listOf(
        "Smart thinking!", "Your brain is growing!", "Genius move!",
        "Brilliant!", "Super smart!", "Nailed it!", "Big brain energy!",
        "You're unstoppable!",
    )

    // Nunito from the Flutter bundle so the kid screen matches the brand.
    private val nunito: Typeface? = runCatching {
        Typeface.createFromAsset(ctx.assets, "flutter_assets/assets/fonts/Nunito-ExtraBold.ttf")
    }.getOrNull()
    private val nunitoBlack: Typeface? = runCatching {
        Typeface.createFromAsset(ctx.assets, "flutter_assets/assets/fonts/Nunito-Black.ttf")
    }.getOrNull()

    private fun TextView.brandFont(black: Boolean = false) {
        typeface = (if (black) nunitoBlack else nunito)
            ?: Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
    }

    private val handler = Handler(Looper.getMainLooper())
    private val session: List<Q> =
        if (mode == "earn") Questions.buildSession(ctx, band, target) else emptyList()
    private var index = 0
    private var solved = 0
    private var streak = 0
    private var current: Q? = session.getOrNull(0)
    private var typed = ""
    private var busy = false

    // Sound effects
    private var soundPool: SoundPool? = null
    private var successSoundId = 0
    private var tryAgainSoundId = 0
    private var bossSoundId = 0

    // live view refs
    private var starsRow: LinearLayout? = null
    private var contentCol: LinearLayout? = null
    private var typedView: TextView? = null
    private var feedbackView: TextView? = null
    private var cardView: View? = null
    private var owlView: ImageView? = null

    override val root: FrameLayout = FrameLayout(ctx).apply {
        background = GradientDrawable(
            GradientDrawable.Orientation.TL_BR, intArrayOf(bgTop, bgBottom)
        )
    }

    init {
        try {
            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
            // NOTE: compile-time R references, NOT getIdentifier() — the release
            // resource shrinker can't see reflective lookups and was stripping
            // the wav files out of the APK entirely (sounds silently vanished).
            soundPool = SoundPool.Builder().setMaxStreams(3).setAudioAttributes(attrs)
                .build().apply {
                    successSoundId = load(ctx, R.raw.nupo_success, 1)
                    tryAgainSoundId = load(ctx, R.raw.nupo_try_again, 1)
                    bossSoundId = load(ctx, R.raw.nupo_boss, 1)
                }
        } catch (_: Throwable) {
        }

        addBubbles()
        if (mode == "done") buildDone() else buildEarn()
        root.addView(
            TextView(ctx).apply {
                text = "Parent"
                setTextColor(0xB3FFFFFF.toInt()); textSize = 14f; brandFont()
                setPadding(dp(16), dp(14), dp(20), dp(14))
                setOnClickListener { showPinEntry() }
            },
            FrameLayout.LayoutParams(wrap, wrap).apply { gravity = Gravity.TOP or Gravity.END }
        )
    }

    private fun playSound(id: Int) {
        val pool = soundPool ?: return
        if (id != 0) runCatching { pool.play(id, 1f, 1f, 1, 0, 1f) }
    }

    override fun release() {
        runCatching { soundPool?.release() }
        soundPool = null
    }

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

    // ------------------------------------------------------------------ EARN
    private fun buildEarn() {
        val col = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(20), dp(40), dp(20), dp(20))
        }
        owlBitmap()?.let { bmp ->
            owlView = ImageView(ctx).apply { setImageBitmap(bmp) }
            col.addView(owlView, LinearLayout.LayoutParams(dp(84), dp(84)))
        }
        starsRow = LinearLayout(ctx).apply {
            gravity = Gravity.CENTER
            setPadding(0, dp(4), 0, dp(2))
        }
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
        var last: View? = null
        for (i in 0 until target) {
            val filled = i < solved
            val tile = ShapeTileView(
                ctx, Tile(Shape.STAR, if (filled) accent else 0x55FFFFFF), dp(34),
                bare = true,
            )
            row.addView(tile, LinearLayout.LayoutParams(dp(38), dp(38)).apply {
                setMargins(dp(3), 0, dp(3), 0)
            })
            if (i == solved - 1) last = tile
        }
        if (popLast) last?.let { popIn(it) }
    }

    private fun renderQuestion() {
        renderStars()
        val col = contentCol ?: return
        col.removeAllViews()
        typed = ""
        val q = current ?: return

        // Boss badge above the card
        if (q.boss) {
            col.addView(TextView(ctx).apply {
                text = "BOSS STAR"
                setTextColor(accent); textSize = 14f; brandFont(black = true)
                gravity = Gravity.CENTER
                setPadding(0, dp(4), 0, dp(6))
            })
        }

        // question card
        val card = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            background = GradientDrawable().apply {
                cornerRadius = dp(30).toFloat(); setColor(Color.WHITE)
                if (q.boss) setStroke(dp(3), accent)
            }
            elevation = dp(8).toFloat()
            setPadding(dp(22), dp(18), dp(22), dp(20))
        }
        card.addView(TextView(ctx).apply {
            text = "$solved of $target"
            setTextColor(0xFFB98600.toInt()); textSize = 12.5f; brandFont()
            background = rounded(0xFFFFF2CC.toInt(), dp(20))
            setPadding(dp(14), dp(5), dp(14), dp(5))
        })
        card.addView(TextView(ctx).apply {
            text = q.prompt
            setTextColor(textDark); brandFont(black = true)
            textSize = if (q.prompt.length > 40) 20f else 27f
            gravity = Gravity.CENTER
            setPadding(0, dp(12), 0, 0)
        })

        // Kind-specific content INSIDE the card (visual displays)
        when (q.kind) {
            QKind.COUNT -> card.addView(tileWrap(q.tiles!!, dp(46)), cardChild(dp(12)))
            QKind.MEMORY -> card.addView(tileWrap(q.tiles!!, dp(58)), cardChild(dp(12)))
            QKind.KEYPAD -> {
                typedView = TextView(ctx).apply {
                    text = " "; setTextColor(textDark); textSize = 28f; brandFont(black = true)
                    gravity = Gravity.CENTER
                    background = rounded(0xFFF2F1FA.toInt(), dp(16))
                    setPadding(0, dp(10), 0, dp(10))
                }
                card.addView(typedView, cardChild(dp(14)))
            }
            else -> {}
        }

        feedbackView = TextView(ctx).apply {
            text = ""; textSize = 15f; gravity = Gravity.CENTER; brandFont()
            setPadding(0, dp(10), 0, 0); visibility = View.GONE
        }
        card.addView(feedbackView)
        cardView = card

        col.addView(spacer())
        col.addView(card, LinearLayout.LayoutParams(match, wrap))
        col.addView(spacer())
        popIn(card)

        // Kind-specific INPUT below the card
        val input: View = when (q.kind) {
            QKind.KEYPAD -> buildKeypad()
            QKind.MCQ -> buildOptions(q.options!!) { submitText(it) }
            QKind.COUNT -> buildOptionRow(q.options!!) { submitText(it) }
            QKind.TRUE_FALSE -> buildTrueFalse()
            QKind.ODD_ONE_OUT -> buildOddGrid(q)
            QKind.COMPARE -> buildCompare(q)
            QKind.MATCH -> buildMatch(q)
            QKind.ORDER -> buildSlots(q.orderItems!!, q.answer.split(","))
            QKind.WORD -> buildSlots(q.letters!!.map { "$it" }, q.answer.map { "$it" })
            QKind.MEMORY -> View(ctx) // input appears after the reveal delay
        }
        col.addView(input, LinearLayout.LayoutParams(match, wrap))
        cascade(input)

        if (q.kind == QKind.MEMORY) startMemoryPhase(q, card, col, input)
    }

    private fun cardChild(top: Int) =
        LinearLayout.LayoutParams(match, wrap).apply { topMargin = top }

    /** Rows of tiles, max 4 per row, centered. */
    private fun tileWrap(tiles: List<Tile>, size: Int): View {
        val box = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER_HORIZONTAL
        }
        var row: LinearLayout? = null
        tiles.forEachIndexed { i, t ->
            if (i % 4 == 0) {
                row = LinearLayout(ctx).apply { gravity = Gravity.CENTER }
                box.addView(row)
            }
            row!!.addView(ShapeTileView(ctx, t, size, bare = true),
                LinearLayout.LayoutParams(size + dp(10), size + dp(10)).apply {
                    setMargins(dp(4), dp(4), dp(4), dp(4))
                })
        }
        return box
    }

    // ---- inputs ----
    private fun buildKeypad(): View {
        val grid = GridLayout(ctx).apply { columnCount = 3 }
        val keys = listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "del", "0", "ok")
        for (k in keys) {
            val bg = when (k) { "ok" -> correct; "del" -> 0x33FFFFFF; else -> Color.WHITE }
            val btn = TextView(ctx).apply {
                gravity = Gravity.CENTER
                textSize = if (k.length > 1) 20f else 26f; brandFont(black = true)
                text = when (k) { "del" -> "⌫"; "ok" -> "✓"; else -> k }
                setTextColor(if (k == "ok" || k == "del") Color.WHITE else textDark)
                background = rounded(bg, dp(20))
                if (k != "del") elevation = dp(3).toFloat()
                setOnClickListener { if (!busy) onKey(k) }
                pressable(this)
            }
            grid.addView(btn, GridLayout.LayoutParams().apply {
                width = 0; columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f)
                height = dp(56); setMargins(dp(6), dp(6), dp(6), dp(6))
            })
        }
        return grid
    }

    private fun buildOptions(options: List<String>, onTap: (String) -> Unit): View {
        val box = LinearLayout(ctx).apply { orientation = LinearLayout.VERTICAL }
        options.forEachIndexed { i, opt ->
            box.addView(TextView(ctx).apply {
                text = opt; gravity = Gravity.CENTER
                textSize = 19f; brandFont(black = true); setTextColor(Color.WHITE)
                background = rounded(optionColors[i % optionColors.size], dp(22))
                elevation = dp(4).toFloat()
                setPadding(dp(10), dp(16), dp(10), dp(16))
                setOnClickListener { if (!busy) onTap(opt) }
                pressable(this)
            }, LinearLayout.LayoutParams(match, wrap).apply { setMargins(0, dp(7), 0, dp(7)) })
        }
        return box
    }

    /** Horizontal row of small choices (COUNT numbers). */
    private fun buildOptionRow(options: List<String>, onTap: (String) -> Unit): View {
        val row = LinearLayout(ctx).apply { gravity = Gravity.CENTER }
        options.forEachIndexed { i, opt ->
            row.addView(TextView(ctx).apply {
                text = opt; gravity = Gravity.CENTER
                textSize = 24f; brandFont(black = true); setTextColor(Color.WHITE)
                background = rounded(optionColors[i % optionColors.size], dp(22))
                elevation = dp(4).toFloat()
                setOnClickListener { if (!busy) onTap(opt) }
                pressable(this)
            }, LinearLayout.LayoutParams(0, dp(64), 1f).apply {
                setMargins(dp(7), dp(6), dp(7), dp(6))
            })
        }
        return row
    }

    private fun buildTrueFalse(): View {
        val row = LinearLayout(ctx).apply { gravity = Gravity.CENTER }
        listOf("true" to correct, "false" to wrong).forEach { (v, color) ->
            row.addView(LinearLayout(ctx).apply {
                orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER
                background = rounded(color, dp(26)); elevation = dp(4).toFloat()
                setPadding(0, dp(18), 0, dp(18))
                addView(TextView(ctx).apply {
                    text = if (v == "true") "✓" else "✕"
                    setTextColor(Color.WHITE); textSize = 34f; brandFont(black = true)
                    gravity = Gravity.CENTER
                })
                addView(TextView(ctx).apply {
                    text = if (v == "true") "TRUE" else "FALSE"
                    setTextColor(Color.WHITE); textSize = 16f; brandFont(black = true)
                    gravity = Gravity.CENTER
                })
                setOnClickListener { if (!busy) submitText(v) }
                pressable(this)
            }, LinearLayout.LayoutParams(0, wrap, 1f).apply {
                setMargins(dp(8), 0, dp(8), 0)
            })
        }
        return row
    }

    private fun buildOddGrid(q: Q): View {
        val grid = GridLayout(ctx).apply { columnCount = 2 }
        q.tiles!!.forEachIndexed { i, t ->
            val tile = ShapeTileView(ctx, t, dp(64))
            tile.setOnClickListener {
                if (busy) return@setOnClickListener
                if (i == q.oddIndex) onCorrect() else onWrongOneShot("that one", tile)
            }
            pressable(tile)
            grid.addView(tile, GridLayout.LayoutParams().apply {
                width = 0; columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f)
                height = dp(96); setMargins(dp(8), dp(8), dp(8), dp(8))
            })
        }
        return grid
    }

    private fun buildCompare(q: Q): View {
        val row = LinearLayout(ctx).apply { gravity = Gravity.CENTER }
        q.options!!.forEachIndexed { i, v ->
            row.addView(TextView(ctx).apply {
                text = v; gravity = Gravity.CENTER
                textSize = 30f; brandFont(black = true); setTextColor(textDark)
                background = rounded(Color.WHITE, dp(26)); elevation = dp(4).toFloat()
                setPadding(dp(8), dp(26), dp(8), dp(26))
                setOnClickListener { if (!busy) submitText("$i") }
                pressable(this)
            }, LinearLayout.LayoutParams(0, wrap, 1f).apply {
                setMargins(dp(8), 0, dp(8), 0)
            })
        }
        return row
    }

    private fun buildMatch(q: Q): View {
        val row = LinearLayout(ctx)
        val leftCol = LinearLayout(ctx).apply { orientation = LinearLayout.VERTICAL }
        val rightCol = LinearLayout(ctx).apply { orientation = LinearLayout.VERTICAL }
        row.addView(leftCol, LinearLayout.LayoutParams(0, wrap, 1f))
        row.addView(rightCol, LinearLayout.LayoutParams(0, wrap, 1f))

        val leftViews = mutableListOf<TextView>(); val rightViews = mutableListOf<TextView>()
        var selectedLeft = -1
        val lockedLeft = BooleanArray(3); val lockedRight = BooleanArray(3)
        var lockedCount = 0

        fun pill(text: String): TextView = TextView(ctx).apply {
            this.text = text; gravity = Gravity.CENTER
            textSize = 16f; brandFont(black = true); setTextColor(textDark)
            background = rounded(Color.WHITE, dp(18)); elevation = dp(3).toFloat()
            setPadding(dp(6), dp(14), dp(6), dp(14))
        }

        fun refreshLeft() {
            leftViews.forEachIndexed { i, v ->
                if (lockedLeft[i]) return@forEachIndexed
                v.background = if (i == selectedLeft)
                    GradientDrawable().apply {
                        cornerRadius = dp(18).toFloat(); setColor(Color.WHITE)
                        setStroke(dp(3), accent)
                    }
                else rounded(Color.WHITE, dp(18))
            }
        }
        fun lock(li: Int, ri: Int) {
            val c = optionColors[lockedCount % optionColors.size]
            lockedLeft[li] = true; lockedRight[ri] = true; lockedCount++
            leftViews[li].background = rounded(c, dp(18))
            leftViews[li].setTextColor(Color.WHITE)
            rightViews[ri].background = rounded(c, dp(18))
            rightViews[ri].setTextColor(Color.WHITE)
            popIn(leftViews[li]); popIn(rightViews[ri])
            if (lockedCount == 3) handler.postDelayed({ onCorrect() }, 350)
            else playSound(successSoundId)
        }

        q.left!!.forEachIndexed { i, s ->
            val v = pill(s)
            v.setOnClickListener {
                if (busy || lockedLeft[i]) return@setOnClickListener
                selectedLeft = i; refreshLeft()
            }
            pressable(v); leftViews.add(v)
            leftCol.addView(v, LinearLayout.LayoutParams(match, wrap).apply {
                setMargins(dp(4), dp(5), dp(4), dp(5))
            })
        }
        q.right!!.forEachIndexed { i, s ->
            val v = pill(s)
            v.setOnClickListener {
                if (busy || lockedRight[i] || selectedLeft < 0) return@setOnClickListener
                if (q.matchMap!![selectedLeft] == i) {
                    val li = selectedLeft; selectedLeft = -1
                    lock(li, i); refreshLeft()
                } else {
                    playSound(tryAgainSoundId)
                    shake(v); leftViews.getOrNull(selectedLeft)?.let { shake(it) }
                }
            }
            pressable(v); rightViews.add(v)
            rightCol.addView(v, LinearLayout.LayoutParams(match, wrap).apply {
                setMargins(dp(4), dp(5), dp(4), dp(5))
            })
        }
        return row
    }

    /** Shared tap-to-place slots UI for ORDER and WORD. */
    private fun buildSlots(items: List<String>, answerSeq: List<String>): View {
        val box = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER_HORIZONTAL
        }
        val n = items.size
        val placed = arrayOfNulls<Int>(n) // slot -> tile index
        val slotViews = mutableListOf<TextView>()
        val tileViews = mutableListOf<TextView>()

        val slotRow = LinearLayout(ctx).apply { gravity = Gravity.CENTER }
        val tileRow = LinearLayout(ctx).apply { gravity = Gravity.CENTER }

        fun tvBase(): TextView = TextView(ctx).apply {
            gravity = Gravity.CENTER; textSize = 22f; brandFont(black = true)
        }
        fun checkDone() {
            if (placed.any { it == null }) return
            busy = true
            val got = placed.map { items[it!!] }
            if (got == answerSeq) { onCorrect() } else {
                playSound(tryAgainSoundId)
                feedback("Almost! Try a different order.", wrong)
                cardView?.let { shake(it) }
                handler.postDelayed({
                    // return all tiles for another go
                    for (s in 0 until n) {
                        placed[s]?.let { t -> tileViews[t].visibility = View.VISIBLE }
                        placed[s] = null
                        slotViews[s].text = ""
                        slotViews[s].background = slotBg(false)
                    }
                    feedbackView?.visibility = View.GONE
                    busy = false
                }, 900)
            }
        }
        fun place(tileIdx: Int) {
            val slot = placed.indexOfFirst { it == null }
            if (slot < 0) return
            placed[slot] = tileIdx
            slotViews[slot].text = items[tileIdx]
            slotViews[slot].background = slotBg(true)
            tileViews[tileIdx].visibility = View.INVISIBLE
            popIn(slotViews[slot])
            checkDone()
        }
        fun unplace(slot: Int) {
            val t = placed[slot] ?: return
            placed[slot] = null
            slotViews[slot].text = ""
            slotViews[slot].background = slotBg(false)
            tileViews[t].visibility = View.VISIBLE
        }

        for (s in 0 until n) {
            val v = tvBase().apply {
                setTextColor(textDark); background = slotBg(false)
                setOnClickListener { if (!busy) unplace(s) }
            }
            slotViews.add(v)
            slotRow.addView(v, LinearLayout.LayoutParams(0, dp(58), 1f).apply {
                setMargins(dp(4), 0, dp(4), 0)
            })
        }
        items.forEachIndexed { i, s ->
            val v = tvBase().apply {
                text = s; setTextColor(Color.WHITE)
                background = rounded(optionColors[i % optionColors.size], dp(16))
                elevation = dp(3).toFloat()
                setOnClickListener { if (!busy) place(i) }
            }
            pressable(v); tileViews.add(v)
            tileRow.addView(v, LinearLayout.LayoutParams(0, dp(58), 1f).apply {
                setMargins(dp(4), dp(12), dp(4), 0)
            })
        }
        box.addView(slotRow, LinearLayout.LayoutParams(match, wrap))
        box.addView(tileRow, LinearLayout.LayoutParams(match, wrap))
        return box
    }

    private fun slotBg(filled: Boolean): GradientDrawable = GradientDrawable().apply {
        cornerRadius = dp(16).toFloat()
        if (filled) { setColor(Color.WHITE) } else {
            setColor(0x22FFFFFF); setStroke(dp(2), 0x66FFFFFF)
        }
    }

    private fun startMemoryPhase(q: Q, card: LinearLayout, col: LinearLayout, inputPlaceholder: View) {
        busy = true
        handler.postDelayed({
            busy = false
            // Hide the shown tiles, swap prompt, present probes.
            (card.getChildAt(1) as? TextView)?.text = "Which one did you see?"
            (card.getChildAt(2))?.visibility = View.GONE // the tileWrap
            val idx = col.indexOfChild(inputPlaceholder)
            col.removeView(inputPlaceholder)
            val probes = LinearLayout(ctx).apply { gravity = Gravity.CENTER }
            q.memoryOptions!!.forEachIndexed { i, t ->
                val tile = ShapeTileView(ctx, t, dp(60))
                tile.setOnClickListener {
                    if (busy) return@setOnClickListener
                    if (i == q.memoryAnswer) onCorrect() else onWrongOneShot("that one", tile)
                }
                pressable(tile)
                probes.addView(tile, LinearLayout.LayoutParams(0, dp(92), 1f).apply {
                    setMargins(dp(6), 0, dp(6), 0)
                })
            }
            col.addView(probes, idx, LinearLayout.LayoutParams(match, wrap))
            cascade(probes)
        }, 2600)
    }

    // ---- answer plumbing ----
    private fun onKey(k: String) {
        when (k) {
            "del" -> if (typed.isNotEmpty()) typed = typed.dropLast(1)
            "ok" -> { if (typed.isNotEmpty()) submitText(typed); return }
            else -> if (typed.length < 6) typed += k
        }
        typedView?.text = if (typed.isEmpty()) " " else typed
    }

    private fun submitText(given: String) {
        val q = current ?: return
        if (busy) return
        if (Questions.isCorrect(q, given)) onCorrect()
        else onWrongOneShot(prettyAnswer(q), null)
    }

    private fun prettyAnswer(q: Q): String = when (q.kind) {
        QKind.COMPARE -> q.options!![q.answer.toInt()]
        QKind.TRUE_FALSE -> q.answer.uppercase()
        else -> q.answer
    }

    private fun onCorrect() {
        val q = current ?: return
        busy = true
        solved++; streak++
        renderStars(popLast = true)
        bounceOwl()
        celebrate(big = q.boss)
        playSound(if (q.boss && bossSoundId != 0) bossSoundId else successSoundId)
        val line = if (streak >= 2) "${affirmations.random()}  •  $streak in a row!"
            else affirmations.random()
        feedback(if (q.boss) "Boss cleared! $line" else line, correct)
        if (solved >= target) {
            handler.postDelayed({ onEarned() }, if (q.boss) 1500L else 1200L)
        } else {
            handler.postDelayed({
                busy = false; index++
                current = session.getOrNull(index)
                renderQuestion()
            }, if (q.boss) 1200L else 850L)
        }
    }

    /** One-shot kinds: gentle reveal, then a fresh question of the same kind. */
    private fun onWrongOneShot(answerText: String, tappedView: View?) {
        val q = current ?: return
        busy = true
        streak = 0
        playSound(tryAgainSoundId)
        tappedView?.let { shake(it) } ?: cardView?.let { shake(it) }
        val reveal = when (q.kind) {
            QKind.ODD_ONE_OUT, QKind.MEMORY -> "Not $answerText. Look again."
            else -> "Oops! It was $answerText."
        }
        feedback(reveal, wrong)
        handler.postDelayed({
            busy = false
            current = Questions.regenerate(ctx, band, q.kind).copy(boss = q.boss)
            renderQuestion()
        }, 1500)
    }

    private fun feedback(text: String, color: Int) {
        feedbackView?.apply {
            this.text = text; setTextColor(color); visibility = View.VISIBLE
        }
    }

    // ---- celebrations / animations ----
    private fun celebrate(big: Boolean = false) {
        repeat(if (big) 3 else 1) { i ->
            handler.postDelayed({
                val emoji = TextView(ctx).apply {
                    text = celebrateEmojis.random(); textSize = if (big) 100f else 88f
                    gravity = Gravity.CENTER
                }
                root.addView(emoji, FrameLayout.LayoutParams(wrap, wrap).apply {
                    gravity = Gravity.CENTER
                    if (big) leftMargin = dp((i - 1) * 70)
                })
                emoji.scaleX = 0.3f; emoji.scaleY = 0.3f; emoji.alpha = 0f
                emoji.animate().scaleX(1.7f).scaleY(1.7f).alpha(1f)
                    .setDuration(260).setInterpolator(OvershootInterpolator())
                    .withEndAction {
                        emoji.animate().alpha(0f).scaleX(2.1f).scaleY(2.1f)
                            .translationYBy(dp(-40).toFloat()).setDuration(420)
                            .withEndAction { runCatching { root.removeView(emoji) } }
                            .start()
                    }.start()
            }, i * 140L)
        }
    }

    private fun popIn(v: View) {
        v.scaleX = 0.6f; v.scaleY = 0.6f
        v.animate().scaleX(1f).scaleY(1f).setDuration(300)
            .setInterpolator(OvershootInterpolator()).start()
    }

    /** Children of [group] pop in one after another. */
    private fun cascade(group: View) {
        if (group !is ViewGroup) return
        var d = 0L
        fun walk(v: View) {
            if (v is ViewGroup && v !is TextView) {
                for (i in 0 until v.childCount) walk(v.getChildAt(i))
            } else {
                v.alpha = 0f; v.scaleX = 0.7f; v.scaleY = 0.7f
                v.animate().alpha(1f).scaleX(1f).scaleY(1f)
                    .setStartDelay(d).setDuration(240)
                    .setInterpolator(OvershootInterpolator()).start()
                d += 40
            }
        }
        walk(group)
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
        val d = dp(12).toFloat()
        v.animate().translationX(-d).setDuration(55).withEndAction {
            v.animate().translationX(d).setDuration(65).withEndAction {
                v.animate().translationX(-d * 0.5f).setDuration(55).withEndAction {
                    v.animate().translationX(0f).setDuration(55).start()
                }.start()
            }.start()
        }.start()
    }

    // ---------------------------------------------------------------- DONE
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
            text = "You are a star today!"
            setTextColor(Color.WHITE); textSize = 27f; brandFont(black = true)
            gravity = Gravity.CENTER
            setPadding(0, dp(8), 0, dp(8))
        })
        col.addView(TextView(ctx).apply {
            text = "Great learning. See you tomorrow."
            setTextColor(0xE6FFFFFF.toInt()); textSize = 17f; brandFont()
            gravity = Gravity.CENTER
        })
        root.addView(col, FrameLayout.LayoutParams(match, match))
    }

    // ------------------------------------------------------------ PARENT PIN
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
            setTextColor(Color.WHITE); textSize = 22f; brandFont(black = true)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, dp(20))
        })
        val dots = TextView(ctx).apply {
            setTextColor(Color.WHITE); textSize = 28f; gravity = Gravity.CENTER
        }
        overlay.addView(dots)
        val err = TextView(ctx).apply {
            setTextColor(0xFFFFE0E0.toInt()); textSize = 14f; gravity = Gravity.CENTER
            brandFont(); setPadding(0, dp(8), 0, dp(8))
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
                brandFont(black = true); setTextColor(textDark)
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
            text = "Back"
            setTextColor(0xCCFFFFFF.toInt()); textSize = 15f; brandFont()
            gravity = Gravity.CENTER
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

    private fun owlBitmap(): Bitmap? = runCatching {
        ctx.assets.open("flutter_assets/assets/mascot_opening.png")
            .use { BitmapFactory.decodeStream(it) }
    }.getOrNull()
}

// ===========================================================================
// ShapeTileView — the hand-drawn tile visual system.
// Draws a soft white rounded card with a coloured shape (circle / square /
// star / heart / triangle / diamond / moon). When Tile.sticker names a bundled
// PNG (flutter_assets/assets/stickers/<name>.png) the illustration is drawn
// instead — so real character art can drop in with zero code changes.
// ===========================================================================
@SuppressLint("ViewConstructor")
class ShapeTileView(
    ctx: Context,
    private val tile: Tile,
    private val sizePx: Int,
    private val bare: Boolean = false, // no card background (stars row, in-card displays)
) : View(ctx) {

    companion object {
        private val stickerCache = HashMap<String, Bitmap?>()
    }

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val path = Path()

    init {
        // Shadow layers only render reliably with software rendering.
        setLayerType(LAYER_TYPE_SOFTWARE, null)
    }
    private val sticker: Bitmap? = tile.sticker?.let { name ->
        stickerCache.getOrPut(name) {
            runCatching {
                context.assets.open("flutter_assets/assets/stickers/$name.png")
                    .use { BitmapFactory.decodeStream(it) }
            }.getOrNull()
        }
    }

    override fun onDraw(canvas: Canvas) {
        val w = width.toFloat(); val h = height.toFloat()
        if (!bare) {
            paint.style = Paint.Style.FILL
            paint.color = Color.WHITE
            paint.setShadowLayer(6f, 0f, 3f, 0x33000000)
            canvas.drawRoundRect(RectF(2f, 2f, w - 2f, h - 2f), h * 0.22f, h * 0.22f, paint)
            paint.clearShadowLayer()
        }
        val s = sticker
        if (s != null) {
            val pad = w * 0.14f
            canvas.drawBitmap(s, null, RectF(pad, pad, w - pad, h - pad), paint)
            return
        }
        paint.color = tile.color
        val cx = w / 2f; val cy = h / 2f
        val r = minOf(w, h) * (if (bare) 0.46f else 0.30f)
        when (tile.shape) {
            Shape.CIRCLE -> canvas.drawCircle(cx, cy, r, paint)
            Shape.SQUARE -> canvas.drawRoundRect(
                RectF(cx - r, cy - r, cx + r, cy + r), r * 0.3f, r * 0.3f, paint)
            Shape.STAR -> { starPath(cx, cy, r); canvas.drawPath(path, paint) }
            Shape.HEART -> { heartPath(cx, cy, r); canvas.drawPath(path, paint) }
            Shape.TRIANGLE -> {
                path.reset()
                path.moveTo(cx, cy - r)
                path.lineTo(cx + r * 0.95f, cy + r * 0.75f)
                path.lineTo(cx - r * 0.95f, cy + r * 0.75f)
                path.close()
                canvas.drawPath(path, paint)
            }
            Shape.DIAMOND -> {
                path.reset()
                path.moveTo(cx, cy - r)
                path.lineTo(cx + r * 0.8f, cy)
                path.lineTo(cx, cy + r)
                path.lineTo(cx - r * 0.8f, cy)
                path.close()
                canvas.drawPath(path, paint)
            }
            Shape.MOON -> {
                path.reset()
                path.addCircle(cx, cy, r, Path.Direction.CW)
                val bite = Path().apply {
                    addCircle(cx + r * 0.55f, cy - r * 0.25f, r * 0.85f, Path.Direction.CW)
                }
                path.op(bite, Path.Op.DIFFERENCE)
                canvas.drawPath(path, paint)
            }
        }
        // Label (rarely used; tiles are mostly pure shapes)
        if (tile.label.isNotEmpty()) {
            paint.color = 0xFF1F2333.toInt()
            paint.textAlign = Paint.Align.CENTER
            paint.textSize = h * 0.3f
            canvas.drawText(tile.label, cx, cy + paint.textSize * 0.35f, paint)
        }
    }

    private fun starPath(cx: Float, cy: Float, r: Float) {
        path.reset()
        val inner = r * 0.45f
        for (i in 0 until 10) {
            val rad = if (i % 2 == 0) r else inner
            val a = Math.toRadians((i * 36 - 90).toDouble())
            val x = cx + (rad * Math.cos(a)).toFloat()
            val y = cy + (rad * Math.sin(a)).toFloat()
            if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }
        path.close()
    }

    private fun heartPath(cx: Float, cy: Float, r: Float) {
        path.reset()
        val top = cy - r * 0.35f
        path.moveTo(cx, cy + r * 0.75f)
        path.cubicTo(cx - r * 1.6f, cy - r * 0.2f, cx - r * 0.7f, top - r * 0.8f, cx, top)
        path.cubicTo(cx + r * 0.7f, top - r * 0.8f, cx + r * 1.6f, cy - r * 0.2f, cx, cy + r * 0.75f)
        path.close()
    }
}
