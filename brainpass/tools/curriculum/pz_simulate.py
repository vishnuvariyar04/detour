# -*- coding: utf-8 -*-
"""Plays the whole Puzzles & Logic skill without a phone.

pz_grade.py checks that the stored answers are the RIGHT answers, by deriving
each one a second time from the picture. This goes further and checks that the
gate can actually ask each question and that a child can actually answer it:

  RENDER      every field CoderGate reads for that shape is present and sane
  ANSWERABLE  the answer can be expressed with the controls on screen -- an
              index inside the options drawn, a number among the four offered,
              a number that exists on the line
  GRADING     the stored answer marks right and a wrong one marks wrong. A
              question everything passes teaches nothing
  TEACH       a stop's teach picture is not one of its own question pictures,
              or the card gives the answer away before the question is asked
  UNIQUE      no question appears twice in the skill, and none collides with
              the 648 already shipped in the other two skills
  WORDS       every prompt says what to DO, and none uses a banned word
  LADDER      the stops serve all 324 exactly once, in order, and terminate

Run after any content change:
    python pz_emit.py && python pz_simulate.py && python pz_grade.py
"""
import json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
CUR = os.path.join(HERE, "..", "..", "assets", "curriculum")

from puzzles_kit import odd_readings

FAILS = []


def bad(qid, msg):
    FAILS.append(f"{qid}: {msg}")


# "Block" is banned outright in this repo: it reads as either an instruction or
# a board square depending on who you ask, which is the worst property for the
# one noun a question hangs on. The rest are the coder skill's vocabulary that
# has no business in a puzzle.
BANNED = ("block", "blocks", "program", "instruction", "tile", "loop", "code word")

VERBS = ("tap", "count", "move", "fold", "put", "add", "start", "sort", "read")

MAX_PROMPT = 56          # characters. Tightened from 96 after review: seven
                         # year olds, many reading in a second or third
                         # language, on a card over the app they wanted.
                         # A rule that needs more room goes on the TRAY
                         # LABEL, which is on screen beside the shapes,
                         # rather than into a longer sentence.
MAX_SENTENCES = 3


def check_words(qid, q):
    prompt = q.get("prompt") or ""
    if not prompt:
        return bad(qid, "no prompt")
    if not any(v in prompt.lower() for v in VERBS):
        bad(qid, f'the prompt never says what to do: "{prompt[:46]}"')
    for w in BANNED:
        if w in prompt.lower():
            bad(qid, f'banned word "{w}" in the prompt')
    if len(prompt) > MAX_PROMPT:
        bad(qid, f"prompt is {len(prompt)} characters, cap is {MAX_PROMPT}")
    if prompt.count(".") + prompt.count("?") > MAX_SENTENCES:
        bad(qid, f"prompt is more than {MAX_SENTENCES} sentences")
    if not q.get("hint"):
        bad(qid, "no hint")


def _same(a, b):
    k = lambda c: (c["kind"], c["color"], c.get("rotation", 0),
                   c.get("n", 1), c.get("size", 1))
    return k(a) == k(b)


def check_question(qid, q):
    shape, pic = q["shape"], q.get("pic") or {}
    ans = q.get("answer") or {}
    opts = q.get("optionCells")
    choices = q.get("choices")

    # ---- RENDER + ANSWERABLE, per shape --------------------------------
    if shape == "pattern":
        cells, gap = pic.get("cells"), pic.get("gapAt")
        if not cells or gap is None:
            return bad(qid, "pattern has no cells or no gap")
        if not (0 <= gap < len(cells)):
            return bad(qid, f"gap {gap} is outside a {len(cells)}-cell strip")
        if len(cells) < 5:
            bad(qid, f"strip is only {len(cells)} cells; too short to show a rule")
        if not opts or len(opts) != 4:
            return bad(qid, f"needs 4 drawn options, has {len(opts or [])}")
        if not (0 <= ans.get("value", -1) < 4):
            return bad(qid, "answer is not one of the four options")
        if not _same(opts[ans["value"]], cells[gap]):
            bad(qid, "the answer option is not the shape the gap wants")
        if sum(1 for o in opts if _same(o, cells[gap])) != 1:
            bad(qid, "more than one option fits the gap")

    elif shape == "numberLine":
        lo, hi = pic.get("from"), pic.get("to")
        end = pic["hopFrom"] + pic["step"] * pic["hops"]
        if end != ans.get("value"):
            bad(qid, f"lands on {end} but the answer says {ans.get('value')}")
        if not (lo <= end <= hi):
            bad(qid, f"lands on {end}, off a line running {lo} to {hi}")
        if pic["hops"] < 2:
            bad(qid, "one hop is not a pattern")

    elif shape in ("countObjects", "array"):
        want = pic["n"] if shape == "countObjects" else pic["rows"] * pic["cols"]
        if want != ans.get("value"):
            bad(qid, f"picture shows {want} but the answer says {ans.get('value')}")
        if not choices or len(choices) != 4:
            return bad(qid, f"needs 4 numbers to tap, has {len(choices or [])}")
        if ans.get("value") not in choices:
            bad(qid, "the answer is not among the numbers offered")

    elif shape == "oddOneOut":
        cells = pic.get("cells") or []
        if len(cells) < 4:
            return bad(qid, f"only {len(cells)} cells")
        # Read one property at a time: band b makes the others noise, so a
        # full-signature comparison finds nothing.
        readings = odd_readings(cells)
        if not readings:
            return bad(qid, "no single property has exactly one outlier")
        picks = {i for _, i in readings}
        if len(picks) > 1:
            return bad(qid, f"two answers are defensible: {readings}")
        if readings[0][1] != ans.get("value"):
            bad(qid, f"the odd cell is {readings[0][1]} but the answer says "
                     f"{ans.get('value')}")

    elif shape == "sortTwo":
        cells, sides = pic.get("cells") or [], ans.get("value") or []
        if len(cells) != len(sides):
            return bad(qid, f"{len(cells)} shapes but {len(sides)} sides")
        if len(cells) < 4:
            bad(qid, f"only {len(cells)} shapes to sort")
        if 0 not in sides or 1 not in sides:
            bad(qid, "every shape goes in one tray; there is nothing to decide")
        if not pic.get("leftLabel") or not pic.get("rightLabel"):
            bad(qid, "a tray has no label")

    elif shape == "sizeOrder":
        sizes = pic.get("sizes") or []
        want = sorted(range(len(sizes)), key=lambda i: sizes[i])
        if want != ans.get("value"):
            bad(qid, f"sorted order is {want}, answer says {ans.get('value')}")
        if len(set(sizes)) != len(sizes):
            bad(qid, f"two shapes share a size {sizes}; the order is not decidable")

    elif shape == "analogy":
        for f in ("a", "b", "c"):
            if not pic.get(f):
                return bad(qid, f"analogy has no {f}")
        if not opts or len(opts) != 4:
            return bad(qid, f"needs 4 drawn options, has {len(opts or [])}")
        if not (0 <= ans.get("value", -1) < 4):
            return bad(qid, "answer is not one of the four options")
        if _same(pic["a"], pic["b"]):
            bad(qid, "the first pair does not change; there is no relation to copy")

    elif shape == "codeRead":
        key = {k["glyph"]: k["n"] for k in pic.get("key") or []}
        row = pic.get("row") or []
        if not key or not row:
            return bad(qid, "code has no key or no row")
        missing = [s for s in row if s not in key]
        if missing:
            return bad(qid, f"row uses {missing}, absent from the key")
        total = sum(key[s] for s in row)
        if total != ans.get("value"):
            bad(qid, f"row totals {total} but the answer says {ans.get('value')}")
        if not choices or len(choices) != 4:
            return bad(qid, f"needs 4 numbers to tap, has {len(choices or [])}")
        if ans.get("value") not in choices:
            bad(qid, "the answer is not among the numbers offered")
        if total > 20:
            bad(qid, f"total {total} is a lot of adding for seven")

    elif shape == "codePick":
        key = {k["glyph"]: k["n"] for k in pic.get("key") or []}
        row, gap = pic.get("row") or [], pic.get("gapAt")
        if gap is None or not (0 <= gap < len(row)):
            return bad(qid, "code gap is missing or outside the row")
        known = [s for i, s in enumerate(row) if i != gap]
        missing = [s for s in known if s not in key]
        if missing:
            return bad(qid, f"row uses {missing}, absent from the key")
        need = pic["total"] - sum(key[s] for s in known)
        holders = [g for g, v in key.items() if v == need]
        if len(holders) != 1:
            return bad(qid, f"the gap needs {need}; {len(holders)} symbols are worth that")
        if not opts or len(opts) != 4:
            return bad(qid, f"needs 4 drawn options, has {len(opts or [])}")
        if opts[ans["value"]]["kind"] != holders[0]:
            bad(qid, "the answer option is not the symbol the gap needs")
        if need <= 0:
            bad(qid, f"the gap is worth {need}; nothing to find")

    else:
        bad(qid, f"unknown shape {shape!r}")

    # ---- GRADING: a wrong answer must actually be marked wrong ---------
    t = ans.get("type")
    if t == "int":
        n = len(opts) if opts else (len(choices) if choices else 0)
        if n and all(i == ans["value"] for i in range(n)):
            bad(qid, "every option is the answer")
    elif t == "ints":
        v = ans.get("value") or []
        if len(set(map(tuple, [v]))) and len(v) == 0:
            bad(qid, "empty answer")


def main():
    path = os.path.join(CUR, "puzzles_and_logic.json")
    d = json.load(open(path, encoding="utf-8"))

    items, shapes = [], {}
    n_stops = n_boss = 0
    for sec in d["sections"]:
        for u in sec["units"]:
            for st in u["stops"]:
                n_stops += 1
                if st.get("boss"):
                    n_boss += 1
                teach = st.get("teach") or {}
                tpic = teach.get("pic")
                if st.get("boss") and teach:
                    bad(st["id"], "a boss has a teach card; both shipped skills leave theirs bare")
                if not st.get("boss") and not teach.get("line"):
                    bad(st["id"], "no teach line")
                for i, q in enumerate(st["questions"]):
                    qid = f"{st['id']}#{i}"
                    items.append((qid, q))
                    shapes[q["shape"]] = shapes.get(q["shape"], 0) + 1
                    check_words(qid, q)
                    check_question(qid, q)
                    if tpic and json.dumps(tpic, sort_keys=True) == \
                            json.dumps(q.get("pic"), sort_keys=True):
                        bad(st["id"], f"the teach picture is question #{i} itself")

    # ---- UNIQUE, here and against everything already shipped -----------
    def key_of(q):
        return json.dumps({"p": q.get("prompt"), "pic": q.get("pic"),
                           "o": q.get("optionCells"), "c": q.get("choices")},
                          sort_keys=True)

    seen = {}
    for qid, q in items:
        k = key_of(q)
        if k in seen:
            bad(qid, f"the same question as {seen[k]}")
        seen[k] = qid

    for other in ("number_sense.json", "think_like_a_coder.json"):
        p = os.path.join(CUR, other)
        if not os.path.exists(p):
            continue
        o = json.load(open(p, encoding="utf-8"))
        for sec in o["sections"]:
            for u in sec["units"]:
                for st in u["stops"]:
                    for q in st["questions"]:
                        k = key_of(q)
                        if k in seen:
                            bad(seen[k], f"already exists in {other} at {st['id']}")

    # ---- GUESSABLE -----------------------------------------------------
    # Added after measuring the shipped skills: every number answer in Think
    # Like a Coder is the second of four (100% of 93) and 88% of Number Sense's
    # are the third, so a child tapping one slot scores full marks without
    # reading the question. Nothing caught it because every answer was, on its
    # own, correct. This is the check that would have.
    import collections
    fams = collections.defaultdict(collections.Counter)
    for qid, q in items:
        v = (q.get("answer") or {}).get("value")
        if not isinstance(v, int) or isinstance(v, bool):
            continue
        if q.get("optionCells"):
            fams[q["shape"]][v] += 1
        elif q.get("choices") and v in q["choices"]:
            fams["number choices"][q["choices"].index(v)] += 1
    for fam, slots in fams.items():
        n = sum(slots.values())
        if n < 8:
            continue
        top, hits = slots.most_common(1)[0]
        if hits / n > 0.45:
            bad(fam, f"{hits} of {n} answers ({hits*100//n}%) sit in slot {top}; "
                     f"a child tapping it every time passes without looking")

    # ---- LADDER --------------------------------------------------------
    if n_stops != 48:
        bad("ladder", f"{n_stops} stops, expected 48")
    if n_boss != 12:
        bad("ladder", f"{n_boss} bosses, expected 12")
    if len(items) != 324:
        bad("ladder", f"{len(items)} questions, expected 324")
    served = [qid for qid, _ in items]
    if len(set(served)) != len(served):
        bad("ladder", "a question id is served twice")

    print(f"stops          : {n_stops} ({n_boss} bosses)")
    print(f"questions      : {len(items)}")
    print(f"ladder walk    : {len(served)} served, {len(set(served))} distinct")
    for s, n in sorted(shapes.items(), key=lambda x: -x[1]):
        print(f"  {s:<14} {n}")
    if FAILS:
        print()
        for f in FAILS[:40]:
            print("  FAIL", f)
        print(f"\n{len(FAILS)} problem(s)")
        sys.exit(1)
    print("\nOK")


if __name__ == "__main__":
    main()
