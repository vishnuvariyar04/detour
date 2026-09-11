# -*- coding: utf-8 -*-
"""Number Sense — 48 stops, 324 questions, ages 7-8.

Three rules hold everywhere in this file.

ONE IDEA, AT LEAST THREE PICTURES. A stop is not the same question seven times;
a child who meets seven identical bonds learns the shape of the screen instead
of the idea on it. Each stop keeps one idea and shows it several ways.

NO QUESTION APPEARS TWICE. Not once in 324. The checker enforces it on the
prompt, the picture and the options together, so a near-copy fails the build.

EVERY PROMPT SAYS WHAT TO DO. "Start at 2 and hop on 3" told a child nothing
about what to touch. "Start at 2. Take 3 hops forward. Tap where you land."
does. The checker refuses a prompt with no instruction verb in it.

The climb: count and compare to 20, then build numbers to 100, then learn to
look, then use all of it for groups, sharing and fractions. Section 4 is where
the skill gets genuinely hard, because by then a child has the tools.
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


# ================================================================ SECTION 1
# Counting and comparing, up to twenty.

S111 = [
    count_objects(C_COUNT.format("stars"), 4, STAR),
    dice("Count the dots. Tap the number.", [3]),
    ten_frame(C_FRAME, 6),
    count_objects(C_COUNT.format("hearts"), 7, HEART),
    dice(C_DICE, [4, 2]),
    ten_frame(C_FRAME, 9),
    count_objects(C_COUNT.format("flowers"), 3, FLOWER),
]

S112 = [
    ten_frame("A full frame is ten. Count them all. Tap the number.", 10, 3),
    count_objects(C_COUNT.format("circles"), 8, CIRCLE),
    dice(C_DICE, [5, 4]),
    ten_frame("Count the counters in both frames. Tap the number.", 10, 7),
    array("2 rows of 4. Tap how many altogether.", 2, 4),
    count_objects(C_COUNT.format("stars"), 10, STAR),
    dice(C_DICE, [6, 6]),
]

S113 = [
    dice("Count the dots. Tap the number.", [6]),
    array("3 rows of 3. Tap how many altogether.", 3, 3),
    ten_frame("Count the counters in both frames. Tap the number.", 10, 9),
    dice(C_DICE, [2, 3]),
    array("2 rows of 5. Tap how many altogether.", 2, 5),
    count_objects(C_COUNT.format("hearts"), 9, HEART),
    frame_gap("How many more counters would fill the frame? Tap the number.", 6),
]

S114 = [  # boss
    count_objects(C_COUNT.format("flowers"), 5, FLOWER),
    dice(C_DICE, [3, 6]),
    ten_frame("Count the counters in both frames. Tap the number.", 10, 5),
    array("3 rows of 4. Tap how many altogether.", 3, 4),
    frame_gap("How many more counters would fill the frame? Tap the number.", 3),
    dice("Count the dots. Tap the number.", [4]),
]

S121 = [
    balance("Which pan goes down? Tap the heavier side.", 6, 2),
    count_colour("Count only the yellow ones. Tap the number.", 7, 4, glyph=STAR),
    balance("Which pan goes down? Tap the heavier side.", 3, 7, HEART),
    bar_model("How many more does the top bar have? Tap the number.", 9, 5),
    balance("The pans are level. Tap Same.", 5, 5),
    count_colour("Count only the purple ones. Tap the number.", 8, 5,
                 yellow=False, glyph=HEART),
    balance("Which pan goes down? Tap the heavier side.", 8, 3),
]

S122 = [
    bar_model("How many more does the top bar have? Tap the number.", 12, 8),
    balance("Which pan goes down? Tap the heavier side.", 4, 6),
    bar_model("Put the two bars end to end. Tap the total.", 7, 6, ask="total"),
    count_colour("Count only the yellow ones. Tap the number.", 9, 6, glyph=CIRCLE),
    balance("The pans are level. Tap Same.", 7, 7, HEART),
    bar_model("How many more does the top bar have? Tap the number.", 15, 9),
    balance("Which pan goes down? Tap the heavier side.", 2, 8, STAR),
]

S123 = [
    size_order("Tap them from smallest to biggest.", [0.5, 1.0, 0.3]),
    balance("Which pan goes down? Tap the heavier side.", 7, 4),
    size_order("Tap them from smallest to biggest.", [0.9, 0.4, 0.65, 0.25]),
    bar_model("Put the two bars end to end. Tap the total.", 9, 4, ask="total"),
    size_order("Tap them from smallest to biggest.", [0.35, 0.8, 1.0, 0.55], HEART),
    count_colour("Count only the yellow ones. Tap the number.", 6, 2, glyph=FLOWER),
    size_order("Tap them from smallest to biggest.", [0.6, 0.35, 0.9], STAR),
]

S124 = [  # boss
    balance("Which pan goes down? Tap the heavier side.", 8, 5),
    size_order("Tap them from smallest to biggest.", [0.4, 1.0, 0.7, 0.25]),
    bar_model("How many more does the top bar have? Tap the number.", 14, 6),
    count_colour("Count only the purple ones. Tap the number.", 10, 4,
                 yellow=False, glyph=STAR),
    size_order("Tap them from smallest to biggest.", [0.95, 0.5, 0.3], HEXAGON),
    balance("Which pan goes down? Tap the heavier side.", 3, 8, HEART),
]

S131 = [
    number_line("Start at 2. Take 3 hops forward. Tap where you land.", 0, 10, 2, 3),
    dice(C_DICE, [2, 2]),
    number_line("Start at 5. Take 4 hops forward. Tap where you land.", 0, 10, 5, 4),
    count_objects(C_COUNT.format("circles"), 6, CIRCLE),
    number_line("Start at 0. Take 7 hops forward. Tap where you land.", 0, 10, 0, 7),
    ten_frame(C_FRAME, 4),
    number_line("Start at 3. Take 5 hops forward. Tap where you land.", 0, 10, 3, 5),
]

S132 = [
    number_line("Start at 8. Take 6 hops forward. Tap where you land.", 0, 20, 8, 6,
                label_every=5),
    ten_frame("Count the counters in both frames. Tap the number.", 10, 2),
    number_line("Start at 11. Take 7 hops forward. Tap where you land.", 0, 20, 11, 7,
                label_every=5),
    array("4 rows of 3. Tap how many altogether.", 4, 3),
    number_line("Start at 6. Take 9 hops forward. Tap where you land.", 0, 20, 6, 9,
                label_every=5),
    bar_model("How many more does the top bar have? Tap the number.", 17, 11),
    number_line("Start at 14. Take 5 hops forward. Tap where you land.", 0, 20, 14, 5,
                label_every=5),
]

S133 = [
    mirror("Fold on the line. Tap the squares that finish the picture.",
           [(0, 1), (1, 1), (2, 2)]),
    number_line("Start at 9. Take 8 hops forward. Tap where you land.", 0, 20, 9, 8,
                label_every=5),
    mirror("Fold on the line. Tap the squares that finish the picture.",
           [(1, 0), (1, 1), (2, 3)]),
    size_order("Tap them from smallest to biggest.", [0.8, 0.3, 0.55], SQUARE),
    mirror("Fold on the line. Tap the squares that finish the picture.",
           [(0, 2), (2, 0), (2, 4)]),
    number_line("Start at 4. Take 6 hops forward. Tap where you land.", 0, 20, 4, 6,
                label_every=5),
    mirror("Fold on the line. Tap the squares that finish the picture.",
           [(2, 2), (1, 4)]),
]

S134 = [  # boss
    number_line("Start at 7. Take 9 hops forward. Tap where you land.", 0, 20, 7, 9,
                label_every=5),
    mirror("Fold on the line. Tap the squares that finish the picture.",
           [(0, 1), (1, 3), (2, 0)]),
    ten_frame("Count the counters in both frames. Tap the number.", 10, 8),
    number_line("Start at 13. Take 6 hops forward. Tap where you land.", 0, 20, 13, 6,
                label_every=5),
    mirror("Fold on the line. Tap the squares that finish the picture.",
           [(1, 2), (2, 2), (2, 4)]),
    size_order("Tap them from smallest to biggest.", [1.0, 0.45, 0.7], HEXAGON),
]


# ================================================================ SECTION 2
# Building numbers, up to a hundred.

S211 = [
    bond("6 is 4 and what? Tap the missing part.", 6, 4),
    dice(C_DICE, [4, 3]),
    count_colour("Count only the yellow ones. Tap the number.", 8, 3, glyph=STAR),
    bond("9 is 5 and what? Tap the missing part.", 9, 5),
    number_line("Start at 4. Take 3 hops forward. Tap where you land.", 0, 10, 4, 3),
    bond("8 is 2 and what? Tap the missing part.", 8, 2),
    bar_model("Put the two bars end to end. Tap the total.", 5, 3, ask="total"),
]

S212 = [
    bond("10 is 6 and what? Tap the missing part.", 10, 6),
    frame_gap("How many more counters would fill the frame? Tap the number.", 7),
    bond("10 is 3 and what? Tap the missing part.", 10, 3),
    dice(C_DICE, [6, 4]),
    frame_gap("How many more counters would fill the frame? Tap the number.", 2),
    bond("10 is 8 and what? Tap the missing part.", 10, 8),
    number_line("Start at 5. Take 5 hops forward. Tap where you land.", 0, 10, 5, 5),
]

S213 = [
    bond("Both parts are here. Tap the whole.", 7, 3, gap="whole"),
    frame_gap("How many more counters would fill the frame? Tap the number.", 4),
    bond("The whole and one part are here. Tap the other part.", 9, 6, gap="left"),
    bar_model("Put the two bars end to end. Tap the total.", 8, 6, ask="total"),
    bond("Both parts are here. Tap the whole.", 6, 5, gap="whole"),
    number_line("Start at 2. Take 6 hops forward. Tap where you land.", 0, 10, 2, 6),
    bond("The whole and one part are here. Tap the other part.", 10, 7, gap="left"),
]

S214 = [  # boss
    bond("10 is 4 and what? Tap the missing part.", 10, 4),
    dice(C_DICE, [5, 2]),
    bond("Both parts are here. Tap the whole.", 8, 7, gap="whole"),
    frame_gap("How many more counters would fill the frame? Tap the number.", 9),
    bond("The whole and one part are here. Tap the other part.", 7, 2, gap="left"),
    bar_model("How many more does the top bar have? Tap the number.", 11, 4),
]

S221 = [
    ten_frame("Ten and some more. Count them all. Tap the number.", 10, 4),
    rods("Count the blocks. Tap the number.", 13),
    ten_frame("Ten and some more. Count them all. Tap the number.", 10, 6),
    number_line("Start at 10. Take 8 hops forward. Tap where you land.", 0, 20, 10, 8,
                label_every=5),
    rods("Count the blocks. Tap the number.", 17),
    ten_frame("Ten and some more. Count them all. Tap the number.", 10, 1),
    bond("15 is 10 and what? Tap the missing part.", 15, 10),
]

S222 = [
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 24),
    number_line("Start at 12. Take 7 hops forward. Tap where you land.", 0, 20, 12, 7,
                label_every=5),
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 31),
    bond("18 is 10 and what? Tap the missing part.", 18, 10),
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 20),
    bar_model("How many more does the top bar have? Tap the number.", 20, 12),
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 28),
]

S223 = [
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 42),
    bond("Both parts are here. Tap the whole.", 16, 10, gap="whole"),
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 35),
    array("5 rows of 4. Tap how many altogether.", 5, 4),
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 50),
    bar_model("Put the two bars end to end. Tap the total.", 14, 11, ask="total"),
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 47),
]

S224 = [  # boss
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 36),
    ten_frame("Ten and some more. Count them all. Tap the number.", 10, 10),
    bond("14 is 10 and what? Tap the missing part.", 14, 10),
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 29),
    number_line("Start at 3. Take 14 hops forward. Tap where you land.", 0, 20, 3, 14,
                label_every=5),
    array("4 rows of 5. Tap how many altogether.", 4, 5),
]

S231 = [
    skip_line("Start at 0. Take 4 hops of 2. Tap where you land.", 20, 0, 2, 4),
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 23),
    skip_line("Start at 0. Take 3 hops of 5. Tap where you land.", 20, 0, 5, 3),
    bond("Both parts are here. Tap the whole.", 13, 9, gap="whole"),
    skip_line("Start at 0. Take 5 hops of 3. Tap where you land.", 20, 0, 3, 5),
    bar_model("How many more does the top bar have? Tap the number.", 18, 13),
    skip_line("Start at 2. Take 4 hops of 4. Tap where you land.", 20, 2, 4, 4),
]

S232 = [
    skip_line("Start at 0. Take 6 hops of 3. Tap where you land.", 20, 0, 3, 6),
    array("3 rows of 6. Tap how many altogether.", 3, 6),
    skip_line("Start at 0. Take 4 hops of 5. Tap where you land.", 20, 0, 5, 4),
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 38),
    skip_line("Start at 1. Take 6 hops of 3. Tap where you land.", 20, 1, 3, 6),
    bond("The whole and one part are here. Tap the other part.", 20, 13, gap="left"),
    skip_line("Start at 4. Take 4 hops of 4. Tap where you land.", 20, 4, 4, 4),
]

S233 = [
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 51),
    skip_line("Start at 0. Take 7 hops of 2. Tap where you land.", 20, 0, 2, 7),
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 44),
    bar_model("Put the two bars end to end. Tap the total.", 17, 9, ask="total"),
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 19),
    skip_line("Start at 5. Take 3 hops of 5. Tap where you land.", 20, 5, 5, 3),
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 33),
]

S234 = [  # boss
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 45),
    skip_line("Start at 0. Take 5 hops of 4. Tap where you land.", 20, 0, 4, 5),
    bond("Both parts are here. Tap the whole.", 19, 12, gap="whole"),
    array("5 rows of 3. Tap how many altogether.", 5, 3),
    bar_model("How many more does the top bar have? Tap the number.", 24, 15),
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 26),
]


# ================================================================ SECTION 3
# Learning to look.

S311 = [
    odd_one_out("Three are alike. Tap the one that is not.", [_SQ, _SQ, _TR, _SQ]),
    sort_two("Move the round shapes to the left tray.",
             [_CI, _SQ, _CIy, _TR], [0, 1, 0, 1], "ROUND", "NOT ROUND"),
    odd_one_out("Three are alike. Tap the one that is not.", [_CI, _CI, _CI, _SQ]),
    pattern("What comes next? Tap it.", [_ST, _HE, _ST, _HE, _ST], 4,
            [cell(HEART), cell(STAR), cell(CIRCLE)]),
    odd_one_out("Three are alike. Tap the one that is not.", [_ST, _STy, _ST, _ST]),
    sort_two("Move the yellow shapes to the left tray.",
             [_STy, _ST, _HEy, _SQ], [0, 1, 0, 1], "YELLOW", "PURPLE"),
    odd_one_out("Three are alike. Tap the one that is not.", [_TR, _TR, _TR, _HX]),
]

S312 = [
    sort_two("Move the round shapes to the left tray.",
             [_CI, _SQ, _CIy, _TR, _HX], [0, 1, 0, 1, 1], "ROUND", "NOT ROUND"),
    odd_one_out("Three are alike. Tap the one that is not.", [_HEy, _HEy, _HE, _HEy]),
    sort_two("Move the pointy shapes to the left tray.",
             [_TR, _CI, _ST, _CIy], [0, 1, 0, 1], "POINTY", "ROUND"),
    size_order("Tap them from smallest to biggest.", [0.4, 0.8, 0.25], SQUARE),
    sort_two("Move the yellow shapes to the left tray.",
             [_FLy, _HX, _TRy, _CI, _STy], [0, 1, 0, 1, 0], "YELLOW", "PURPLE"),
    odd_one_out("Three are alike. Tap the one that is not.", [_SQ, _SQ, _SQ, _CI]),
    sort_two("Move the round shapes to the left tray.",
             [_CIy, _TR, _CI, _SQ, _HXy], [0, 1, 0, 1, 1], "ROUND", "NOT ROUND"),
]

S313 = [
    pattern("What comes next? Tap it.", [_CI, _CI, _SQ, _CI, _CI], 4,
            [cell(SQUARE), cell(CIRCLE), cell(TRIANGLE)]),
    odd_one_out("Three are alike. Tap the one that is not.", [_DI, _DI, _DI, _ST]),
    pattern("One is missing. Tap what belongs in the gap.", [_ST, _STy, _ST, _STy], 3,
            [cell(STAR, ACCENT), cell(STAR), cell(HEART)]),
    sort_two("Move the yellow shapes to the left tray.",
             [_SQy, _HE, _TRy], [0, 1, 0], "YELLOW", "PURPLE"),
    pattern("What comes next? Tap it.", [_TR, _SQ, _TR, _SQ, _TR], 4,
            [cell(SQUARE), cell(TRIANGLE), cell(HEXAGON)]),
    odd_one_out("Three are alike. Tap the one that is not.", [_FL, _FL, _HX, _FL]),
    pattern("The shape turns each time. Tap what comes next.",
            [cell(TRIANGLE, PRIMARY, 0), cell(TRIANGLE, PRIMARY, 90),
             cell(TRIANGLE, PRIMARY, 180), cell(TRIANGLE, PRIMARY, 270)], 3,
            [cell(TRIANGLE, PRIMARY, 270), cell(TRIANGLE, PRIMARY, 0),
             cell(TRIANGLE, PRIMARY, 90)]),
]

S314 = [  # boss
    odd_one_out("Three are alike. Tap the one that is not.", [_HX, _HX, _ST, _HX]),
    pattern("What comes next? Tap it.", [_ST, _ST, _HE, _ST, _ST], 4,
            [cell(STAR), cell(HEART), cell(CIRCLE)]),
    sort_two("Move the pointy shapes to the left tray.",
             [_ST, _CI, _TR, _HX], [0, 1, 0, 1], "POINTY", "ROUND"),
    size_order("Tap them from smallest to biggest.", [0.7, 0.3, 1.0], FLOWER),
    odd_one_out("Three are alike. Tap the one that is not.", [_CIy, _CIy, _CIy, _CI]),
    pattern("One is missing. Tap what belongs in the gap.", [_SQ, _SQy, _SQ, _SQy], 1,
            [cell(SQUARE, ACCENT), cell(SQUARE), cell(TRIANGLE)]),
]

# ---- 3.2 shapes inside shapes: easy figures first, then the hidden ones ----

S321 = [
    shape_hunt("Tap every triangle. Some hide inside others.", "tree", "triangle"),
    shape_hunt("Tap every rectangle. Some hide inside others.", "arrow", "rectangle"),
    odd_one_out("Three are alike. Tap the one that is not.", [_TR, _TR, _SQ, _TR]),
    shape_hunt("Tap every triangle. Some hide inside others.", "boat", "triangle"),
    shape_count("How many rectangles are hiding here? Tap the number.",
                "flag", "rectangle"),
    pattern("What comes next? Tap it.", [_TR, _CI, _TR, _CI, _TR], 4,
            [cell(CIRCLE), cell(TRIANGLE), cell(SQUARE)]),
    size_order("Tap them from smallest to biggest.", [0.45, 0.75, 0.25], TRIANGLE),
]

S322 = [
    shape_hunt("Tap every square. Some hide inside others.", "house", "square"),
    shape_hunt("Tap every triangle. Some hide inside others.", "rocket", "triangle"),
    mirror("Fold on the line. Tap the squares that finish the picture.",
           [(0, 2), (1, 1), (2, 3)]),
    shape_count("How many squares are hiding here? Tap the number.",
                "window4", "square"),
    shape_hunt("Tap every rectangle. Some hide inside others.", "envelope", "rectangle"),
    odd_one_out("Three are alike. Tap the one that is not.", [_SQ, _SQ, _HX, _SQ]),
    shape_hunt("Tap every square. Some hide inside others.", "truck", "square"),
]

S323 = [
    shape_count("How many triangles are hiding here? Tap the number.",
                "triangle4", "triangle"),
    shape_hunt("Tap every triangle. Some hide inside others.", "pinwheel", "triangle"),
    mirror("Fold on the line. Tap the squares that finish the picture.",
           [(0, 0), (0, 4), (1, 2), (2, 1)]),
    shape_count("How many squares are hiding here? Tap the number.",
                "nested", "square"),
    shape_count("How many triangles are hiding here? Tap the number.",
                "hex6", "triangle"),
    size_order("Tap them from smallest to biggest.", [0.6, 0.9, 0.3], TRIANGLE),
    shape_count("How many squares are hiding here? Tap the number.",
                "pinwheel", "square"),
]

S324 = [  # boss
    shape_count("How many squares are hiding here? Tap the number.", "quilt", "square"),
    shape_hunt("Tap every square. Some hide inside others.", "quilt", "square"),
    mirror("Fold on the line. Tap the squares that finish the picture.",
           [(0, 2), (1, 0), (2, 4)]),
    shape_count("How many triangles are hiding here? Tap the number.",
                "quilt", "triangle"),
    shape_count("How many squares are hiding here? Tap the number.", "stairs", "square"),
    pattern("What comes next? Tap it.", [_HX, _TR, _HX, _TR, _HX], 4,
            [cell(TRIANGLE), cell(HEXAGON), cell(STAR)]),
]

S331 = [
    size_order("Tap them from smallest to biggest.", [0.3, 0.6, 1.0], HEXAGON),
    pattern("What comes next? Tap it.", [_CI, _HE, _CI, _HE, _CI], 4,
            [cell(HEART), cell(CIRCLE), cell(SQUARE)]),
    odd_one_out("Three are alike. Tap the one that is not.", [_TR, _TR, _CI, _TR]),
    size_order("Tap them from smallest to biggest.", [1.0, 0.25, 0.7, 0.45], SQUARE),
    pattern("One is missing. Tap what belongs in the gap.", [_HX, _ST, _HX, _ST], 2,
            [cell(HEXAGON), cell(STAR), cell(HEART)]),
    sort_two("Move the yellow shapes to the left tray.",
             [_HXy, _CI, _STy], [0, 1, 0], "YELLOW", "PURPLE"),
    size_order("Tap them from smallest to biggest.", [0.5, 0.8], FLOWER),
]

S332 = [
    mirror("Fold on the line. Tap the squares that finish the picture.",
           [(1, 1), (1, 2), (2, 0), (2, 4)]),
    pattern("What comes next? Tap it.", [_ST, _ST, _HE, _ST, _ST], 3,
            [cell(HEART), cell(STAR), cell(CIRCLE)]),
    odd_one_out("Three are alike. Tap the one that is not.", [_SQ, _DI, _SQ, _SQ]),
    mirror("Fold on the line. Tap the squares that finish the picture.",
           [(0, 3), (1, 3), (2, 3)]),
    sort_two("Move the round shapes to the left tray.",
             [_CI, _SQ, _HX, _CIy], [0, 1, 1, 0], "ROUND", "NOT ROUND"),
    size_order("Tap them from smallest to biggest.", [0.9, 0.3, 0.55], HEART),
    odd_one_out("Three are alike. Tap the one that is not.", [_HE, _HE, _HE, _ST]),
]

S333 = [
    shape_count("How many rectangles are hiding here? Tap the number.",
                "quilt", "rectangle"),
    size_order("Tap them from smallest to biggest.", [0.4, 1.0, 0.15, 0.7], STAR),
    pattern("One is missing. Tap what belongs in the gap.", [_CI, _SQ, _TR, _CI, _SQ], 3,
            [cell(CIRCLE), cell(SQUARE), cell(TRIANGLE)]),
    odd_one_out("Three are alike. Tap the one that is not.", [_HXy, _HXy, _HX, _HXy]),
    shape_count("How many triangles are hiding here? Tap the number.",
                "rocket", "triangle"),
    sort_two("Move the pointy shapes to the left tray.",
             [_TRy, _CIy, _ST, _HX, _CI], [0, 1, 0, 1, 1], "POINTY", "ROUND"),
    pattern("What comes next? Tap it.", [_HE, _CI, _HE, _CI, _HE], 4,
            [cell(CIRCLE), cell(HEART), cell(STAR)]),
]

S334 = [  # boss
    shape_count("How many squares are hiding here? Tap the number.", "truck", "square"),
    size_order("Tap them from smallest to biggest.", [0.8, 0.35, 1.0, 0.5], HEART),
    pattern("What comes next? Tap it.", [_SQ, _ST, _SQ, _ST, _SQ], 4,
            [cell(STAR), cell(SQUARE), cell(CIRCLE)]),
    sort_two("Move the round shapes to the left tray.",
             [_CIy, _TR, _CI, _ST], [0, 1, 0, 1], "ROUND", "NOT ROUND"),
    odd_one_out("Three are alike. Tap the one that is not.", [_CI, _CI, _HX, _CI]),
    mirror("Fold on the line. Tap the squares that finish the picture.",
           [(0, 1), (1, 3), (2, 2)]),
]


# ================================================================ SECTION 4
# Using it: groups, sharing and fractions.

S411 = [
    array("4 rows of 6. Tap how many altogether.", 4, 6),
    groups("5 bags with 3 in each. Tap how many altogether.", 5, 3),
    skip_line("Start at 0. Take 6 hops of 2. Tap where you land.", 20, 0, 2, 6),
    array("3 rows of 5. Tap how many altogether.", 3, 5),
    groups("4 bags with 4 in each. Tap how many altogether.", 4, 4, glyph=HEART),
    array("2 rows of 8. Tap how many altogether.", 2, 8),
    groups("3 bags with 6 in each. Tap how many altogether.", 3, 6, glyph=CIRCLE),
]

S412 = [
    array("5 rows of 5. Tap how many altogether.", 5, 5),
    groups("6 bags with 2 in each. Tap how many altogether.", 6, 2),
    skip_line("Start at 0. Take 8 hops of 2. Tap where you land.", 20, 0, 2, 8),
    array("4 rows of 4. Tap how many altogether.", 4, 4, glyph=STAR),
    groups("2 bags with 9 in each. Tap how many altogether.", 2, 9, glyph=FLOWER),
    skip_line("Start at 0. Take 4 hops of 3. Tap where you land.", 20, 0, 3, 4),
    array("6 rows of 3. Tap how many altogether.", 6, 3),
]

S413 = [
    groups("12 shared into 3 equal bags. Tap how many in one bag.", 3, 4, share=True),
    array("5 rows of 6. Tap how many altogether.", 5, 6),
    groups("20 shared into 4 equal bags. Tap how many in one bag.", 4, 5,
           share=True, glyph=HEART),
    skip_line("Start at 0. Take 5 hops of 5. Tap where you land.", 30, 0, 5, 5),
    groups("15 shared into 5 equal bags. Tap how many in one bag.", 5, 3,
           share=True, glyph=CIRCLE),
    array("3 rows of 7. Tap how many altogether.", 3, 7),
    groups("18 shared into 3 equal bags. Tap how many in one bag.", 3, 6, share=True),
]

S414 = [  # boss
    array("6 rows of 4. Tap how many altogether.", 6, 4),
    groups("24 shared into 4 equal bags. Tap how many in one bag.", 4, 6, share=True),
    skip_line("Start at 0. Take 7 hops of 3. Tap where you land.", 30, 0, 3, 7),
    groups("7 bags with 3 in each. Tap how many altogether.", 7, 3, glyph=STAR),
    array("2 rows of 9. Tap how many altogether.", 2, 9, glyph=HEART),
    groups("16 shared into 8 equal bags. Tap how many in one bag.", 8, 2, share=True),
]

S421 = [
    fraction("Which circle has more coloured in? Tap it.", 2, 1, other=(4, 1)),
    fraction_wall("Same length strips. Tap the one with the biggest pieces.",
                  [(4, 2), (2, 1), (6, 3)]),
    fraction("Which circle has more coloured in? Tap it.", 4, 3, other=(4, 1)),
    groups("Half of 8. Tap how many that is.", 2, 4, share=True, glyph=CIRCLE),
    fraction("Which circle has more coloured in? Tap it.", 3, 2, other=(6, 2)),
    fraction_wall("The top shows half. Tap the other strip showing half.",
                  [(2, 1), (5, 3), (4, 2)], ask="same"),
    fraction("Which circle has more coloured in? Tap it.", 8, 5, other=(2, 1)),
]

S422 = [
    fraction_wall("Same length strips. Tap the one with the biggest pieces.",
                  [(8, 3), (3, 1), (6, 2)]),
    fraction("Which circle has more coloured in? Tap it.", 6, 5, other=(3, 1)),
    groups("A quarter of 12. Tap how many that is.", 4, 3, share=True, glyph=STAR),
    fraction("Which circle has more coloured in? Tap it.", 8, 7, other=(4, 3)),
    fraction_wall("The top shows a quarter. Tap the other quarter.",
                  [(4, 1), (5, 2), (8, 2)], ask="same"),
    groups("Half of 14. Tap how many that is.", 2, 7, share=True, glyph=HEART),
    fraction("Which circle has more coloured in? Tap it.", 6, 1, other=(8, 3)),
]

S423 = [
    shape_count("How many triangles are hiding here? Tap the number.",
                "kite", "triangle"),
    fraction_wall("Same length strips. Tap the one with the biggest pieces.",
                  [(6, 2), (5, 2), (2, 1)]),
    mirror("Fold on the line. Tap the squares that finish the picture.",
           [(0, 0), (1, 1), (2, 2), (2, 4)]),
    shape_count("How many squares are hiding here? Tap the number.",
                "house", "square"),
    groups("A quarter of 16. Tap how many that is.", 4, 4, share=True, glyph=FLOWER),
    shape_hunt("Tap every square. Some hide inside others.", "rocket", "square"),
    pattern("What comes next? Tap it.", [_HX, _HE, _HX, _HE, _HX], 4,
            [cell(HEART), cell(HEXAGON), cell(STAR)]),
]

S424 = [  # boss
    array("7 rows of 3. Tap how many altogether.", 7, 3),
    fraction("Which circle has more coloured in? Tap it.", 5, 4, other=(2, 1)),
    mirror("Fold on the line. Tap the squares that finish the picture.",
           [(0, 2), (2, 0), (2, 3)]),
    groups("21 shared into 7 equal bags. Tap how many in one bag.", 7, 3, share=True),
    shape_count("How many triangles are hiding here? Tap the number.",
                "tree", "triangle"),
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 41),
]

S431 = [
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 37),
    bond("Both parts are here. Tap the whole.", 17, 8, gap="whole"),
    skip_line("Start at 0. Take 9 hops of 2. Tap where you land.", 30, 0, 2, 9),
    balance("Which pan goes down? Tap the heavier side.", 5, 8),
    ten_frame("Ten and some more. Count them all. Tap the number.", 10, 7),
    array("4 rows of 7. Tap how many altogether.", 4, 7),
    count_colour("Count only the yellow ones. Tap the number.", 9, 3, glyph=CIRCLE),
]

S432 = [
    shape_count("How many squares are hiding here? Tap the number.", "cross", "square"),
    pattern("What comes next? Tap it.", [_CI, _ST, _CI, _ST, _CI], 4,
            [cell(STAR), cell(CIRCLE), cell(HEART)]),
    size_order("Tap them from smallest to biggest.", [1.0, 0.4, 0.7, 0.2], HEXAGON),
    sort_two("Move the yellow shapes to the left tray.",
             [_CIy, _SQ, _STy, _TR], [0, 1, 0, 1], "YELLOW", "PURPLE"),
    mirror("Fold on the line. Tap the squares that finish the picture.",
           [(0, 4), (1, 0), (2, 2)]),
    odd_one_out("Three are alike. Tap the one that is not.", [_SQ, _SQ, _SQ, _HE]),
    shape_hunt("Tap every triangle. Some hide inside others.", "quilt", "triangle"),
]

S433 = [
    groups("30 shared into 5 equal bags. Tap how many in one bag.", 5, 6, share=True),
    skip_line("Start at 0. Take 6 hops of 5. Tap where you land.", 30, 0, 5, 6),
    bond("The whole and one part are here. Tap the other part.", 16, 9, gap="left"),
    fraction("Which circle has more coloured in? Tap it.", 4, 3, other=(6, 2)),
    array("8 rows of 3. Tap how many altogether.", 8, 3),
    bar_model("How many more does the top bar have? Tap the number.", 22, 13),
    rods("Each tall stick is ten. Count the blocks. Tap the number.", 18),
]

S434 = [  # boss
    array("6 rows of 5. Tap how many altogether.", 6, 5),
    groups("28 shared into 4 equal bags. Tap how many in one bag.", 4, 7, share=True),
    shape_count("How many triangles are hiding here? Tap the number.",
                "boat", "triangle"),
    skip_line("Start at 3. Take 5 hops of 4. Tap where you land.", 30, 3, 4, 5),
    fraction_wall("The top shows half. Tap the other strip showing half.",
                  [(2, 1), (8, 3), (6, 3)], ask="same"),
    bar_model("Put the two bars end to end. Tap the total.", 19, 14, ask="total"),
]
