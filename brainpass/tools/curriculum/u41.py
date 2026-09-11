# -*- coding: utf-8 -*-
"""Unit 4.1 — Finding Bugs.

The habit: say what you expect, run it, and look at the first place the two
disagree. Everything after a broken step looks broken too, so the only step
worth fixing is the earliest one.

Stop 4.1.2 is built on Code.org's Bee: Debugging, which hands a child a puzzle
that has ALREADY been solved wrongly and names the four things that can be
wrong with it — a step missing, a step too many, the steps in the wrong order,
or a loop counted wrong. Naming the four gives a child somewhere to start; the
first version of this stop asked them instead why only the first wrong step is
worth fixing, which is a question about debugging rather than an act of it.

Source: code.org/curriculum/course2/10/Teacher (Bee: Debugging).
"""
from kit import (U, D, L, R, PICK, OPEN, g, q, rep, cell, opt, blk, num, yes,
                 order, ends, fails_at, step_count, shortest_steps, only_winner,
                 same_end, stars_collected, moves_made, rows, route)

# ---------------------------------------------------------------- 4.1.1
_a0 = g(5, 5, (0, 0), goal=(3, 2), walls=[(2, 0)], program=[R, R, R, U, U])
_a1 = g(5, 5, (0, 0), goal=(2, 2), program=[R, R, U, U])
_a3 = g(5, 5, (0, 0), goal=(0, 3), walls=[(0, 2)], program=[U, U, U])
_a5 = g(5, 5, (0, 0), goal=(2, 1), walls=[(1, 1)])
_a6 = g(5, 5, (0, 0), goal=(3, 0), walls=[(2, 0)], program=[R, R, R])

S411 = [
 q("predict", "Before you run it: tap the square you think he ends on.",
   "Follow the steps in your head, wall and all.",
   ends(_a0), visual=_a0),

 q("debug", "Run it. Tap the step where it goes wrong.",
   "Walk it until Nupo bumps into something.",
   fails_at(_a0), visual=_a0),

 q("predict", "This one has no wall. Tap the square he ends on.",
   "Nothing is in the way, so every step works.",
   ends(_a1), visual=_a1),

 q("debug", "He stops short of the flag. Tap the step that fails.",
   "One step tries to walk through the wall.",
   fails_at(_a3), visual=_a3),

 q("choose", "One wall, one flag. Tap the list that gets there.",
   "He has to go under or over the wall, not through it.",
   only_winner(_a5, [[U, R, R, D], [R, R, U], [U, U, R, R, D, D]]),
   visual=_a5, options=[[U, R, R, D], [R, R, U], [U, U, R, R, D, D]]),

 q("count", "How many moves happen before the wall stops him? Tap the number.",
   "Count the steps that actually move him.",
   num(2), visual=_a6, kind="stated"),

 q("predict", "Tap the square he is stuck on.",
   "The blocked step does nothing, and the ones after it repeat the problem.",
   ends(_a6), visual=_a6),
]

# ---------------------------------------------------------------- 4.1.2
# Everything after the first bad step looks bad too.
_b0 = g(5, 5, (0, 0), goal=(2, 3), walls=[(1, 1)], program=[U, R, U, U])
_b2 = g(5, 5, (0, 0), goal=(2, 2), program=[R, R, U, U])
_b4 = g(5, 5, (0, 0), goal=(0, 4), walls=[(0, 3)], program=[U, U, U, U])
_b6 = g(5, 5, (0, 0), goal=(2, 2), walls=[(1, 2)])
# One board per bug kind, so each question shows the fault it names.
_b1 = g(5, 5, (0, 0), goal=(0, 3), program=[U, U])          # a step missing
_b1gap = g(5, 5, (0, 0), goal=(0, 3), program=[U, U, "?"])
_b3 = g(5, 5, (0, 0), goal=(0, 2), program=[U, U, U])       # a step too many
_b5 = g(6, 6, (0, 0), goal=(0, 3), program=["repeat:?", U, "end"])

S412 = [
 q("chooseText", "This list stops one square short of the flag. Tap what is "
                 "wrong with it.",
   "Count the squares to the flag, then count the steps.",
   opt(0), visual=_b1,
   optionsText=["A step is missing",
                "There is a step too many",
                "The steps are in the wrong order"]),

 q("complete", "Tap the step that fills the gap and lands him on the flag.",
   "Look at the square before the gap and the flag after it.",
   opt(0), visual=_b1gap, optionsText=["UP", "DOWN", "LEFT"]),

 q("chooseText", "This list goes one square past the flag. Tap what is "
                 "wrong with it.",
   "It does everything the flag needs, and then one thing more.",
   opt(1), visual=_b3,
   optionsText=["A step is missing",
                "There is a step too many",
                "The steps are in the wrong order"]),

 q("debug", "This list walks into a wall. Tap the first step that fails.",
   "Go from the top and stop at the first bump.",
   fails_at(_b4), visual=_b4),

 q("choose", "The same four steps, in three orders. Tap the one that "
             "reaches the flag.",
   "The wall sits directly above the middle square.",
   only_winner(_b6, [[R, R, U, U], [U, U, R, R], [R, U, U, R]]),
   visual=_b6, options=[[R, R, U, U], [U, U, R, R], [R, U, U, R]]),

 q("complete", "This loop counts wrong. Tap the count that lands him on the "
               "flag.",
   "Count the squares between Nupo and the flag.",
   opt(1), visual=_b5, optionsText=["2", "3", "4"]),

 q("count", "How many moves does the broken list actually make? Tap the "
            "number.",
   "Blocked steps still count as steps, but they move him nowhere.",
   moves_made(_b4), visual=_b4, kind="moves"),
]

# ---------------------------------------------------------------- 4.1.3
# Predict, then check.
_c0 = g(5, 5, (0, 0), program=[U, R, U, R])
_c1 = g(5, 5, (0, 0), goal=(2, 2), walls=[(1, 0)], program=[R, R, U, U])
_c3 = g(5, 5, (0, 0), goal=(2, 2), walls=[(1, 0)])
_c5 = g(5, 5, (0, 0), program=rep(2, [U, R]))

S413 = [
 q("predict", "Where do you think it ends? Tap that square.",
   "Trace it before you look at anything else.",
   ends(_c0), visual=_c0),

 q("predict", "Now this one, with a wall. Tap where he really ends.",
   "The wall changes the answer. Take it one step at a time.",
   ends(_c1), visual=_c1),

 q("debug", "Your guess and the run differ. Tap the step where.",
   "Find the first step that could not do what you expected.",
   fails_at(_c1), visual=_c1),

 q("choose", "Tap the list that gets to the flag with that wall there.",
   "He has to go up before he goes across.",
   only_winner(_c3, [[R, R, U, U], [U, R, R, U], [U, R, R, R]]),
   visual=_c3, options=[[R, R, U, U], [U, R, R, U], [U, R, R, R]]),

 q("predict", "After the fix, tap the square he ends on.",
   "This one has nothing in the way.",
   ends(_c5), visual=_c5),

 q("compare", "A long list beside a loop. Do they end on the same square? Tap "
              "your answer.",
   "Run both and compare only the last square.",
   same_end(g(5, 5, (0, 0)), [U, R, U, R], rep(2, [U, R])),
   visual=g(5, 5, (0, 0)), options=[[U, R, U, R], rep(2, [U, R])]),

 q("chooseText", "Your guess and the run disagree. Tap what that means.",
   "That is the whole point of guessing first.",
   opt(0), visual=_c0,
   optionsText=["A bug, or something you misread",
                "Nothing useful", "A broken board"]),
]

# ---------------------------------------------------------------- 4.1.4  BOSS
_d0 = g(5, 5, (0, 0), goal=(3, 3), walls=[(1, 0), (2, 2)], program=[R, R, R, U, U, U])
_d2 = g(5, 5, (0, 0), goal=(2, 2), stars=[(1, 1)])
_d3 = g(5, 5, (0, 0), goal=(0, 4), walls=[(0, 2)], program=rep(4, [U]))
_d5 = g(5, 5, (0, 0), goal=(3, 1), walls=[(2, 1)])

S414 = [
 q("debug", "Tap the first wrong step.",
   "Two things are in the way. Only one stops him first.",
   fails_at(_d0), visual=_d0),

 q("predict", "Tap the square that broken list leaves him on.",
   "Keep going after the bump. The later steps still try.",
   ends(_d0), visual=_d0),

 q("fix", "Put the steps in order to get the star and the flag.",
   "The star sits on the diagonal, so go up and across in turns.",
   route(_d2, [R, U, R, U]), visual=_d2, blocks=[U, R, U, R], slots=4),

 q("debug", "This loop hits a wall. Tap the step inside it that fails.",
   "The step inside runs four times, but one of those runs bumps.",
   fails_at(_d3), visual=_d3),

 q("count", "How many moves does the loop make in total? Tap the number.",
   "Blocked runs still count as moves.",
   moves_made(_d3), visual=_d3, kind="moves"),

 q("choose", "Tap the list that gets round this wall to the flag.",
   "Go along the bottom first, then up at the end.",
   only_winner(_d5, [[R, R, R, U], [U, R, R, R], [R, U, R, R]]),
   visual=_d5, options=[[R, R, R, U], [U, R, R, R], [R, U, R, R]]),
]
