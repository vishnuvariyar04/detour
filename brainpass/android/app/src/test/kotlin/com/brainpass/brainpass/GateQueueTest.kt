package com.brainpass.brainpass

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotSame
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class GateQueueTest {

    private class Q(val name: String, val review: Boolean = false)

    private fun queue(vararg names: String, review: Set<String> = emptySet()) =
        GateQueue(names.map { Q(it, it in review) }) { Q(it.name, it.review) }

    /**
     * Plays the gate like GuardService does: walk the queue, and on a wrong answer
     * requeue. [firstTryWrong] are answered wrongly the first time only; [alwaysWrong]
     * are wrong for [alwaysWrongTimes] attempts before being answered right.
     * Returns the order in which questions were shown and how often the cursor moved.
     */
    private fun play(
        q: GateQueue<Q>,
        firstTryWrong: Set<String> = emptySet(),
        wrongTimes: Map<String, Int> = emptyMap(),
    ): Pair<List<String>, Int> {
        val shown = mutableListOf<String>()
        val misses = HashMap<String, Int>()
        var cursorMoves = 0
        var i = 0
        while (true) {
            val item = q[i] ?: break
            shown += item.name
            val need = wrongTimes[item.name] ?: if (item.name in firstTryWrong) 1 else 0
            val correct = (misses[item.name] ?: 0) >= need
            // The same rule CoderGate uses: cursor moves only on a first showing of a ladder question.
            if (!item.review && !q.isRetry(i)) cursorMoves++
            if (!correct) { misses[item.name] = (misses[item.name] ?: 0) + 1; q.requeue(i) }
            i++
        }
        return shown to cursorMoves
    }

    @Test
    fun allRightFirstTimeShowsEachQuestionOnce() {
        val (shown, _) = play(queue("a", "b", "c"))
        assertEquals(listOf("a", "b", "c"), shown)
    }

    @Test
    fun aWrongAnswerComesBackAtTheEnd() {
        val (shown, _) = play(queue("a", "b", "c"), firstTryWrong = setOf("a"))
        assertEquals(listOf("a", "b", "c", "a"), shown)
    }

    @Test
    fun theGateDoesNotEndUntilEveryQuestionIsRight() {
        val (shown, _) = play(queue("a", "b", "c"), wrongTimes = mapOf("b" to 3))
        assertEquals("b is shown 4 times: 3 wrong + 1 right", 4, shown.count { it == "b" })
        assertEquals("the last thing shown is the question finally got right", "b", shown.last())
    }

    @Test
    fun everythingWrongStillEndsOnceEverythingIsEventuallyRight() {
        val (shown, _) = play(queue("a", "b", "c"), firstTryWrong = setOf("a", "b", "c"))
        assertEquals(listOf("a", "b", "c", "a", "b", "c"), shown)
    }

    @Test
    fun retriesKeepTheOrderOfTheMisses() {
        val (shown, _) = play(queue("a", "b", "c", "d"), firstTryWrong = setOf("c", "a"))
        assertEquals(listOf("a", "b", "c", "d", "a", "c"), shown)
    }

    @Test
    fun aRetryIsRecognisedAndAFirstShowingIsNot() {
        val q = queue("a", "b")
        assertFalse(q.isRetry(0))
        q.requeue(0)
        assertEquals(3, q.size)
        assertTrue(q.isRetry(2))
        assertFalse("the original stays a first showing", q.isRetry(0))
        assertFalse(q.isRetry(1))
    }

    @Test
    fun aRetryOfARetryIsStillARetry() {
        val q = queue("a")
        q.requeue(0); q.requeue(1)
        assertEquals(3, q.size)
        assertTrue(q.isRetry(1))
        assertTrue(q.isRetry(2))
    }

    @Test
    fun theRetryIsANewObjectCarryingTheSameQuestion() {
        val q = queue("a")
        val original = q[0]!!
        q.requeue(0)
        val again = q[1]!!
        assertNotSame(original, again)
        assertEquals("a", again.name)
        assertSame(original, q[0])
    }

    /** The lesson cursor must move exactly once per ladder question, however many misses. */
    @Test
    fun cursorMovesOncePerLadderQuestionEvenWithRetries() {
        val (_, moves) = play(queue("a", "b", "c"), wrongTimes = mapOf("a" to 2, "c" to 1))
        assertEquals(3, moves)
    }

    @Test
    fun aReviewQuestionNeverMovesTheCursorEvenWhenRetried() {
        val (_, moves) = play(
            queue("r", "a", "b", review = setOf("r")),
            wrongTimes = mapOf("r" to 2),
        )
        assertEquals("only a and b move the cursor", 2, moves)
    }

    @Test
    fun retryOfAReviewQuestionStaysAReview() {
        val q = queue("r", "a", review = setOf("r"))
        q.requeue(0)
        assertTrue("retry keeps the review flag, so it will not move the cursor", q[2]!!.review)
    }

    @Test
    fun outOfRangeIsNullNotACrash() {
        val q = queue("a")
        assertNull(q[5])
        assertNull(q[-1])
        assertFalse(q.isRetry(5))
    }

    @Test
    fun emptySessionIsEmpty() {
        val q = queue()
        assertEquals(0, q.size)
        assertNull(q[0])
    }
}
