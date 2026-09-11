# -*- coding: utf-8 -*-
"""Unit 2.2 — Loop Counts.

Getting the count right is where loops actually bite. Off by one is the most
common bug there is, and it is worth a whole stop of its own.

Boards here are deliberately roomy. On a small board the edge clamps an
overshooting loop onto the correct square, so a wrong count would still LOOK
right — which would teach exactly the wrong lesson.
"""
from kit import (U, D, L, R, PICK, OPEN, g, q, rep, cell, opt, blk, num, yes,
                 order, ends, fails_at, step_count, shortest_steps, only_winner,
                 same_end, stars_collected, moves_made, rows, route)

# ---------------------------------------------------------------- 2.2.1
_a0 = g(6, 6, (0, 0), program=rep(3, [U]))
_a1 = g(6, 6, (0, 0), program=rep(4, [U, R]))
_a4 = g(6, 6, (0, 0), program=rep(2, [U, U, R]))
_a2 = g(6, 6, (0, 0), goal=(0, 4))
_a3 = g(6, 6, (0, 0), goal=(0, 3), program=["repeat:?", U, "end"])

S221 = [
 q("predict", "DO 3 TIMES with UP inside. Tap the square he ends on.",
   "One step up, three times over.",
   ends(_a0), visual=_a0),

 q("count", "Two steps inside, four goes round. How many moves is that? Tap "
            "the number.",
   "Two steps inside, four times round.",
   moves_made(_a1), visual=_a1, kind="moves"),

 q("choose", "Tap the count that reaches the flag.",
   "The flag is four squares up.",
   only_winner(_a2, [rep(3, [U]), rep(4, [U]), rep(5, [U])]),
   visual=_a2, options=[rep(3, [U]), rep(4, [U]), rep(5, [U])]),

 q("complete", "The loop count is missing. Tap the count that reaches the "
               "flag.",
   "Count the squares from Nupo up to the flag.",
   opt(1), visual=_a3, optionsText=["2", "3", "4"]),

 q("predict", "Three steps inside, twice round. Tap where he ends.",
   "Up, up, across. Then up, up, across again.",
   ends(_a4), visual=_a4),

 q("compare", "Two loops, different counts, different steps inside. Do they "
              "end on the same square? Tap your answer.",
   "Count the total moves each one makes.",
   same_end(g(6, 6, (0, 0)), rep(2, [U, U]), rep(4, [U])),
   visual=g(6, 6, (0, 0)), options=[rep(2, [U, U]), rep(4, [U])]),

 q("count", "How many times do the steps inside run? Tap the number.",
   "The number on the DO row tells you.",
   num(4), visual=_a1, kind="stated"),
]

# ---------------------------------------------------------------- 2.2.2
# Off by one, the classic bug.
_b0 = g(6, 6, (0, 0), goal=(0, 3), program=rep(4, [U]))
_b2 = g(6, 6, (0, 0), goal=(0, 4), program=rep(5, [U]))
_b4 = g(6, 6, (0, 0), goal=(0, 4), program=rep(3, [U]))
_b1 = g(6, 6, (0, 0), goal=(0, 3))
_b5 = g(6, 6, (0, 0), goal=(0, 4))

S222 = [
 q("predict", "This loop goes one too far. Tap where Nupo ends.",
   "Do all four, even though the flag is only three up.",
   ends(_b0), visual=_b0),

 q("choose", "Change the count so he lands on the flag. Tap your answer.",
   "The flag is three squares up.",
   only_winner(_b1, [rep(2, [U]), rep(3, [U]), rep(4, [U])]),
   visual=_b1, options=[rep(2, [U]), rep(3, [U]), rep(4, [U])]),

 q("predict", "Five times round when four was needed. Tap where he stops.",
   "Do all five and see where that leaves him.",
   ends(_b2), visual=_b2),

 q("count", "What count reaches this flag? Tap the number.",
   "Count the squares from Nupo up to the flag.",
   num(4), visual=_b5, kind="stated"),

 q("predict", "This loop stops one short. Tap the square he stops on.",
   "Only three times round, so only three squares up.",
   ends(_b4), visual=_b4),

 q("chooseText", "Nupo lands one square past the flag. What went wrong? Tap "
                 "your answer.",
   "Think about the number on the DO row.",
   opt(0), visual=_b0,
   optionsText=["The count is one too big",
                "The count is one too small",
                "The steps inside are wrong"]),

 q("compare", "One loop goes round once more than the other. Do they end on "
              "the same square? Tap your answer.",
   "Try both counts and see where each one ends.",
   same_end(g(6, 6, (0, 0)), rep(3, [U]), rep(4, [U])),
   visual=g(6, 6, (0, 0)), options=[rep(3, [U]), rep(4, [U])]),
]

# ---------------------------------------------------------------- 2.2.3
# Work out the distance, then set the count.
_c0 = g(7, 7, (0, 0), goal=(0, 6), program=["repeat:?", U, "end"])
_c1 = g(7, 7, (0, 0), goal=(0, 6), program=["repeat:?", U, U, "end"])
_c2 = g(6, 6, (0, 0), goal=(3, 3))
_c3 = g(6, 6, (0, 0), goal=(0, 4), stars=[(0, 2), (0, 4)],
        program=["repeat:?", U, "end"])
_c4 = g(6, 6, (0, 0), program=rep(3, [U, R]))
_c5 = g(6, 6, (0, 0), goal=(0, 4))

S223 = [
 q("count", "The flag is 6 squares up. How many times must this loop go "
            "round? Tap the number.",
   "One square each time round.",
   num(6), visual=_c0, kind="stated"),

 q("count", "Now two UP steps sit inside the loop. How many goes round "
            "reach the same flag? Tap the number.",
   "Two squares each time round, so you need fewer turns.",
   num(3), visual=_c1, kind="stated"),

 q("choose", "Each go round moves one up and one across. Tap the loop that "
             "reaches the flag.",
   "Count the squares up, then the squares across.",
   only_winner(_c2, [rep(2, [U, R]), rep(3, [U, R]), rep(4, [U, R])]),
   visual=_c2, options=[rep(2, [U, R]), rep(3, [U, R]), rep(4, [U, R])]),

 q("complete", "Tap the count that gets Nupo both stars and the flag.",
   "The furthest star is also where the flag is.",
   opt(2), visual=_c3, optionsText=["2", "3", "4"]),

 q("count", "Count 3, and UP RIGHT inside. How many moves in total? Tap the "
            "number.",
   "Two moves each turn, three turns.",
   moves_made(_c4), visual=_c4, kind="moves"),

 q("predict", "Three goes round, up then across each time. Tap the square it "
              "ends on.",
   "Three turns of up-then-across.",
   ends(_c4), visual=_c4),

 q("choose", "Tap the loop that reaches the flag with the fewest turns.",
   "Bigger steps inside mean fewer turns.",
   only_winner(_c5, [rep(2, [U, U]), rep(3, [U]), rep(5, [U])]),
   visual=_c5, options=[rep(2, [U, U]), rep(3, [U]), rep(5, [U])]),
]

# ---------------------------------------------------------------- 2.2.4  BOSS
_d0 = g(6, 6, (0, 0), goal=(3, 0), program=["repeat:?", R, "end"])
_d1 = g(6, 6, (0, 0), goal=(0, 3), program=rep(5, [U]))
_d2 = g(6, 6, (0, 0), program=rep(4, [R, U]))
_d3 = g(6, 6, (0, 0), goal=(2, 2))
_d4 = g(6, 6, (0, 0), program=rep(3, [R, U]))
_d5 = g(6, 6, (0, 0), goal=(0, 4), stars=[(0, 2)])

S224 = [
 q("complete", "Tap the loop count that gets Nupo to the flag.",
   "Count the squares across to the flag.",
   opt(1), visual=_d0, optionsText=["2", "3", "4"]),

 q("predict", "This count is too big. Tap where Nupo actually ends.",
   "Do all five times round, past the flag.",
   ends(_d1), visual=_d1),

 q("count", "How many moves does this loop make altogether? Tap the number.",
   "Two inside, four turns.",
   moves_made(_d2), visual=_d2, kind="moves"),

 q("choose", "Tap the loop that lands exactly on the flag.",
   "The flag is two up and two across.",
   only_winner(_d3, [rep(2, [R, U]), rep(3, [R, U]), rep(4, [R, U])]),
   visual=_d3, options=[rep(2, [R, U]), rep(3, [R, U]), rep(4, [R, U])]),

 q("predict", "Tap the square this loop finishes on.",
   "Across then up, three turns.",
   ends(_d4), visual=_d4),

 q("choose", "Tap the loop that gets the star and stops on the flag.",
   "The star is on the way up. The flag is further.",
   only_winner(_d5, [rep(3, [U]), rep(4, [U]), rep(5, [U])]),
   visual=_d5, options=[rep(3, [U]), rep(4, [U]), rep(5, [U])]),
]
