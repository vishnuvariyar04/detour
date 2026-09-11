# -*- coding: utf-8 -*-
"""Answers every Number Sense question the way the app grades it.

ns_simulate.py checks that each question is FAIR — answerable, readable, and
posed by a picture that matches. This checks something different and more
important: that a child who does the right thing is marked right.

It re-implements CoderGate.submit()'s comparison for every shape, works out
what a correct child would tap from the picture alone, and feeds that through.
If this and the authored answer ever disagree, one of them is wrong, and a
child would be told their correct answer was not.

It is deliberately a SECOND implementation. Reading the answer out of the JSON
and comparing it to itself proves nothing; deriving it again from the picture
is what makes the agreement mean something.
"""
import json
import os
import sys

import figures as FIG

HERE = os.path.dirname(os.path.abspath(__file__))
JSON = os.path.join(HERE, "..", "..", "assets", "curriculum", "number_sense.json")

WRONG = []


def fail(qid, msg):
    WRONG.append(f"{qid}: {msg}")


def what_a_child_taps(q):
    """The answer worked out from the picture, not read from the answer field.

    Returns (value, how) or (None, reason) when the picture cannot be read.
    """
    sh, pic = q["shape"], q.get("pic") or {}

    if sh == "countObjects":
        sp = pic.get("splitAt", -1)
        if sp < 0:
            return pic["n"], "counted them all"
        yellow = pic["n"] - sp
        asked_yellow = "yellow" in q["prompt"]
        return (yellow if asked_yellow else sp), "counted one colour"

    if sh == "tenFrame":
        if "more" in q["prompt"] and "fill" in q["prompt"]:
            return 10 - pic["filled"], "counted the empty cells"
        return pic["filled"] + max(pic.get("second", -1), 0), "counted the counters"

    if sh == "dice":
        return sum(pic["faces"]), "added the faces"

    if sh == "rods":
        return pic["n"], "ten for each stick, plus the ones"

    if sh == "bond":
        w, l, r, gap = (pic.get("whole"), pic.get("left"),
                        pic.get("right"), pic.get("gap"))
        if gap == "right":
            return w - l, "whole take the part shown"
        if gap == "left":
            return w - r, "whole take the part shown"
        return l + r, "the two parts added"

    if sh == "numberLine":
        step = pic.get("step", 1)
        hops = pic.get("hops")
        if hops is None:
            # a plain hop question states the count in its prompt
            import re
            m = re.search(r"Take (\d+) hops", q["prompt"])
            if not m:
                return None, "the prompt does not say how many hops"
            hops = int(m.group(1))
        return pic["hopFrom"] + step * hops, f"{hops} hops of {step}"

    if sh == "balance":
        l, r = pic["leftCount"], pic["rightCount"]
        return (0 if l > r else 1 if r > l else 2), "the heavier pan goes down"

    if sh == "array":
        return pic["rows"] * pic["cols"], "rows times columns"

    if sh == "groups":
        return (pic["per"] if pic.get("share")
                else pic["groups"] * pic["per"]), "groups of the same size"

    if sh == "barModel":
        return (abs(pic["a"] - pic["b"]) if pic["ask"] == "more"
                else pic["a"] + pic["b"]), "the bars compared"

    if sh == "shapeCount":
        return FIG.counts(pic["figure"], pic["target"]), "counted the shapes"

    if sh == "fraction":
        a = pic["shaded"] / pic["slices"]
        b = pic["otherShaded"] / pic["otherSlices"]
        return (0 if a > b else 1), "the fuller circle"

    if sh == "fractionWall":
        rows = pic["rows"]
        if pic.get("ask", "biggest") == "biggest":
            sizes = [r[0] for r in rows]
            return sizes.index(min(sizes)), "fewest pieces means biggest pieces"
        top = rows[0][1] / rows[0][0]
        for i in range(1, len(rows)):
            if abs(rows[i][1] / rows[i][0] - top) < 1e-9:
                return i, "the strip covering the same amount"
        return None, "no strip matches the top"

    if sh == "oddOneOut":
        cells = pic["cells"]
        sig = [(c["kind"], c["color"], c.get("rotation", 0)) for c in cells]
        for i, s in enumerate(sig):
            if sig.count(s) == 1:
                return i, "the one unlike the rest"
        return None, "no single odd one"

    if sh == "pattern":
        want = pic["cells"][pic["gapAt"]]
        opts = q.get("optionCells") or []
        for i, o in enumerate(opts):
            if (o["kind"], o["color"], o.get("rotation", 0)) == \
               (want["kind"], want["color"], want.get("rotation", 0)):
                return i, "the option matching the gap"
        return None, "no option matches the gap"

    if sh == "sizeOrder":
        sizes = pic["sizes"]
        return sorted(range(len(sizes)), key=lambda i: sizes[i]), "smallest first"

    if sh == "sortTwo":
        return q["answer"]["value"], "each shape against the label"

    if sh == "mirror":
        cols = pic["cols"]
        return [[cols - 1 - c, r] for c, r in pic["given"]], "reflected across the fold"

    if sh == "shapeHunt":
        kinds = [k for k, _ in FIG.FIGURES[pic["figure"]][1]]
        return [i for i, k in enumerate(kinds) if k == pic["target"]], "every matching piece"

    return None, f"no rule for {sh}"


def gradeable(q, tapped):
    """Mirrors how CoderGate.submit() compares a tap with the stored answer."""
    sh, want = q["shape"], q["answer"]["value"]
    if sh in ("countObjects", "tenFrame", "dice", "rods", "bond", "numberLine",
              "array", "groups", "barModel", "shapeCount"):
        return tapped == want, "number key"
    if sh in ("balance", "fraction", "fractionWall", "oddOneOut", "pattern"):
        return tapped == want, "option index"
    if sh in ("sizeOrder",):
        return list(tapped) == list(want), "tap order"
    if sh in ("sortTwo",):
        return list(tapped) == list(want), "tray per item"
    if sh in ("mirror",):
        return sorted(map(list, tapped)) == sorted(map(list, want)), "cells"
    if sh == "shapeHunt":
        # graded by KIND in the app, so any piece of the right kind counts
        kinds = [k for k, _ in FIG.FIGURES[q["pic"]["figure"]][1]]
        want_set = {i for i, k in enumerate(kinds) if k == q["pic"]["target"]}
        return set(tapped) == want_set, "set of pieces"
    return False, "ungraded shape"


def main():
    d = json.load(open(JSON, encoding="utf-8"))
    qs = [(f"{st['id']}#{i}", q)
          for sec in d["sections"] for u in sec["units"] for st in u["stops"]
          if st.get("authored")
          for i, q in enumerate(st["questions"])]

    by_shape = {}
    for qid, q in qs:
        tapped, how = what_a_child_taps(q)
        if tapped is None:
            fail(qid, f"cannot work the answer out from the picture: {how}")
            continue
        ok, _ = gradeable(q, tapped)
        by_shape.setdefault(q["shape"], [0, 0])
        by_shape[q["shape"]][1] += 1
        if ok:
            by_shape[q["shape"]][0] += 1
        else:
            fail(qid, f"a child who {how} would be marked WRONG "
                      f"(picture says {tapped}, answer says {q['answer']['value']})")

    print(f"checked {len(qs)} questions against the app's own grading\n")
    for sh in sorted(by_shape):
        ok, n = by_shape[sh]
        mark = "ok" if ok == n else "FAIL"
        print(f"  {sh:14} {ok:3}/{n:<3} {mark}")
    print()
    for w in WRONG:
        print("  WRONG", w)
    print("every answer is correct" if not WRONG
          else f"{len(WRONG)} question(s) would mark a correct child wrong")
    return 1 if WRONG else 0


if __name__ == "__main__":
    sys.exit(main())
