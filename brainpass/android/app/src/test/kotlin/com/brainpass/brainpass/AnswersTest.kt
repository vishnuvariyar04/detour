package com.brainpass.brainpass

import org.json.JSONObject
import org.junit.Assert.fail
import org.junit.Test
import java.io.File

/**
 * Works out the answer to every coder question again, using the app's own
 * simulator, and fails the build if it disagrees with the answer the child
 * will be marked against.
 *
 * The authoring side already checks itself: tools/curriculum/validate.py
 * re-derives each answer from the board before writing the JSON. That proves
 * the PYTHON agrees with itself. It cannot prove the phone agrees, and the
 * phone is what marks the child. The two simulators have drifted apart twice
 * before — once when Python skipped a path entry on a blocked move, and once
 * when a step returned before recording where Nupo was standing — and both
 * times the symptom was a right answer marked wrong on the device.
 *
 * So this runs on the JVM against Curriculum.Sim, the very code the gate uses.
 * If it passes, a child who does the right thing is marked right.
 */
class AnswersTest {

    /** Kept out of the string literals so no tool mangles it. */
    private val NEWLINE = System.lineSeparator()

    private fun asset(name: String): JSONObject {
        // The module sits at android/app; the assets are two levels up.
        val f = File("../../assets/curriculum/$name")
        if (!f.exists()) fail("missing $name — run tools/curriculum/emit_json.py")
        return JSONObject(f.readText())
    }

    private class Wrong(val id: String, val why: String)

    private fun stops(d: JSONObject): List<JSONObject> {
        val out = mutableListOf<JSONObject>()
        val secs = d.getJSONArray("sections")
        for (i in 0 until secs.length()) {
            val units = secs.getJSONObject(i).getJSONArray("units")
            for (j in 0 until units.length()) {
                val ss = units.getJSONObject(j).getJSONArray("stops")
                for (k in 0 until ss.length()) out.add(ss.getJSONObject(k))
            }
        }
        return out
    }

    /** Fewest moves from start to goal, ignoring stars and keys. */
    private fun shortest(b: Curriculum.Board): Int? {
        val goal = b.goal ?: return null
        val seen = mutableMapOf(b.start to 0)
        val q = ArrayDeque(listOf(b.start))
        while (q.isNotEmpty()) {
            val c = q.removeFirst()
            if (c == goal) return seen[c]
            for (d in listOf(0 to 1, 0 to -1, 1 to 0, -1 to 0)) {
                val n = (c.first + d.first) to (c.second + d.second)
                if (n.first !in 0 until b.w || n.second !in 0 until b.h) continue
                if (b.walls.contains(n) || seen.containsKey(n)) continue
                seen[n] = seen[c]!! + 1
                q.addLast(n)
            }
        }
        return null
    }

    @Test
    fun everyCoderAnswerIsTheOneTheBoardGives() {
        val d = asset("think_like_a_coder.json")
        val wrong = mutableListOf<Wrong>()
        val seen = sortedMapOf<String, Int>()
        var checked = 0

        for (stop in stops(d)) {
            if (!stop.optBoolean("authored")) continue
            val qs = stop.optJSONArray("questions") ?: continue
            for (i in 0 until qs.length()) {
                val o = qs.getJSONObject(i)
                val q = Curriculum.Question(o, stop.getString("id"), i)
                val id = "${stop.getString("id")}#$i"
                seen[q.shape] = (seen[q.shape] ?: 0) + 1
                val b = q.board
                val ans = o.getJSONObject("answer")
                val prog = b?.program ?: emptyList()
                checked++

                fun bad(why: String) = wrong.add(Wrong(id, why))
                fun run() = Curriculum.Sim.run(b!!, prog)

                when (q.shape) {
                    "predict" -> {
                        val end = run().end
                        val want = listOf(end.first, end.second)
                        val got = ans.getJSONArray("value")
                            .let { listOf(it.getInt(0), it.getInt(1)) }
                        if (want != got) bad("board ends at $want, answer says $got")
                    }

                    "debug" -> {
                        val f = run().failAt
                        if (f != q.answerInt) bad("first failing row is $f, answer says ${q.answerInt}")
                    }

                    "spot" -> checkSpot(id, q, prog, ::bad)

                    "count" -> {
                        val want: Int? = when (q.kind) {
                            "moves" -> run().moves.size
                            "rows", "steps" -> prog.size
                            "stars" -> run().stars.size
                            "var" -> run().boxes[q.varName] ?: 0
                            "shortest" -> shortest(b!!)
                            "checks" -> checksMade(b!!, prog)
                            "fires" -> checksFired(b!!, prog)
                            // "stated" is a claim the prompt makes, not
                            // something the board can settle.
                            else -> null
                        }
                        if (want != null && want != q.answerInt)
                            bad("${q.kind} is $want, answer says ${q.answerInt}")
                        if (q.choices.isNotEmpty() && !q.choices.contains(q.answerInt))
                            bad("the right number ${q.answerInt} is not one of the choices")
                    }

                    "choose" -> {
                        val opts = q.options.orEmpty()
                        val ok = opts.indices.filter { Curriculum.Sim.clears(b!!, opts[it]) }
                        when (o.optString("criterion", "clears")) {
                            "shortest" -> {
                                val best = ok.minByOrNull { opts[it].size }
                                if (best != q.answerInt)
                                    bad("shortest working list is $best, answer says ${q.answerInt}")
                            }
                            else -> if (ok != listOf(q.answerInt))
                                bad("lists that clear the board: $ok, answer says ${q.answerInt}")
                        }
                    }

                    "compare" -> {
                        val opts = q.options.orEmpty()
                        if (opts.size != 2) bad("a compare needs exactly two lists")
                        else {
                            val same = Curriculum.Sim.run(b!!, opts[0]).end ==
                                Curriculum.Sim.run(b, opts[1]).end
                            if (same != q.answerBool)
                                bad("they end ${if (same) "the same" else "differently"}, " +
                                    "answer says ${q.answerBool}")
                        }
                    }

                    "yesno" -> {
                        val crit = q.criterion
                        val got: Boolean = when {
                            crit.startsWith("canMove:") ->
                                !blocked(b!!, crit.substringAfter(':'))
                            crit == "standingOn:star" -> b!!.stars.contains(b.start)
                            crit == "standingOn:door" -> b!!.door == b.start
                            crit == "reachesFlag" -> b!!.goal != null && run().end == b.goal
                            crit == "allStars" -> run().stars.size == b!!.stars.size
                            crit == "throughDoor" -> run().doorOpen
                            crit == "anyStepFails" -> run().failAt >= 0
                            else -> { bad("unknown criterion '$crit'"); q.answerBool }
                        }
                        if (got != q.answerBool)
                            bad("the board says $got, answer says ${q.answerBool}")
                    }

                    "trace" -> {
                        val t = Curriculum.Sim.run(b!!, prog).trace
                            .map { it[q.varName] ?: 0 }.drop(1).take(prog.size)
                        if (t != q.traceOf) bad("trace is $t, question shows ${q.traceOf}")
                        else if (q.gapRow !in t.indices) bad("gap row ${q.gapRow} out of range")
                        else if (t[q.gapRow] != q.answerInt)
                            bad("row ${q.gapRow} is ${t[q.gapRow]}, answer says ${q.answerInt}")
                    }

                    "fix", "constrain" -> {
                        val steps = ans.getJSONArray("value")
                            .let { a -> (0 until a.length()).map { a.getString(it) } }
                        if (!Curriculum.Sim.clears(b!!, steps))
                            bad("the stored answer does not clear the board")
                        if (steps.size != q.slots) bad("answer is ${steps.size} steps, ${q.slots} slots")
                    }

                    "inverse" -> {
                        val steps = ans.getJSONArray("value")
                            .let { a -> (0 until a.length()).map { a.getString(it) } }
                        if (steps != prog) bad("the answer is not the path shown")
                    }

                    // chooseText and complete are a choice the author makes,
                    // not something the board decides. What CAN be checked is
                    // that the index points at an option that exists.
                    "chooseText", "complete" -> {
                        if (q.answerInt !in q.optionsText.indices)
                            bad("answer ${q.answerInt} is not one of ${q.optionsText.size} options")
                    }

                    else -> bad("no check for shape '${q.shape}'")
                }
            }
        }

        if (wrong.isNotEmpty()) {
            val msg = buildString {
                append("${wrong.size} of $checked answers disagree with the ")
                append("simulator that grades them:\n")
                wrong.take(40).forEach { append("  ${it.id}: ${it.why}\n") }
            }
            fail(msg)
        }
        // Printed so a shape that quietly stopped being checked is visible
        // rather than showing up as a smaller number nobody reads.
        println("$checked coder answers re-derived on the phone's own simulator; all agree")
        println("  by shape: " + seen.entries.joinToString { "${it.key} ${it.value}" })
    }

    /**
     * The same treatment for Number Sense: work the answer out from the
     * PICTURE, not from the answer field, and check the app would mark it
     * right. Comparing an answer against itself proves nothing; deriving it
     * again from what the child can see is what makes agreement mean
     * something.
     */
    @Test
    fun everyNumberSenseAnswerIsTheOneThePictureGives() {
        val d = asset("number_sense.json")
        val wrong = mutableListOf<Wrong>()
        val seen = sortedMapOf<String, Int>()
        var checked = 0

        for (stop in stops(d)) {
            if (!stop.optBoolean("authored")) continue
            val qs = stop.optJSONArray("questions") ?: continue
            for (i in 0 until qs.length()) {
                val o = qs.getJSONObject(i)
                val q = Curriculum.Question(o, stop.getString("id"), i)
                val id = "${stop.getString("id")}#$i"
                seen[q.shape] = (seen[q.shape] ?: 0) + 1
                val p = q.pic ?: run {
                    wrong.add(Wrong(id, "no picture to read the answer from")); return@run null
                } ?: continue
                val ans = o.getJSONObject("answer")
                checked++
                fun bad(why: String) = wrong.add(Wrong(id, why))

                fun num(want: Int) {
                    if (want != q.answerInt) bad("the picture shows $want, answer says ${q.answerInt}")
                    if (q.choices.isNotEmpty() && !q.choices.contains(q.answerInt))
                        bad("the right number is not among the choices")
                }
                fun opt(want: Int) {
                    if (want != q.answerInt) bad("the picture points at $want, answer says ${q.answerInt}")
                }

                when (q.shape) {
                    "countObjects" ->
                        num(if (p.splitAt < 0) p.n
                            else if (q.prompt.contains("yellow")) p.n - p.splitAt else p.splitAt)

                    "tenFrame" ->
                        num(if (q.prompt.contains("more") && q.prompt.contains("fill"))
                                10 - p.filled
                            else p.filled + maxOf(p.second, 0))

                    "dice" -> num(p.faces.sum())
                    "rods" -> num(p.n)
                    "array" -> num(p.rows * p.cols)
                    "groups" -> num(if (p.share) p.per else p.groupCount * p.per)
                    "barModel" -> num(if (p.ask == "more") Math.abs(p.a - p.b) else p.a + p.b)

                    "bond" -> num(when (p.gap) {
                        "right" -> (p.whole ?: 0) - (p.left ?: 0)
                        "left" -> (p.whole ?: 0) - (p.right ?: 0)
                        else -> (p.left ?: 0) + (p.right ?: 0)
                    })

                    "numberLine" -> {
                        val hops = if (p.hops > 0) p.hops
                        else Regex("""Take (\d+) hops""").find(q.prompt)?.groupValues?.get(1)?.toInt()
                        if (hops == null) bad("the prompt never says how many hops")
                        else num((p.hopFrom ?: 0) + p.step * hops)
                    }

                    "balance" -> opt(if (p.leftCount > p.rightCount) 0
                                     else if (p.rightCount > p.leftCount) 1 else 2)

                    "fraction" -> opt(if (p.shaded.toFloat() / p.slices >
                                          p.otherShaded.toFloat() / p.otherSlices) 0 else 1)

                    "fractionWall" -> {
                        val rows = p.strips
                        if (o.optJSONObject("pic")?.optString("ask", "biggest") == "biggest") {
                            val fewest = rows.map { it.first }.min()
                            opt(rows.indexOfFirst { it.first == fewest })
                        } else {
                            val top = rows[0].second.toFloat() / rows[0].first
                            opt((1 until rows.size).first {
                                Math.abs(rows[it].second.toFloat() / rows[it].first - top) < 1e-6
                            })
                        }
                    }

                    "oddOneOut" -> {
                        val sig = p.cells.map { Triple(it.kind, it.color, it.rotation) }
                        val odd = sig.indices.filter { k -> sig.count { it == sig[k] } == 1 }
                        if (odd.size != 1) bad("$odd are all unlike the rest")
                        else opt(odd[0])
                    }

                    "pattern" -> {
                        val want = p.cells[p.gapAt]
                        val k = q.optionCells.indexOfFirst {
                            it.kind == want.kind && it.color == want.color &&
                                it.rotation == want.rotation
                        }
                        if (k < 0) bad("no option matches the gap") else opt(k)
                    }

                    // A shape count can include shapes made OF other pieces —
                    // two triangles that together form a square — so the
                    // drawn parts are a floor, not the answer.
                    "shapeCount" -> {
                        val drawn = p.parts.count { it.first == p.target }
                        if (q.answerInt < drawn)
                            bad("$drawn ${p.target}s are drawn, answer says only ${q.answerInt}")
                        if (q.choices.isNotEmpty() && !q.choices.contains(q.answerInt))
                            bad("the right number is not among the choices")
                    }

                    // Graded by WHAT was found, not by which index: several
                    // pieces are triangles and any of them is a right answer.
                    "shapeHunt" -> {
                        val want = ans.optString("value")
                        if (want != p.target)
                            bad("the picture asks for '${p.target}', answer says '$want'")
                        if (p.parts.none { it.first == p.target })
                            bad("no piece in the figure is a ${p.target}")
                    }

                    "sizeOrder" -> {
                        val want = p.sizes.indices.sortedBy { p.sizes[it] }
                        val got = ans.getJSONArray("value")
                            .let { a -> (0 until a.length()).map { a.getInt(it) } }
                        if (want != got) bad("smallest first is $want, answer says $got")
                    }

                    "mirror" -> {
                        val want = p.given.map { listOf(p.cols - 1 - it.first, it.second) }.sortedBy { it[0] * 100 + it[1] }
                        val got = ans.getJSONArray("value").let { a ->
                            (0 until a.length()).map { k ->
                                a.getJSONArray(k).let { listOf(it.getInt(0), it.getInt(1)) }
                            }
                        }.sortedBy { it[0] * 100 + it[1] }
                        if (want != got) bad("the reflection is $want, answer says $got")
                    }

                    // sortTwo is graded per item against the tray labels, which
                    // are words rather than a rule the picture settles.
                    "sortTwo" -> {}

                    else -> bad("no check for shape '${q.shape}'")
                }
            }
        }

        if (wrong.isNotEmpty()) {
            fail(buildString {
                append("${wrong.size} of $checked Number Sense answers disagree ")
                append("with their own picture:" + NEWLINE)
                wrong.take(40).forEach { append("  ${it.id}: ${it.why}" + NEWLINE) }
            })
        }
        println("$checked Number Sense answers re-derived from the picture; all agree")
        println("  by shape: " + seen.entries.joinToString { "${it.key} ${it.value}" })
    }

    private fun blocked(b: Curriculum.Board, dir: String): Boolean {
        val d = when (dir) {
            "up" -> 0 to 1; "down" -> 0 to -1
            "left" -> -1 to 0; else -> 1 to 0
        }
        val n = (b.start.first + d.first) to (b.start.second + d.second)
        return n.first !in 0 until b.w || n.second !in 0 until b.h || b.walls.contains(n)
    }

    /**
     * How many times a condition is LOOKED at, and how many times it says yes.
     *
     * Sim does not record this — nothing in the app needs it — so it is worked
     * out here by walking the program the same way Sim does. That makes it a
     * genuinely separate derivation of the two questions section 3 leans on.
     */
    private fun walkChecks(b: Curriculum.Board, prog: List<String>): List<Boolean> {
        val out = mutableListOf<Boolean>()
        for (i in prog.indices) {
            if (!prog[i].startsWith("if:")) continue
            // Re-run the program and count how the condition at row i came out
            // each time it was reached. Cheaper to do it by replay than to
            // duplicate the interpreter: run the prefix, then read the state.
        }
        // Replay properly: step the program, evaluating conditions as we go.
        val res = mutableListOf<Boolean>()
        var pos = b.start
        val taken = mutableSetOf<Pair<Int, Int>>()
        var hasKey = false

        fun sense(name: String): Boolean = when {
            name.startsWith("not-") -> !sense(name.substring(4))
            name == "star" -> (b.stars - taken).contains(pos)
            name == "key" -> hasKey
            name == "door" -> b.door != null && pos == b.door
            name.startsWith("wall-") -> {
                val d = when (name.substringAfter('-')) {
                    "up" -> 0 to 1; "down" -> 0 to -1
                    "left" -> -1 to 0; else -> 1 to 0
                }
                val n = (pos.first + d.first) to (pos.second + d.second)
                n.first !in 0 until b.w || n.second !in 0 until b.h || b.walls.contains(n)
            }
            else -> false
        }

        fun matchEnd(i: Int, hi: Int): Int {
            var level = 1; var j = i + 1
            while (j < hi && level > 0) {
                val t = prog[j]
                if (t.startsWith("repeat:") || t.startsWith("if:")) level++
                else if (t == "end") level--
                if (level > 0) j++
            }
            return if (j >= hi) -1 else j
        }

        fun splitElse(lo: Int, hi: Int): Int {
            var level = 0; var j = lo
            while (j < hi) {
                val t = prog[j]
                if (t.startsWith("repeat:") || t.startsWith("if:")) level++
                else if (t == "end") level--
                else if (t == "else" && level == 0) return j
                j++
            }
            return -1
        }

        fun walk(lo: Int, hi: Int, depth: Int) {
            if (depth > 12) return
            var i = lo
            while (i < hi) {
                val t = prog[i]
                when {
                    t.startsWith("repeat:") -> {
                        val times = t.substringAfter(':').toIntOrNull() ?: 0
                        val j = matchEnd(i, hi); if (j < 0) return
                        repeat(times) { walk(i + 1, j, depth + 1) }
                        i = j + 1
                    }
                    t.startsWith("if:") -> {
                        val j = matchEnd(i, hi); if (j < 0) return
                        val e = splitElse(i + 1, j)
                        val v = sense(t.substringAfter(':'))
                        res.add(v)
                        if (v) walk(i + 1, if (e >= 0) e else j, depth + 1)
                        else if (e >= 0) walk(e + 1, j, depth + 1)
                        i = j + 1
                    }
                    t == "end" || t == "else" -> i++
                    else -> {
                        when {
                            t == "pick" -> when {
                                b.key != null && pos == b.key && !hasKey -> hasKey = true
                                b.stars.contains(pos) -> taken.add(pos)
                            }
                            t == "open" -> {}
                            t.startsWith("set:") || t.startsWith("add:") -> {}
                            else -> {
                                val d = when (t) {
                                    "up" -> 0 to 1; "down" -> 0 to -1
                                    "left" -> -1 to 0; "right" -> 1 to 0
                                    else -> null
                                }
                                if (d != null) {
                                    val n = (pos.first + d.first) to (pos.second + d.second)
                                    val off = n.first !in 0 until b.w ||
                                        n.second !in 0 until b.h || b.walls.contains(n)
                                    if (!off) {
                                        pos = n
                                        if (b.stars.contains(pos) && !b.mustPick) taken.add(pos)
                                    }
                                }
                            }
                        }
                        i++
                    }
                }
            }
        }
        walk(0, prog.size, 0)
        out.addAll(res)
        return out
    }

    private fun checksMade(b: Curriculum.Board, p: List<String>) = walkChecks(b, p).size
    private fun checksFired(b: Curriculum.Board, p: List<String>) = walkChecks(b, p).count { it }

    /**
     * A "tap the row that..." question is fair only when exactly one row fits.
     * Two shipped where several did, and a child tapping a different right row
     * was told they were wrong.
     */
    private fun checkSpot(
        id: String, q: Curriculum.Question, prog: List<String>,
        bad: (String) -> Unit,
    ) {
        val b = q.board ?: return bad("a spot question needs a board")
        val crit = q.criterion
        if (crit.isEmpty()) return bad("no criterion, so nothing says which row")
        val inside = prog.indices.filter {
            !prog[it].startsWith("repeat:") && !prog[it].startsWith("if:") &&
                prog[it] != "end" && prog[it] != "else"
        }
        val ran = Curriculum.Sim.run(b, prog).origin.toSet()
        val hit: List<Int> = when {
            crit == "skipped" -> inside.filter { it !in ran }
            crit == "ran" -> inside.filter { it in ran }
            crit == "first" -> listOf(0)
            crit == "pickup" -> prog.indices.filter { prog[it] == "pick" }
            crit == "replaces" -> prog.indices.filter { prog[it].startsWith("set:") }
            crit == "loopOpen" -> prog.indices.filter { prog[it].startsWith("repeat:") }
            crit == "innerLoop" ->
                prog.indices.filter { prog[it].startsWith("repeat:") }.drop(1)
            crit == "lastInLoop" -> {
                val open = prog.indexOfFirst { it.startsWith("repeat:") }
                if (open < 0) emptyList() else {
                    var level = 1; var j = open + 1
                    while (j < prog.size && level > 0) {
                        val t = prog[j]
                        if (t.startsWith("repeat:") || t.startsWith("if:")) level++
                        else if (t == "end") level--
                        if (level > 0) j++
                    }
                    listOf(j - 1)
                }
            }
            crit == "undo" -> {
                val opp = mapOf("up" to "down", "down" to "up",
                    "left" to "right", "right" to "left")
                (1 until prog.size).filter { opp[prog[it - 1]] == prog[it] }
            }
            crit.startsWith("firstChanges:") -> {
                val n = crit.substringAfter(':')
                prog.indices.filter {
                    prog[it].startsWith("set:$n:") || prog[it].startsWith("add:$n:")
                }.take(1)
            }
            crit.startsWith("chunk:") -> {
                val n = crit.substringAfter(':').toInt()
                val starts = (0..prog.size - n).filter { i ->
                    (0..prog.size - n).any { j -> j != i && prog.subList(j, j + n) == prog.subList(i, i + n) }
                }
                if (starts.size < 2) bad("no $n-row group actually repeats")
                starts.take(1)
            }
            crit.startsWith("afterChunk:") -> {
                val n = crit.substringAfter(':').toInt()
                var i = 0
                while (i + 2 * n <= prog.size &&
                    prog.subList(i, i + n) == prog.subList(i + n, i + 2 * n)) i += n
                if (i + n < prog.size) listOf(i + n) else emptyList()
            }
            else -> { bad("unknown criterion '$crit'"); return }
        }
        if (hit.size > 1 && !crit.startsWith("chunk:"))
            bad("rows $hit all fit — a child tapping any of them is marked wrong")
        if (q.answerInt !in hit) bad("rows that fit are $hit, answer says ${q.answerInt}")
    }
}
