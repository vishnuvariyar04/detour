# -*- coding: utf-8 -*-
"""Builds the Puzzles & Logic skill (band b, ages 7-8) from pz_units.py.

Run:  python pz_emit.py && python pz_simulate.py && python pz_grade.py

WHERE IT GOES. assets/curriculum/, which the gate scans and children are served.
A stop reaches the ladder only when CoderGate can draw every shape in it, and
that set is read from CoderGate rather than copied -- see drawable.py.
Every question in the rebuilt skill uses a drawing CoderGate cannot make yet --
a clue card, a line of children, a compass, a clock -- and CoderGate's
when(q.shape) has no else branch, so in assets/curriculum a band b child would
be served a skill with no playable stop in it. The first version of this skill
lived in assets/curriculum with its undrawable stops marked unauthored; this
version has no drawable stops at all, so it waits in the pending folder with
band d until its views exist.
"""
import io, json, os

import pz_units as U
import drawable
import puzzles_kit as K

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "..", "assets", "curriculum", "puzzles_and_logic.json")

# What CoderGate can draw, read from CoderGate. Never hand-written: the
# hand-written version went stale the moment the views were built, and every
# stop in this skill was marked unplayable while looking fine.
DRAWN_TODAY = drawable.gate_shapes("b")

SECTIONS = [
    (1, "Number thinking", "Work out the number a puzzle is hiding."),
    (2, "Order and position", "Who comes first, who stands where, which way to turn."),
    (3, "Relations and codes", "How people are linked, and how words hide in codes."),
    (4, "Logic", "Spot what does not fit, and think it through."),
]

UNITS = {
    "1.1": "Missing numbers", "1.2": "Story sums", "1.3": "Number patterns",
    "2.1": "Taller, older, faster", "2.2": "Places in a line", "2.3": "Left, right and turning",
    "3.1": "Family relations", "3.2": "Analogies", "3.3": "Letter and number codes",
    "4.1": "Odd one out", "4.2": "Days, months and the clock", "4.3": "Think it through",
}

# (title, teach line). No teach card on a boss, as in every other skill.
TITLES = {
    "1.1.1": ("Adding across tens", "Both sides of the equals sign must be the same."),
    "1.1.2": ("Taking away across tens", "Check a take away by adding back."),
    "1.1.3": ("Two steps", "Undo the last step first."),
    "1.1.4": ("Missing numbers", None),
    "1.2.1": ("Getting more, giving away", "Getting more means add. Giving away means take away. Do one step at a time."),
    "1.2.2": ("Together and compared", "How many more? Take the smaller from the bigger."),
    "1.2.3": ("Groups and sharing", "Equal groups: add the same number again and again."),
    "1.2.4": ("Story sums", None),
    "1.3.1": ("Counting in steps", "Find the jump from one number to the next."),
    "1.3.2": ("Bigger jumps", "Check the jump is the same every time."),
    "1.3.3": ("Growing jumps", "Sometimes the jump gets bigger each time."),
    "1.3.4": ("Number patterns", None),
    "2.1.1": ("Who is the tallest", "Put the people in order, most first."),
    "2.1.2": ("Taller and shorter", "Shorter than is the same clue turned round."),
    "2.1.3": ("Second place", "Put everyone in order, then count down."),
    "2.1.4": ("Taller, older, faster", None),
    "2.2.1": ("From the other end", "From the back, the last child is 1st."),
    "2.2.2": ("How long is the line", "Count from both ends, but count the child once."),
    "2.2.3": ("In between", "Count only the children standing between them."),
    "2.2.4": ("Places in a line", None),
    "2.3.1": ("Left and right", "Your left hand makes an L with its thumb."),
    "2.3.2": ("Turning", "Turning right goes North, East, South, West."),
    "2.3.3": ("Turning around", "Turning around is two turns the same way."),
    "2.3.4": ("Left, right and turning", None),
    "3.1.1": ("Parents and children", "A brother and a sister share the same parents."),
    "3.1.2": ("Grandparents", "Your father's mother is your grandmother."),
    "3.1.3": ("Aunts, uncles and cousins", "Your mother's sister is your aunt."),
    "3.1.4": ("Family relations", None),
    "3.2.1": ("Babies and homes", "Say how the first pair goes together."),
    "3.2.2": ("Opposites and senses", "Use the same link for the second pair."),
    "3.2.3": ("Numbers that match", "Find what happens to each number, then do it again."),
    "3.2.4": ("Analogies", None),
    "3.3.1": ("The alphabet", "Each letter in the code moves one step along."),
    "3.3.2": ("Codes that flip", "Some codes write the word backwards."),
    "3.3.3": ("Number codes", "A is 1, B is 2, C is 3."),
    "3.3.4": ("Letter and number codes", None),
    "4.1.1": ("Which one is different", "Find what three of them have in common."),
    "4.1.2": ("Groups of things", "Fruit, animals, clothes: which group is each one in?"),
    "4.1.3": ("Odd numbers out", "Is it odd or even? Does it end in 0 or 5?"),
    "4.1.4": ("Odd one out", None),
    "4.2.1": ("Days of the week", "After Sunday comes Monday again."),
    "4.2.2": ("Reading the clock", "The short hand shows the hour."),
    "4.2.3": ("Months of the year", "After December comes January again."),
    "4.2.4": ("Days, months and the clock", None),
    "4.3.1": ("How many ways", "Take one top. Count what goes with it. Do that for each."),
    "4.3.2": ("Mixed puzzles", "Read slowly. What kind of puzzle is it?"),
    "4.3.3": ("More mixed puzzles", "Check your answer fits every clue."),
    "4.3.4": ("Puzzles and logic", None),
}

card = lambda lines, conclusion=None: {"kind": "card", "lines": lines,
                                        **({"conclusion": conclusion} if conclusion else {})}

# A worked example for each non-boss stop. None is a question from its own stop.
TEACH_PICS = {
    "1.1.1": {"kind": "equation", "left": 26, "op": "+", "right": 8, "result": 34, "hide": "right", "reveal": 8},
    "1.1.2": {"kind": "equation", "left": 52, "op": "-", "right": 15, "result": 37, "hide": "right", "reveal": 15},
    "1.1.3": card(["I am a number.", "I add 12, then double.", "Now I am 40."], "Halve 40 is 20. Take 12. So I am 8."),
    "1.2.1": card(["Om has 26 kites.", "He gets 9, then gives away 5.", "How many are left?"],
                  "26 and 9 is 35. Take 5 is 30."),
    "1.2.2": {"kind": "bars", "names": ["Aman", "Diya"], "values": [45, 28],
              "shown": {"top": 45, "low": 28, "diff": None}, "hide": "diff", "reveal": 17},
    "1.2.3": card(["There are 3 bags of 6 sweets.", "How many sweets in all?"], "6 and 6 and 6 is 18."),
    "1.3.1": {"kind": "series", "terms": [4, 11, 18, 25, 32], "showSteps": True},
    "1.3.2": {"kind": "series", "terms": [90, 82, 74, 66, 58], "showSteps": True},
    "1.3.3": {"kind": "series", "terms": [3, 4, 6, 9, 13], "showSteps": True},
    "2.1.1": card(["Ravi is taller than Om.", "Om is taller than Dev."], "So Ravi is the tallest."),
    "2.1.2": card(["Asha is shorter than Mia."], "So Mia is taller than Asha."),
    "2.1.3": card(["Tara is older than Om.", "Om is older than Ali."], "So Om is second oldest."),
    "2.2.1": {"kind": "line", "n": 5, "mark": 2, "name": "Om", "reveal": "4th from the back"},
    "2.2.2": card(["Riya is 2nd from the front.", "Riya is 3rd from the back."], "So 4 are in the line."),
    "2.2.3": card(["Om is 1st in the line.", "Dev is 4th in the line."], "So 2 stand between them."),
    "2.3.1": {"kind": "shelf", "items": ["circle", "star", "heart"], "target": "star",
              "side": "left", "steps": 1, "reveal": "circle"},
    "2.3.2": {"kind": "compass", "lines": ["Riya faces North.", "She turns right."],
              "start": "North", "moves": ["right"], "conclusion": "Now she faces East."},
    "2.3.3": {"kind": "compass", "lines": ["Om faces East.", "He turns around."],
              "start": "East", "moves": ["around"], "conclusion": "Now he faces West."},
    "3.1.1": card(["Raj is Om's father.", "Mia is Om's sister."], "So Raj is Mia's father."),
    "3.1.2": card(["Asha is Dev's mother.", "Dev is Riya's father."], "So Asha is Riya's grandmother."),
    "3.1.3": card(["Neha is Ravi's sister.", "Ravi is Tom's father."], "So Neha is Tom's aunt."),
    "3.2.1": {"kind": "wordPairs", "pairs": [["cat", "kitten"], ["hen", "chick"]]},
    "3.2.2": {"kind": "wordPairs", "pairs": [["big", "small"], ["up", "down"]]},
    "3.2.3": {"kind": "numPairs", "pairs": [[2, 4], [5, 10], [3, 6]]},
    "3.3.1": {"kind": "example", "example": ["DOG", K.shift_word("DOG", 1)], "word": "CAT",
              "mode": "encode", "reveal": K.shift_word("CAT", 1)},
    "3.3.2": {"kind": "example", "example": ["NOW", "WON"], "word": "TOP", "mode": "encode", "reveal": "POT"},
    "3.3.3": {"kind": "numExample", "example": ["CAB", "3 1 2"], "word": "BAD", "mode": "encode",
              "reveal": "2 1 4"},
    "4.1.1": {"kind": "words", "words": ["mango", "apple", "bus", "banana"], "reveal": "bus"},
    "4.1.2": {"kind": "words", "words": ["cap", "sock", "crow", "shirt"], "reveal": "crow"},
    "4.1.3": {"kind": "words", "words": ["2", "4", "6", "9"], "reveal": "9"},
    "4.2.1": card(["Today is Friday.", "Tomorrow is Saturday."]),
    "4.2.2": {"kind": "clock", "h": 4, "m": 0, "form": "read", "lines": [], "reveal": "4 o'clock"},
    "4.2.3": card(["July comes just after June."]),
    "4.3.1": card(["2 tops and 2 skirts.", "Each top goes with 2 skirts."], "2 and 2 is 4 ways."),
    "4.3.2": card(["Is it a story, a code or a line?"]),
    "4.3.3": card(["Read every clue again.", "Does your answer fit them all?"]),
}

OPTION_FIELDS = ("optionsText", "optionRules", "optionCells")


def balance_slots(questions):
    """Turn the right answer through slots 0-3 within each question type.

    Each question's options come out of the kit with the answer first, and
    number choices come out with the answer in the lowest slot the mistakes
    allow. Left alone that is a skill a child passes by tapping one place. The
    compass keeps its North-East-South-West order on purpose and is balanced by
    authoring instead; pz_simulate.py holds every type under 45% in any slot.
    """
    seen = {}
    for q in questions:
        i = seen.get(q["shape"], 0)
        seen[q["shape"]] = i + 1
        pool = q.pop("_pool", None)
        fields = q.pop("_rotate", None)
        if q.get("fixedOrder"):
            continue
        a = q["answer"]
        if a["type"] == "number":
            q["choices"] = K.choices4(a["value"], pool["mistakes"], i % 4, pool["lo"])
            continue
        n = len(q[fields[0]])
        shift = (i % n - a["value"]) % n
        for f in fields:
            lst = q[f]
            q[f] = [lst[(j - shift) % n] for j in range(n)]
        a["value"] = i % n


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
                stop = {"id": sid, "title": title,
                        "authored": all(q["shape"] in DRAWN_TODAY for q in qs),
                        "boss": stop_n == 4, "questions": qs}
                if line:
                    stop["teach"] = {"line": line, "pic": TEACH_PICS[sid]}
                stops.append(stop)
            units.append({"n": un, "title": UNITS[uid], "stops": stops})
        sections.append({"n": sn, "title": sname, "subtitle": ssub, "units": units})
    balance_slots([q for s in sections for u in s["units"] for st in u["stops"]
                   for q in st["questions"]])
    return {
        "id": "puzzles_and_logic",
        "name": "Puzzles & Logic",
        "band": "b",                  # lowercase, always
        "ages": "7-8",
        "promise": "Your child will work out missing numbers and story sums, put "
                   "people in order, follow family clues and codes, and spot what "
                   "does not belong.",
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
