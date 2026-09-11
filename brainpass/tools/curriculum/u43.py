# -*- coding: utf-8 -*-
"""Unit 4.3 — Breaking It Down.

The last unit, and the one that ties the skill together: a big level is small
levels stacked up, a chunk you keep repeating deserves a name, and a real
program uses sequences, loops, conditions and boxes all at once.

There is no CALL row in Nupo's language, so a chunk is taught as something a
child RECOGNISES and reuses rather than something they declare. That is the
honest version of the idea at this age, and it is how Code.org introduces
functions in Course F: solve the level without one, look at the code, find the
part that repeats, then ask why a loop will not do the job here.

That last question is the one that makes the idea land, and the first version
of 4.3.2 never asked it — its board was UP RIGHT three times in a row, which a
loop handles perfectly. The whole stop was section 2 again under a new name.
The board is now one where the repeats are separated by other steps, so a loop
genuinely cannot express it, and the stop finishes with the contrasting case
where a loop can.

Source: curriculum.code.org/csf-20/coursef lesson 1 (Functions in Minecraft).
"""
from kit import (U, D, L, R, PICK, OPEN, g, q, rep, cell, opt, blk, num, yes,
                 order, ends, fails_at, step_count, shortest_steps, only_winner,
                 same_end, stars_collected, moves_made, rows, route, setv, addv,
                 box_value, trace_q)

C = "COINS"


def iff(cond, body, other=None):
    out = ["if:%s" % cond] + list(body)
    if other:
        out += ["else"] + list(other)
    return out + ["end"]


# ---------------------------------------------------------------- 4.3.1
# One big level, three small parts: key, door, flag.
_a0 = g(6, 6, (0, 0), key=(2, 0), door=(4, 0), goal=(5, 0))
_a2 = g(6, 6, (0, 0), key=(2, 0), door=(4, 0), goal=(5, 0),
        program=[R, R, PICK])
_a4 = g(6, 6, (0, 0), goal=(2, 0))
_a6 = g(6, 6, (0, 0), key=(1, 0), door=(3, 0), goal=(4, 0))
_a7 = g(6, 6, (0, 0), key=(1, 0), door=(3, 0), goal=(5, 0),
        program=[R, PICK, R, R, OPEN])

S431 = [
 q("chooseText", "This level needs a key, a door and a flag. What comes first? "
                 "Tap your answer.",
   "You cannot open the door without the thing that opens it.",
   opt(1), visual=_a0,
   optionsText=["Reach the flag", "Fetch the key", "Open the door"]),

 q("count", "Nupo must fetch the key, open the door, then reach the flag. "
            "How many jobs is that? Tap the number.",
   "Count the things named in the question.",
   num(3), visual=_a0, kind="stated"),

 q("predict", "Here is just the first job. Tap the square he ends on.",
   "Only these three rows run.",
   ends(_a2), visual=_a2),

 q("fix", "Build just the first part: get to the key and pick it up.",
   "Two steps across, then pick it up.",
   route(g(6, 6, (0, 0), key=(2, 0), door=(2, 0)), [R, R, PICK, OPEN]),
   visual=g(6, 6, (0, 0), key=(2, 0), door=(2, 0)),
   blocks=[R, PICK, R, OPEN], slots=4),

 q("choose", "Tap the order that does all three jobs.",
   "Key first, then the door, then the flag.",
   only_winner(_a6, [[R, PICK, R, R, OPEN, R],
                     [R, R, OPEN, PICK, R, R],
                     [R, R, R, PICK, OPEN, R]]),
   visual=_a6, options=[[R, PICK, R, R, OPEN, R],
                        [R, R, OPEN, PICK, R, R],
                        [R, R, R, PICK, OPEN, R]]),

 q("count", "How many steps does the whole level take? Tap the number.",
   "Count the shortest way from Nupo to the flag.",
   shortest_steps(_a4), visual=_a4, kind="shortest"),

 q("predict", "This list does the first two jobs only. Tap the square Nupo "
              "ends on.",
   "He fetches the key and opens the door, and stops there.",
   ends(_a7), visual=_a7),
]

# ---------------------------------------------------------------- 4.3.2
# A chunk you use again and again deserves a name.
#
# The chunk here is UP RIGHT, and it appears three times with different steps
# in between. That separation is the whole point: a loop can only repeat what
# sits next to itself, so this is the shape of problem a name solves. The stop
# closes with the contrasting board where the repeats ARE adjacent and a loop
# is the right tool after all.
_CHUNK = [U, R]
_b0 = g(7, 7, (0, 0), program=_CHUNK + [D] + _CHUNK + [L] + _CHUNK)
_b4 = g(7, 7, (0, 0), goal=(3, 3))
_b6 = g(7, 7, (0, 0), goal=(2, 2))

S432 = [
 q("spot", "The same two steps appear three times, but never side by side. "
           "Tap where the FIRST pair starts.",
   "Look for the pair that keeps coming back further down.",
   blk(0), visual=_b0, criterion="chunk:2"),

 q("count", "How many rows does this list use in full? Tap the number.",
   "Count them one by one.",
   rows(_b0), visual=_b0, kind="rows"),

 q("chooseText", "A loop cannot shorten this list. Tap the reason why.",
   "Look at what sits between one pair and the next.",
   opt(0), visual=_b0,
   optionsText=["The pairs are not next to each other",
                "The pair is too short",
                "There are only three pairs"]),

 q("count", "The chunk is 2 steps and Nupo uses it 3 times. How many steps "
            "is that in all? Tap the number.",
   "Two steps, three goes.",
   num(6), visual=_b0, kind="stated"),

 q("predict", "Run the whole list. Tap the square Nupo ends on.",
   "The steps in between move him too.",
   ends(_b0), visual=_b0),

 q("choose", "Here the chunk repeats side by side. A loop does fit this "
             "time. Tap the loop that reaches the flag.",
   "The flag is three up and three across.",
   only_winner(_b4, [rep(3, _CHUNK), rep(2, _CHUNK), rep(4, _CHUNK)]),
   visual=_b4, options=[rep(3, _CHUNK), rep(2, _CHUNK), rep(4, _CHUNK)]),

 q("constrain", "Use the chunk twice to reach the flag in exactly 4 steps. "
                "Drag the steps into order.",
   "The chunk is one up and one across. Do it twice.",
   route(_b6, [U, R, U, R]), visual=_b6,
   blocks=[U, D, L, R], slots=4, reusable=True),
]

# ---------------------------------------------------------------- 4.3.3
# Everything at once.
_c0 = g(6, 6, (0, 0), stars=[(0, 1), (0, 2)], mustPick=True,
        program=rep(2, [U] + iff("star", [PICK])))
_c1 = g(6, 6, (0, 0), vars={C: 0}, program=rep(3, [U, addv(C, 2)]))
_c3 = g(6, 6, (0, 0), goal=(2, 2), walls=[(1, 1)])
_c5 = g(6, 6, (0, 0), vars={C: 0}, program=rep(2, [addv(C, 3), R]))
# A trace table shows one value per row, so it needs a program with no loop.
_c6 = g(6, 6, (0, 0), vars={C: 0}, program=[addv(C, 3), R, addv(C, 3), R])

S433 = [
 q("predict", "A loop with a condition inside. Tap the square he ends on.",
   "The moves happen every time round. The pick only sometimes.",
   ends(_c0), visual=_c0),

 q("count", "How many stars does that collect? Tap the number.",
   "He checks on every square he steps onto.",
   stars_collected(_c0), visual=_c0, kind="stars"),

 q("count", "A loop with a box inside. What ends up in COINS? Tap the number.",
   "Two added each time, three times round.",
   box_value(_c1, C), visual=_c1, kind="var", varName=C),

 q("choose", "Tap the one that gets round the wall to the flag.",
   "The wall sits on the diagonal, so go along one side.",
   only_winner(_c3, [[R, R, U, U], [U, R, R, U], [R, U, U, R]]),
   visual=_c3, options=[[R, R, U, U], [U, R, R, U], [R, U, U, R]]),

 q("predict", "Loop, move and box together. Tap where he ends.",
   "Only the move rows change where he is.",
   ends(_c5), visual=_c5),

 trace_q("Tap the number that belongs in the blank row of this table.",
         "Only the ADD rows change the number.",
         _c6, C, 2),

 q("count", "How many moves does that loop make in total? Tap the number.",
   "Two rows inside, twice round.",
   moves_made(_c5), visual=_c5, kind="moves"),
]

# ---------------------------------------------------------------- 4.3.4  BOSS
_d0 = g(7, 7, (0, 0), goal=(3, 3), stars=[(1, 1), (2, 2)], mustPick=True,
        program=rep(3, [U, R] + iff("star", [PICK])))
_d2 = g(7, 7, (0, 0), vars={C: 0}, program=rep(4, [addv(C, 3)]))
_d6 = g(7, 7, (0, 0), vars={C: 0},
        program=[addv(C, 3), addv(C, 3), addv(C, 3), addv(C, 3)])
_d3 = g(7, 7, (0, 0), goal=(2, 2))
_d5 = g(7, 7, (0, 0), key=(2, 0), door=(4, 0), goal=(5, 0))

S434 = [
 q("predict", "Everything at once. Tap the square he ends on.",
   "Up and across each time round, three times over.",
   ends(_d0), visual=_d0),

 q("count", "How many stars does that list collect? Tap the number.",
   "He only picks up when he is standing on one.",
   stars_collected(_d0), visual=_d0, kind="stars"),

 q("count", "Four goes round, adding each time. What is left in COINS? "
            "Tap the number.",
   "Three added, four times round.",
   box_value(_d2, C), visual=_d2, kind="var", varName=C),

 q("constrain", "Use the named chunk twice to reach the flag in exactly 4 "
                "steps. Drag the steps into order.",
   "Two up and two across.",
   route(_d3, [U, R, U, R]), visual=_d3,
   blocks=[U, D, L, R], slots=4, reusable=True),

 q("choose", "One list fetches the key, opens the door and reaches the flag. "
             "Tap it.",
   "Key first. Then the door. Then the flag.",
   only_winner(_d5, [[R, R, PICK, R, R, OPEN, R],
                     [R, R, R, R, OPEN, PICK, R],
                     [R, R, OPEN, R, R, PICK, R]]),
   visual=_d5, options=[[R, R, PICK, R, R, OPEN, R],
                        [R, R, R, R, OPEN, PICK, R],
                        [R, R, OPEN, R, R, PICK, R]]),

 trace_q("Last one. Tap the number for the blank row.",
         "Three added every time round.",
         _d6, C, 3),
]
