package com.brainpass.brainpass

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar

/**
 * The skill curriculum: content, the ladder the child climbs, and the progress
 * that both the gate and the Flutter roadmap read.
 *
 * Content lives in a JSON asset under assets/curriculum (reachable natively as
 * flutter_assets/assets/curriculum/...), so a new skill is a new file, not new code.
 *
 * SHAPE
 *   Skill -> Section -> Unit -> Stop -> Question
 *   One stop is one idea. A gate serves a slice of the stop's questions; the
 *   stop completes when its last question is answered, whichever gate that
 *   happens to be. The cursor is per CHILD, not per app, so a ladder climbed
 *   through Roblox continues through YouTube.
 *
 * GRADING
 *   [Sim] is the reference simulator. brainpass/tools coder/validate.py runs the
 *   same rules over the JSON at author time; the two must stay in step:
 *   a blocked move is skipped and the program keeps running.
 */
object Curriculum {

    // ---------------------------------------------------------------- model

    /** A GridBot board. [x] is the column, [y] counts UP from the bottom row. */
    class Board(o: JSONObject) {
        val w = o.optInt("w", 5)
        val h = o.optInt("h", 5)
        val start = o.cell("start") ?: (0 to 0)
        val goal = o.cell("goal")
        val key = o.cell("key")
        val door = o.cell("door")
        val walls = o.cells("walls")
        val stars = o.cells("stars")
        val program = o.strings("program")

        /**
         * When true a star must be picked up deliberately; walking over it is
         * not enough. Conditions questions need this, or "IF ON A STAR THEN
         * PICK UP" is a step that never changes anything.
         */
        val mustPick = o.optBoolean("mustPick", false)

        /** Named boxes and the numbers they start with. */
        val vars: Map<String, Int> = o.optJSONObject("vars")?.let { j ->
            j.keys().asSequence().associateWith { k -> j.optInt(k, 0) }
        } ?: emptyMap()

        /**
         * True when the grid actually holds something to reach or avoid. A
         * board with none of these is scenery — for a variables question the
         * boxes are the subject and the empty grid is a distraction.
         */
        val hasWorld: Boolean
            get() = goal != null || stars.isNotEmpty() || walls.isNotEmpty() ||
                key != null || door != null
    }

    class Question(o: JSONObject, val stopId: String, val index: Int) {
        val shape = o.optString("shape")
        val prompt = o.optString("prompt")
        val hint = o.optString("hint")
        val board = o.optJSONObject("visual")?.let { Board(it) }
        val options = o.optJSONArray("options")?.let { arr ->
            (0 until arr.length()).map { arr.getJSONArray(it).toStrings() }
        }
        val optionsText = o.strings("optionsText")

        /** Drawn choices, for a pattern question whose options are shapes. */
        val optionCells: List<CellSpec> = o.optJSONArray("optionCells")?.let { a ->
            (0 until a.length()).map { CellSpec(a.getJSONObject(it)) }
        } ?: emptyList()

        /** The condition a `truth` question asks about, shown verbatim. */
        val expr: String = o.optString("expr")

        /** What a count question is counting: steps, moves, rows, stars... */
        val kind: String = o.optString("kind", "steps")

        /**
         * What the question MEANS, where the shape alone does not say.
         *
         * A yes/no question uses it to word the answer a child is shown:
         * "reachesFlag", "allStars", "throughDoor", "anyStepFails",
         * "canMove:<dir>" and "standingOn:<thing>". A spot question uses it to
         * say what makes one row the right one, which is what the authoring
         * checks use to refuse a question where several rows fit.
         */
        val criterion: String = o.optString("criterion")

        /** Which named box a variable or trace question is about. */
        val varName: String = o.optString("varName", "COINS")
        /** The box's value after each row, for a trace table. */
        val traceOf: List<Int> = o.optJSONArray("traceOf")?.let { a ->
            (0 until a.length()).map { a.optInt(it) }
        } ?: emptyList()
        /** Which trace row is left blank. */
        val gapRow: Int = o.optInt("gapRow", -1)

        /** The four numbers offered for a number answer. */
        val choices: List<Int> = o.optJSONArray("choices")?.let { a ->
            (0 until a.length()).map { a.optInt(it) }
        } ?: emptyList()
        // Band d answers that are DRAWINGS rather than words: four nets, four
        // cuts, four solids, four side views, four rows of bulbs. Each is its
        // own array because each draws differently; a single "options" holding
        // any of them would need the reader to guess which.
        val optionNets: List<List<Pair<Int, Int>>> = o.optJSONArray("optionNets")?.let { a ->
            (0 until a.length()).mapNotNull { i ->
                (a.opt(i) as? JSONArray)?.let { net ->
                    (0 until net.length()).mapNotNull { k ->
                        (net.opt(k) as? JSONArray)?.let { it.optInt(0) to it.optInt(1) }
                    }
                }
            }
        } ?: emptyList()
        val optionSections: List<Pic> = o.optJSONArray("optionSections")?.let { a ->
            (0 until a.length()).mapNotNull { (a.opt(it) as? JSONObject)?.let(::Pic) }
        } ?: emptyList()
        val optionCubes: List<List<Triple<Int, Int, Int>>> =
            o.optJSONArray("optionCubes")?.let { a ->
                (0 until a.length()).mapNotNull { i ->
                    (a.opt(i) as? JSONArray)?.let { set ->
                        (0 until set.length()).mapNotNull { k ->
                            (set.opt(k) as? JSONArray)?.let {
                                Triple(it.optInt(0), it.optInt(1), it.optInt(2))
                            }
                        }
                    }
                }
            } ?: emptyList()
        val optionViews: List<List<Int>> = o.optJSONArray("optionViews")?.let { a ->
            (0 until a.length()).mapNotNull { i ->
                (a.opt(i) as? JSONArray)?.let { v -> (0 until v.length()).map { v.optInt(it) } }
            }
        } ?: emptyList()
        val optionBits: List<List<Boolean>> = o.optJSONArray("optionBits")?.let { a ->
            (0 until a.length()).mapNotNull { i ->
                (a.opt(i) as? JSONArray)?.let { r ->
                    (0 until r.length()).map { r.optInt(it) != 0 }
                }
            }
        } ?: emptyList()
        val optionShapes: List<String> = o.strings("optionShapes")

        val blocks = o.strings("blocks")
        val slots = o.optInt("slots", 0)

        /**
         * True when [blocks] is a palette rather than a hand: each step can be
         * used as many times as the child likes. Used by "reach the flag in
         * exactly N steps", where the puzzle is the route, not the pieces.
         */
        val reusable = o.optBoolean("reusable", false)

        /** The drawing for a Number Sense question; null for the coder skill. */
        val pic: Pic? = o.optJSONObject("pic")?.let { Pic(it) }

        private val answer = o.optJSONObject("answer") ?: JSONObject()
        val answerType: String = answer.optString("type")
        val answerCell: Pair<Int, Int>? = answer.cell("value")
        val answerInt: Int = answer.optInt("value", -1)
        val answerBool: Boolean = answer.optBoolean("value", false)
        val answerOrder: List<String> = answer.strings("value")

        /** The answer as a list of cells, for a mirror. */
        val answerCells: Set<Pair<Int, Int>> = answer.optJSONArray("value")?.let { a ->
            (0 until a.length()).mapNotNull {
                (a.opt(it) as? JSONArray)?.let { e -> e.getInt(0) to e.getInt(1) }
            }.toSet()
        } ?: emptySet()

        /** The answer as a list of whole numbers, for orders and sets. */
        val answerInts: List<Int> = answer.optJSONArray("value")?.let { a ->
            (0 until a.length()).map { a.optInt(it, -1) }
        } ?: emptyList()

        /** Stable id so a missed question can be queued for review. */
        val id: String get() = "$stopId#$index"

        /**
         * A [fix] question is graded by running the child's program: any order
         * that clears the board counts, because several usually do. Everything
         * else compares against the stored answer.
         */
        fun isCorrectOrder(program: List<String>): Boolean {
            val b = board ?: return program == answerOrder
            return if (shape == "fix" || shape == "constrain") Sim.clears(b, program)
            else program == answerOrder
        }
    }

    /**
     * What to draw for a Number Sense question.
     *
     * The coder skill has one picture — a board — so its shape could carry the
     * drawing implicitly. This skill has sixteen, so the question says which one
     * it wants and supplies only the fields that picture reads.
     */
    class Pic(o: JSONObject) {
        val kind: String = o.optString("kind")
        val glyph: String = o.optString("glyph", "star")

        /** count / rods / dice */
        val n: Int = o.optInt("n", 0)
        val splitAt: Int = o.optInt("splitAt", -1)
        val faces: List<Int> = o.optJSONArray("faces")?.let { a ->
            (0 until a.length()).map { a.optInt(it) }
        } ?: emptyList()

        /** tenFrame */
        val filled: Int = o.optInt("filled", 0)
        val second: Int = o.optInt("second", -1)

        /** numberLine */
        val from: Int = o.optInt("from", 0)
        val to: Int = o.optInt("to", 10)
        val labelEvery: Int = o.optInt("labelEvery", 1)
        val marker: Int? = if (o.has("marker")) o.optInt("marker") else null
        val hopFrom: Int? = if (o.has("hopFrom")) o.optInt("hopFrom") else null

        /** bond */
        val whole: Int? = if (o.has("whole")) o.optInt("whole") else null
        val left: Int? = if (o.has("left")) o.optInt("left") else null
        val right: Int? = if (o.has("right")) o.optInt("right") else null
        val gap: String = o.optString("gap", "right")

        /** balance */
        val leftCount: Int = o.optInt("leftCount", 0)
        val rightCount: Int = o.optInt("rightCount", 0)

        /** shapeHunt / shapeCount */
        val figure: String = o.optString("figure", "triangle4")
        /** Which kind of piece the child is asked to find. */
        val target: String = o.optString("target", "triangle")

        /**
         * The figure's polygons, carried by the question itself.
         *
         * The geometry used to be written out in Kotlin, again in the checker
         * and again in the review page, and the three drifted — four pieces
         * called squares measured as rectangles. There is now one source and
         * it travels with the data.
         */
        val parts: List<Pair<String, List<Pair<Float, Float>>>> =
            o.optJSONArray("parts")?.let { a ->
                (0 until a.length()).map { i ->
                    val part = a.getJSONObject(i)
                    val pa = part.optJSONArray("pts") ?: JSONArray()
                    part.optString("kind") to (0 until pa.length()).map { k ->
                        val pt = pa.getJSONArray(k)
                        pt.getDouble(0).toFloat() to pt.getDouble(1).toFloat()
                    }
                }
            } ?: emptyList()

        /**
         * Grid size. Shared by the array (rows x columns of counters) and the
         * mirror (the fold grid) — both read the same two JSON keys, so one
         * pair of fields serves both rather than two that could disagree.
         */
        val cols: Int = o.optInt("cols", 0)
        val rows: Int = o.optInt("rows", 0)

        /** groups */
        val groupCount: Int = o.optInt("groups", 0)
        val per: Int = o.optInt("per", 0)
        val share: Boolean = o.optBoolean("share", false)

        /** barModel */
        val a: Int = o.optInt("a", 0)
        val b: Int = o.optInt("b", 0)
        val ask: String = o.optString("ask", "more")

        /** numberLine, when the hops are bigger than one */
        val step: Int = o.optInt("step", 1)
        val hops: Int = o.optInt("hops", 0)

        /** fractionWall: each strip as (pieces, coloured) */
        val strips: List<Pair<Int, Int>> = o.optJSONArray("rows")?.let { a ->
            (0 until a.length()).mapNotNull {
                (a.opt(it) as? JSONArray)?.let { r -> r.getInt(0) to r.getInt(1) }
            }
        } ?: emptyList()

        /**
         * pattern / oddOneOut / sort — the cells, and where the gap is.
         *
         * Only the entries that ARE drawn things are taken. A cube net also
         * calls its squares "cells", but writes them as [column, row] pairs;
         * reading those as CellSpec threw, and the throw happened inside
         * Skill(), which allSkills() catches per file — so one band d question
         * would have silently cost a child the whole skill.
         */
        val cells: List<CellSpec> = o.optJSONArray("cells")?.let { a ->
            (0 until a.length()).mapNotNull { (a.opt(it) as? JSONObject)?.let(::CellSpec) }
        } ?: emptyList()
        val gapAt: Int = o.optInt("gapAt", -1)
        val leftLabel: String = o.optString("leftLabel", "YES")
        val rightLabel: String = o.optString("rightLabel", "NO")

        /** sizeOrder */
        val sizes: List<Float> = o.optJSONArray("sizes")?.let { a ->
            (0 until a.length()).map { a.optDouble(it, 1.0).toFloat() }
        } ?: emptyList()

        /** fraction */
        val slices: Int = o.optInt("slices", 4)
        val shaded: Int = o.optInt("shaded", 1)
        val otherSlices: Int = o.optInt("otherSlices", 0)
        val otherShaded: Int = o.optInt("otherShaded", 0)

        /** mirror */
        val given: List<Pair<Int, Int>> = o.optJSONArray("given")?.let { a ->
            (0 until a.length()).map {
                val e = a.getJSONArray(it)
                e.getInt(0) to e.getInt(1)
            }
        } ?: emptyList()

        // ---------------------------------------------------------- bands b and d
        //
        // Puzzles and Logic (7-8) and Reasoning (11-12) ask about order,
        // relation and rule rather than quantity, so their drawings need
        // words, sequences and solids that no counting picture had a field
        // for. Everything below is additive: the two shipped skills read
        // none of it, and a picture reads only the handful its kind needs.

        /** The sentences a card, a compass or a clock keeps on screen. */
        val lines: List<String> = o.strings("lines")

        /** A run of numbers, null where the gap is. */
        val terms: List<Int?> = o.optJSONArray("terms")?.let { a ->
            (0 until a.length()).map { if (a.isNull(it)) null else a.optInt(it) }
        } ?: emptyList()

        /** equation: the two sides, the sign, and which part is hidden. */
        val op: String = o.optString("op", "+")
        val hide: String = o.optString("hide")
        val result: Int = o.optInt("result", 0)

        /** bars: the two children, their amounts, and what each label shows. */
        val names: List<String> = o.strings("names")
        val values: List<Int> = o.optJSONArray("values")?.let { a ->
            (0 until a.length()).map { a.optInt(it) }
        } ?: emptyList()
        private val shown: JSONObject? = o.optJSONObject("shown")
        val shownTop: Int? = shown?.takeIf { !it.isNull("top") }?.optInt("top")
        val shownLow: Int? = shown?.takeIf { !it.isNull("low") }?.optInt("low")
        val shownDiff: Int? = shown?.takeIf { !it.isNull("diff") }?.optInt("diff")

        /** line: how many in the queue, which one is marked, and their names. */
        val mark: Int = o.optInt("mark", 0)
        val name: String = o.optString("name")

        /** shelf: the row of shapes and which way the question points. */
        val items: List<String> = o.strings("items")
        val side: String = o.optString("side")
        val stepCount: Int = o.optInt("steps", 0)

        /** compass: which way the child faces, and the turns they make. */
        val start: String = o.optString("start")
        val moves: List<String> = o.strings("moves")

        /** letter and month: the one given, and how far from it to go. */
        val base: String = o.optString("base")
        val offset: Int = o.optInt("offset", 0)

        /** code: one worked example, the word to put through it, which way. */
        val example: List<String> = o.strings("example")
        val word: String = o.optString("word")
        val mode: String = o.optString("mode")

        /** The four things an odd-one-out is choosing between. */
        val words: List<String> = o.strings("words")

        /** clock: the time the hands show. */
        val h: Int = o.optInt("h", 12)
        val m: Int = o.optInt("m", 0)

        /**
         * Pairs, as an analogy shows them: `cow -> calf`, then `dog -> ?`.
         * The missing half is null, which is what makes it the question.
         */
        val wordPairs: List<Pair<String?, String?>> = o.pairsOf { a, i ->
            (if (a.isNull(i)) null else a.optString(i))
        }
        val numPairs: List<Pair<Int?, Int?>> = o.pairsOf { a, i ->
            (if (a.isNull(i)) null else a.optInt(i))
        }

        // ------------------------------------------------------------- band d
        //
        // Reasoning (11-12) turns solids over, cuts them and codes words.
        //
        // Seven of its JSON keys are also band b keys holding something else:
        // "start" is a compass direction there and a grid square here, "steps"
        // a count there and sentences here, "target" a shape there and a number
        // here, "word" a string there and a row of symbols here, "who" and
        // "what" can be null here, and "cells" is CellSpecs in band a but
        // [column, row] pairs here. Each of those gets its OWN field below
        // rather than a shared one that would have to guess: a reader that
        // guesses wrong on a skill it was not written for is how one bad
        // question costs a child every question.

        /** sequence: which position is being asked about, or which value. */
        val askPosition: Int = o.optInt("askPosition", 0)
        val askValue: Int = if (o.has("askValue")) o.optInt("askValue") else Int.MIN_VALUE

        /** claim: the statement being judged, and how it is worded. */
        val claimText: String = o.optJSONObject("claim")?.optString("text").orEmpty()

        /** deduce: the people, the things they could have, and the noun. */
        val people: List<String> = o.strings("people")
        val things: List<String> = o.strings("things")
        val noun: String = o.optString("noun")

        /** ifThen and knights: the rules, and who says what. */
        val rules: List<List<String>> = o.rows("rules")
        val says: List<List<String>> = o.rows("says")

        /** binary: the place values, which bulbs are lit, and what is asked. */
        val bulbValues: List<Int> = o.optJSONArray("values")?.let { a ->
            (0 until a.length()).map { a.optInt(it) }
        } ?: emptyList()
        val on: List<Boolean> = o.optJSONArray("on")?.let { a ->
            (0 until a.length()).map { a.optInt(it) != 0 }
        } ?: emptyList()
        val askPlus: Boolean = o.optInt("askPlus", 0) != 0
        /** "target" is a shape name in band b and a number here. */
        val targetNum: Int = o.optInt("target", 0)

        /** cipher: how far the alphabet is shifted. */
        val shift: Int = o.optInt("shift", 0)

        /** symbolCode: the key, and the word written in those symbols. */
        class Sym(o: JSONObject) {
            val glyph: String = o.optString("glyph", "circle")
            val colour: String = o.optString("color", "primary")
            val letter: String = o.optString("letter")
        }
        val symKey: List<Sym> = o.syms("key")
        /** "word" is a plain string in band b; here it can be a row of symbols. */
        val symWord: List<Sym> = o.syms("word")

        /** letterCode: the numbers standing for the letters. */
        val codes: List<String> = o.optJSONArray("codes")?.let { a ->
            (0 until a.length()).map { a.optString(it) }
        } ?: emptyList()

        /** net: the squares of the net, what is drawn on each, which to find. */
        val netCells: List<Pair<Int, Int>> = o.optJSONArray("cells")?.let { a ->
            (0 until a.length()).mapNotNull { i ->
                (a.opt(i) as? JSONArray)?.let { it.optInt(0) to it.optInt(1) }
            }
        } ?: emptyList()
        val marks: List<String> = o.strings("marks")

        /** polycube: the little cubes the shape is made of. */
        val cubes: List<Triple<Int, Int, Int>> = o.triples("cubes")

        /** stack: how tall the pile is on each square of the floor. */
        val heights: List<List<Int>> = o.optJSONArray("heights")?.let { a ->
            (0 until a.length()).mapNotNull { i ->
                (a.opt(i) as? JSONArray)?.let { r ->
                    (0 until r.length()).map { r.optInt(it) }
                }
            }
        } ?: emptyList()

        /** roll: the floor, where the dice starts, and which faces show. */
        val gridW: Int = o.optInt("w", 0)
        val gridH: Int = o.optInt("h", 0)
        /** "start" is a compass direction in band b and a square here. */
        val startCell: Pair<Int, Int>? = o.cell("start")
        val faceTop: Int = o.optInt("top", 0)
        val faceFront: Int = o.optInt("front", 0)
        val faceRight: Int = o.optInt("right", 0)

        /** turnCube: what the turns are, in words. "steps" is a count in band b. */
        val stepLines: List<String> = o.strings("steps")

        /** section: the solid, and the plane cutting it. */
        val solid: String = o.optString("solid")
        val cut: String = o.optString("cut")
        val point: List<Float> = o.floats("point")
        val normal: List<Float> = o.floats("normal")

        /**
         * A teach card's answer, worked out, as a line to read.
         *
         * The picture on a teach card is the same picture a question uses, so
         * it has the same gap in it. Left alone it asks rather than teaches:
         * "Both sides of the equals sign must be the same" over 26 + ? = 34.
         * Twenty-six teach cards carry the answer and nothing was reading it.
         *
         * It arrives as a number, a word, or a list of numbers depending on
         * the picture, so it is kept as the line to print rather than as a
         * value fifteen drawings would each have to know how to place.
         */
        val reveal: String = when (val r = o.opt("reveal")) {
            null, JSONObject.NULL -> ""
            is JSONArray -> (0 until r.length()).joinToString(", ") { r.optString(it) }
            else -> r.toString()
        }

        /** stack and deduce: which side is being looked at, and who or what. */
        val who: String = o.optString("who")
        val what: String = o.optString("what")
    }

    /** One drawn thing inside a pattern, tray or odd-one-out row. */
    class CellSpec(o: JSONObject) {
        val kind: String = o.optString("kind", "circle")
        val color: String = o.optString("color", "primary")
        val rotation: Float = o.optDouble("rotation", 0.0).toFloat()
    }

    class Stop(o: JSONObject, val sectionN: Int, val unitN: Int) {
        val id = o.optString("id")
        val title = o.optString("title")
        val boss = o.optBoolean("boss", false)
        val authored = o.optBoolean("authored", false)
        val teachLine: String? = o.optJSONObject("teach")?.optString("line")

        /** The teach card's own worked example — never one of the questions. */
        /** A logic stop demonstrates a condition instead of a board. */
        class TruthDemo(o: JSONObject) {
            val facts: List<String> = o.optJSONArray("facts")?.let { a ->
                (0 until a.length()).map { a.optString(it) }
            } ?: emptyList()
            val expr: String = o.optString("expr")
            val value: Boolean = o.optBoolean("value")
        }

        val teachTruth: TruthDemo? =
            o.optJSONObject("teach")?.optJSONObject("truth")?.let { TruthDemo(it) }

        /** Two programs shown at once, when one run cannot make the point. */
        class CompareDemo(o: JSONObject) {
            val board = Board(o.getJSONObject("board"))
            val a: List<String> = o.optJSONArray("a")?.let { j ->
                (0 until j.length()).map { j.optString(it) } } ?: emptyList()
            val b: List<String> = o.optJSONArray("b")?.let { j ->
                (0 until j.length()).map { j.optString(it) } } ?: emptyList()
        }

        val teachCompare: CompareDemo? =
            o.optJSONObject("teach")?.optJSONObject("compare")?.let { CompareDemo(it) }

        val teachBoard: Board? =
            o.optJSONObject("teach")?.optJSONObject("board")?.let { Board(it) }

        /** A Number Sense stop demonstrates with one of its own pictures. */
        val teachPic: Pic? =
            o.optJSONObject("teach")?.optJSONObject("pic")?.let { Pic(it) }
        val questions: List<Question> = o.optJSONArray("questions")?.let { arr ->
            (0 until arr.length()).map { Question(arr.getJSONObject(it), o.optString("id"), it) }
        } ?: emptyList()
    }

    class Unit(val n: Int, val title: String, val stops: List<Stop>)
    class Section(val n: Int, val title: String, val subtitle: String, val units: List<Unit>)

    class Skill(o: JSONObject) {
        val id = o.optString("id")
        val name = o.optString("name")
        val band = o.optString("band").lowercase()
        val promise = o.optString("promise")
        val sections: List<Section>

        init {
            val secs = mutableListOf<Section>()
            val sa = o.optJSONArray("sections") ?: JSONArray()
            for (i in 0 until sa.length()) {
                val so = sa.getJSONObject(i)
                val sn = so.optInt("n", i + 1)
                val units = mutableListOf<Unit>()
                val ua = so.optJSONArray("units") ?: JSONArray()
                for (j in 0 until ua.length()) {
                    val uo = ua.getJSONObject(j)
                    val un = uo.optInt("n", j + 1)
                    val sta = uo.optJSONArray("stops") ?: JSONArray()
                    units.add(Unit(un, uo.optString("title"),
                        (0 until sta.length()).map { Stop(sta.getJSONObject(it), sn, un) }))
                }
                secs.add(Section(sn, so.optString("title"), so.optString("subtitle"), units))
            }
            sections = secs
        }

        /** Every stop in order, playable or not — this is what the roadmap draws. */
        val allStops: List<Stop> by lazy { sections.flatMap { it.units }.flatMap { it.stops } }

        /** The stops a gate may actually serve: authored, in ladder order. */
        val ladder: List<Stop> by lazy { allStops.filter { it.authored && it.questions.isNotEmpty() } }

        fun stopById(id: String): Stop? = allStops.firstOrNull { it.id == id }
    }

    // ---------------------------------------------------------------- loading

    private const val DIR = "flutter_assets/assets/curriculum"
    @Volatile private var cached: List<Skill>? = null

    /** Every skill shipped in the assets, cheapest-band first. */
    fun allSkills(c: Context): List<Skill> {
        cached?.let { return it }
        val out = mutableListOf<Skill>()
        try {
            for (name in c.assets.list(DIR).orEmpty()) {
                if (!name.endsWith(".json")) continue
                try {
                    val text = c.assets.open("$DIR/$name").bufferedReader().use { it.readText() }
                    out.add(Skill(JSONObject(text)))
                } catch (e: Exception) {
                    // One malformed file must not cost the child every skill.
                }
            }
        } catch (e: Exception) {
            // No curriculum directory at all; callers fall back to [Questions].
        }
        val sorted = out.sortedBy { it.band }
        cached = sorted
        return sorted
    }

    /**
     * The skill to serve this child, or null to fall back to [Questions].
     *
     * A skill is written for a band and offered to that band and upwards, never
     * downwards: a six year old cannot read "tap the block that runs first", and
     * handing them a skill written for a ten year old would make the roadmap a
     * record of failure rather than progress.
     *
     * When several fit, the child gets the most advanced one they qualify for,
     * so a nine year old meets Think Like a Coder rather than the counting
     * skill written for their younger sibling.
     */
    fun skillFor(c: Context): Skill? {
        val child = EnginePrefs.ageBand(c).lowercase()
        return allSkills(c).filter { it.band.isNotEmpty() && child >= it.band }
            .maxByOrNull { it.band }
    }

    /** The skill this child is on, for callers that do not re-check the band. */
    fun skill(c: Context): Skill? = skillFor(c) ?: allSkills(c).firstOrNull()

    // ---------------------------------------------------------------- session

    /**
     * One thing the gate shows. Exactly one of [teachStop] / [question] is set:
     * a teach card introduces the stop the questions that follow belong to.
     */
    class Item(
        val stop: Stop,
        val question: Question?,
        val teachStop: Stop? = null,
        /** A repeat pulled from the review queue — it must not move the cursor. */
        val review: Boolean = false,
    ) {
        val isTeach get() = teachStop != null
    }

    /**
     * Build what this gate should ask: the rest of the current stop, plus one
     * question the child got wrong earlier.
     *
     * ONE GATE IS ONE STOP. A stop is a single idea with six or seven questions
     * on it, which is about a minute — short enough that a child opening an app
     * does not feel ambushed, long enough to actually land the idea. Splitting a
     * stop across two gates for the sake of a round number would break the
     * promise the roadmap makes: "this stop is what Nupo asks next time".
     *
     * A session interrupted halfway (the child backs out, the phone locks)
     * resumes mid-stop, because the cursor moves per question, not per stop.
     *
     * [floor] is a lower bound from the app's rule, kept so a very short stop
     * still fills a reasonable gate.
     */
    fun session(c: Context, floor: Int = 1): List<Item> {
        val s = skill(c) ?: return emptyList()
        if (s.ladder.isEmpty()) return emptyList()

        val out = mutableListOf<Item>()
        var stopIdx = Progress.stopIndex(c)
        var qIdx = Progress.questionIndex(c)
        if (stopIdx >= s.ladder.size) return emptyList() // ladder finished

        // One missed question from an earlier session, re-asked first.
        Progress.nextReview(c)?.let { rid ->
            val stop = s.stopById(rid.substringBefore('#'))
            val q = stop?.questions?.getOrNull(rid.substringAfter('#').toIntOrNull() ?: -1)
            if (stop != null && q != null) out.add(Item(stop, q, review = true))
        }

        // Teach cards do not count against the question total — a child meeting
        // a new idea should still get every question on it.
        fun asked() = out.count { !it.isTeach }
        do {
            val stop = s.ladder[stopIdx]
            if (qIdx == 0 && !Progress.taught(c, stop.id) && stop.teachLine != null) {
                out.add(Item(stop, null, teachStop = stop))
            }
            for (k in qIdx until stop.questions.size) out.add(Item(stop, stop.questions[k]))
            stopIdx++
            qIdx = 0
        } while (asked() < floor && stopIdx < s.ladder.size)

        return out
    }

    // ---------------------------------------------------------------- progress

    /**
     * Per-child ladder position and history. Separate from [EnginePrefs] because
     * this survives rule changes and the midnight rollover.
     */
    object Progress {
        private const val FILE = "nupo_progress"
        private const val K_STOP = "stopIndex"
        private const val K_Q = "questionIndex"
        private const val K_REVIEW = "review"
        private const val K_ASKED = "asked"
        private const val K_RIGHT = "right"
        private const val K_DAY = "lastDay"
        private const val K_STREAK = "streak"
        private const val K_TODAY = "answeredToday"

        private fun p(c: Context): SharedPreferences =
            c.getSharedPreferences(FILE, Context.MODE_PRIVATE)

        /**
         * Ladder position is per skill.
         *
         * Stop ids repeat between skills — both start at "1.1.1" — so a single
         * cursor would put a child who moves skills at whatever stop number they
         * had reached in the other one, and mark teach cards they have never
         * seen as already taught.
         */
        private fun ns(c: Context, key: String): String {
            val id = skillFor(c)?.id.orEmpty()
            return if (id.isEmpty()) key else "${key}__$id"
        }

        /**
         * Progress saved before skills were namespaced belongs to the coder
         * skill, the only one that existed then.
         */
        private const val LEGACY_SKILL = "think_like_a_coder"

        private fun getIntNs(c: Context, key: String): Int {
            val pr = p(c)
            val k = ns(c, key)
            if (pr.contains(k)) return pr.getInt(k, 0)
            if (skillFor(c)?.id == LEGACY_SKILL && pr.contains(key)) {
                return pr.getInt(key, 0)
            }
            return 0
        }

        fun stopIndex(c: Context) = getIntNs(c, K_STOP)
        fun questionIndex(c: Context) = getIntNs(c, K_Q)
        fun asked(c: Context) = p(c).getInt(K_ASKED, 0)
        fun right(c: Context) = p(c).getInt(K_RIGHT, 0)
        fun streak(c: Context) = p(c).getInt(K_STREAK, 0)
        fun answeredToday(c: Context) = if (today() == p(c).getString(K_DAY, "")) p(c).getInt(K_TODAY, 0) else 0

        fun taught(c: Context, stopId: String): Boolean {
            val pr = p(c)
            val k = ns(c, "taught_$stopId")
            if (pr.contains(k)) return pr.getBoolean(k, false)
            return skillFor(c)?.id == LEGACY_SKILL &&
                pr.getBoolean("taught_$stopId", false)
        }

        fun markTaught(c: Context, stopId: String) =
            p(c).edit().putBoolean(ns(c, "taught_$stopId"), true).apply()

        /** Stops fully answered — what the roadmap fills in. */
        fun stopsDone(c: Context) = stopIndex(c)

        /**
         * Record one resolved question. The cursor moves whether or not the
         * child got it right; a miss comes back through the review queue instead
         * of blocking the ladder.
         */
        fun resolve(c: Context, q: Question, correct: Boolean) {
            val pr = p(c)
            val e = pr.edit()
            e.putInt(K_ASKED, asked(c) + 1)
            if (correct) e.putInt(K_RIGHT, right(c) + 1)
            bumpToday(c, e)

            // Streak and today's count.
            val d = today()
            if (pr.getString(K_DAY, "") != d) {
                val wasYesterday = pr.getString(K_DAY, "") == yesterday()
                e.putString(K_DAY, d)
                e.putInt(K_TODAY, 1)
                e.putInt(K_STREAK, if (wasYesterday) streak(c) + 1 else 1)
            } else {
                e.putInt(K_TODAY, pr.getInt(K_TODAY, 0) + 1)
            }

            // Review queue: a miss goes to the back, a hit clears any entry.
            val queue = (pr.getString(ns(c, K_REVIEW), "") ?: "")
                .split('|').filter { it.isNotBlank() }
                .toMutableList()
            queue.remove(q.id)
            if (!correct) queue.add(q.id)
            while (queue.size > 20) queue.removeAt(0)
            e.putString(ns(c, K_REVIEW), queue.joinToString("|"))
            e.apply()
        }

        /**
         * Advance the cursor past a question that was served from the ladder
         * (not from the review queue).
         */
        fun advance(c: Context, skill: Skill) {
            var si = stopIndex(c)
            var qi = questionIndex(c) + 1
            val stop = skill.ladder.getOrNull(si) ?: return
            if (qi >= stop.questions.size) { si++; qi = 0 }
            p(c).edit().putInt(ns(c, K_STOP), si).putInt(ns(c, K_Q), qi).apply()
        }

        fun nextReview(c: Context): String? =
            (p(c).getString(ns(c, K_REVIEW), "") ?: "")
                .split('|').firstOrNull { it.isNotBlank() }

        fun reset(c: Context) = p(c).edit().clear().apply()

        /**
         * Questions answered on each of the last seven days, oldest first.
         * This is what the weekly parent summary is built from, so it is kept
         * here rather than derived — the gate is the only thing that sees a
         * question being answered.
         */
        fun week(c: Context): List<Int> {
            val pr = p(c)
            val cal = Calendar.getInstance()
            cal.add(Calendar.DAY_OF_YEAR, -6)
            return (0 until 7).map {
                val n = pr.getInt("d_" + stamp(cal), 0)
                cal.add(Calendar.DAY_OF_YEAR, 1)
                n
            }
        }

        private fun bumpToday(c: Context, e: SharedPreferences.Editor) {
            val k = "d_" + today()
            e.putInt(k, p(c).getInt(k, 0) + 1)
        }

        private fun stamp(cal: Calendar) = String.format(
            "%04d-%02d-%02d",
            cal.get(Calendar.YEAR), cal.get(Calendar.MONTH) + 1, cal.get(Calendar.DAY_OF_MONTH),
        )

        private fun today() = stamp(Calendar.getInstance())
        private fun yesterday() =
            stamp(Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, -1) })
    }

    // ---------------------------------------------------------------- simulator

    /**
     * Runs a GridBot program. Kept deliberately small and total: an illegal move
     * is skipped and the program carries on, which is what makes "tap the first
     * block that fails" a meaningful question.
     */
    object Sim {
        private val DELTA = mapOf(
            "up" to (0 to 1), "down" to (0 to -1),
            "left" to (-1 to 0), "right" to (1 to 0),
        )

        class Result(
            val end: Pair<Int, Int>,
            val stars: Set<Pair<Int, Int>>,
            val hasKey: Boolean,
            val doorOpen: Boolean,
            /** Index into the program AS WRITTEN of the first step that could
             *  not run, or -1. A step inside a loop reports the row a child
             *  actually sees, not its position in the expanded run. */
            val failAt: Int,
            /** Tile occupied after each expanded move, for drawing the trail. */
            val path: List<Pair<Int, Int>>,
            /** The moves actually performed, loops unrolled. */
            val moves: List<String>,
            /** origin[i] is the program row that produced moves[i]. */
            val origin: List<Int>,
            /** What each named box ends up holding. */
            val boxes: Map<String, Int>,
            /** Every box's value after each step, for a trace table. */
            val trace: List<Map<String, Int>>,
        )

        /** How long a program may run before we call it a runaway loop. */
        private const val MAX_STEPS = 2000

        /** Index of the `end` closing the block that opens at [i]. */
        private fun matchEnd(p: List<String>, i: Int, hi: Int): Int {
            var level = 1
            var j = i + 1
            while (j < hi && level > 0) {
                val t = p[j]
                if (t.startsWith("repeat:") || t.startsWith("if:")) level++
                else if (t == "end") level--
                if (level > 0) j++
            }
            return if (j >= hi) -1 else j
        }

        /** Index of this block's own `else`, or -1. */
        private fun splitElse(p: List<String>, lo: Int, hi: Int): Int {
            var level = 0
            var j = lo
            while (j < hi) {
                val t = p[j]
                if (t.startsWith("repeat:") || t.startsWith("if:")) level++
                else if (t == "end") level--
                else if (t == "else" && level == 0) return j
                j++
            }
            return -1
        }

        /**
         * Answers one yes/no question about where Nupo is standing.
         *
         * Sensors are deliberately concrete — "is there a wall above you" —
         * because a child can check the answer by looking at the board, which
         * is what makes a condition feel like a rule rather than a spell.
         */
        private fun sense(
            name: String, pos: Pair<Int, Int>, b: Board,
            hasKey: Boolean, starsLeft: Set<Pair<Int, Int>>,
        ): Boolean = when {
            name == "star" -> starsLeft.contains(pos)
            name == "key" -> hasKey
            name == "door" -> b.door != null && pos == b.door
            name.startsWith("wall-") -> {
                val d = DELTA[name.substringAfter('-')] ?: (0 to 0)
                val n = (pos.first + d.first) to (pos.second + d.second)
                n.first !in 0 until b.w || n.second !in 0 until b.h ||
                    b.walls.contains(n)
            }
            else -> false
        }

        private fun test(
            cond: String, pos: Pair<Int, Int>, b: Board,
            hasKey: Boolean, starsLeft: Set<Pair<Int, Int>>,
        ): Boolean =
            if (cond.startsWith("not-")) !test(cond.substring(4), pos, b, hasKey, starsLeft)
            else sense(cond, pos, b, hasKey, starsLeft)

        /**
         * Unrolls loops in a program with no conditions. Kept for the questions
         * that only ask how many moves a loop makes.
         */
        fun expand(program: List<String>): Pair<List<String>, List<Int>> {
            val r = run(Board(JSONObject("""{"w":99,"h":99,"start":[0,0]}""")), program)
            return r.moves to r.origin
        }

        /**
         * Interprets a program: loops unrolled, conditions evaluated against
         * where Nupo is standing at the moment they are reached.
         *
         * Mirrors run() in tools/curriculum/validate.py. Change one, change the
         * other, or the app will mark right answers wrong.
         */
        fun run(b: Board, program: List<String>): Result {
            var pos = b.start
            val taken = mutableSetOf<Pair<Int, Int>>()
            val path = mutableListOf(pos)
            val moves = mutableListOf<String>()
            val origin = mutableListOf<Int>()
            var hasKey = false
            var opened = false
            var fail = -1
            // Named boxes holding numbers. SET replaces what is inside, ADD
            // changes it. The trace records every box after each step, which is
            // exactly what a trace table shows a child.
            val boxes = b.vars.toMutableMap()
            val trace = mutableListOf<Map<String, Int>>(boxes.toMap())

            fun act(tok: String, src: Int) {
                moves.add(tok)
                origin.add(src)
                if (tok.startsWith("set:") || tok.startsWith("add:")) {
                    val parts = tok.split(":")
                    if (parts.size == 3) {
                        val name = parts[1]
                        val n = parts[2].toIntOrNull() ?: 0
                        boxes[name] = if (parts[0] == "set") n else (boxes[name] ?: 0) + n
                    }
                    trace.add(boxes.toMap())
                    // Nupo does not move, but path must stay one entry longer
                    // than moves or the animation walks off the end of it.
                    path.add(pos)
                    return
                }
                val d = DELTA[tok]
                when {
                    d != null -> {
                        val n = (pos.first + d.first) to (pos.second + d.second)
                        val blocked = n.first !in 0 until b.w ||
                            n.second !in 0 until b.h || b.walls.contains(n)
                        if (blocked) { if (fail < 0) fail = src } else {
                            pos = n
                            if (b.stars.contains(pos) && !b.mustPick) taken.add(pos)
                        }
                    }
                    tok == "pick" -> when {
                        b.key != null && pos == b.key && !hasKey -> hasKey = true
                        b.stars.contains(pos) -> taken.add(pos)
                        else -> if (fail < 0) fail = src
                    }
                    tok == "open" -> {
                        if (b.door != null && pos == b.door && hasKey) opened = true
                        else if (fail < 0) fail = src
                    }
                }
                path.add(pos)
                trace.add(boxes.toMap())
            }

            fun walk(lo: Int, hi: Int, depth: Int) {
                if (depth > 12) return
                var i = lo
                while (i < hi) {
                    if (moves.size > MAX_STEPS) return
                    val tok = program[i]
                    when {
                        tok.startsWith("repeat:") -> {
                            val times = tok.substringAfter(':').toIntOrNull() ?: 0
                            val j = matchEnd(program, i, hi)
                            if (j < 0) return
                            repeat(times) { walk(i + 1, j, depth + 1) }
                            i = j + 1
                        }
                        tok.startsWith("if:") -> {
                            val j = matchEnd(program, i, hi)
                            if (j < 0) return
                            val e = splitElse(program, i + 1, j)
                            val cond = tok.substringAfter(':')
                            if (test(cond, pos, b, hasKey, b.stars - taken)) {
                                walk(i + 1, if (e >= 0) e else j, depth + 1)
                            } else if (e >= 0) {
                                walk(e + 1, j, depth + 1)
                            }
                            i = j + 1
                        }
                        tok == "end" || tok == "else" -> i++
                        else -> { act(tok, i); i++ }
                    }
                }
            }

            walk(0, program.size, 0)
            return Result(pos, taken, hasKey, opened, fail, path, moves, origin,
                boxes, trace)
        }

        /** Did the program satisfy everything the board asks for? */
        fun clears(b: Board, program: List<String>): Boolean {
            val r = run(b, program)
            if (b.goal != null && r.end != b.goal) return false
            if (b.stars.isNotEmpty() && r.stars.size != b.stars.size) return false
            if (b.door != null && !r.doorOpen) return false
            return true
        }
    }
}

// ---------------------------------------------------------------- json helpers

private fun JSONObject.cell(key: String): Pair<Int, Int>? {
    val a = optJSONArray(key) ?: return null
    if (a.length() < 2) return null
    return a.optInt(0) to a.optInt(1)
}

private fun JSONObject.cells(key: String): Set<Pair<Int, Int>> {
    val a = optJSONArray(key) ?: return emptySet()
    return (0 until a.length()).mapNotNull { i ->
        a.optJSONArray(i)?.let { it.optInt(0) to it.optInt(1) }
    }.toSet()
}

/**
 * The "pairs" array as two-element pairs, with null kept as null.
 *
 * An analogy's missing half is the question, so a pair reader that turned a
 * JSON null into 0 or "" would quietly draw an answer where a gap belongs.
 */
private fun <T> JSONObject.pairsOf(read: (JSONArray, Int) -> T?): List<Pair<T?, T?>> {
    val a = optJSONArray("pairs") ?: return emptyList()
    return (0 until a.length()).mapNotNull { i ->
        a.optJSONArray(i)?.let { pr -> read(pr, 0) to read(pr, 1) }
    }
}

/** An array of arrays of strings, e.g. the rules of an if-then question. */
private fun JSONObject.rows(key: String): List<List<String>> {
    val a = optJSONArray(key) ?: return emptyList()
    return (0 until a.length()).mapNotNull { i ->
        (a.opt(i) as? JSONArray)?.let { r -> (0 until r.length()).map { r.optString(it) } }
    }
}

/** An array of [x, y, z] whole numbers, e.g. the cubes of a solid. */
private fun JSONObject.triples(key: String): List<Triple<Int, Int, Int>> {
    val a = optJSONArray(key) ?: return emptyList()
    return (0 until a.length()).mapNotNull { i ->
        (a.opt(i) as? JSONArray)?.let { Triple(it.optInt(0), it.optInt(1), it.optInt(2)) }
    }
}

/** An array of numbers, e.g. a point or a direction in space. */
private fun JSONObject.floats(key: String): List<Float> {
    val a = optJSONArray(key) ?: return emptyList()
    return (0 until a.length()).map { a.optDouble(it, 0.0).toFloat() }
}

/**
 * Symbols, taken only where they ARE symbols.
 *
 * "word" is a plain string in band b and a row of symbol objects in band d, so
 * this reads nothing at all rather than throwing when it meets the string.
 */
private fun JSONObject.syms(key: String): List<Curriculum.Pic.Sym> {
    val a = optJSONArray(key) ?: return emptyList()
    return (0 until a.length()).mapNotNull {
        (a.opt(it) as? JSONObject)?.let(Curriculum.Pic::Sym)
    }
}

private fun JSONObject.strings(key: String): List<String> =
    optJSONArray(key)?.toStrings() ?: emptyList()

private fun JSONArray.toStrings(): List<String> =
    (0 until length()).map { optString(it) }
