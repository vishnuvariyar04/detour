package com.brainpass.brainpass

import java.util.Collections
import java.util.IdentityHashMap

/**
 * The questions a gate walks through, in order, where a wrong answer sends the
 * SAME question back to the END of the queue.
 *
 * A child has to get every question right to finish: the gate only ends when
 * the queue runs out, and each miss puts one more entry on the back. The queue
 * is never reordered or shortened, so [index] positions stay valid and a retry
 * always comes after everything the child has not yet seen.
 *
 * Pure Kotlin (no Android types) so it can be unit-tested on the JVM.
 *
 * @param retryOf builds the entry that stands for "this question again". It
 *   must return a NEW object: retries are recognised by identity, so the caller
 *   can tell a first showing from a repeat (a repeat must not move the lesson
 *   cursor a second time).
 */
class GateQueue<T : Any>(initial: List<T>, private val retryOf: (T) -> T) {
    private val list = initial.toMutableList()
    private val retries: MutableSet<T> = Collections.newSetFromMap(IdentityHashMap())

    val size: Int get() = list.size

    operator fun get(index: Int): T? = list.getOrNull(index)

    /** True if the entry at [index] is a repeat of a question answered wrongly. */
    fun isRetry(index: Int): Boolean = list.getOrNull(index)?.let { it in retries } ?: false

    /** The entry at [index] was answered wrongly: bring it back after all the others. */
    fun requeue(index: Int) {
        val again = retryOf(list[index])
        retries.add(again)
        list.add(again)
    }
}
