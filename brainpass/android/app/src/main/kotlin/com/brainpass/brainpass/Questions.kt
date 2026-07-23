package com.brainpass.brainpass

import android.content.Context
import kotlin.random.Random

/**
 * Question engine v2 — the content brain of the kid-facing learning moment.
 *
 * Design goals (July 2026 "peak fun" redesign):
 *  - Many WAYS to answer, not just keypad/MCQ: tap-the-odd-one, counting,
 *    true/false, compare, missing number, match-the-pairs, put-in-order,
 *    word builder, memory flash.
 *  - A designed session ARC: an easy hook first, variety in the middle (never
 *    the same interaction twice in a row), and a slightly harder "Boss star"
 *    finale.
 *  - Visual, not text-walls: shape/colour tiles rendered natively by LockUi
 *    (Tile.sticker names let real illustrations drop in later with no code
 *    change).
 *  - No stale repeats: banked content (GK/true-false/pairs/words) avoids
 *    anything shown recently (persisted via EnginePrefs).
 */

enum class Band { A, B, C, D } // 5–6 / 7–8 / 9–10 / 11+

fun bandFromString(s: String?): Band = when (s) {
    "a" -> Band.A
    "c" -> Band.C
    "d" -> Band.D
    else -> Band.B
}

/** How the child answers. */
enum class QKind {
    KEYPAD,       // type a number (math / pattern / missing)
    MCQ,          // tap 1 of 3 text options (GK)
    TRUE_FALSE,   // giant true / false buttons
    ODD_ONE_OUT,  // 4 tiles, tap the odd one
    COUNT,        // count the tiles, tap the right number
    COMPARE,      // two big cards, tap the bigger/smaller
    MATCH,        // match 3 left tiles to 3 right tiles
    ORDER,        // arrange 4 numbers smallest -> largest
    WORD,         // letter tiles -> spell the word
    MEMORY,       // memorise 3 tiles, recall one
}

/** Shapes LockUi can draw natively (used when no sticker asset exists). */
object Shape {
    const val CIRCLE = 0
    const val SQUARE = 1
    const val STAR = 2
    const val HEART = 3
    const val TRIANGLE = 4
    const val DIAMOND = 5
    const val MOON = 6
}

/**
 * One visual tile. [sticker] is a future hook: when
 * flutter_assets/assets/stickers/<sticker>.png exists LockUi shows the
 * illustration instead of the shape.
 */
data class Tile(
    val shape: Int,
    val color: Int,
    val label: String = "",
    val sticker: String? = null,
)

/** A single question. Only the fields for its [kind] are set. */
data class Q(
    val kind: QKind,
    val prompt: String,
    val answer: String = "",
    val options: List<String>? = null,     // MCQ / COUNT choices
    val tiles: List<Tile>? = null,          // ODD_ONE_OUT grid / COUNT display / MEMORY shown
    val oddIndex: Int = -1,                 // ODD_ONE_OUT correct tile
    val left: List<String>? = null,         // MATCH left column
    val right: List<String>? = null,        // MATCH right column (shuffled)
    val matchMap: IntArray? = null,         // MATCH: left i -> index in right
    val orderItems: List<String>? = null,   // ORDER: shuffled items; answer = ascending
    val letters: List<Char>? = null,        // WORD: shuffled letters
    val memoryOptions: List<Tile>? = null,  // MEMORY probe tiles (one was shown)
    val memoryAnswer: Int = -1,             // MEMORY correct probe index
    val boss: Boolean = false,              // finale question (double celebration)
)

object Questions {
    private fun r(min: Int, max: Int) = min + Random.nextInt(max - min + 1)

    // Playful tile palette (matches the lock's bright look).
    private val tileColors = intArrayOf(
        0xFFFF7A7A.toInt(), // coral
        0xFF35C9B0.toInt(), // teal
        0xFFFFB020.toInt(), // amber
        0xFF9B7BFF.toInt(), // violet
        0xFF57B9FF.toInt(), // sky
        0xFF7ED957.toInt(), // lime
        0xFFFF8FD1.toInt(), // pink
    )
    private val shapes = intArrayOf(
        Shape.CIRCLE, Shape.SQUARE, Shape.STAR, Shape.HEART,
        Shape.TRIANGLE, Shape.DIAMOND, Shape.MOON
    )
    private fun randColor() = tileColors[Random.nextInt(tileColors.size)]
    private fun randShape() = shapes[Random.nextInt(shapes.size)]

    // ---------------------------------------------------------------------
    // KEYPAD math (kept from v1, D spiced up)
    // ---------------------------------------------------------------------
    fun generateMath(band: Band): Q {
        fun k(prompt: String, ans: Int) = Q(QKind.KEYPAD, prompt, "$ans")
        return when (band) {
            Band.A -> when (r(0, 1)) {
                0 -> { val x = r(1, 5); val y = r(1, 4); k("$x + $y = ?", x + y) }
                else -> { val x = r(2, 9); val y = r(1, x - 1); k("$x − $y = ?", x - y) }
            }
            Band.B -> when (r(0, 2)) {
                0 -> { val x = r(5, 20); val y = r(1, 10); k("$x + $y = ?", x + y) }
                1 -> { val x = r(10, 30); val y = r(1, 9); k("$x − $y = ?", x - y) }
                else -> { val x = r(2, 5); val y = r(2, 6); k("$x × $y = ?", x * y) }
            }
            Band.C -> when (r(0, 3)) {
                0 -> { val x = r(10, 89); val y = r(10, 89); k("$x + $y = ?", x + y) }
                1 -> { val x = r(30, 99); val y = r(10, 29); k("$x − $y = ?", x - y) }
                2 -> { val x = r(2, 12); val y = r(2, 12); k("$x × $y = ?", x * y) }
                else -> { val y = r(2, 10); val q = r(2, 10); k("${y * q} ÷ $y = ?", q) }
            }
            Band.D -> when (r(0, 3)) {
                0 -> { val a = r(2, 8); val b = r(2, 8); val c = r(2, 15); k("$a × $b + $c = ?", a * b + c) }
                1 -> { val y = r(3, 12); val q = r(4, 12); k("${y * q} ÷ $y = ?", q) }
                2 -> { val a = r(2, 9); val b = r(2, 9); val c = r(2, 9); k("$a × $b − $c = ?", a * b - c) }
                else -> { val n = r(4, 15); k("$n² = ?", n * n) }
            }
        }
    }

    // ---------------------------------------------------------------------
    // KEYPAD pattern (kept from v1)
    // ---------------------------------------------------------------------
    fun generatePattern(band: Band): Q {
        fun seqQ(seq: List<Int>, next: Int) =
            Q(QKind.KEYPAD, "${seq.joinToString(",  ")},  ?", "$next")
        return when (band) {
            Band.A -> { val s = r(1, 2); val a = r(1, 5)
                seqQ(listOf(a, a + s, a + 2 * s, a + 3 * s), a + 4 * s) }
            Band.B -> { val s = listOf(2, -2, 3, 5, 10).random()
                val a = if (s < 0) r(10, 20) else r(1, 10)
                seqQ(listOf(a, a + s, a + 2 * s, a + 3 * s), a + 4 * s) }
            Band.C -> { val s = listOf(3, 4, 6, 8, -3, -5).random()
                val a = if (s < 0) r(25, 40) else r(1, 15)
                seqQ(listOf(a, a + s, a + 2 * s, a + 3 * s), a + 4 * s) }
            Band.D -> if (Random.nextBoolean()) {
                val a = r(2, 3)
                seqQ(listOf(a, a * 2, a * 4, a * 8), a * 16)
            } else {
                val a = r(1, 10)
                seqQ(listOf(a, a + 3, a + 2, a + 5, a + 4), a + 7)
            }
        }
    }

    // ---------------------------------------------------------------------
    // MISSING number ( 7 + _ = 12 )
    // ---------------------------------------------------------------------
    fun generateMissing(band: Band): Q {
        fun q(prompt: String, ans: Int) = Q(QKind.KEYPAD, prompt, "$ans")
        return when (band) {
            Band.A -> { val a = r(1, 5); val m = r(1, 5); q("$a + ⬜ = ${a + m}", m) }
            Band.B -> if (Random.nextBoolean()) {
                val a = r(3, 15); val m = r(1, 10); q("$a + ⬜ = ${a + m}", m)
            } else {
                val m = r(1, 9); val c = r(m + 1, 20); q("⬜ − $m = ${c - m}", c)
            }
            Band.C -> { val a = r(2, 9); val m = r(2, 9); q("$a × ⬜ = ${a * m}", m) }
            Band.D -> { val m = r(3, 9); val a = r(2, 8); val add = r(1, 12)
                q("$a × ⬜ + $add = ${a * m + add}", m) }
        }
    }

    // ---------------------------------------------------------------------
    // COUNT the tiles
    // ---------------------------------------------------------------------
    fun generateCount(band: Band): Q {
        val n = if (band == Band.A) r(3, 7) else r(5, 12)
        val color = randColor(); val shape = randShape()
        val tiles = List(n) { Tile(shape, color) }
        val opts = mutableSetOf(n)
        while (opts.size < 3) opts.add((n + r(-3, 3)).coerceAtLeast(1))
        return Q(
            QKind.COUNT, "How many can you count?", "$n",
            options = opts.shuffled().map { "$it" }, tiles = tiles,
        )
    }

    // ---------------------------------------------------------------------
    // ODD ONE OUT (visual)
    // ---------------------------------------------------------------------
    fun generateOdd(band: Band): Q {
        val baseShape = randShape(); val baseColor = randColor()
        var oddShape = baseShape; var oddColor = baseColor
        if (band == Band.A || Random.nextBoolean()) {
            while (oddColor == baseColor) oddColor = randColor()   // colour differs
            if (band != Band.A && Random.nextBoolean()) {
                while (oddShape == baseShape) oddShape = randShape()
            }
        } else {
            while (oddShape == baseShape) oddShape = randShape()   // shape differs
        }
        val odd = r(0, 3)
        val tiles = List(4) { i ->
            if (i == odd) Tile(oddShape, oddColor) else Tile(baseShape, baseColor)
        }
        return Q(QKind.ODD_ONE_OUT, "Tap the odd one out!", "$odd",
            tiles = tiles, oddIndex = odd)
    }

    // ---------------------------------------------------------------------
    // COMPARE (tap the bigger)
    // ---------------------------------------------------------------------
    fun generateCompare(band: Band): Q {
        fun q(l: String, rr: String, leftWins: Boolean) = Q(
            QKind.COMPARE, "Tap the BIGGER one!",
            answer = if (leftWins) "0" else "1",
            options = listOf(l, rr),
        )
        return when (band) {
            Band.A -> { var a = r(1, 20); var b = r(1, 20); while (a == b) b = r(1, 20)
                q("$a", "$b", a > b) }
            Band.B -> { var a = r(10, 99); var b = r(10, 99); while (a == b) b = r(10, 99)
                q("$a", "$b", a > b) }
            Band.C -> { val x = r(3, 9); val y = r(3, 9); val v = x * y
                val other = v + listOf(-3, -2, 2, 3).random()
                q("$x × $y", "$other", v > other) }
            Band.D -> { val num = r(1, 3); val den = num + r(1, 3)   // n/d vs m/k
                val num2 = r(1, 3); val den2 = num2 + r(1, 3)
                val l = num.toDouble() / den; val rr = num2.toDouble() / den2
                if (l == rr) return generateCompare(band)
                q("$num⁄$den", "$num2⁄$den2", l > rr) }
        }
    }

    // ---------------------------------------------------------------------
    // TRUE / FALSE — banked facts + generated math statements
    // ---------------------------------------------------------------------
    private data class Tf(val s: String, val t: Boolean)

    private val tfA = listOf(
        Tf("Dogs can bark.", true), Tf("Fish can walk on land.", false),
        Tf("The sun comes out at night.", false), Tf("Bees make honey.", true),
        Tf("Ice is cold.", true), Tf("Elephants are tiny.", false),
        Tf("A week has 7 days.", true), Tf("Cows say meow.", false),
        Tf("Bananas are yellow.", true), Tf("Fire is safe to touch.", false),
        Tf("Birds have wings.", true), Tf("Carrots grow in the sky.", false),
        Tf("We smell with our nose.", true), Tf("Rain falls up.", false),
    )
    private val tfB = listOf(
        Tf("Spiders have 6 legs.", false), Tf("The sun is a star.", true),
        Tf("Penguins can fly.", false), Tf("An octopus has 8 arms.", true),
        Tf("Water freezes at 0°C.", true), Tf("Bats are birds.", false),
        Tf("A year has 12 months.", true), Tf("Goldfish can live out of water.", false),
        Tf("Rainbows have 7 colours.", true), Tf("The moon makes its own light.", false),
        Tf("Frogs can live on land and in water.", true), Tf("Paper is made from plastic.", false),
        Tf("Giraffes are the tallest land animals.", true), Tf("A day has 26 hours.", false),
    )
    private val tfC = listOf(
        Tf("Jupiter is the largest planet.", true), Tf("Sound travels faster than light.", false),
        Tf("The heart pumps blood.", true), Tf("The Sahara is in Asia.", false),
        Tf("Water boils at 100°C.", true), Tf("Humans have 400 bones.", false),
        Tf("Plants make food using sunlight.", true), Tf("Mercury is the farthest planet from the Sun.", false),
        Tf("Diamond is the hardest natural substance.", true), Tf("Whales are fish.", false),
        Tf("Australia is both a country and a continent.", true), Tf("The Great Wall is in Japan.", false),
        Tf("Mixing blue and yellow makes green.", true), Tf("A triangle has 4 sides.", false),
    )
    private val tfD = listOf(
        Tf("Light travels faster than sound.", true), Tf("The smallest prime number is 1.", false),
        Tf("Skin is the body's largest organ.", true), Tf("Sydney is the capital of Australia.", false),
        Tf("Plants absorb carbon dioxide.", true), Tf("There are 360 seconds in an hour.", false),
        Tf("A hexagon has 6 sides.", true), Tf("Gold's chemical symbol is Go.", false),
        Tf("A right angle is 90 degrees.", true), Tf("Saturn is closest to the Sun.", false),
        Tf("The square root of 81 is 9.", true), Tf("Evaporation turns gas into liquid.", false),
        Tf("Shakespeare wrote Romeo and Juliet.", true), Tf("Pi is exactly 3.", false),
    )

    private fun tfBank(band: Band) = when (band) {
        Band.A -> tfA; Band.B -> tfB; Band.C -> tfC; Band.D -> tfD
    }

    fun generateTrueFalse(ctx: Context, band: Band): Q {
        // Half the time: a math statement (infinite, no repeats possible).
        if (Random.nextBoolean() && band != Band.A) {
            val m = generateMath(band)
            val real = m.answer.toInt()
            val isTrue = Random.nextBoolean()
            val shown = if (isTrue) real else real + listOf(-2, -1, 1, 2).random()
            return Q(
                QKind.TRUE_FALSE,
                m.prompt.replace(" = ?", " = $shown"),
                if (shown == real) "true" else "false",
            )
        }
        val bank = tfBank(band)
        val i = EnginePrefs.pickFresh(ctx, "tf_${band.name}", bank.size)
        return Q(QKind.TRUE_FALSE, bank[i].s, if (bank[i].t) "true" else "false")
    }

    // ---------------------------------------------------------------------
    // MATCH the pairs
    // ---------------------------------------------------------------------
    private val pairsA = listOf(
        "Cow" to "Moo", "Cat" to "Meow", "Dog" to "Woof", "Duck" to "Quack",
        "Lion" to "Roar", "Bee" to "Buzz", "Sun" to "Day", "Moon" to "Night",
        "Fish" to "Water", "Bird" to "Nest",
    )
    private val pairsB = listOf(
        "Cow" to "Calf", "Dog" to "Puppy", "Cat" to "Kitten", "Frog" to "Tadpole",
        "Bee" to "Hive", "Bird" to "Nest", "Bear" to "Den", "Rabbit" to "Burrow",
        "2 × 5" to "10", "3 × 4" to "12", "4 × 4" to "16", "6 + 7" to "13",
    )
    private val pairsC = listOf(
        "France" to "Paris", "Japan" to "Tokyo", "India" to "New Delhi",
        "Italy" to "Rome", "Egypt" to "Cairo", "USA" to "Washington",
        "6 × 7" to "42", "8 × 8" to "64", "9 × 6" to "54", "72 ÷ 8" to "9",
        "Heart" to "Pumps blood", "Lungs" to "Breathe",
    )
    private val pairsD = listOf(
        "Australia" to "Canberra", "Canada" to "Ottawa", "Brazil" to "Brasília",
        "Germany" to "Berlin", "√64" to "8", "√121" to "11", "√144" to "12",
        "7²" to "49", "9²" to "81", "H₂O" to "Water", "Au" to "Gold",
        "12 × 12" to "144",
    )

    private fun pairBank(band: Band) = when (band) {
        Band.A -> pairsA; Band.B -> pairsB; Band.C -> pairsC; Band.D -> pairsD
    }

    fun generateMatch(ctx: Context, band: Band): Q {
        val bank = pairBank(band)
        // pick 3 distinct fresh-ish pairs
        val picked = mutableListOf<Pair<String, String>>()
        val used = mutableSetOf<Int>()
        while (picked.size < 3) {
            val i = if (picked.isEmpty())
                EnginePrefs.pickFresh(ctx, "match_${band.name}", bank.size)
            else Random.nextInt(bank.size)
            if (used.add(i)) picked.add(bank[i])
        }
        val left = picked.map { it.first }
        val rightShuffled = picked.map { it.second }.shuffled()
        val map = IntArray(3) { i -> rightShuffled.indexOf(picked[i].second) }
        return Q(QKind.MATCH, "Match the pairs!", left = left,
            right = rightShuffled, matchMap = map)
    }

    // ---------------------------------------------------------------------
    // ORDER (sort ascending)
    // ---------------------------------------------------------------------
    fun generateOrder(band: Band): Q {
        val range = when (band) {
            Band.A -> 1..12; Band.B -> 1..30; Band.C -> 5..99; Band.D -> 10..500
        }
        val nums = mutableSetOf<Int>()
        while (nums.size < 4) nums.add(range.random())
        val sorted = nums.sorted()
        var shuffled = sorted.shuffled()
        while (shuffled == sorted) shuffled = sorted.shuffled()
        return Q(
            QKind.ORDER, "Put them in order — smallest first!",
            answer = sorted.joinToString(","),
            orderItems = shuffled.map { "$it" },
        )
    }

    // ---------------------------------------------------------------------
    // WORD builder (unscramble letter tiles)
    // ---------------------------------------------------------------------
    private data class W(val word: String, val clue: String)

    private val wordsB = listOf(
        W("STAR", "It twinkles in the night sky"), W("FROG", "It hops and says ribbit"),
        W("MOON", "It glows at night"), W("FISH", "It swims and has fins"),
        W("CAKE", "A sweet birthday treat"), W("LION", "The king of the jungle"),
        W("BEAR", "A big furry animal that loves honey"), W("TREE", "It has leaves and branches"),
    )
    private val wordsC = listOf(
        W("TIGER", "A big cat with stripes"), W("EARTH", "The planet we live on"),
        W("HONEY", "Bees make this"), W("RIVER", "Water that flows to the sea"),
        W("CLOUD", "White and fluffy in the sky"), W("WHALE", "The biggest sea animal"),
        W("MANGO", "A sweet yellow fruit"), W("ZEBRA", "A horse with stripes"),
    )
    private val wordsD = listOf(
        W("ROCKET", "It flies to space"), W("JUNGLE", "A thick tropical forest"),
        W("PLANET", "Earth is one of these"), W("CASTLE", "Where kings and queens live"),
        W("ENERGY", "The power to do work"), W("WINTER", "The coldest season"),
        W("ORANGE", "A fruit and a colour"), W("VOLCANO", "A mountain that erupts"),
    )

    fun generateWord(ctx: Context, band: Band): Q {
        val bank = when (band) {
            Band.A, Band.B -> wordsB; Band.C -> wordsC; Band.D -> wordsD
        }
        val i = EnginePrefs.pickFresh(ctx, "word_${band.name}", bank.size)
        val w = bank[i]
        var mixed = w.word.toList().shuffled()
        while (String(mixed.toCharArray()) == w.word) mixed = w.word.toList().shuffled()
        return Q(QKind.WORD, w.clue, answer = w.word, letters = mixed)
    }

    // ---------------------------------------------------------------------
    // MEMORY flash
    // ---------------------------------------------------------------------
    fun generateMemory(band: Band): Q {
        // 3 clearly distinct tiles (unique shape AND colour).
        val shapePool = shapes.toMutableList().also { it.shuffle() }
        val colorPool = tileColors.toMutableList().also { it.shuffle() }
        val shown = List(3) { Tile(shapePool[it], colorPool[it]) }
        val target = shown[Random.nextInt(3)]
        // probes: the target + 2 tiles that were NOT shown
        val probes = mutableListOf(target)
        probes.add(Tile(shapePool[3], colorPool[3]))
        probes.add(Tile(shapePool[4], colorPool[4]))
        val mixed = probes.shuffled()
        return Q(
            QKind.MEMORY, "Remember these!", tiles = shown,
            memoryOptions = mixed, memoryAnswer = mixed.indexOf(target),
        )
    }

    // ---------------------------------------------------------------------
    // GK MCQ — banks (expanded) with no-repeat pick
    // ---------------------------------------------------------------------
    fun generateGk(ctx: Context, band: Band): Q {
        val pool = Gk.byBand(band)
        val i = EnginePrefs.pickFresh(ctx, "gk_${band.name}", pool.size)
        val card = pool[i]
        val idx = card.options.indices.toMutableList().also { it.shuffle() }
        return Q(
            QKind.MCQ, card.prompt, card.options[card.correctIndex],
            options = idx.map { card.options[it] },
        )
    }

    // ---------------------------------------------------------------------
    // SESSION ARC
    // ---------------------------------------------------------------------
    private fun kindsFor(band: Band): List<QKind> = when (band) {
        Band.A -> listOf(
            QKind.COUNT, QKind.ODD_ONE_OUT, QKind.TRUE_FALSE, QKind.COMPARE,
            QKind.KEYPAD, QKind.MCQ, QKind.MATCH, QKind.MEMORY,
        )
        Band.B -> listOf(
            QKind.TRUE_FALSE, QKind.ODD_ONE_OUT, QKind.COMPARE, QKind.KEYPAD,
            QKind.MCQ, QKind.MATCH, QKind.ORDER, QKind.WORD, QKind.MEMORY, QKind.COUNT,
        )
        Band.C, Band.D -> listOf(
            QKind.TRUE_FALSE, QKind.COMPARE, QKind.KEYPAD, QKind.MCQ,
            QKind.MATCH, QKind.ORDER, QKind.WORD, QKind.MEMORY, QKind.ODD_ONE_OUT,
        )
    }

    private fun easyKinds(band: Band): List<QKind> = when (band) {
        Band.A -> listOf(QKind.COUNT, QKind.ODD_ONE_OUT)
        Band.B -> listOf(QKind.TRUE_FALSE, QKind.ODD_ONE_OUT, QKind.COMPARE)
        Band.C, Band.D -> listOf(QKind.TRUE_FALSE, QKind.COMPARE)
    }

    private fun bossKinds(band: Band): List<QKind> = when (band) {
        Band.A -> listOf(QKind.MEMORY, QKind.MATCH, QKind.KEYPAD)
        Band.B -> listOf(QKind.MATCH, QKind.ORDER, QKind.WORD)
        Band.C -> listOf(QKind.WORD, QKind.ORDER, QKind.MATCH)
        Band.D -> listOf(QKind.WORD, QKind.ORDER, QKind.KEYPAD)
    }

    private fun make(ctx: Context, band: Band, kind: QKind): Q = when (kind) {
        QKind.KEYPAD -> if (Random.nextInt(3) == 0) generatePattern(band)
            else if (Random.nextInt(3) == 0) generateMissing(band) else generateMath(band)
        QKind.MCQ -> generateGk(ctx, band)
        QKind.TRUE_FALSE -> generateTrueFalse(ctx, band)
        QKind.ODD_ONE_OUT -> generateOdd(band)
        QKind.COUNT -> generateCount(band)
        QKind.COMPARE -> generateCompare(band)
        QKind.MATCH -> generateMatch(ctx, band)
        QKind.ORDER -> generateOrder(band)
        QKind.WORD -> generateWord(ctx, band)
        QKind.MEMORY -> generateMemory(band)
    }

    /**
     * Build a whole session: [count] questions with an arc —
     * easy hook -> varied middle (no kind repeats back-to-back) -> boss finale.
     */
    fun buildSession(ctx: Context, band: Band, count: Int): List<Q> {
        if (count <= 0) return emptyList()
        val all = kindsFor(band)
        val plan = mutableListOf<QKind>()
        plan.add(easyKinds(band).random())
        if (count > 1) {
            while (plan.size < count - 1) {
                val pool = all.filter { it != plan.last() }
                plan.add(pool.random())
            }
            val bossPool = bossKinds(band).filter { it != plan.last() }
            plan.add(if (bossPool.isEmpty()) bossKinds(band).random() else bossPool.random())
        }
        return plan.mapIndexed { i, kind ->
            val q = make(ctx, band, kind)
            if (i == plan.size - 1 && count > 1) q.copy(boss = true) else q
        }
    }

    /** Generate a replacement question of the same kind (after a wrong answer). */
    fun regenerate(ctx: Context, band: Band, kind: QKind): Q = make(ctx, band, kind)

    /** Text-style check (keypad / MCQ / compare / word). */
    fun isCorrect(q: Q, given: String): Boolean {
        val a = q.answer.trim(); val g = given.trim()
        val ai = a.toIntOrNull(); val gi = g.toIntOrNull()
        return if (ai != null && gi != null) ai == gi else a.equals(g, ignoreCase = true)
    }
}
