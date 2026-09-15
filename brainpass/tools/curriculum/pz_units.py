# -*- coding: utf-8 -*-
"""Puzzles & Logic — 48 stops, 324 questions, band b, ages 7-8.

REBUILT 2026-09-15. Everything that was here before (shape patterns, sorting,
analogies of shapes, symbol sums) was removed at Sai's request and replaced with
reasoning of the kind a Class 2-3 Olympiad paper and an aptitude paper ask,
pitched for seven and eight year olds:

  1 Number thinking     missing numbers, story sums, number patterns
  2 Order and position  taller/older/faster, places in a line, left, right, turning
  3 Relations and codes family relations, analogies, letter and number codes
  4 Logic               odd one out, days, months and the clock, think it through

Rules held everywhere, and enforced by the kit and pz_simulate.py:
- the question a child reads is at most eight words, and each clue line too
- at most three clue lines on a screen
- numbers stay between 0 and 100, never negative
- family relations stay to parents, grandparents, brothers and sisters, aunts,
  uncles and cousins; no in-laws, nothing a child has to guess from a name
- no question appears twice, and no puzzle appears twice with only the names
  or the order of the numbers changed
"""
from puzzles_kit import (
    equation, riddle, story, bars, series, series_rule,
    rank, rank_count, queue_back, queue_calc, queue_who, turns, shelf,
    relation, relation_who, word_analogy, number_analogy,
    letter_code, number_code, alphabet,
    odd_word, odd_number, weekday, month, clock, combos,
)

P_BOX = "Tap the number for the box."
P_RID = "Tap the number I am."
P_STORY = "Read the story. Tap the answer."
P_BAR = "Tap the missing number on the bars."
P_MISS = "Tap the missing number."
P_RULE = "Tap the rule for this row."
P_CLUE = "Read the clues. Tap the answer."
P_WAYS = "Read the story. Tap how many ways."
P_AN = "Tap the word that fits."
P_NAN = "Tap the number that fits."
P_CODE = "Tap how the word is written."
P_ODD = "Tap the one that does not belong."
P_DAY = "Read the clue. Tap the day."
P_MONTH = "Tap the month."
P_TIME = "Tap the time."
P_READ = "Tap the time the clock shows."


def back(n):
    return f"Tap {n}'s place from the back."


def face(n):
    return f"Tap the way {n} faces now."


# ================================================================ SECTION 1
# Number thinking.

# ---- 1.1 Missing numbers ----------------------------------------------------

S111 = [
    equation(P_BOX, 8, "+", 7, 15, "right"),
    equation(P_BOX, 9, "+", 5, 14, "left"),
    equation(P_BOX, 6, "+", 8, 14, "result"),
    equation(P_BOX, 7, "+", 9, 16, "right"),
    equation(P_BOX, 12, "+", 6, 18, "left"),
    riddle(P_RID, [("add", 4)], 12),
    riddle(P_RID, [("take", 5)], 9),
]

S112 = [
    equation(P_BOX, 15, "-", 6, 9, "right"),
    equation(P_BOX, 17, "-", 8, 9, "left"),
    equation(P_BOX, 30, "+", 40, 70, "right"),
    equation(P_BOX, 50, "-", 20, 30, "result"),
    equation(P_BOX, 13, "-", 7, 6, "result"),
    riddle(P_RID, [("double",)], 14),
    riddle(P_RID, [("half",)], 8),
]

S113 = [
    equation(P_BOX, 24, "+", 6, 30, "right"),
    equation(P_BOX, 45, "-", 5, 40, "right"),
    equation(P_BOX, 36, "+", 4, 40, "left"),
    equation(P_BOX, 60, "-", 25, 35, "left"),
    riddle(P_RID, [("add", 3), ("double",)], 16),
    riddle(P_RID, [("double",), ("take", 4)], 10),
    riddle(P_RID, [("take", 2), ("half",)], 6),
]

S114 = [
    equation(P_BOX, 19, "-", 11, 8, "right"),
    riddle(P_RID, [("add", 10)], 25),
    equation(P_BOX, 27, "+", 13, 40, "result"),
    riddle(P_RID, [("half",), ("add", 5)], 11),
    equation(P_BOX, 80, "-", 35, 45, "left"),
    riddle(P_RID, [("double",), ("add", 6)], 20),
]

# ---- 1.2 Story sums ---------------------------------------------------------
# Change stories first, because research on young children finds them easiest;
# then combine and compare, then equal groups and fair shares.

S121 = [
    story(P_STORY, "join", "Riya", "marbles", 8, 5),
    story(P_STORY, "leave", "Kabir", "kites", 12, 4),
    story(P_STORY, "join", "Om", "stickers", 15, 7),
    story(P_STORY, "leave", "Meera", "sweets", 20, 6),
    story(P_STORY, "gain", "Aman", "shells", 9, 16),
    story(P_STORY, "leave", "Tara", "balloons", 11, 9),
    bars(P_BAR, "Ravi", 14, "Asha", 9, "diff"),
]

S122 = [
    story(P_STORY, "total", "Diya", "balls", 7, 8),
    story(P_STORY, "part", "Neha", "fish", 18, 7),
    story(P_STORY, "more", "Veer", "pencils", 9, 4, "Isha"),
    story(P_STORY, "fewer", "Priya", "books", 16, 5, "Rohan"),
    story(P_STORY, "diff", "Sahil", "cards", 17, 9, "Zoya"),
    story(P_STORY, "total", "Yash", "cars", 12, 9),
    bars(P_BAR, "Lila", 20, "Karan", 13, "diff"),
]

S123 = [
    story(P_STORY, "groups", "", "apples", 3, 4),
    story(P_STORY, "legs", "", "hens", 5, 2),
    story(P_STORY, "share", "", "mangoes", 12, 3),
    story(P_STORY, "groups", "", "toffees", 5, 10),
    story(P_STORY, "share", "", "pencils", 20, 5),
    bars(P_BAR, "Mia", 25, "Dev", 18, "low"),
    bars(P_BAR, "Anya", 30, "Raj", 22, "top"),
]

S124 = [
    story(P_STORY, "gain", "Pooja", "beads", 14, 21),
    story(P_STORY, "fewer", "Nikhil", "stamps", 25, 8, "Sara"),
    story(P_STORY, "legs", "", "cows", 4, 4),
    bars(P_BAR, "Kavya", 40, "Ali", 26, "diff"),
    story(P_STORY, "share", "", "biscuits", 18, 2),
    story(P_STORY, "more", "Rani", "shells", 23, 9, "Tom"),
]

# ---- 1.3 Number patterns ----------------------------------------------------

S131 = [
    series(P_MISS, [2, 4, 6, 8, 10, 12], 5),
    series(P_MISS, [5, 10, 15, 20, 25, 30], 5),
    series(P_MISS, [10, 20, 30, 40, 50, 60], 3),
    series(P_MISS, [20, 18, 16, 14, 12, 10], 4),
    series(P_MISS, [3, 5, 7, 9, 11, 13], 2),
    series_rule(P_RULE, [4, 6, 8, 10, 12], [("add", 2), ("add", 4), ("double",), ("grow",)]),
    series_rule(P_RULE, [25, 20, 15, 10, 5], [("take", 5), ("take", 4), ("add", 5), ("take", 10)]),
]

S132 = [
    series(P_MISS, [3, 6, 9, 12, 15, 18], 5),
    series(P_MISS, [4, 8, 12, 16, 20, 24], 2),
    series(P_MISS, [30, 27, 24, 21, 18, 15], 5),
    series(P_MISS, [50, 45, 40, 35, 30, 25], 1),
    series(P_MISS, [1, 4, 7, 10, 13, 16], 4),
    series_rule(P_RULE, [2, 5, 8, 11, 14], [("add", 3), ("add", 2), ("grow",), ("double",)]),
    series_rule(P_RULE, [40, 36, 32, 28, 24], [("take", 4), ("take", 2), ("take", 6), ("add", 4)]),
]

S133 = [
    series(P_MISS, [1, 2, 4, 7, 11, 16], 5),
    series(P_MISS, [1, 2, 4, 8, 16, 32], 5),
    series(P_MISS, [2, 3, 5, 8, 12, 17], 4),
    series(P_MISS, [3, 6, 12, 24, 48], 3),
    series(P_MISS, [10, 11, 13, 16, 20, 25], 3),
    series_rule(P_RULE, [1, 2, 4, 8, 16], [("double",), ("add", 1), ("grow",), ("add", 2)]),
    series_rule(P_RULE, [5, 6, 8, 11, 15], [("grow",), ("add", 1), ("double",), ("add", 3)]),
]

S134 = [
    series(P_MISS, [6, 12, 18, 24, 30, 36], 4),
    series(P_MISS, [5, 10, 20, 40, 80], 4),
    series_rule(P_RULE, [7, 14, 21, 28, 35], [("add", 7), ("double",), ("add", 6), ("grow",)]),
    series(P_MISS, [45, 40, 35, 30, 25, 20], 3),
    series(P_MISS, [4, 5, 7, 10, 14, 19], 5),
    series(P_MISS, [90, 80, 70, 60, 50, 40], 5),
]


# ================================================================ SECTION 2
# Order and position.

# ---- 2.1 Taller, older, faster ----------------------------------------------
# Three people and two clues, which research finds seven and eight year olds can
# hold. The second stop mixes "taller" with "shorter", which is where children
# actually slip; four people come only at the end of the unit.

S211 = [
    rank("Tap who is the tallest.", "tall", ["Asha", "Ravi", "Om"],
         [("Asha", "Ravi", "more"), ("Ravi", "Om", "more")], "top"),
    rank("Tap who is the shortest.", "tall", ["Kabir", "Meera", "Dev"],
         [("Meera", "Kabir", "more"), ("Kabir", "Dev", "more")], "bottom"),
    rank("Tap who is the oldest.", "old", ["Zoya", "Imran", "Tara"],
         [("Imran", "Zoya", "more"), ("Zoya", "Tara", "more")], "top"),
    rank("Tap who is the fastest.", "fast", ["Neha", "Arjun", "Priya"],
         [("Priya", "Neha", "more"), ("Arjun", "Priya", "more")], "top"),
    rank("Tap who is the heaviest.", "heavy", ["Rohan", "Isha", "Veer"],
         [("Isha", "Veer", "more"), ("Rohan", "Isha", "more")], "top"),
    rank_count("Tap how many are taller than Om.", "tall", ["Om", "Diya", "Yash"],
               [("Diya", "Yash", "more"), ("Yash", "Om", "more")], "Om"),
    rank_count("Tap how many are older than Riya.", "old", ["Riya", "Sahil", "Anu"],
               [("Sahil", "Riya", "more"), ("Riya", "Anu", "more")], "Riya"),
]

S212 = [
    rank("Tap who is the tallest.", "tall", ["Mia", "Karan", "Lila"],
         [("Mia", "Karan", "less"), ("Lila", "Mia", "less")], "top"),
    rank("Tap who is the youngest.", "old", ["Nina", "Tom", "Rani"],
         [("Tom", "Nina", "less"), ("Rani", "Tom", "more")], "bottom"),
    rank("Tap who is the slowest.", "fast", ["Ali", "Pooja", "Nikhil"],
         [("Pooja", "Ali", "less"), ("Nikhil", "Pooja", "less")], "bottom"),
    rank("Tap who is the lightest.", "heavy", ["Sara", "Aman", "Kavya"],
         [("Aman", "Sara", "more"), ("Kavya", "Sara", "less")], "bottom"),
    rank("Tap who is the shortest.", "tall", ["Raj", "Asha", "Veer"],
         [("Asha", "Raj", "less"), ("Raj", "Veer", "less")], "bottom"),
    rank_count("Tap how many are faster than Dev.", "fast", ["Dev", "Isha", "Om"],
               [("Dev", "Isha", "less"), ("Om", "Dev", "less")], "Dev"),
    rank_count("Tap how many are heavier than Zoya.", "heavy", ["Zoya", "Kabir", "Meera"],
               [("Kabir", "Zoya", "less"), ("Meera", "Kabir", "less")], "Zoya"),
]

S213 = [
    rank("Tap who is the second tallest.", "tall", ["Om", "Riya", "Dev"],
         [("Riya", "Om", "more"), ("Om", "Dev", "more")], "second"),
    rank("Tap who is the second oldest.", "old", ["Tara", "Imran", "Neha"],
         [("Neha", "Tara", "less"), ("Imran", "Neha", "less")], "second"),
    rank("Tap who is the second fastest.", "fast", ["Arjun", "Mia", "Yash"],
         [("Yash", "Arjun", "more"), ("Mia", "Arjun", "less")], "second"),
    rank("Tap who is the second heaviest.", "heavy", ["Lila", "Rohan", "Priya"],
         [("Lila", "Priya", "less"), ("Rohan", "Lila", "less")], "second"),
    rank("Tap who is the tallest.", "tall", ["Asha", "Ravi", "Om", "Meera"],
         [("Ravi", "Om", "more"), ("Asha", "Ravi", "more"), ("Om", "Meera", "more")], "top"),
    rank("Tap who is the youngest.", "old", ["Kabir", "Zoya", "Dev", "Anu"],
         [("Zoya", "Dev", "less"), ("Kabir", "Zoya", "less"), ("Anu", "Dev", "more")], "bottom"),
    rank_count("Tap how many are taller than Nina.", "tall", ["Aman", "Rani", "Tom", "Nina"],
               [("Rani", "Aman", "more"), ("Aman", "Tom", "more"), ("Tom", "Nina", "more")], "Nina"),
]

S214 = [
    rank("Tap who is the oldest.", "old", ["Sahil", "Diya", "Ali"],
         [("Diya", "Ali", "less"), ("Sahil", "Diya", "less")], "top"),
    rank_count("Tap how many are older than Pooja.", "old", ["Pooja", "Veer", "Kavya"],
               [("Veer", "Pooja", "more"), ("Kavya", "Veer", "more")], "Pooja"),
    rank("Tap who is the second tallest.", "tall", ["Karan", "Isha", "Raj", "Neha"],
         [("Isha", "Karan", "less"), ("Raj", "Isha", "less"), ("Neha", "Karan", "more")], "second"),
    rank("Tap who is the heaviest.", "heavy", ["Anya", "Om", "Riya"],
         [("Riya", "Anya", "less"), ("Om", "Anya", "more")], "top"),
    rank("Tap who is the fastest.", "fast", ["Tom", "Meera", "Arjun", "Zoya"],
         [("Meera", "Tom", "less"), ("Arjun", "Zoya", "more"), ("Zoya", "Tom", "more")], "top"),
    rank_count("Tap how many are heavier than Imran.", "heavy", ["Imran", "Lila", "Dev", "Sara"],
               [("Lila", "Imran", "less"), ("Dev", "Lila", "less"), ("Sara", "Dev", "less")], "Imran"),
]

# ---- 2.2 Places in a line ---------------------------------------------------

S221 = [
    queue_back(back("Mia"), "Mia", 7, 2),
    queue_back(back("Om"), "Om", 6, 4),
    queue_back(back("Riya"), "Riya", 9, 3),
    queue_back(back("Kabir"), "Kabir", 8, 8),
    queue_back(back("Neha"), "Neha", 10, 6),
    queue_who("Tap who is 2nd from the back.", ["Asha", "Ravi", "Tara", "Dev", "Zoya"], 2, "back"),
    queue_who("Tap who is 3rd from the front.", ["Imran", "Diya", "Yash", "Lila", "Aman", "Sara"], 3, "front"),
]

S222 = [
    queue_who("Tap who is 4th from the front.", ["Nina", "Raj", "Anu", "Veer", "Mia"], 4, "front"),
    queue_who("Tap who is 3rd from the back.", ["Pooja", "Tom", "Kavya", "Ali", "Rohan", "Isha"], 3, "back"),
    queue_who("Tap who is 1st from the back.", ["Sahil", "Rani", "Karan", "Meera"], 1, "back"),
    queue_calc(P_CLUE, "total", 3, 5, "Arjun"),
    queue_calc(P_CLUE, "total", 4, 4, "Priya"),
    queue_calc(P_CLUE, "total", 5, 6, "Om"),
    queue_calc(P_CLUE, "total", 1, 8, "Zoya"),
]

S223 = [
    queue_calc(P_CLUE, "between", 2, 6, "Ravi", "Asha"),
    queue_calc(P_CLUE, "between", 8, 3, "Diya", "Kabir"),
    queue_calc(P_CLUE, "between", 1, 4, "Tara", "Imran"),
    queue_calc(P_CLUE, "between", 4, 10, "Yash", "Lila"),
    queue_back(back("Veer"), "Veer", 5, 1),
    queue_back(back("Anu"), "Anu", 10, 9),
    queue_calc(P_CLUE, "total", 7, 3, "Nikhil"),
]

S224 = [
    queue_who("Tap who is 2nd from the front.", ["Raj", "Mia", "Aman", "Pooja", "Ali"], 2, "front"),
    queue_back(back("Sara"), "Sara", 8, 5),
    queue_calc(P_CLUE, "between", 2, 9, "Tom", "Nina"),
    queue_calc(P_CLUE, "total", 6, 4, "Kavya"),
    queue_who("Tap who is 4th from the back.", ["Isha", "Rohan", "Sahil", "Rani", "Karan", "Meera"], 4, "back"),
    queue_back(back("Dev"), "Dev", 9, 7),
]

# ---- 2.3 Left, right and turning --------------------------------------------

S231 = [
    shelf("Tap the shape just left of the heart.", ["star", "circle", "heart", "square", "diamond"], "heart", "left", 1),
    shelf("Tap the shape just right of the star.", ["triangle", "star", "diamond", "circle", "heart"], "star", "right", 1),
    shelf("Tap the shape just left of the square.", ["heart", "diamond", "triangle", "square", "star"], "square", "left", 1),
    shelf("Tap the shape just right of the circle.", ["circle", "heart", "star", "triangle", "square"], "circle", "right", 1),
    shelf("Tap the shape just left of the diamond.", ["square", "star", "circle", "triangle", "diamond"], "diamond", "left", 1),
    turns(face("Om"), "Om", "North", ["right"]),
    turns(face("Riya"), "Riya", "East", ["left"]),
]

S232 = [
    turns(face("Kabir"), "Kabir", "South", ["right"]),
    turns(face("Asha"), "Asha", "West", ["right"]),
    turns(face("Dev"), "Dev", "North", ["left"]),
    turns(face("Tara"), "Tara", "East", ["right", "right"]),
    turns(face("Imran"), "Imran", "South", ["left", "left"]),
    shelf("Tap the shape just right of the triangle.", ["diamond", "square", "triangle", "heart", "circle"], "triangle", "right", 1),
    shelf("Tap the shape just left of the star.", ["circle", "star", "heart", "diamond", "triangle"], "star", "left", 1),
]

S233 = [
    turns(face("Zoya"), "Zoya", "North", ["around"]),
    turns(face("Yash"), "Yash", "West", ["around"]),
    turns(face("Neha"), "Neha", "East", ["right", "left"]),
    turns(face("Aman"), "Aman", "South", ["around", "left"]),
    shelf("Tap two places left of the heart.", ["square", "triangle", "star", "heart", "circle"], "heart", "left", 2),
    shelf("Tap two places right of the diamond.", ["diamond", "circle", "square", "star", "heart"], "diamond", "right", 2),
    shelf("Tap two places right of the circle.", ["heart", "circle", "triangle", "diamond", "star"], "circle", "right", 2),
]

S234 = [
    turns(face("Lila"), "Lila", "West", ["left", "left"]),
    shelf("Tap two places left of the star.", ["triangle", "heart", "diamond", "square", "star"], "star", "left", 2),
    turns(face("Veer"), "Veer", "North", ["right", "around"]),
    shelf("Tap the shape just right of the heart.", ["star", "triangle", "circle", "heart", "diamond"], "heart", "right", 1),
    turns(face("Diya"), "Diya", "South", ["left"]),
    turns(face("Karan"), "Karan", "East", ["around", "left"]),
]


# ================================================================ SECTION 3
# Relations and codes.

# ---- 3.1 Family relations ---------------------------------------------------
# The puzzles from aptitude papers, pitched down: two or three short facts, and
# only relations a seven year old uses at home. Two conventions the engine uses,
# the same ones those papers use: a brother and a sister share their parents,
# and a parent's husband or wife is also a parent.


def rel(x, y):
    return f"Tap who {x} is to {y}."


S311 = [
    relation(rel("Raj", "Riya"), [("Raj", "father", "Aman"), ("Riya", "sister", "Aman")], "Raj", "Riya"),
    relation(rel("Om", "Meera"), [("Om", "son", "Meera")], "Om", "Meera"),
    relation(rel("Diya", "Kabir"), [("Diya", "sister", "Arjun"), ("Arjun", "son", "Kabir")], "Diya", "Kabir"),
    relation(rel("Priya", "Tom"), [("Priya", "mother", "Isha"), ("Tom", "brother", "Isha")], "Priya", "Tom"),
    relation(rel("Yash", "Neha"), [("Neha", "daughter", "Ravi"), ("Yash", "son", "Ravi")], "Yash", "Neha"),
    relation_who("Tap Anu's father.",
                 [("Dev", "husband", "Lila"), ("Lila", "mother", "Anu"), ("Karan", "brother", "Anu")],
                 "Anu", "father"),
    relation_who("Tap Veer's sister.",
                 [("Zoya", "daughter", "Raj"), ("Veer", "son", "Raj"), ("Mia", "mother", "Veer")],
                 "Veer", "sister"),
]

S312 = [
    relation(rel("Asha", "Om"), [("Asha", "mother", "Raj"), ("Raj", "father", "Om")], "Asha", "Om"),
    relation(rel("Kabir", "Rani"), [("Kabir", "father", "Imran"), ("Rani", "daughter", "Imran")], "Kabir", "Rani"),
    relation(rel("Nina", "Sahil"), [("Nina", "daughter", "Tara"), ("Tara", "daughter", "Sahil")], "Nina", "Sahil"),
    relation(rel("Ali", "Pooja"), [("Ali", "son", "Karan"), ("Karan", "son", "Pooja")], "Ali", "Pooja"),
    relation(rel("Meera", "Dev"),
             [("Meera", "mother", "Rohan"), ("Rohan", "father", "Isha"), ("Dev", "brother", "Isha")],
             "Meera", "Dev"),
    relation_who("Tap Kavya's grandfather.",
                 [("Om", "father", "Aman"), ("Aman", "father", "Kavya"), ("Sara", "mother", "Kavya")],
                 "Kavya", "grandfather"),
    relation_who("Tap Tom's grandmother.",
                 [("Lila", "mother", "Diya"), ("Diya", "mother", "Tom"), ("Yash", "brother", "Tom")],
                 "Tom", "grandmother"),
]

S313 = [
    relation(rel("Anu", "Om"), [("Anu", "sister", "Raj"), ("Raj", "father", "Om")], "Anu", "Om"),
    relation(rel("Karan", "Riya"), [("Karan", "brother", "Meera"), ("Meera", "mother", "Riya")], "Karan", "Riya"),
    relation(rel("Zoya", "Dev"),
             [("Zoya", "daughter", "Asha"), ("Asha", "sister", "Ravi"), ("Ravi", "father", "Dev")],
             "Zoya", "Dev"),
    relation(rel("Priya", "Kabir"), [("Kabir", "son", "Imran"), ("Priya", "sister", "Imran")], "Priya", "Kabir"),
    relation(rel("Rohan", "Mia"), [("Mia", "daughter", "Nina"), ("Rohan", "brother", "Nina")], "Rohan", "Mia"),
    relation_who("Tap Isha's uncle.",
                 [("Veer", "brother", "Pooja"), ("Pooja", "mother", "Isha"), ("Sahil", "father", "Isha")],
                 "Isha", "uncle"),
    relation_who("Tap Tara's aunt.",
                 [("Lila", "sister", "Yash"), ("Yash", "father", "Tara"), ("Diya", "sister", "Tara")],
                 "Tara", "aunt"),
]

S314 = [
    relation(rel("Aman", "Sara"),
             [("Aman", "father", "Ali"), ("Ali", "father", "Neha"), ("Sara", "sister", "Neha")],
             "Aman", "Sara"),
    relation_who("Tap Om's cousin.",
                 [("Riya", "daughter", "Kabir"), ("Kabir", "brother", "Meera"), ("Meera", "mother", "Om")],
                 "Om", "cousin"),
    relation(rel("Diya", "Yash"),
             [("Diya", "mother", "Rani"), ("Rani", "sister", "Tom"), ("Tom", "father", "Yash")],
             "Diya", "Yash"),
    relation(rel("Imran", "Kavya"), [("Imran", "husband", "Priya"), ("Priya", "mother", "Kavya")], "Imran", "Kavya"),
    relation_who("Tap Veer's grandmother.",
                 [("Asha", "mother", "Dev"), ("Dev", "brother", "Nina"), ("Nina", "mother", "Veer")],
                 "Veer", "grandmother"),
    relation(rel("Sahil", "Rani"),
             [("Sahil", "husband", "Lila"), ("Lila", "mother", "Karan"), ("Karan", "father", "Rani")],
             "Sahil", "Rani"),
]

# ---- 3.2 Analogies ----------------------------------------------------------

S321 = [
    word_analogy(P_AN, "baby", "cow", "dog"),
    word_analogy(P_AN, "baby", "hen", "sheep"),
    word_analogy(P_AN, "baby", "cat", "duck"),
    word_analogy(P_AN, "home", "bird", "bee"),
    word_analogy(P_AN, "home", "dog", "horse"),
    number_analogy(P_NAN, "add", 3, [2, 5], 7),
    number_analogy(P_NAN, "times", 2, [3, 4], 6),
]

S322 = [
    word_analogy(P_AN, "opposite", "hot", "big"),
    word_analogy(P_AN, "opposite", "up", "day"),
    word_analogy(P_AN, "opposite", "happy", "fast"),
    word_analogy(P_AN, "sense", "eye", "ear"),
    word_analogy(P_AN, "sense", "nose", "tongue"),
    number_analogy(P_NAN, "take", 4, [9, 12], 15),
    number_analogy(P_NAN, "add", 10, [5, 12], 23),
]

S323 = [
    word_analogy(P_AN, "work", "doctor", "teacher"),
    word_analogy(P_AN, "work", "farmer", "cook"),
    word_analogy(P_AN, "colour", "grass", "banana"),
    word_analogy(P_AN, "colour", "snow", "coal"),
    number_analogy(P_NAN, "times", 3, [2, 4], 5),
    number_analogy(P_NAN, "times", 10, [3, 5], 4),
    number_analogy(P_NAN, "take", 2, [10, 7], 18),
]

S324 = [
    word_analogy(P_AN, "baby", "lion", "frog"),
    word_analogy(P_AN, "opposite", "wet", "full"),
    number_analogy(P_NAN, "add", 6, [4, 9], 14),
    word_analogy(P_AN, "home", "spider", "rabbit"),
    word_analogy(P_AN, "work", "pilot", "doctor"),
    number_analogy(P_NAN, "times", 5, [2, 3], 6),
]

# ---- 3.3 Letter and number codes --------------------------------------------

S331 = [
    alphabet("Tap the letter just after M.", "M", 1),
    alphabet("Tap the letter just before K.", "K", -1),
    alphabet("Tap the letter just after R.", "R", 1),
    alphabet("Tap the letter just before E.", "E", -1),
    letter_code(P_CODE, "CAT", "PEN", ("shift", 1)),
    letter_code(P_CODE, "BUS", "HAT", ("shift", 1)),
    letter_code(P_CODE, "SUN", "FIG", ("shift", 1)),
]

S332 = [
    letter_code(P_CODE, "TOP", "TEN", ("reverse",)),
    letter_code(P_CODE, "PAN", "GUM", ("reverse",)),
    letter_code(P_CODE, "DOG", "CUP", ("shift", 2)),
    letter_code(P_CODE, "BED", "RAT", ("reverse",)),
    letter_code(P_CODE, "JAM", "BOX", ("shift", -1)),
    alphabet("Tap the letter two after P.", "P", 2),
    alphabet("Tap the letter two before H.", "H", -2),
]

S333 = [
    number_code("A is 1. Tap the code.", "BAD", "CAB", "encode"),
    number_code("A is 1. Tap the code.", "ACE", "BIG", "encode"),
    number_code("A is 1. Tap the word.", "DIG", "BED", "decode"),
    number_code("A is 1. Tap the word.", "FED", "HID", "decode"),
    number_code("A is 1. Tap the code.", "HEAD", "FACE", "encode"),
    letter_code(P_CODE, "HIT", "BAG", ("shift", 1)),
    letter_code(P_CODE, "STAR", "POOL", ("reverse",)),
]

S334 = [
    alphabet("Tap the letter just after V.", "V", 1),
    number_code("A is 1. Tap the word.", "CAGE", "BADGE", "decode"),
    letter_code(P_CODE, "MAP", "DOT", ("shift", 1)),
    letter_code(P_CODE, "WAS", "NOW", ("reverse",)),
    number_code("A is 1. Tap the code.", "JIG", "DEAF", "encode"),
    alphabet("Tap the letter two after T.", "T", 2),
]


# ================================================================ SECTION 4
# Logic.

# ---- 4.1 Odd one out --------------------------------------------------------

S411 = [
    odd_word(P_ODD, ["apple", "mango", "carrot", "banana"]),
    odd_word(P_ODD, ["bus", "train", "parrot", "car"]),
    odd_word(P_ODD, ["red", "blue", "shirt", "green"]),
    odd_word(P_ODD, ["hand", "nose", "ear", "cycle"]),
    odd_word(P_ODD, ["crow", "sparrow", "lion", "owl"]),
    odd_number(P_ODD, [2, 4, 7, 8]),
    odd_number(P_ODD, [10, 40, 30, 35]),
]

S412 = [
    odd_word(P_ODD, ["potato", "onion", "guava", "cabbage"]),
    odd_word(P_ODD, ["sock", "cap", "dress", "eagle"]),
    odd_word(P_ODD, ["circle", "square", "triangle", "pink"]),
    odd_word(P_ODD, ["cow", "goat", "dog", "pigeon"]),
    odd_number(P_ODD, [15, 55, 35, 42]),
    odd_number(P_ODD, [3, 7, 9, 6]),
    odd_number(P_ODD, [12, 14, 16, 19]),
]

S413 = [
    odd_number(P_ODD, [35, 15, 45, 18]),
    odd_number(P_ODD, [60, 50, 70, 55]),
    odd_number(P_ODD, [8, 13, 17, 11]),
    odd_number(P_ODD, [22, 26, 24, 31]),
    odd_word(P_ODD, ["boat", "plane", "truck", "spinach"]),
    odd_word(P_ODD, ["knee", "elbow", "foot", "scarf"]),
    odd_word(P_ODD, ["papaya", "cherry", "orange", "peacock"]),
]

S414 = [
    odd_word(P_ODD, ["zebra", "elephant", "horse", "duck"]),
    odd_number(P_ODD, [40, 80, 90, 45]),
    odd_word(P_ODD, ["yellow", "brown", "black", "scooter"]),
    odd_number(P_ODD, [7, 9, 3, 12]),
    odd_word(P_ODD, ["radish", "peas", "brinjal", "grapes"]),
    odd_number(P_ODD, [30, 36, 38, 34]),
]

# ---- 4.2 Days, months and the clock -----------------------------------------
# O'clock and half past only, which is where Class 2 and 3 are.

S421 = [
    weekday(P_DAY, "after", "Monday", 2),
    weekday(P_DAY, "after", "Friday", 3),
    weekday(P_DAY, "ago", "Thursday", 2),
    weekday(P_DAY, "today", "Sunday"),
    weekday(P_DAY, "tomorrow", "Tuesday"),
    month(P_MONTH, "June", 1),
    month(P_MONTH, "March", -1),
]

S422 = [
    clock(P_READ, 3, 0, "read"),
    clock(P_READ, 7, 30, "read"),
    clock(P_TIME, 2, 0, "after", 3),
    clock(P_TIME, 11, 0, "after", 2),
    clock(P_TIME, 6, 30, "before", 2),
    weekday(P_DAY, "after", "Saturday", 2),
    weekday(P_DAY, "ago", "Monday", 1),
]

S423 = [
    month(P_MONTH, "November", 2),
    month(P_MONTH, "September", 1),
    month(P_MONTH, "January", -1),
    clock(P_TIME, 9, 30, "after", 4),
    clock(P_TIME, 1, 0, "before", 3),
    weekday(P_DAY, "today", "Wednesday"),
    weekday(P_DAY, "tomorrow", "Saturday"),
]

S424 = [
    weekday(P_DAY, "ago", "Sunday", 3),
    clock(P_READ, 12, 30, "read"),
    month(P_MONTH, "August", 2),
    clock(P_TIME, 8, 0, "after", 5),
    weekday(P_DAY, "after", "Wednesday", 4),
    month(P_MONTH, "May", -1),
]

# ---- 4.3 Think it through ---------------------------------------------------
# "How many ways" first -- possible combinations is on the Class 3 syllabus --
# then every kind of puzzle in the skill, shuffled.

S431 = [
    combos(P_WAYS, "Riya", 3, "tops", 2, "skirts"),
    combos(P_WAYS, "Om", 2, "caps", 4, "shirts"),
    combos(P_WAYS, "Zoya", 3, "breads", 3, "fillings"),
    combos(P_WAYS, "Kabir", 4, "cones", 3, "flavours"),
    story(P_STORY, "join", "Isha", "shells", 26, 8),
    rank("Tap who is the fastest.", "fast", ["Dev", "Sara", "Tom"],
         [("Sara", "Tom", "more"), ("Dev", "Sara", "less")], "top"),
    relation(rel("Kavya", "Nikhil"), [("Kavya", "wife", "Aman"), ("Aman", "father", "Nikhil")],
             "Kavya", "Nikhil"),
]

S432 = [
    combos(P_WAYS, "Neha", 2, "hairbands", 2, "clips"),
    combos(P_WAYS, "Arjun", 4, "shirts", 4, "shorts"),
    equation(P_BOX, 16, "-", 9, 7, "right"),
    queue_calc(P_CLUE, "total", 4, 7, "Mia"),
    turns(face("Sahil"), "Sahil", "West", ["left"]),
    word_analogy(P_AN, "colour", "tomato", "sky"),
    alphabet("Tap the letter just before W.", "W", -1),
]

S433 = [
    series(P_MISS, [8, 10, 12, 14, 16, 18], 1),
    odd_word(P_ODD, ["guava", "cherry", "bus", "apple"]),
    weekday(P_DAY, "after", "Tuesday", 5),
    riddle(P_RID, [("add", 7)], 20),
    queue_who("Tap who is 2nd from the back.", ["Veer", "Anu", "Raj", "Rani"], 2, "back"),
    number_analogy(P_NAN, "add", 5, [1, 6], 10),
    shelf("Tap two places left of the circle.", ["heart", "square", "circle", "star", "triangle"], "circle", "left", 2),
]

S434 = [
    relation_who("Tap Nina's aunt.",
                 [("Asha", "sister", "Karan"), ("Karan", "father", "Nina"), ("Rohan", "brother", "Nina")],
                 "Nina", "aunt"),
    story(P_STORY, "groups", "", "pencils", 4, 5),
    rank("Tap who is the second oldest.", "old", ["Ali", "Lila", "Yash", "Priya"],
         [("Lila", "Ali", "more"), ("Yash", "Ali", "less"), ("Priya", "Yash", "less")], "second"),
    letter_code(P_CODE, "LOG", "SIP", ("shift", 1)),
    clock(P_TIME, 10, 30, "after", 3),
    weekday(P_DAY, "ago", "Friday", 4),
]
