# -*- coding: utf-8 -*-
"""Unit 1.3 — Reading and Writing Programs.

Three skills, in order: run a list in your head, turn a route you can see into a
list, and then pick the shortest list that still works. The last one is where
"correct" stops being the only bar.
"""
from kit import (U, D, L, R, PICK, OPEN, g, q, cell, opt, blk, num, yes, order,
                 ends, ends_at, fails_at, step_count, shortest_steps,
                 only_winner, same_end, stars_collected, route)

# ---------------------------------------------------------------- 1.3.1
# Trace it in your head before you press go.
_a0 = g(5, 5, (0, 0), program=[U, R, U, R, U])
_a1 = g(5, 5, (1, 0), program=[U, U, L, U, U, R])
_a2 = g(5, 5, (0, 0), program=[R, R, U, U])
_a3 = g(5, 5, (0, 0), stars=[(1, 0), (1, 2)], program=[R, U, U, R])
_a5 = g(5, 5, (0, 0), program=[U, R, U])
_a6 = g(5, 5, (0, 0), goal=(3, 1), walls=[(2, 1)], program=[U, R, R, R])

S131 = [
 q("predict", "Do not run it. Tap the square Nupo ends on.",
   "Move your finger one square per step, from the top of the list.",
   ends(_a0), visual=_a0),

 q("predict", "A longer list. Tap the square he ends on.",
   "Take it slowly. Six steps, one at a time.",
   ends(_a1), visual=_a1),

 q("predict", "Tap the square this list ends on.",
   "Two across, then two up.",
   ends(_a2), visual=_a2),

 q("count", "How many stars does Nupo collect? Tap the number.",
   "He only gets a star if he walks onto its square.",
   stars_collected(_a3), visual=_a3, kind="stars"),

 q("compare", "Same four steps, swapped around. Do they end on the same "
              "square? Tap your answer.",
   "Trace both from the same square and compare only the end.",
   same_end(g(5, 5, (0, 0)), [U, R, U, R], [R, U, R, U]),
   visual=g(5, 5, (0, 0)), options=[[U, R, U, R], [R, U, R, U]]),

 q("predict", "Stop after three steps. Tap the square he is on.",
   "Only do the three steps you can see.",
   ends(_a5), visual=_a5),

 q("debug", "You expected the flag. Tap the step that ruins it.",
   "One step runs straight into the wall.",
   fails_at(_a6), visual=_a6),
]

# ---------------------------------------------------------------- 1.3.2
# See the route, write the list.
_b0 = g(5, 5, (0, 0), program=[U, R, R])
_b1 = g(5, 5, (0, 0), program=[R, U, U, R, D])
_b2 = g(5, 5, (0, 0), goal=(2, 1), walls=[(1, 1)])
_b3 = g(5, 5, (0, 0), goal=(2, 1), program=[R, "?", U])
_b4 = g(5, 5, (0, 0), goal=(2, 2), stars=[(1, 0), (2, 1)])
_b5 = g(5, 5, (0, 0), program=[U, U, R])
_b6 = g(5, 5, (0, 0), program=[R, U, R, U])

S132 = [
 q("inverse", "The dots show a three step walk. Put the steps in that order.",
   "Start at Nupo and follow the dots one square at a time.",
   order([U, R, R]), visual=_b0, blocks=[R, U, R], slots=3),

 q("inverse", "A longer path. Put the steps in that order.",
   "Follow the dots to the very end. Watch for the step back down.",
   order([R, U, U, R, D]), visual=_b1,
   blocks=[U, R, D, R, U], slots=5),

 q("choose", "Tap the list that draws this path to the flag.",
   "Trace each one. The wall stops two of them.",
   only_winner(_b2, [[U, R, R], [R, R, U], [R, U, U]]),
   visual=_b2, options=[[U, R, R], [R, R, U], [R, U, U]]),

 q("complete", "This list matches the path except one gap. Tap the step that "
               "fills it.",
   "Look at the square before the gap and the one after it.",
   opt(0), visual=_b3, optionsText=["RIGHT", "DOWN", "LEFT"]),

 q("fix", "Build a list that gets both stars and then the flag.",
   "Both stars sit on the way. Go across, up, across, up.",
   route(_b4, [R, U, R, U]), visual=_b4, blocks=[U, R, U, R], slots=4),

 q("compare", "Do the two lists leave Nupo on the same square? Tap your "
              "answer.",
   "Same steps in a different order do not always mean the same path.",
   same_end(g(5, 5, (0, 0)), [U, U, R], [R, U, U]),
   visual=g(5, 5, (0, 0)), options=[[U, U, R], [R, U, U]]),

 q("count", "How many steps are in this path? Tap the number.",
   "Count the steps in the list.",
   step_count(_b6), visual=_b6, kind="steps"),
]

# ---------------------------------------------------------------- 1.3.3
# Many lists work. The best one is shortest.
_c0 = g(5, 5, (0, 0), goal=(2, 1))
_c1 = g(5, 5, (0, 0), goal=(3, 3))
_c2 = g(5, 5, (0, 0), goal=(2, 3))
_c3 = g(5, 5, (0, 0), goal=(3, 1), stars=[(2, 0)])
_c4 = g(5, 5, (0, 0), goal=(2, 0), walls=[(1, 0)])
_c5 = g(5, 5, (0, 0), goal=(2, 2), stars=[(1, 1)])
_c6 = g(5, 5, (0, 0), goal=(4, 0), walls=[(2, 0)])

S133 = [
 q("choose", "Both reach the flag. Tap the one that is shorter.",
   "Count the steps in each list.",
   opt(1), visual=_c0, options=[[U, R, D, U, R], [R, R, U]],
   criterion="shortest"),

 q("count", "What is the fewest steps to the flag? Tap the number.",
   "Count the squares across, then up. Add them together.",
   shortest_steps(_c1), visual=_c1, kind="shortest"),

 q("constrain", "Reach the flag in exactly 5 steps. Drag the steps into order.",
   "Two across and three up makes five.",
   route(_c2, [R, R, U, U, U]), visual=_c2,
   blocks=[U, D, L, R], slots=5, reusable=True),

 q("fix", "Get the star and then the flag, with none wasted. Drag the steps "
          "into order.",
   "The star is on the bottom row, on the way across.",
   route(_c3, [R, R, R, U]), visual=_c3, blocks=[R, U, R, R], slots=4),

 q("count", "The wall is in the way. How many steps now? Tap the number.",
   "Going round the wall costs extra steps.",
   shortest_steps(_c4), visual=_c4, kind="shortest"),

 q("choose", "Tap the one that gets the star AND is shortest.",
   "One misses the star. One gets it the long way round.",
   opt(0), visual=_c5,
   options=[[R, U, R, U], [R, R, U, U], [U, R, D, R, U, U]],
   criterion="shortest"),

 q("count", "What is the fewest steps past this wall to the flag? Tap the "
            "number.",
   "He has to step around the wall and come back down.",
   shortest_steps(_c6), visual=_c6, kind="shortest"),
]

# ---------------------------------------------------------------- 1.3.4  BOSS
_d0 = g(5, 5, (0, 0), program=[R, U, R, U, R])
_d1 = g(5, 5, (0, 0), goal=(3, 2))
_d2 = g(5, 5, (0, 0), goal=(2, 2), walls=[(1, 2)], program=[U, U, R, R])
_d3 = g(5, 5, (0, 0), program=[R, R, U, U, R, U])
_d4 = g(5, 5, (0, 0), goal=(3, 2), stars=[(1, 0), (2, 1), (3, 1)])
_d5 = g(5, 5, (0, 0), goal=(2, 2), stars=[(1, 1)])

S134 = [
 q("inverse", "The dots show the path. Put the steps in that order.",
   "Follow the dots from Nupo. Say each move as you go.",
   order([R, U, R, U, R]), visual=_d0,
   blocks=[U, R, R, U, R], slots=5),

 q("constrain", "Reach this flag in exactly 5 steps. Drag the steps into "
                "order.",
   "Three across and two up.",
   route(_d1, [R, R, R, U, U]), visual=_d1,
   blocks=[U, D, L, R], slots=5, reusable=True),

 q("debug", "Tap the step that breaks this list.",
   "One step walks straight into the wall.",
   fails_at(_d2), visual=_d2),

 q("predict", "Trace it. Tap the square Nupo ends on.",
   "Six steps. Take them one at a time.",
   ends(_d3), visual=_d3),

 q("count", "What is the fewest steps that gets all three stars and the flag? "
            "Tap the number.",
   "Every star sits on the way. None needs a detour.",
   num(5), visual=_d4, kind="stated"),

 q("choose", "Tap the one that is correct, shortest, and gets the star.",
   "Check the star first, then count the steps.",
   opt(1), visual=_d5,
   options=[[R, R, U, U], [R, U, R, U], [U, R, U, R, D, U]],
   criterion="shortest"),
]
