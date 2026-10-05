# -*- coding: utf-8 -*-
"""Number Sense — 48 stops, 324 questions, band a, ages 5-6.

Three rules hold everywhere in this file.

ONE IDEA PER STOP. Every question in a stop practises the idea its teach card
shows, and nothing else. The skill used to mix three or four topics into each
stop ("Two dice" asked no dice questions, "Cut into pieces" taught fractions
and then asked about hops), so the idea a child had just been shown was
missing from most of the questions after it. Variety now comes from showing
the SAME idea several ways (a full ten frame, two parts that make ten, 5 + 5
on a line), and mixing happens only in the boss stop, which reviews its own
unit. `ns_emit.py` lists the question kinds each stop may use, and
`ns_simulate.py` fails the build if a question lands in the wrong stop.

NO QUESTION APPEARS TWICE. Not once in 324. The checker enforces it on the
prompt, the picture and the options together, so a near-copy fails the build.

EVERY PROMPT SAYS WHAT TO DO. "Start at 2 and hop on 3" told a child nothing
about what to touch. "Start at 2. Take 3 hops forward. Tap where you land."
does. The checker refuses a prompt with no instruction verb in it.

The climb: count and compare to 20, then build numbers with parts, tens and
same-size hops, then learn to look, then use all of it for groups, sharing and
fractions.
"""
from numkit import (
    STAR, HEART, CIRCLE, SQUARE, TRIANGLE, DIAMOND, HEXAGON, FLOWER,
    PRIMARY, ACCENT, cell,
    count_objects, count_colour, ten_frame, frame_gap, dice, rods, bond,
    number_line, balance, fraction, shape_hunt, pattern, odd_one_out,
    sort_two, size_order, mirror,
    array, groups, skip_line, bar_model, fraction_wall, shape_count,
)

_SQ, _TR, _CI = cell(SQUARE), cell(TRIANGLE), cell(CIRCLE)
_ST, _HE, _HX = cell(STAR), cell(HEART), cell(HEXAGON)
_DI, _FL = cell(DIAMOND), cell(FLOWER)
_SQy, _TRy = cell(SQUARE, ACCENT), cell(TRIANGLE, ACCENT)
_CIy, _STy = cell(CIRCLE, ACCENT), cell(STAR, ACCENT)
_HEy, _HXy = cell(HEART, ACCENT), cell(HEXAGON, ACCENT)
_DIy, _FLy = cell(DIAMOND, ACCENT), cell(FLOWER, ACCENT)

# Short, literal instructions. Every one names the thing to touch.
C_COUNT = "Count the {}. Tap the number."
C_DICE = "Add the two dice. Tap the total."
C_FRAME = "Count the counters. Tap the number."
C_TWO = "Count the counters in both frames. Tap the number."
C_GAP = "How many more counters would fill the frame? Tap the number."
C_PAN = "Which pan goes down? Tap it, or tap Same."
C_MORE = "How many more does the top bar have? Tap the number."
C_FEWER = "How many fewer does the bottom bar have? Tap the number."
C_SIZE = "Tap them from smallest to biggest."
C_HOP = "Start at {}. Take {} hops forward. Tap where you land."
C_FOLD = "Fold on the line. Tap the squares that finish the picture."
C_PART = "{} is {} and what? Tap the missing part."
C_WHOLE = "Both parts are here. Tap the whole."
C_OTHER = "The whole and one part are here. Tap the other part."
C_RODS = "Each tall stick is ten. Count the blocks. Tap the number."
C_SKIP = "Start at {}. Take {} hops of {}. Tap where you land."
C_ODD = "Three are alike. Tap the one that is not."
C_NEXT = "What comes next? Tap it."
C_GAPPAT = "One is missing. Tap what belongs in the gap."
C_ROWS = "{} rows of {}. Tap how many altogether."
C_BAGS = "{} bags with {} in each. Tap how many altogether."
C_SHARE = "{} shared into {} equal bags. Tap how many in one bag."
C_CIRCLE = "Which circle has more coloured in? Tap it."
C_BIG = "Same length strips. Tap the one with the biggest pieces."


def hop(start, n, to=10):
    return number_line(C_HOP.format(start, n), 0, to, start, n,
                       label_every=1 if to <= 10 else 5)


def skip(start, hops_, step, to=20):
    return skip_line(C_SKIP.format(start, hops_, step), to, start, step, hops_)


# ================================================================ SECTION 1
# Counting and comparing, up to twenty.

# 1.1.1 Count them: touch each one as you say the number.
S111 = [
    count_objects(C_COUNT.format("stars"), 4, STAR),
    dice("Count the dots. Tap the number.", [3]),
    ten_frame(C_FRAME, 6),
    count_objects(C_COUNT.format("hearts"), 7, HEART),
    dice(C_DICE, [4, 2]),
    ten_frame(C_FRAME, 9),
    count_objects(C_COUNT.format("flowers"), 3, FLOWER),
]

# 1.1.2 Count them all: every one, and only once each.
S112 = [
    count_objects(C_COUNT.format("circles"), 8, CIRCLE),
    dice(C_DICE, [5, 4]),
    count_objects(C_COUNT.format("stars"), 10, STAR),
    array("2 rows of 4. Count them all. Tap the number.", 2, 4),
    count_objects(C_COUNT.format("hearts"), 10, HEART),
    dice(C_DICE, [6, 6]),
    count_objects(C_COUNT.format("flowers"), 9, FLOWER),
]

# 1.1.3 A full frame is ten: five in a row, two rows make ten.
S113 = [
    ten_frame(C_FRAME, 8),
    ten_frame("Is the frame full? Count the counters. Tap the number.", 10),
    ten_frame(C_TWO, 10, 9),
    ten_frame("A full frame is ten. Count them all. Tap the number.", 10, 3),
    ten_frame(C_TWO, 10, 7),
    frame_gap(C_GAP, 6),
    frame_gap(C_GAP, 8),
]

S114 = [  # boss: how many
    count_objects(C_COUNT.format("flowers"), 5, FLOWER),
    dice(C_DICE, [3, 6]),
    ten_frame(C_TWO, 10, 5),
    array("3 rows of 4. Count them all. Tap the number.", 3, 4),
    frame_gap(C_GAP, 3),
    dice("Count the dots. Tap the number.", [4]),
]

# 1.2.1 Which side is heavier: the heavier side goes down.
S121 = [
    balance(C_PAN, 6, 2),
    balance(C_PAN, 3, 7, HEART),
    balance(C_PAN, 5, 5),
    balance(C_PAN, 8, 3),
    balance(C_PAN, 4, 8, HEART),
    balance(C_PAN, 6, 6, FLOWER),
    balance(C_PAN, 1, 6),
]

# 1.2.2 More and fewer: the longer bar has more; the extra bit is how many more.
S122 = [
    bar_model(C_MORE, 12, 8),
    bar_model(C_MORE, 15, 9),
    bar_model(C_FEWER, 10, 7),
    bar_model(C_MORE, 13, 6),
    bar_model(C_FEWER, 11, 9),
    bar_model(C_MORE, 16, 10),
    bar_model(C_FEWER, 14, 11),
]

# 1.2.3 Big and small: smallest first, then the next one up.
S123 = [
    size_order(C_SIZE, [0.5, 1.0, 0.3]),
    size_order(C_SIZE, [0.9, 0.4, 0.65, 0.25]),
    size_order(C_SIZE, [0.35, 0.8, 1.0, 0.55], HEART),
    size_order(C_SIZE, [0.6, 0.35, 0.9], STAR),
    size_order(C_SIZE, [0.45, 0.9, 0.2], CIRCLE),
    size_order(C_SIZE, [1.0, 0.6, 0.35, 0.8], SQUARE),
    size_order(C_SIZE, [0.3, 0.55, 0.85], HEART),
]

S124 = [  # boss: more or fewer
    balance(C_PAN, 8, 5),
    size_order(C_SIZE, [0.4, 1.0, 0.7, 0.25]),
    bar_model(C_MORE, 14, 6),
    balance(C_PAN, 7, 7, HEART),
    size_order(C_SIZE, [0.95, 0.5, 0.3], HEXAGON),
    bar_model(C_FEWER, 13, 5),
]

# 1.3.1 Hop along the line: each hop is one step to the next number.
S131 = [
    hop(2, 3),
    hop(5, 4),
    hop(0, 7),
    hop(3, 5),
    hop(1, 6),
    hop(6, 3),
    hop(4, 5),
]

# 1.3.2 Longer hops: count each hop out loud as it lands.
S132 = [
    hop(8, 6, 20),
    hop(11, 7, 20),
    hop(6, 9, 20),
    hop(14, 5, 20),
    hop(9, 8, 20),
    hop(4, 6, 20),
    hop(12, 7, 20),
]

# 1.3.3 Fold it over: each square has a partner across the line.
S133 = [
    mirror(C_FOLD, [(0, 1), (1, 1), (2, 2)]),
    mirror(C_FOLD, [(1, 0), (1, 1), (2, 3)]),
    mirror(C_FOLD, [(0, 2), (2, 0), (2, 4)]),
    mirror(C_FOLD, [(2, 2), (1, 4)]),
    mirror(C_FOLD, [(0, 2), (1, 1), (2, 3)]),
    mirror(C_FOLD, [(0, 3), (1, 3), (2, 3)]),
    mirror(C_FOLD, [(2, 0), (2, 1)]),
]

S134 = [  # boss: lines and folds
    hop(7, 9, 20),
    mirror(C_FOLD, [(0, 1), (1, 3), (2, 0)]),
    hop(2, 7),
    hop(13, 6, 20),
    mirror(C_FOLD, [(1, 2), (2, 2), (2, 4)]),
    mirror(C_FOLD, [(0, 0), (1, 4)]),
]


# ================================================================ SECTION 2
# Building numbers: parts, tens and same-size hops.

# 2.1.1 A number has parts: both parts make the whole.
S211 = [
    bond(C_PART.format(6, 4), 6, 4),
    dice(C_DICE, [4, 3]),
    count_colour("Count only the yellow ones. Tap the number.", 8, 3, glyph=STAR),
    bond(C_PART.format(9, 5), 9, 5),
    count_colour("Count only the purple ones. Tap the number.", 8, 5,
                 yellow=False, glyph=HEART),
    bond(C_PART.format(8, 2), 8, 2),
    bar_model("Put the two bars end to end. Tap the total.", 5, 3, ask="total"),
]

# 2.1.2 Friends of ten. (The onboarding demo for ages 5-6 is a question from
# this stop; test/onboarding_demo_test.dart checks it is still here.)
S212 = [
    bond(C_PART.format(10, 6), 10, 6),
    frame_gap(C_GAP, 7),
    bond(C_PART.format(10, 3), 10, 3),
    dice(C_DICE, [6, 4]),
    frame_gap(C_GAP, 2),
    bond(C_PART.format(10, 8), 10, 8),
    hop(5, 5),
]

# 2.1.3 Find the missing part: the whole is at the top; the parts are below.
S213 = [
    bond(C_WHOLE, 7, 3, gap="whole"),
    frame_gap(C_GAP, 4),
    bond(C_OTHER, 9, 6, gap="left"),
    bar_model("Put the two bars end to end. Tap the total.", 8, 6, ask="total"),
    bond(C_WHOLE, 6, 5, gap="whole"),
    bond(C_OTHER, 8, 3, gap="left"),
    bond(C_OTHER, 10, 7, gap="left"),
]

S214 = [  # boss: parts and wholes
    bond(C_PART.format(10, 4), 10, 4),
    dice(C_DICE, [5, 2]),
    bond(C_WHOLE, 8, 7, gap="whole"),
    frame_gap(C_GAP, 9),
    bond(C_OTHER, 7, 2, gap="left"),
    count_colour("Count only the purple ones. Tap the number.", 10, 4,
                 yellow=False, glyph=STAR),
]

# 2.2.1 Two dice: know each face, then put them together.
S221 = [
    dice(C_DICE, [6, 5]),
    dice(C_DICE, [4, 6]),
    dice(C_DICE, [5, 5]),
    dice(C_DICE, [6, 3]),
    dice(C_DICE, [4, 4]),
    dice(C_DICE, [3, 5]),
    dice(C_DICE, [2, 6]),
]

# 2.2.2 Ten and some more: a full frame is ten; count on from ten.
S222 = [
    ten_frame("Ten and some more. Count them all. Tap the number.", 10, 4),
    ten_frame("Ten and some more. Count them all. Tap the number.", 10, 6),
    bond(C_PART.format(15, 10), 15, 10),
    hop(10, 8, 20),
    ten_frame("Ten and some more. Count them all. Tap the number.", 10, 1),
    bond(C_PART.format(18, 10), 18, 10),
    ten_frame(C_TWO, 10, 2),
]

# 2.2.3 Tens and ones: each tall stick is ten blocks.
S223 = [
    rods(C_RODS, 42),
    bond(C_WHOLE, 16, 10, gap="whole"),
    rods(C_RODS, 35),
    rods(C_RODS, 24),
    rods(C_RODS, 50),
    rods(C_RODS, 31),
    rods(C_RODS, 47),
]

S224 = [  # boss: past ten
    rods(C_RODS, 36),
    ten_frame("Ten and some more. Count them all. Tap the number.", 10, 10),
    bond(C_PART.format(14, 10), 14, 10),
    rods(C_RODS, 29),
    dice(C_DICE, [5, 6]),
    rods(C_RODS, 28),
]

# 2.3.1 Hops of two and five: every hop jumps the same amount.
S231 = [
    skip(0, 4, 2),
    skip(0, 3, 5),
    skip(0, 7, 2),
    skip(5, 3, 5),
    skip(0, 4, 5),
    skip(4, 5, 2),
    skip(1, 6, 2),
]

# 2.3.2 Hops of three and four: say each number you land on.
S232 = [
    skip(0, 5, 3),
    skip(2, 4, 4),
    skip(0, 6, 3),
    skip(1, 6, 3),
    skip(4, 4, 4),
    skip(0, 3, 4),
    skip(3, 4, 3),
]

# 2.3.3 Sticks and cubes: count the sticks first, then the loose ones.
S233 = [
    rods(C_RODS, 51),
    rods(C_RODS, 23),
    rods(C_RODS, 44),
    rods(C_RODS, 38),
    rods(C_RODS, 19),
    rods(C_RODS, 16),
    rods(C_RODS, 33),
]

S234 = [  # boss: hops and tens
    rods(C_RODS, 45),
    skip(0, 5, 4),
    skip(0, 2, 5),
    skip(2, 5, 3),
    rods(C_RODS, 26),
    rods(C_RODS, 52),
]


# ================================================================ SECTION 3
# Learning to look.

# 3.1.1 One is different: three share something, one does not.
S311 = [
    odd_one_out(C_ODD, [_SQ, _SQ, _TR, _SQ]),
    odd_one_out(C_ODD, [_CI, _CI, _CI, _SQ]),
    odd_one_out(C_ODD, [_ST, _STy, _ST, _ST]),
    odd_one_out(C_ODD, [_HEy, _HEy, _HE, _HEy]),
    odd_one_out(C_ODD, [_TR, _TR, _TR, _HX]),
    odd_one_out(C_ODD, [_DI, _DI, _DI, _ST]),
    odd_one_out(C_ODD, [_FL, _FL, _HX, _FL]),
]

# 3.1.2 Put them in groups: check each one against the label.
S312 = [
    sort_two("Move the round shapes to the left tray.",
             [_CI, _SQ, _CIy, _TR, _HX], [0, 1, 0, 1, 1], "ROUND", "NOT ROUND"),
    sort_two("Move the yellow shapes to the left tray.",
             [_STy, _ST, _HEy, _SQ], [0, 1, 0, 1], "YELLOW", "PURPLE"),
    sort_two("Move the pointy shapes to the left tray.",
             [_TR, _CI, _ST, _CIy], [0, 1, 0, 1], "POINTY", "ROUND"),
    sort_two("Move the round shapes to the left tray.",
             [_CI, _SQ, _CIy, _TR], [0, 1, 0, 1], "ROUND", "NOT ROUND"),
    sort_two("Move the yellow shapes to the left tray.",
             [_FLy, _HX, _TRy, _CI, _STy], [0, 1, 0, 1, 0], "YELLOW", "PURPLE"),
    sort_two("Move the yellow shapes to the left tray.",
             [_SQy, _HE, _TRy], [0, 1, 0], "YELLOW", "PURPLE"),
    sort_two("Move the round shapes to the left tray.",
             [_CIy, _TR, _CI, _SQ, _HXy], [0, 1, 0, 1, 1], "ROUND", "NOT ROUND"),
]

# 3.1.3 What comes next: say the pattern out loud as you point.
S313 = [
    pattern(C_NEXT, [_CI, _CI, _SQ, _CI, _CI], 4,
            [cell(SQUARE), cell(CIRCLE), cell(TRIANGLE)]),
    pattern(C_NEXT, [_ST, _HE, _ST, _HE, _ST], 4,
            [cell(HEART), cell(STAR), cell(CIRCLE)]),
    pattern(C_GAPPAT, [_ST, _STy, _ST, _STy], 3,
            [cell(STAR, ACCENT), cell(STAR), cell(HEART)]),
    pattern(C_NEXT, [_TR, _SQ, _TR, _SQ, _TR], 4,
            [cell(SQUARE), cell(TRIANGLE), cell(HEXAGON)]),
    pattern(C_NEXT, [_TR, _CI, _TR, _CI, _TR], 4,
            [cell(CIRCLE), cell(TRIANGLE), cell(SQUARE)]),
    pattern("The shape turns each time. Tap what comes next.",
            [cell(TRIANGLE, PRIMARY, 0), cell(TRIANGLE, PRIMARY, 90),
             cell(TRIANGLE, PRIMARY, 180), cell(TRIANGLE, PRIMARY, 270)], 3,
            [cell(TRIANGLE, PRIMARY, 270), cell(TRIANGLE, PRIMARY, 0),
             cell(TRIANGLE, PRIMARY, 90)]),
    pattern(C_GAPPAT, [_DI, _DIy, _DI, _DIy], 1,
            [cell(DIAMOND), cell(DIAMOND, ACCENT), cell(STAR)]),
]

S314 = [  # boss: sorting and patterns
    odd_one_out(C_ODD, [_HX, _HX, _ST, _HX]),
    pattern(C_NEXT, [_ST, _ST, _HE, _ST, _ST], 4,
            [cell(STAR), cell(HEART), cell(CIRCLE)]),
    sort_two("Move the pointy shapes to the left tray.",
             [_ST, _CI, _TR, _CIy], [0, 1, 0, 1], "POINTY", "ROUND"),
    odd_one_out(C_ODD, [_SQ, _SQ, _SQ, _SQy]),
    odd_one_out(C_ODD, [_CIy, _CIy, _CIy, _CI]),
    pattern(C_GAPPAT, [_SQ, _SQy, _SQ, _SQy], 1,
            [cell(SQUARE, ACCENT), cell(SQUARE), cell(TRIANGLE)]),
]

# 3.2.1 Shapes inside shapes: a big shape can be made of smaller ones.
S321 = [
    shape_hunt("Tap every triangle. Some hide inside others.", "tree", "triangle"),
    shape_hunt("Tap every rectangle. Some hide inside others.", "arrow", "rectangle"),
    shape_hunt("Tap every triangle. Some hide inside others.", "boat", "triangle"),
    shape_count("How many rectangles are hiding here? Tap the number.",
                "flag", "rectangle"),
    shape_hunt("Tap every square. Some hide inside others.", "rocket", "square"),
    shape_count("How many triangles are hiding here? Tap the number.",
                "kite", "triangle"),
    shape_hunt("Tap every triangle. Some hide inside others.", "house", "triangle"),
]

# 3.2.2 Look again: some shapes share their edges.
S322 = [
    shape_hunt("Tap every square. Some hide inside others.", "house", "square"),
    shape_hunt("Tap every triangle. Some hide inside others.", "rocket", "triangle"),
    shape_count("How many squares are hiding here? Tap the number.",
                "window4", "square"),
    shape_hunt("Tap every rectangle. Some hide inside others.", "envelope", "rectangle"),
    shape_count("How many triangles are hiding here? Tap the number.",
                "triangle4", "triangle"),
    shape_hunt("Tap every square. Some hide inside others.", "truck", "square"),
    shape_count("How many squares are hiding here? Tap the number.",
                "nested", "square"),
]

# 3.2.3 Both halves match: fold the picture and the halves land on each other.
S323 = [
    mirror(C_FOLD, [(0, 0), (0, 4), (1, 2), (2, 1)]),
    mirror(C_FOLD, [(1, 1), (1, 2), (2, 0), (2, 4)]),
    mirror(C_FOLD, [(0, 0), (1, 1), (2, 2), (2, 4)]),
    mirror(C_FOLD, [(0, 2), (2, 0), (2, 3)]),
    mirror(C_FOLD, [(0, 4), (1, 0), (2, 2)]),
    mirror(C_FOLD, [(0, 1), (0, 3), (1, 2), (2, 2)]),
    mirror(C_FOLD, [(1, 0), (2, 1), (1, 4), (2, 3)]),
]

S324 = [  # boss: hidden shapes
    shape_count("How many squares are hiding here? Tap the number.", "quilt", "square"),
    shape_hunt("Tap every square. Some hide inside others.", "quilt", "square"),
    mirror(C_FOLD, [(0, 2), (1, 0), (2, 4)]),
    shape_count("How many triangles are hiding here? Tap the number.",
                "quilt", "triangle"),
    shape_count("How many squares are hiding here? Tap the number.", "stairs", "square"),
    mirror(C_FOLD, [(0, 1), (1, 3), (2, 2)]),
]

# 3.3.1 Order and rules: smallest first, and every pattern has a rule.
S331 = [
    size_order(C_SIZE, [0.3, 0.6, 1.0], HEXAGON),
    pattern(C_NEXT, [_CI, _HE, _CI, _HE, _CI], 4,
            [cell(HEART), cell(CIRCLE), cell(SQUARE)]),
    size_order(C_SIZE, [1.0, 0.25, 0.7, 0.45], SQUARE),
    pattern(C_GAPPAT, [_HX, _ST, _HX, _ST], 2,
            [cell(HEXAGON), cell(STAR), cell(HEART)]),
    size_order(C_SIZE, [0.5, 0.8], FLOWER),
    pattern(C_NEXT, [_SQ, _SQ, _CI, _SQ, _SQ], 4,
            [cell(CIRCLE), cell(SQUARE), cell(HEART)]),
    size_order(C_SIZE, [0.4, 0.8, 0.25], SQUARE),
]

# 3.3.2 Sort and continue: work out the rule before you answer.
S332 = [
    pattern(C_NEXT, [_ST, _ST, _HE, _ST, _ST], 3,
            [cell(HEART), cell(STAR), cell(CIRCLE)]),
    odd_one_out(C_ODD, [_SQ, _DI, _SQ, _SQ]),
    sort_two("Move the round shapes to the left tray.",
             [_CI, _SQ, _HX, _CIy], [0, 1, 1, 0], "ROUND", "NOT ROUND"),
    size_order(C_SIZE, [0.9, 0.3, 0.55], HEART),
    odd_one_out(C_ODD, [_HE, _HE, _HE, _ST]),
    sort_two("Move the yellow shapes to the left tray.",
             [_HXy, _CI, _STy], [0, 1, 0], "YELLOW", "PURPLE"),
    pattern(C_NEXT, [_HE, _HE, _DI, _HE, _HE], 4,
            [cell(STAR), cell(DIAMOND), cell(HEART)]),
]

# 3.3.3 Rules everywhere: size, shape or colour can be the rule.
S333 = [
    size_order(C_SIZE, [0.4, 1.0, 0.15, 0.7], STAR),
    pattern(C_GAPPAT, [_CI, _SQ, _TR, _CI, _SQ], 3,
            [cell(CIRCLE), cell(SQUARE), cell(TRIANGLE)]),
    odd_one_out(C_ODD, [_HXy, _HXy, _HX, _HXy]),
    sort_two("Move the pointy shapes to the left tray.",
             [_TRy, _CIy, _ST, _DI, _CI], [0, 1, 0, 0, 1], "POINTY", "ROUND"),
    pattern(C_NEXT, [_HE, _CI, _HE, _CI, _HE], 4,
            [cell(CIRCLE), cell(HEART), cell(STAR)]),
    odd_one_out(C_ODD, [_DIy, _DIy, _DIy, _DI]),
    sort_two("Move the yellow shapes to the left tray.",
             [_DIy, _SQ, _CIy, _HE], [0, 1, 0, 1], "YELLOW", "PURPLE"),
]

S334 = [  # boss: looking carefully
    odd_one_out(C_ODD, [_ST, _ST, _ST, _DI]),
    size_order(C_SIZE, [0.8, 0.35, 1.0, 0.5], HEART),
    pattern(C_NEXT, [_SQ, _ST, _SQ, _ST, _SQ], 4,
            [cell(STAR), cell(SQUARE), cell(CIRCLE)]),
    sort_two("Move the round shapes to the left tray.",
             [_CIy, _TR, _CI, _ST], [0, 1, 0, 1], "ROUND", "NOT ROUND"),
    odd_one_out(C_ODD, [_CI, _CI, _HX, _CI]),
    pattern(C_GAPPAT, [_TR, _TRy, _TR, _TRy], 2,
            [cell(TRIANGLE, ACCENT), cell(TRIANGLE), cell(CIRCLE)]),
]


# ================================================================ SECTION 4
# Using it: groups, sharing and fractions.

# 4.1.1 Rows of things: 3 rows of 4 is 4, then 4 more, then 4 more.
S411 = [
    array(C_ROWS.format(4, 6), 4, 6),
    array(C_ROWS.format(3, 5), 3, 5),
    array(C_ROWS.format(2, 8), 2, 8),
    array(C_ROWS.format(5, 5), 5, 5),
    array(C_ROWS.format(4, 4), 4, 4, STAR),
    array(C_ROWS.format(6, 3), 6, 3),
    array(C_ROWS.format(5, 6), 5, 6),
]

# 4.1.2 Equal groups: count one group, then count on by that much.
S412 = [
    groups(C_BAGS.format(5, 3), 5, 3),
    groups(C_BAGS.format(4, 4), 4, 4, HEART),
    skip(0, 6, 2),
    groups(C_BAGS.format(3, 6), 3, 6, CIRCLE),
    groups(C_BAGS.format(6, 2), 6, 2),
    skip(0, 4, 3),
    groups(C_BAGS.format(2, 9), 2, 9, FLOWER),
]

# 4.1.3 Sharing equally: share them out one at a time until none are left.
S413 = [
    groups(C_SHARE.format(12, 3), 3, 4, share=True),
    groups(C_SHARE.format(20, 4), 4, 5, HEART, share=True),
    groups(C_SHARE.format(15, 5), 5, 3, CIRCLE, share=True),
    groups(C_SHARE.format(18, 3), 3, 6, share=True),
    groups(C_SHARE.format(10, 2), 2, 5, FLOWER, share=True),
    groups(C_SHARE.format(24, 6), 6, 4, share=True),
    groups(C_SHARE.format(16, 4), 4, 4, HEART, share=True),
]

S414 = [  # boss: groups and sharing
    array(C_ROWS.format(6, 4), 6, 4),
    groups(C_SHARE.format(24, 4), 4, 6, share=True),
    skip(0, 7, 3, 30),
    groups(C_BAGS.format(7, 3), 7, 3),
    array(C_ROWS.format(2, 9), 2, 9, HEART),
    groups(C_SHARE.format(16, 8), 8, 2, share=True),
]

# 4.2.1 Which has more colour: more colour means more of the circle.
S421 = [
    fraction(C_CIRCLE, 2, 1, other=(4, 1)),
    fraction(C_CIRCLE, 4, 3, other=(4, 1)),
    fraction(C_CIRCLE, 3, 2, other=(6, 2)),
    fraction(C_CIRCLE, 8, 5, other=(2, 1)),
    fraction(C_CIRCLE, 6, 5, other=(3, 1)),
    fraction(C_CIRCLE, 8, 7, other=(4, 3)),
    fraction(C_CIRCLE, 6, 1, other=(8, 3)),
]

# 4.2.2 Bigger pieces: fewer pieces means each piece is bigger.
S422 = [
    fraction_wall(C_BIG, [(4, 2), (2, 1), (6, 3)]),
    fraction_wall(C_BIG, [(8, 3), (3, 1), (6, 2)]),
    fraction_wall(C_BIG, [(6, 2), (5, 2), (2, 1)]),
    fraction_wall(C_BIG, [(5, 2), (3, 1), (8, 4)]),
    fraction_wall(C_BIG, [(6, 1), (4, 1), (2, 1)]),
    fraction_wall(C_BIG, [(3, 2), (6, 2), (4, 1)]),
    fraction_wall(C_BIG, [(8, 6), (5, 3), (4, 2)]),
]

# 4.2.3 Halves and quarters: half is two equal parts, a quarter is one of four.
S423 = [
    groups("Half of 8. Tap how many that is.", 2, 4, CIRCLE, share=True),
    fraction_wall("The top shows half. Tap the other strip showing half.",
                  [(2, 1), (5, 3), (4, 2)], ask="same"),
    groups("A quarter of 12. Tap how many that is.", 4, 3, share=True),
    groups("Half of 14. Tap how many that is.", 2, 7, HEART, share=True),
    fraction_wall("The top shows a quarter. Tap the other quarter.",
                  [(4, 1), (5, 2), (8, 2)], ask="same"),
    groups("A quarter of 16. Tap how many that is.", 4, 4, FLOWER, share=True),
    groups("Half of 10. Tap how many that is.", 2, 5, STAR, share=True),
]

S424 = [  # boss: parts and pieces
    fraction(C_CIRCLE, 5, 4, other=(2, 1)),
    fraction_wall(C_BIG, [(6, 3), (4, 2), (3, 1)]),
    groups("Half of 18. Tap how many that is.", 2, 9, share=True),
    fraction_wall("The top shows half. Tap the other strip showing half.",
                  [(2, 1), (8, 3), (6, 3)], ask="same"),
    fraction(C_CIRCLE, 3, 1, other=(4, 3)),
    groups("A quarter of 20. Tap how many that is.", 4, 5, HEART, share=True),
]

# 4.3 All of it: every idea from the skill, mixed together on purpose.
S431 = [
    rods(C_RODS, 37),
    bond(C_WHOLE, 17, 8, gap="whole"),
    skip(0, 9, 2, 30),
    balance(C_PAN, 5, 8),
    ten_frame("Ten and some more. Count them all. Tap the number.", 10, 7),
    array(C_ROWS.format(4, 7), 4, 7),
    count_colour("Count only the yellow ones. Tap the number.", 9, 3, glyph=CIRCLE),
]

S432 = [
    shape_count("How many squares are hiding here? Tap the number.", "cross", "square"),
    pattern(C_NEXT, [_CI, _ST, _CI, _ST, _CI], 4,
            [cell(STAR), cell(CIRCLE), cell(HEART)]),
    size_order(C_SIZE, [1.0, 0.4, 0.7, 0.2], HEXAGON),
    sort_two("Move the yellow shapes to the left tray.",
             [_CIy, _SQ, _STy, _TR], [0, 1, 0, 1], "YELLOW", "PURPLE"),
    mirror(C_FOLD, [(0, 4), (1, 0), (2, 3)]),
    odd_one_out(C_ODD, [_SQ, _SQ, _SQ, _HE]),
    shape_hunt("Tap every triangle. Some hide inside others.", "quilt", "triangle"),
]

S433 = [
    groups(C_SHARE.format(30, 5), 5, 6, share=True),
    skip(0, 6, 5, 30),
    bond(C_OTHER, 16, 9, gap="left"),
    fraction(C_CIRCLE, 4, 3, other=(6, 2)),
    array(C_ROWS.format(8, 3), 8, 3),
    bar_model(C_MORE, 22, 13),
    rods(C_RODS, 18),
]

S434 = [  # boss: the last climb
    array(C_ROWS.format(6, 5), 6, 5),
    groups(C_SHARE.format(28, 4), 4, 7, share=True),
    shape_count("How many triangles are hiding here? Tap the number.",
                "boat", "triangle"),
    skip(3, 5, 4, 30),
    fraction_wall("The top shows half. Tap the other strip showing half.",
                  [(2, 1), (6, 2), (8, 4)], ask="same"),
    bar_model("Put the two bars end to end. Tap the total.", 19, 14, ask="total"),
]
