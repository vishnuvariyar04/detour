package com.brainpass.brainpass

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.media.AudioAttributes
import android.media.SoundPool
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.animation.DecelerateInterpolator
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

/**
 * The learning moment, rebuilt around the curriculum.
 *
 * The old gate asked a random question on a purple gradient. This one walks a
 * child through a slice of an actual skill: a teach card when a new stop opens,
 * then that stop's questions, then the minutes they earned. Progress carries
 * across apps and across days ([Curriculum.Progress]), so the ladder is the same
 * ladder whether the gate fired on YouTube or on a game.
 *
 * Look and feel: a light ground, one idea on screen at a time, a segmented
 * progress bar at the top, and one big action button pinned to the bottom edge
 * where a thumb already is. Verdicts arrive in a drawer that slides up over that
 * button, so the child never hunts for what to do next.
 *
 * Everything is drawn in code — this runs in the guard's overlay window, where
 * there is no Activity and no theme to inflate.
 */
@SuppressLint("ClickableViewAccessibility")
class CoderGate(
    private val ctx: Context,
    private val minutes: Int,
    private val items: List<Curriculum.Item>,
    private val skill: Curriculum.Skill,
    private val onEarned: () -> Unit,
    private val onOverride: () -> Unit,
) : GateUi {

    private val fonts = Fonts(ctx)
    private val handler = Handler(Looper.getMainLooper())

    // Session state
    private var index = 0
    private var answered = 0          // resolved items, for the progress bar
    private var correctCount = 0
    private var hintShown = false
    private var locked = false        // true between answering and Continue

    // The child's answer for the item on screen, whatever shape it takes.
    private var pickedCell: Pair<Int, Int>? = null
    private var pickedBlock = -1
    private var pickedOption = -1
    // Answers can be negative ("Below zero"), so -1 can't mean "nothing picked".
    private var pickedNumber = NO_NUMBER
    // The order the number choices were actually drawn in. The authored lists are
    // ascending, which put the right answer in the same slot every time, so they
    // are shuffled per showing; buttons and the verdict tint are indexed by THIS.
    private var shownChoices: List<Int> = emptyList()

    // Number Sense pictures, and what the child has done to them.
    private var picView: android.view.View? = null
    private var pickedSet = mutableSetOf<Int>()
    private var pickedOrder = mutableListOf<Int>()
    private var pickedCells = mutableSetOf<Pair<Int, Int>>()
    private var pickedSides: IntArray = IntArray(0)
    private var pickedBool: Boolean? = null
    private var builtProgram: List<String> = emptyList()

    private var sound: SoundPool? = null
    private var sndGood = 0
    private var sndBad = 0
    private var sndBoss = 0

    // Views belonging to the item currently on screen. These MUST be declared
    // above the init block: Kotlin initialises properties in declaration order,
    // and init calls render(), which clears optionButtons.
    private var board: GridBotView? = null
    private var list: ProgramListView? = null
    private var bank: BlockBankView? = null
    private val optionButtons = mutableListOf<PushButton>()
    private var hintCard: TextView? = null

    /**
     * Bumped on every render. A delayed demo playback that fires after the child
     * has already moved on would otherwise run the teach card's program on the
     * next question's board.
     */
    private var generation = 0

    // ------------------------------------------------------------------ chrome

    override val root = FrameLayout(ctx).apply { setBackgroundColor(Ink.bg) }

    private val progress = SegmentBar(ctx)
    private val body = LinearLayout(ctx).apply {
        orientation = LinearLayout.VERTICAL
        setPadding(dp(20), dp(4), dp(20), dp(16))
    }
    private val scroller = ScrollView(ctx).apply {
        isFillViewport = true
        overScrollMode = View.OVER_SCROLL_NEVER
        addView(body, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
    }
    private val action = PushButton(ctx, fonts).apply {
        face = Ink.primary; ledgeColor = Ink.primaryLedge; textColor = Color.WHITE
        textSize = 17f; radius = 18f; depth = 6
    }
    private val hintButton = PushButton(ctx, fonts).apply {
        face = Ink.surface; ledgeColor = Ink.ledge; textColor = Ink.muted
        label = "Hint"; textSize = 15f; radius = 18f; depth = 5
    }
    private val actionBar = LinearLayout(ctx).apply {
        orientation = LinearLayout.HORIZONTAL
        setPadding(dp(20), dp(10), dp(20), dp(18))
        setBackgroundColor(Ink.bg)
    }
    private val drawer = FrameLayout(ctx)

    init {
        loadSounds()

        val topBar = LinearLayout(ctx).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(20), dp(18), dp(12), dp(10))
        }
        topBar.addView(progress, LinearLayout.LayoutParams(0, dp(14), 1f))
        // A PushButton, not a TextView with a click listener: every other
        // control in the overlay handles touches this way and they all work,
        // and a parent reaching for this in a hurry needs a real hit target
        // rather than a line of 13sp text.
        val parentButton = PushButton(ctx, fonts).apply {
            label = "Parent"
            textSize = 13f
            radius = 14f
            depth = 3
            face = Ink.surface; ledgeColor = Ink.ledge; textColor = Ink.muted
        }
        parentButton.onTap = { showPinSheet() }
        topBar.addView(parentButton, LinearLayout.LayoutParams(dp(78), dp(38)).apply {
            marginStart = dp(12)
        })

        actionBar.addView(hintButton, LinearLayout.LayoutParams(dp(96), dp(56)).apply {
            marginEnd = dp(10)
        })
        actionBar.addView(action, LinearLayout.LayoutParams(0, dp(56), 1f))
        hintButton.onTap = { revealHint() }

        val col = LinearLayout(ctx).apply { orientation = LinearLayout.VERTICAL }
        col.addView(topBar, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        col.addView(scroller, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        col.addView(actionBar, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))

        root.addView(col, FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT))
        root.addView(drawer, FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT,
            Gravity.BOTTOM))

        progress.total = items.size
        render()
    }

    override fun release() {
        handler.removeCallbacksAndMessages(null)
        board?.stop()
        runCatching { sound?.release() }
        sound = null
    }

    private fun loadSounds() = runCatching {
        val attrs = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_GAME)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()
        sound = SoundPool.Builder().setMaxStreams(3).setAudioAttributes(attrs).build().apply {
            // Compile-time R references: the release resource shrinker cannot see
            // getIdentifier() lookups and strips the wavs out of the APK.
            sndGood = load(ctx, R.raw.nupo_success, 1)
            sndBad = load(ctx, R.raw.nupo_try_again, 1)
            sndBoss = load(ctx, R.raw.nupo_boss, 1)
        }
    }

    private fun play(id: Int) = runCatching { sound?.play(id, 0.85f, 0.85f, 1, 0, 1f) }

    // ------------------------------------------------------------------ render

    private fun render() {
        body.removeAllViews()
        optionButtons.clear()
        board = null; list = null; bank = null; hintCard = null
        boardRowView = null; boardView = null; boxesView = null
        pickedCell = null; pickedBlock = -1; pickedOption = -1
        pickedNumber = NO_NUMBER; pickedBool = null; builtProgram = emptyList()
        shownChoices = emptyList()
        picView = null
        pickedSet = mutableSetOf(); pickedOrder = mutableListOf()
        pickedCells = mutableSetOf(); pickedSides = IntArray(0)
        hintShown = false
        locked = false
        drawer.removeAllViews()

        generation++
        val item = items.getOrNull(index)
        if (item == null) { renderFinish(); return }

        if (item.isTeach) renderTeach(item.teachStop!!) else renderQuestion(item.question!!)
        if (debugBuild) item.question?.let { logTargets(it) }
    }

    // ---- teach card

    private fun renderTeach(stop: Curriculum.Stop) {
        hintButton.visibility = View.GONE
        // A teach card has nothing to answer, so "Got it" must always be tappable.
        // The action button is shared with the questions and can arrive disabled:
        // submitting a build-a-program answer disables it and nothing re-enables
        // it, and most teach layouts below never do either.
        action.tint(Ink.primary, Ink.primaryLedge)
        action.enabledLook = true
        progress.value = answered

        body.addView(label(ctx, fonts, "NEW IDEA", 12f, Ink.primary, black = true).apply {
            letterSpacing = 0.14f
        })
        body.addView(space(6))
        body.addView(label(ctx, fonts, stop.title, 26f, Ink.text, black = true))
        body.addView(space(10))
        body.addView(label(ctx, fonts, stop.teachLine ?: "", 16f, Ink.muted).apply {
            typeface = fonts.body
            setLineSpacing(dp(4).toFloat(), 1f)
        })
        body.addView(space(18))

        // A worked example that plays itself: the idea demonstrated, not described.
        // A Number Sense stop demonstrates with one of its own pictures. Without
        // this it fell through to the board below and showed a counting lesson
        // as a grid with a walking owl on it — the right words over the wrong
        // picture, which teaches worse than no picture at all.
        stop.teachPic?.let { tp ->
            val v = pictureFor(tp)
            body.addView(v, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT))
            // The answer, under the example. A teach card whose picture still
            // has its gap in it is a question, and the child has been given no
            // idea yet with which to answer it.
            if (tp.reveal.isNotEmpty()) {
                body.addView(space(12))
                body.addView(label(ctx, fonts, "Answer:  ${tp.reveal}", 17f,
                    Ink.good, black = true, align = Gravity.CENTER))
            }
            val replayP = PushButton(ctx, fonts).apply {
                face = Ink.surface; ledgeColor = Ink.ledge; textColor = Ink.primary
                label = "Watch again"; textSize = 15f; radius = 18f; depth = 5
            }
            replayP.onTap = { playPicture(v) }
            body.addView(space(16))
            body.addView(replayP, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(52)))
            v.post { playPicture(v) }
            action.label = "Got it"
            action.onTap = { next() }
            return
        }

        // The stop supplies its own demo board. It must never be one of the
        // stop's question boards — animating the answer to the question you are
        // about to ask turns the lesson into a waiting game.
        val demo = stop.teachBoard
            ?: Curriculum.Board(org.json.JSONObject(
                """{"w":4,"h":4,"start":[0,0],"goal":[2,2],"program":["up","up","right","right"]}"""
            ))
        // A logic stop has no board worth drawing: the idea IS the condition,
        // so the demo shows the facts, the condition, and the verdict landing.
        // Two runs at once, for an idea a single run cannot show: the same
        // steps in a different order, or the same job in fewer rows.
        val cd = stop.teachCompare
        if (cd != null) {
            val row = LinearLayout(ctx).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.TOP
            }
            val gbs = mutableListOf<GridBotView>()
            val pls = mutableListOf<ProgramListView>()
            listOf("A" to cd.a, "B" to cd.b).forEachIndexed { i, (name, prog) ->
                val col = LinearLayout(ctx).apply {
                    orientation = LinearLayout.VERTICAL
                    gravity = Gravity.CENTER_HORIZONTAL
                }
                col.addView(label(ctx, fonts, name, 15f, Ink.muted,
                    black = true, align = Gravity.CENTER))
                col.addView(space(6))
                val gb = GridBotView(ctx)
                gb.setBoard(cd.board, false)
                gbs.add(gb)
                col.addView(gb, LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, dp(150)))
                col.addView(space(8))
                val pl = ProgramListView(ctx, fonts)
                pl.compact = true
                pl.program = prog
                pls.add(pl)
                col.addView(pl, LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT))
                row.addView(col, LinearLayout.LayoutParams(0,
                    ViewGroup.LayoutParams.WRAP_CONTENT, 1f).apply {
                    marginStart = if (i == 0) 0 else dp(12)
                })
            }
            body.addView(row, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT))

            val g3 = generation
            val playBoth = {
                gbs.forEachIndexed { i, gb ->
                    pls[i].reset()
                    gb.play(if (i == 0) cd.a else cd.b,
                        onStep = { r -> pls[i].running = r },
                        onDone = { pls[i].running = -1 })
                }
            }
            val replayC = PushButton(ctx, fonts).apply {
                face = Ink.surface; ledgeColor = Ink.ledge; textColor = Ink.primary
                label = "Watch again"; textSize = 15f; radius = 18f; depth = 5
            }
            replayC.onTap = { playBoth() }
            body.addView(space(16))
            body.addView(replayC, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(52)))
            handler.postDelayed({ if (g3 == generation) playBoth() }, 500)
            action.label = "Got it"
            action.onTap = { next() }
            return
        }

        val td = stop.teachTruth
        if (td != null) {
            body.addView(factsCard(td.facts))
            body.addView(space(14))
            body.addView(exprCard(td.expr))
            body.addView(space(14))
            val verdict = label(ctx, fonts, "", 24f,
                if (td.value) Ink.good else Ink.bad, black = true,
                align = Gravity.CENTER).apply {
                background = roundRect(
                    if (td.value) Ink.goodWash else Ink.badWash, ctx.dpf(18f),
                    if (td.value) Ink.good else Ink.bad, dp(2))
                setPadding(dp(16), dp(16), dp(16), dp(16))
                alpha = 0f
            }
            body.addView(verdict, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT))
            val g2 = generation
            val showVerdict = {
                verdict.text = if (td.value) "TRUE" else "FALSE"
                verdict.alpha = 0f
                verdict.animate().alpha(1f).setDuration(240).start()
            }
            val replayT = PushButton(ctx, fonts).apply {
                face = Ink.surface; ledgeColor = Ink.ledge; textColor = Ink.primary
                label = "Watch again"; textSize = 15f; radius = 18f; depth = 5
            }
            replayT.onTap = {
                verdict.text = ""
                verdict.alpha = 0f
                handler.postDelayed({ if (g2 == generation) showVerdict() }, 700)
            }
            body.addView(space(16))
            body.addView(replayT, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(52)))
            handler.postDelayed({ if (g2 == generation) showVerdict() }, 900)
            action.label = "Got it"
            action.onTap = { next() }
            return
        }

        val showGrid = boxesFor(demo)
        if (showGrid) {
            body.addView(boardRow(demo, demo.program, stack = true, compact = true))
        } else {
            val pl = ProgramListView(ctx, fonts)
            pl.compact = true
            pl.program = demo.program
            list = pl
            body.addView(pl, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT))
        }
        val playIt = { if (showGrid) runDemo(demo.program) else playBoxes(demo) }
        body.addView(space(14))

        val replay = PushButton(ctx, fonts).apply {
            face = Ink.surface; ledgeColor = Ink.ledge; textColor = Ink.primary
            label = "Watch again"; textSize = 15f; radius = 16f
        }
        replay.onTap = { playIt() }
        body.addView(replay, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, dp(50)))

        action.label = "Got it"
        action.tint(Ink.primary, Ink.primaryLedge)
        action.enabledLook = true
        action.onTap = {
            Curriculum.Progress.markTaught(ctx, stop.id)
            next()
        }
        val g = generation
        handler.postDelayed({ if (g == generation) playIt() }, 420)
    }

    private fun runDemo(program: List<String>) {
        val b = board ?: return
        list?.reset()
        b.play(program, onStep = { list?.running = it }, onDone = { list?.running = -1 })
    }

    // ---- questions

    /**
     * Reports where this question's tappable parts landed, for the on-device
     * test driver in tools/e2e.
     *
     * The gate draws itself on a Canvas, so there is no accessibility tree for a
     * test to query and no reliable way to find a target from pixels alone —
     * every shape needed its own fragile heuristic. Having the view report its
     * own geometry makes the whole ladder testable exactly as a child taps it.
     * Debug builds only.
     */
    /** Debug builds only; the release APK never logs geometry. */
    private val debugBuild: Boolean
        get() = (ctx.applicationInfo.flags and
            android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0

    private fun logTargets(q: Curriculum.Question, delayMs: Long = 600) {
        // After the board has been grown to fit, not before: growing it pushes
        // everything below down, and geometry read too early pointed at the
        // option above the one meant. A re-report after a tap needs no such
        // wait — the layout has already settled — and waiting made a driver
        // read stale positions and tap empty space.
        body.postDelayed({
            val sb = StringBuilder("targets ${q.id} ${q.shape}")
            val loc = IntArray(2)
            action.getLocationOnScreen(loc)
            sb.append(" action=${loc[0] + action.width / 2},${loc[1] + action.height / 2}")
            optionButtons.forEachIndexed { i, b ->
                b.getLocationOnScreen(loc)
                sb.append(" opt$i=${loc[0] + b.width / 2},${loc[1] + b.height / 2}")
            }
            list?.let { pl ->
                for (i in q.board?.program?.indices ?: IntRange.EMPTY) {
                    val p = pl.rowOnScreen(i)
                    sb.append(" row$i=${p[0]},${p[1]}")
                }
            }
            board?.let { gb ->
                q.answerCell?.let { (cx, cy) ->
                    val p = gb.cellOnScreen(cx, cy)
                    sb.append(" cell=${p[0]},${p[1]}")
                }
            }
            bank?.let { bk ->
                q.blocks.indices.forEach { i ->
                    val p = bk.chipOnScreen(i)
                    sb.append(" chip$i=${p[0]},${p[1]}")
                }
            }
            when (val v = picView) {
                is NumberLineView -> for (n in (q.pic?.from ?: 0)..(q.pic?.to ?: 10)) {
                    val p = v.tickOnScreen(n)
                    sb.append(" tick$n=${p[0]},${p[1]}")
                }
                is FractionWallView -> (q.pic?.strips ?: emptyList()).indices
                    .forEach { i ->
                        val pt = v.stripOnScreen(i)
                        sb.append(" strip$i=${pt[0]},${pt[1]}")
                    }
                is ShapeHuntView -> v.kinds().indices.forEach { i ->
                    val p = v.partOnScreen(i)
                    sb.append(" part$i=${p[0]},${p[1]}")
                }
                is OddOneOutView -> (q.pic?.cells ?: emptyList()).indices.forEach { i ->
                    val p = v.tileOnScreen(i)
                    sb.append(" tile$i=${p[0]},${p[1]}")
                }
                is SortTrayView -> (q.pic?.cells ?: emptyList()).indices.forEach { i ->
                    val p = v.itemOnScreen(i)
                    sb.append(" item$i=${p[0]},${p[1]}")
                }
                is SizeOrderView -> (q.pic?.sizes ?: emptyList()).indices.forEach { i ->
                    val p = v.itemOnScreen(i)
                    sb.append(" size$i=${p[0]},${p[1]}")
                }
                is MirrorView -> for (r in 0 until v.rows)
                    for (cc in 0 until v.cols) {
                        val p = v.cellOnScreen(cc, r)
                        sb.append(" mc${cc}_$r=${p[0]},${p[1]}")
                    }
                else -> Unit
            }
            android.util.Log.d("NupoGate", sb.toString())
        }, delayMs)
    }

    private fun renderQuestion(q: Curriculum.Question) {
        hintButton.visibility = if (q.hint.isBlank()) View.GONE else View.VISIBLE
        hintButton.enabledLook = true
        hintButton.tint(Ink.surface, Ink.ledge, Ink.muted)
        progress.value = answered

        body.addView(label(ctx, fonts, q.prompt, 19f, Ink.text, black = true).apply {
            setLineSpacing(dp(3).toFloat(), 1f)
        })
        body.addView(space(16))

        when (q.shape) {
            "predict" -> {
                boxesFor(q.board)
                body.addView(boardRow(q.board, q.board?.program ?: emptyList(),
                    compact = true))
                board?.mode = GridBotView.Mode.PICK_CELL
                board?.onCellTap = { x, y -> pickedCell = x to y; refreshAction() }
                caption("Tap a square on the board.")
            }
            "spot", "debug" -> {
                val showGrid = boxesFor(q.board)
                if (showGrid) {
                    body.addView(boardRow(q.board, q.board?.program ?: emptyList()))
                } else {
                    val pl = ProgramListView(ctx, fonts)
                    pl.program = q.board?.program ?: emptyList()
                    list = pl
                    body.addView(pl, LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT))
                }
                list?.selectable = true
                list?.onBlockTap = { i -> pickedBlock = i; refreshAction() }
                caption("Tap a step in the list.")
            }
            // The habit this unit teaches: write down what the box holds at
            // each step. One row is blank and the child works it out.
            "trace" -> {
                val tt = TraceTableView(ctx, fonts)
                tt.boxName = q.varName
                tt.steps = (q.board?.program ?: emptyList()).map { Blocks.word(it) }
                tt.values = q.traceOf
                tt.gapRow = q.gapRow
                body.addView(tt, LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT))
                body.addView(space(14))
                body.addView(numberChoices(q.choices))
            }
            "count" -> {
                val showGrid = boxesFor(q.board)
                // The board is context for where the steps happen. It used to
                // be dropped here because a four-row keypad left no room; now
                // that a number is one row of choices, it fits again — except
                // for questions purely about reading the listing, where a
                // shrunken board is noise beside a long program.
                val listOnly = (q.kind == "moves" || q.kind == "rows") &&
                    (q.board?.program?.size ?: 0) > 4
                val needsBoard = !listOnly && q.board != null && showGrid
                if (needsBoard) {
                    body.addView(boardRow(q.board, q.board?.program ?: emptyList(),
                        compact = true))
                } else if (q.board != null) {
                    val pl = ProgramListView(ctx, fonts)
                    pl.compact = true
                    pl.program = q.board.program
                    list = pl
                    body.addView(pl, LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT))
                }
                body.addView(space(14))
                body.addView(numberChoices(q.choices))
            }
            "choose" -> {
                body.addView(boardRow(q.board, emptyList()))
                body.addView(space(14))
                body.addView(programOptions(q.options ?: emptyList()))
            }
            "chooseText", "complete" -> {
                // Some questions are about the idea, not the board — drawing an
                // empty grid for those is noise the child has to look past.
                //
                // boxesFor() is what puts the number box on screen and says
                // whether the grid is worth drawing beside it. Without it a
                // question asking what a row does to STARS drew a grid and no
                // box at all: the subject of the question was invisible.
                if (q.board != null) {
                    val showGrid = boxesFor(q.board)
                    if (showGrid) {
                        body.addView(boardRow(q.board, q.board.program, compact = true))
                    } else {
                        val pl = ProgramListView(ctx, fonts)
                        pl.compact = true
                        pl.program = q.board.program
                        list = pl
                        body.addView(pl, LinearLayout.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.WRAP_CONTENT))
                    }
                    body.addView(space(14))
                }
                body.addView(textOptions(q.optionsText))
            }
            // There is deliberately no "truth" branch any more. It drew a
            // condition in mid-air beside a list of facts, thirty-seven times
            // word for word, and a child cannot look at a condition. Every
            // question that used it now runs on a board and asks Yes or No
            // about what happened. Leaving the branch here would let one back
            // in without a way to grade it.
            // A question about what the run actually did, answered Yes or No.
            // This replaced the "truth" screen, which showed a condition in
            // mid-air beside a list of facts: a child cannot look at a
            // condition, but they can look at a board and say whether Nupo
            // ended up on the flag.
            "yesno" -> {
                val showGrid = boxesFor(q.board)
                if (showGrid) {
                    body.addView(boardRow(q.board, q.board?.program ?: emptyList(),
                        compact = true))
                }
                body.addView(space(14))
                body.addView(textOptions(listOf("Yes", "No")))
            }
            "compare" -> {
                body.addView(boardRow(q.board, emptyList()))
                body.addView(space(12))
                body.addView(compareCards(q))
                body.addView(space(12))
                body.addView(textOptions(listOf("The same square", "Different squares")))
            }
            // ---- Number Sense: the picture carries the question ----------
            // Counting a shape that is made of other shapes: the picture is
            // the same figure as a hunt, but the answer is a number, because
            // the hidden shapes cannot be tapped without tapping their parts.
            "shapeCount", "array", "groups", "barModel",
            "countObjects", "tenFrame", "rods", "dice", "bond" -> {
                body.addView(numberPicture(q))
                body.addView(space(18))
                body.addView(numberChoices(q.choices))
                caption("Tap the number.")
            }
            "numberLine" -> {
                val v = NumberLineView(ctx, fonts).apply {
                    val pic = q.pic
                    from = pic?.from ?: 0
                    to = pic?.to ?: 10
                    labelEvery = pic?.labelEvery ?: 1
                    pic?.marker?.let { marker = it }
                    pic?.hopFrom?.let { hopFrom = it }
                    selectable = true
                    onPick = { pickedNumber = it; refreshAction() }
                }
                picView = v
                body.addView(v, LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT))
                caption("Tap a number on the line.")
            }
            "balance" -> {
                body.addView(numberPicture(q))
                body.addView(space(16))
                // "This side" and "that side" say nothing on their own — the
                // child has to guess which pan the words point at. Left and
                // right name the pans, and are worth learning at this age.
                body.addView(textOptions(listOf("Left", "Right", "Same")))
            }
            "shapeHunt" -> {
                val v = ShapeHuntView(ctx).apply {
                    setParts(q.pic?.parts ?: emptyList())
                    onPick = { pickedSet = it.toMutableSet(); refreshAction() }
                }
                picView = v
                body.addView(v, LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT))
            }
            "pattern" -> {
                body.addView(numberPicture(q))
                body.addView(space(16))
                body.addView(cellOptions(q))
            }
            "oddOneOut" -> {
                val v = OddOneOutView(ctx).apply {
                    cells = (q.pic?.cells ?: emptyList()).map { cellOf(it) }
                    onPick = { pickedOption = it; refreshAction() }
                }
                picView = v
                body.addView(v, LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT))
            }
            "sortTwo" -> {
                val v = SortTrayView(ctx, fonts).apply {
                    leftLabel = q.pic?.leftLabel ?: "YES"
                    rightLabel = q.pic?.rightLabel ?: "NO"
                    items = (q.pic?.cells ?: emptyList()).map { cellOf(it) }
                    onChange = {
                        pickedSides = it.copyOf()
                        refreshAction()
                        // The tray reflows when an item moves, so every other
                        // item is somewhere new. Re-report the geometry or a
                        // test driver taps where things used to be.
                        if (debugBuild) logTargets(q, 80)
                    }
                }
                picView = v
                pickedSides = IntArray(q.pic?.cells?.size ?: 0)
                body.addView(v, LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT))
                caption("Tap a shape to move it.")
            }
            "sizeOrder" -> {
                val v = SizeOrderView(ctx).apply {
                    sizes = q.pic?.sizes ?: emptyList()
                    kind = q.pic?.glyph ?: Glyphs.STAR
                    onPick = { pickedOrder = it.toMutableList(); refreshAction() }
                }
                picView = v
                body.addView(v, LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT))
            }
            "fractionWall" -> {
                val v = FractionWallView(ctx).apply {
                    strips = q.pic?.strips ?: emptyList()
                    referenceTop = q.pic?.ask != "biggest"
                    selectable = true
                    onPick = { pickedOption = it; refreshAction() }
                }
                picView = v
                body.addView(v, LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT))
                caption("Tap a strip.")
            }
            "fraction" -> {
                body.addView(numberPicture(q))
                body.addView(space(16))
                // The two circles sit side by side, so name them by where they
                // are. "This one" and "that one" point at nothing on their own.
                val twoCircles = (q.pic?.otherSlices ?: 0) > 0
                body.addView(textOptions(
                    if (twoCircles) listOf("Left", "Right") else q.optionsText))
            }
            "mirror" -> {
                val v = MirrorView(ctx).apply {
                    cols = (q.pic?.cols ?: 0).takeIf { it > 0 } ?: 6
                    rows = (q.pic?.rows ?: 0).takeIf { it > 0 } ?: 5
                    given = (q.pic?.given ?: emptyList()).toSet()
                    onPick = { pickedCells = it.toMutableSet(); refreshAction() }
                }
                picView = v
                body.addView(v, LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT))
                caption("Tap the empty squares.")
            }
            "fix", "inverse", "constrain" -> {
                body.addView(boardRow(q.board, emptyList(), showPath = q.shape == "inverse"))
                body.addView(space(16))
                val bk = BlockBankView(ctx, fonts)
                bk.setBlocks(q.blocks, q.slots, palette = q.reusable)
                bk.onChange = { builtProgram = it; refreshAction() }
                bank = bk
                body.addView(bk, LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
                caption(
                    if (q.reusable) "Fill every box, then run it. Steps can be used again."
                    else "Tap the steps to fill the boxes, then run it."
                )
            }
            in PuzzleShapes.all -> renderPuzzle(q)
        }
        body.addView(space(8))

        action.label =
            if (q.shape in setOf("fix", "inverse", "constrain")) "Run it" else "Check"
        action.tint(Ink.primary, Ink.primaryLedge)
        action.onTap = { submit(q) }
        refreshAction()
    }

    /**
     * A Puzzles and Logic or Reasoning question: the drawing, then the answer.
     *
     * Which answer row appears is decided by the QUESTION, not by its shape —
     * a question that stores four numbers gets number buttons, one that stores
     * drawn shapes gets shape buttons. That way a new shape needs a drawing and
     * nothing else, and no shape can end up with an answer row that cannot
     * express its answer.
     */
    private fun renderPuzzle(q: Curriculum.Question) {
        val pic = q.pic
        val drawing: View? = when {
            PuzzlePicView.draws(pic) -> PuzzlePicView(ctx, fonts).apply { this.pic = pic }
            ReasonPicView.draws(pic) -> ReasonPicView(ctx, fonts).apply { this.pic = pic }
            else -> null
        }
        if (drawing != null) {
            picView = drawing
            body.addView(drawing, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT))
            body.addView(space(16))
        }
        when {
            q.answerType == "number" -> {
                body.addView(numberChoices(q.choices))
                caption("Tap the number.")
            }
            q.optionCells.isNotEmpty() -> {
                body.addView(cellOptions(q))
                caption("Tap a shape.")
            }
            // Band d answers that are themselves drawings. Each is its own row
            // because each needs a different amount of room: four nets or four
            // solids need two columns to stay readable, four side views and
            // four flat shapes fit in one line.
            q.optionNets.isNotEmpty() -> {
                body.addView(drawnGrid(q.optionNets.size) { c, box, i ->
                    Solid.netCells(c, gridPaint, fonts, ctx.dpf(1f), q.optionNets[i],
                        box.left + dp(10), box.top + dp(10),
                        box.width() - dp(20), box.height() - dp(20),
                        ctx.dpf(26f), emptyList(), "", Solid.TOP)
                })
                caption("Tap a net.")
            }
            q.optionSections.isNotEmpty() -> {
                body.addView(drawnGrid(q.optionSections.size) { c, box, i ->
                    Solid.solidCut(c, gridPaint, q.optionSections[i],
                        box.left + dp(8), box.top + dp(8),
                        box.width() - dp(16), box.height() - dp(16))
                })
                caption("Tap a cut.")
            }
            q.optionCubes.isNotEmpty() -> {
                body.addView(drawnGrid(q.optionCubes.size) { c, box, i ->
                    Solid.voxels(c, gridPaint, q.optionCubes[i],
                        box.left + dp(12), box.top + dp(10),
                        box.width() - dp(24), box.height() - dp(20), ctx.dpf(22f))
                })
                caption("Tap a shape.")
            }
            q.optionViews.isNotEmpty() -> {
                body.addView(drawnRow(q.optionViews.size, 94) { c, box, i ->
                    paintSideView(c, box, q.optionViews[i])
                })
                caption("Tap a view.")
            }
            q.optionShapes.isNotEmpty() -> {
                body.addView(drawnRow(q.optionShapes.size, 76) { c, box, i ->
                    Solid.flat(c, gridPaint, q.optionShapes[i],
                        box.centerX(), box.centerY(),
                        minOf(box.width(), box.height()) * 0.26f)
                })
                caption("Tap a shape.")
            }
            q.optionBits.isNotEmpty() -> {
                body.addView(drawnStack(q.optionBits.size, 50) { c, box, i ->
                    paintBitRow(c, box, q.optionBits[i], q.pic?.bulbValues.orEmpty())
                })
                caption("Tap a row of bulbs.")
            }
            else -> body.addView(textOptions(q.optionsText))
        }
    }

    /** One paint for every drawn option; they are painted one at a time. */
    private val gridPaint = Paint(Paint.ANTI_ALIAS_FLAG)

    /** Answer cards two to a row, for drawings that need the room. */
    private fun drawnGrid(
        count: Int, paint: (Canvas, RectF, Int) -> Unit,
    ): View = LinearLayout(ctx).apply {
        orientation = LinearLayout.VERTICAL
        var i = 0
        while (i < count) {
            val row = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL }
            for (k in 0 until 2) {
                val idx = i + k
                if (idx >= count) {
                    row.addView(View(ctx), LinearLayout.LayoutParams(0, dp(124), 1f).apply {
                        marginStart = if (k == 0) 0 else dp(10)
                    })
                    continue
                }
                val b = PushButton(ctx, fonts).apply {
                    radius = 14f
                    face = Ink.surface; ledgeColor = Ink.ledge
                    painter = { c, box -> paint(c, box, idx) }
                }
                b.onTap = { pickedOption = idx; repaintOptions(); refreshAction() }
                optionButtons.add(b)
                row.addView(b, LinearLayout.LayoutParams(0, dp(124), 1f).apply {
                    marginStart = if (k == 0) 0 else dp(10)
                })
            }
            addView(row, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                topMargin = if (i == 0) 0 else dp(12)
            })
            i += 2
        }
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    }

    /** Answer cards side by side, for drawings that stay readable small. */
    private fun drawnRow(
        count: Int, heightDp: Int, paint: (Canvas, RectF, Int) -> Unit,
    ): View = LinearLayout(ctx).apply {
        orientation = LinearLayout.HORIZONTAL
        for (i in 0 until count) {
            val b = PushButton(ctx, fonts).apply {
                radius = 14f
                face = Ink.surface; ledgeColor = Ink.ledge
                painter = { c, box -> paint(c, box, i) }
            }
            b.onTap = { pickedOption = i; repaintOptions(); refreshAction() }
            optionButtons.add(b)
            addView(b, LinearLayout.LayoutParams(0, dp(heightDp), 1f).apply {
                marginStart = if (i == 0) 0 else dp(10)
            })
        }
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    }

    /** Answer cards one above another, for rows of bulbs. */
    private fun drawnStack(
        count: Int, heightDp: Int, paint: (Canvas, RectF, Int) -> Unit,
    ): View = LinearLayout(ctx).apply {
        orientation = LinearLayout.VERTICAL
        for (i in 0 until count) {
            val b = PushButton(ctx, fonts).apply {
                radius = 14f
                face = Ink.surface; ledgeColor = Ink.ledge
                painter = { c, box -> paint(c, box, i) }
            }
            b.onTap = { pickedOption = i; repaintOptions(); refreshAction() }
            optionButtons.add(b)
            addView(b, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(heightDp)).apply {
                topMargin = if (i == 0) 0 else dp(10)
            })
        }
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    }

    /** What a pile of cubes looks like from one side: columns of squares. */
    private fun paintSideView(c: Canvas, box: RectF, heights: List<Int>) {
        if (heights.isEmpty()) return
        val n = heights.size
        val tallest = maxOf(3, heights.max())
        val sz = minOf((box.width() - dp(14)) / n, (box.height() - dp(14)) / tallest)
        val ox = box.left + (box.width() - n * sz) / 2f
        val base = box.bottom - dp(7)
        heights.forEachIndexed { col, h ->
            for (z in 0 until h) {
                Draw.rrect(c, gridPaint, ox + col * sz + 0.5f, base - (z + 1) * sz + 0.5f,
                    sz - 1f, sz - 1f, 2f, Solid.FRONT, Ink.primaryLedge, 1f)
            }
        }
    }

    /** One candidate row of lit and unlit bulbs. */
    private fun paintBitRow(c: Canvas, box: RectF, bits: List<Boolean>, values: List<Int>) {
        val n = bits.size
        if (n == 0) return
        val inset = dp(24)
        val w = box.width() - inset * 2
        val cell = w / n
        val r = minOf(cell * 0.3f, ctx.dpf(20f))
        for (i in 0 until n) {
            val cx = box.left + inset + i * cell + cell / 2f
            val cy = box.centerY()
            if (bits[i]) {
                gridPaint.style = Paint.Style.FILL; gridPaint.color = 0x47FDC703
                c.drawCircle(cx, cy, r + ctx.dpf(6f), gridPaint)
            }
            gridPaint.style = Paint.Style.FILL
            gridPaint.color = if (bits[i]) Ink.accent else 0xFFE4E6EF.toInt()
            c.drawCircle(cx, cy, r, gridPaint)
            gridPaint.style = Paint.Style.STROKE; gridPaint.strokeWidth = ctx.dpf(1.5f)
            gridPaint.color = if (bits[i]) Ink.accentLedge else Ink.ledge
            c.drawCircle(cx, cy, r, gridPaint)
            gridPaint.style = Paint.Style.FILL
        }
    }

    /** Turns a [Curriculum.CellSpec] into something the views can draw. */
    private fun cellOf(c: Curriculum.CellSpec) = Cell(
        c.kind,
        when (c.color) {
            "accent" -> Ink.accent
            "good" -> Ink.good
            else -> Ink.primary
        },
        c.rotation,
    )

    /**
     * The drawing a Number Sense question is about.
     *
     * Every one of these plays as it appears: a child who watches seven stars
     * land has already been counted to seven, which is most of the answer.
     */
    /** A picture built from its [Curriculum.Pic] alone, for teach cards. */
    private fun pictureFor(pic: Curriculum.Pic): View = when (pic.kind) {
        "count" -> CountGroupView(ctx).apply {
            glyph = pic.glyph; splitAt = pic.splitAt; count = pic.n
        }
        "tenFrame" -> TenFrameView(ctx).apply {
            glyph = pic.glyph; secondFilled = pic.second; filled = pic.filled
        }
        "rods" -> RodsView(ctx).apply { value = pic.n }
        "dice" -> DiceView(ctx).apply {
            faces = if (pic.faces.isNotEmpty()) pic.faces else listOf(pic.n)
        }
        "bond" -> NumberBondView(ctx, fonts).apply {
            whole = pic.whole; left = pic.left; right = pic.right; gap = pic.gap
        }
        "balance" -> BalanceScaleView(ctx).apply {
            glyph = pic.glyph; leftCount = pic.leftCount; rightCount = pic.rightCount
        }
        "numberLine" -> NumberLineView(ctx, fonts).apply {
            from = pic.from; to = pic.to; labelEvery = pic.labelEvery
            pic.marker?.let { marker = it }
            pic.hopFrom?.let { hopFrom = it }
        }
        "pattern" -> PatternStripView(ctx, fonts).apply {
            cells = pic.cells.map { cellOf(it) }; gapAt = pic.gapAt
        }
        "oddOneOut" -> OddOneOutView(ctx).apply {
            cells = pic.cells.map { cellOf(it) }
        }
        "shapeHunt", "shapeCount" -> ShapeHuntView(ctx).apply {
            setParts(pic.parts)
        }
        "array" -> ArrayGridView(ctx).apply {
            glyph = pic.glyph; cols = pic.cols; rows = pic.rows
        }
        "groups" -> GroupsView(ctx).apply {
            glyph = pic.glyph; per = pic.per; groups = pic.groupCount
        }
        "barModel" -> BarModelView(ctx).apply { a = pic.a; b = pic.b }
        "fractionWall" -> FractionWallView(ctx).apply {
            strips = pic.strips
            referenceTop = pic.ask != "biggest"
        }
        "sizeOrder" -> SizeOrderView(ctx).apply {
            sizes = pic.sizes; kind = pic.glyph
        }
        "fraction" -> FractionView(ctx).apply {
            slices = pic.slices; shaded = pic.shaded
            otherSlices = pic.otherSlices; otherShaded = pic.otherShaded
        }
        "mirror" -> MirrorView(ctx).apply {
            cols = pic.cols.takeIf { it > 0 } ?: 6
            rows = pic.rows.takeIf { it > 0 } ?: 5
            given = pic.given.toSet()
        }
        "sortTwo" -> SortTrayView(ctx, fonts).apply {
            leftLabel = pic.leftLabel; rightLabel = pic.rightLabel
            items = pic.cells.map { cellOf(it) }
        }
        // Puzzles and Logic and Reasoning. Without these the teach card for
        // every stop in both new skills showed its words over empty space:
        // "Find the step between two numbers, then check it works for every
        // pair" with no pair of numbers under it, which teaches nothing.
        else -> when {
            PuzzlePicView.draws(pic) -> PuzzlePicView(ctx, fonts).apply { this.pic = pic }
            ReasonPicView.draws(pic) -> ReasonPicView(ctx, fonts).apply { this.pic = pic }
            else -> View(ctx)
        }
    }

    /** Replays whichever picture this is. */
    private fun playPicture(v: View) {
        when (v) {
            is CountGroupView -> v.play()
            is TenFrameView -> v.play()
            is RodsView -> v.play()
            is DiceView -> v.play()
            is NumberBondView -> v.play()
            is BalanceScaleView -> v.play()
            is NumberLineView -> v.play()
            is FractionView -> v.play()
            is MirrorView -> v.play()
            is SortTrayView -> v.play()
            is SizeOrderView -> v.play()
            is ShapeHuntView -> v.play()
            is ArrayGridView -> v.play()
            is GroupsView -> v.play()
            is BarModelView -> v.play()
            is FractionWallView -> v.play()
            is OddOneOutView -> v.play()
            is PatternStripView -> v.play()
            else -> Unit
        }
    }

    private fun numberPicture(q: Curriculum.Question): View {
        val pic = q.pic
        val v: View = when (q.shape) {
            "countObjects" -> CountGroupView(ctx).apply {
                glyph = pic?.glyph ?: Glyphs.STAR
                splitAt = pic?.splitAt ?: -1
                count = pic?.n ?: 0
                post { play() }
            }
            "tenFrame" -> TenFrameView(ctx).apply {
                glyph = pic?.glyph ?: Glyphs.CIRCLE
                secondFilled = pic?.second ?: -1
                filled = pic?.filled ?: 0
                post { play() }
            }
            "rods" -> RodsView(ctx).apply {
                value = pic?.n ?: 0
                post { play() }
            }
            "dice" -> DiceView(ctx).apply {
                faces = pic?.faces ?: listOf(pic?.n ?: 1)
                post { play() }
            }
            "shapeCount" -> ShapeHuntView(ctx).apply {
                setParts(pic?.parts ?: emptyList())
                post { play() }
            }
            "array" -> ArrayGridView(ctx).apply {
                glyph = pic?.glyph ?: Glyphs.CIRCLE
                cols = pic?.cols ?: 0
                rows = pic?.rows ?: 0
                post { play() }
            }
            "groups" -> GroupsView(ctx).apply {
                glyph = pic?.glyph ?: Glyphs.STAR
                per = pic?.per ?: 0
                groups = pic?.groupCount ?: 0
                post { play() }
            }
            "barModel" -> BarModelView(ctx).apply {
                a = pic?.a ?: 0
                b = pic?.b ?: 0
                post { play() }
            }
            "bond" -> NumberBondView(ctx, fonts).apply {
                whole = pic?.whole
                left = pic?.left
                right = pic?.right
                gap = pic?.gap ?: "right"
                post { play() }
            }
            "balance" -> BalanceScaleView(ctx).apply {
                glyph = pic?.glyph ?: Glyphs.STAR
                leftCount = pic?.leftCount ?: 0
                rightCount = pic?.rightCount ?: 0
                post { play() }
            }
            "pattern" -> PatternStripView(ctx, fonts).apply {
                cells = (pic?.cells ?: emptyList()).map { cellOf(it) }
                gapAt = pic?.gapAt ?: -1
            }
            "fraction" -> FractionView(ctx).apply {
                slices = pic?.slices ?: 4
                shaded = pic?.shaded ?: 1
                otherSlices = pic?.otherSlices ?: 0
                otherShaded = pic?.otherShaded ?: 0
                post { play() }
            }
            else -> View(ctx)
        }
        picView = v
        return v
    }

    /** The choices for a pattern question, drawn rather than written. */
    private fun cellOptions(q: Curriculum.Question): View = LinearLayout(ctx).apply {
        orientation = LinearLayout.HORIZONTAL
        val opts = q.pic?.cells.orEmpty()
        // A pattern's options live in optionCells, not in the strip itself.
        val choices = q.optionCells.map { cellOf(it) }
        choices.forEachIndexed { i, c ->
            val b = PushButton(ctx, fonts).apply {
                radius = 16f
                face = Ink.surface; ledgeColor = Ink.ledge
                painter = { canvas, box ->
                    val p = Paint(Paint.ANTI_ALIAS_FLAG)
                    Glyphs.draw(canvas, c.kind, box.centerX(), box.centerY(),
                        minOf(box.width(), box.height()) * 0.28f, c.color,
                        if (c.color == Ink.accent) Ink.accentLedge else Ink.primaryLedge,
                        p, c.rotation)
                }
            }
            b.onTap = { pickedOption = i; repaintOptions(); refreshAction() }
            optionButtons.add(b)
            addView(b, LinearLayout.LayoutParams(0, dp(76), 1f).apply {
                marginStart = if (i == 0) 0 else dp(10)
            })
        }
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    }

    /** What is true right now, as a short list a child can check against. */
    private fun factsCard(facts: List<String>): View = LinearLayout(ctx).apply {
        orientation = LinearLayout.VERTICAL
        background = roundRect(Ink.surface, ctx.dpf(18f), Ink.line, dp(2))
        setPadding(dp(16), dp(14), dp(16), dp(14))
        addView(label(ctx, fonts, "RIGHT NOW", 11f, Ink.muted, black = true).apply {
            letterSpacing = 0.12f
        })
        facts.forEachIndexed { i, f ->
            addView(space(if (i == 0) 8 else 6))
            addView(label(ctx, fonts, "•  $f", 15f, Ink.text).apply {
                typeface = fonts.body
            })
        }
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    }

    /** The condition itself, given the weight of the thing being judged. */
    private fun exprCard(expr: String): View = LinearLayout(ctx).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER
        background = roundRect(0xFFF3EFFF.toInt(), ctx.dpf(18f), Ink.primary, dp(2))
        setPadding(dp(16), dp(18), dp(16), dp(18))
        addView(label(ctx, fonts, expr, 22f, Ink.primary,
            black = true, align = Gravity.CENTER))
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    }

    private fun caption(text: String) {
        body.addView(space(10))
        body.addView(label(ctx, fonts, text, 13f, Ink.muted, align = Gravity.CENTER).apply {
            typeface = fonts.body
        })
    }

    private var boxesView: BoxesView? = null

    /**
     * Adds the named boxes above the board when a question has any, and says
     * whether the grid itself is still worth drawing.
     *
     * On a variables board with no flag, star or wall the grid is an empty
     * lattice with a motionless owl on it. The boxes are the subject; the grid
     * would only be there to fill space.
     */
    private fun boxesFor(b: Curriculum.Board?): Boolean {
        if (b == null || b.vars.isEmpty()) return true
        val bv = BoxesView(ctx, fonts)
        bv.boxes = b.vars.entries.map { it.key to it.value }
        boxesView = bv
        body.addView(bv, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        body.addView(space(14))
        return b.hasWorld
    }

    /**
     * Steps a demo that has nothing to animate on the grid.
     *
     * A variables demo moves no one; what changes is the number in the box. The
     * rows light up one at a time and the box ticks over with them.
     */
    private fun playBoxes(b: Curriculum.Board) {
        val g = generation
        val trace = Curriculum.Sim.run(b, b.program).trace
        fun step(i: Int) {
            if (g != generation) return
            if (i >= b.program.size) { list?.running = -1; return }
            list?.running = i
            boxesView?.boxes = trace.getOrElse(i + 1) { trace.last() }
                .entries.map { it.key to it.value }
            handler.postDelayed({ step(i + 1) }, 620)
        }
        boxesView?.boxes = b.vars.entries.map { it.key to it.value }
        handler.postDelayed({ step(0) }, 420)
    }

    /** The board row, so it can be grown to fill whatever space is left over. */
    private var boardRowView: View? = null
    private var boardView: View? = null

    /** Board on the left, the program listing beside it when there is one. */
    private fun boardRow(
        b: Curriculum.Board?, program: List<String>, showPath: Boolean = false,
        stack: Boolean = false, compact: Boolean = false,
    ): View {
        val gb = GridBotView(ctx)
        gb.setBoard(b, showPath)
        board = gb
        boardView = gb

        val row: View
        if (program.isEmpty()) {
            row = FrameLayout(ctx).apply {
                addView(gb, FrameLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, dp(MIN_BOARD), Gravity.CENTER))
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT)
            }
        } else {
            val pl = ProgramListView(ctx, fonts)
            pl.compact = compact
            pl.program = program
            list = pl
            // A board is only ever as big as the narrower of its two
            // dimensions. Beside a 134dp listing on a phone that caps it at
            // about 176dp, which is fine for 5x5 but makes a 7x7 grid a
            // postage stamp. Big boards get the full width and the listing
            // goes underneath.
            val wide = stack || (b?.w ?: 5) >= 6 || (b?.h ?: 5) >= 6
            row = if (wide) {
                LinearLayout(ctx).apply {
                    orientation = LinearLayout.VERTICAL
                    addView(gb, LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT, dp(MIN_BOARD)))
                    addView(pl, LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                        topMargin = dp(12)
                    })
                    layoutParams = LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT)
                }
            } else {
                LinearLayout(ctx).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                    addView(gb, LinearLayout.LayoutParams(0, dp(MIN_BOARD), 1f))
                    addView(pl, LinearLayout.LayoutParams(dp(134),
                        ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                        marginStart = dp(10)
                    })
                    layoutParams = LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT)
                }
            }
        }
        boardRowView = row
        growBoardToFit()
        return row
    }

    /**
     * Hands the board whatever vertical space the rest of the question did not
     * use.
     *
     * Only the BOARD is resized, never the row: the row stays wrap-content so a
     * long program listing always gets the height it asked for. Sizing the row
     * instead clipped the listing top and bottom.
     *
     * The measurement has to wait for a real layout pass — on the first frame
     * the ScrollView still reports zero height, and sizing against that made the
     * board smaller than it started.
     */
    private fun growBoardToFit() {
        val gb = boardView ?: return
        val vto = scroller.viewTreeObserver
        vto.addOnGlobalLayoutListener(object :
            android.view.ViewTreeObserver.OnGlobalLayoutListener {
            override fun onGlobalLayout() {
                if (boardView !== gb) {                    // moved on already
                    scroller.viewTreeObserver.removeOnGlobalLayoutListener(this)
                    return
                }
                // gb must have been measured too. On an early pass its height
                // is still 0, which made the row's whole height count as other
                // content — slack collapsed and the board clamped to its floor.
                if (scroller.height <= 0 || body.height <= 0 || gb.height <= 0) return
                scroller.viewTreeObserver.removeOnGlobalLayoutListener(this)
                // body is stretched to the viewport by isFillViewport, so its
                // height already includes the empty space we are trying to
                // reclaim. Add up what the other children actually occupy.
                var rest = body.paddingTop + body.paddingBottom
                for (i in 0 until body.childCount) {
                    val c = body.getChildAt(i)
                    // Everything except the board itself counts as taken. For a
                    // stacked layout that includes the program listing sitting
                    // underneath it, which otherwise got pushed off screen.
                    rest += if (c === boardRowView) (c.height - gb.height) else c.height
                }
                val slack = scroller.height - rest - dp(8)
                // A board is square, so height beyond its own width is dead
                // space inside the row, not a bigger board.
                val widthCap = if (gb.width > 0) gb.width else dp(MAX_BOARD)
                // maxOf guards the case where the column is narrower than the
                // minimum board: coerceIn throws outright if max < min, and
                // that crash inside a layout listener takes the gate down.
                val hi = maxOf(dp(HARD_MIN_BOARD), minOf(dp(MAX_BOARD), widthCap))
                val want = if (slack >= dp(MIN_BOARD)) slack.coerceAtMost(hi)
                           else slack.coerceIn(dp(HARD_MIN_BOARD), hi)
                if (want != gb.height) {
                    gb.layoutParams = gb.layoutParams.also { it.height = want }
                    gb.requestLayout()
                }
            }
        })
    }

    /**
     * Four numbers to tap, one of them right.
     *
     * This was a typed keypad. Tapping beats typing for this age: it is one
     * gesture instead of two, it cannot be left half-entered, and it costs a
     * single row instead of four — which matters on a screen already carrying a
     * board and a program listing. The wrong options are the mistakes children
     * actually make (one too many, one too few), so the answer still has to be
     * worked out.
     */
    private fun numberChoices(choices: List<Int>): View = LinearLayout(ctx).apply {
        orientation = LinearLayout.HORIZONTAL
        val order = choices.shuffled().also { shownChoices = it }
        order.forEachIndexed { i, n ->
            val b = PushButton(ctx, fonts).apply {
                label = "$n"; textSize = 22f; radius = 16f
                face = Ink.surface; ledgeColor = Ink.ledge; textColor = Ink.text
            }
            b.onTap = {
                pickedNumber = n
                optionButtons.forEachIndexed { j, v ->
                    v.tint(if (j == i) 0xFFEDE6FF.toInt() else Ink.surface,
                        if (j == i) Ink.primary else Ink.ledge, Ink.text)
                }
                refreshAction()
            }
            optionButtons.add(b)
            addView(b, LinearLayout.LayoutParams(0, dp(62), 1f).apply {
                marginStart = if (i == 0) 0 else dp(10)
            })
        }
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    }

    /** Answer cards that each show a whole program as a row of chips. */
    private fun programOptions(options: List<List<String>>): View = LinearLayout(ctx).apply {
        orientation = LinearLayout.VERTICAL
        options.forEachIndexed { i, prog ->
            val b = PushButton(ctx, fonts).apply {
                radius = 16f
                face = Ink.surface; ledgeColor = Ink.ledge
                painter = { c, box -> paintProgramRow(c, box, prog, i) }
            }
            b.onTap = { pickedOption = i; repaintOptions(); refreshAction() }
            optionButtons.add(b)
            addView(b, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(62)).apply {
                topMargin = if (i == 0) 0 else dp(10)
            })
        }
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    }

    private fun paintProgramRow(c: Canvas, box: RectF, prog: List<String>, i: Int) {
        val p = Paint(Paint.ANTI_ALIAS_FLAG)
        // Row letter, so the child can name the option they mean.
        p.color = if (pickedOption == i) Ink.primary else Ink.muted
        p.typeface = fonts.black
        p.textSize = ctx.dpf(14f)
        p.textAlign = Paint.Align.CENTER
        c.drawText(('A' + i).toString(), box.left + ctx.dpf(22f),
            box.centerY() - (p.descent() + p.ascent()) / 2f, p)

        // Each chip gets the width its own text needs, not a fixed slot.
        // A fixed slot meant "DO 2 TIMES" spilled into the chip beside it and
        // the two words ran together into nonsense.
        val avail = box.right - ctx.dpf(12f) - (box.left + ctx.dpf(44f))
        val gap = ctx.dpf(6f)
        var size = 9.5f
        var widths: List<Float>
        while (true) {
            p.typeface = fonts.extra
            p.textSize = ctx.dpf(size)
            widths = prog.map { t ->
                if (t in Blocks.ARROWS) maxOf(ctx.dpf(14f), p.measureText(Blocks.word(t)))
                else p.measureText(Blocks.shortWord(t))
            }
            val total = widths.sum() + gap * (prog.size - 1).coerceAtLeast(0)
            if (total <= avail || size <= 6.5f) break
            size -= 0.5f
        }
        val total = widths.sum() + gap * (prog.size - 1).coerceAtLeast(0)
        var x = box.left + ctx.dpf(44f) + ((avail - total) / 2f).coerceAtLeast(0f)
        prog.forEachIndexed { k, token ->
            val w = widths[k]
            if (token in Blocks.ARROWS) {
                Blocks.drawArrow(c, x + w / 2, box.centerY() - ctx.dpf(5f),
                    ctx.dpf(7f), token, Ink.text, ctx)
                p.color = Ink.muted
                p.typeface = fonts.body
                p.textSize = ctx.dpf(size)
                c.drawText(Blocks.word(token), x + w / 2, box.bottom - ctx.dpf(11f), p)
            } else {
                p.color = Ink.text
                p.typeface = fonts.extra
                p.textSize = ctx.dpf(size)
                c.drawText(Blocks.shortWord(token), x + w / 2,
                    box.centerY() + ctx.dpf(1f), p)
            }
            x += w + gap
        }
    }

    private fun textOptions(options: List<String>): View = LinearLayout(ctx).apply {
        orientation = LinearLayout.VERTICAL
        options.forEachIndexed { i, text ->
            val b = PushButton(ctx, fonts).apply {
                label = text; textSize = 16f; radius = 16f
                face = Ink.surface; ledgeColor = Ink.ledge; textColor = Ink.text
            }
            b.onTap = {
                pickedOption = i
                pickedBool = i == 0    // compare uses "same tile" first
                repaintOptions(); refreshAction()
            }
            optionButtons.add(b)
            addView(b, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(56)).apply {
                topMargin = if (i == 0) 0 else dp(10)
            })
        }
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    }

    /**
     * The two programs a compare question is about, each with its own play
     * button — the child can run them and watch, which is the point of the
     * question: order changes the ending.
     */
    private fun compareCards(q: Curriculum.Question): View = LinearLayout(ctx).apply {
        orientation = LinearLayout.VERTICAL
        (q.options ?: emptyList()).forEachIndexed { i, prog ->
            val b = PushButton(ctx, fonts).apply {
                radius = 16f
                face = Ink.surface; ledgeColor = Ink.ledge
                painter = { c, box ->
                    paintProgramRow(c, box, prog, i)
                    val p = Paint(Paint.ANTI_ALIAS_FLAG)
                    p.color = Ink.primary
                    p.typeface = fonts.extra
                    p.textSize = ctx.dpf(12f)
                    p.textAlign = Paint.Align.RIGHT
                    c.drawText("RUN", box.right - ctx.dpf(16f),
                        box.centerY() - (p.descent() + p.ascent()) / 2f, p)
                }
            }
            b.onTap = {
                board?.setBoard(q.board)
                board?.play(prog)
            }
            addView(b, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(58)).apply {
                topMargin = if (i == 0) 0 else dp(8)
            })
        }
        layoutParams = LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    }

    private fun repaintOptions() {
        optionButtons.forEachIndexed { i, v ->
            if (i == pickedOption) v.tint(0xFFEDE6FF.toInt(), Ink.primary, Ink.text)
            else v.tint(Ink.surface, Ink.ledge, Ink.text)
        }
    }

    private fun hasAnswer(q: Curriculum.Question): Boolean = when (q.shape) {
        "predict" -> pickedCell != null
        "spot", "debug" -> pickedBlock >= 0
        "count", "trace" -> pickedNumber != NO_NUMBER
        "choose", "chooseText", "complete", "compare", "yesno" -> pickedOption >= 0
        "fix", "inverse", "constrain" -> bank?.complete() == true
        "countObjects", "tenFrame", "rods", "dice", "bond",
        "shapeCount", "array", "groups", "barModel" -> pickedNumber != NO_NUMBER
        "numberLine" -> pickedNumber != NO_NUMBER
        "balance", "oddOneOut", "pattern", "fraction",
        "fractionWall" -> pickedOption >= 0
        "shapeHunt" -> pickedSet.isNotEmpty()
        "sizeOrder" -> pickedOrder.size == (q.pic?.sizes?.size ?: 0)
        "mirror" -> pickedCells.isNotEmpty()
        // Sorting starts with everything in the left tray, which is a valid
        // answer to "none of these are round" — so it is always submittable.
        "sortTwo" -> true
        // Puzzles and Logic and Reasoning: whichever row the question put on
        // screen is the one that has to have been touched.
        in PuzzleShapes.all ->
            if (q.answerType == "number") pickedNumber != NO_NUMBER else pickedOption >= 0
        else -> false
    }

    private fun refreshAction() {
        val q = items.getOrNull(index)?.question ?: return
        action.enabledLook = !locked && hasAnswer(q)
    }

    // ---- hint

    private fun revealHint() {
        if (hintShown) return
        val q = items.getOrNull(index)?.question ?: return
        hintShown = true
        hintButton.enabledLook = false
        val card = label(ctx, fonts, q.hint, 15f, Ink.text).apply {
            typeface = fonts.body
            background = roundRect(0xFFFFF6DA.toInt(), ctx.dpf(14f), Ink.accent, dp(2))
            setPadding(dp(14), dp(12), dp(14), dp(12))
            setLineSpacing(dp(3).toFloat(), 1f)
            alpha = 0f
        }
        hintCard = card
        body.addView(card, 1)
        body.addView(space(12), 2)
        card.animate().alpha(1f).setDuration(220).start()
    }

    // ---- grading

    private fun submit(q: Curriculum.Question) {
        if (locked || !hasAnswer(q)) return

        // Build-a-program answers are shown running before they are judged: the
        // point of the question is watching what the program does.
        if (q.shape in setOf("fix", "inverse", "constrain")) {
            locked = true
            action.enabledLook = false
            bank?.lock()
            val program = bank?.program() ?: emptyList()
            board?.setBoard(q.board)
            board?.play(program, onDone = { grade(q, q.isCorrectOrder(program)) })
            return
        }

        val correct = when (q.shape) {
            "predict" -> pickedCell == q.answerCell
            "spot", "debug" -> pickedBlock == q.answerInt
            "count", "trace" -> pickedNumber == q.answerInt
            "choose", "chooseText", "complete" -> pickedOption == q.answerInt
            // textOptions sets pickedBool from the FIRST option, which is
            // "Yes" here and "The same square" for a compare.
            "compare", "yesno" -> pickedBool == q.answerBool
            "countObjects", "tenFrame", "rods", "dice", "bond", "numberLine",
            "shapeCount", "array", "groups", "barModel" -> pickedNumber == q.answerInt
            "balance", "oddOneOut", "pattern", "fraction",
            "fractionWall" -> pickedOption == q.answerInt
            // Finding shapes is graded by WHAT was found, not by which index:
            // several pieces are triangles and any of them is a right answer.
            "shapeHunt" -> {
                val hunt = picView as? ShapeHuntView
                val kinds = hunt?.kinds().orEmpty()
                val want = kinds.indices.filter { kinds[it] == (q.pic?.target ?: "") }.toSet()
                pickedSet == want
            }
            // Graded against the authored answer, not against what the view
            // would compute: one source of truth means the Python that writes
            // the question and the Kotlin that marks it cannot drift apart.
            "sizeOrder" -> pickedOrder == q.answerInts
            "mirror" -> pickedCells == q.answerCells
            // answerInts holds which tray each item belongs in.
            "sortTwo" -> pickedSides.toList() == q.answerInts
            // Graded against the stored answer, which a second program worked
            // out from the words the child reads (tools/curriculum/pz_grade.py)
            // rather than from the data the question was built from.
            in PuzzleShapes.all ->
                if (q.answerType == "number") pickedNumber == q.answerInt
                else pickedOption == q.answerInt
            else -> false
        }
        grade(q, correct)
    }

    private fun grade(q: Curriculum.Question, correct: Boolean) {
        android.util.Log.d("NupoGate", "grade ${q.id} ${q.shape} correct=$correct")
        locked = true
        answered++
        if (correct) correctCount++
        progress.value = answered

        Curriculum.Progress.resolve(ctx, q, correct)
        // Only ladder questions move the cursor. A review question is a repeat of
        // one already passed, so advancing on it would skip fresh content.
        if (!isReviewItem()) Curriculum.Progress.advance(ctx, skill)

        // Show the verdict on whatever the child actually touched.
        when (q.shape) {
            "predict" -> pickedCell?.let { board?.showVerdict(it, correct) }
            "spot", "debug" -> list?.showVerdict(pickedBlock, correct)
            "fix", "inverse", "constrain" -> bank?.tintVerdict(correct)
            "shapeHunt", "sizeOrder", "mirror", "sortTwo", "numberLine",
            "oddOneOut", "fractionWall" ->
                (picView as? NumberView)?.showVerdict(correct)
            // the chosen number is already tinted; mark it right or wrong
            in PuzzleShapes.all -> if (q.answerType == "number") {
                optionButtons.getOrNull(shownChoices.indexOf(pickedNumber))?.tint(
                    if (correct) Ink.goodWash else Ink.badWash,
                    if (correct) Ink.good else Ink.bad, Ink.text)
            } else {
                optionButtons.getOrNull(pickedOption)?.tint(
                    if (correct) Ink.goodWash else Ink.badWash,
                    if (correct) Ink.good else Ink.bad, Ink.text)
            }
            "count", "trace", "countObjects", "tenFrame", "rods", "dice",
            "bond", "shapeCount", "array", "groups", "barModel" -> optionButtons
                .getOrNull(shownChoices.indexOf(pickedNumber))?.tint(
                    if (correct) Ink.goodWash else Ink.badWash,
                    if (correct) Ink.good else Ink.bad, Ink.text)
            else -> optionButtons.getOrNull(pickedOption)?.tint(
                if (correct) Ink.goodWash else Ink.badWash,
                if (correct) Ink.good else Ink.bad, Ink.text,
            )
        }
        play(if (correct) sndGood else sndBad)
        showDrawer(correct, if (correct) praise() else explain(q))
    }

    /** The first item of a session can be a repeat pulled from the review queue. */
    private fun isReviewItem(): Boolean = items.getOrNull(index)?.review == true

    private fun praise(): String = listOf(
        "Exactly right.", "That is the one.", "Sharp thinking.",
        "Nailed it.", "Spot on.",
    ).random()

    /** Says what the answer was, in the words of the question, not just "wrong". */
    private fun explain(q: Curriculum.Question): String = when (q.shape) {
        "predict" -> q.answerCell?.let {
            "He ends up ${it.second} squares up and ${it.first} across."
        } ?: "Look again at where he stops."
        "spot", "debug" -> "It was step ${q.answerInt + 1}."
        "count", "trace" -> "The answer is ${q.answerInt}."
        "choose" -> "It was ${('A' + q.answerInt)}."
        "chooseText", "complete" -> q.optionsText.getOrNull(q.answerInt) ?: ""
        "compare" -> if (q.answerBool) "They end on the same square."
                     else "They end on different squares."
        "yesno" -> when (q.criterion) {
            "reachesFlag" -> if (q.answerBool) "Yes, he lands on the flag."
                             else "No, he stops somewhere else."
            "allStars" -> if (q.answerBool) "Yes, he takes every one."
                          else "No, he leaves one behind."
            "throughDoor" -> if (q.answerBool) "Yes, the door opens."
                             else "No, the door stays shut."
            "anyStepFails" -> if (q.answerBool) "Yes, one step goes nowhere."
                              else "No, every step works."
            "standingOn:star" -> if (q.answerBool) "Yes, he is on a star."
                                 else "No, the square under him is empty."
            "standingOn:door" -> if (q.answerBool) "Yes, he is at the door."
                                 else "No, the door is somewhere else."
            else -> if (q.answerBool) "Yes, the way is clear."
                    else "No, something is in the way."
        }
        "fix", "constrain" ->
            "Those steps do not get there. Watch where Nupo stops."
        "inverse" -> "Follow the dots one square at a time."
        // Puzzles and Logic and Reasoning. A child who got it wrong is told
        // WHICH answer was right in the words of the question, not just that
        // theirs was not: "The answer is 45" beats a red mark and nothing.
        in PuzzleShapes.all -> when {
            q.answerType == "number" -> "The answer is ${q.answerInt}."
            q.optionsText.isNotEmpty() ->
                q.optionsText.getOrNull(q.answerInt)?.let { "The answer is $it." }.orEmpty()
            // A drawn answer has no words to quote, so it is pointed at
            // instead. Saying only "not quite" would leave a child who cannot
            // see which net folds no wiser than before they answered.
            q.optionCells.isNotEmpty() ->
                q.optionCells.getOrNull(q.answerInt)?.kind
                    ?.let { "The answer is the $it." } ?: ""
            q.optionShapes.isNotEmpty() ->
                q.optionShapes.getOrNull(q.answerInt)
                    ?.let { "The cut makes a $it." } ?: ""
            q.optionBits.isNotEmpty() -> "It is row ${q.answerInt + 1}."
            q.optionViews.isNotEmpty() || q.optionNets.isNotEmpty() ||
                q.optionSections.isNotEmpty() || q.optionCubes.isNotEmpty() ->
                "It is the ${Draw.ordinal(q.answerInt + 1)} one."
            else -> "Look at the picture again."
        }
        else -> ""
    }

    // ---- verdict drawer

    private fun showDrawer(correct: Boolean, message: String) {
        val sheet = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(if (correct) Ink.goodWash else Ink.badWash)
            setPadding(dp(20), dp(16), dp(20), dp(20))
        }
        sheet.addView(label(
            ctx, fonts, if (correct) "Correct" else "Not quite", 20f,
            if (correct) Ink.good else Ink.bad, black = true,
        ))
        if (message.isNotBlank()) {
            sheet.addView(space(4))
            sheet.addView(label(ctx, fonts, message, 15f, Ink.text).apply {
                typeface = fonts.body
                setLineSpacing(dp(3).toFloat(), 1f)
            })
        }
        sheet.addView(space(14))
        val cont = PushButton(ctx, fonts).apply {
            label = if (index >= items.size - 1) "Finish" else "Continue"
            textSize = 17f; radius = 18f; depth = 6
            face = if (correct) Ink.good else Ink.bad
            ledgeColor = if (correct) Ink.goodLedge else Ink.badLedge
            textColor = Color.WHITE
        }
        cont.onTap = { next() }
        sheet.addView(cont, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, dp(56)))

        drawer.removeAllViews()
        drawer.addView(sheet, FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        sheet.translationY = dp(220).toFloat()
        sheet.animate().translationY(0f).setDuration(260)
            .setInterpolator(DecelerateInterpolator(1.6f)).start()
    }

    private fun next() {
        index++
        scroller.scrollTo(0, 0)
        render()
    }

    // ---- finish

    private fun renderFinish() {
        hintButton.visibility = View.GONE
        progress.value = items.size
        drawer.removeAllViews()

        val stop = items.lastOrNull()?.stop
        val done = stop != null &&
            Curriculum.Progress.stopIndex(ctx) > skill.ladder.indexOfFirst { it.id == stop.id }

        body.addView(space(24))
        body.addView(Confetti(ctx), LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, dp(150)))
        body.addView(space(6))
        body.addView(label(
            ctx, fonts, if (done) "Stop complete" else "Nice work", 28f,
            Ink.text, black = true, align = Gravity.CENTER,
        ))
        body.addView(space(8))
        body.addView(label(
            ctx, fonts,
            "$correctCount of $answered right  •  ${skill.name}",
            15f, Ink.muted, align = Gravity.CENTER,
        ).apply { typeface = fonts.body })
        body.addView(space(22))

        val card = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            background = roundRect(Ink.surface, ctx.dpf(20f), Ink.line, dp(2))
            setPadding(dp(20), dp(20), dp(20), dp(20))
        }
        card.addView(label(ctx, fonts, "$minutes", 44f, Ink.primary,
            black = true, align = Gravity.CENTER))
        card.addView(label(ctx, fonts, "minutes unlocked", 15f, Ink.muted,
            align = Gravity.CENTER).apply { typeface = fonts.body })
        body.addView(card, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))

        action.label = "Start playing"
        action.tint(Ink.good, Ink.goodLedge)
        action.enabledLook = true
        action.onTap = { onEarned() }
        play(if (done) sndBoss else sndGood)
    }

    // ---- parent PIN

    /**
     * The overlay window is FLAG_NOT_FOCUSABLE, so it can never raise the soft
     * keyboard — an EditText here would be dead on arrival. The PIN is entered
     * on a keypad drawn in the sheet itself.
     */
    private fun showPinSheet() {
        val sheet = LinearLayout(ctx).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Ink.surface)
            setPadding(dp(20), dp(18), dp(20), dp(20))
        }
        sheet.addView(label(ctx, fonts, "Parent PIN", 20f, Ink.text,
            black = true, align = Gravity.CENTER))
        sheet.addView(space(10))

        val dots = label(ctx, fonts, "", 24f, Ink.primary, align = Gravity.CENTER)
        sheet.addView(dots)
        val err = label(ctx, fonts, "", 13f, Ink.bad, align = Gravity.CENTER).apply {
            typeface = fonts.body
        }
        sheet.addView(space(4))
        sheet.addView(err)
        sheet.addView(space(12))

        var pin = ""
        fun refresh() {
            dots.text = (0 until 4).joinToString("  ") { if (it < pin.length) "●" else "○" }
        }
        refresh()

        val keys = LinearLayout(ctx).apply { orientation = LinearLayout.VERTICAL }
        val rows = listOf(
            listOf("1", "2", "3"), listOf("4", "5", "6"),
            listOf("7", "8", "9"), listOf("", "0", "del"),
        )
        for ((ri, row) in rows.withIndex()) {
            val line = LinearLayout(ctx).apply { orientation = LinearLayout.HORIZONTAL }
            for ((ci, k) in row.withIndex()) {
                if (k.isEmpty()) {
                    line.addView(View(ctx), LinearLayout.LayoutParams(0, dp(50), 1f))
                    continue
                }
                val b = PushButton(ctx, fonts).apply {
                    label = if (k == "del") "⌫" else k
                    textSize = if (k == "del") 17f else 20f
                    radius = 14f
                    face = Ink.surface; ledgeColor = Ink.ledge; textColor = Ink.text
                }
                b.onTap = {
                    if (k == "del") { if (pin.isNotEmpty()) pin = pin.dropLast(1) }
                    else if (pin.length < 4) pin += k
                    refresh()
                    if (pin.length == 4) {
                        if (EnginePrefs.verifyPin(ctx, pin)) onOverride()
                        else { err.text = "Wrong PIN"; pin = ""; refresh() }
                    }
                }
                line.addView(b, LinearLayout.LayoutParams(0, dp(50), 1f).apply {
                    marginStart = if (ci == 0) 0 else dp(8)
                })
            }
            keys.addView(line, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = if (ri == 0) 0 else dp(8) })
        }
        sheet.addView(keys, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        sheet.addView(space(12))

        val back = PushButton(ctx, fonts).apply {
            label = "Back to the lesson"; textSize = 15f; radius = 16f
            face = Ink.surface; ledgeColor = Ink.ledge; textColor = Ink.muted
        }
        back.onTap = { drawer.removeAllViews() }
        sheet.addView(back, LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, dp(50)))

        drawer.removeAllViews()
        drawer.addView(sheet, FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        sheet.translationY = dp(400).toFloat()
        sheet.animate().translationY(0f).setDuration(260)
            .setInterpolator(DecelerateInterpolator(1.6f)).start()
    }

    // ---- bits

    private fun space(h: Int) = View(ctx).apply {
        layoutParams = LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(h))
    }

    private fun dp(v: Int) = (v * ctx.resources.displayMetrics.density).toInt()

    private companion object {
        /** `pickedNumber` before a tap. Not -1: negative answers are real answers. */
        const val NO_NUMBER = Int.MIN_VALUE

        /** The size a board would like to be when there is room. */
        const val MIN_BOARD = 210

        /**
         * The size it shrinks to when there genuinely is not room — a six-row
         * nested loop plus a number pad does not leave 210dp. Better a small
         * board than an answer pad the child has to scroll to find.
         */
        const val HARD_MIN_BOARD = 120
        /** Never larger than this, or a 3x3 grid looks like wall art. */
        const val MAX_BOARD = 380
    }

    /**
     * Session progress as filled segments — a child can see exactly how many
     * questions are left, which a sliding bar never quite tells them.
     */
    private class SegmentBar(ctx: Context) : View(ctx) {
        var total = 1
            set(v) { field = v.coerceAtLeast(1); invalidate() }
        var value = 0
            set(v) { field = v; invalidate() }

        private val p = Paint(Paint.ANTI_ALIAS_FLAG)
        private val r = RectF()

        override fun onDraw(canvas: Canvas) {
            val gap = context.dpf(4f)
            val w = (width - gap * (total - 1)) / total
            val rad = height / 2f
            for (i in 0 until total) {
                p.color = if (i < value) Ink.primary else Ink.line
                r.set(i * (w + gap), 0f, i * (w + gap) + w, height.toFloat())
                canvas.drawRoundRect(r, rad, rad, p)
            }
        }
    }

    /** A short burst of falling confetti for the end of a session. */
    private class Confetti(ctx: Context) : View(ctx) {
        private val colors = intArrayOf(
            Ink.primary, Ink.accent, Ink.good, 0xFF35C9B0.toInt(), 0xFFFF7A7A.toInt())
        private val p = Paint(Paint.ANTI_ALIAS_FLAG)
        private val seeds = List(26) {
            floatArrayOf(
                Math.random().toFloat(),                 // x
                Math.random().toFloat(),                 // phase
                (Math.random() * 360).toFloat(),         // rotation
                (0.7f + Math.random().toFloat() * 0.6f), // speed
            )
        }
        private var t = 0f

        override fun onDraw(canvas: Canvas) {
            val w = width.toFloat(); val h = height.toFloat()
            val size = context.dpf(7f)
            seeds.forEachIndexed { i, s ->
                val y = ((s[1] + t * s[3]) % 1.2f) * h - size
                if (y < -size || y > h) return@forEachIndexed
                p.color = colors[i % colors.size]
                canvas.save()
                canvas.rotate(s[2] + t * 220f, s[0] * w, y)
                canvas.drawRoundRect(
                    s[0] * w - size / 2, y - size / 2,
                    s[0] * w + size / 2, y + size / 2,
                    size / 4, size / 4, p
                )
                canvas.restore()
            }
            t += 0.012f
            if (t < 1.6f) postInvalidateOnAnimation()
        }
    }
}

/** What [GuardService] needs from whichever gate is on screen. */
/**
 * The question shapes of Puzzles and Logic (7-8) and Reasoning (11-12).
 *
 * These two skills have fifty-five shapes between them, but only four ways to
 * answer: pick a number, pick a sentence, pick a drawn shape, or pick one of
 * several drawn pictures. So the gate serves them from ONE branch that asks
 * the question which of the four it is, rather than fifty-five branches that
 * would each repeat the same wiring and each be a place to get it wrong.
 *
 * A shape is listed here only once its drawing exists. A shape that is not
 * listed falls through to the gate's `else`, which draws nothing and offers
 * nothing — so forgetting to add one is a blank screen, never a wrong answer
 * marked right.
 */
object PuzzleShapes {

    /** Ages 7-8: number thinking, order and position, relations, logic. */
    val bandB = setOf(
        // the answer is one of four numbers
        "equation", "riddle", "story", "bars", "series", "queueBack",
        "queueCalc", "rankCount", "numberAnalogy", "combos",
        // the answer is one of several sentences
        "seriesRule", "rank", "queueWho", "turns", "relation", "relationWho",
        "wordAnalogy", "wordCode", "numCode", "alphabet", "oddWord",
        "oddNumber", "weekday", "month", "clock",
        // the answer is one of four drawn shapes
        "shelf",
    )

    /** Ages 11-12: sequences, argument, codes, and solids in space. */
    val bandD = setOf(
        // the answer is one of four numbers
        "sequence", "nthTerm", "termPosition", "binaryRead", "roll",
        "sectionSides", "stackCount",
        // the answer is one of several sentences
        "seqRule", "claim", "ifThen", "deduce", "knights", "cipher",
        "cipherWrite", "crackCode", "symbolCode", "letterCode", "mirrorCode",
        "mirrorWrite",
        // the answer is one of four drawn shapes
        "netFace", "cubeTurn",
        // the answer is one of four drawings of its own kind
        "netPick", "sectionShape", "sectionWhich", "sameShape", "stackView",
        "binaryPick",
    )

    val all: Set<String> = bandB + bandD
}

interface GateUi {
    val root: FrameLayout
    fun release()
}
