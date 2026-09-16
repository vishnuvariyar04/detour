# -*- coding: utf-8 -*-
"""Builds the Reasoning skill (band d, ages 11-12) from rs_units.py.

Run:  python rs_emit.py && python rs_simulate.py && python rs_grade.py

WHERE IT GOES, AND WHY NOT assets/curriculum. The gate serves a child the most
advanced skill whose band they have reached, and an eleven year old today gets
Think Like a Coder -- a full, playable ladder. Every question in this skill uses
a drawing CoderGate cannot make yet, and its when(q.shape) has no else branch,
so those questions would render a prompt and nothing else. Dropping this file
into assets/curriculum would switch every band d child from a working skill to a
skill with no playable stop in it.

It is written to assets/curriculum/, which the gate scans, so these questions
reach children. A stop is only put on the ladder when every shape in it is one
CoderGate can draw, and that set is read from CoderGate rather than copied --
see drawable.py for why.
"""
import io, json, os

import drawable
import rs_units as U
import reasoning_kit as K

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "assets", "curriculum", "reasoning.json")

# What CoderGate can draw, read from CoderGate. Never hand-written: the
# hand-written version went stale the moment the views were built, and every
# stop in this skill was marked unplayable while looking fine.
DRAWN_TODAY = drawable.gate_shapes("d")

SECTIONS = [
    (1, "Sequences", "Every pattern has a rule. Find it, then push it further."),
    (2, "Logic", "Work out what must be true, and what only seems true."),
    (3, "Codes", "A code is a rule you can run backwards."),
    (4, "Space", "Picture it, then turn it in your head."),
]

UNITS = {
    "1.1": "The next term", "1.2": "The nth term",
    "1.3": "Squares, cubes, second differences",
    "2.1": "If and then", "2.2": "Always, sometimes, never", "2.3": "Deduction grids",
    "3.1": "Binary", "3.2": "Shift ciphers", "3.3": "Substitution",
    "4.1": "3D nets", "4.2": "Rotating in 3D", "4.3": "Cross-sections",
}

# (title, teach line). None on a boss: both shipped skills leave all twelve of
# their bosses without a teach card, and so does band b.
TITLES = {
    "1.1.1": ("Big steps", "Find the step between two numbers, then check it works for every pair."),
    "1.1.2": ("Below zero", "A pattern can carry on past zero. The step stays the same."),
    "1.1.3": ("Times patterns", "Some patterns multiply. Check every step, not just the first."),
    "1.1.4": ("The next term", None),
    "1.2.1": ("The 10th number", "The 10th number is the 1st number plus 9 steps."),
    "1.2.2": ("Far along", "No need to write them all out. Count the steps, then multiply."),
    "1.2.3": ("Which position?", "Take away the 1st number, divide by the step, then add 1."),
    "1.2.4": ("The nth term", None),
    "1.3.1": ("Squares and triangles", "Square numbers are 1x1, 2x2, 3x3. Triangle numbers add 1, 2, 3, 4."),
    "1.3.2": ("Cube numbers", "Cube numbers are 1x1x1, 2x2x2, 3x3x3."),
    "1.3.3": ("The gaps between the gaps", "If the steps keep growing, look at how much they grow by."),
    "1.3.4": ("Squares and cubes", None),
    "2.1.1": ("What must be true", "If the first part is true, the second part must be true too."),
    "2.1.2": ("When you cannot tell", "A rule only works one way. Do not run it backwards."),
    "2.1.3": ("Truth-tellers and liars", "Pretend they tell the truth. If that cannot work, they are lying."),
    "2.1.4": ("If and then", None),
    "2.2.1": ("Odd and even", "One example that fails means it is not always true."),
    "2.2.2": ("Multiples", "A multiple of 5 always ends in 5 or 0."),
    "2.2.3": ("Square numbers", "A square number is a number times itself, like 3x3 or 4x4."),
    "2.2.4": ("Always, sometimes, never", None),
    "2.3.1": ("Three friends", "Each person has exactly one thing, and no two have the same."),
    "2.3.2": ("Either and neither", "Neither rules out two people at once."),
    "2.3.3": ("The other way round", "Work out everything you can, then read off the answer."),
    "2.3.4": ("Deduction grids", None),
    "3.1.1": ("Reading the bulbs", "Each bulb is worth double the one on its right. Add the lit ones."),
    "3.1.2": ("More bulbs", "A new bulb on the left is worth double the one before it."),
    "3.1.3": ("Writing in bulbs", "Light the biggest bulb that fits, take it away, and repeat."),
    "3.1.4": ("Binary", None),
    "3.2.1": ("Decoding", "Find each coded letter on the bottom row. The real letter is above it."),
    "3.2.2": ("Wrapping round", "After Z, the alphabet starts again at A."),
    "3.2.3": ("Writing in code", "Find each letter on the top row. Its code is below it."),
    "3.2.4": ("Shift ciphers", None),
    "3.3.1": ("Symbol keys", "Each symbol always stands for the same letter."),
    "3.3.2": ("The back-to-front alphabet", "A swaps with Z and B swaps with Y. One key codes and decodes."),
    "3.3.3": ("Crack the code", "Compare the example letter by letter to find the rule, then use it."),
    "3.3.4": ("Substitution", None),
    "4.1.1": ("Opposite faces", "Two squares in a line with one between them end up opposite."),
    "4.1.2": ("Round the corner", "Pick one square for the bottom and fold the others up around it."),
    "4.1.3": ("Will it fold?", "A net fails if two squares fold onto the same side."),
    "4.1.4": ("Cube nets", None),
    "4.2.1": ("Same shape, turned", "Turning keeps the shape. A mirror image never matches, however you turn it."),
    "4.2.2": ("Turning a cube", "Follow one face at a time as the cube tips over."),
    "4.2.3": ("From another side", "From straight on you only see the tallest cube in each line."),
    "4.2.4": ("Rotating in 3D", None),
    "4.3.1": ("Straight cuts", "Cut a prism straight across and the cut is the same shape as its end."),
    "4.3.2": ("Cones, pyramids and spheres", "Cut straight across and the cut face matches the base."),
    "4.3.3": ("Slanted cuts", "Picture the cut face lying flat, then trace round its edge."),
    "4.3.4": ("Cross-sections", None),
}


def _worked(rules, facts, ask):
    v = K.must(rules, facts, ask)
    end = (f"So it {K.lit(ask, True)}." if v is True else
           f"So it {K.lit(ask, False)}." if v is False else
           "So you cannot tell.")
    return {"kind": "clues",
            "lines": [K.rule_sentence(r) for r in rules] + [K.fact_sentence(f) for f in facts],
            "conclusion": end}


def _claim_card(c):
    return {"kind": "claim", "lines": [K.claim_sentence(c)],
            "conclusion": K.ALWAYS3[K.claim_truth(c)] + "."}


def _grid_card(people, things, noun, clues, who):
    sol = K._solutions(people, things, clues)
    assert len(sol) == 1, "a teach card must be a puzzle with one answer too"
    owner = next(p for p in people if sol[0][p] == who)
    return {"kind": "grid", "people": people, "things": things, "noun": noun,
            "lines": [K.clue_sentence(c, noun) for c in clues],
            "conclusion": f"So {owner} has the {K._thing(who, noun)}."}


def _clash(cells):
    """The two squares that fold onto the same side, for a net that fails."""
    cells = [tuple(c) for c in cells]
    s = set(cells)
    states = {cells[0]: {p: p for p in "BTNSEW"}}
    stack = [cells[0]]
    while stack:
        u = stack.pop()
        for d in K._ROLL:
            v = (u[0] + d[0], u[1] + d[1])
            if v in s and v not in states:
                states[v] = K._roll_state(states[u], d)
                stack.append(v)
    seen = {}
    for i, c in enumerate(cells):
        f = states[c]["B"]
        if f in seen:
            return [seen[f], i]
        seen[f] = i
    raise ValueError("this net folds; it has no clash to show")


def _pair(cells, straight):
    faces = K.fold(cells)
    cs = [tuple(c) for c in cells]
    for i, c in enumerate(cs):
        j = next(j for j, d in enumerate(cs) if faces[d] == K.OPPOSITE[faces[c]])
        d = cs[j]
        line = (c[0] == d[0] or c[1] == d[1]) and abs(c[0] - d[0]) + abs(c[1] - d[1]) == 2
        if line == straight:
            return [i, j]
    raise ValueError("no such pair")


N = U.NETS
TEACH_PICS = {
    "1.1.1": {"kind": "sequence", "terms": [3, 10, 17, 24, 31, 38], "showSteps": True},
    "1.1.2": {"kind": "sequence", "terms": [20, 13, 6, -1, -8, -15], "showSteps": True},
    "1.1.3": {"kind": "sequence", "terms": [1, 3, 9, 27, 81, 243], "showSteps": True},
    "1.2.1": {"kind": "sequence", "terms": [2, 5, 8, 11, 14], "askPosition": 10, "reveal": 29},
    "1.2.2": {"kind": "sequence", "terms": [4, 9, 14, 19, 24], "askPosition": 20, "reveal": 99},
    "1.2.3": {"kind": "sequence", "terms": [1, 4, 7, 10, 13], "askValue": 31, "reveal": 11},
    "1.3.1": {"kind": "sequence", "terms": [1, 4, 9, 16, 25, 36], "showSteps": True},
    "1.3.2": {"kind": "sequence", "terms": [1, 8, 27, 64, 125, 216], "showSteps": True},
    "1.3.3": {"kind": "sequence", "terms": [2, 5, 10, 17, 26, 37], "showSteps": True},
    "2.1.1": _worked([("big", True, "shiny", True)], [("big", True)], "shiny"),
    "2.1.2": _worked([("spots", True, "big", True)], [("big", True)], "spots"),
    "2.1.3": {"kind": "truth", "lines": K.KK_RULE + ['Om says: "We are both liars."'],
              "conclusion": "A truth-teller could never say that. So Om is a liar."},
    "2.2.1": _claim_card({"a": "even", "op": "plus", "b": "even", "is": "even"}),
    "2.2.2": _claim_card({"a": "m10", "op": "is", "is": "m5"}),
    "2.2.3": _claim_card({"a": "sq", "op": "is", "is": "odd"}),
    "2.3.1": _grid_card(["Kabir", "Neha", "Dev"], ["cat", "dog", "fish"], "",
                        [{"t": "has", "p": "Neha", "x": "dog"},
                         {"t": "not", "p": "Kabir", "x": "fish"}], "fish"),
    "2.3.2": _grid_card(["Tara", "Joy", "Isha"], ["red", "blue", "green"], "bag",
                        [{"t": "neither", "ps": ["Tara", "Joy"], "x": "blue"},
                         {"t": "either", "ps": ["Tara", "Isha"], "x": "green"}], "red"),
    "2.3.3": _grid_card(["Imran", "Anu", "Rohan"], ["mango", "apple", "banana"], "",
                        [{"t": "not", "p": "Imran", "x": "mango"},
                         {"t": "not", "p": "Imran", "x": "apple"},
                         {"t": "not", "p": "Rohan", "x": "mango"}], "apple"),
    "3.1.1": {"kind": "binary", "values": U.V4, "on": [0, 1, 1, 1], "showSum": True},
    "3.1.2": {"kind": "binary", "values": U.V5, "on": [1, 0, 0, 1, 0], "showSum": True},
    "3.1.3": {"kind": "binary", "values": U.V4, "on": [0, 1, 1, 1], "after": [1, 0, 0, 0]},
    "3.2.1": {"kind": "shift", "shift": 2, "word": K.shift_word("DOG", 2), "mode": "decode", "reveal": "DOG"},
    "3.2.2": {"kind": "shift", "shift": 3, "word": K.shift_word("XYZ", 3), "mode": "decode", "reveal": "XYZ"},
    "3.2.3": {"kind": "shift", "shift": 1, "word": "SUN", "mode": "encode", "reveal": K.shift_word("SUN", 1)},
    "3.3.1": dict(K.symbol_decode("x", "HAT")["pic"], reveal="HAT"),
    "3.3.2": {"kind": "mirrorAlpha", "word": K.atbash("BAG"), "mode": "decode", "reveal": "BAG"},
    "3.3.3": {"kind": "example", "example": ["HEN", K.shift_word("HEN", 1)], "word": "PIG",
              "mode": "encode", "reveal": K.shift_word("PIG", 1)},
    "4.1.1": {"kind": "net", "cells": N[0], "marks": U.marks(3), "pair": _pair(N[0], True)},
    "4.1.2": {"kind": "net", "cells": N[5], "marks": U.marks(5), "pair": _pair(N[5], False)},
    "4.1.3": {"kind": "net", "cells": U.FAKES[5], "marks": U.marks(1), "clash": _clash(U.FAKES[5])},
    "4.2.1": {"kind": "polycube", "cubes": [list(c) for c in U.PC4[7]],
              "turned": [list(c) for c in K.norm3([K._apply_rot(K.ROT24[5], c) for c in U.PC4[7]])]},
    "4.2.2": {"kind": "turnCube", "marks": [K.HEART, K.SQUARE, K.STAR], "moves": ["away"],
              "steps": [K.TURN_WORDS["away"]], "ask": "T", "reveal": K.SQUARE},
    "4.2.3": {"kind": "stack", "heights": [[3, 2], [2, 1]], "side": "front",
              "reveal": K.views([[3, 2], [2, 1]])[0]},
    "4.3.1": {"kind": "section", "solid": "hexprism", "cut": "across",
              "point": [0.5, 0.5, 0.3], "normal": [0, 0, 1], "reveal": "hexagon"},
    "4.3.2": {"kind": "section", "solid": "pyramid", "cut": "across",
              "point": [0.5, 0.5, 0.25], "normal": [0, 0, 1], "reveal": "square"},
    "4.3.3": {"kind": "section", "solid": "cuboid", "cut": "slant",
              "point": [1, 0.5, 0.5], "normal": [0.4, 0, 1], "reveal": "rectangle"},
}


OPTION_FIELDS = ("optionsText", "optionRules", "optionCells", "optionBits",
                 "optionNets", "optionViews", "optionCubes", "optionShapes",
                 "optionSections")


def balance_slots(questions):
    """Put the right answer in slot 0, 1, 2, 3 in turn within each question type.

    The kit places answers by hashing each question, which evens out over
    hundreds but not over the eight binary questions or nine position questions a
    type actually has: the first build put 55% of one type's answers in one slot.
    A child tapping that slot every time would pass without reading. Turning
    through the slots in ladder order makes every slot near a quarter.

    Always-sometimes-never and the if-then scale keep their reading order on
    purpose; their answers are balanced by authoring and checked by the gate.
    """
    seen = {}
    for q in questions:
        i = seen.get(q["shape"], 0)
        seen[q["shape"]] = i + 1
        pool = q.pop("_pool", None)
        if q.get("fixedOrder"):
            continue
        a = q["answer"]
        if a["type"] == "number":
            q["choices"] = K.choices4(a["value"], pool["mistakes"], 0, pool["lo"], k=i % 4,
                                      allowed=set(pool["allowed"]) if pool.get("allowed") else None)
            continue
        fields = [f for f in OPTION_FIELDS if q.get(f)]
        n = len(q[fields[0]])
        shift = (i % n - a["value"]) % n
        for f in fields:
            lst = q[f]
            q[f] = [lst[(j - shift) % n] for j in range(n)]
        a["value"] = i % n


def _drawable(qs):
    return all(q["shape"] in DRAWN_TODAY for q in qs)


def build():
    sections = []
    for sn, sname, ssub in SECTIONS:
        units = []
        for un in (1, 2, 3):
            uid = f"{sn}.{un}"
            stops = []
            for stop_n in (1, 2, 3, 4):
                sid = f"{uid}.{stop_n}"
                qs = getattr(U, "S" + sid.replace(".", ""))
                title, line = TITLES[sid]
                stop = {"id": sid, "title": title, "authored": _drawable(qs),
                        "boss": stop_n == 4, "questions": qs}
                if line:
                    stop["teach"] = {"line": line, "pic": TEACH_PICS[sid]}
                stops.append(stop)
            units.append({"n": un, "title": UNITS[uid], "stops": stops})
        sections.append({"n": sn, "title": sname, "subtitle": ssub, "units": units})
    balance_slots([q for s in sections for u in s["units"] for st in u["stops"]
                   for q in st["questions"]])
    return {
        "id": "reasoning",
        "name": "Reasoning",
        "band": "d",                      # lowercase, always
        "ages": "11-12",
        "promise": "Your child will find the rule in a pattern, reason from clues to "
                   "an answer that must be true, crack codes, and turn shapes in "
                   "their head.",
        "sections": sections,
    }


if __name__ == "__main__":
    skill = build()
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    io.open(OUT, "w", encoding="utf-8").write(json.dumps(skill, indent=1, ensure_ascii=False))
    stops = [st for s in skill["sections"] for u in s["units"] for st in u["stops"]]
    print(f"stops={len(stops)} questions={sum(len(st['questions']) for st in stops)} "
          f"teach={sum(1 for st in stops if st.get('teach'))} "
          f"playable today={sum(1 for st in stops if st['authored'])} "
          f"-> {os.path.relpath(OUT, HERE)}")
