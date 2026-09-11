# -*- coding: utf-8 -*-
"""Unit 2.1 — Spotting Repetition.

Before a child can write a loop they have to SEE one: the same short burst of
steps happening again and again. Every question here is about noticing the
pattern, not yet about counting it precisely.

Vocabulary on screen: a loop row reads "DO 3 TIMES", closed by "END". The steps
between them are drawn indented, so "inside the loop" is visible rather than
explained.
"""
from kit import (U, D, L, R, PICK, OPEN, g, q, rep, cell, opt, blk, num, yes,
                 order, ends, fails_at, step_count, shortest_steps, only_winner,
                 same_end, stars_collected, moves_made, rows, route)

# ---------------------------------------------------------------- 2.1.1
_a0 = g(5, 5, (0, 0), program=[R, U, R, U, R, U])
_a4 = g(5, 5, (0, 0), program=[R, U, R, U, R, U, L])
_a5 = g(5, 5, (0, 0), program=rep(3, [R, U]))
_a2 = g(5, 5, (0, 0), goal=(3, 3))

S211 = [
 q("spot", "The same two steps keep coming back. Tap where the FIRST pair starts.",
   "Look for the pair that happens again and again.",
   blk(0), visual=_a0, criterion="chunk:2"),

 q("count", "How many times does that pair of steps happen? Tap the number.",
   "Count how many RIGHT and UP pairs you can see.",
   num(3), visual=_a0, kind="stated"),

 q("choose", "Tap the loop that does the same job as the long list.",
   "The long list makes six moves. Count what each loop makes.",
   only_winner(_a2, [rep(3, [R, U]), rep(2, [R, U]), rep(4, [R, U])]),
   visual=_a2, options=[rep(3, [R, U]), rep(2, [R, U]), rep(4, [R, U])]),

 q("compare", "Do the long list and the loop end on the same square? Tap your "
              "answer.",
   "Run them both. A loop is just a shorter way to say the same thing.",
   same_end(g(5, 5, (0, 0)), [R, U, R, U, R, U], rep(3, [R, U])),
   visual=g(5, 5, (0, 0)), options=[[R, U, R, U, R, U], rep(3, [R, U])]),

 q("spot", "Tap the first step that is NOT part of the repeat.",
   "The pattern is RIGHT then UP. Find where that stops.",
   blk(6), visual=_a4, criterion="afterChunk:2"),

 q("count", "How many moves does this loop make in total? Tap the number.",
   "Two steps inside, done three times.",
   moves_made(_a5), visual=_a5, kind="moves"),

 q("predict", "Tap the square this loop ends on.",
   "Do the steps inside. Then go back up and do them again.",
   ends(_a5), visual=_a5),
]

# ---------------------------------------------------------------- 2.1.2
# A loop needs a start and an end, and the END line decides what repeats.
_b0 = g(5, 5, (0, 0), program=rep(3, [U, R]))
_b2 = g(5, 5, (0, 0), program=["repeat:2", U, R, "end", R])
_b5 = g(5, 5, (0, 0), goal=(2, 2), walls=[(1, 2)], program=rep(3, [U, R]))
_b1 = g(5, 5, (0, 0), goal=(2, 2))

S212 = [
 q("spot", "Tap the last step INSIDE the loop.",
   "The steps inside sit further in than the DO and END lines.",
   blk(2), visual=_b0, criterion="lastInLoop"),

 q("choose", "Tap the loop that reaches the flag.",
   "Two up and two across. Count what each loop actually makes.",
   only_winner(_b1, [rep(2, [U, R]), rep(3, [U, R]), rep(1, [U, R])]),
   visual=_b1, options=[rep(2, [U, R]), rep(3, [U, R]), rep(1, [U, R])]),

 q("predict", "One step sits outside the loop. Tap the square he ends on.",
   "Finish the loop first. Then do the step below END.",
   ends(_b2), visual=_b2),

 q("count", "How many rows does this listing have? Tap the number.",
   "Count every row, including the DO line and the END line.",
   rows(_b0), visual=_b0, kind="rows"),

 q("count", "How many moves does Nupo make? Tap the number.",
   "Two steps inside, three times round.",
   moves_made(_b0), visual=_b0, kind="moves"),

 q("compare", "One step has been moved outside the loop. Do the two still end "
              "on the same square? Tap your answer.",
   "One list repeats both steps. The other repeats only the first.",
   same_end(g(5, 5, (0, 0)), rep(2, [U, R]), ["repeat:2", U, "end", R]),
   visual=g(5, 5, (0, 0)),
   options=[rep(2, [U, R]), ["repeat:2", U, "end", R]]),

 q("debug", "A wall stops this loop. Tap the step that hits it.",
   "Go round the loop until Nupo bumps into something.",
   fails_at(_b5), visual=_b5),
]

# ---------------------------------------------------------------- 2.1.3
# The same job, far fewer rows.
_c0 = g(5, 5, (0, 0), program=[U, U, U, U])
_c1 = g(5, 5, (0, 0), program=rep(4, [U]))
_c3 = g(5, 5, (0, 0), goal=(0, 4))
_c5 = g(5, 5, (0, 0), goal=(3, 3))
_c6 = g(5, 5, (0, 0), program=rep(2, [R, U]))

S213 = [
 q("count", "How many rows does this long list use? Tap the number.",
   "Count the rows one by one.",
   rows(_c0), visual=_c0, kind="rows"),

 q("count", "The loop does the same job. How many rows does it use? Tap the "
            "number.",
   "Count the DO row, the step inside, and the END row.",
   rows(_c1), visual=_c1, kind="rows"),

 q("compare", "The loop uses far fewer rows. Do the two end on the same "
              "square? Tap your answer.",
   "Run both. If they end in the same place, both are correct.",
   same_end(g(5, 5, (0, 0)), [U, U, U, U], rep(4, [U])),
   visual=g(5, 5, (0, 0)), options=[[U, U, U, U], rep(4, [U])]),

 q("choose", "Tap the one that reaches the flag with the fewest rows.",
   "They all get there. Count the rows in each.",
   opt(1), visual=_c3,
   options=[[U, U, U, U], rep(4, [U]), [U, U, U, U, D, U]],
   criterion="shortest"),

 q("predict", "This loop goes round twice. Tap the square it ends on.",
   "Two steps inside, twice round.",
   ends(_c6), visual=_c6),

 q("choose", "Tap the loop that reaches this flag.",
   "The flag is three up and three across.",
   only_winner(_c5, [rep(3, [R, U]), rep(2, [R, U]), rep(3, [U, U])]),
   visual=_c5, options=[rep(3, [R, U]), rep(2, [R, U]), rep(3, [U, U])]),

 q("count", "How many moves does this loop make? Tap the number.",
   "One step inside, four times round.",
   moves_made(_c1), visual=_c1, kind="moves"),
]

# ---------------------------------------------------------------- 2.1.4  BOSS
_d0 = g(5, 5, (0, 0), program=[R, U, R, U, R, U, R, U])
# 6x6: on a 5x5 the board edge clamps repeat-5 onto the same square as
# repeat-4, so a child picking the wrong count would still SEE Nupo on the
# flag and be told they were wrong.
_d1 = g(6, 6, (0, 0), goal=(4, 4))
_d2 = g(5, 5, (0, 0), program=rep(4, [R, U]))
_d4 = g(5, 5, (0, 0), goal=(0, 3), stars=[(0, 1), (0, 2)])
_d5 = g(5, 5, (0, 0), goal=(2, 2), walls=[(1, 0)])

S214 = [
 q("spot", "Tap the FIRST step of the repeating pattern.",
   "The same two steps run over and over from the very top.",
   blk(0), visual=_d0, criterion="chunk:2"),

 q("count", "How many times does that pattern repeat? Tap the number.",
   "Count the RIGHT and UP pairs.",
   num(4), visual=_d0, kind="stated"),

 q("choose", "Tap the loop that does the same as that long list.",
   "The long list makes eight moves.",
   only_winner(_d1, [rep(3, [R, U]), rep(4, [R, U]), rep(5, [R, U])]),
   visual=_d1, options=[rep(3, [R, U]), rep(4, [R, U]), rep(5, [R, U])]),

 q("predict", "This loop goes round four times. Tap the square it ends on.",
   "Across then up, and four goes of it.",
   ends(_d2), visual=_d2),

 q("count", "How many moves does that loop make? Tap the number.",
   "Two inside, four times round.",
   moves_made(_d2), visual=_d2, kind="moves"),

 q("choose", "Tap the loop that gets both stars and the flag.",
   "The stars sit on the way up. Count how far the flag is.",
   only_winner(_d4, [rep(3, [U]), rep(2, [U]), rep(4, [U])]),
   visual=_d4, options=[rep(3, [U]), rep(2, [U]), rep(4, [U])]),
]
