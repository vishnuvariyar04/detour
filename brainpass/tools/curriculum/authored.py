# -*- coding: utf-8 -*-
"""Authored GridBot content for Think Like a Coder, Section 1.

Grid schema
  w,h        board size in tiles
  start      [x,y]  x = column, y = row counting UP from the bottom
  goal       [x,y]  flag
  walls      [[x,y]] impassable
  stars      [[x,y]] collectables
  key/door   [x,y]  door only opens if the key was picked up first
  program    [tok]  the program shown beside the board
  tok        up | down | left | right | pick | open | ?

Question shapes and the exact contract the gate renders for each
  predict     visual.program            answer cell    -> tap a tile
  count       visual optional           answer number  -> keypad
  spot|debug  visual.program            answer block   -> tap a block
  choose      options = [program,...]   answer option  -> tap a program card
  chooseText  optionsText = [str,...]   answer option  -> tap a text card
  complete    visual.program has "?"    optionsText, answer option
  compare     options = exactly 2       answer bool    -> Same / Different
  fix         blocks + slots            answer order   -> drag blocks into slots
              graded by SIMULATION: any arrangement that clears the board is
              accepted, so several right answers are fine
  inverse     blocks + slots            answer order   -> graded EXACTLY against
              the path drawn on the board
"""
from kit import (U, D, L, R, PICK, OPEN, g, q, rep, cell, opt, blk, num, yes, order,
                 ends, fails_at, step_count, shortest_steps, only_winner,
                 shortest_winner, same_end, stars_collected, route)

# ---------------------------------------------------------------- 1.1.1
S111 = [
 q("predict", "Nupo does these steps. Tap the square he ends on.",
   "Put your finger on Nupo. Move it one square for each step.",
   cell(1, 2), visual=g(program=[U, U, R])),

 q("spot", "Which step does Nupo do first? Tap it.",
   "Nupo always starts at the top of the list.",
   blk(0), visual=g(program=[U, R, U, R]), criterion="first"),

 q("count", "How many steps are in this list? Tap the number.",
   "Count the steps. Do not count the squares.",
   num(4), visual=g(program=[U, R, U, R])),

 q("choose", "Tap the list that takes Nupo to the flag.",
   "Count how many squares up the flag is. Then count across.",
   opt(1), visual=g(goal=(2, 1)),
   options=[[R, R, R], [R, R, U], [U, U, R]]),

 q("predict", "Same steps, but Nupo starts somewhere new. Tap the square he ends on.",
   "The steps did not change. Start from his new square.",
   cell(3, 2), visual=g(start=(2, 0), program=[U, U, R])),

 q("compare", "Do these two lists end on the same square? Tap your answer.",
   "Try each list from the same square. Only the last one matters.",
   yes(False), visual=g(),
   options=[[U, U, R], [U, R, R]]),

 q("fix", "Put the steps in order so Nupo gets the star.",
   "The star is two squares up and one across. Do both UP steps first.",
   order([U, U, R]), visual=g(stars=[(1, 2)], walls=[(1, 0)]),
   blocks=[R, U, U], slots=3),
]

# ---------------------------------------------------------------- 1.1.2
S112 = [
 q("compare", "Same three steps, new order. Do they end on the same square? "
              "Tap your answer.",
   "Watch the grey wall. It stops one of them.",
   yes(False), visual=g(walls=[(1, 0)]),
   options=[[R, U, U], [U, R, U]]),

 q("predict", "Two steps swapped places. Tap the square Nupo ends on.",
   "Read the steps in their new order, from the top.",
   cell(2, 1), visual=g(program=[R, R, U])),

 q("choose", "Only one of these gets Nupo to the flag. Tap it.",
   "Two of them bump into the wall. Find the one that does not.",
   opt(1), visual=g(goal=(2, 2), walls=[(1, 1)]),
   options=[[U, R, R, U], [R, R, U, U], [R, U, R, U]]),

 q("fix", "Put the steps in order to reach the flag.",
   "Which step hits the wall? Think what Nupo should do first.",
   order([R, R, U, U]), visual=g(goal=(2, 2), walls=[(1, 1)]),
   blocks=[R, U, R, U], slots=4),

 q("compare", "No wall this time. Do these two end on the same square? Tap "
              "your answer.",
   "Try both. With nothing in the way they may meet up.",
   yes(True), visual=g(),
   options=[[U, R], [R, U]]),

 q("debug", "A wall is in the way. Tap the first step Nupo cannot do.",
   "Go one step at a time. Stop when Nupo bumps the wall.",
   blk(2), visual=g(walls=[(2, 1)], program=[U, R, R, U])),

 q("predict", "Tap the square Nupo ends on.",
   "Do every step, right down to the last one.",
   cell(2, 2), visual=g(program=[U, R, U, R])),
]

# ---------------------------------------------------------------- 1.1.3
S113 = [
 q("debug", "This does not work. Tap the first step Nupo cannot do.",
   "Where is Nupo standing when each step happens?",
   blk(0), visual=g(key=(2, 0), door=(3, 0), program=[PICK, R, R, OPEN])),

 q("spot", "Which step must happen before OPEN? Tap it.",
   "Nupo needs the key in his hands first.",
   blk(2), visual=g(key=(2, 0), door=(3, 0), program=[R, R, PICK, R, OPEN]), criterion="pickup"),

 q("choose", "Tap the one that picks up the key AND opens the door.",
   "Nupo must stand on the key before he can pick it up.",
   opt(2), visual=g(key=(2, 0), door=(3, 0)),
   options=[[PICK, R, R, R, OPEN],
            [R, R, R, OPEN, PICK],
            [R, R, PICK, R, OPEN]]),

 q("fix", "Put the steps in order so Nupo opens the door.",
   "Walk to the key. Pick it up. Then go to the door.",
   order([R, R, PICK, R, OPEN]), visual=g(key=(2, 0), door=(3, 0)),
   blocks=[PICK, R, R, OPEN, R], slots=5),

 q("chooseText", "Nupo gets to the door with no key. Tap what happens.",
   "A step he cannot do just does not happen.",
   opt(1), visual=g(door=(2, 0), program=[R, R, OPEN]),
   optionsText=["The door opens anyway",
                "Nothing happens. The door stays shut",
                "Nupo walks backwards"]),

 q("complete", "One step is missing. Tap the one that goes in the gap.",
   "What must Nupo be holding when he gets to the door?",
   opt(0), visual=g(key=(2, 0), door=(3, 0), program=[R, R, "?", R, OPEN]),
   optionsText=["PICK UP", "UP", "LEFT"]),

 q("debug", "Tap the first step Nupo cannot do.",
   "He walks straight past something he needs.",
   blk(3), visual=g(key=(1, 0), door=(3, 0), program=[R, R, R, OPEN, PICK])),
]

# ---------------------------------------------------------------- 1.1.4  BOSS
S114 = [
 q("choose", "Tap the one that gets both stars and then the flag.",
   "Nupo must walk over both stars, not just reach the flag.",
   opt(0), visual=g(goal=(3, 2), stars=[(1, 0), (3, 1)]),
   options=[[R, R, R, U, U], [U, U, R, R, R], [R, U, U, R, R]]),

 q("fix", "Put the steps in order to get the star, then the flag.",
   "Pick up the star on the way past.",
   order([R, U, R, U]), visual=g(goal=(2, 2), stars=[(1, 1)]),
   blocks=[U, R, U, R], slots=4),

 q("debug", "Tap the first step that goes wrong.",
   "Look for the step that bumps into the wall.",
   blk(1), visual=g(goal=(3, 1), walls=[(2, 0)], program=[R, R, R, U])),

 q("predict", "Nupo takes four steps right. Tap the square he ends on.",
   "Do every step, even the ones after he passes the flag.",
   cell(4, 0), visual=g(goal=(2, 0), program=[R, R, R, R])),

 q("count", "What is the smallest number of steps that reaches the flag? Tap "
            "the number.",
   "Find the shortest way there. Then count the steps.",
   num(6), visual=g(goal=(3, 3), walls=[(1, 1)]), kind="shortest"),

 q("inverse", "The dots show where Nupo walked. Put the steps in that order.",
   "Follow the dots from Nupo. Name each move as you go.",
   order([U, R, R, D]), visual=g(program=[U, R, R, D]),
   blocks=[R, D, U, R], slots=4),
]

from u12 import S121, S122, S123, S124
from u13 import S131, S132, S133, S134
from u21 import S211, S212, S213, S214
from u22 import S221, S222, S223, S224
from u23 import S231, S232, S233, S234
from u31 import S311, S312, S313, S314
from u32 import S321, S322, S323, S324
from u33 import S331, S332, S333, S334
from u41 import S411, S412, S413, S414
from u42 import S421, S422, S423, S424
from u43 import S431, S432, S433, S434

AUTHORED = {
    "1.1.1": S111, "1.1.2": S112, "1.1.3": S113, "1.1.4": S114,
    "1.2.1": S121, "1.2.2": S122, "1.2.3": S123, "1.2.4": S124,
    "1.3.1": S131, "1.3.2": S132, "1.3.3": S133, "1.3.4": S134,
    "2.1.1": S211, "2.1.2": S212, "2.1.3": S213, "2.1.4": S214,
    "2.2.1": S221, "2.2.2": S222, "2.2.3": S223, "2.2.4": S224,
    "2.3.1": S231, "2.3.2": S232, "2.3.3": S233, "2.3.4": S234,
    "3.1.1": S311, "3.1.2": S312, "3.1.3": S313, "3.1.4": S314,
    "3.2.1": S321, "3.2.2": S322, "3.2.3": S323, "3.2.4": S324,
    "3.3.1": S331, "3.3.2": S332, "3.3.3": S333, "3.3.4": S334,
    "4.1.1": S411, "4.1.2": S412, "4.1.3": S413, "4.1.4": S414,
    "4.2.1": S421, "4.2.2": S422, "4.2.3": S423, "4.2.4": S424,
    "4.3.1": S431, "4.3.2": S432, "4.3.3": S433, "4.3.4": S434,
}

# ---------------------------------------------------------------- teach demos
# Each teach card animates its own board. It must NOT reuse a question's board:
# playing the answer to the question you are about to ask teaches nothing except
# that you can wait for the demo. These are deliberately 4x4 so a child can also
# see at a glance that the demo is not the puzzle.
TEACH_BOARDS = {
    "1.2.1": g(4, 4, (0, 0), walls=[(1, 1)], program=[U, R, R]),
    "1.2.2": g(4, 4, (0, 0), goal=(2, 1), program=[R, R]),
    "1.2.3": g(4, 4, (0, 0), program=[R, U, D, R]),
    "1.3.1": g(4, 4, (0, 0), program=[U, R, U]),
    "1.3.2": g(4, 4, (0, 0), program=[R, R, U]),
    "2.1.1": g(5, 5, (0, 0), program=rep(2, [R, U])),
    "2.1.2": g(5, 5, (0, 0), program=["repeat:2", R, "end", U]),
    "2.2.1": g(5, 5, (0, 0), program=rep(4, [U])),
    "2.2.2": g(5, 5, (0, 0), goal=(0, 2), program=rep(3, [U])),
    "2.2.3": g(5, 5, (0, 0), goal=(3, 0), program=rep(3, [R])),
    "2.3.1": g(5, 5, (0, 0), program=rep(2, rep(2, [R]))),
    "2.3.2": g(5, 5, (0, 0), program=rep(2, rep(2, [U]))),
    "2.3.3": g(5, 5, (0, 0), program=rep(2, rep(2, [R]))),
    "3.1.1": g(4, 4, (0, 0), stars=[(0, 1)], mustPick=True,
               program=[U, "if:star", PICK, "end"]),
    "3.1.2": g(4, 4, (0, 0), walls=[(0, 1)],
               program=["if:wall-up", R, "else", U, "end"]),
    "3.1.3": g(4, 4, (0, 0), stars=[(0, 2)], mustPick=True,
               program=rep(2, [U, "if:star", PICK, "end"])),
    # 3.2 and 3.3 used to teach from a facts-and-verdict card with no board on
    # it. Each of these runs the lesson instead: the demo shows the step being
    # taken or skipped, which is the whole idea in one animation.
    "3.2.1": g(4, 4, (0, 0), stars=[(1, 0)], mustPick=True,
               program=[R, "if:star", PICK, "end"]),
    "3.2.2": g(4, 4, (0, 0), walls=[(0, 1)],
               program=["if:wall-up", R, "else", U, "end"]),
    "3.2.3": g(4, 4, (0, 0), walls=[(1, 0)],
               program=["if:not-wall-up", U, "else", R, "end"]),
    "3.3.1": g(4, 4, (0, 0), stars=[(1, 0), (2, 0)], walls=[(2, 1)],
               mustPick=True,
               program=rep(2, [R, "if:star", "if:wall-up", PICK, "end", "end"])),
    "3.3.2": g(4, 4, (1, 0), stars=[(1, 0)], mustPick=True,
               program=["if:wall-right", U, "else", "if:star", U, "end", "end"]),
    "3.3.3": g(4, 4, (0, 0), stars=[(1, 0)], walls=[(1, 1)], mustPick=True,
               program=[R, "if:star", "if:wall-up", PICK, "end", "end", U]),
    "4.1.1": g(4, 4, (0, 0), walls=[(1, 0)], program=[R, U, R]),
    "4.1.2": g(4, 4, (0, 0), walls=[(0, 2)], program=[U, U, U]),
    "4.1.3": g(4, 4, (0, 0), program=[R, U, R, U]),
    "4.2.1": g(4, 4, (0, 0), vars={"COINS": 0},
               program=["add:COINS:1", "add:COINS:4", "add:COINS:2"]),
    "4.2.2": g(4, 4, (0, 0), vars={"COINS": 4},
               program=["set:COINS:1", "add:COINS:2"]),
    "4.2.3": g(4, 4, (0, 0), vars={"COINS": 0},
               program=["add:COINS:1", "add:COINS:1", "add:COINS:1"]),
    "4.3.1": g(4, 4, (0, 0), key=(1, 0), door=(2, 0),
               program=[R, "pick", R, "open"]),
    "4.3.2": g(4, 4, (0, 0), program=rep(2, [U, R])),
    "4.3.3": g(4, 4, (0, 0), vars={"COINS": 0},
               program=[U, "add:COINS:1", R]),
    "1.1.1": g(4, 4, (0, 0), program=[R, U, R]),
    "1.1.3": g(4, 4, (0, 0), key=(1, 0), door=(3, 0),
               program=[R, PICK, R, R, OPEN]),
}

# ---------------------------------------------------------------- kid copy
# Teach lines and stop titles as a child reads them. They override the spine in
# data.py, which is written for the adult building the curriculum.
TEACH_LINES = {
    "1.1.1": "Nupo does one step at a time. He starts at the top and works down.",
    "1.1.2": "The same steps in a different order can take Nupo somewhere else.",
    "1.1.3": "Some steps only work if Nupo did something else first.",
    "1.2.1": "Nupo does exactly what you say. He never guesses what you meant.",
    "1.2.2": "Leave one step out and Nupo lands in the wrong place.",
    "1.2.3": "Steps that undo each other still cost you. Shorter is better.",
    "1.3.1": "A good coder runs the steps in their head before pressing go.",
    "1.3.2": "Look at a path, then work out the steps that made it.",
    "1.3.3": "Lots of lists work. The best one gets there in the fewest steps.",
    "2.1.1": "When the same steps come back again and again, use a loop.",
    "2.1.2": "A loop needs a start and an end. The END row decides what repeats.",
    "2.1.3": "A loop does the same job in far fewer rows.",
    "2.2.1": "DO 4 TIMES means the steps inside run four times. Not three.",
    "2.2.2": "One time too many, or one too few. The most common bug there is.",
    "2.2.3": "Work out how far you must go. Then set the count to match.",
    "2.3.1": "The inside loop finishes fully every time the outside one goes round.",
    "2.3.2": "Outside count times inside count. That is how many times it runs.",
    "2.3.3": "Nesting helps when a pattern sits inside another pattern.",
    "3.1.1": "IF checks something first. If it is false, the steps are skipped.",
    "3.1.2": "IF and OR ELSE give two roads. Exactly one is always taken.",
    "3.1.3": "A condition can be checked many times and still fire only once.",
    "3.2.1": "A check looks at the square Nupo is on. Or the one beside him.",
    "3.2.2": "A wall check asks if the next square is free. The board edge counts as a wall.",
    "3.2.3": "NOT reads the check backwards. Blocked becomes clear, clear becomes blocked.",
    "3.3.1": "A check inside a check. The step only happens when both say yes.",
    "3.3.2": "Two roads to the same step. Either check can send him down its road.",
    "3.3.3": "Real ones use both. Two checks can guard one step, or reach it.",
    "4.1.1": "To find a bug, run it and watch where it stops making sense.",
    "4.1.2": "Once one step is wrong, every step after it looks wrong too.",
    "4.1.3": "Say what you think will happen. If you are wrong, you found a bug.",
    "4.2.1": "A box holds a number. You can look inside, and you can change it.",
    "4.2.2": "SET puts a new number in. ADD changes the one already there.",
    "4.2.3": "Write down what the box holds at each step. The bug shows up.",
    "4.3.1": "Big jobs are small jobs stacked up. Do them one at a time.",
    "4.3.2": "Steps you keep using deserve a name you can use again.",
    "4.3.3": "Real ones use steps, loops, conditions and boxes together.",
}

# A teach card for a logic stop shows the idea itself: the facts, the condition
# and the verdict. A grid with a walking owl on it would be decoration for a
# lesson that has nothing to do with the board.
# Some ideas cannot be shown by one run. "Order changes everything" needs two
# orders; "the shortest way" needs a long route beside a short one. These play
# two programs on two boards at once, so the difference is the whole picture.
TEACH_COMPARE = {
    "1.1.2": (g(4, 4, (0, 0), walls=[(1, 0)]), [U, R, R], [R, R, U]),
    "1.3.3": (g(5, 5, (0, 0), goal=(2, 1)), [R, R, U], [U, R, D, R, U]),
    # six rows against three: the saving has to be visible at a glance
    "2.1.3": (g(7, 7, (0, 0)), [R, R, R, R, R, R], rep(6, [R])),
    "2.3.3": (g(5, 5, (0, 0)), [R, R, R, R], rep(2, rep(2, [R]))),
}

# Nothing teaches from a bare condition any more. The dict stays because the
# emitter still reads it, and because an empty one states plainly that the
# facts-and-verdict card was retired rather than merely gone unused.
TEACH_TRUTH = {}

TITLES = {
    "1.1.1": "One step at a time",
    "1.1.2": "Order changes everything",
    "1.1.3": "First things first",
    "1.1.4": "Boss level",
    "1.2.1": "Exactly what you say",
    "1.2.2": "A missing step",
    "1.2.3": "No wasted steps",
    "1.2.4": "Boss level",
    "1.3.1": "Run it in your head",
    "1.3.2": "From path to steps",
    "1.3.3": "The shortest way",
    "1.3.4": "Boss level",
    "2.1.1": "Spot the repeat",
    "2.1.2": "Where the loop ends",
    "2.1.3": "Fewer rows, same job",
    "2.1.4": "Boss level",
    "2.2.1": "Exactly this many times",
    "2.2.2": "One too many",
    "2.2.3": "Picking the count",
    "2.2.4": "Boss level",
    "2.3.1": "A loop inside a loop",
    "2.3.2": "Counting them all",
    "2.3.3": "When nesting helps",
    "2.3.4": "Boss level",
    "3.1.1": "Only if",
    "3.1.2": "This road or that one",
    "3.1.3": "Checked a lot, done rarely",
    "3.1.4": "Boss level",
    "3.2.1": "Under his feet",
    "3.2.2": "Blocked or clear",
    "3.2.3": "The other way round",
    "3.2.4": "Boss level",
    "3.3.1": "Both must be true",
    "3.3.2": "Either will do",
    "3.3.3": "Both and either",
    "3.3.4": "Boss level",
    "4.1.1": "Run it and watch",
    "4.1.2": "The first wrong step",
    "4.1.3": "Guess, then check",
    "4.1.4": "Boss level",
    "4.2.1": "A box with a number",
    "4.2.2": "SET and ADD",
    "4.2.3": "Keep a table",
    "4.2.4": "Boss level",
    "4.3.1": "One part at a time",
    "4.3.2": "Name it once",
    "4.3.3": "All of it together",
    "4.3.4": "Boss level",
}
