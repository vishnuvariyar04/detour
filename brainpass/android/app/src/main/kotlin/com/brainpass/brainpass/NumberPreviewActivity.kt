package com.brainpass.brainpass

import android.app.Activity
import android.content.pm.ApplicationInfo
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.Button
import android.widget.TextView

/**
 * A gallery of the Number Sense drawings, for looking at on a real phone.
 *
 * These are the pictures a five year old will be answering questions about, and
 * how they read at arm's length on a real screen is not something a description
 * settles. Being able to see them before 324 questions are authored on top of
 * them is the point: a picture that does not teach is far cheaper to change now
 * than later.
 *
 * Debug builds only. Launch with:
 *   adb shell am start -n app.nupo.kid/com.brainpass.brainpass.NumberPreviewActivity
 */
class NumberPreviewActivity : Activity() {

    override fun onCreate(saved: Bundle?) {
        super.onCreate(saved)
        if ((applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) == 0) {
            finish()
            return
        }
        val fonts = Fonts(this)
        val pad = (16 * resources.displayMetrics.density).toInt()

        // Every animated view registers here so one button can replay them all.
        val players = mutableListOf<() -> Unit>()

        val col = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Ink.bg)
            setPadding(pad, pad, pad, pad)
        }

        fun caption(s: String) = TextView(this).apply {
            text = s
            textSize = 12.5f
            typeface = fonts.extra
            setTextColor(Ink.muted)
            letterSpacing = 0.08f
            setPadding(0, pad, 0, pad / 2)
        }

        fun card(v: View, label: String) {
            col.addView(caption(label))
            col.addView(LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER_HORIZONTAL
                background = roundRect(Ink.surface, 18f * resources.displayMetrics.density,
                    Ink.line, (1.5f * resources.displayMetrics.density).toInt())
                setPadding(pad, pad, pad, pad)
                addView(v, LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT))
            }, LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT))
        }

        col.addView(Button(this).apply {
            text = "Replay all"
            setOnClickListener { players.forEach { it() } }
        })
        // Also replays on a loop, so any card can be watched without scrolling
        // back to the button.
        val h = android.os.Handler(mainLooper)
        val tick = object : Runnable {
            override fun run() {
                players.forEach { it() }
                h.postDelayed(this, 2600)
            }
        }
        h.postDelayed(tick, 900)

        card(CountGroupView(this).apply { count = 7; players += { play() } },
            "HOW MANY  -  seven stars land one by one")
        card(CountGroupView(this).apply { count = 6; splitAt = 4; glyph = Glyphs.HEART
            players += { play() } },
            "PARTS  -  four and two")
        card(CountGroupView(this).apply { count = 8; glyph = Glyphs.FLOWER
            players += { play() } },
            "HOW MANY  -  the counters can be anything")
        card(TenFrameView(this).apply { filled = 7; players += { play() } },
            "TEN FRAME  -  fills one cell at a time")
        card(TenFrameView(this).apply { filled = 10; secondFilled = 3
            players += { play() } },
            "TEEN  -  ten and three")
        card(NumberLineView(this, fonts).apply {
            from = 0; to = 10; hopFrom = 3; marker = 7; players += { play() }
        }, "NUMBER LINE  -  three, then four hops on")
        card(NumberLineView(this, fonts).apply {
            from = 0; to = 20; labelEvery = 5; selectable = true
        }, "NUMBER LINE  -  tappable, labelled every five")
        card(NumberBondView(this, fonts).apply { whole = 6; left = 4; gap = "right"
            players += { play() } },
            "NUMBER BOND  -  six is four and what?")
        card(NumberBondView(this, fonts).apply {
            left = 5; right = 3; gap = "whole"
        }, "NUMBER BOND  -  five and three make what?")

        // Shape hunts are not here: their geometry now travels with each
        // question, so a hand-built gallery card cannot make one. The question
        // wall shows every figure as the child will meet it.
        // The playful half: looking, not counting.
        card(PatternStripView(this, fonts).apply {
            cells = listOf(
                Cell(Glyphs.STAR, Ink.primary), Cell(Glyphs.HEART, Ink.accent),
                Cell(Glyphs.STAR, Ink.primary), Cell(Glyphs.HEART, Ink.accent),
                Cell(Glyphs.STAR, Ink.primary))
            gapAt = 4
        }, "PATTERN  -  what comes next?")
        card(PatternStripView(this, fonts).apply {
            cells = listOf(
                Cell(Glyphs.TRIANGLE, Ink.primary, 0f),
                Cell(Glyphs.TRIANGLE, Ink.primary, 90f),
                Cell(Glyphs.TRIANGLE, Ink.primary, 180f),
                Cell(Glyphs.TRIANGLE, Ink.primary, 270f))
            gapAt = 3
        }, "PATTERN  -  the rule can be a turn, not a shape")
        card(OddOneOutView(this).apply {
            cells = listOf(
                Cell(Glyphs.SQUARE, Ink.primary), Cell(Glyphs.SQUARE, Ink.primary),
                Cell(Glyphs.TRIANGLE, Ink.primary), Cell(Glyphs.SQUARE, Ink.primary))
        }, "ODD ONE OUT  -  by shape")
        card(OddOneOutView(this).apply {
            cells = listOf(
                Cell(Glyphs.STAR, Ink.primary), Cell(Glyphs.STAR, Ink.accent),
                Cell(Glyphs.STAR, Ink.primary), Cell(Glyphs.STAR, Ink.primary))
        }, "ODD ONE OUT  -  by colour")

        // More pictures, so forty questions do not all look the same.
        card(BalanceScaleView(this).apply {
            leftCount = 6; rightCount = 3; players += { play() }
        }, "BALANCE  -  which side is heavier?")
        card(BalanceScaleView(this).apply {
            leftCount = 4; rightCount = 4; glyph = Glyphs.HEART; players += { play() }
        }, "BALANCE  -  the same, so it stays level")
        card(RodsView(this).apply { value = 23; players += { play() } },
            "TENS AND ONES  -  twenty-three")
        card(DiceView(this).apply { faces = listOf(5); players += { play() } },
            "DICE  -  know five without counting")
        card(DiceView(this).apply { faces = listOf(4, 3); players += { play() } },
            "DOMINO  -  four and three")
        card(MirrorView(this).apply {
            given = setOf(0 to 1, 1 to 1, 1 to 2, 2 to 0, 2 to 3)
            players += { play() }
        }, "MIRROR  -  tap to finish the other half")

        card(SortTrayView(this, fonts).apply {
            leftLabel = "ROUND"; rightLabel = "NOT ROUND"
            items = listOf(
                Cell(Glyphs.CIRCLE, Ink.primary), Cell(Glyphs.SQUARE, Ink.primary),
                Cell(Glyphs.CIRCLE, Ink.accent), Cell(Glyphs.TRIANGLE, Ink.accent),
                Cell(Glyphs.HEXAGON, Ink.primary))
            players += { play() }
        }, "SORT  -  tap a shape to send it to the other tray")
        card(SizeOrderView(this).apply {
            sizes = listOf(0.55f, 1f, 0.3f, 0.78f)
            players += { play() }
        }, "ORDER BY SIZE  -  tap smallest first")
        card(FractionView(this).apply { slices = 4; shaded = 1; players += { play() } },
            "FRACTION  -  one quarter")
        card(FractionView(this).apply {
            slices = 2; shaded = 1; otherSlices = 4; otherShaded = 3
            selectable = true; players += { play() }
        }, "FRACTION  -  which is more, a half or three quarters?")

        setContentView(ScrollView(this).apply {
            setBackgroundColor(Ink.bg)
            addView(col, ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT))
        })
    }
}
