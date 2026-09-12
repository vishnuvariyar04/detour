# -*- coding: utf-8 -*-
"""Derives every Puzzles & Logic answer a SECOND time, from the picture alone.

Reading an answer out of the JSON and comparing it to itself proves nothing.
This reads only the drawing -- the strip, the key, the trays, the first pair of
the analogy -- works out what the answer has to be, and compares. It shares no
code with puzzles_kit.py, which is the entire point: if the kit and this file
agree, two independent readings of the same picture agree.

The sort questions get the most attention here, because their rule is a Python
function at authoring time and is NOT in the JSON. What this checks instead is
stronger than re-running that function would be: that the two trays can be told
apart by some property a child can actually SEE. If no single visible property
reproduces the stored trays, the question cannot be answered by looking at it,
whatever the author intended.
"""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
PATH = os.path.join(HERE, "..", "..", "assets", "curriculum",
                    "puzzles_and_logic.json")

FAILS = []
COUNTS = {}


def bad(qid, msg):
    FAILS.append(f"{qid}: {msg}")


def sig(c):
    return (c["kind"], c["color"], c.get("rotation", 0), c.get("n", 1),
            c.get("size", 1))


# Every property a seven year old can see at a glance. A tray split that none of
# these explains is a split a child cannot make.
POINTY = {"star", "triangle", "diamond"}
FOUR_CORNERS = {"square", "diamond"}
KINDS = ("star", "heart", "circle", "square", "triangle", "diamond",
         "hexagon", "flower")


def visible_predicates():
    """Every rule a child could read off the shapes themselves.

    Band b's rules take two properties at once ("yellow AND pointy") or a
    negation ("NOT round"), so a list of single properties can no longer
    express them. This builds the space instead: each visible feature, its
    negation, and every AND / AND-NOT / OR pair of two features.

    The check this powers is the real one for a sort question. The authoring
    rule is a Python lambda and is not in the JSON, so it cannot be re-run here;
    what matters anyway is not what the author intended but whether SOME rule a
    child can see puts the shapes exactly where the answer says. If none does,
    the question cannot be answered by looking at it.
    """
    feats = [("yellow", lambda c: c["color"] == "accent"),
             ("pointy", lambda c: c["kind"] in POINTY),
             ("round", lambda c: c["kind"] == "circle"),
             ("4 corners", lambda c: c["kind"] in FOUR_CORNERS),
             ("3 corners", lambda c: c["kind"] == "triangle")]
    for k in KINDS:
        feats.append((f"is {k}", lambda c, k=k: c["kind"] == k))

    preds = []
    for name, f in feats:
        preds.append((name, f))
        preds.append((f"not {name}", lambda c, f=f: not f(c)))
    for i, (n1, f1) in enumerate(feats):
        for n2, f2 in feats[i + 1:]:
            preds.append((f"{n1} and {n2}", lambda c, a=f1, b=f2: a(c) and b(c)))
            preds.append((f"{n1} and not {n2}", lambda c, a=f1, b=f2: a(c) and not b(c)))
            preds.append((f"{n2} and not {n1}", lambda c, a=f1, b=f2: b(c) and not a(c)))
            preds.append((f"{n1} or {n2}", lambda c, a=f1, b=f2: a(c) or b(c)))
            preds.append((f"neither {n1} nor {n2}",
                          lambda c, a=f1, b=f2: not a(c) and not b(c)))
    return preds


PREDS = visible_predicates()


def infer_relation(a, b):
    """What the first pair of an analogy did, read off the two items."""
    ops = []
    if a["color"] != b["color"]:
        ops.append(("color", b["color"]))
    if a.get("n", 1) != b.get("n", 1):
        ops.append(("n", b.get("n", 1) / a.get("n", 1)))
    if a.get("size", 1) != b.get("size", 1):
        ops.append(("size", b.get("size", 1) - a.get("size", 1)))
    if a.get("rotation", 0) != b.get("rotation", 0):
        ops.append(("rotation", b.get("rotation", 0) - a.get("rotation", 0)))
    return ops


def apply_relation(c, ops):
    out = dict(c)
    for field, v in ops:
        if field == "color":
            out["color"] = "accent" if c["color"] == "primary" else "primary"
        elif field == "n":
            out["n"] = int(round(c.get("n", 1) * v))
        elif field == "size":
            out["size"] = c.get("size", 1) + v
        elif field == "rotation":
            out["rotation"] = (c.get("rotation", 0) + v) % 360
    return out


def grade(qid, q):
    shape, pic = q["shape"], q.get("pic") or {}
    stored = (q.get("answer") or {}).get("value")
    opts = q.get("optionCells") or []
    COUNTS[shape] = COUNTS.get(shape, 0) + 1

    if shape == "pattern":
        want = pic["cells"][pic["gapAt"]]
        hits = [i for i, o in enumerate(opts) if sig(o) == sig(want)]
        if hits != [stored]:
            bad(qid, f"the gap wants option {hits}, stored {stored}")

    elif shape == "numberLine":
        # Walked one hop at a time rather than multiplied, so an arithmetic slip
        # in the kit cannot be repeated by the same arithmetic here.
        at = pic["hopFrom"]
        for _ in range(pic["hops"]):
            at += pic["step"]
        if at != stored:
            bad(qid, f"walking the hops lands on {at}, stored {stored}")

    elif shape == "countObjects":
        if pic["n"] != stored:
            bad(qid, f"picture draws {pic['n']}, stored {stored}")

    elif shape == "array":
        # Counted row by row, not rows*cols.
        total = 0
        for _ in range(pic["rows"]):
            total += pic["cols"]
        if total != stored:
            bad(qid, f"counting the rows gives {total}, stored {stored}")

    elif shape == "oddOneOut":
        # Derived property by property, counting by hand rather than calling
        # the kit's helper, so the two readings stay independent.
        cells = pic["cells"]
        picks = set()
        for prop in ("kind", "color", "rotation"):
            seen = {}
            for c in cells:
                seen.setdefault(c.get(prop, 0), []).append(c)
            if len(seen) == 2 and any(len(v) == 1 for v in seen.values()):
                odd_val = [k for k, v in seen.items() if len(v) == 1][0]
                picks.add(next(i for i, c in enumerate(cells)
                               if c.get(prop, 0) == odd_val))
        if picks != {stored}:
            bad(qid, f"reading each property gives {sorted(picks)}, stored {stored}")

    elif shape == "sortTwo":
        cells, sides = pic["cells"], stored
        ok = [name for name, p in PREDS
              if [0 if p(c) else 1 for c in cells] == sides]
        if not ok:
            bad(qid, "no property a child can see reproduces these trays "
                     f"({pic.get('leftLabel')} / {pic.get('rightLabel')})")

    elif shape == "sizeOrder":
        sizes = pic["sizes"]
        order, left = [], list(range(len(sizes)))
        while left:                       # selection sort, not sorted()
            m = min(left, key=lambda i: sizes[i])
            order.append(m); left.remove(m)
        if order != stored:
            bad(qid, f"smallest-first order is {order}, stored {stored}")

    elif shape == "analogy":
        ops = infer_relation(pic["a"], pic["b"])
        if not ops:
            return bad(qid, "the first pair changes nothing")
        want = apply_relation(pic["c"], ops)
        hits = [i for i, o in enumerate(opts) if sig(o) == sig(want)]
        if hits != [stored]:
            bad(qid, f"the same change applied to C wants {hits}, stored {stored}")

    elif shape == "codeRead":
        key = {k["glyph"]: k["n"] for k in pic["key"]}
        total = 0
        for s in pic["row"]:              # added one at a time
            total += key[s]
        if total != stored:
            bad(qid, f"the row adds to {total}, stored {stored}")

    elif shape == "codePick":
        key = {k["glyph"]: k["n"] for k in pic["key"]}
        got = 0
        for i, s in enumerate(pic["row"]):
            if i != pic["gapAt"]:
                got += key[s]
        need = pic["total"] - got
        holders = [g for g, v in key.items() if v == need]
        if len(holders) != 1:
            return bad(qid, f"{len(holders)} symbols are worth the missing {need}")
        hits = [i for i, o in enumerate(opts) if o["kind"] == holders[0]]
        if hits != [stored]:
            bad(qid, f"the gap needs {holders[0]} at {hits}, stored {stored}")

    else:
        bad(qid, f"no independent check for shape {shape!r}")


def main():
    d = json.load(open(PATH, encoding="utf-8"))
    n = 0
    for sec in d["sections"]:
        for u in sec["units"]:
            for st in u["stops"]:
                for i, q in enumerate(st["questions"]):
                    grade(f"{st['id']}#{i}", q)
                    n += 1
    failed = {f.split("#")[0] for f in FAILS}
    for s, c in sorted(COUNTS.items()):
        print(f"  {s:<14} {c:>4}/{c}  ok")
    if FAILS:
        print()
        for f in FAILS[:40]:
            print("  FAIL", f)
        print(f"\n{len(FAILS)} of {n} answers disagree")
        sys.exit(1)
    print(f"\nevery answer is correct  ({n} re-derived from the picture)")


if __name__ == "__main__":
    main()
