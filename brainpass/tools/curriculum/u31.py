# -*- coding: utf-8 -*-
"""Unit 3.1 — If and then.

IF checks something before a step runs. If the check fails, the step is
skipped and everything carries on.

This unit used to teach that with thirty-seven identical "Is this true or
false?" screens: a condition floating in the air, no board, nothing at stake.
A child cannot see a condition. They CAN see a step that did not happen, and
an owl standing where he would not be standing if it had. So every question
here runs the condition on a board and asks about the result.

The second thing it fixes is sameness. Nearly every question in section 3 used
to be "where does he end up", "does he get the stars" or "does he reach the
flag", stop after stop, and by the fourth unit a child is answering the FORM of
the question rather than thinking. Counting how often a check is looked at, and
how often it comes back yes, is a question only a conditions unit can ask, and
it is the one that carries the idea.
"""
from kit import (g, q, rep, U, D, L, R, PICK, OPEN,
                 ends, stars_collected, moves_made, only_winner,
                 checks_made, checks_fired,
                 yesno, skipped_step, ran_step, can_move, opt)

# ---------------------------------------------------------------- 3.1.1
# The step runs, or it does not.

_p1 = g(5, 5, (0, 0), stars=[(0, 2)], mustPick=True,
        program=[U, U, "if:star", PICK, "end", U])
_p2 = g(5, 5, (0, 0), stars=[(1, 0)], mustPick=True,
        program=[R, "if:star", PICK, "end", R, R])
_p3 = g(5, 5, (0, 0), stars=[(3, 3)], mustPick=True,
        program=[U, "if:star", PICK, "end", U])
_p4 = g(5, 5, (0, 0), goal=(0, 3), stars=[(0, 1)], mustPick=True,
        program=[U, "if:star", PICK, "end", U, U])
_p5 = g(6, 6, (0, 0), stars=[(0, 1), (0, 3)], mustPick=True,
        program=rep(4, [U, "if:star", PICK, "end"]))
_p6 = g(5, 5, (0, 0), goal=(2, 2), program=[U, U, R, R])
_p7 = g(5, 5, (0, 0), goal=(2, 0), stars=[(1, 0)], mustPick=True,
        program=[R, "if:star", PICK, "end", R])

S311 = [
    q("predict", "Run the steps and tap the square Nupo ends on.",
      "The IF only checks. It never moves him.",
      ends(_p1), visual=_p1),

    yesno("Does Nupo pick up the star? Tap Yes or No.",
          "He is standing on it when the check is made.", _p2, "star"),

    skipped_step("One step in this list never happens. Tap that step.",
                 "Nupo is not on a star when the check is made.", _p3),

    q("count", "How many stars does Nupo pick up? Tap the number.",
      "Only the ones he is standing on when the check is made.",
      stars_collected(_p4), visual=_p4, kind="stars"),

    q("count", "The check is made more than once here. How many times does "
      "it come back yes? Tap the number.",
      "Look at which squares he lands on, then at which have a star.",
      checks_fired(_p5), visual=_p5, kind="fires"),

    q("count", "Some rows here are checks, not moves. How many moves does Nupo "
               "make? Tap the number.",
      "IF and END are checks, not moves.",
      moves_made(_p6), visual=_p6, kind="moves"),

    yesno("Does Nupo finish on the flag? Tap Yes or No.",
          "Work down the list one row at a time.", _p7, "flag"),
]

# ---------------------------------------------------------------- 3.1.2
# If, or else: two roads, and exactly one of them is walked.

_e_wall = g(5, 5, (0, 0), goal=(1, 0), walls=[(0, 1)],
            program=["if:wall-up", R, "else", U, "end"])
_e_open = g(5, 5, (0, 0), goal=(0, 1),
            program=["if:wall-up", R, "else", U, "end"])
_e2 = g(5, 5, (2, 0), goal=(2, 1), walls=[(3, 0)],
        program=["if:wall-right", U, "else", R, "end"])
_e3 = g(5, 5, (0, 0), goal=(2, 2), walls=[(1, 0)],
        program=["if:wall-right", U, "else", R, "end",
                 "if:wall-right", U, "else", R, "end",
                 R, R])

S312 = [
    q("predict", "There is a wall above Nupo. Run the steps and tap the "
      "square he ends on.",
      "A wall above means the top road is taken, not the bottom one.",
      ends(_e_wall), visual=_e_wall),

    q("predict", "Nothing is above Nupo now. Tap the square he ends on.",
      "No wall above. The check says no, so the OR ELSE road runs.",
      ends(_e_open), visual=_e_open),

    ran_step("Only one of these two roads is walked. Tap the step that does "
             "happen.",
             "Look right of Nupo, then read the check.", _e2),

    skipped_step("The other road is left alone. Tap the step that does not "
                 "happen.",
                 "One road is walked, and the other is passed over.", _e_open),

    can_move("Can Nupo step up from where he stands? Tap Yes or No.",
             "Look at the one square directly above him.", _e_wall, "up"),

    yesno("Does Nupo reach the flag? Tap Yes or No.",
          "Walk the road the check picks, then read the rest.", _e3, "flag"),

    q("count", "How many moves does Nupo make in this list? Tap the number.",
      "Each IF lets through one move, and two more follow.",
      moves_made(_e3), visual=_e3, kind="moves"),
]

# ---------------------------------------------------------------- 3.1.3
# Checked a lot, done rarely. The loop asks the same question every pass.

_l1 = g(6, 6, (0, 0), stars=[(1, 0), (3, 0), (4, 0)], mustPick=True,
        program=rep(5, [R, "if:star", PICK, "end"]))
_l3 = g(6, 6, (0, 0), stars=[(0, 2), (0, 4)], mustPick=True,
        program=rep(3, [U, "if:star", PICK, "end"]))
_l4 = g(6, 6, (0, 0), stars=[(2, 0)], mustPick=True,
        program=rep(4, [R, "if:star", PICK, "end"]))
_l5 = g(5, 5, (0, 0), goal=(0, 4), stars=[(0, 3)], mustPick=True,
        program=[U, PICK, U, U, PICK, U])
_l7 = g(5, 5, (0, 0), goal=(0, 2), stars=[(0, 1)], mustPick=True)

S313 = [
    q("count", "The check sits inside a loop. How many times is it looked "
      "at? Tap the number.",
      "Once on every go round, whatever it says.",
      checks_made(_l1), visual=_l1, kind="checks"),

    q("count", "How many of those looks come back yes? Tap the number.",
      "Count the squares he lands on that have a star.",
      checks_fired(_l1), visual=_l1, kind="fires"),

    q("count", "How many stars does Nupo end up holding? Tap the number.",
      "He goes past some squares he never lands on.",
      stars_collected(_l3), visual=_l3, kind="stars"),

    q("predict", "The loop goes round whether the check fires or not. Tap "
      "the square Nupo ends on.",
      "Four goes round, one step across each time.",
      ends(_l4), visual=_l4),

    q("debug", "This list picks up without checking first. Tap the first "
      "step that goes wrong.",
      "Find the first PICK UP made on an empty square.",
      {"type": "block", "value": 1}, visual=_l5),

    yesno("Does Nupo pick up every star on the board? Tap Yes or No.",
          "Count the stars, then count the ones he lands on.", _l3, "star"),

    q("choose", "Tap the list that takes the star and stops on the flag.",
      "He must be standing on the star when PICK UP runs.",
      only_winner(_l7, [[U, PICK, U], [U, U, PICK], [PICK, U, U]]),
      visual=_l7, options=[[U, PICK, U], [U, U, PICK], [PICK, U, U]]),
]

# ---------------------------------------------------------------- 3.1.4  BOSS

_z1 = g(6, 6, (0, 0), stars=[(1, 0), (2, 0)], mustPick=True,
        program=rep(4, [R, "if:star", PICK, "end"]))
_z2 = g(5, 5, (0, 0), key=(0, 1), door=(0, 3),
        program=[U, PICK, U, U, "if:door", OPEN, "end"])
_z3 = g(6, 6, (0, 0), goal=(2, 2), walls=[(0, 1)],
        program=["if:wall-up", R, "else", U, "end", U, U, R])
_z4 = g(5, 5, (0, 0), stars=[(4, 0)], mustPick=True,
        program=[U, "if:star", PICK, "end", R])
_z5 = g(5, 5, (0, 0), goal=(3, 0), program=[R, R, R])
_z6 = g(5, 5, (0, 0), stars=[(2, 0)], mustPick=True,
        program=[R, "if:star", PICK, "end"])

S314 = [
    q("count", "How many times does this check come back yes? Tap the "
      "number.",
      "He goes round four times and lands on a star twice.",
      checks_fired(_z1), visual=_z1, kind="fires"),

    yesno("Does Nupo get through the door? Tap Yes or No.",
          "He picks the key up on the way.", _z2, "door"),

    q("predict", "Read each check as you go. Tap the square Nupo ends on.",
      "The first check decides which road he starts on.",
      ends(_z3), visual=_z3),

    skipped_step("One step here is skipped. Tap that step.",
                 "Nothing is under him when the check is made.", _z4),

    q("count", "Checks are not moves. How many moves does Nupo make? Tap "
      "the number.",
      "Three rows, and all three shift him.",
      moves_made(_z5), visual=_z5, kind="moves"),

    q("chooseText", "The PICK UP never happened. Tap the reason why.",
      "Look at the square he was standing on when the check was made.",
      opt(0), visual=_z6,
      optionsText=["He was not on a star",
                   "The star was already taken",
                   "A wall was in the way"]),
]
