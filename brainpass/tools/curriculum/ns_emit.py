# -*- coding: utf-8 -*-
"""Builds assets/curriculum/number_sense.json from ns_units.py.

Run:  python ns_emit.py && python ns_simulate.py
"""
import io, json, os, sys

import ns_units as U

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "assets", "curriculum", "number_sense.json")

SECTIONS = [
    (1, "Counting", "Every number is a pile you can count."),
    (2, "Making numbers", "Numbers are made of other numbers."),
    (3, "Looking", "Shapes, patterns and the odd one out."),
    (4, "Putting it together", "Everything so far, mixed up."),
]

UNITS = {
    "1.1": "How many",
    "1.2": "More and fewer",
    "1.3": "Where numbers live",
    "2.1": "Parts of a number",
    "2.2": "Past ten",
    "2.3": "Tens and pieces",
    "3.1": "Odd one out",
    "3.2": "Shapes inside shapes",
    "3.3": "Rules and order",
    "4.1": "Bigger numbers",
    "4.2": "Parts and pieces",
    "4.3": "All of it",
}

# One line a child hears before the first question of a stop. Short, concrete,
# and about the picture in front of them rather than about mathematics.
TITLES = {
    "1.1.1": ("Count them", "Touch each one as you say the number."),
    "1.1.2": ("Count them all", "Count every one, and only once each."),
    "1.1.3": ("A full frame is ten", "Five in a row. Two rows make ten."),
    "1.1.4": ("How many?", None),
    "1.2.1": ("Which side is heavier", "The heavier side goes down."),
    "1.2.2": ("More and fewer", "More things means the side dips lower."),
    "1.2.3": ("Big and small", "Smallest first, then the next one up."),
    "1.2.4": ("More or fewer", None),
    "1.3.1": ("Hop along the line", "Each hop is one step to the next number."),
    "1.3.2": ("Longer hops", "Count each hop out loud as it lands."),
    "1.3.3": ("Fold it over", "Each square has a partner across the line."),
    "1.3.4": ("Lines and folds", None),
    "2.1.1": ("A number has parts", "Six is four and two. Both parts make the whole."),
    "2.1.2": ("Friends of ten", "Two parts that make ten are a pair worth knowing."),
    "2.1.3": ("Find the missing part", "The whole is at the top; the parts are below."),
    "2.1.4": ("Parts and wholes", None),
    "2.2.1": ("Two dice", "Know each face, then put them together."),
    "2.2.2": ("Ten and some more", "A full frame is ten. Count on from ten."),
    "2.2.3": ("Tens and ones", "Each tall stick is ten blocks."),
    "2.2.4": ("Past ten", None),
    "2.3.1": ("Cut into pieces", "More colour means more of the circle."),
    "2.3.2": ("Bigger pieces", "Fewer cuts means each piece is bigger."),
    "2.3.3": ("Sticks and cubes", "Count the sticks first, then the loose ones."),
    "2.3.4": ("Pieces and blocks", None),
    "3.1.1": ("One is different", "Three of them share something. One does not."),
    "3.1.2": ("Put them in groups", "Check each one against the label."),
    "3.1.3": ("What comes next", "Say the pattern out loud as you point."),
    "3.1.4": ("Sorting and patterns", None),
    "3.2.1": ("Shapes inside shapes", "A big shape can be made of smaller ones."),
    "3.2.2": ("Look again", "Some shapes share their edges. Look twice."),
    "3.2.3": ("Both halves match", "Fold the picture and the halves land on each other."),
    "3.2.4": ("Hidden shapes", None),
    "3.3.1": ("Order and rules", "Smallest first, and every pattern has a rule."),
    "3.3.2": ("Sort and continue", "Work out the rule before you answer."),
    "3.3.3": ("Rules everywhere", "Size, shape, colour: any of them can be the rule."),
    "3.3.4": ("Looking carefully", None),
    "4.1.1": ("Bigger numbers", "Everything so far, with larger numbers."),
    "4.1.2": ("Keep counting on", "Hops and sticks both get you there."),
    "4.1.3": ("Numbers to fifty", "Count the tens first. Then the ones."),
    "4.1.4": ("Big numbers", None),
    "4.2.1": ("Two colours", "Count only the ones you are asked for."),
    "4.2.2": ("Which is more", "Compare how much of each circle is filled."),
    "4.2.3": ("Shapes and folds", "Look, fold, and put things in order."),
    "4.2.4": ("Parts and pieces", None),
    "4.3.1": ("All of it", "Every kind of question, mixed together."),
    "4.3.2": ("Looking and sorting", "Rules, shapes and order, all at once."),
    "4.3.3": ("Numbers and pieces", "Counting, hopping, sticks and slices."),
    "4.3.4": ("The last climb", None),
}


# What each stop demonstrates before its first question.
#
# A teach card with the right words over the wrong picture teaches worse than
# no picture, so every one of these is drawn from the same vocabulary the
# stop's own questions use.
TEACH_PICS = {
    "1.1.1": {"kind": "count", "n": 5, "glyph": "star"},
    "1.1.2": {"kind": "count", "n": 8, "glyph": "heart"},
    "1.1.3": {"kind": "tenFrame", "filled": 7, "glyph": "circle"},
    "1.2.1": {"kind": "balance", "leftCount": 6, "rightCount": 3, "glyph": "star"},
    "1.2.2": {"kind": "barModel", "a": 9, "b": 5, "ask": "more"},
    "1.2.3": {"kind": "sizeOrder", "sizes": [0.4, 1.0, 0.7], "glyph": "star"},
    "1.3.1": {"kind": "numberLine", "from": 0, "to": 10, "hopFrom": 3,
              "marker": 3, "labelEvery": 1},
    "1.3.2": {"kind": "numberLine", "from": 0, "to": 20, "hopFrom": 8,
              "marker": 8, "labelEvery": 5},
    "1.3.3": {"kind": "mirror", "cols": 6, "rows": 5,
              "given": [[0, 1], [1, 1], [2, 2]]},
    "2.1.1": {"kind": "bond", "whole": 6, "left": 4, "right": 2, "gap": "none"},
    "2.1.2": {"kind": "tenFrame", "filled": 6, "glyph": "circle"},
    "2.1.3": {"kind": "bond", "left": 5, "right": 3, "gap": "whole"},
    "2.2.1": {"kind": "dice", "faces": [4, 3]},
    "2.2.2": {"kind": "tenFrame", "filled": 10, "second": 4, "glyph": "circle"},
    "2.2.3": {"kind": "rods", "n": 23},
    "2.3.1": {"kind": "fraction", "slices": 2, "shaded": 1,
              "otherSlices": 4, "otherShaded": 1},
    "2.3.2": {"kind": "fraction", "slices": 4, "shaded": 3,
              "otherSlices": 8, "otherShaded": 3},
    "2.3.3": {"kind": "rods", "n": 35},
    "3.1.1": {"kind": "oddOneOut", "cells": [
        {"kind": "square", "color": "primary"},
        {"kind": "square", "color": "primary"},
        {"kind": "triangle", "color": "primary"},
        {"kind": "square", "color": "primary"}]},
    "3.1.2": {"kind": "sortTwo", "leftLabel": "ROUND", "rightLabel": "NOT ROUND",
              "cells": [
                  {"kind": "circle", "color": "primary"},
                  {"kind": "square", "color": "primary"},
                  {"kind": "circle", "color": "accent"},
                  {"kind": "triangle", "color": "primary"}]},
    "3.1.3": {"kind": "pattern", "gapAt": 4, "cells": [
        {"kind": "star", "color": "primary"},
        {"kind": "heart", "color": "accent"},
        {"kind": "star", "color": "primary"},
        {"kind": "heart", "color": "accent"},
        {"kind": "star", "color": "primary"}]},
    "3.2.1": {"kind": "shapeHunt", "figure": "house", "target": "square"},
    "3.2.2": {"kind": "shapeHunt", "figure": "rocket", "target": "triangle"},
    "3.2.3": {"kind": "mirror", "cols": 6, "rows": 5,
              "given": [[0, 0], [1, 2], [2, 1]]},
    "3.3.1": {"kind": "sizeOrder", "sizes": [0.3, 0.9, 0.6], "glyph": "hexagon"},
    "3.3.2": {"kind": "sortTwo", "leftLabel": "YELLOW", "rightLabel": "PURPLE",
              "cells": [
                  {"kind": "star", "color": "accent"},
                  {"kind": "star", "color": "primary"},
                  {"kind": "heart", "color": "accent"}]},
    "3.3.3": {"kind": "pattern", "gapAt": 3, "cells": [
        {"kind": "triangle", "color": "primary", "rotation": 0},
        {"kind": "triangle", "color": "primary", "rotation": 90},
        {"kind": "triangle", "color": "primary", "rotation": 180},
        {"kind": "triangle", "color": "primary", "rotation": 270}]},
    "4.1.1": {"kind": "array", "rows": 3, "cols": 4, "glyph": "circle"},
    "4.1.2": {"kind": "groups", "groups": 4, "per": 3, "glyph": "star"},
    "4.1.3": {"kind": "groups", "groups": 3, "per": 5, "glyph": "heart",
              "share": True},
    "4.2.1": {"kind": "count", "n": 7, "splitAt": 4, "glyph": "star"},
    "4.2.2": {"kind": "fractionWall", "rows": [[2, 1], [4, 2], [3, 1]]},
    "4.2.3": {"kind": "shapeHunt", "figure": "tree", "target": "triangle"},
    "4.3.1": {"kind": "bond", "whole": 9, "left": 7, "gap": "right"},
    "4.3.2": {"kind": "oddOneOut", "cells": [
        {"kind": "hexagon", "color": "primary"},
        {"kind": "hexagon", "color": "primary"},
        {"kind": "star", "color": "primary"},
        {"kind": "hexagon", "color": "primary"}]},
    "4.3.3": {"kind": "tenFrame", "filled": 10, "second": 6, "glyph": "circle"},
}


def build():
    sections = []
    for sn, sname, spromise in SECTIONS:
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
                    "authored": True,
                    "boss": stop_n == 4,
                    "questions": qs,
                }
                if line:
                    stop["teach"] = {"line": line}
                    pic = TEACH_PICS.get(sid)
                    if pic:
                        pic = dict(pic)
                        # A hunt's geometry travels with it, the same as a
                        # question's, so there is still only one source.
                        if pic.get("figure"):
                            import figures as _F
                            pic["parts"] = _F.parts_json(pic["figure"])
                        stop["teach"]["pic"] = pic
                stops.append(stop)
            units.append({"n": un, "title": UNITS[uid], "stops": stops})
        sections.append({"n": sn, "title": sname, "subtitle": spromise,
                         "units": units})

    return {
        "id": "number_sense",
        "name": "Number Sense",
        "band": "a",
        "ages": "5-6",
        "promise": "Your child will count, compare and take numbers apart - "
                   "and see the shapes and patterns hiding in plain sight.",
        "sections": sections,
    }


if __name__ == "__main__":
    skill = build()
    n_stops = sum(len(u["stops"]) for s in skill["sections"] for u in s["units"])
    n_qs = sum(len(st["questions"]) for s in skill["sections"]
               for u in s["units"] for st in u["stops"])
    io.open(OUT, "w", encoding="utf-8").write(json.dumps(skill, indent=1))
    print(f"stops={n_stops} questions={n_qs} -> {os.path.relpath(OUT, HERE)}")
    if n_stops != 48 or n_qs != 324:
        sys.exit(f"expected 48 stops and 324 questions, got {n_stops}/{n_qs}")
