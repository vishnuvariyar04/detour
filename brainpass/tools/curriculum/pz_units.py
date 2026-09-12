# -*- coding: utf-8 -*-
"""Puzzles & Logic — 48 stops, 324 questions, band b, ages 7-8.

REWRITTEN after the first draft was reviewed on the wall and judged "almost the
same as 5-6". That was correct, and measuring it afterwards showed how correct:

  patterns    band a runs star, heart, star, heart -- period two, one property.
              The first draft ran period three. Longer, but the same act: see
              the repeat. Now every pattern runs TWO cycles at once, two shapes
              against three colours, so the strip only repeats every six and the
              child has to track each cycle and put them back together.
  sorting     band a already ships POINTY / ROUND over five shapes. The first
              draft shipped STAR / NOT A STAR over five shapes. Identical. Now
              the rules take two properties at once, or a negation.
  odd one out band a gives four cells identical but for one, so the outlier pops
              with no reasoning at all. Now the other properties are noise, and
              the child has to work out which property matters first.
  arrays      band a already reaches 8x3 and 5x6. The first draft's biggest was
              the same size. Now they are times-table facts up to 48.

Four rules hold everywhere in this file.

HARDER THAN BAND A, DEMONSTRABLY. Not "longer" and not "more of them". If a five
year old could do it with the same act of thought, it does not belong here.

ONE IDEA, SEVERAL PICTURES. Each unit now mixes two or three question types.
Both shipped skills do this in all twelve of their units; the first draft of this
one had ten units running a single type for twenty-seven questions.

SHORT, PLAIN PROMPTS. Seven year olds, many reading in a second or third
language, on a card over the app they actually wanted. One short sentence naming
one action. Where a rule is needed, it goes on the TRAY LABEL, which is on screen
beside the shapes, instead of lengthening the sentence.

NO QUESTION APPEARS TWICE, here or against the 648 already shipped.
"""
from puzzles_kit import (
    STAR, HEART, CIRCLE, SQUARE, TRIANGLE, DIAMOND, HEXAGON, FLOWER,
    PRIMARY, ACCENT, cell, item,
    pattern, repeat_strip, interleaved, skip_line, count_objects, array,
    odd_one_out, odd_by, sort_two, yes_no, size_order,
    analogy, rel_colour, rel_count, rel_bigger, rel_smaller, rel_turn,
    code_read, code_pick,
)

_SQ, _TR, _CI = cell(SQUARE), cell(TRIANGLE), cell(CIRCLE)
_ST, _HE, _HX = cell(STAR), cell(HEART), cell(HEXAGON)
_DI, _FL = cell(DIAMOND), cell(FLOWER)
_SQy, _TRy = cell(SQUARE, ACCENT), cell(TRIANGLE, ACCENT)
_CIy, _STy = cell(CIRCLE, ACCENT), cell(STAR, ACCENT)
_HEy, _HXy = cell(HEART, ACCENT), cell(HEXAGON, ACCENT)
_DIy, _FLy = cell(DIAMOND, ACCENT), cell(FLOWER, ACCENT)

# One short sentence, one action. Reused deliberately: a child who has met the
# sentence before spends their attention on the puzzle instead of the wording.
P_NEXT = "Tap the shape that comes next."
P_GAP = "Tap the shape that fits the gap."
P_ODD = "Tap the one that does not belong."
P_SMALL = "Tap them from small to big."
P_LAND = "Tap the number it lands on."
P_SORT = "Move each shape to its box."
P_AN = "Tap the shape that finishes it."
P_CODE = "Tap what the row adds up to."
P_CODEGAP = "Tap the missing symbol."

# Two shapes against three colours: repeats every six, not every two.
_2x3 = [(([STAR, HEART]), [PRIMARY, ACCENT, PRIMARY]),
        (([CIRCLE, SQUARE]), [ACCENT, PRIMARY, PRIMARY]),
        (([TRIANGLE, DIAMOND]), [PRIMARY, PRIMARY, ACCENT]),
        (([HEXAGON, FLOWER]), [ACCENT, ACCENT, PRIMARY])]


# ================================================================ SECTION 1
# Patterns: two rules running at once, not one.

S111 = [
    interleaved(P_NEXT, [STAR, HEART], [PRIMARY, ACCENT, PRIMARY], 8, 7),
    interleaved(P_NEXT, [CIRCLE, SQUARE], [ACCENT, PRIMARY, PRIMARY], 8, 7),
    interleaved(P_NEXT, [TRIANGLE, DIAMOND], [PRIMARY, PRIMARY, ACCENT], 8, 7),
    interleaved(P_NEXT, [HEXAGON, FLOWER], [ACCENT, ACCENT, PRIMARY], 8, 7),
    interleaved(P_NEXT, [HEART, CIRCLE], [PRIMARY, ACCENT, ACCENT], 8, 7),
    interleaved(P_NEXT, [SQUARE, STAR], [ACCENT, PRIMARY, ACCENT], 8, 7),
    interleaved(P_NEXT, [DIAMOND, HEXAGON], [PRIMARY, ACCENT, PRIMARY], 8, 7),
]

S112 = [
    interleaved(P_GAP, [STAR, CIRCLE], [PRIMARY, PRIMARY, ACCENT], 9, 4),
    interleaved(P_GAP, [HEART, SQUARE], [ACCENT, PRIMARY, PRIMARY], 9, 3),
    interleaved(P_GAP, [TRIANGLE, FLOWER], [PRIMARY, ACCENT, ACCENT], 9, 5),
    interleaved(P_GAP, [DIAMOND, STAR], [ACCENT, ACCENT, PRIMARY], 9, 6),
    odd_by(P_ODD, [_TR, _TRy, _SQ, _TR, _TRy], "kind"),
    odd_by(P_ODD, [_CI, _CIy, _CI, _HE, _CIy], "kind"),
    odd_by(P_ODD, [_ST, _STy, _STy, _ST, _DI], "kind"),
]

# The gap now sits early in the strip, so the rule has to be read from the right
# hand side backwards as well as from the left forwards.
S113 = [
    interleaved(P_GAP, [HEXAGON, CIRCLE], [PRIMARY, ACCENT, PRIMARY], 10, 1),
    interleaved(P_GAP, [FLOWER, HEART], [ACCENT, PRIMARY, ACCENT], 10, 2),
    interleaved(P_GAP, [SQUARE, DIAMOND], [PRIMARY, PRIMARY, ACCENT], 10, 0),
    interleaved(P_GAP, [STAR, HEXAGON], [ACCENT, PRIMARY, PRIMARY], 10, 8),
    interleaved(P_NEXT, [CIRCLE, TRIANGLE], [PRIMARY, ACCENT, ACCENT], 10, 9),
    odd_by(P_ODD, [_HE, _HEy, _HE, _HEy, _FL, _HE], "kind"),
    odd_by(P_ODD, [_DI, _DIy, _HX, _DI, _DIy], "kind"),
]

S114 = [
    interleaved(P_NEXT, [HEART, DIAMOND], [ACCENT, PRIMARY, PRIMARY], 9, 8),
    interleaved(P_GAP, [FLOWER, STAR], [PRIMARY, ACCENT, PRIMARY], 10, 4),
    odd_by(P_ODD, [_SQ, _SQy, _SQ, _CI, _SQy, _SQ], "kind"),
    interleaved(P_GAP, [CIRCLE, HEXAGON], [ACCENT, ACCENT, PRIMARY], 9, 2),
    odd_by(P_ODD, [_FL, _FLy, _TR, _FL, _FLy], "kind"),
    interleaved(P_NEXT, [TRIANGLE, SQUARE], [PRIMARY, ACCENT, ACCENT], 8, 7),
]

# ---- 1.2 Number steps ------------------------------------------------------
# Band a hops one at a time on a line to ten. These are threes, fours and sixes
# to fifty, and back down again.

S121 = [
    skip_line(P_LAND, 30, 0, 3, 6),
    skip_line(P_LAND, 30, 4, 3, 5),
    skip_line(P_LAND, 40, 0, 4, 7),
    skip_line(P_LAND, 40, 6, 4, 6),
    skip_line(P_LAND, 50, 2, 6, 7),
    skip_line(P_LAND, 50, 0, 6, 8),
    skip_line(P_LAND, 40, 7, 4, 8),
]

S122 = [
    skip_line(P_LAND, 40, 38, -4, 8),
    skip_line(P_LAND, 30, 29, -3, 8),
    skip_line(P_LAND, 50, 48, -6, 7),
    skip_line(P_LAND, 40, 35, -4, 7),
    array("Count them. Tap the number.", 4, 6),
    array("Count them. Tap the number.", 6, 5, STAR),
    array("Count them. Tap the number.", 3, 9, HEART),
]

S123 = [
    skip_line(P_LAND, 50, 5, 7, 6),
    skip_line(P_LAND, 50, 44, -7, 6),
    skip_line(P_LAND, 50, 3, 8, 5),
    skip_line(P_LAND, 50, 46, -8, 5),
    array("Count them. Tap the number.", 6, 7),
    array("Count them. Tap the number.", 4, 8, SQUARE),
    array("Count them. Tap the number.", 6, 8, CIRCLE),
]

S124 = [
    skip_line(P_LAND, 50, 1, 6, 8),
    array("Count them. Tap the number.", 5, 8, HEART),
    skip_line(P_LAND, 50, 47, -6, 7),
    array("Count them. Tap the number.", 7, 6, STAR),
    skip_line(P_LAND, 40, 9, 4, 7),
    skip_line(P_LAND, 30, 27, -3, 9),
]

# ---- 1.3 Growing patterns --------------------------------------------------

S131 = [
    array("Count them. Tap the number.", 3, 7),
    size_order(P_SMALL, [0.3, 0.55, 0.85, 1.0]),
    array("Count them. Tap the number.", 5, 6, STAR),
    size_order(P_SMALL, [0.95, 0.4, 0.65, 0.2], HEART),
    array("Count them. Tap the number.", 4, 7, HEART),
    size_order(P_SMALL, [0.5, 1.0, 0.2, 0.75], CIRCLE),
    array("Count them. Tap the number.", 8, 4, SQUARE),
]

S132 = [
    size_order(P_SMALL, [0.2, 0.4, 0.6, 0.8, 1.0], SQUARE),
    skip_line(P_LAND, 50, 5, 5, 8),
    size_order(P_SMALL, [1.0, 0.75, 0.5, 0.3, 0.15], TRIANGLE),
    skip_line(P_LAND, 50, 2, 7, 6),
    size_order(P_SMALL, [0.6, 0.2, 0.95, 0.4, 0.8], HEXAGON),
    array("Count them. Tap the number.", 6, 6, DIAMOND),
    size_order(P_SMALL, [0.35, 0.85, 0.15, 0.6, 1.0], FLOWER),
]

S133 = [
    array("Count them. Tap the number.", 7, 5),
    interleaved(P_NEXT, [SQUARE, CIRCLE], [PRIMARY, ACCENT, ACCENT], 8, 7),
    array("Count them. Tap the number.", 8, 5, HEART),
    size_order(P_SMALL, [0.2, 0.5, 0.8, 1.0], DIAMOND),
    array("Count them. Tap the number.", 6, 4, FLOWER),
    interleaved(P_GAP, [HEART, HEXAGON], [ACCENT, PRIMARY, PRIMARY], 9, 5),
    array("Count them. Tap the number.", 7, 4, HEXAGON),
]

S134 = [
    array("Count them. Tap the number.", 8, 6),
    size_order(P_SMALL, [0.15, 0.4, 0.65, 0.9], STAR),
    skip_line(P_LAND, 50, 0, 7, 7),
    array("Count them. Tap the number.", 5, 9, TRIANGLE),
    size_order(P_SMALL, [0.8, 0.3, 1.0, 0.55, 0.15], CIRCLE),
    skip_line(P_LAND, 50, 49, -7, 7),
]


# ================================================================ SECTION 2
# Rules: two at once, or one turned inside out.
#
# Band a sorts on a single property it has already named -- ROUND / NOT ROUND.
# Every rule here needs two properties held together, or a negation, which is
# the first place a child has to check a shape against something it is NOT.
# The rule lives on the tray label, on screen beside the shapes, so the prompt
# stays one short sentence.

_y = lambda c: c["color"] == ACCENT
_pointy = lambda c: c["kind"] in (STAR, TRIANGLE, DIAMOND)
_round = lambda c: c["kind"] == CIRCLE
_corners4 = lambda c: c["kind"] in (SQUARE, DIAMOND)

# ---- 2.1 Two rules at once -------------------------------------------------

S211 = [
    sort_two(P_SORT, [_STy, _ST, _CIy, _STy, _HE, _CI],
             lambda c: c["kind"] == STAR and _y(c), "YELLOW STARS", "THE REST"),
    sort_two(P_SORT, [_CI, _CIy, _SQ, _CI, _HEy, _CIy],
             lambda c: _round(c) and not _y(c), "PURPLE CIRCLES", "THE REST"),
    sort_two(P_SORT, [_TRy, _TR, _DIy, _SQ, _TRy, _CI],
             lambda c: c["kind"] == TRIANGLE and _y(c), "YELLOW TRIANGLES", "THE REST"),
    sort_two(P_SORT, [_DIy, _DI, _SQy, _SQ, _HXy, _CIy],
             lambda c: _corners4(c) and _y(c), "YELLOW, 4 CORNERS", "THE REST"),
    sort_two(P_SORT, [_HE, _HEy, _FL, _HE, _FLy, _HEy],
             lambda c: c["kind"] == HEART and not _y(c), "PURPLE HEARTS", "THE REST"),
    sort_two(P_SORT, [_STy, _TRy, _CIy, _ST, _TR, _HXy],
             lambda c: _pointy(c) and _y(c), "YELLOW, POINTY", "THE REST"),
    sort_two(P_SORT, [_HXy, _HX, _FLy, _FL, _DIy, _DI],
             lambda c: c["kind"] == HEXAGON and _y(c), "YELLOW HEXAGONS", "THE REST"),
]

# ---- 2.2 Odd one out, with noise -------------------------------------------
# Band a's four cells are identical but for one, so nothing has to be worked out.
# Here the other properties vary on purpose: the child has to decide which
# property matters before they can find the shape that breaks it.

S221 = [
    odd_by(P_ODD, [_TR, _TRy, _TR, _SQ, _TRy], "kind"),
    odd_by(P_ODD, [_CIy, _CI, _HE, _CIy, _CI], "kind"),
    odd_by(P_ODD, [_ST, _STy, _ST, _STy, _HX, _ST], "kind"),
    odd_by(P_ODD, [_DI, _DIy, _DI, _FL, _DIy, _DI], "kind"),
    odd_by(P_ODD, [_HXy, _HX, _HXy, _TR, _HX], "kind"),
    odd_by(P_ODD, [_FL, _FLy, _CI, _FL, _FLy, _FL], "kind"),
    odd_by(P_ODD, [_SQ, _SQy, _SQ, _SQy, _HE], "kind"),
]

S212 = [
    sort_two(P_SORT, [_ST, _STy, _HE, _HEy, _CI, _CIy],
             _pointy, "POINTY", "SMOOTH"),
    odd_by(P_ODD, [_TRy, _TR, _TRy, _CI, _TR, _TRy], "kind"),
    sort_two(P_SORT, [_SQy, _SQ, _DIy, _CI, _HX, _DI],
             _corners4, "4 CORNERS", "THE REST"),
    odd_by(P_ODD, [_HE, _HEy, _HE, _DI, _HEy], "kind"),
    sort_two(P_SORT, [_CIy, _CI, _STy, _ST, _FLy, _TR],
             lambda c: _round(c) or c["kind"] == FLOWER, "ROUND", "THE REST"),
    odd_by(P_ODD, [_HXy, _HX, _HX, _HXy, _FL, _HX], "kind"),
    sort_two(P_SORT, [_DIy, _DI, _HXy, _HX, _SQy, _SQ],
             lambda c: c["kind"] == DIAMOND and _y(c), "YELLOW DIAMONDS", "THE REST"),
]

S213 = [
    sort_two(P_SORT, [_STy, _ST, _CIy, _CI, _TRy, _TR],
             lambda c: not _y(c), "NOT YELLOW", "YELLOW"),
    sort_two(P_SORT, [_CI, _SQ, _TR, _CIy, _HX, _DI],
             lambda c: not _round(c), "NOT ROUND", "ROUND"),
    odd_by(P_ODD, [_CI, _CIy, _CI, _SQ, _CIy, _CI], "kind"),
    sort_two(P_SORT, [_TR, _TRy, _SQ, _HE, _DI, _CI],
             lambda c: not _pointy(c), "NOT POINTY", "POINTY"),
    sort_two(P_SORT, [_HE, _HEy, _FL, _FLy, _ST, _STy],
             lambda c: c["kind"] != HEART, "NOT HEARTS", "HEARTS"),
    odd_by(P_ODD, [_FLy, _FL, _FLy, _HX, _FL], "kind"),
    sort_two(P_SORT, [_SQ, _SQy, _DI, _DIy, _CI, _TR],
             lambda c: not _corners4(c), "NOT 4 CORNERS", "4 CORNERS"),
]

S214 = [
    sort_two(P_SORT, [_STy, _ST, _HEy, _HE, _CIy, _CI],
             lambda c: c["kind"] == STAR and _y(c), "YELLOW STARS", "THE REST"),
    odd_by(P_ODD, [_TR, _TRy, _HX, _TR, _TRy, _TR], "kind"),
    sort_two(P_SORT, [_DI, _DIy, _SQ, _SQy, _HX, _FL],
             lambda c: not _corners4(c), "NOT 4 CORNERS", "4 CORNERS"),
    interleaved(P_NEXT, [HEART, SQUARE], [ACCENT, PRIMARY, PRIMARY], 8, 7),
    odd_by(P_ODD, [_CIy, _CI, _CIy, _TR, _CI], "kind"),
    sort_two(P_SORT, [_FLy, _FL, _HXy, _HX, _STy, _ST],
             lambda c: c["kind"] == FLOWER and not _y(c), "PURPLE FLOWERS", "THE REST"),
]

# ---- 2.3 Sorting into groups -----------------------------------------------

S231 = [
    sort_two(P_SORT, [_ST, _TR, _DI, _CI, _HE, _FL],
             _pointy, "POINTY", "SMOOTH"),
    odd_by(P_ODD, [_HE, _HEy, _HE, _CI, _HEy, _HE], "kind"),
    sort_two(P_SORT, [_SQy, _DI, _CIy, _HX, _SQ, _DIy],
             _corners4, "4 CORNERS", "THE REST"),
    sort_two(P_SORT, [_CIy, _CI, _HEy, _STy, _ST, _HE],
             _y, "YELLOW", "PURPLE"),
    odd_by(P_ODD, [_DIy, _DI, _DIy, _ST, _DI], "kind"),
    sort_two(P_SORT, [_TR, _TRy, _HX, _HXy, _FL, _FLy],
             lambda c: c["kind"] == TRIANGLE, "TRIANGLES", "THE REST"),
    sort_two(P_SORT, [_ST, _STy, _CI, _CIy, _SQ, _SQy],
             lambda c: not _pointy(c), "NOT POINTY", "POINTY"),
]

S232 = [
    sort_two(P_SORT, [_HXy, _HX, _FLy, _FL, _DIy, _DI],
             lambda c: _y(c) and not _corners4(c), "YELLOW, NOT 4", "THE REST"),
    odd_by(P_ODD, [_SQ, _SQy, _FL, _SQ, _SQy, _SQ], "kind"),
    sort_two(P_SORT, [_STy, _ST, _TRy, _TR, _CIy, _CI],
             lambda c: _pointy(c) and not _y(c), "PURPLE, POINTY", "THE REST"),
    interleaved(P_GAP, [DIAMOND, CIRCLE], [PRIMARY, ACCENT, ACCENT], 9, 4),
    odd_by(P_ODD, [_HX, _HXy, _HX, _CI, _HXy], "kind"),
    sort_two(P_SORT, [_HE, _HEy, _DI, _DIy, _CI, _CIy],
             lambda c: c["kind"] == DIAMOND or _round(c), "ROUND OR DIAMOND", "THE REST"),
    sort_two(P_SORT, [_FL, _FLy, _ST, _STy, _TR, _TRy],
             lambda c: _y(c) and _pointy(c), "YELLOW, POINTY", "THE REST"),
]

S233 = [
    odd_by(P_ODD, [_TRy, _TR, _TRy, _TR, _HE, _TR], "kind"),
    sort_two(P_SORT, [_CI, _CIy, _SQ, _SQy, _HX, _HXy],
             lambda c: not _round(c) and not _y(c), "PURPLE, NOT ROUND", "THE REST"),
    array("Count them. Tap the number.", 6, 5, DIAMOND),
    sort_two(P_SORT, [_STy, _ST, _FLy, _FL, _DIy, _DI],
             lambda c: c["kind"] == STAR or c["kind"] == DIAMOND, "POINTY ONES", "THE REST"),
    odd_by(P_ODD, [_CI, _CIy, _CI, _CIy, _DI, _CI], "kind"),
    sort_two(P_SORT, [_HEy, _HE, _HXy, _HX, _TRy, _TR],
             lambda c: not _y(c) and c["kind"] != TRIANGLE, "PURPLE, NO TRIANGLE", "THE REST"),
    interleaved(P_NEXT, [FLOWER, DIAMOND], [PRIMARY, PRIMARY, ACCENT], 8, 7),
]

S234 = [
    sort_two(P_SORT, [_ST, _STy, _HE, _HEy, _DI, _DIy],
             lambda c: _pointy(c) and _y(c), "YELLOW, POINTY", "THE REST"),
    odd_by(P_ODD, [_FL, _FLy, _FL, _SQ, _FLy], "kind"),
    sort_two(P_SORT, [_CIy, _CI, _TRy, _TR, _HXy, _HX],
             lambda c: not _y(c), "NOT YELLOW", "YELLOW"),
    size_order(P_SMALL, [0.25, 0.55, 0.85, 1.0], HEXAGON),
    odd_by(P_ODD, [_HE, _HEy, _HX, _HE, _HEy, _HE], "kind"),
    sort_two(P_SORT, [_SQ, _SQy, _DI, _DIy, _FL, _FLy],
             lambda c: _corners4(c) and not _y(c), "PURPLE, 4 CORNERS", "THE REST"),
]


# 2.2 continued. The property that matters moves: shape in 2.2.1, colour here,
# and then the way a shape faces, which nothing about its outline gives away.

S222 = [
    odd_by(P_ODD, [_TR, _CI, _SQ, _STy, _HX], "color"),
    odd_by(P_ODD, [_HEy, _CIy, _SQy, _TR, _FLy], "color"),
    odd_by(P_ODD, [_ST, _HX, _DI, _CI, _TRy, _FL], "color"),
    odd_by(P_ODD, [_CIy, _TRy, _HXy, _DIy, _SQ], "color"),
    odd_by(P_ODD, [_SQ, _HE, _FL, _DI, _HXy], "color"),
    odd_by(P_ODD, [_FLy, _STy, _DIy, _HE, _CIy, _TRy], "color"),
    odd_by(P_ODD, [_HX, _TR, _CI, _HEy, _SQ, _DI], "color"),
]

S223 = [
    odd_by(P_ODD, [cell(TRIANGLE), cell(CIRCLE, ACCENT), cell(SQUARE),
                   cell(HEART, ACCENT, 90), cell(HEXAGON)], "rotation"),
    odd_by(P_ODD, [cell(STAR, ACCENT, 90), cell(DIAMOND, PRIMARY, 90),
                   cell(HEART, PRIMARY, 90), cell(FLOWER, ACCENT),
                   cell(CIRCLE, PRIMARY, 90)], "rotation"),
    odd_by(P_ODD, [cell(SQUARE, PRIMARY, 45), cell(TRIANGLE, ACCENT, 45),
                   cell(HEXAGON, PRIMARY, 45), cell(DIAMOND, ACCENT),
                   cell(STAR, PRIMARY, 45), cell(FLOWER, ACCENT, 45)], "rotation"),
    odd_by(P_ODD, [cell(HEART), cell(STAR, ACCENT), cell(TRIANGLE),
                   cell(HEXAGON, ACCENT, 180), cell(CIRCLE)], "rotation"),
    odd_by(P_ODD, [cell(FLOWER, ACCENT, 180), cell(SQUARE, PRIMARY, 180),
                   cell(DIAMOND, ACCENT, 180), cell(TRIANGLE, PRIMARY),
                   cell(HEART, ACCENT, 180)], "rotation"),
    odd_by(P_ODD, [cell(CIRCLE, PRIMARY, 90), cell(HEXAGON, ACCENT, 90),
                   cell(STAR, PRIMARY), cell(HEART, ACCENT, 90),
                   cell(SQUARE, PRIMARY, 90), cell(FLOWER, ACCENT, 90)], "rotation"),
    odd_by(P_ODD, [cell(DIAMOND, ACCENT), cell(TRIANGLE, PRIMARY),
                   cell(HEXAGON, ACCENT), cell(SQUARE, PRIMARY, 45),
                   cell(CIRCLE, ACCENT)], "rotation"),
]

S224 = [
    odd_by(P_ODD, [_TRy, _HXy, _CIy, _SQ, _FLy], "color"),
    odd_by(P_ODD, [_HE, _HEy, _HE, _ST, _HEy, _HE], "kind"),
    odd_by(P_ODD, [cell(STAR, PRIMARY, 180), cell(CIRCLE, ACCENT, 180),
                   cell(TRIANGLE, PRIMARY, 180), cell(FLOWER, ACCENT),
                   cell(DIAMOND, PRIMARY, 180)], "rotation"),
    sort_two(P_SORT, [_ST, _STy, _HX, _HXy, _CI, _CIy],
             lambda c: _pointy(c) and not _y(c), "PURPLE, POINTY", "THE REST"),
    odd_by(P_ODD, [_DI, _SQ, _HX, _CI, _FLy, _TR], "color"),
    odd_by(P_ODD, [_FL, _FLy, _FL, _HE, _FLy, _FL], "kind"),
]


# ================================================================ SECTION 3
# Codes: a rule someone else hands you, which you then apply.
#
# No letters anywhere. The spine asked for shift ciphers and decode-a-word; both
# test alphabet recall and reading speed rather than reasoning, neither fits in
# six seconds over another app, and for a child reading in a second or third
# language they fail the wrong child for the wrong reason.

def _both(r1, r2):
    """Two changes at once, applied in order."""
    return lambda it: r2(r1(it))


def analogy2(prompt, a, c, r1, r2, hint=None):
    """An analogy where TWO things change between the first pair.

    The three wrong options are the two half-answers and the unchanged shape, so
    a child who spots only one of the two changes lands on a wrong option rather
    than stumbling onto the right one.
    """
    return analogy(prompt, a, c, _both(r1, r2),
                   [_both(r1, r2)(c), r1(c), r2(c), dict(c)], hint)


# ---- 3.1 Analogies ---------------------------------------------------------

S311 = [
    analogy(P_AN, item(STAR), item(HEART), rel_colour,
            [item(HEART, ACCENT), item(HEART), item(STAR, ACCENT), item(CIRCLE, ACCENT)]),
    analogy(P_AN, item(CIRCLE), item(SQUARE), rel_count(2),
            [item(SQUARE, n=2), item(SQUARE), item(SQUARE, n=3), item(CIRCLE, n=2)]),
    analogy(P_AN, item(TRIANGLE), item(DIAMOND), rel_bigger,
            [item(DIAMOND, size=2), item(DIAMOND), item(TRIANGLE, size=2), item(HEXAGON, size=2)]),
    analogy(P_AN, item(HEXAGON), item(FLOWER), rel_turn,
            [item(FLOWER, rotation=90), item(FLOWER), item(HEXAGON, rotation=90),
             item(FLOWER, rotation=180)]),
    analogy(P_AN, item(HEART, ACCENT), item(STAR, ACCENT), rel_colour,
            [item(STAR), item(STAR, ACCENT), item(HEART), item(CIRCLE)]),
    analogy(P_AN, item(SQUARE), item(HEXAGON), rel_count(3),
            [item(HEXAGON, n=3), item(HEXAGON, n=2), item(HEXAGON), item(SQUARE, n=3)]),
    analogy(P_AN, item(DIAMOND, size=2), item(CIRCLE, size=2), rel_smaller,
            [item(CIRCLE), item(CIRCLE, size=2), item(DIAMOND), item(STAR)]),
]

# Two changes at once.
S312 = [
    analogy2(P_AN, item(STAR), item(HEART), rel_colour, rel_count(2)),
    analogy2(P_AN, item(CIRCLE), item(SQUARE), rel_colour, rel_bigger),
    analogy2(P_AN, item(TRIANGLE), item(HEXAGON), rel_count(2), rel_bigger),
    analogy2(P_AN, item(FLOWER), item(DIAMOND), rel_colour, rel_turn),
    analogy2(P_AN, item(HEART), item(CIRCLE), rel_count(3), rel_colour),
    analogy2(P_AN, item(SQUARE), item(STAR), rel_bigger, rel_turn),
    interleaved(P_NEXT, [HEXAGON, TRIANGLE], [ACCENT, PRIMARY, ACCENT], 9, 8),
]

S313 = [
    analogy2(P_AN, item(DIAMOND), item(FLOWER), rel_turn, rel_count(2)),
    analogy(P_AN, item(STAR, ACCENT, n=2), item(HEART, ACCENT, n=2), rel_count(2),
            [item(HEART, ACCENT, n=4), item(HEART, ACCENT, n=2),
             item(HEART, ACCENT, n=3), item(STAR, ACCENT, n=4)]),
    analogy2(P_AN, item(CIRCLE, size=2), item(HEXAGON, size=2), rel_smaller, rel_colour),
    analogy(P_AN, item(TRIANGLE, rotation=90), item(SQUARE, rotation=90), rel_turn,
            [item(SQUARE, rotation=180), item(SQUARE, rotation=90), item(SQUARE),
             item(TRIANGLE, rotation=180)]),
    analogy2(P_AN, item(FLOWER, ACCENT), item(STAR, ACCENT), rel_colour, rel_bigger),
    analogy2(P_AN, item(HEART), item(DIAMOND), rel_bigger, rel_count(2)),
    odd_by(P_ODD, [_HXy, _HX, _HXy, _DI, _HX, _HXy], "kind"),
]

S314 = [
    analogy2(P_AN, item(STAR), item(FLOWER), rel_colour, rel_count(3)),
    analogy(P_AN, item(HEXAGON), item(HEART), rel_bigger,
            [item(HEART, size=2), item(HEART), item(HEXAGON, size=2), item(CIRCLE, size=2)]),
    analogy2(P_AN, item(DIAMOND), item(SQUARE), rel_count(2), rel_turn),
    analogy(P_AN, item(CIRCLE, ACCENT), item(TRIANGLE, ACCENT), rel_colour,
            [item(TRIANGLE), item(TRIANGLE, ACCENT), item(CIRCLE), item(HEXAGON)]),
    analogy2(P_AN, item(HEART, size=2), item(HEXAGON, size=2), rel_smaller, rel_count(2)),
    analogy2(P_AN, item(FLOWER), item(CIRCLE), rel_turn, rel_bigger),
]

# ---- 3.2 Symbol codes ------------------------------------------------------

_K4a = [(STAR, 2), (HEART, 3), (CIRCLE, 4), (DIAMOND, 5)]
_K4b = [(TRIANGLE, 3), (SQUARE, 4), (HEXAGON, 6), (FLOWER, 7)]
_K4c = [(STAR, 1), (SQUARE, 5), (HEXAGON, 6), (HEART, 8)]

S321 = [
    code_read(P_CODE, _K4a, [STAR, HEART]),
    code_read(P_CODE, _K4a, [CIRCLE, DIAMOND]),
    code_read(P_CODE, _K4a, [HEART, HEART, STAR]),
    code_read(P_CODE, _K4a, [DIAMOND, STAR, HEART]),
    code_read(P_CODE, _K4a, [CIRCLE, CIRCLE, HEART]),
    code_read(P_CODE, _K4a, [STAR, STAR, DIAMOND, HEART]),
    code_read(P_CODE, _K4a, [HEART, CIRCLE, DIAMOND]),
]

S322 = [
    code_read(P_CODE, _K4b, [TRIANGLE, SQUARE]),
    code_read(P_CODE, _K4b, [HEXAGON, FLOWER]),
    code_read(P_CODE, _K4b, [SQUARE, SQUARE, TRIANGLE]),
    code_read(P_CODE, _K4b, [FLOWER, TRIANGLE, SQUARE]),
    code_read(P_CODE, _K4b, [HEXAGON, HEXAGON, TRIANGLE]),
    code_read(P_CODE, _K4b, [TRIANGLE, TRIANGLE, SQUARE, HEXAGON]),
    array("Count them. Tap the number.", 9, 4),
]

S323 = [
    code_read(P_CODE, _K4c, [STAR, HEART]),
    code_read(P_CODE, _K4c, [SQUARE, HEXAGON]),
    code_read(P_CODE, _K4c, [HEART, SQUARE, STAR]),
    code_read(P_CODE, _K4c, [HEXAGON, HEXAGON, STAR]),
    code_read(P_CODE, _K4c, [STAR, STAR, SQUARE, HEXAGON]),
    code_read(P_CODE, _K4c, [SQUARE, SQUARE, HEXAGON]),
    skip_line(P_LAND, 50, 6, 7, 6),
]

S324 = [
    code_read(P_CODE, _K4a, [DIAMOND, DIAMOND, CIRCLE]),
    code_read(P_CODE, _K4b, [FLOWER, SQUARE, TRIANGLE]),
    code_read(P_CODE, _K4c, [HEART, STAR, SQUARE, STAR]),
    code_read(P_CODE, _K4a, [CIRCLE, HEART, HEART, STAR]),
    code_read(P_CODE, _K4b, [HEXAGON, SQUARE, TRIANGLE, TRIANGLE]),
    code_read(P_CODE, _K4c, [SQUARE, HEXAGON, STAR, STAR]),
]

# ---- 3.3 Two-step codes ----------------------------------------------------
# Add what is there, take it from the total, then find the symbol worth the
# difference. Every key has four symbols so all four options mean something.

_O4a = [STAR, HEART, CIRCLE, DIAMOND]
_O4b = [TRIANGLE, SQUARE, HEXAGON, FLOWER]
_O4c = [STAR, SQUARE, HEXAGON, HEART]

S331 = [
    code_pick(P_CODEGAP, _K4a, [STAR, HEART], 1, 5, _O4a),
    code_pick(P_CODEGAP, _K4a, [CIRCLE, STAR], 1, 8, _O4a),
    code_pick(P_CODEGAP, _K4a, [HEART, DIAMOND], 0, 9, _O4a),
    code_pick(P_CODEGAP, _K4a, [DIAMOND, CIRCLE], 1, 7, _O4a),
    code_pick(P_CODEGAP, _K4a, [STAR, CIRCLE], 0, 7, _O4a),
    code_pick(P_CODEGAP, _K4a, [HEART, STAR], 0, 6, _O4a),
    code_pick(P_CODEGAP, _K4a, [CIRCLE, DIAMOND], 0, 7, _O4a),
]

S332 = [
    code_pick(P_CODEGAP, _K4b, [TRIANGLE, SQUARE], 1, 9, _O4b),
    code_pick(P_CODEGAP, _K4b, [HEXAGON, TRIANGLE], 1, 13, _O4b),
    code_pick(P_CODEGAP, _K4b, [FLOWER, SQUARE], 0, 10, _O4b),
    code_pick(P_CODEGAP, _K4b, [SQUARE, HEXAGON], 1, 11, _O4b),
    code_pick(P_CODEGAP, _K4b, [TRIANGLE, FLOWER], 0, 13, _O4b),
    code_pick(P_CODEGAP, _K4c, [STAR, SQUARE], 1, 7, _O4c),
    code_read(P_CODE, _K4c, [SQUARE, HEXAGON, HEART]),
]

S333 = [
    code_pick(P_CODEGAP, _K4a, [STAR, HEART, CIRCLE], 2, 10, _O4a),
    code_pick(P_CODEGAP, _K4a, [HEART, CIRCLE, DIAMOND], 1, 12, _O4a),
    code_pick(P_CODEGAP, _K4a, [DIAMOND, STAR, HEART], 0, 9, _O4a),
    code_pick(P_CODEGAP, _K4b, [TRIANGLE, SQUARE, HEXAGON], 2, 14, _O4b),
    code_pick(P_CODEGAP, _K4b, [SQUARE, HEXAGON, TRIANGLE], 1, 11, _O4b),
    code_pick(P_CODEGAP, _K4c, [STAR, HEXAGON, SQUARE], 2, 12, _O4c),
    sort_two(P_SORT, [_STy, _ST, _DIy, _DI, _HXy, _HX],
             lambda c: _pointy(c) and _y(c), "YELLOW, POINTY", "THE REST"),
]

S334 = [
    code_pick(P_CODEGAP, _K4a, [CIRCLE, CIRCLE, HEART], 2, 11, _O4a),
    code_pick(P_CODEGAP, _K4b, [HEXAGON, TRIANGLE, SQUARE], 0, 13, _O4b),
    code_pick(P_CODEGAP, _K4c, [HEART, SQUARE, STAR], 1, 14, _O4c),
    code_pick(P_CODEGAP, _K4a, [STAR, DIAMOND, HEART], 1, 10, _O4a),
    code_pick(P_CODEGAP, _K4b, [FLOWER, TRIANGLE, SQUARE], 1, 17, _O4b),
    code_pick(P_CODEGAP, _K4c, [HEXAGON, STAR, SQUARE], 0, 12, _O4c),
]


# ================================================================ SECTION 4
# Logic: everything so far, and the first questions needing a chain of thought.

# ---- 4.1 True or false -----------------------------------------------------
# CoderGate deleted its old "truth" screen because it "drew a condition in mid-
# air beside a list of facts", and a child cannot look at a condition. So the
# claim is one short question, the evidence is on screen, and the child answers
# it once per shape. Every rule here needs two properties or a negation.

S411 = [
    yes_no("Is it a yellow star? Move each shape.",
           [_STy, _ST, _STy, _CIy, _HE, _STy],
           lambda c: c["kind"] == STAR and _y(c)),
    yes_no("Is it a purple circle? Move each shape.",
           [_CI, _CIy, _CI, _SQ, _HEy, _CI],
           lambda c: _round(c) and not _y(c)),
    yes_no("Is it NOT yellow? Move each shape.",
           [_TR, _TRy, _HX, _HXy, _DI, _DIy],
           lambda c: not _y(c)),
    yes_no("Is it yellow and pointy? Move each shape.",
           [_STy, _TRy, _CIy, _ST, _HEy, _DIy],
           lambda c: _y(c) and _pointy(c)),
    yes_no("Is it NOT a circle? Move each shape.",
           [_CI, _CIy, _ST, _HE, _SQ, _CIy],
           lambda c: not _round(c)),
    yes_no("Is it purple with 4 corners? Move each shape.",
           [_SQ, _SQy, _DI, _DIy, _HX, _TR],
           lambda c: _corners4(c) and not _y(c)),
    yes_no("Is it a purple heart? Move each shape.",
           [_HE, _HEy, _HE, _FL, _HEy, _DI],
           lambda c: c["kind"] == HEART and not _y(c)),
]

S412 = [
    yes_no("Is it yellow but NOT round? Move each shape.",
           [_STy, _CIy, _TRy, _CI, _HXy, _ST],
           lambda c: _y(c) and not _round(c)),
    yes_no("Is it a yellow flower? Move each shape.",
           [_FLy, _FL, _FLy, _STy, _HXy, _FL],
           lambda c: c["kind"] == FLOWER and _y(c)),
    yes_no("Is it NOT pointy? Move each shape.",
           [_ST, _CI, _TR, _HE, _DI, _HX],
           lambda c: not _pointy(c)),
    yes_no("Is it purple and pointy? Move each shape.",
           [_ST, _STy, _TR, _TRy, _CI, _DI],
           lambda c: _pointy(c) and not _y(c)),
    yes_no("Is it a yellow hexagon? Move each shape.",
           [_HXy, _HX, _HXy, _FLy, _CIy, _HX],
           lambda c: c["kind"] == HEXAGON and _y(c)),
    yes_no("Is it NOT a square? Move each shape.",
           [_SQ, _SQy, _DI, _CI, _TR, _SQ],
           lambda c: c["kind"] != SQUARE),
    yes_no("Is it purple and round? Move each shape.",
           [_CI, _CIy, _CI, _STy, _HE, _CIy],
           lambda c: _round(c) and not _y(c)),
]

S413 = [
    yes_no("Is it yellow with 4 corners? Move each shape.",
           [_SQy, _DIy, _SQ, _DI, _HXy, _CIy],
           lambda c: _corners4(c) and _y(c)),
    yes_no("Is it NOT a heart and NOT yellow? Move each shape.",
           [_HE, _HEy, _CI, _CIy, _TR, _TRy],
           lambda c: c["kind"] != HEART and not _y(c)),
    odd_by(P_ODD, [_ST, _STy, _ST, _HX, _STy, _ST], "kind"),
    yes_no("Is it a purple triangle? Move each shape.",
           [_TR, _TRy, _TR, _DI, _SQ, _TRy],
           lambda c: c["kind"] == TRIANGLE and not _y(c)),
    yes_no("Is it pointy but NOT a star? Move each shape.",
           [_ST, _TR, _DI, _STy, _CI, _TRy],
           lambda c: _pointy(c) and c["kind"] != STAR),
    odd_by(P_ODD, [_CIy, _CI, _CIy, _FL, _CI], "kind"),
    yes_no("Is it yellow or a diamond? Move each shape.",
           [_DIy, _DI, _STy, _ST, _CIy, _CI],
           lambda c: _y(c) or c["kind"] == DIAMOND),
]

S414 = [
    yes_no("Is it a yellow star? Move each shape.",
           [_STy, _ST, _HXy, _STy, _CI, _HE],
           lambda c: c["kind"] == STAR and _y(c)),
    yes_no("Is it NOT yellow and NOT round? Move each shape.",
           [_CI, _CIy, _TR, _TRy, _SQ, _SQy],
           lambda c: not _y(c) and not _round(c)),
    interleaved(P_GAP, [STAR, DIAMOND], [PRIMARY, ACCENT, ACCENT], 10, 6),
    yes_no("Does it have 4 corners? Move each shape.",
           [_SQ, _DIy, _TR, _HX, _SQy, _CI],
           _corners4),
    odd_by(P_ODD, [_HXy, _HX, _HXy, _SQ, _HX, _HXy], "kind"),
    yes_no("Is it purple and NOT a square? Move each shape.",
           [_SQ, _SQy, _CI, _CIy, _HE, _HEy],
           lambda c: not _y(c) and c["kind"] != SQUARE),
]

# ---- 4.2 What is missing ---------------------------------------------------
# The gap sits inside a strip whose shape and colour run on different cycles, so
# it has to be read from both sides and on both properties at once.

S421 = [
    interleaved(P_GAP, [HEART, CIRCLE], [PRIMARY, ACCENT, PRIMARY], 11, 5),
    interleaved(P_GAP, [SQUARE, TRIANGLE], [ACCENT, PRIMARY, PRIMARY], 11, 6),
    interleaved(P_GAP, [HEXAGON, STAR], [PRIMARY, PRIMARY, ACCENT], 11, 4),
    interleaved(P_GAP, [FLOWER, DIAMOND], [ACCENT, ACCENT, PRIMARY], 11, 7),
    interleaved(P_GAP, [CIRCLE, HEART], [PRIMARY, ACCENT, ACCENT], 11, 3),
    interleaved(P_GAP, [TRIANGLE, HEXAGON], [ACCENT, PRIMARY, ACCENT], 11, 8),
    interleaved(P_GAP, [DIAMOND, SQUARE], [PRIMARY, ACCENT, PRIMARY], 11, 2),
]

S422 = [
    interleaved(P_GAP, [STAR, FLOWER], [PRIMARY, PRIMARY, ACCENT], 12, 9),
    interleaved(P_GAP, [HEART, HEXAGON], [ACCENT, PRIMARY, PRIMARY], 12, 10),
    interleaved(P_GAP, [CIRCLE, DIAMOND], [PRIMARY, ACCENT, ACCENT], 12, 1),
    interleaved(P_GAP, [SQUARE, FLOWER], [ACCENT, ACCENT, PRIMARY], 12, 5),
    interleaved(P_GAP, [TRIANGLE, STAR], [PRIMARY, ACCENT, PRIMARY], 12, 7),
    interleaved(P_GAP, [HEXAGON, CIRCLE], [ACCENT, PRIMARY, ACCENT], 12, 4),
    interleaved(P_GAP, [DIAMOND, HEART], [PRIMARY, PRIMARY, ACCENT], 12, 11),
]

S423 = [
    interleaved(P_NEXT, [FLOWER, TRIANGLE], [ACCENT, PRIMARY, PRIMARY], 11, 10),
    interleaved(P_GAP, [STAR, SQUARE], [PRIMARY, ACCENT, ACCENT], 12, 6),
    odd_by(P_ODD, [_TRy, _TR, _TRy, _FL, _TR, _TRy], "kind"),
    interleaved(P_GAP, [HEART, TRIANGLE], [ACCENT, PRIMARY, ACCENT], 11, 5),
    interleaved(P_NEXT, [CIRCLE, HEXAGON], [PRIMARY, ACCENT, PRIMARY], 12, 11),
    odd_by(P_ODD, [_DI, _DIy, _HE, _DI, _DIy], "kind"),
    interleaved(P_GAP, [SQUARE, HEART], [PRIMARY, PRIMARY, ACCENT], 11, 9),
]

S424 = [
    interleaved(P_GAP, [HEXAGON, DIAMOND], [ACCENT, PRIMARY, PRIMARY], 12, 8),
    interleaved(P_NEXT, [STAR, CIRCLE], [PRIMARY, ACCENT, ACCENT], 11, 10),
    odd_by(P_ODD, [_SQy, _SQ, _SQy, _HX, _SQ, _SQy], "kind"),
    interleaved(P_GAP, [FLOWER, HEART], [PRIMARY, ACCENT, PRIMARY], 12, 3),
    interleaved(P_GAP, [TRIANGLE, CIRCLE], [ACCENT, ACCENT, PRIMARY], 11, 6),
    interleaved(P_NEXT, [DIAMOND, FLOWER], [PRIMARY, PRIMARY, ACCENT], 12, 11),
]

# ---- 4.3 Putting it together -----------------------------------------------
# Every idea in the skill, shuffled, so no stop can be answered by knowing which
# screen comes next. The last boss is the last thing in the skill.

S431 = [
    interleaved(P_NEXT, [HEART, STAR], [ACCENT, PRIMARY, ACCENT], 9, 8),
    odd_by(P_ODD, [_FL, _FLy, _FL, _HX, _FLy, _FL], "kind"),
    code_read(P_CODE, _K4a, [HEART, DIAMOND, STAR]),
    sort_two(P_SORT, [_DIy, _DI, _CIy, _CI, _STy, _ST],
             lambda c: _pointy(c) and _y(c), "YELLOW, POINTY", "THE REST"),
    analogy2(P_AN, item(CIRCLE), item(TRIANGLE), rel_colour, rel_count(2)),
    skip_line(P_LAND, 50, 4, 6, 7),
    yes_no("Is it NOT a hexagon? Move each shape.",
           [_HX, _HXy, _CI, _ST, _HXy, _TR],
           lambda c: c["kind"] != HEXAGON),
]

S432 = [
    code_pick(P_CODEGAP, _K4b, [SQUARE, TRIANGLE], 1, 11, _O4b),
    interleaved(P_GAP, [CIRCLE, FLOWER], [ACCENT, PRIMARY, PRIMARY], 10, 5),
    size_order(P_SMALL, [0.2, 0.45, 0.7, 1.0], DIAMOND),
    analogy(P_AN, item(HEXAGON), item(SQUARE), rel_turn,
            [item(SQUARE, rotation=90), item(SQUARE), item(HEXAGON, rotation=90),
             item(SQUARE, rotation=180)]),
    odd_by(P_ODD, [_ST, _CI, _TR, _HEy, _DI], "color"),
    array("Count them. Tap the number.", 7, 7, STAR),
    sort_two(P_SORT, [_HEy, _HE, _FLy, _FL, _SQy, _SQ],
             lambda c: not _y(c) and c["kind"] != SQUARE, "PURPLE, NO SQUARE", "THE REST"),
]

S433 = [
    yes_no("Is it a yellow diamond? Move each shape.",
           [_DIy, _DI, _DIy, _STy, _CI, _DI],
           lambda c: c["kind"] == DIAMOND and _y(c)),
    code_read(P_CODE, _K4c, [HEXAGON, SQUARE, STAR]),
    interleaved(P_GAP, [DIAMOND, TRIANGLE], [PRIMARY, ACCENT, ACCENT], 12, 7),
    skip_line(P_LAND, 50, 45, -6, 7),
    analogy2(P_AN, item(STAR), item(HEXAGON), rel_bigger, rel_colour),
    odd_by(P_ODD, [cell(HEART, PRIMARY, 90), cell(STAR, ACCENT, 90),
                   cell(CIRCLE, PRIMARY, 90), cell(SQUARE, ACCENT),
                   cell(FLOWER, PRIMARY, 90)], "rotation"),
    array("Count them. Tap the number.", 6, 9, HEART),
]

S434 = [
    interleaved(P_NEXT, [SQUARE, HEXAGON], [ACCENT, PRIMARY, ACCENT], 11, 10),
    code_pick(P_CODEGAP, _K4c, [STAR, HEART, SQUARE], 2, 14, _O4c),
    analogy2(P_AN, item(FLOWER), item(HEART), rel_turn, rel_count(3)),
    yes_no("Is it purple and pointy? Move each shape.",
           [_STy, _ST, _TRy, _TR, _DIy, _DI],
           lambda c: _pointy(c) and not _y(c)),
    sort_two(P_SORT, [_CIy, _CI, _HXy, _HX, _TRy, _TR],
             lambda c: _y(c) and not _round(c), "YELLOW, NOT ROUND", "THE REST"),
    odd_by(P_ODD, [_CI, _CIy, _CI, _HX, _CIy, _CI], "kind"),
]
