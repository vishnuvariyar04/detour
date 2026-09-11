# -*- coding: utf-8 -*-
"""Plays the whole Number Sense skill and checks every question is fair.

The same discipline as simulate.py for the coder skill: every question must be
answerable, the answer must be reachable by tapping, the reading must be within
a five year old's range, and no picture may contradict the question asked of it.

The shape-hunt figures are described here a second time, independently of the
Kotlin that draws them. If the two ever disagree about how many triangles a
figure has, this fails — which is exactly the drift that would otherwise mark a
child's correct answer wrong.
"""
import json, os, re, sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
JSON = os.path.join(HERE, "..", "..", "assets", "curriculum", "number_sense.json")

PROBLEMS = []


def bad(where, msg):
    PROBLEMS.append(f"{where}: {msg}")


# ---------------------------------------------------------------- figures
#
# One source: figures.py. The old copy here had to be kept in step by hand and
# said four rectangles were squares.
import figures as FIG

# Words a five year old meets in these prompts. Anything outside this is either
# a typo or a word that has no business in a picture-led question.
ALLOWED_LONG = {
    "altogether", "together", "coloured", "smallest", "triangle", "triangles",
    "squares", "square", "another", "belong", "finish", "missing", "yellow",
    "purple", "circles", "hearts", "flowers", "blocks", "number", "numbers",
    "counters", "biggest", "rectangle", "rectangles", "quarter", "forward",
    "reaches", "heavier", "shapes", "shared", "hiding", "picture",
}

# A prompt has to tell the child what to DO. "Start at 2 and hop on 3" named
# no action, so a child had to guess whether to tap the line, a number, or
# nothing at all.
VERBS = ("tap", "count", "move", "fold", "put", "add", "start")


def check_instruction(qid, prompt):
    if not prompt:
        return bad(qid, "no prompt")
    if not any(v in prompt.lower() for v in VERBS):
        bad(qid, f'the prompt never says what to do: "{prompt[:44]}"')


def check_unique(items):
    """No question may appear twice anywhere in the skill.

    Same prompt, same picture and same options is the same question however far
    apart the two sit — and a child who meets it again has been given a turn
    that teaches nothing.
    """
    seen = {}
    for qid, q in items:
        key = json.dumps({
            "p": q.get("prompt"), "pic": q.get("pic"),
            "o": q.get("optionsText") or q.get("optionCells"),
            "c": q.get("choices"),
        }, sort_keys=True)
        if key in seen:
            bad(qid, f"the same question as {seen[key]}")
        else:
            seen[key] = qid


def check_reading(qid, text, field):
    if not text:
        return
    if re.search(r"\b[a-z]+_[a-z]+\b", text):
        bad(qid, f'{field} has a code name in it: "{text[:40]}"')
    for w in re.findall(r"[A-Za-z]+", text):
        if len(w) > 7 and w.lower() not in ALLOWED_LONG:
            bad(qid, f'{field} uses a long word: "{w}"')
    if len(text) > 70:
        bad(qid, f"{field} is {len(text)} characters; keep it under 70")


def check_choices(qid, q):
    """A number answer must be one of the four keys offered."""
    ch = q.get("choices")
    if ch is None:
        return bad(qid, "a number question with no choices")
    if len(ch) != 4:
        bad(qid, f"{len(ch)} number keys offered; the pad draws four")
    if len(set(ch)) != len(ch):
        bad(qid, "the same number is offered twice")
    v = q["answer"]["value"]
    if v not in ch:
        bad(qid, f"the answer {v} is not one of the choices {ch}")
    if any(c < 0 for c in ch):
        bad(qid, f"a negative number is offered: {ch}")


def check_pic(qid, q):
    """The picture has to actually pose the question being asked."""
    shape, pic, ans = q["shape"], q.get("pic") or {}, q["answer"]["value"]

    if shape == "countObjects":
        if pic["n"] > 10:
            bad(qid, f"{pic['n']} things is too many to count at this age")
        sp = pic.get("splitAt", -1)
        if sp < 0:
            if pic["n"] != ans:
                bad(qid, f"draws {pic['n']} things but the answer is {ans}")
        else:
            # Counters from splitAt on are yellow; the rest are purple.
            yellow, purple = pic["n"] - sp, sp
            asked = "yellow" if "yellow" in q["prompt"] else "purple"
            want = yellow if asked == "yellow" else purple
            if want != ans:
                bad(qid, f"asks for the {asked} ones ({want}) but answers {ans}")
            if yellow == 0 or purple == 0:
                bad(qid, "only one colour is drawn, so the question is empty")

    elif shape == "tenFrame":
        total = pic["filled"] + max(pic.get("second", -1), 0)
        if "more" in q["prompt"] and "fill" in q["prompt"]:
            if 10 - pic["filled"] != ans:
                bad(qid, "asks how many more, but the answer is not the gap")
        elif total != ans:
            bad(qid, f"shows {total} but the answer is {ans}")

    elif shape == "dice":
        if sum(pic["faces"]) != ans:
            bad(qid, f"faces {pic['faces']} sum to {sum(pic['faces'])}, not {ans}")
        if any(f < 1 or f > 6 for f in pic["faces"]):
            bad(qid, f"a die face outside 1-6: {pic['faces']}")

    elif shape == "rods":
        if pic["n"] != ans:
            bad(qid, f"shows {pic['n']} but the answer is {ans}")

    elif shape == "bond":
        w, l, r = pic.get("whole"), pic.get("left"), pic.get("right")
        gap = pic.get("gap")
        known = [x for x in (w, l, r) if x is not None]
        if len(known) != 2:
            bad(qid, "a bond must show exactly two of its three numbers")
        if gap == "right" and w is not None and l is not None and w - l != ans:
            bad(qid, f"{w} take {l} is {w - l}, not {ans}")
        if gap == "left" and w is not None and r is not None and w - r != ans:
            bad(qid, f"{w} take {r} is {w - r}, not {ans}")
        if gap == "whole" and l is not None and r is not None and l + r != ans:
            bad(qid, f"{l} and {r} is {l + r}, not {ans}")
        if any(x is not None and x < 0 for x in (w, l, r)) or ans < 0:
            bad(qid, "a bond has gone negative")

    elif shape == "numberLine":
        if not (pic["from"] <= ans <= pic["to"]):
            bad(qid, f"the answer {ans} is off the line {pic['from']}-{pic['to']}")
        if pic.get("hopFrom") is None:
            bad(qid, "a hop question with nowhere to hop from")

    elif shape == "balance":
        l, r = pic["leftCount"], pic["rightCount"]
        want = 0 if l > r else (1 if r > l else 2)
        if want != ans:
            bad(qid, f"{l} against {r} should answer {want}, not {ans}")
        if max(l, r) > 8:
            bad(qid, f"{max(l, r)} on a pan is more than the scale draws")

    elif shape == "fraction":
        if pic.get("otherSlices"):
            a = pic["shaded"] / pic["slices"]
            b = pic["otherShaded"] / pic["otherSlices"]
            if a == b:
                bad(qid, "both circles show the same amount, so there is no answer")
            want = 0 if a > b else 1
            if want != ans:
                bad(qid, f"{a:.2f} against {b:.2f} should answer {want}")
        else:
            # The single-circle form has no options wired in the gate, so a
            # question written that way would be unanswerable on the phone.
            if not q.get("optionsText"):
                bad(qid, "one circle and no options: nothing to tap")
        if pic["shaded"] > pic["slices"]:
            bad(qid, "more slices shaded than the circle has")

    elif shape == "array":
        if pic["rows"] * pic["cols"] != ans:
            bad(qid, f"{pic['rows']}x{pic['cols']} is {pic['rows']*pic['cols']}, not {ans}")
        if pic["rows"] > 8 or pic["cols"] > 10:
            bad(qid, "an array this big is a counting chore, not a times fact")

    elif shape == "groups":
        tot = pic["groups"] * pic["per"]
        want = pic["per"] if pic.get("share") else tot
        if want != ans:
            bad(qid, f"{pic['groups']} groups of {pic['per']} should answer {want}")
        if pic.get("share") and str(tot) not in q["prompt"]:
            bad(qid, f"a sharing prompt must say the total ({tot})")

    elif shape == "barModel":
        want = abs(pic["a"] - pic["b"]) if pic["ask"] == "more" else pic["a"] + pic["b"]
        if want != ans:
            bad(qid, f"bars {pic['a']} and {pic['b']} should answer {want}")
        if pic["ask"] == "more" and pic["a"] == pic["b"]:
            bad(qid, "the bars are equal, so there is no difference to find")

    elif shape == "fractionWall":
        rows, ask = pic["rows"], pic.get("ask", "biggest")
        if len(rows) < 3:
            bad(qid, "a wall needs at least three strips to choose between")
        if ask == "biggest":
            sizes = [r[0] for r in rows]
            if sizes.count(min(sizes)) != 1:
                bad(qid, "two strips tie for the biggest pieces")
            elif sizes.index(min(sizes)) != ans:
                bad(qid, f"strip {sizes.index(min(sizes))} has the biggest pieces")
        else:
            if ans == 0:
                bad(qid, "the answer is the reference strip, which cannot be tapped")
            top = rows[0][1] / rows[0][0]
            m = [i for i in range(1, len(rows))
                 if abs(rows[i][1] / rows[i][0] - top) < 1e-9]
            if len(m) != 1:
                bad(qid, f"{len(m)} strips match the top one; it must be exactly 1")
            elif m[0] != ans:
                bad(qid, f"strip {m[0]} matches the top, not {ans}")
        for pieces, on in rows:
            if on > pieces:
                bad(qid, "a strip has more coloured than it has pieces")

    elif shape == "shapeCount":
        want = FIG.counts(pic["figure"], pic["target"])
        if want != ans:
            bad(qid, f"{pic['figure']} has {want} {pic['target']}s, not {ans}")
        if want < 2:
            bad(qid, "counting one shape is not a question")

    elif shape == "shapeHunt":
        if pic["figure"] not in FIG.FIGURES:
            return bad(qid, f"unknown figure {pic['figure']}")
        kinds = [k for k, _ in FIG.FIGURES[pic["figure"]][1]]
        n = kinds.count(pic["target"])
        if n == 0:
            bad(qid, f"asks for {pic['target']} but {pic['figure']} has none")
        if n == len(kinds):
            bad(qid, "every piece is the answer, so there is nothing to find")

    elif shape == "pattern":
        cells, gap = pic["cells"], pic["gapAt"]
        if not (0 <= gap < len(cells)):
            return bad(qid, f"the gap {gap} is outside the strip")
        opts = q.get("optionCells") or []
        if len(opts) < 2:
            bad(qid, "a pattern needs choices to pick from")
        if not (0 <= ans < len(opts)):
            return bad(qid, f"the answer {ans} is not one of the choices")
        want = cells[gap]
        got = opts[ans]
        if (want["kind"], want["color"], want.get("rotation", 0)) != \
           (got["kind"], got["color"], got.get("rotation", 0)):
            bad(qid, "the chosen option is not what the strip has in the gap")

    elif shape == "oddOneOut":
        cells = pic["cells"]
        if not (0 <= ans < len(cells)):
            return bad(qid, f"the answer {ans} is outside the row")
        odd = cells[ans]
        rest = [c for i, c in enumerate(cells) if i != ans]
        same_kind = len({c["kind"] for c in rest}) == 1
        same_color = len({c["color"] for c in rest}) == 1
        if not (same_kind and same_color):
            bad(qid, "the three that stay are not alike, so the odd one is unclear")
        if odd["kind"] == rest[0]["kind"] and odd["color"] == rest[0]["color"]:
            bad(qid, "the odd one is identical to the others")

    elif shape == "sortTwo":
        cells, sides = pic["cells"], q["answer"]["value"]
        if len(cells) != len(sides):
            bad(qid, f"{len(cells)} things but {len(sides)} answers")
        if len(set(sides)) < 2:
            bad(qid, "every item goes in one tray, so there is nothing to sort")

    elif shape == "sizeOrder":
        sizes = pic["sizes"]
        want = sorted(range(len(sizes)), key=lambda i: sizes[i])
        if want != q["answer"]["value"]:
            bad(qid, "the answer is not the smallest-first order")
        if len(set(sizes)) != len(sizes):
            bad(qid, "two things are the same size, so the order is ambiguous")

    elif shape == "mirror":
        cols, given = pic["cols"], pic["given"]
        want = [[cols - 1 - c, r] for (c, r) in given]
        if want != q["answer"]["value"]:
            bad(qid, "the answer is not the reflection of the given half")
        if any(c >= cols // 2 for (c, r) in given):
            bad(qid, "a given square is on the answering side of the fold")
        if not given:
            bad(qid, "nothing is given, so there is nothing to mirror")


def main():
    d = json.load(open(JSON, encoding="utf-8"))
    stops = [st for s in d["sections"] for u in s["units"] for st in u["stops"]]
    n_q = 0
    shapes = {}
    for st in stops:
        if not st["boss"]:
            teach = st.get("teach") or {}
            if not teach.get("line"):
                bad(st["id"], "no teach line")
            if not teach.get("pic"):
                # Without one the gate falls back to the coder demo board and
                # shows a counting lesson as a grid with a walking owl on it.
                bad(st["id"], "no teach picture")
        seen_shapes = set()
        for i, q in enumerate(st["questions"]):
            qid = f"{st['id']}#{i}"
            n_q += 1
            shapes[q["shape"]] = shapes.get(q["shape"], 0) + 1
            seen_shapes.add(q["shape"])
            check_instruction(qid, q.get("prompt"))
            check_reading(qid, q.get("prompt"), "prompt")
            check_reading(qid, q.get("hint"), "hint")
            if not q.get("hint"):
                bad(qid, "no hint")
            if q["shape"] in ("countObjects", "tenFrame", "dice", "rods", "bond",
                              "array", "groups", "barModel", "shapeCount"):
                check_choices(qid, q)
            check_pic(qid, q)
        st["_shapes"] = seen_shapes
        # One idea, at least three pictures. Seven of the same question stops
        # being about the idea and becomes about clicking: a child learns the
        # shape of the screen instead of the thing on it.
        if len(seen_shapes) < 3:
            bad(st["id"], f"only {len(seen_shapes)} kind(s) of question: "
                          f"{sorted(seen_shapes)}")
        top = max(Counter(q["shape"] for q in st["questions"]).values())
        if top > 4:
            bad(st["id"], f"one kind of question appears {top} times")

    # Variety is judged per unit, not per stop: a stop that teaches number
    # bonds should be allowed to use bonds throughout, but a child must not
    # meet four stops in a row that all look the same.
    for sec in d["sections"]:
        for u in sec["units"]:
            kinds = set()
            for st in u["stops"]:
                kinds |= st.get("_shapes", set())
            if len(kinds) < 3:
                bad(f"unit {sec['n']}.{u['n']}",
                    f"only {len(kinds)} kind(s) of picture in the whole unit: "
                    f"{sorted(kinds)}")

    check_unique([(f"{st['id']}#{i}", q)
                  for st in stops for i, q in enumerate(st["questions"])])
    # the figures themselves must be geometrically honest
    for prob in FIG.audit():
        bad("figures", prob)

    print(f"stops={len(stops)} questions={n_q}")
    for s, n in sorted(shapes.items(), key=lambda kv: -kv[1]):
        print(f"  {s:14} {n}")
    if len(stops) != 48 or n_q != 324:
        bad("skill", f"expected 48 stops and 324 questions, got {len(stops)}/{n_q}")
    for p in PROBLEMS:
        print("  FAIL", p)
    print("OK" if not PROBLEMS else f"{len(PROBLEMS)} problem(s)")
    return 1 if PROBLEMS else 0


if __name__ == "__main__":
    sys.exit(main())
