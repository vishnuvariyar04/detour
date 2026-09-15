# -*- coding: utf-8 -*-
"""Reasoning — 48 stops, 324 questions, band d, ages 11-12.

HARDER THAN BAND C, AND SAID HOW. Think Like a Coder's hardest question traces a
list of up to ten steps, and its biggest number answer is 20. Here:

  sequences  the 100th term, found without writing out the 99 before it;
             answers into the hundreds; squares, cubes, second differences
  logic      what MUST follow from a rule, including the two fallacies an
             eleven year old falls for -- where the honest answer is that you
             cannot tell -- and deductions with no clue that gives it away
  codes      binary with carrying, shift codes that wrap past Z, symbol keys
  space      folding a net in your head, rolling a dice five times, counting
             cubes you cannot see

SHORT, PLAIN PROMPTS. One sentence naming one action, never over 60 characters.
The reasoning lives in the picture -- the clue card, the key, the net -- so the
instruction itself stays easy to read.

NO QUESTION APPEARS TWICE, here or against the 972 already written.
"""
from reasoning_kit import (
    STAR, HEART, CIRCLE, SQUARE, TRIANGLE, DIAMOND, HEXAGON, FLOWER,
    arith, geom, grow, sum2, alternate, by_position,
    sequence, nth_term, nth_poly, term_position, seq_rule,
    if_then, claim, deduce,
    binary_read, binary_pick,
    cipher_decode, cipher_encode, symbol_decode, letter_code, letter_sum,
    net_face, net_pick, fold, OPPOSITE, dice,
    stack_count, stack_fill, stack_view,
    knights, mirror_decode, mirror_encode, crack,
    polycube_pick, cube_turn, section_shape, section_sides, section_which,
)


def ordinal(n):
    if 10 <= n % 100 <= 20:
        suf = "th"
    else:
        suf = {1: "st", 2: "nd", 3: "rd"}.get(n % 10, "th")
    return f"{n}{suf}"


P_NEXT = "Tap the number that comes next."
P_MISS = "Tap the missing number."
P_RULE = "Tap the rule that makes this pattern."
P_NTH = lambda n: f"Tap the {ordinal(n)} number in this pattern."
P_POS = lambda v: f"Which position in the pattern is {v}? Tap it."

sq = lambda p: p * p
cube = lambda p: p ** 3
tri = lambda p: p * (p + 1) // 2


# ================================================================ SECTION 1
# Sequences: find the rule, then push it much further than the page goes.

# ---- 1.1 Find the rule -----------------------------------------------------

S111 = [
    sequence(P_NEXT, arith(7, 9, 6), 5),
    sequence(P_NEXT, arith(95, -13, 6), 5),
    sequence(P_NEXT, arith(18, 17, 6), 5),
    sequence(P_NEXT, arith(200, -24, 6), 5),
    sequence(P_NEXT, arith(4, 23, 6), 5),
    seq_rule(P_RULE, arith(5, 7, 5),
             [{"t": "add", "k": 7}, {"t": "grow", "step": 7, "inc": 1},
              {"t": "alt", "ops": [["add", 7], ["mul", 2]]}, {"t": "add", "k": 5}]),
    seq_rule(P_RULE, arith(60, -8, 5),
             [{"t": "add", "k": -8}, {"t": "grow", "step": -8, "inc": -1},
              {"t": "add", "k": -6}, {"t": "mul", "k": "1/2"}]),
]

# Below zero, and holes in the middle, where the rule has to be read from both
# sides instead of run forward off the end.
S112 = [
    sequence(P_NEXT, arith(26, -9, 6), 5),
    sequence(P_MISS, arith(40, -15, 6), 3),
    sequence(P_MISS, arith(-30, 11, 6), 2),
    sequence(P_NEXT, arith(13, -6, 6), 5),
    sequence(P_MISS, arith(-48, 12, 7), 4),
    sequence(P_MISS, arith(55, -14, 6), 1),
    sequence(P_NEXT, arith(-7, -8, 6), 5),
]

# Times patterns. The trap rules fit the first step or two and then break, which
# is exactly how a child who checks one step gets these wrong.
S113 = [
    sequence(P_NEXT, geom(3, 2, 6), 5),
    sequence(P_NEXT, geom(2, 3, 6), 5),
    sequence(P_NEXT, geom(1600, "1/2", 6), 5),
    sequence(P_MISS, geom(5, 2, 6), 3),
    sequence(P_MISS, geom(4, 3, 6), 2),
    seq_rule(P_RULE, geom(3, 2, 5),
             [{"t": "mul", "k": 2}, {"t": "add", "k": 3},
              {"t": "grow", "step": 3, "inc": 3},
              {"t": "alt", "ops": [["add", 3], ["mul", 2]]}]),
    seq_rule(P_RULE, geom(2, 3, 5),
             [{"t": "mul", "k": 3}, {"t": "add", "k": 4},
              {"t": "grow", "step": 4, "inc": 8}, {"t": "sum2"}]),
]

S114 = [
    sequence(P_NEXT, sum2(3, 4, 6), 5),
    sequence(P_NEXT, alternate(2, [("add", 3), ("mul", 2)], 7), 6),
    sequence(P_MISS, geom(7, 2, 6), 4),
    seq_rule(P_RULE, sum2(2, 5, 5),
             [{"t": "sum2"}, {"t": "grow", "step": 3, "inc": -1},
              {"t": "alt", "ops": [["add", 3], ["add", 2]]}, {"t": "add", "k": 3}]),
    sequence(P_NEXT, arith(250, -37, 6), 5),
    sequence(P_MISS, alternate(1, [("mul", 3), ("add", 1)], 7), 3),
]

# ---- 1.2 The nth term ------------------------------------------------------
# Band c runs a rule forward one step at a time. This asks for a term far past
# the end of the page, which needs the rule as a formula, not as a habit.

S121 = [
    nth_term(P_NTH(10), 4, 3, 5, 10),
    nth_term(P_NTH(10), 7, 5, 5, 10),
    nth_term(P_NTH(10), 2, 9, 5, 10),
    nth_term(P_NTH(10), 50, -4, 5, 10),
    nth_term(P_NTH(10), 11, 6, 5, 10),
    nth_term(P_NTH(10), -3, 7, 5, 10),
    nth_term(P_NTH(10), 100, -9, 5, 10),
]

S122 = [
    nth_term(P_NTH(20), 5, 3, 5, 20),
    nth_term(P_NTH(25), 6, 4, 5, 25),
    nth_term(P_NTH(50), 1, 2, 5, 50),
    nth_term(P_NTH(100), 3, 5, 5, 100),
    nth_term(P_NTH(30), 10, -2, 5, 30),
    nth_term(P_NTH(40), 8, 7, 5, 40),
    nth_term(P_NTH(21), 12, 11, 5, 21),
]

S123 = [
    term_position(P_POS(46), 4, 3, 5, 15),
    term_position(P_POS(62), 7, 5, 5, 12),
    term_position(P_POS(116), 2, 6, 5, 20),
    term_position(P_POS(22), 90, -4, 5, 18),
    term_position(P_POS(91), 1, 9, 5, 11),
    term_position(P_POS(197), 5, 8, 5, 25),
    term_position(P_POS(68), -10, 6, 5, 14),
]

S124 = [
    nth_term(P_NTH(100), 7, 4, 5, 100),
    term_position(P_POS(206), 3, 7, 5, 30),
    sequence(P_NEXT, arith(17, 19, 6), 5),
    nth_term(P_NTH(50), -20, 6, 5, 50),
    term_position(P_POS(25), 100, -3, 5, 26),
    sequence(P_MISS, arith(9, 13, 6), 2),
]

# ---- 1.3 Squares, cubes, second differences --------------------------------

S131 = [
    sequence(P_NEXT, by_position(sq, 6), 5),
    sequence(P_NEXT, by_position(sq, 6, start=5), 5),
    sequence(P_NEXT, by_position(tri, 6), 5),
    sequence(P_MISS, by_position(sq, 6, start=7), 2),
    sequence(P_NEXT, by_position(tri, 6, start=4), 5),
    seq_rule(P_RULE, by_position(sq, 5),
             [{"t": "sq", "b": 0}, {"t": "add", "k": 3}, {"t": "mul", "k": 4},
              {"t": "alt", "ops": [["add", 3], ["add", 5]]}]),
    seq_rule(P_RULE, by_position(lambda p: p * p + 2, 5),
             [{"t": "sq", "b": 2}, {"t": "add", "k": 3}, {"t": "mul", "k": 2},
              {"t": "alt", "ops": [["add", 3], ["add", 5]]}]),
]

S132 = [
    sequence(P_NEXT, by_position(cube, 6), 5),
    sequence(P_MISS, by_position(cube, 6), 3),
    sequence(P_NEXT, by_position(cube, 6, start=2), 5),
    nth_poly(P_NTH(12), sq, 5, 12, [121, 169, 24, 132]),
    nth_poly(P_NTH(10), cube, 5, 10, [729, 1331, 30, 100]),
    nth_poly(P_NTH(15), sq, 5, 15, [196, 256, 30, 215]),
    nth_poly(P_NTH(20), tri, 5, 20, [190, 231, 40, 200]),
]

# The gaps between the gaps are constant. Not one of these is an adding or a
# times pattern, so a child running either habit gets a specific wrong answer.
S133 = [
    sequence(P_NEXT, by_position(lambda p: p * p + p, 6), 5),
    sequence(P_NEXT, by_position(lambda p: 2 * p * p + 1, 6), 5),
    sequence(P_NEXT, grow(4, 3, 2, 6), 5),
    sequence(P_MISS, grow(5, 2, 3, 6), 3),
    sequence(P_NEXT, by_position(lambda p: 3 * p * p - p, 6), 5),
    seq_rule(P_RULE, grow(1, 2, 2, 5),
             [{"t": "grow", "step": 2, "inc": 2}, {"t": "add", "k": 2},
              {"t": "mul", "k": 3}, {"t": "alt", "ops": [["add", 2], ["add", 4]]}]),
    seq_rule(P_RULE, by_position(lambda p: p * p + 3, 5),
             [{"t": "sq", "b": 3}, {"t": "add", "k": 3},
              {"t": "grow", "step": 3, "inc": 1}, {"t": "mul", "k": 2}]),
]

S134 = [
    sequence(P_NEXT, by_position(lambda p: p ** 3 + 1, 6), 5),
    nth_poly(P_NTH(25), sq, 5, 25, [576, 676, 50, 600]),
    sequence(P_MISS, by_position(tri, 7, start=6), 4),
    sequence(P_NEXT, grow(10, 5, 4, 6), 5),
    nth_term(P_NTH(100), 15, -2, 5, 100),
    seq_rule(P_RULE, by_position(cube, 5),
             [{"t": "cube", "b": 0}, {"t": "mul", "k": 8}, {"t": "add", "k": 7},
              {"t": "grow", "step": 7, "inc": 12}]),
]


# ================================================================ SECTION 2
# Logic: what follows, what only seems to follow, and who has what.

P_IF = "Read the clues. Tap what must be true."
P_KK = lambda p: f"Read what they say. Tap what {p} is."
P_CLAIM = "Is this always, sometimes or never true? Tap one."
P_WHO = lambda x: f"Read the clues. Tap who has the {x}."
P_WHAT = lambda p: f"Read the clues. Tap what {p} has."

# ---- 2.1 If-then -----------------------------------------------------------

S211 = [
    if_then(P_IF, [("star", True, "purple", True)], [("star", True)], "purple"),
    if_then(P_IF, [("big", True, "spots", False)], [("big", True)], "spots"),
    if_then(P_IF, [("stripe", True, "shiny", True)], [("shiny", False)], "stripe"),
    if_then(P_IF, [("purple", False, "big", True)], [("big", False)], "purple"),
    if_then(P_IF, [("spots", True, "star", False)], [("star", True)], "spots"),
    if_then(P_IF, [("shiny", False, "stripe", True)], [("shiny", False)], "stripe"),
    if_then(P_IF, [("big", True, "purple", False)], [("purple", True)], "big"),
]

# The two fallacies. "If it has a star it is purple; it is purple" tempts almost
# everyone into "so it has a star". It does not follow. Three questions here DO
# follow, so "you cannot tell" cannot be learned as the answer to this stop.
S212 = [
    if_then(P_IF, [("star", True, "purple", True)], [("purple", True)], "star"),
    if_then(P_IF, [("big", True, "spots", True)], [("big", False)], "spots"),
    if_then(P_IF, [("stripe", True, "shiny", False)], [("shiny", False)], "stripe"),
    if_then(P_IF, [("purple", False, "star", True)], [("purple", True)], "star"),
    if_then(P_IF, [("spots", True, "big", False)], [("big", True)], "spots"),
    if_then(P_IF, [("shiny", True, "stripe", True)], [("shiny", True)], "stripe"),
    if_then(P_IF, [("star", False, "spots", False)], [("spots", True)], "star"),
]

S213 = [
    knights(P_KK("Asha"), ["Asha", "Ravi"], [("Asha", ("one_liar",))], "Asha"),
    knights(P_KK("Omar"), ["Kabir", "Omar"],
            [("Kabir", ("same", "Kabir", "Omar")), ("Omar", ("diff", "Kabir", "Omar"))], "Omar"),
    knights(P_KK("Zoya"), ["Zoya", "Dev"], [("Zoya", ("both", "liar"))], "Zoya"),
    knights(P_KK("Neha"), ["Neha", "Imran"], [("Neha", ("diff", "Neha", "Imran"))], "Neha"),
    knights(P_KK("Tara"), ["Tara", "Arjun"],
            [("Tara", ("is", "Arjun", "liar")), ("Arjun", ("is", "Tara", "liar"))], "Tara"),
    knights(P_KK("Joy"), ["Isha", "Joy"], [("Isha", ("same", "Isha", "Joy"))], "Joy"),
    knights(P_KK("Priya"), ["Priya", "Sam"],
            [("Priya", ("is", "Sam", "truth-teller")), ("Sam", ("diff", "Priya", "Sam"))], "Priya"),
]

S214 = [
    if_then(P_IF, [("star", True, "purple", True), ("purple", True, "spots", True),
                   ("spots", True, "big", False)], [("star", True)], "big"),
    if_then(P_IF, [("shiny", True, "stripe", True), ("stripe", True, "star", False)],
            [("star", True)], "shiny"),
    if_then(P_IF, [("big", True, "spots", True), ("spots", True, "purple", True)],
            [("purple", True)], "big"),
    claim(P_CLAIM, {"a": "odd", "op": "plus", "b": "odd", "is": "even"}),
    knights(P_KK("Anu"), ["Rohan", "Anu"],
            [("Rohan", ("one_liar",)), ("Anu", ("is", "Rohan", "liar"))], "Anu"),
    claim(P_CLAIM, {"a": "even", "op": "is", "is": "m4"}),
]

# ---- 2.2 Always, sometimes, never ------------------------------------------
# Every claim is about classes of whole numbers that repeat with a period, so
# "always" and "never" are checked exactly, not just as far as someone looked.

S221 = [
    claim(P_CLAIM, {"a": "odd", "op": "plus", "b": "even", "is": "even"}),
    claim(P_CLAIM, {"a": "even", "op": "times", "b": "odd", "is": "even"}),
    claim(P_CLAIM, {"a": "odd", "op": "times", "b": "odd", "is": "even"}),
    claim(P_CLAIM, {"a": "even", "op": "plus", "b": "even", "is": "m4"}),
    claim(P_CLAIM, {"a": "odd", "op": "double", "is": "m4"}),
    claim(P_CLAIM, {"a": "even", "op": "double", "is": "m4"}),
    claim(P_CLAIM, {"a": "odd", "op": "plus", "b": "odd", "is": "odd"}),
]

S222 = [
    claim(P_CLAIM, {"a": "m3", "op": "plus", "b": "m3", "is": "m3"}),
    claim(P_CLAIM, {"a": "m5", "op": "plus", "b": "m5", "is": "m10"}),
    claim(P_CLAIM, {"a": "m4", "op": "times", "b": "odd", "is": "m4"}),
    claim(P_CLAIM, {"a": "m6", "op": "is", "is": "m3"}),
    claim(P_CLAIM, {"a": "m10", "op": "is", "is": "m4"}),
    claim(P_CLAIM, {"a": "m4", "op": "plus", "b": "odd", "is": "even"}),
    claim(P_CLAIM, {"a": "m10", "op": "is", "is": "odd"}),
]

S223 = [
    claim(P_CLAIM, {"a": "sq", "op": "is", "is": "even"}),
    claim(P_CLAIM, {"a": "odd", "op": "square", "is": "odd"}),
    claim(P_CLAIM, {"a": "even", "op": "square", "is": "m4"}),
    claim(P_CLAIM, {"a": "odd", "op": "square", "is": "even"}),
    claim(P_CLAIM, {"a": "m3", "op": "square", "is": "m6"}),
    claim(P_CLAIM, {"a": "sq", "op": "plus", "b": "sq", "is": "even"}),
    claim(P_CLAIM, {"a": "even", "op": "square", "is": "odd"}),
]

S224 = [
    claim(P_CLAIM, {"a": "m3", "op": "times", "b": "m4", "is": "m6"}),
    claim(P_CLAIM, {"a": "odd", "op": "plus", "b": "odd", "is": "m4"}),
    if_then(P_IF, [("spots", True, "big", True), ("big", True, "shiny", True)],
            [("shiny", True)], "spots"),
    claim(P_CLAIM, {"a": "m6", "op": "plus", "b": "odd", "is": "even"}),
    claim(P_CLAIM, {"a": "m5", "op": "times", "b": "even", "is": "m10"}),
    if_then(P_IF, [("purple", True, "stripe", True)], [("stripe", False)], "purple"),
]

# ---- 2.3 Who has what ------------------------------------------------------
# Exactly one arrangement fits, and no single clue gives the answer away: both
# checked by trying every arrangement.

S231 = [
    deduce(P_WHO("cat"), ["Asha", "Ravi", "Meera"], ["cat", "dog", "fish"], "",
           [{"t": "has", "p": "Asha", "x": "fish"}, {"t": "not", "p": "Ravi", "x": "cat"}],
           who="cat"),
    deduce(P_WHO("flute"), ["Kabir", "Zoya", "Arjun"], ["drum", "flute", "guitar"], "",
           [{"t": "has", "p": "Zoya", "x": "drum"}, {"t": "not", "p": "Kabir", "x": "flute"}],
           who="flute"),
    deduce(P_WHO("mango"), ["Priya", "Dev", "Isha"], ["mango", "apple", "banana"], "",
           [{"t": "has", "p": "Dev", "x": "banana"}, {"t": "not", "p": "Isha", "x": "mango"}],
           who="mango"),
    deduce(P_WHO("red bag"), ["Rohan", "Tara", "Imran"], ["red", "blue", "green"], "bag",
           [{"t": "has", "p": "Imran", "x": "blue"}, {"t": "not", "p": "Tara", "x": "red"}],
           who="red"),
    deduce(P_WHO("dog"), ["Neha", "Sam", "Anu"], ["cat", "dog", "bird"], "",
           [{"t": "has", "p": "Sam", "x": "cat"}, {"t": "not", "p": "Neha", "x": "dog"}],
           who="dog"),
    deduce(P_WHO("guitar"), ["Joy", "Meera", "Ravi"], ["drum", "flute", "guitar"], "",
           [{"t": "has", "p": "Meera", "x": "flute"}, {"t": "not", "p": "Joy", "x": "guitar"}],
           who="guitar"),
    deduce(P_WHO("green bag"), ["Asha", "Kabir", "Zoya"], ["red", "blue", "green"], "bag",
           [{"t": "has", "p": "Kabir", "x": "red"}, {"t": "not", "p": "Zoya", "x": "green"}],
           who="green"),
]

S232 = [
    deduce(P_WHO("cat"), ["Asha", "Ravi", "Meera"], ["cat", "dog", "fish"], "",
           [{"t": "neither", "ps": ["Asha", "Ravi"], "x": "dog"},
            {"t": "either", "ps": ["Asha", "Meera"], "x": "fish"}], who="cat"),
    deduce(P_WHO("apple"), ["Dev", "Isha", "Priya"], ["mango", "apple", "banana"], "",
           [{"t": "neither", "ps": ["Dev", "Isha"], "x": "banana"},
            {"t": "either", "ps": ["Dev", "Priya"], "x": "mango"}], who="apple"),
    deduce(P_WHO("drum"), ["Tara", "Rohan", "Imran"], ["drum", "flute", "guitar"], "",
           [{"t": "neither", "ps": ["Rohan", "Imran"], "x": "flute"},
            {"t": "either", "ps": ["Tara", "Imran"], "x": "guitar"}], who="drum"),
    deduce(P_WHO("blue bag"), ["Sam", "Neha", "Joy"], ["red", "blue", "green"], "bag",
           [{"t": "neither", "ps": ["Sam", "Joy"], "x": "red"},
            {"t": "either", "ps": ["Sam", "Neha"], "x": "green"}], who="blue"),
    deduce(P_WHO("bird"), ["Anu", "Arjun", "Zoya"], ["cat", "dog", "bird"], "",
           [{"t": "neither", "ps": ["Anu", "Zoya"], "x": "dog"},
            {"t": "either", "ps": ["Anu", "Arjun"], "x": "cat"}], who="bird"),
    deduce(P_WHO("banana"), ["Meera", "Kabir", "Isha"], ["mango", "apple", "banana"], "",
           [{"t": "neither", "ps": ["Kabir", "Isha"], "x": "apple"},
            {"t": "either", "ps": ["Meera", "Isha"], "x": "mango"}], who="banana"),
    deduce(P_WHO("flute"), ["Ravi", "Priya", "Dev"], ["drum", "flute", "guitar"], "",
           [{"t": "neither", "ps": ["Priya", "Dev"], "x": "guitar"},
            {"t": "either", "ps": ["Ravi", "Dev"], "x": "drum"}], who="flute"),
]

S233 = [
    deduce(P_WHAT("Ravi"), ["Asha", "Ravi", "Meera"], ["cat", "dog", "fish"], "",
           [{"t": "not", "p": "Asha", "x": "cat"}, {"t": "not", "p": "Asha", "x": "dog"},
            {"t": "not", "p": "Meera", "x": "cat"}], what="Ravi"),
    deduce(P_WHAT("Zoya"), ["Kabir", "Zoya", "Arjun"], ["drum", "flute", "guitar"], "",
           [{"t": "either", "ps": ["Kabir", "Arjun"], "x": "drum"},
            {"t": "not", "p": "Arjun", "x": "drum"}, {"t": "not", "p": "Zoya", "x": "flute"}],
           what="Zoya"),
    deduce(P_WHAT("Dev"), ["Priya", "Dev", "Isha"], ["mango", "apple", "banana"], "",
           [{"t": "neither", "ps": ["Priya", "Dev"], "x": "apple"},
            {"t": "not", "p": "Dev", "x": "mango"}], what="Dev"),
    claim(P_CLAIM, {"a": "m4", "op": "plus", "b": "m4", "is": "m4"}),
    deduce(P_WHAT("Rohan"), ["Rohan", "Tara", "Imran"], ["red", "blue", "green"], "bag",
           [{"t": "either", "ps": ["Rohan", "Tara"], "x": "green"},
            {"t": "not", "p": "Rohan", "x": "green"}, {"t": "not", "p": "Imran", "x": "red"}],
           what="Rohan"),
    deduce(P_WHAT("Anu"), ["Neha", "Sam", "Anu"], ["cat", "dog", "bird"], "",
           [{"t": "neither", "ps": ["Neha", "Anu"], "x": "bird"},
            {"t": "not", "p": "Anu", "x": "cat"}], what="Anu"),
    if_then(P_IF, [("big", True, "star", False), ("star", False, "shiny", True)],
            [("big", True)], "shiny"),
]

# Four friends and four things: 24 arrangements, so the clues have to be chained.
S234 = [
    deduce(P_WHO("fish"), ["Asha", "Ravi", "Meera", "Kabir"],
           ["cat", "dog", "fish", "bird"], "",
           [{"t": "not", "p": "Asha", "x": "dog"},
            {"t": "not", "p": "Asha", "x": "fish"},
            {"t": "either", "ps": ["Asha", "Meera"], "x": "dog"},
            {"t": "neither", "ps": ["Asha", "Kabir"], "x": "bird"}], who="fish"),
    deduce(P_WHAT("Dev"), ["Priya", "Dev", "Isha", "Zoya"],
           ["drum", "flute", "guitar", "piano"], "",
           [{"t": "has", "p": "Priya", "x": "piano"},
            {"t": "neither", "ps": ["Dev", "Isha"], "x": "drum"},
            {"t": "not", "p": "Isha", "x": "flute"}], what="Dev"),
    claim(P_CLAIM, {"a": "m5", "op": "plus", "b": "m10", "is": "m10"}),
    deduce(P_WHO("green bag"), ["Rohan", "Tara", "Imran", "Neha"],
           ["red", "blue", "green", "yellow"], "bag",
           [{"t": "not", "p": "Rohan", "x": "red"},
            {"t": "not", "p": "Rohan", "x": "green"},
            {"t": "either", "ps": ["Rohan", "Tara"], "x": "red"},
            {"t": "neither", "ps": ["Rohan", "Imran"], "x": "yellow"}], who="green"),
    if_then(P_IF, [("spots", False, "purple", True), ("purple", True, "big", False)],
            [("big", True)], "spots"),
    deduce(P_WHAT("Joy"), ["Sam", "Anu", "Joy", "Arjun"],
           ["mango", "apple", "banana", "grapes"], "",
           [{"t": "neither", "ps": ["Sam", "Anu"], "x": "grapes"},
            {"t": "not", "p": "Arjun", "x": "grapes"},
            {"t": "either", "ps": ["Anu", "Arjun"], "x": "banana"},
            {"t": "not", "p": "Arjun", "x": "banana"},
            {"t": "not", "p": "Sam", "x": "mango"}], what="Joy"),
]


# ================================================================ SECTION 3
# Codes: a rule you can run backwards.

V4 = [8, 4, 2, 1]
V5 = [16, 8, 4, 2, 1]
V6 = [32, 16, 8, 4, 2, 1]

P_BULBS = "Add up the lit bulbs. Tap the number."
P_SHOW = lambda n: f"Tap the bulbs that show {n}."
P_MORE = "Tap the bulbs that show one more."
P_DECODE = "Use the key to decode the word. Tap it."
P_ENCODE = "Use the key to write this word in code. Tap it."
P_SYM = "Swap each symbol for its letter. Tap the word."
P_A1 = "A is 1, B is 2 and so on. Tap the word."
P_SUM = lambda w: f"A is 1, B is 2 and so on. Add up {w}. Tap it."
P_CRACK_E = "Use the same code. Tap how the word is written."
P_CRACK_D = "Use the same code. Tap what the word means."

# ---- 3.1 Binary ------------------------------------------------------------

S311 = [
    binary_read(P_BULBS, V4, [1, 0, 1, 1]),
    binary_read(P_BULBS, V4, [0, 1, 1, 0]),
    binary_read(P_BULBS, V4, [1, 1, 0, 1]),
    binary_read(P_BULBS, V4, [1, 0, 0, 1]),
    binary_read(P_BULBS, V4, [0, 1, 0, 1]),
    binary_read(P_BULBS, V4, [1, 1, 1, 0]),
    binary_pick(P_SHOW(10), V4, 10),
]

S312 = [
    binary_read(P_BULBS, V5, [1, 0, 1, 1, 0]),
    binary_read(P_BULBS, V5, [1, 1, 0, 0, 1]),
    binary_read(P_BULBS, V5, [0, 1, 1, 1, 1]),
    binary_read(P_BULBS, V6, [1, 0, 1, 0, 1, 1]),
    binary_read(P_BULBS, V6, [1, 1, 0, 1, 0, 0]),
    binary_pick(P_SHOW(19), V5, 19),
    binary_pick(P_SHOW(37), V6, 37),
]

# One more than the number shown. Most of these carry, which is where binary
# stops being a lookup and starts being arithmetic.
S313 = [
    binary_pick(P_SHOW(13), V5, 13),
    binary_pick(P_SHOW(26), V5, 26),
    binary_pick(P_MORE, V5, 11, show=True, plus=1),
    binary_pick(P_MORE, V5, 23, show=True, plus=1),
    binary_pick(P_MORE, V6, 31, show=True, plus=1),
    binary_read(P_BULBS, V6, [1, 0, 0, 1, 1, 0]),
    binary_read(P_BULBS, V5, [1, 1, 1, 1, 1]),
]

S314 = [
    binary_read(P_BULBS, V6, [1, 1, 1, 0, 1, 1]),
    binary_pick(P_SHOW(44), V6, 44),
    binary_pick(P_MORE, V6, 39, show=True, plus=1),
    binary_read(P_BULBS, V5, [1, 0, 0, 0, 1]),
    binary_pick(P_SHOW(30), V5, 30),
    binary_pick(P_MORE, V5, 15, show=True, plus=1),
]

# ---- 3.2 Shift codes -------------------------------------------------------
# Every wrong option is a real word sharing letters with the answer, so the
# right one cannot be spotted as "the only real word" without decoding.

S321 = [
    cipher_decode(P_DECODE, "CAT", 1),
    cipher_decode(P_DECODE, "SUN", 2),
    cipher_decode(P_DECODE, "DOG", 3),
    cipher_decode(P_DECODE, "PEN", 1),
    cipher_decode(P_DECODE, "BOX", 2),
    cipher_decode(P_DECODE, "FIG", 3),
    cipher_encode(P_ENCODE, "HAT", 1),
]

# Letters near the end of the alphabet, so the code wraps past Z back to A.
S322 = [
    cipher_decode(P_DECODE, "ZOO", 3),
    cipher_decode(P_DECODE, "WAX", 4),
    cipher_decode(P_DECODE, "YES", 5),
    cipher_decode(P_DECODE, "TOY", 6),
    cipher_decode(P_DECODE, "KEY", 4),
    cipher_decode(P_DECODE, "SKY", 5),
    cipher_encode(P_ENCODE, "ZIP", 3),
]

S323 = [
    cipher_encode(P_ENCODE, "FISH", 2),
    cipher_encode(P_ENCODE, "KITE", 3),
    cipher_encode(P_ENCODE, "STAR", 4),
    cipher_encode(P_ENCODE, "MOON", 1),
    cipher_encode(P_ENCODE, "SNOW", 5),
    cipher_decode(P_DECODE, "MANGO", 2),
    cipher_decode(P_DECODE, "ZEBRA", 3),
]

S324 = [
    cipher_decode(P_DECODE, "TIGER", 7),
    cipher_encode(P_ENCODE, "QUEEN", 4),
    cipher_decode(P_DECODE, "WATER", 9),
    cipher_encode(P_ENCODE, "RIVER", 6),
    cipher_decode(P_DECODE, "LIGHT", 11),
    cipher_encode(P_ENCODE, "CLOUD", 13),
]

# ---- 3.3 Substitution ------------------------------------------------------
# Each letter swapped for another thing by a fixed key: a symbol, a number, the
# back-to-front alphabet, or a rule worked out from an example with no key shown.

S331 = [
    symbol_decode(P_SYM, "CAT"),
    symbol_decode(P_SYM, "DOG"),
    symbol_decode(P_SYM, "SUN"),
    symbol_decode(P_SYM, "PEN"),
    symbol_decode(P_SYM, "BOX"),
    symbol_decode(P_SYM, "RED"),
    letter_code(P_A1, "BAG"),
]

S332 = [
    mirror_decode(P_DECODE, "SUN"),
    mirror_decode(P_DECODE, "KITE"),
    mirror_decode(P_DECODE, "FISH"),
    mirror_decode(P_DECODE, "MOON"),
    mirror_encode(P_ENCODE, "CUP"),
    mirror_encode(P_ENCODE, "STAR"),
    mirror_encode(P_ENCODE, "BELL"),
]

S333 = [
    crack(P_CRACK_E, "CAT", "DOG", ("shift", 1), "encode"),
    crack(P_CRACK_E, "SUN", "BED", ("atbash",), "encode"),
    crack(P_CRACK_D, "HAT", "FIG", ("shift", 2), "decode"),
    crack(P_CRACK_E, "MAP", "BUS", ("shift", 3), "encode"),
    crack(P_CRACK_D, "TEN", "JAM", ("atbash",), "decode"),
    crack(P_CRACK_E, "FISH", "KING", ("shift", 25), "encode"),
    crack(P_CRACK_D, "BOOK", "LAMP", ("shift", 4), "decode"),
]

S334 = [
    letter_code(P_A1, "ZEBRA"),
    mirror_encode(P_ENCODE, "QUEEN"),
    crack(P_CRACK_E, "WIND", "SNOW", ("shift", 5), "encode"),
    symbol_decode(P_SYM, "WAX"),
    mirror_decode(P_DECODE, "TRUCK"),
    crack(P_CRACK_D, "LAKE", "SHIP", ("atbash",), "decode"),
]


# ================================================================ SECTION 4
# Space: picture it, then turn it in your head.

import reasoning_kit as _K

NETS = {  # the eleven nets of a cube, each checked by folding below
    0: [[0, 0], [0, 1], [0, 2], [1, 1], [2, 1], [3, 1]],
    1: [[0, 0], [0, 1], [1, 1], [1, 2], [2, 1], [3, 1]],
    2: [[0, 0], [0, 1], [1, 1], [2, 1], [2, 2], [3, 1]],
    3: [[0, 0], [0, 1], [1, 1], [2, 1], [2, 2], [3, 2]],
    4: [[0, 0], [0, 1], [1, 1], [2, 1], [3, 1], [3, 2]],
    5: [[0, 0], [1, 0], [1, 1], [1, 2], [2, 1], [3, 1]],
    6: [[0, 0], [1, 0], [1, 1], [2, 1], [2, 2], [3, 1]],
    7: [[0, 0], [1, 0], [1, 1], [2, 1], [2, 2], [3, 2]],
    8: [[0, 0], [1, 0], [2, 0], [2, 1], [3, 1], [4, 1]],
    9: [[0, 1], [1, 0], [1, 1], [1, 2], [2, 1], [3, 1]],
    10: [[0, 1], [1, 0], [1, 1], [2, 1], [2, 2], [3, 1]],
}
FAKES = {  # hexominoes that do NOT fold, with no 2x2 block and no row of five
    0: [[0, 0], [0, 1], [0, 2], [1, 0], [1, 2], [2, 0]],
    1: [[0, 0], [0, 1], [0, 2], [1, 0], [2, 0], [3, 0]],
    2: [[0, 0], [0, 1], [0, 2], [1, 1], [2, 0], [2, 1]],
    3: [[0, 0], [0, 1], [1, 0], [2, 0], [2, 1], [3, 0]],
    4: [[0, 0], [0, 1], [1, 0], [2, 0], [2, 1], [3, 1]],
    5: [[0, 0], [0, 1], [1, 0], [2, 0], [3, 0], [3, 1]],
    6: [[0, 0], [0, 1], [1, 1], [1, 2], [2, 0], [2, 1]],
    7: [[0, 0], [0, 1], [1, 1], [1, 2], [2, 2], [3, 2]],
    8: [[0, 0], [1, 0], [1, 1], [1, 2], [2, 0], [3, 0]],
    9: [[0, 0], [1, 0], [1, 1], [1, 2], [2, 2], [3, 2]],
    10: [[0, 0], [1, 0], [1, 1], [2, 1], [3, 1], [4, 1]],
    11: [[0, 0], [1, 0], [2, 0], [2, 1], [2, 2], [3, 1]],
}


def turn(net, k):
    """The same net turned k quarter turns, so the options do not all lie flat."""
    pts = [tuple(c) for c in net]
    for _ in range(k % 4):
        pts = [(y, -x) for x, y in pts]
    return [list(c) for c in _K._norm(pts)]


P_OPP = lambda g: f"Fold it into a cube. Tap the face opposite the {g}."
P_FOLDS = "Tap the net that folds into a cube."
P_NOT = "Tap the net that does NOT fold into a cube."
P_ROLL = "The dice rolls along the arrows. Tap the top number."
P_COUNT = "Count every cube, even hidden ones. Tap the number."
P_FILL = "Tap how many more cubes fill the dotted shape."
P_FRONT = "Tap what you see from the FRONT."
P_SAME = "Which picture is the same shape, turned? Tap it."
P_TURN = lambda side: f"Follow the turn. Tap what is {side}."
P_TURNS = lambda side: f"Follow both turns. Tap what is {side}."
P_CUT = "Cut along the yellow plane. Tap the shape of the cut."
P_SIDES = "Cut along the yellow plane. How many sides? Tap it."
P_WHICH = lambda s: f"Which cut makes {'an' if s[0] in 'aeiou' else 'a'} {s}? Tap it."
PC4 = _K.all_polycubes(4)
PC5 = _K.all_polycubes(5)
P_RIGHT = "Tap what you see from the RIGHT."

# Only shapes that stay distinct when drawn small; see CLEAR_GLYPHS in the kit.
M = _K.CLEAR_GLYPHS


def marks(k):
    return [M[(k + i * 5) % 6] for i in range(6)]


def net_q(net, k, straight):
    """A face and its opposite, either in a straight line or round a corner.

    In a straight line with one square between them is the rule a child can
    learn by eye. Round a corner is where they have to fold it for real, so the
    two kinds are chosen deliberately rather than left to chance.
    """
    faces = fold(net)
    cells = [tuple(c) for c in net]
    s = set(cells)
    picks = []
    for i, c in enumerate(cells):
        j = next(j for j, d in enumerate(cells) if faces[d] == OPPOSITE[faces[c]])
        d = cells[j]
        mid = ((c[0] + d[0]) / 2, (c[1] + d[1]) / 2)
        line = (c[0] == d[0] or c[1] == d[1]) and abs(c[0] - d[0]) + abs(c[1] - d[1]) == 2 \
            and mid in s
        if line == straight:
            picks.append(i)
    m = marks(k)
    i = picks[k % len(picks)]
    return net_face(P_OPP(m[i]), net, m, m[i])


# ---- 4.1 Cube nets ---------------------------------------------------------

S411 = [
    net_q(NETS[0], 0, True),
    net_q(turn(NETS[1], 1), 1, True),
    net_q(NETS[2], 2, True),
    net_q(turn(NETS[4], 3), 3, True),
    net_q(NETS[9], 4, True),
    net_q(turn(NETS[10], 2), 5, True),
    net_pick(P_FOLDS, [NETS[0]], [FAKES[1], FAKES[5], FAKES[8]]),
]

S412 = [
    net_q(NETS[1], 6, False),
    net_q(turn(NETS[3], 1), 7, False),
    net_q(NETS[5], 1, False),
    net_q(turn(NETS[6], 3), 2, False),
    net_q(NETS[7], 3, False),
    net_q(turn(NETS[8], 1), 4, False),
    net_pick(P_FOLDS, [turn(NETS[7], 1)], [FAKES[4], FAKES[9], turn(FAKES[11], 1)]),
]

S413 = [
    net_pick(P_FOLDS, [NETS[3]], [FAKES[3], FAKES[7], FAKES[10]]),
    net_pick(P_FOLDS, [turn(NETS[8], 1)], [FAKES[0], turn(FAKES[2], 1), FAKES[6]]),
    net_pick(P_NOT, [NETS[5], turn(NETS[6], 1), NETS[9]], [FAKES[4]], odd_one="not"),
    net_pick(P_FOLDS, [NETS[10]], [turn(FAKES[1], 1), FAKES[9], turn(FAKES[5], 2)]),
    net_pick(P_NOT, [turn(NETS[2], 1), NETS[7], NETS[1]], [FAKES[11]], odd_one="not"),
    net_pick(P_FOLDS, [turn(NETS[6], 2)], [FAKES[3], turn(FAKES[8], 1), FAKES[7]]),
    net_pick(P_NOT, [NETS[4], turn(NETS[8], 1), NETS[0]], [turn(FAKES[10], 1)], odd_one="not"),
]

S414 = [
    net_q(turn(NETS[5], 2), 5, False),
    net_pick(P_NOT, [NETS[3], NETS[10], turn(NETS[1], 1)], [FAKES[6]], odd_one="not"),
    net_q(turn(NETS[7], 3), 6, False),
    net_pick(P_FOLDS, [turn(NETS[9], 1)], [FAKES[2], turn(FAKES[4], 1), FAKES[0]]),
    net_q(NETS[6], 7, False),
    dice(P_ROLL, 1, 2, 3, ["right", "down"], 4, 3, [0, 0]),
]

# ---- stacks used by 4.2's views ---------------------------------------------
# Rows run back to front, columns left to right, and every stack steps DOWN
# towards you, so each column's top is in view and a count has one answer.

H = {
    1: [[3, 2, 1], [2, 1, 1]],
    2: [[2, 2, 1], [1, 1, 0]],
    3: [[3, 3, 2], [3, 2, 1], [1, 1, 1]],
    4: [[4, 3, 2, 1], [2, 2, 1, 0]],
    5: [[3, 2], [3, 1], [2, 1]],
    6: [[4, 4, 2], [3, 2, 1], [2, 1, 0]],
    7: [[2, 1, 1, 1], [1, 1, 0, 0]],
    8: [[3, 3, 3], [2, 2, 2]],
    9: [[4, 2, 2], [4, 2, 1], [1, 1, 1]],
    10: [[3, 2, 2, 1], [3, 1, 1, 0], [2, 1, 0, 0]],
    11: [[2, 2], [2, 2], [1, 1]],
    12: [[4, 3, 1], [3, 3, 1], [2, 1, 1]],
    13: [[3, 1, 1], [2, 1, 0]],
    14: [[4, 4, 3, 2], [3, 2, 2, 1]],
}

# ---- 4.2 Rotating in 3D ----------------------------------------------------
# A shape turned, a marked cube tipped over, a dice rolled, and the view from
# another side (the source spine's "perspective"). The mirror image is always
# offered where a shape has one: it is the classic wrong answer, and no turn
# makes it match.

S421 = [
    polycube_pick(P_SAME, PC4[5], [PC4[2], PC4[7], PC4[1]], "a"),
    polycube_pick(P_SAME, PC4[6], [PC4[1], PC4[2], PC4[7]], "b"),
    polycube_pick(P_SAME, PC5[7], [PC5[11], PC5[13], PC5[9]], "c"),
    polycube_pick(P_SAME, PC5[9], [PC5[7], PC5[15], PC5[19]], "d"),
    polycube_pick(P_SAME, PC5[11], [PC5[13], PC5[16], PC5[7]], "e"),
    polycube_pick(P_SAME, PC5[20], [PC5[18], PC5[19], PC5[23]], "f"),
    polycube_pick(P_SAME, PC5[25], [PC5[26], PC5[27], PC5[13]], "g"),
]

S422 = [
    cube_turn(P_TURN("on top"), (STAR, HEART, CIRCLE), ["away"], "T"),
    cube_turn(P_TURN("on top"), (SQUARE, TRIANGLE, DIAMOND), ["left"], "T"),
    cube_turn(P_TURN("at the front"), (HEART, CIRCLE, STAR), ["spinR"], "F"),
    cube_turn(P_TURN("at the front"), (DIAMOND, STAR, SQUARE), ["toward"], "F"),
    cube_turn(P_TURN("on the right"), (TRIANGLE, SQUARE, HEART), ["right"], "R"),
    dice(P_ROLL, 1, 2, 3, ["right"], 4, 3, [0, 1]),
    dice(P_ROLL, 3, 6, 2, ["right", "right", "down"], 5, 3, [0, 0]),
]

S423 = [
    stack_view(P_FRONT, H[3], "front"),
    stack_view(P_RIGHT, H[4], "right"),
    stack_view(P_RIGHT, H[6], "right"),
    stack_view(P_FRONT, H[9], "front"),
    stack_count(P_COUNT, H[1]),
    stack_count(P_COUNT, H[5]),
    polycube_pick(P_SAME, PC5[15], [PC5[16], PC5[11], PC5[19]], "h"),
]

S424 = [
    polycube_pick(P_SAME, PC5[16], [PC5[15], PC5[25], PC5[13]], "i"),
    cube_turn(P_TURNS("on top"), (CIRCLE, DIAMOND, TRIANGLE), ["left", "away"], "T"),
    stack_view(P_FRONT, H[12], "front"),
    cube_turn(P_TURNS("at the front"), (HEART, SQUARE, DIAMOND), ["away", "spinR"], "F"),
    dice(P_ROLL, 6, 2, 3, ["up", "right", "right", "up", "right"], 5, 4, [0, 3]),
    cube_turn(P_TURNS("on the right"), (SQUARE, STAR, CIRCLE), ["right", "toward"], "R"),
]


# ---- 4.3 Cross-sections -----------------------------------------------------
# Cut a solid along the yellow plane and name the cut face. Every one of the
# twenty-two cuts is used once as a question; rs_grade.py computes each cut
# face from the geometry instead of trusting the table in the kit.

S431 = [
    section_shape(P_CUT, "cube", "across"),
    section_shape(P_CUT, "cuboid", "short"),
    section_shape(P_CUT, "cylinder", "across"),
    section_shape(P_CUT, "cylinder", "down"),
    section_shape(P_CUT, "triprism", "across"),
    section_shape(P_CUT, "hexprism", "down"),
    section_sides(P_SIDES, "hexprism", "across"),
]

S432 = [
    section_shape(P_CUT, "cone", "across"),
    section_shape(P_CUT, "cone", "down"),
    section_shape(P_CUT, "pyramid", "across"),
    section_shape(P_CUT, "pyramid", "down"),
    section_shape(P_CUT, "sphere", "across"),
    section_which(P_WHICH("triangle"), "triangle",
                  [("cone", "down"), ("cylinder", "down"), ("sphere", "across"), ("cuboid", "across")]),
    section_sides(P_SIDES, "cube", "down"),
]

S433 = [
    section_shape(P_CUT, "cube", "diagonal"),
    section_shape(P_CUT, "cube", "corner"),
    section_shape(P_CUT, "cube", "middle"),
    section_shape(P_CUT, "cylinder", "slant"),
    section_shape(P_CUT, "cone", "slant"),
    section_shape(P_CUT, "sphere", "slant"),
    section_which(P_WHICH("circle"), "circle",
                  [("sphere", "slant"), ("cylinder", "slant"), ("cone", "down"), ("cuboid", "short")]),
]

# The last stop in the skill: one question from every section.
S434 = [
    section_which(P_WHICH("square"), "square",
                  [("cuboid", "short"), ("cuboid", "long"), ("cone", "across"), ("triprism", "down")]),
    section_shape(P_CUT, "cuboid", "long"),
    section_which(P_WHICH("oval"), "oval",
                  [("cylinder", "slant"), ("sphere", "slant"), ("cylinder", "across"), ("cone", "down")]),
    section_sides(P_SIDES, "triprism", "down"),
    section_which(P_WHICH("hexagon"), "hexagon",
                  [("cube", "middle"), ("cube", "diagonal"), ("pyramid", "across"), ("triprism", "across")]),
    section_shape(P_CUT, "cuboid", "across"),
]
