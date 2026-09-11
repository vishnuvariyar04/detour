# -*- coding: utf-8 -*-
"""Unit 1.2 — Being Precise.

The idea a child leaves with: the computer does exactly what you wrote, so a
wrong step, a missing step or a wasted step all cost you. Walls are the teacher
here, because a wall turns a sloppy list into a visibly wrong one.
"""
from kit import (U, D, L, R, PICK, OPEN, g, q, cell, opt, blk, num, yes, order,
                 ends, ends_at, fails_at, step_count, shortest_steps,
                 only_winner, same_end, route)

# ---------------------------------------------------------------- 1.2.1
# Nupo does not walk round things. He bumps and carries on.
_b0 = g(5, 5, (0, 0), walls=[(1, 0)], program=[R, R, U])
_b2 = g(5, 5, (0, 0), walls=[(2, 1)], program=[U, R, R, U])
_b5 = g(5, 5, (0, 0), goal=(3, 0), walls=[(2, 0)], program=[R, R, R, R])
_b6 = g(5, 5, (0, 0), goal=(3, 1), program=[R, R, R, U])
_b1 = g(5, 5, (0, 0), goal=(2, 0), walls=[(1, 0)])
_b3 = g(5, 5, (0, 0), goal=(3, 0), walls=[(2, 0)])

S121 = [
 q("predict", "A wall is in the way. Tap the square Nupo ends on.",
   "A wall stops that step. Nupo stays put and does the next one.",
   ends(_b0), visual=_b0),

 q("chooseText", "Nupo walks into a wall. Tap what he does.",
   "He is not clever enough to go round on his own.",
   opt(1), visual=g(5, 5, (0, 0), walls=[(1, 0)], program=[R, U]),
   optionsText=["He walks round it",
                "He stays put and does the next step",
                "He goes back to the start"]),

 q("debug", "Tap the step that walks into the wall.",
   "Go one step at a time until Nupo bumps.",
   fails_at(_b2), visual=_b2),

 q("choose", "Tap the list that gets round the wall to the flag.",
   "Nupo has to go round the wall, not through it.",
   only_winner(_b1, [[R, R], [U, R, R, D], [R, U, R, D]]),
   visual=_b1, options=[[R, R], [U, R, R, D], [R, U, R, D]]),

 q("fix", "Put the steps in order to get round the wall.",
   "Go up first, then across, then back down.",
   route(_b3, [R, U, R, R, D]), visual=_b3,
   blocks=[R, U, R, R, D], slots=5),

 q("debug", "Nupo stopped too early. Tap the step that went wrong.",
   "One step tried to walk into the wall.",
   fails_at(_b5), visual=_b5),

 q("predict", "No wall this time. Tap the square Nupo ends on.",
   "Nothing is in the way, so every step works.",
   ends(_b6), visual=_b6),
]

# ---------------------------------------------------------------- 1.2.2
# Leave a step out and he lands short.
_c0 = g(5, 5, (0, 0), goal=(2, 1), program=[R, R, "?"])
_c1 = g(5, 5, (0, 0), goal=(2, 2), program=[U, U, R])
_c3 = g(5, 5, (0, 0), goal=(2, 2), program=[U, "?", U, R])
_c5 = g(5, 5, (0, 0), goal=(1, 3), program=[U, U, R])
_c6 = g(5, 5, (0, 0), goal=(2, 2), stars=[(1, 1)])

S122 = [
 q("complete", "One step is missing. Tap the one that reaches the flag.",
   "Nupo is already across. He just needs to go up.",
   opt(0), visual=_c0, optionsText=["UP", "DOWN", "LEFT"]),

 q("predict", "This list is one step short. Tap the square he ends on.",
   "Just do the steps that are there. Do not add one.",
   ends(_c1), visual=_c1),

 q("count", "How many more steps does Nupo need to reach the flag? Tap the "
            "number.",
   "Count the squares between his last square and the flag.",
   num(1), visual=_c1, kind="stated"),

 q("complete", "One step is missing from the middle. Tap the step that fills "
               "the gap.",
   "Work out where he must end up, then fill the middle.",
   opt(1), visual=_c3, optionsText=["DOWN", "UP", "LEFT"]),

 q("choose", "Tap the list that stops on the star.",
   "Check where each one ends. Only one lands on the star.",
   only_winner(g(5, 5, (0, 0), stars=[(1, 2)]),
               [[U, U, R], [R, R, U], [U, R, R]]),
   visual=g(5, 5, (0, 0), stars=[(1, 2)]),
   options=[[U, U, R], [R, R, U], [U, R, R]]),

 q("predict", "He stops one square short of the flag. Tap where he stops.",
   "Do every step in the list and stop there.",
   ends(_c5), visual=_c5),

 q("fix", "Put the steps in order. Cross the star on the way to the flag.",
   "The star is on the way. Go through it, not round it.",
   route(_c6, [U, R, U, R]), visual=_c6, blocks=[R, U, U, R], slots=4),
]

# ---------------------------------------------------------------- 1.2.3
# Steps that undo each other still cost you.
_d0 = g(5, 5, (0, 0), program=[U, D, R, R])
_d3 = g(5, 5, (0, 0), goal=(2, 1), stars=[(1, 1)])
_d4 = g(5, 5, (0, 0), goal=(3, 2), walls=[(1, 1)])
_d6 = g(5, 5, (0, 0), goal=(2, 2))

S123 = [
 q("spot", "Tap the step that cancels out the one before it.",
   "One step goes up. The next one takes it straight back.",
   blk(1), visual=_d0, criterion="undo"),

 q("count", "How many steps here are wasted? Tap the number.",
   "A step up and a step back down get you nowhere.",
   num(2), visual=_d0, kind="stated"),

 q("predict", "Two of these steps cancel out. Tap the square he ends on.",
   "Do them all anyway. He still ends up somewhere.",
   ends(_d0), visual=_d0),

 q("choose", "Both of these reach the flag. Tap the one that is shorter.",
   "Count the steps in each list. Fewer is better.",
   opt(0), visual=g(5, 5, (0, 0), goal=(2, 0)),
   options=[[R, R], [R, U, D, R]], criterion="shortest"),

 q("fix", "Get the star and then the flag, with no wasted steps. Drag the "
          "steps into order.",
   "The star sits between Nupo and the flag. Go through it.",
   route(_d3, [R, U, R]), visual=_d3, blocks=[R, U, R], slots=3),

 q("count", "What is the fewest steps that reaches the flag? Tap the number.",
   "The wall is in the way. Count the shortest way round it.",
   shortest_steps(_d4), visual=_d4, kind="shortest"),

 q("constrain", "Reach the flag in exactly 4 steps. Drag the steps into order.",
   "The flag is two squares up and two across. Tap steps to fill the boxes.",
   route(_d6, [U, U, R, R]), visual=_d6,
   blocks=[U, D, L, R], slots=4, reusable=True),
]

# ---------------------------------------------------------------- 1.2.4  BOSS
_e0 = g(5, 5, (0, 0), goal=(3, 2), walls=[(2, 0)], program=[R, R, R, U, U])
_e1 = g(5, 5, (0, 0), goal=(2, 1), stars=[(1, 0)])
_e2 = g(5, 5, (0, 0), goal=(3, 0), walls=[(1, 1)])
_e3 = g(5, 5, (0, 0), goal=(2, 2), program=[U, "?", U, "?"])
_e4 = g(5, 5, (0, 0), goal=(3, 3), walls=[(1, 1), (2, 2)])
_e5 = g(5, 5, (0, 0), goal=(2, 1), stars=[(1, 0)])

S124 = [
 q("debug", "Tap the one step that breaks this list.",
   "Only one step tries to walk into the wall.",
   fails_at(_e0), visual=_e0),

 q("fix", "Get the star and then the flag. Drag the steps into order.",
   "The star is on the bottom row. Go along it first.",
   route(_e1, [R, R, U]), visual=_e1, blocks=[R, U, R], slots=3),

 q("constrain", "Reach the flag in exactly 3 steps. Drag the steps into order.",
   "The flag is three squares across and none up.",
   route(_e2, [R, R, R]), visual=_e2,
   blocks=[U, D, L, R], slots=3, reusable=True),

 q("complete", "Two steps are missing. Tap the one that fills the FIRST gap.",
   "Work out where he must end up. Then fill the first gap.",
   opt(0), visual=_e3, optionsText=["RIGHT", "DOWN", "LEFT"]),

 q("count", "Two walls stand in the way. What is the fewest steps to the flag? "
            "Tap the number.",
   "Two walls are in the way. Count the shortest way past them.",
   shortest_steps(_e4), visual=_e4, kind="shortest"),

 q("choose", "Tap the list that is correct AND shortest.",
   "Two of them get there. One does it with no wasted steps.",
   opt(1), visual=_e5,
   options=[[U, R, D, R, U], [R, R, U], [U, U, R, R]],
   criterion="shortest"),
]
