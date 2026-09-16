package com.brainpass.brainpass

import android.app.Activity
import android.content.pm.ApplicationInfo
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import org.json.JSONObject

/**
 * Every drawing of the two new skills, one question of each kind, on a phone.
 *
 * The review wall shows these as canvas drawings in a browser at a made-up card
 * width. What actually matters is whether a seven year old can read them on a
 * real screen at arm's length: whether the clue card wraps, whether the queue
 * names collide at seven children, whether the clock hands are tellable apart.
 * None of that is settled by the wall and none of it is settled by the checker.
 *
 * It reads the skills straight out of assets/curriculum_pending, which is
 * bundled but never served, so this screen can show a skill that no child can
 * yet reach.
 *
 * Debug builds only. Launch with:
 *   adb shell am start -n app.nupo.kid/com.brainpass.brainpass.PuzzlePreviewActivity
 * One skill at a time:
 *   adb shell am start -n app.nupo.kid/com.brainpass.brainpass.PuzzlePreviewActivity \
 *     --es skill puzzles_and_logic
 */
class PuzzlePreviewActivity : Activity() {

    override fun onCreate(saved: Bundle?) {
        super.onCreate(saved)
        if ((applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) == 0) {
            finish()
            return
        }
        val fonts = Fonts(this)
        val den = resources.displayMetrics.density
        val pad = (16 * den).toInt()

        val col = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Ink.bg)
            setPadding(pad, pad, pad, pad)
        }

        fun caption(s: String, colour: Int = Ink.muted) = TextView(this).apply {
            text = s
            textSize = 12.5f
            typeface = fonts.extra
            setTextColor(colour)
            letterSpacing = 0.06f
            setPadding(0, pad, 0, pad / 2)
        }

        // The real gate, not a gallery of its parts.
        //
        // A drawing that renders is not the same as a question that WORKS: the
        // tap has to register, the answer has to be graded, the verdict has to
        // name the right answer and Continue has to move on. All of that lives
        // in CoderGate, so testing it means running CoderGate, not a copy of
        // its layout code that could agree with itself while both are wrong.
        if (intent?.getStringExtra("mode") == "gate") {
            showGate(intent.getStringExtra("skill") ?: "puzzles_and_logic",
                intent.getStringExtra("shape"))
            return
        }

        val want = intent?.getStringExtra("skill")
        val files = assets.list(DIR).orEmpty()
            .filter { it.endsWith(".json") }
            .filter { want == null || it.startsWith(want) }
            .sorted()

        if (files.isEmpty()) {
            col.addView(caption("Nothing in $DIR", Ink.bad))
        }

        for (file in files) {
            val text = assets.open("$DIR/$file").bufferedReader().use { it.readText() }
            val skill = Curriculum.Skill(JSONObject(text))
            col.addView(caption("${skill.name.uppercase()}  ·  band ${skill.band}", Ink.primary))

            // One question of every shape, in the order the child would meet
            // them: the first of a kind is the one its teach card just led up
            // to, so it is the one worth looking at hardest.
            val seen = mutableSetOf<String>()
            val onlyShape = intent?.getStringExtra("shape")
            // Every kind once, in the order a child meets them: the first of a
            // kind is the one its teach card has just led up to.
            //
            // Paged, because band d draws eighteen solids and a whole page of
            // them is more than a software-rendered emulator will do inside
            // one frame — the page came up, then the system offered to close
            // it. `--ei skip N --ei limit M` walks through instead.
            val skip = intent?.getIntExtra("skip", 0) ?: 0
            val limit = intent?.getIntExtra("limit", 6) ?: 6
            val firsts = skill.sections
                .flatMap { it.units }.flatMap { it.stops }.flatMap { it.questions }
                .filter { onlyShape == null || it.shape == onlyShape }
                .filter { seen.add(it.shape + "/" + (it.pic?.kind ?: "-")) }
                .drop(skip).take(limit)

            col.addView(caption("showing ${skip + 1}-${skip + firsts.size}" +
                "   ·   next:  --ei skip ${skip + firsts.size}", Ink.primary))

            for (q in firsts) {
                col.addView(caption("${q.shape}   ·   ${q.pic?.kind ?: "no picture"}"))
                col.addView(LinearLayout(this).apply {
                    orientation = LinearLayout.VERTICAL
                    background = roundRect(Ink.bg, 18f * den, Ink.line, (1.5f * den).toInt())
                    setPadding(pad, pad, pad, pad)

                    addView(label(this@PuzzlePreviewActivity, fonts, q.prompt, 19f, Ink.text,
                        black = true).apply { setLineSpacing(3f * den, 1f) })
                    addView(gap((12 * den).toInt()))

                    // Both bands, chosen the way the gate chooses.
                    val pic = q.pic
                    val drawing: View? = when {
                        PuzzlePicView.draws(pic) ->
                            PuzzlePicView(this@PuzzlePreviewActivity, fonts)
                                .apply { this.pic = pic }
                        ReasonPicView.draws(pic) ->
                            ReasonPicView(this@PuzzlePreviewActivity, fonts)
                                .apply { this.pic = pic }
                        else -> null
                    }
                    if (drawing != null) {
                        addView(drawing, LinearLayout.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.WRAP_CONTENT))
                        addView(gap((14 * den).toInt()))
                    }

                    // The answer row, drawn the way the gate draws it, so a
                    // long option that would overflow the button shows up here
                    // and not for the first time on a child's screen.
                    when {
                        q.answerType == "number" -> addView(numberRow(fonts, q, den))
                        q.optionCells.isNotEmpty() -> addView(cellRow(fonts, q, den))
                        q.optionsText.isNotEmpty() -> addView(textRow(fonts, q, den))
                        // Band d answers that are drawings. The gallery says
                        // which kind rather than redrawing them: how they look
                        // is checked in the gate itself, where they are the
                        // real buttons and not a second copy that could differ.
                        else -> addView(label(this@PuzzlePreviewActivity, fonts,
                            "answers are drawings — check these in `--es mode gate`",
                            13f, Ink.muted))
                    }

                    addView(gap((10 * den).toInt()))
                    addView(label(this@PuzzlePreviewActivity, fonts,
                        "answer: " + answerText(q), 13f, Ink.good).apply {
                        typeface = fonts.extra
                    })
                }, LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT))
            }
        }

        setContentView(ScrollView(this).apply {
            setBackgroundColor(Ink.bg)
            addView(col, ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT))
        })
    }

    /**
     * Hosts the real [CoderGate] over a session built from a pending skill.
     *
     * The gate normally runs in the guard's overlay window, which needs the
     * accessibility service, the overlay permission and a gated app to open.
     * None of that changes a single line of what the gate draws or how it
     * grades, so for checking the questions it is plumbing in the way. The
     * gate only needs a Context and a list of items.
     *
     * Pass a shape to see only that kind:
     *   --es mode gate --es shape relation
     */
    private fun showGate(skillFile: String, shape: String?) {
        // Pending first, then the shipped skills: the gate code these two
        // share was changed to serve the new bands, so being able to run band
        // a and band c through the same harness is how that change is shown
        // not to have broken them.
        val dir = if (assets.list(DIR).orEmpty().contains("$skillFile.json")) DIR else SHIPPED
        val text = assets.open("$dir/$skillFile.json").bufferedReader().use { it.readText() }
        val skill = Curriculum.Skill(JSONObject(text))
        val items = mutableListOf<Curriculum.Item>()
        for (section in skill.sections) {
            for (unit in section.units) {
                for (stop in unit.stops) {
                    for (q in stop.questions) {
                        if (shape == null || q.shape == shape) {
                            items.add(Curriculum.Item(stop, q))
                        }
                    }
                }
            }
        }
        if (items.isEmpty()) {
            setContentView(TextView(this).apply {
                setText("no questions for shape=$shape in $skillFile")
            })
            return
        }
        val gate = CoderGate(this, 10, items, skill, {}, {})
        setContentView(gate.root)
    }

    /** What the gate will mark as right, spelled out so the page can be checked. */
    private fun answerText(q: Curriculum.Question): String =
        if (q.answerType == "number") "${q.answerInt}"
        else q.optionsText.getOrNull(q.answerInt)
            ?: q.optionCells.getOrNull(q.answerInt)?.kind
            ?: "option ${q.answerInt + 1}"

    private fun gap(h: Int) = View(this).apply {
        layoutParams = LinearLayout.LayoutParams(1, h)
    }

    private fun numberRow(fonts: Fonts, q: Curriculum.Question, den: Float) =
        LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            q.choices.forEachIndexed { i, n ->
                addView(PushButton(this@PuzzlePreviewActivity, fonts).apply {
                    label = "$n"; textSize = 22f; radius = 16f
                    face = Ink.surface; ledgeColor = Ink.ledge; textColor = Ink.text
                }, LinearLayout.LayoutParams(0, (62 * den).toInt(), 1f).apply {
                    marginStart = if (i == 0) 0 else (10 * den).toInt()
                })
            }
        }

    private fun textRow(fonts: Fonts, q: Curriculum.Question, den: Float) =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            q.optionsText.forEachIndexed { i, t ->
                addView(PushButton(this@PuzzlePreviewActivity, fonts).apply {
                    label = t; textSize = 16f; radius = 16f
                    face = Ink.surface; ledgeColor = Ink.ledge; textColor = Ink.text
                }, LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT, (56 * den).toInt()).apply {
                    topMargin = if (i == 0) 0 else (10 * den).toInt()
                })
            }
        }

    private fun cellRow(fonts: Fonts, q: Curriculum.Question, den: Float) =
        LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            q.optionCells.forEachIndexed { i, c ->
                addView(PushButton(this@PuzzlePreviewActivity, fonts).apply {
                    radius = 16f
                    face = Ink.surface; ledgeColor = Ink.ledge
                    painter = { canvas, box ->
                        val p = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)
                        Glyphs.draw(canvas, c.kind, box.centerX(), box.centerY(),
                            minOf(box.width(), box.height()) * 0.28f,
                            Ink.primary, Ink.primaryLedge, p, c.rotation)
                    }
                }, LinearLayout.LayoutParams(0, (76 * den).toInt(), 1f).apply {
                    marginStart = if (i == 0) 0 else (10 * den).toInt()
                })
            }
        }

    private companion object {
        const val DIR = "flutter_assets/assets/curriculum_pending"
        const val SHIPPED = "flutter_assets/assets/curriculum"
    }
}
