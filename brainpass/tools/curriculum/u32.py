# -*- coding: utf-8 -*-
"""Unit 3.2 — What the check looks at.

This unit used to be called "True or False" and had no board at all. It showed
a line like `NOT coins > 5` beside a list of facts and asked a child to say
whether it held. Nineteen of its twenty-seven questions were that same screen,
and two of the rest asked whether a condition could be true and false at once,
which is not a question about programming.

A check is worth teaching as something with a place to stand. Every question
here puts Nupo on a board and asks about the square he is on or the square next
to him, so a child settles it by looking, and the answer is still there to be
pointed at when they get it wrong.
"""
from kit import (g, q, rep, U, D, L, R, PICK, OPEN,
                 ends, stars_collected, moves_made, only_winner,
                 checks_made, checks_fired,
                 yesno, skipped_step, ran_step, can_move, standing_on, opt)

# ---------------------------------------------------------------- 3.2.1
# A check is about the square Nupo is standing on, or the one next to it.

_a0 = g(5, 5, (2, 2), walls=[(2, 3)], stars=[(2, 2)], mustPick=True)
_a1 = g(5, 5, (1, 1), stars=[(3, 1)], mustPick=True)
_a2 = g(5, 5, (0, 0), stars=[(0, 2)], mustPick=True,
        program=[U, U, "if:star", PICK, "end"])
_a3 = g(5, 5, (0, 0), stars=[(1, 0), (2, 0), (3, 0)], mustPick=True,
        program=rep(3, [R, "if:star", PICK, "end"]))
_a4 = g(5, 5, (0, 0), stars=[(4, 4)], mustPick=True,
        program=[U, U, "if:star", PICK, "end", R])

S321 = [
    standing_on("Look at the board. Is Nupo standing on a star right now? "
                "Tap Yes or No.",
                "A check looks at the square under his feet, nothing else.",
                _a0, "star"),

    standing_on("The star is further along. Is Nupo standing on it yet? "
                "Tap Yes or No.",
                "The check is made where he is now, not where he is heading.",
                _a1, "star"),

    can_move("Is the square directly above Nupo free? Tap Yes or No.",
             "A wall there, or the board edge, would stop him.", _a0, "up"),

    q("chooseText", "Which square does the check ON A STAR look at? Tap "
      "your answer.",
      "A check never looks ahead, and never looks back.",
      opt(0), visual=_a0,
      optionsText=["The square Nupo is standing on",
                   "The square he started from",
                   "Every square on the board"]),

    q("predict", "The check does not move him. Tap the square Nupo ends on.",
      "PICK UP takes the star but leaves him where he is.",
      ends(_a2), visual=_a2),

    q("count", "The list checks on every square he lands on. How many times "
      "does it say yes? Tap the number.",
      "Three landings, and a star waiting on each of them.",
      checks_fired(_a3), visual=_a3, kind="fires"),

    skipped_step("Nupo never picks this star up. Tap the step that is "
                 "skipped.",
                 "There is nothing under him when the check is made.", _a4),
]

# ---------------------------------------------------------------- 3.2.2
# Blocked or clear: the check steers him round things.

_b0 = g(5, 5, (0, 0), goal=(1, 0), walls=[(0, 1)],
        program=["if:wall-up", R, "else", U, "end"])
_b1 = g(5, 5, (2, 2), goal=(2, 3),
        program=["if:wall-up", R, "else", U, "end"])
_b2 = g(6, 5, (0, 0), goal=(3, 0), walls=[(1, 1)],
        program=[R, "if:wall-up", R, "else", U, "end", R])
_b3 = g(5, 5, (0, 2), goal=(2, 2), walls=[(1, 2)],
        program=[U, R, R, D])
_b4 = g(5, 5, (0, 0), goal=(0, 3), walls=[(1, 0)])

S322 = [
    q("predict", "A wall sits above Nupo. Tap the square he ends on.",
      "A wall above means the check says yes, so the first road runs.",
      ends(_b0), visual=_b0),

    q("predict", "This board has no wall above him. Tap the square he ends "
      "on.",
      "Nothing above him. The check says no, so the OR ELSE road runs.",
      ends(_b1), visual=_b1),

    ran_step("Two roads, one check. Tap the step that actually runs.",
             "Look above Nupo first, then read the check.", _b1),

    can_move("Is the way up clear for Nupo? Tap Yes or No.",
             "There is a wall drawn in the square above him.", _b2, "up"),

    yesno("Does Nupo land on the flag at the end? Tap Yes or No.",
          "Work down the list, taking whichever road the check picks.",
          _b2, "flag"),

    yesno("Does any step in this list fail? Tap Yes or No.",
          "A step into a wall goes nowhere, and that is a failed step.",
          _b3, "stuck"),

    q("choose", "A wall sits in the way on the right. Tap the list that "
      "still reaches the flag.",
      "He has to get up and round rather than straight across.",
      only_winner(_b4, [[U, U, U], [R, R, U], [U, R, R]]),
      visual=_b4, options=[[U, U, U], [R, R, U], [U, R, R]]),
]

# ---------------------------------------------------------------- 3.2.3
# NOT: the same check, read the other way round.

_c0 = g(5, 5, (0, 0), goal=(0, 2), walls=[(1, 0)],
        program=["if:not-wall-up", U, "else", R, "end", U])
_c1 = g(5, 5, (0, 0), goal=(1, 0), walls=[(0, 1)],
        program=["if:not-wall-up", U, "else", R, "end"])
_c1gap = g(5, 5, (0, 0), goal=(1, 0), walls=[(0, 1)],
           program=["if:not-wall-up", U, "else", "?", "end"])
_c2 = g(6, 6, (0, 0), stars=[(0, 1), (0, 3)], mustPick=True,
        program=rep(4, [U, "if:not-star", R, "end"]))
_c3 = g(5, 5, (0, 0), goal=(3, 0), walls=[(1, 1), (2, 1)],
        program=rep(3, ["if:not-wall-right", R, "else", U, "end"]))

S323 = [
    q("predict", "This check asks if the way up is CLEAR. Tap the square "
      "Nupo ends on.",
      "Nothing is above him, so the way up is clear.",
      ends(_c0), visual=_c0),

    ran_step("The way up is blocked here. Tap the step that happens.",
             "The check wants a clear square above, and does not get one.",
             _c1),

    q("chooseText", "What does the check NO WALL ABOVE ask? Tap your answer.",
      "NOT reads the same check the other way round.",
      opt(0), visual=_c1,
      optionsText=["Is the square above free?",
                   "Is there a wall above?",
                   "Is Nupo on a star?"]),

    q("count", "This list moves right only when Nupo is NOT on a star. How "
      "many moves does he make? Tap the number.",
      "Four moves up. Add one move right for every go with no star.",
      moves_made(_c2), visual=_c2, kind="moves"),

    q("count", "How many times does this NOT check come back yes? Tap the "
      "number.",
      "It says yes on every landing square with no star on it.",
      checks_fired(_c2), visual=_c2, kind="fires"),

    yesno("Does Nupo stop on the flag? Tap Yes or No.",
          "Read the check each time round, then take the road it picks.",
          _c3, "flag"),

    q("complete", "The way up is blocked, and Nupo must still move. Tap the "
      "step that belongs in the OR ELSE row.",
      "The OR ELSE road runs when the way up is not clear.",
      opt(1), visual=_c1gap, optionsText=["UP", "RIGHT", "PICK UP"]),
]

# ---------------------------------------------------------------- 3.2.4  BOSS

_d0 = g(6, 6, (0, 0), goal=(2, 2), walls=[(0, 1)],
        program=["if:wall-up", R, "else", U, "end",
                 "if:wall-up", R, "else", U, "end", U, U])
_d1 = g(5, 5, (0, 0), key=(0, 2), door=(0, 4),
        program=[U, U, PICK, U, U, "if:door", OPEN, "end"])
_d2 = g(6, 6, (0, 0), stars=[(1, 0), (2, 0), (4, 0)], mustPick=True,
        program=rep(5, [R, "if:star", PICK, "end"]))
_d2gap = g(6, 6, (0, 0), stars=[(1, 0), (2, 0), (4, 0)], mustPick=True,
           program=rep(5, [R, "if:?", PICK, "end"]))
_d3 = g(5, 5, (0, 0), goal=(4, 0), walls=[(3, 0)], program=[R, R, R, R])
_d4 = g(5, 5, (0, 0), stars=[(3, 3)], mustPick=True,
        program=[R, R, "if:star", PICK, "end", U])

S324 = [
    q("predict", "Read each check against where he stands. Tap the square "
      "Nupo ends on.",
      "The first check decides which road he starts on.",
      ends(_d0), visual=_d0),

    yesno("Does the door open for Nupo? Tap Yes or No.",
          "He needs to be carrying the key by the time he reaches it.",
          _d1, "door"),

    q("debug", "Nupo gets stuck on this board. Tap the first step that "
      "fails.",
      "Follow him along the row until a wall is in his way.",
      {"type": "block", "value": 2}, visual=_d3),

    q("count", "How many stars does Nupo end up with? Tap the number.",
      "Five goes round, and a star on only some of the squares.",
      stars_collected(_d2), visual=_d2, kind="stars"),

    q("complete", "This list should pick a star up whenever Nupo lands on "
      "one. Tap the check that belongs in the IF row.",
      "The check has to ask about the square he is standing on.",
      opt(0), visual=_d2gap,
      optionsText=["ON A STAR", "WALL ABOVE", "AT THE DOOR"]),

    skipped_step("One step here is never reached. Tap it.",
                 "The check is made on a square with nothing on it.", _d4),
]
