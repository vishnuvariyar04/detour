# -*- coding: utf-8 -*-
"""Builds assets/curriculum/puzzles_and_logic.json from pz_units.py.

Run:  python pz_emit.py && python pz_simulate.py && python pz_grade.py
"""
import io, json, os

import pz_units as U
from puzzles_kit import (
    STAR, HEART, CIRCLE, SQUARE, TRIANGLE, DIAMOND, HEXAGON, FLOWER,
    PRIMARY, ACCENT, cell, item, repeat_strip,
)

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "assets", "curriculum",
                   "puzzles_and_logic.json")

SECTIONS = [
    (1, "Patterns", "A pattern is a rule you can see."),
    (2, "Rules", "Every puzzle hides a rule. Find it, then use it."),
    (3, "Codes", "A code swaps one thing for another."),
    (4, "Logic", "Work it out from what you already know."),
]

UNITS = {
    "1.1": "Repeating patterns",
    "1.2": "Number steps",
    "1.3": "Growing patterns",
    "2.1": "What is the rule",
    "2.2": "Odd one out",
    "2.3": "Sorting into groups",
    "3.1": "Analogies",
    "3.2": "Symbol codes",
    "3.3": "Two-step codes",
    "4.1": "True or false",
    "4.2": "What is missing",
    "4.3": "Putting it together",
}

# (stop title, teach line). A boss carries None: both shipped skills leave their
# twelve bosses with no teach card at all, and a boss that arrives with a worked
# example is not a boss.
TITLES = {
    "1.1.1": ("What comes next", "A pattern repeats. Find the part that repeats and say it again."),
    "1.1.2": ("The hole in the row", "Read the row from both sides of the gap."),
    "1.1.3": ("Two things changing", "The shape repeats on one beat, the colour on another."),
    "1.1.4": ("Repeating patterns", None),
    "1.2.1": ("Hops of two", "Every hop is the same size. Count them as they land."),
    "1.2.2": ("Hops of five and ten", "Bigger hops, fewer of them, same idea."),
    "1.2.3": ("Hopping back", "The same rule read the other way. Every hop goes down."),
    "1.2.4": ("Number steps", None),
    "1.3.1": ("Rows that grow", "One row, then another the same. Count a row, then the rows."),
    "1.3.2": ("Growing by the same amount", "Each day it grows by the same number."),
    "1.3.3": ("Smallest to biggest", "Find the smallest one first, then the next one up."),
    "1.3.4": ("Growing patterns", None),
    "2.1.1": ("Follow the rule", "The label says what belongs. Check one shape at a time."),
    "2.1.2": ("A rule about colour", "The shape does not matter here. Only the colour does."),
    "2.1.3": ("A rule about corners", "Count the corners rather than naming the shape."),
    "2.1.4": ("What is the rule", None),
    "2.2.1": ("The different shape", "Three are the same. One is not."),
    "2.2.2": ("The different colour", "Same shape every time, so look at the colour."),
    "2.2.3": ("The one that is turned", "Nothing changes but the way it faces."),
    "2.2.4": ("Odd one out", None),
    "2.3.1": ("Two groups", "Both trays have a name. Nothing is left over."),
    "2.3.2": ("Grouping by colour", "Two colours, two trays."),
    "2.3.3": ("Grouping by corners", "Sort by what the shape is like, not what it is called."),
    "2.3.4": ("Sorting into groups", None),
    "3.1.1": ("The same change", "The first pair changed. Do the same to the second."),
    "3.1.2": ("One becomes many", "Count what the first pair did, then do it again."),
    "3.1.3": ("Bigger, smaller, turned", "The change is not always colour or number."),
    "3.1.4": ("Analogies", None),
    "3.2.1": ("A key to read", "The key says what each symbol is worth. Read it first."),
    "3.2.2": ("A new key", "A different key. The symbols are worth new numbers now."),
    "3.2.3": ("Longer rows", "More symbols to add, but the key works the same way."),
    "3.2.4": ("Symbol codes", None),
    "3.3.1": ("The missing symbol", "Add what you can see, then take it from the total."),
    "3.3.2": ("Bigger numbers", "Same two steps. The key is worth more this time."),
    "3.3.3": ("Three in the row", "More to add before the gap gives itself away."),
    "3.3.4": ("Two-step codes", None),
    "4.1.1": ("Yes or no", "Check the rule against one shape at a time."),
    "4.1.2": ("Check every one", "Some belong and some do not. Every shape needs an answer."),
    "4.1.3": ("Two things at once", "Both parts have to be true, not just one."),
    "4.1.4": ("True or false", None),
    "4.2.1": ("The gap in the middle", "Look at both sides of the hole before you choose."),
    "4.2.2": ("Colour in the gap", "The colour repeats too. The gap needs both to be right."),
    "4.2.3": ("Longer rules", "The part that repeats is longer here. Find it first."),
    "4.2.4": ("What is missing", None),
    "4.3.1": ("All of it", "Every kind of puzzle so far, mixed up."),
    "4.3.2": ("All of it again", "Read each one carefully. They are not in any order."),
    "4.3.3": ("The hardest ones", "Take your time. You have done all of these before."),
    "4.3.4": ("Puzzles and logic", None),
}


def _strip_pic(unit, times, extra, gap):
    return {"kind": "pattern", "cells": repeat_strip(unit, times, extra),
            "gapAt": gap}


def _sort_pic(cells, left, right):
    return {"kind": "sortTwo", "cells": cells, "leftLabel": left,
            "rightLabel": right}


def _code_pic(key, row, gap_at=None, total=None):
    pic = {"kind": "code", "key": [{"glyph": k, "n": v} for k, v in key],
           "row": list(row)}
    if gap_at is not None:
        pic["gapAt"] = gap_at
        pic["total"] = total
    return pic


_SQ, _TR, _CI = cell(SQUARE), cell(TRIANGLE), cell(CIRCLE)
_ST, _HE, _HX = cell(STAR), cell(HEART), cell(HEXAGON)
_DI, _FL = cell(DIAMOND), cell(FLOWER)
_STy, _CIy = cell(STAR, ACCENT), cell(CIRCLE, ACCENT)
_HEy, _TRy = cell(HEART, ACCENT), cell(TRIANGLE, ACCENT)

# One picture per non-boss stop. Deliberately NOT a copy of any question in its
# own stop -- an animation that plays the answer before the question is asked is
# rejected by the checker, and rightly.
#
# These are static, unlike the coder skill's, which animate. That skill animates
# because a program running is temporal: you have to watch the steps happen in
# order or the idea does not land. Band b's content is relational -- a pattern, a
# rule, a key -- and none of it unfolds over time. The exception is unit 1.2,
# where hopping along a number line genuinely does, so those three animate.
TEACH_PICS = {
    "1.1.1": _strip_pic([_CI, _HE, _HE], 2, 1, 6),
    "1.1.2": _strip_pic([_ST, _SQ, _DI], 3, 0, 4),
    "1.1.3": _strip_pic([_HX, cell(HEXAGON, ACCENT)], 3, 1, 6),
    "1.2.1": {"kind": "numberLine", "from": 0, "to": 20, "labelEvery": 5,
              "hopFrom": 0, "marker": 0, "step": 2, "hops": 3},
    "1.2.2": {"kind": "numberLine", "from": 0, "to": 30, "labelEvery": 5,
              "hopFrom": 0, "marker": 0, "step": 5, "hops": 4},
    "1.2.3": {"kind": "numberLine", "from": 0, "to": 20, "labelEvery": 5,
              "hopFrom": 16, "marker": 16, "step": -4, "hops": 3},
    "1.3.1": {"kind": "array", "rows": 2, "cols": 3, "glyph": CIRCLE},
    "1.3.2": {"kind": "numberLine", "from": 0, "to": 25, "labelEvery": 5,
              "hopFrom": 2, "marker": 2, "step": 4, "hops": 4},
    "1.3.3": {"kind": "sizeOrder", "sizes": [2, 4, 1, 3], "glyph": STAR},
    "2.1.1": _sort_pic([_HE, _CI, _HE], "HEART", "NOT A HEART"),
    "2.1.2": _sort_pic([_CIy, _CI, _HEy], "YELLOW", "NOT YELLOW"),
    "2.1.3": _sort_pic([_TR, _CI, _SQ], "3 CORNERS", "NOT 3"),
    "2.2.1": {"kind": "oddOneOut", "cells": [_CI, _CI, _HE, _CI]},
    "2.2.2": {"kind": "oddOneOut", "cells": [_HEy, _HEy, _HE, _HEy]},
    "2.2.3": {"kind": "oddOneOut", "cells": [
        cell(TRIANGLE), cell(TRIANGLE, rotation=90), cell(TRIANGLE),
        cell(TRIANGLE)]},
    "2.3.1": _sort_pic([_ST, _TR, _ST, _TR], "STARS", "TRIANGLES"),
    "2.3.2": _sort_pic([_TRy, _TR, _CIy, _CI], "YELLOW", "PURPLE"),
    "2.3.3": _sort_pic([_SQ, _TR, _DI, _TR], "4 CORNERS", "3 CORNERS"),
    "3.1.1": {"kind": "analogy", "a": item(FLOWER), "b": item(FLOWER, ACCENT),
              "c": item(HEXAGON)},
    "3.1.2": {"kind": "analogy", "a": item(HEXAGON), "b": item(HEXAGON, n=2),
              "c": item(DIAMOND)},
    "3.1.3": {"kind": "analogy", "a": item(FLOWER), "b": item(FLOWER, size=2),
              "c": item(HEART)},
    "3.2.1": _code_pic([(STAR, 1), (HEART, 2), (CIRCLE, 3)], [STAR, CIRCLE]),
    "3.2.2": _code_pic([(TRIANGLE, 2), (SQUARE, 3), (HEXAGON, 5)], [TRIANGLE, HEXAGON]),
    "3.2.3": _code_pic([(FLOWER, 1), (DIAMOND, 4), (CIRCLE, 5)], [FLOWER, DIAMOND, FLOWER]),
    "3.3.1": _code_pic([(STAR, 1), (HEART, 2), (CIRCLE, 3), (DIAMOND, 4)],
                       [STAR, CIRCLE], 1, 4),
    "3.3.2": _code_pic([(TRIANGLE, 2), (SQUARE, 4), (HEXAGON, 6), (FLOWER, 8)],
                       [TRIANGLE, TRIANGLE], 1, 6),
    "3.3.3": _code_pic([(STAR, 1), (HEART, 2), (CIRCLE, 3), (DIAMOND, 4)],
                       [HEART, STAR, CIRCLE], 2, 5),
    "4.1.1": _sort_pic([_ST, _CI, _ST], "YES", "NO"),
    "4.1.2": _sort_pic([_TRy, _CI, _TR, _HE], "YES", "NO"),
    "4.1.3": _sort_pic([_STy, _ST, _CIy], "YES", "NO"),
    "4.2.1": _strip_pic([_DI, _HX, _HX], 3, 0, 5),
    "4.2.2": _strip_pic([_CI, _CIy, _TR], 3, 0, 4),
    "4.2.3": _strip_pic([_HE, _ST, _SQ, _FL], 2, 0, 3),
    "4.3.1": _strip_pic([_FL, _DI, _FL], 3, 0, 6),
    "4.3.2": {"kind": "oddOneOut", "cells": [_SQ, _SQ, _SQ, _TR]},
    "4.3.3": _code_pic([(STAR, 1), (HEART, 2), (CIRCLE, 3)], [HEART, HEART]),
}


# Shapes CoderGate can draw TODAY. Its main when(q.shape) has no else branch, so
# a shape missing from this set renders the prompt and nothing else: no picture
# and no control to answer with. A child meeting one is stuck on it forever.
#
# So any stop holding such a question is emitted authored:false. The roadmap
# already draws unauthored stops greyed out as "coming soon", which is the
# mechanism's intended use -- the whole 48-stop shape stays visible while only
# the playable stops are served.
#
# Adding AnalogyView and CodeView to the gate means adding their shape names
# here, and the skill turns itself on. Nothing else to remember.
DRAWN_TODAY = {
    "pattern", "numberLine", "countObjects", "array", "oddOneOut", "sortTwo",
    "sizeOrder",
}

NEW_SHAPES = {"analogy", "codeRead", "codePick"}


def _playable(questions):
    return all(q["shape"] in DRAWN_TODAY for q in questions)


def build():
    sections = []
    for sn, sname, ssub in SECTIONS:
        units = []
        for un in (1, 2, 3):
            uid = f"{sn}.{un}"
            stops = []
            for stop_n in (1, 2, 3, 4):
                sid = f"{uid}.{stop_n}"
                key = "S" + sid.replace(".", "")
                qs = getattr(U, key, None)
                if qs is None:
                    raise SystemExit(f"missing {key}")
                title, line = TITLES[sid]
                stop = {
                    "id": sid,
                    "title": title,
                    "authored": _playable(qs),
                    "boss": stop_n == 4,
                    "questions": qs,
                }
                if line:
                    stop["teach"] = {"line": line}
                    pic = TEACH_PICS.get(sid)
                    if pic:
                        stop["teach"]["pic"] = pic
                stops.append(stop)
            units.append({"n": un, "title": UNITS[uid], "stops": stops})
        sections.append({"n": sn, "title": sname, "subtitle": ssub,
                         "units": units})
    return {
        "id": "puzzles_and_logic",
        "name": "Puzzles & Logic",
        # Lowercase, always. An uppercase band here would make the roadmap pick
        # a different skill than the gate serves; that shipped once already.
        "band": "b",
        "ages": "7-8",
        "promise": "Your child will spot the pattern, name the rule behind it, "
                   "and crack a code that uses it.",
        "sections": sections,
    }


if __name__ == "__main__":
    skill = build()
    io.open(OUT, "w", encoding="utf-8").write(
        json.dumps(skill, indent=1, ensure_ascii=False))
    n_stops = sum(len(u["stops"]) for s in skill["sections"] for u in s["units"])
    n_qs = sum(len(st["questions"]) for s in skill["sections"]
               for u in s["units"] for st in u["stops"])
    n_teach = sum(1 for s in skill["sections"] for u in s["units"]
                  for st in u["stops"] if st.get("teach"))
    n_auth = sum(1 for s in skill["sections"] for u in s["units"]
                 for st in u["stops"] if st["authored"])
    print(f"stops={n_stops} authored={n_auth} questions={n_qs} teach={n_teach} "
          f"-> {os.path.relpath(OUT, HERE)}")
    if n_auth < n_stops:
        held = [st["id"] for s in skill["sections"] for u in s["units"]
                for st in u["stops"] if not st["authored"]]
        print(f"  {n_stops - n_auth} stops held back until the gate can draw "
              f"{sorted(NEW_SHAPES)}:")
        print(f"  {', '.join(held)}")
