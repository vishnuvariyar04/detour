# -*- coding: utf-8 -*-
"""Plays the whole Reasoning skill without a phone.

rs_grade.py checks every answer is RIGHT by deriving it again from the picture.
This checks the gate can ask each question and a child can answer it:

  RENDER      every field the drawing needs is present
  ANSWERABLE  the answer is one of the options on screen, options are distinct
  FITS        the prompt, picture and answers fit on the 360x797 card, measured
              with the real Nunito files. Band b shipped a first draft whose
              shapes ran off the card; this is the check that would have caught it
  WORDS       one short sentence that says what to do, no banned words, every
              answer text and clue line fits its row
  MATCHES     the prompt asks about the same thing the answer is about
  TEACH       a teach card never shows one of its own questions; no boss has one
  UNIQUE      no question twice, here or in the three other skills
  GUESSABLE   no answer slot a child could tap every time and pass
  LADDER      48 stops, 12 bosses, 324 questions

The layout numbers below are the SAME numbers the review wall's renderers use.
Change one and change the other, or this measures a card nobody draws.
"""
import collections, json, math, os, sys
from PIL import ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..")
PATH = os.path.join(ROOT, "assets", "curriculum_pending", "reasoning.json")
FONTS = os.path.join(ROOT, "assets", "fonts")

W, H, M = 360, 797, 16
CW = W - 2 * M
TOP = 100
BOTTOM = H - 70 - 8                 # the Hint / Check bar starts at H - 70

FAILS = []


def bad(qid, msg):
    FAILS.append(f"{qid}: {msg}")


_font = {}


def tw(s, size, face):
    key = (size, face)
    if key not in _font:
        _font[key] = ImageFont.truetype(os.path.join(FONTS, f"Nunito-{face}.ttf"),
                                        int(round(size * 4)))
    return _font[key].getlength(str(s)) / 4


def wrap_count(s, size, face, maxw):
    """Mirrors wrap() in wall_template.html: greedy by words."""
    lines, line = 0, ""
    for w in str(s).split(" "):
        t = f"{line} {w}" if line else w
        if tw(t, size, face) > maxw and line:
            lines += 1
            line = w
        else:
            line = t
    return lines + (1 if line else 0)


def card_h(lines):
    return 28 + 22 * sum(wrap_count(l, 15, "Bold", CW - 28) for l in lines)


def seq_box(n):
    return min(56, (CW - 6 * (n - 1)) / n)


def pic_h(q):
    p = q.get("pic")
    if p is None:
        return 0
    k = p["kind"]
    if k == "sequence":
        return 64 + (38 if ("askPosition" in p or "askValue" in p) else 0)
    if k in ("clues", "claim", "truth"):
        return card_h(p["lines"])
    if k == "grid":
        return card_h(p["lines"]) + (112 if len(p["people"]) == 3 else 0)
    if k == "binary":
        return 118
    if k == "binaryAsk":
        return 150
    if k == "shift":
        return 150
    if k == "symbols":
        return 40 * math.ceil(len(p["key"]) / 5) + 12 + 54
    if k == "letters":
        return 70
    if k == "net":
        cols = max(c[0] for c in p["cells"]) + 1
        rows = max(c[1] for c in p["cells"]) + 1
        size = min(46, CW / cols, 150 / rows)
        return rows * size + 8
    if k == "roll":
        return max(p["h"] * 38, 104) + 10
    if k == "polycube":
        return 150
    if k == "turnCube":
        return 132 + 22 * len(p["steps"])
    if k == "section":
        return 170
    if k == "mirrorAlpha":
        return 150
    if k == "example":
        return 112
    if k == "stack":
        hs = p["heights"]
        w, d = len(hs[0]), len(hs)
        top = p["full"][2] if p.get("full") else max(map(max, hs))
        s = 24
        return (w + d) * s * 0.5 + top * s + 30
    raise ValueError(k)


def opts_h(q):
    if q.get("choices"):
        return 72
    if q.get("optionsText"):
        return 72 * len(q["optionsText"])
    if q.get("optionCells"):
        return 86
    if q.get("optionBits"):
        return 60 * len(q["optionBits"])
    if q.get("optionNets"):
        return 2 * 132 + 10
    if q.get("optionViews"):
        return 104
    if q.get("optionCubes") or q.get("optionSections"):
        return 2 * 132 + 10
    if q.get("optionShapes"):
        return 86
    return 0


def check_fit(qid, q):
    lines = wrap_count(q["prompt"], 18, "Black", CW)
    if lines > 2:
        bad(qid, f"prompt wraps to {lines} lines")
    y = TOP + lines * 26 + 10
    ph = pic_h(q)
    if ph:
        y += ph + 16
    end = y + opts_h(q)
    if end > BOTTOM:
        bad(qid, f"runs {end - BOTTOM:.0f}dp past the bottom of the card")
    for t in q.get("optionsText") or []:
        if tw(t, 16, "Bold") > CW - 24:
            bad(qid, f'answer "{t}" is too wide for its row')
    for c in q.get("choices") or []:
        if tw(c, 22, "Black") > (CW - 30) / 4 - 10:
            bad(qid, f"number {c} is too wide for its key")
    p = q.get("pic") or {}
    for line in p.get("lines", []):
        if wrap_count(line, 15, "Bold", CW - 28) > 2:
            bad(qid, f'clue "{line[:40]}" needs more than two lines')
    if p.get("kind") == "sequence":
        n = len(p["terms"])
        box = seq_box(n)
        widest = max(tw("?" if t is None else t, 13, "Black") for t in p["terms"])
        if widest > box - 6:
            bad(qid, f"a number is unreadable even at 13dp in a {box:.0f}dp box")


VERBS = ("tap",)
BANNED = ("block", "program", "tile", "instruction")


def check_words(qid, q):
    pr = q.get("prompt") or ""
    if not any(v in pr.lower() for v in VERBS):
        bad(qid, f'prompt never says what to do: "{pr}"')
    if len(pr) > 60:
        bad(qid, f"prompt is {len(pr)} characters, cap is 60")
    for w in BANNED:
        if w in pr.lower():
            bad(qid, f'banned word "{w}"')
    if not q.get("hint"):
        bad(qid, "no hint")


def check_matches(qid, q):
    p = q.get("pic") or {}
    pr = q["prompt"]
    if q["shape"] == "nthTerm" and str(p["askPosition"]) not in pr:
        bad(qid, "prompt names a different position")
    if q["shape"] == "termPosition" and str(p["askValue"]) not in pr:
        bad(qid, "prompt names a different number")
    if p.get("kind") == "binaryAsk" and str(p["target"]) not in pr:
        bad(qid, "prompt names a different number")
    if q["shape"] == "netFace" and p["target"] not in pr:
        bad(qid, "prompt names a different face")
    if q["shape"] == "netPick" and (("NOT" in pr) == bool(q.get("askFolds"))):
        bad(qid, "prompt and question disagree about NOT")
    if q["shape"] == "knights" and p["ask"] not in pr:
        bad(qid, "prompt asks about a different person")
    if q["shape"] == "cubeTurn":
        side = {"T": "on top", "F": "at the front", "R": "on the right"}[p["ask"]]
        if side not in pr:
            bad(qid, "prompt asks about a different side")
        if ("both" in pr) != (len(p["moves"]) == 2):
            bad(qid, "prompt and picture disagree about how many turns")
    if q["shape"] == "sectionWhich":
        want = q["optionShapeWanted"] if "optionShapeWanted" in q else None
    if q["shape"] == "deduce":
        if p.get("who") and f"the {(p['who'] + ' ' + p['noun']).strip()}" not in pr:
            bad(qid, "prompt asks about a different thing")
        if p.get("what") and p["what"] not in pr:
            bad(qid, "prompt asks about a different person")


SMALL_UNCLEAR = {"hexagon", "flower"}


def check_glyphs(qid, q):
    """Nets and symbol keys draw shapes at about 20px, where a flower reads as a
    hexagon and a hexagon as a circle. Neither may appear in them."""
    p = q.get("pic") or {}
    used = set(p.get("marks") or [])
    used |= {k["glyph"] for k in p.get("key") or []}
    used |= {g["glyph"] for g in p.get("word") or [] if isinstance(g, dict)}
    used |= {c["kind"] for c in q.get("optionCells") or []}
    used |= set(p.get("marks") or [])
    if used & SMALL_UNCLEAR:
        bad(qid, f"draws {sorted(used & SMALL_UNCLEAR)} small, where it is easy to misread")


def check_answerable(qid, q):
    a = q["answer"]
    if a["type"] == "number":
        ch = q.get("choices") or []
        if len(ch) != 4 or len(set(ch)) != 4:
            return bad(qid, f"needs four different numbers, has {ch}")
        if a["value"] not in ch:
            bad(qid, "the answer is not among the numbers offered")
        if ch != sorted(ch):
            bad(qid, "number keys are not in order")
        return
    opts = (q.get("optionsText") or q.get("optionCells") or q.get("optionBits")
            or q.get("optionNets") or q.get("optionViews") or q.get("optionCubes")
            or q.get("optionShapes") or q.get("optionSections"))
    if not opts:
        return bad(qid, "no options to tap")
    if not (0 <= a["value"] < len(opts)):
        bad(qid, "answer is not one of the options")
    if len({json.dumps(o, sort_keys=True) for o in opts}) != len(opts):
        bad(qid, "two options are identical")
    if q.get("optionBits"):
        n = len((q.get("pic") or {}).get("values") or [])
        if any(len(b) != n for b in q["optionBits"]):
            bad(qid, "a bulb row has the wrong number of bulbs")


REQUIRED = {
    "sequence": ("terms",), "clues": ("lines", "rules", "facts", "ask"),
    "claim": ("lines", "claim"), "grid": ("people", "things", "clues", "lines"),
    "binary": ("values", "on"), "binaryAsk": ("values", "target"),
    "shift": ("shift", "word", "mode"), "symbols": ("key", "word"),
    "letters": (), "net": ("cells", "marks", "target"),
    "roll": ("w", "h", "start", "moves", "top", "front", "right"),
    "stack": ("heights",),
    "truth": ("lines", "people", "says", "ask"),
    "polycube": ("cubes",), "turnCube": ("marks", "moves", "steps", "ask"),
    "section": ("solid", "point", "normal"), "mirrorAlpha": ("word", "mode"),
    "example": ("example", "word", "mode"),
}


def check_render(qid, q):
    p = q.get("pic")
    if p is None:
        if q["shape"] not in ("netPick", "sectionWhich"):
            bad(qid, "no picture")
        return
    for f in REQUIRED.get(p["kind"], ()):
        if f not in p:
            bad(qid, f"picture has no {f}")


def key_of(q):
    return json.dumps([q.get(k) for k in ("prompt", "pic", "visual", "optionsText",
                                          "optionCells", "optionBits", "optionNets",
                                          "optionViews", "optionCubes", "optionShapes",
                                          "optionSections", "choices", "options")],
                      sort_keys=True)


def main():
    d = json.load(open(PATH, encoding="utf-8"))
    items, stops, bosses = [], 0, 0
    for sec in d["sections"]:
        for u in sec["units"]:
            for st in u["stops"]:
                stops += 1
                bosses += bool(st.get("boss"))
                teach = st.get("teach")
                if st.get("boss") and teach:
                    bad(st["id"], "a boss has a teach card")
                if not st.get("boss") and not (teach and teach.get("line") and teach.get("pic")):
                    bad(st["id"], "no teach line and picture")
                for i, q in enumerate(st["questions"]):
                    qid = f"{st['id']}#{i}"
                    items.append((qid, q))
                    check_render(qid, q)
                    check_answerable(qid, q)
                    check_glyphs(qid, q)
                    check_words(qid, q)
                    check_matches(qid, q)
                    check_fit(qid, q)
                    if teach and json.dumps(teach["pic"], sort_keys=True) == \
                            json.dumps(q.get("pic"), sort_keys=True):
                        bad(st["id"], f"teach card shows question #{i}")

    seen = {}
    for qid, q in items:
        k = key_of(q)
        if k in seen:
            bad(qid, f"same question as {seen[k]}")
        seen[k] = qid
    for other in ("number_sense.json", "think_like_a_coder.json", "puzzles_and_logic.json"):
        o = json.load(open(os.path.join(ROOT, "assets", "curriculum", other), encoding="utf-8"))
        for sec in o["sections"]:
            for u in sec["units"]:
                for st in u["stops"]:
                    for q in st["questions"]:
                        if key_of(q) in seen:
                            bad(seen[key_of(q)], f"already exists in {other}")

    slots = collections.defaultdict(collections.Counter)
    for qid, q in items:
        a = q["answer"]
        if a["type"] == "number":
            slots[q["shape"]][q["choices"].index(a["value"])] += 1
        else:
            slots[q["shape"]][a["value"]] += 1
    for shape, c in slots.items():
        n = sum(c.values())
        top, hits = c.most_common(1)[0]
        if n >= 8 and hits / n > 0.45:
            bad(shape, f"{hits} of {n} answers ({hits * 100 // n}%) in slot {top}")

    if (stops, bosses, len(items)) != (48, 12, 324):
        bad("ladder", f"{stops} stops, {bosses} bosses, {len(items)} questions")

    shapes = collections.Counter(q["shape"] for _, q in items)
    print(f"stops {stops} ({bosses} bosses), questions {len(items)}")
    for s, n in shapes.most_common():
        top = slots[s].most_common(1)[0][1] * 100 // sum(slots[s].values())
        print(f"  {s:<13} {n:>3}   busiest answer slot {top}%")
    if FAILS:
        print()
        for f in FAILS[:60]:
            print("  FAIL", f)
        print(f"\n{len(FAILS)} problem(s)")
        sys.exit(1)
    print("\nOK")


if __name__ == "__main__":
    main()
