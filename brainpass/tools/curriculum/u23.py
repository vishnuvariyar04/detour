# -*- coding: utf-8 -*-
"""Unit 2.3 — Loops Inside Loops.

The one idea: the inner loop finishes completely every single time the outer
loop goes round once. Everything else in this unit is that sentence, checked
from a different angle.

Boards are 7x7 here. Nested loops move Nupo a long way, and the board edge must
never quietly rescue a wrong answer by clamping it onto the right square.
"""
from kit import (U, D, L, R, PICK, OPEN, g, q, rep, cell, opt, blk, num, yes,
                 order, ends, fails_at, step_count, shortest_steps, only_winner,
                 same_end, stars_collected, moves_made, rows, route)

# ---------------------------------------------------------------- 2.3.1
_a0 = g(7, 7, (0, 0), program=rep(2, rep(3, [U])))
_a3 = g(7, 7, (0, 0), program=rep(2, rep(2, [R])))
_a4 = g(7, 7, (0, 0), program=rep(3, rep(2, [R])))
# The flag sits at 4, not the top row: an overshooting loop must land
# somewhere visibly wrong rather than being clamped onto the flag.
_a2 = g(7, 7, (0, 0), goal=(0, 4))

S231 = [
 q("predict", "A loop inside a loop. Tap the square he ends on.",
   "Finish the whole inside loop, then go round the outside one again.",
   ends(_a0), visual=_a0),

 q("count", "How many moves does Nupo make in total? Tap the number.",
   "Three inside, and the whole lot happens twice.",
   moves_made(_a0), visual=_a0, kind="moves"),

 q("spot", "Tap the row that starts the INSIDE loop.",
   "The inside loop is the one drawn further in.",
   blk(1), visual=_a0, criterion="innerLoop"),

 q("choose", "Tap the one that moves Nupo four squares up.",
   "Multiply the outside count by the inside count.",
   only_winner(_a2, [rep(2, rep(2, [U])), rep(2, rep(3, [U])),
                     rep(3, rep(3, [U]))]),
   visual=_a2, options=[rep(2, rep(2, [U])), rep(2, rep(3, [U])),
                        rep(3, rep(3, [U]))]),

 q("predict", "Tap the square this nested loop ends on.",
   "Two across each time the inside loop runs, and three goes of that.",
   ends(_a4), visual=_a4),

 q("compare", "A nested loop beside a plain one. Do they end on the same "
              "square? Tap your answer.",
   "Count the total moves each one makes.",
   same_end(g(7, 7, (0, 0)), rep(2, rep(3, [U])), rep(6, [U])),
   visual=g(7, 7, (0, 0)), options=[rep(2, rep(3, [U])), rep(6, [U])]),

 q("count", "How many times does the OUTSIDE loop go round? Tap the number.",
   "Read the number on the outer DO row.",
   num(2), visual=_a3, kind="stated"),
]

# ---------------------------------------------------------------- 2.3.2
# Outer times inner. That is the whole trick.
_b0 = g(7, 7, (0, 0), program=rep(3, rep(4, [U])))
_b1 = g(7, 7, (0, 0), program=rep(4, rep(2, [U, R])))
_b3 = g(7, 7, (0, 0), goal=(0, 6), program=["repeat:3", "repeat:?", U, "end", "end"])
_b5 = g(7, 7, (0, 0), program=rep(2, rep(3, [U])))
_b2 = g(7, 7, (0, 0), goal=(3, 3))

S232 = [
 q("count", "How many times does the UP row run altogether? Tap the number.",
   "Three lots of four.",
   num(12), visual=_b0, kind="stated"),

 q("count", "How many moves does this one make? Tap the number.",
   "Two moves inside, twice, and all of that four times.",
   moves_made(_b1), visual=_b1, kind="moves"),

 q("choose", "Tap the one that makes exactly six moves.",
   "Multiply the two counts, then multiply by the steps inside.",
   only_winner(g(7, 7, (0, 0), goal=(0, 6)),
               [rep(2, rep(3, [U])), rep(2, rep(2, [U])), rep(1, rep(5, [U]))]),
   visual=g(7, 7, (0, 0), goal=(0, 6)),
   options=[rep(2, rep(3, [U])), rep(2, rep(2, [U])), rep(1, rep(5, [U]))]),

 q("complete", "Tap the inside count that gets Nupo to the flag.",
   "The flag is six up, and the outside loop runs three times.",
   opt(0), visual=_b3, optionsText=["2", "3", "4"]),

 q("compare", "These two nested loops have their counts swapped. Do they "
              "end on the same square? Tap your answer.",
   "Both make the same number of moves in total.",
   same_end(g(7, 7, (0, 0)), rep(2, rep(3, [U])), rep(3, rep(2, [U]))),
   visual=g(7, 7, (0, 0)),
   options=[rep(2, rep(3, [U])), rep(3, rep(2, [U]))]),

 q("predict", "Outside 2, inside 3, UP inside. Tap where he ends.",
   "Six ups altogether.",
   ends(_b5), visual=_b5),

 q("choose", "Tap the one that lands exactly on the flag.",
   "The flag is three up and three across.",
   only_winner(_b2, [rep(3, [R, U]), rep(2, rep(2, [R, U])), rep(4, [R, U])]),
   visual=_b2, options=[rep(3, [R, U]), rep(2, rep(2, [R, U])), rep(4, [R, U])]),
]

# ---------------------------------------------------------------- 2.3.3
# Nesting shines when a pattern sits inside another pattern.
_c0 = g(7, 7, (0, 0), goal=(0, 4))
_c1 = g(7, 7, (0, 0), goal=(4, 0))
_c3 = g(7, 7, (0, 0), program=rep(2, rep(2, [R])))
_c4 = g(7, 7, (0, 0), goal=(0, 6))
_c5 = g(7, 7, (0, 0), program=rep(3, rep(2, [U])))

S233 = [
 q("choose", "Tap the one that reaches the flag four squares up.",
   "Two lots of two makes four.",
   only_winner(_c0, [rep(2, rep(2, [U])), rep(2, rep(3, [U])),
                     rep(3, rep(2, [U]))]),
   visual=_c0, options=[rep(2, rep(2, [U])), rep(2, rep(3, [U])),
                        rep(3, rep(2, [U]))]),

 q("choose", "Now the flag is four squares across. Tap it.",
   "Same idea, but the step inside has changed.",
   only_winner(_c1, [rep(2, rep(2, [R])), rep(2, rep(2, [U])),
                     rep(3, rep(2, [R]))]),
   visual=_c1, options=[rep(2, rep(2, [R])), rep(2, rep(2, [U])),
                        rep(3, rep(2, [R]))]),

 q("count", "How many rows does this nested loop use? Tap the number.",
   "Count every row, both DO rows and both END rows.",
   rows(_c3), visual=_c3, kind="rows"),

 q("compare", "Could a plain loop replace this nested one? Do they end on the "
              "same square? Tap your answer.",
   "Count the moves each one makes.",
   same_end(g(7, 7, (0, 0)), rep(2, rep(2, [R])), rep(4, [R])),
   visual=g(7, 7, (0, 0)), options=[rep(2, rep(2, [R])), rep(4, [R])]),

 q("predict", "The inside loop goes up twice. Tap the square this one "
              "ends on.",
   "Two ups inside, three times over.",
   ends(_c5), visual=_c5),

 q("count", "How many moves does that make? Tap the number.",
   "Two inside, three times over.",
   moves_made(_c5), visual=_c5, kind="moves"),

 q("choose", "Tap the one that reaches the flag six squares up.",
   "Look for the two counts that multiply to six.",
   only_winner(_c4, [rep(2, rep(3, [U])), rep(2, rep(2, [U])),
                     rep(3, rep(1, [U]))]),
   visual=_c4, options=[rep(2, rep(3, [U])), rep(2, rep(2, [U])),
                        rep(3, rep(1, [U]))]),
]

# ---------------------------------------------------------------- 2.3.4  BOSS
_d0 = g(7, 7, (0, 0), program=rep(3, rep(2, [R, U])))
_d1 = g(7, 7, (0, 0), program=rep(2, rep(3, [R])))
_d3 = g(7, 7, (0, 0), goal=(0, 6), program=["repeat:2", "repeat:?", U, "end", "end"])
_d4 = g(7, 7, (0, 0), goal=(4, 4))
_d5 = g(7, 7, (0, 0), goal=(0, 4), stars=[(0, 2), (0, 4)])

S234 = [
 q("predict", "Trace the nested loop. Tap the square he ends on.",
   "Two moves inside, twice, and all of that three times.",
   ends(_d0), visual=_d0),

 q("count", "How many moves was that? Tap the number.",
   "Multiply the counts, then multiply by the steps inside.",
   moves_made(_d0), visual=_d0, kind="moves"),

 q("count", "How many moves does this nested loop make? Tap the number.",
   "Three inside, twice over.",
   moves_made(_d1), visual=_d1, kind="moves"),

 q("complete", "The inside count is missing. Tap the one that reaches the "
               "flag.",
   "Six up in total, and the outside loop runs twice.",
   opt(1), visual=_d3, optionsText=["2", "3", "4"]),

 q("choose", "Tap the loop that stops exactly on this flag.",
   "The flag is four up and four across.",
   only_winner(_d4, [rep(2, rep(2, [R, U])), rep(3, rep(2, [R, U])),
                     rep(2, rep(3, [R, U]))]),
   visual=_d4, options=[rep(2, rep(2, [R, U])), rep(3, rep(2, [R, U])),
                        rep(2, rep(3, [R, U]))]),

 q("choose", "Tap the one that collects every star and stops on the flag.",
   "The stars sit on the way up. Count how far the flag is.",
   only_winner(_d5, [rep(2, rep(2, [U])), rep(2, rep(3, [U])),
                     rep(3, rep(2, [U]))]),
   visual=_d5, options=[rep(2, rep(2, [U])), rep(2, rep(3, [U])),
                        rep(3, rep(2, [U]))]),
]
