package com.brainpass.brainpass

import kotlin.random.Random

/**
 * Native (Kotlin) port of the question engine. The kid-facing lock is now 100%
 * native, so the generators + GK content live here (mirroring lib/questions.dart).
 */

enum class Band { A, B, C }

fun bandFromString(s: String?): Band = when (s) {
    "a" -> Band.A
    "c" -> Band.C
    else -> Band.B
}

/** A question. [options] null => numeric keypad; non-null => multiple choice. */
data class Question(
    val prompt: String,
    val answer: String,
    val options: List<String>? = null,
) {
    val isMultipleChoice: Boolean get() = options != null
}

enum class QuestionKind { MATH, PATTERN, GK }

object Questions {
    private fun r(min: Int, max: Int) = min + Random.nextInt(max - min + 1)

    fun generateMath(band: Band): Question = when (band) {
        Band.A -> if (Random.nextBoolean()) {
            val x = r(1, 10); val y = r(1, 10); Question("$x + $y = ?", "${x + y}")
        } else {
            val x = r(2, 20); val y = r(1, x); Question("$x − $y = ?", "${x - y}")
        }
        Band.B -> when (r(0, 3)) {
            0 -> { val x = r(10, 99); val y = r(10, 99); Question("$x + $y = ?", "${x + y}") }
            1 -> { val x = r(20, 99); val y = r(1, x); Question("$x − $y = ?", "${x - y}") }
            2 -> { val x = r(2, 12); val y = r(2, 12); Question("$x × $y = ?", "${x * y}") }
            else -> { val y = r(2, 12); val q = r(2, 12); val x = y * q; Question("$x ÷ $y = ?", "$q") }
        }
        Band.C -> when (r(0, 3)) {
            0 -> { val x = r(11, 49); val y = r(2, 12); Question("$x × $y = ?", "${x * y}") }
            1 -> { val y = r(3, 15); val q = r(3, 15); val x = y * q; Question("$x ÷ $y = ?", "$q") }
            2 -> { val a = r(2, 9); val b = r(2, 9); val c = r(2, 9); Question("$a × $b + $c = ?", "${a * b + c}") }
            else -> { val n = r(4, 15); Question("$n² = ?", "${n * n}") }
        }
    }

    fun generatePattern(band: Band): Question {
        val step = when (band) {
            Band.A -> r(1, 3)
            Band.B -> r(2, 6)
            Band.C -> r(3, 12)
        }
        val start = r(1, if (band == Band.A) 5 else 12)
        val seq = listOf(start, start + step, start + 2 * step, start + 3 * step)
        val next = start + 4 * step
        return Question("${seq.joinToString(", ")}, ?", "$next")
    }

    fun gkToQuestion(card: GkCard): Question {
        val idx = card.options.indices.toMutableList().also { it.shuffle() }
        val shuffled = idx.map { card.options[it] }
        return Question(card.prompt, card.options[card.correctIndex], shuffled)
    }

    fun generateOne(band: Band, kind: QuestionKind): Question = when (kind) {
        QuestionKind.MATH -> generateMath(band)
        QuestionKind.PATTERN -> generatePattern(band)
        QuestionKind.GK -> {
            val pool = Gk.byBand(band)
            gkToQuestion(pool[Random.nextInt(pool.size)])
        }
    }

    /** Plan of question kinds for one earn cycle: mostly math/pattern, GK sprinkled. */
    fun buildEarnPlan(count: Int): List<QuestionKind> = (0 until count).map { i ->
        when {
            i % 3 == 2 -> QuestionKind.GK
            i % 2 == 0 -> QuestionKind.MATH
            else -> QuestionKind.PATTERN
        }
    }

    fun isCorrect(q: Question, given: String): Boolean {
        val a = q.answer.trim()
        val g = given.trim()
        val ai = a.toIntOrNull(); val gi = g.toIntOrNull()
        return if (ai != null && gi != null) ai == gi else a.equals(g, ignoreCase = true)
    }
}

data class GkCard(val prompt: String, val options: List<String>, val correctIndex: Int)

object Gk {
    fun byBand(b: Band): List<GkCard> = when (b) {
        Band.A -> bandA
        Band.B -> bandB
        Band.C -> bandC
    }

    private val bandA = listOf(
        GkCard("What is a baby dog called?", listOf("Puppy", "Kitten", "Cub"), 0),
        GkCard("The sun is a...?", listOf("Star", "Planet", "Cloud"), 0),
        GkCard("Which animal gives us milk?", listOf("Cow", "Lion", "Snake"), 0),
        GkCard("How many sides does a triangle have?", listOf("3", "4", "5"), 0),
        GkCard("Where do fish live?", listOf("Water", "Trees", "Sky"), 0),
        GkCard("What colour is the sky on a clear day?", listOf("Blue", "Green", "Red"), 0),
        GkCard("Which insect makes honey?", listOf("Bee", "Ant", "Spider"), 0),
        GkCard("What do we see with?", listOf("Eyes", "Ears", "Nose"), 0),
        GkCard("How many days are in a week?", listOf("7", "5", "10"), 0),
        GkCard("Ice is frozen...?", listOf("Water", "Milk", "Juice"), 0),
        GkCard("What is a baby cat called?", listOf("Kitten", "Puppy", "Calf"), 0),
        GkCard("What do plants need to grow?", listOf("Water and sunlight", "Candy", "Toys"), 0),
    )

    private val bandB = listOf(
        GkCard("Which is the largest planet in our solar system?", listOf("Jupiter", "Earth", "Mars"), 0),
        GkCard("What is the fastest land animal?", listOf("Cheetah", "Elephant", "Turtle"), 0),
        GkCard("A group of lions is called a...?", listOf("Pride", "Pack", "Herd"), 0),
        GkCard("On which continent is the Sahara Desert?", listOf("Africa", "Asia", "Europe"), 0),
        GkCard("Roughly how many bones are in an adult human body?", listOf("206", "100", "500"), 0),
        GkCard("In which country is the Great Wall?", listOf("China", "India", "Egypt"), 0),
        GkCard("Making food from sunlight is called...?", listOf("Photosynthesis", "Digestion", "Evaporation"), 0),
        GkCard("What is the largest ocean?", listOf("Pacific", "Atlantic", "Indian"), 0),
        GkCard("How many legs does a spider have?", listOf("8", "6", "4"), 0),
        GkCard("Water freezes at what temperature (°C)?", listOf("0", "50", "100"), 0),
        GkCard("Bats are...?", listOf("Mammals", "Birds", "Insects"), 0),
        GkCard("What currency is used in Japan?", listOf("Yen", "Dollar", "Rupee"), 0),
    )

    private val bandC = listOf(
        GkCard("What is the chemical symbol for gold?", listOf("Au", "Gd", "Go"), 0),
        GkCard("What is the smallest prime number?", listOf("2", "1", "3"), 0),
        GkCard("Which planet is known as the Red Planet?", listOf("Mars", "Venus", "Jupiter"), 0),
        GkCard("Which travels faster?", listOf("Light", "Sound", "They are equal"), 0),
        GkCard("What is the largest organ of the human body?", listOf("Skin", "Heart", "Liver"), 0),
        GkCard("What is the capital of Australia?", listOf("Canberra", "Sydney", "Melbourne"), 0),
        GkCard("A six-sided polygon is called a...?", listOf("Hexagon", "Pentagon", "Octagon"), 0),
        GkCard("What is often called the powerhouse of the cell?", listOf("Mitochondria", "Nucleus", "Ribosome"), 0),
        GkCard("Who wrote Romeo and Juliet?", listOf("Shakespeare", "Dickens", "Tolkien"), 0),
        GkCard("What is the square root of 64?", listOf("8", "6", "16"), 0),
        GkCard("Which gas do plants absorb from the air?", listOf("Carbon dioxide", "Oxygen", "Nitrogen"), 0),
        GkCard("Which country is also a continent?", listOf("Australia", "India", "Brazil"), 0),
    )
}
