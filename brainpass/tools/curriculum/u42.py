# -*- coding: utf-8 -*-
"""Unit 4.2 — Variables.

A variable is a labelled box with a number in it. SET puts a new number in and
throws away what was there; ADD changes the number that is already there. That
one distinction is the whole unit, and it is where most beginners trip.

This unit was rebuilt against how variables are actually taught to this age,
because the first version taught them in mid-air:

  Code.org's unplugged lesson gives every child an ENVELOPE with a label on
  the outside and a card inside. The label is the name, the card is the value,
  and swapping the card changes what the program says. BoxesView draws exactly
  that, so the picture and the lesson agree.

  Code.org then teaches CHANGING variables with the Bee, where the variable is
  the nectar the bee has collected. The number has a cause the child can see:
  it goes up because the bee did something. The first version of 4.2.1 had a
  box called COINS on an empty grid, rising by rows that said ADD 1 for no
  reason at all. Here the box counts the stars Nupo picks up, so every ADD row
  is something that happened on the board beside it.

  The Raspberry Pi Foundation's trajectory for primary learners runs Data
  Storer -> Data User -> Variable Interpreter before anything else, which is
  what these three stops are: the box holds a number, the number is used, and
  then the number is followed step by step in a table.

Sources: curriculum.code.org/csf-20/coursef (lessons 7 and 9);
raspberrypi.org/blog/variables-primary-school-computing-maths-education-seminar
"""
from kit import (U, D, L, R, PICK, OPEN, g, q, rep, cell, opt, blk, num, yes,
                 order, ends, fails_at, step_count, only_winner, same_end,
                 moves_made, rows, route, setv, addv, box_value, box_trace,
                 trace_q)

S = "STARS"
C = "COINS"
K = "KEYS"

# ---------------------------------------------------------------- 4.2.1
# Data storer: the box holds a number, and the number counts something real.
#
# Every ADD row here sits directly under the PICK UP that earned it, so a child
# reading down the list can see why the number went up.

def _walk(stars, w=6):
    """Nupo walks the bottom row, taking a star and counting it each time."""
    prog = []
    for x in range(1, w - 1):
        prog.append(R)
        if (x, 0) in stars:
            prog += [PICK, addv(S, 1)]
    return prog


_a0 = g(6, 4, (0, 0), stars=[(1, 0), (2, 0), (3, 0)], mustPick=True,
        vars={S: 0}, program=_walk({(1, 0), (2, 0), (3, 0)}))
_a1 = g(6, 4, (0, 0), stars=[(1, 0), (3, 0)], mustPick=True,
        vars={S: 2}, program=_walk({(1, 0), (3, 0)}))
_a2 = g(6, 4, (0, 0), stars=[(1, 0), (4, 0)], mustPick=True,
        vars={S: 0}, program=_walk({(1, 0), (4, 0)}))
_a3 = g(6, 4, (0, 0), stars=[(2, 0)], mustPick=True, vars={S: 0},
        program=[R, R, PICK, addv(S, 1), R])
# A trace table shows one row per step, so its board needs a SHORT list: ten
# rows of table plus a row of number choices does not fit on a phone.
_a5 = g(6, 4, (0, 0), stars=[(1, 0), (3, 0)], mustPick=True, vars={S: 0},
        program=[R, PICK, addv(S, 1), R, R, PICK, addv(S, 1)])
_a4 = g(6, 4, (0, 0), key=(1, 0), stars=[(3, 0)], mustPick=True,
        vars={S: 0, K: 0},
        program=[R, PICK, addv(K, 1), R, R, PICK, addv(S, 1)])

S421 = [
    q("count", "Nupo adds one to the box for every star he picks up. What is "
      "in STARS at the end? Tap the number.",
      "Count the ADD rows, or count the stars. They agree.",
      box_value(_a0, S), visual=_a0, kind="var", varName=S),

    q("count", "This box does not start empty. What is in it at the end? "
      "Tap the number.",
      "Start from the number already in the box, then add.",
      box_value(_a1, S), visual=_a1, kind="var", varName=S),

    q("spot", "Tap the FIRST row that changes what is in the box.",
      "Only an ADD row touches the box. Moving and picking up do not.",
      blk(2), visual=_a2, criterion="firstChanges:" + S),

    q("chooseText", "Nupo moves right. What does that row do to STARS? "
      "Tap your answer.",
      "A row has to name the box before it can change it.",
      opt(0), visual=_a3,
      optionsText=["Nothing at all",
                   "Adds one to it",
                   "Empties it"]),

    q("count", "He walks over one star without picking it up. What is in "
      "STARS at the end? Tap the number.",
      "The box only counts what an ADD row counts.",
      box_value(_a3, S), visual=_a3, kind="var", varName=S),

    q("count", "Two boxes on this board. What is in KEYS at the end? Tap "
      "the number.",
      "Read only the rows that say KEYS.",
      box_value(_a4, K), visual=_a4, kind="var", varName=K),

    trace_q("Follow STARS down the list. Tap the number for the blank row.",
            "Look at the row above the blank, and the one step between them.",
            _a5, S, 2),
]

# ---------------------------------------------------------------- 4.2.2
# Data user: SET throws away, ADD builds on. Here the box is the whole
# subject, so these boards carry no flag or star — an empty grid beside them
# would be scenery a child has to learn to ignore.
_b0 = g(4, 4, (0, 0), vars={C: 5}, program=[setv(C, 2)])
_b1 = g(4, 4, (0, 0), vars={C: 5}, program=[addv(C, 2)])
_b2 = g(4, 4, (0, 0), vars={C: 0}, program=[addv(C, 5), setv(C, 2), addv(C, 3)])
_b3 = g(4, 4, (0, 0), vars={C: 0}, program=[setv(C, 3), addv(C, 4), addv(C, 1)])
_b4 = g(4, 4, (0, 0), vars={C: 0}, program=[setv(C, 2), setv(C, 6)])
_b5 = g(4, 4, (0, 0), vars={C: 9}, program=[addv(C, -3), addv(C, -2)])

S422 = [
    q("count", "The box already holds 5. This row SETS it to 2. What is in "
      "it now? Tap the number.",
      "SET throws away what was there.",
      box_value(_b0, C), visual=_b0, kind="var", varName=C),

    q("count", "The box holds 5 again, but now the row ADDS 2. What is in "
      "it now? Tap the number.",
      "ADD keeps what was there and builds on it.",
      box_value(_b1, C), visual=_b1, kind="var", varName=C),

    q("spot", "Tap the row that throws away what the box already held.",
      "One of these three rows does not care what was in the box.",
      blk(1), visual=_b2, criterion="replaces"),

    q("count", "SET first, then two ADD rows. What is in the box at the "
      "end? Tap the number.",
      "Start from the SET, not from zero.",
      box_value(_b3, C), visual=_b3, kind="var", varName=C),

    q("chooseText", "Two SET rows in a row. What became of the first "
      "number? Tap your answer.",
      "SET does not care what was in the box before it.",
      opt(0), visual=_b4,
      optionsText=["It was thrown away",
                   "It was added to the second one",
                   "It is still in the box"]),

    q("count", "ADD can take away too. What is left in the box? Tap the "
      "number.",
      "Take three off first, then two more.",
      box_value(_b5, C), visual=_b5, kind="var", varName=C),

    trace_q("The SET row sits in the middle. Tap the number for the blank "
            "row.",
            "Read the row above the blank, then do the one step between them.",
            _b2, C, 1),
]

# ---------------------------------------------------------------- 4.2.3
# Variable interpreter: follow the number down the list, one row at a time.
# This is the habit the UK computing curriculum calls code tracing, given the
# way the research recommends — a worked example with values missing.
_c0 = g(4, 4, (0, 0), vars={C: 0}, program=[addv(C, 2), addv(C, 2), addv(C, 2)])
_c1 = g(4, 4, (0, 0), vars={C: 1}, program=rep(3, [addv(C, 3)]))
_c2 = g(6, 4, (0, 0), stars=[(1, 0), (3, 0)], mustPick=True, vars={S: 0},
        program=[R, PICK, addv(S, 1), R, R, PICK, addv(S, 1)])
_c3 = g(4, 4, (0, 0), vars={C: 0, K: 0},
        program=[addv(C, 4), addv(K, 1), addv(C, 2)])
_c5 = g(4, 4, (0, 0), vars={C: 10}, program=[addv(C, -3), addv(C, -3)])

S423 = [
    trace_q("One row of this table is blank. Tap the number that belongs "
            "there.",
            "Each row adds to the row above it.",
            _c0, C, 1),

    q("count", "A loop with an ADD inside. What ends up in COINS? Tap the "
      "number.",
      "Three times round, three lots added, on top of what it started with.",
      box_value(_c1, C), visual=_c1, kind="var", varName=C),

    trace_q("The moves leave the box alone. Tap the number for the blank "
            "row.",
            "Only the ADD rows change it. The rest hold it steady.",
            _c2, S, 4),

    q("count", "Two boxes now. What is in COINS at the end? Tap the number.",
      "Read only the rows that say COINS.",
      box_value(_c3, C), visual=_c3, kind="var", varName=C),

    q("count", "And what is in KEYS? Tap the number.",
      "Only one row in this list touches KEYS.",
      box_value(_c3, K), visual=_c3, kind="var", varName=K),

    q("chooseText", "This list has move rows and ADD rows. Which kind "
      "changes STARS? Tap your answer.",
      "A row has to name the box before it can change it.",
      opt(0), visual=_c2,
      optionsText=["Only the ADD rows",
                   "Only the move rows",
                   "Both kinds of row"]),

    trace_q("This list takes away instead of adding. Tap the number for the "
            "blank row.",
            "Each row takes three off the row above it.",
            _c5, C, 1),
]

# ---------------------------------------------------------------- 4.2.4  BOSS
_d0 = g(4, 4, (0, 0), vars={C: 0},
        program=[setv(C, 5), addv(C, 3), addv(C, 2)])
_d2 = g(4, 4, (0, 0), vars={C: 0}, program=rep(4, [addv(C, 5)]))
_d3 = g(4, 4, (0, 0), vars={C: 0},
        program=[addv(C, 6), setv(C, 1), addv(C, 6)])
_d4 = g(4, 4, (0, 0), vars={C: 0}, program=rep(3, [addv(C, 4)]))
_d5 = g(6, 4, (0, 0), stars=[(1, 0), (2, 0), (4, 0)], mustPick=True,
        vars={S: 0},
        program=[R, PICK, addv(S, 1), R, PICK, addv(S, 1), R, R, PICK,
                 addv(S, 1)])

S424 = [
    trace_q("A SET row, then two ADD rows. Tap the number for the blank row.",
            "The SET row does not care what was above it.",
            _d0, C, 0),

    q("count", "What is the final value in COINS? Tap the number.",
      "Work down from the SET row to the bottom.",
      box_value(_d0, C), visual=_d0, kind="var", varName=C),

    q("count", "A loop adding 5, four times round. What is in the box at "
      "the end? Tap the number.",
      "Four lots of five.",
      box_value(_d2, C), visual=_d2, kind="var", varName=C),

    q("spot", "It should end at 12 but ends at 7. Tap the row that spoils "
      "it.",
      "One row throws away everything above it.",
      blk(1), visual=_d3, criterion="replaces"),

    q("count", "How many times does the value change inside this loop? Tap "
      "the number.",
      "Once on every go round.",
      num(3), visual=_d4, kind="stated"),

    q("count", "The box counts the stars again. What is in STARS at the "
      "end? Tap the number.",
      "One ADD row under every PICK UP.",
      box_value(_d5, S), visual=_d5, kind="var", varName=S),
]
