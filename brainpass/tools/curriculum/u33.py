# -*- coding: utf-8 -*-
"""Unit 3.3 — Both, and either.

The old version of this unit asked children to evaluate `(has_key AND at_door)
OR bridge` against a list of facts, and finished by asking why
`HAS KEY AND NOT HAS KEY` never fires. That is a logic exercise wearing a
programming costume, and none of it was on a board.

AND and OR are worth teaching as things Nupo does, and both already exist in
the language he speaks:

  AND  is a check inside a check. The step happens only when the outer check
       says yes AND the inner one does too.
  OR   is two roads that end at the same step. Either road gets there, so the
       step happens when the first check says yes OR the second one does.

That is not a simplification for children; it is what AND and OR compile to.
A child who reads a nested IF as "both" has learned the real thing.
"""
from kit import (g, q, rep, U, D, L, R, PICK, OPEN,
                 ends, stars_collected, moves_made,
                 checks_made, checks_fired,
                 yesno, skipped_step, ran_step, can_move, standing_on, opt)

# A check inside a check: pick the star up only when there is also a wall
# directly above it. Nupo walks the bottom row, so a wall above a star is
# something he can see rather than something that blocks his way.
_BOTH = ["if:star", "if:wall-up", PICK, "end", "end"]

# Two roads to the same step: move up when the way right is blocked, or when
# standing on a star. Either check is enough, because both roads end in UP.
_EITHER = ["if:wall-right", U, "else", "if:star", U, "end", "end"]

# ---------------------------------------------------------------- 3.3.1
# Both must say yes.

_a0 = g(6, 6, (0, 0), stars=[(1, 0), (3, 0)], walls=[(1, 1)], mustPick=True,
        program=rep(3, [R] + _BOTH))
_a1 = g(6, 6, (0, 0), stars=[(1, 0), (3, 0)], walls=[(1, 1), (3, 1)],
        mustPick=True, program=rep(3, [R] + _BOTH))
_a2 = g(5, 5, (0, 0), stars=[(1, 0)], mustPick=True, program=[R] + _BOTH)
# The gap board carries the wall the answer is about: asking a child to
# drop in WALL ABOVE on a board with no wall teaches the wrong lesson.
_a2gap = g(5, 5, (0, 0), stars=[(1, 0)], walls=[(1, 1)], mustPick=True,
           program=[R, "if:star", "if:?", PICK, "end", "end"])

S331 = [
    q("count", "Nupo picks a star up only if a wall sits above it too. How "
      "many stars does he pick up? Tap the number.",
      "Two stars on the row. Look above each one before you count it.",
      stars_collected(_a0), visual=_a0, kind="stars"),

    yesno("Is every star on this board collected? Tap Yes or No.",
          "One of the two stars has open sky above it.", _a0, "star"),

    q("count", "On this board BOTH stars have a wall above them. How many "
      "does Nupo pick up now? Tap the number.",
      "When both checks say yes, the step goes ahead.",
      stars_collected(_a1), visual=_a1, kind="stars"),

    skipped_step("Nupo is on a star, but nothing is above him. Tap the step "
                 "that never happens.",
                 "The outer check says yes. The inner one does not.", _a2),

    q("chooseText", "The inner check came back no. What happens to the PICK "
      "UP? Tap your answer.",
      "Both checks have to say yes before the step inside them runs.",
      opt(0), visual=_a2,
      optionsText=["It is skipped",
                   "It runs anyway",
                   "The whole list stops"]),

    q("count", "Count every check made here, the inner ones too. How many "
      "are there? Tap the number.",
      "The inner check is only looked at when the outer one says yes.",
      checks_made(_a0), visual=_a0, kind="checks"),

    q("complete", "The star must have a wall above it too. Tap the check "
      "for the inner IF row.",
      "The outer check already asks about the star.",
      opt(1), visual=_a2gap,
      optionsText=["ON A STAR", "WALL ABOVE", "AT THE DOOR"]),
]

# ---------------------------------------------------------------- 3.3.2
# Either one is enough.

_b0 = g(5, 5, (4, 0), goal=(4, 1), program=_EITHER)
_b1 = g(5, 5, (1, 0), goal=(1, 1), stars=[(1, 0)], mustPick=True,
        program=_EITHER)
_b2 = g(5, 5, (1, 0), goal=(1, 1), program=_EITHER)
_b2gap = g(5, 5, (1, 0), goal=(1, 1),
           program=["if:wall-right", U, "else", "if:star", "?", "end", "end"])
_b3 = g(6, 6, (0, 0), stars=[(0, 1), (0, 2)], mustPick=True,
        program=rep(3, [U] + _EITHER))

S332 = [
    q("predict", "Nupo moves up when the way right is blocked. Or when a "
      "star is under him. Here the board edge counts as a wall. Tap the "
      "square he ends on.",
      "The first check is enough on its own.",
      ends(_b0), visual=_b0),

    q("predict", "The way right is clear here, but Nupo is on a star. Tap "
      "the square he ends on.",
      "The second road leads to the same step as the first.",
      ends(_b1), visual=_b1),

    q("predict", "The way right is clear and there is no star. Tap the "
      "square Nupo ends on.",
      "Neither check says yes, so neither road is walked.",
      ends(_b2), visual=_b2),

    yesno("Neither check fired. Does Nupo still reach the flag? Tap Yes or "
          "No.",
          "Check both roads before you decide he stays put.", _b2, "flag"),

    q("chooseText", "Two roads end at the same step. How many checks must "
      "say yes for it to run? Tap your answer.",
      "Either road on its own gets him there.",
      opt(0), visual=_b0,
      optionsText=["Just one of them",
                   "Both of them",
                   "Neither of them"]),

    q("count", "How many moves does this loop make in all? Tap the number.",
      "Three goes round, and a star under him on some of them.",
      moves_made(_b3), visual=_b3, kind="moves"),

    q("complete", "Nupo must move up on either road. Tap the step that "
      "belongs on the second road.",
      "Both roads must end at the same step. Otherwise only one check counts.",
      opt(0), visual=_b2gap, optionsText=["UP", "RIGHT", "PICK UP"]),
]

# ---------------------------------------------------------------- 3.3.3
# Both and either, on the same board.

_c0 = g(6, 6, (0, 0), stars=[(1, 0), (2, 0), (4, 0)], walls=[(1, 1), (4, 1)],
        mustPick=True, program=rep(4, [R] + _BOTH))
_c1 = g(6, 6, (0, 0), goal=(0, 4), stars=[(0, 1)], mustPick=True,
        program=[U] + _EITHER + [U, U])
_c2 = g(5, 5, (2, 2), stars=[(2, 2)], walls=[(3, 2)], mustPick=True)
_cc = g(5, 5, (0, 0), stars=[(1, 0)], mustPick=True)
_c3 = g(6, 6, (0, 0), stars=[(2, 0)], walls=[(2, 1)], mustPick=True,
        program=rep(3, [R] + _BOTH))
_c3gap = g(6, 6, (0, 0), stars=[(2, 0)], walls=[(2, 1)], mustPick=True,
           program=rep(3, [R, "if:?", PICK, "end"]))

S333 = [
    q("count", "Again a star is picked up only when a wall sits above it. "
      "How many stars does Nupo pick up? Tap the number.",
      "Three stars along the row, and a wall above only some of them.",
      stars_collected(_c0), visual=_c0, kind="stars"),

    q("predict", "This list moves up if the way right is blocked. Or if "
      "Nupo is on a star. Tap the square he ends on.",
      "The star lets the move through, and two more steps follow.",
      ends(_c1), visual=_c1),

    # An option card is a single row of chips, so every IF on it reads just
    # "IF" with no room to say what it checks. Two different checks would look
    # identical. This asks the same thing with the checks in the LIST, where
    # they are spelled out, and two plain routes as the options.
    q("compare", "Two lists, one board. Do they finish on the same square? "
      "Tap your answer.",
      "Run each one from the top and compare only where he stops.",
      {"type": "bool",
       "value": ends(_cc, [U, R])["value"] == ends(_cc, [R, U])["value"]},
      visual=_cc, options=[[U, R], [R, U]]),

    standing_on("Is Nupo standing on a star right now? Tap Yes or No.",
                "With OR, this check on its own would be enough.",
                _c2, "star"),

    q("count", "Only one star here, and a wall above it. How many stars "
      "does Nupo pick up? Tap the number.",
      "Both checks say yes on the square where the star sits.",
      stars_collected(_c3), visual=_c3, kind="stars"),

    q("count", "How many times is a check looked at on this board? Tap the "
      "number.",
      "Three goes round, and the inner check is not always reached.",
      checks_made(_c3), visual=_c3, kind="checks"),

    q("complete", "Nupo must pick this star up whether or not anything sits "
      "above it. Tap the check that belongs in the IF row.",
      "One check is enough when the other is not wanted.",
      opt(0), visual=_c3gap,
      optionsText=["ON A STAR", "WALL ABOVE", "WALL ON THE RIGHT"]),
]

# ---------------------------------------------------------------- 3.3.4  BOSS

_d0 = g(6, 6, (0, 0), stars=[(1, 0), (2, 0), (3, 0)], walls=[(2, 1)],
        mustPick=True, program=rep(3, [R] + _BOTH))
_d1 = g(5, 5, (4, 2), goal=(4, 3), program=_EITHER)
_d2 = g(5, 5, (0, 0), stars=[(1, 0)], mustPick=True, program=[R] + _BOTH)
_d3 = g(6, 6, (0, 0), goal=(0, 3), stars=[(0, 1)], mustPick=True,
        program=[U] + _EITHER + [U])

S334 = [
    q("count", "Same rule again: a wall must sit above the star. How many "
      "stars does Nupo pick up? Tap the number.",
      "Move one square at a time and check both things each go.",
      stars_collected(_d0), visual=_d0, kind="stars"),

    yesno("Does Nupo end up holding all three stars? Tap Yes or No.",
          "Only the stars with something directly above them count.",
          _d0, "star"),

    q("predict", "Either check sends Nupo up: way right blocked, or a star "
      "underfoot. Tap the square he ends on.",
      "The board edge counts as blocked.",
      ends(_d1), visual=_d1),

    skipped_step("Nupo reaches the star, but the sky above it is open. Tap "
                 "the step that never happens.",
                 "The inner check is the one that turns it down.", _d2),

    q("count", "How many moves does Nupo make on this board? Tap the number.",
      "The checks are not moves. Count only the rows that shift him.",
      moves_made(_d3), visual=_d3, kind="moves"),

    yesno("Does Nupo stop on the flag square? Tap Yes or No.",
          "The star opens the second road, then one more step follows.",
          _d3, "flag"),
]
