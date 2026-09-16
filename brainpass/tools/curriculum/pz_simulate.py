# -*- coding: utf-8 -*-
"""Plays the whole Puzzles & Logic skill (band b, ages 7-8) without a phone.

pz_grade.py proves every answer is RIGHT by working it out again from what the
child reads. This proves the gate can ask each question and a seven year old can
answer it:

  RENDER      every field the drawing needs is there
  ANSWERABLE  the answer is one of the options; options are all different;
              numbers in order, and never below zero
  WORDS       the question is at most eight words and says "tap"; each clue line
              at most eight words, at most three lines (the design memo's band b
              budget); no banned word
  MATCHES     the question asks about the same person, letter or thing that the
              answer is about
  FITS        prompt, picture and answers fit the 360x797 card, measured with the
              real Nunito files
  TEACH       no teach card shows one of its own questions; no boss has one
  UNIQUE      no question twice -- and no PUZZLE twice with only the names, the
              nouns or the order of the numbers changed -- and nothing repeated
              from the other three skills
  GUESSABLE   no answer slot a child could tap every time and pass
  LADDER      48 stops, 12 bosses, 324 questions
"""
import collections, json, math, os, re, sys
from PIL import ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..")
PATH = os.path.join(ROOT, "assets", "curriculum", "puzzles_and_logic.json")
FONTS = os.path.join(ROOT, "assets", "fonts")

W, H, M = 360, 797, 16
CW = W - 2 * M
TOP, BOTTOM = 100, H - 70 - 8
FAILS = []


def bad(qid, msg):
    FAILS.append(f"{qid}: {msg}")


_font = {}


def tw(s, size, face):
    if (size, face) not in _font:
        _font[(size, face)] = ImageFont.truetype(os.path.join(FONTS, f"Nunito-{face}.ttf"), int(size * 4))
    return _font[(size, face)].getlength(str(s)) / 4


def wrap_count(s, size, face, maxw):
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


def words(s):
    return len(s.replace("?", " ").replace(".", " ").split())


# ---- the same layout numbers the wall's band b renderers return ---------------
def pic_h(q):
    p = q.get("pic") or {}
    k = p.get("kind")
    if k == "card":
        return card_h(p["lines"])
    if k == "equation":
        return 70
    if k == "bars":
        return 124
    if k == "series":
        return 64
    if k == "line":
        return 128 if p.get("names") else 110
    if k == "compass":
        return card_h(p["lines"]) + 10 + 118
    if k == "shelf":
        return 84
    if k == "wordPairs":
        return 112
    if k == "numPairs":
        return 44 * len(p["pairs"]) + 12
    if k in ("example", "numExample"):
        return 112
    if k == "letter":
        return 70
    if k == "words":
        return 0
    if k == "clock":
        return 140 + (card_h(p["lines"]) + 10 if p.get("lines") else 0)
    raise ValueError(k)


def opts_h(q):
    if q.get("choices"):
        return 72
    if q.get("optionsText"):
        return 72 * len(q["optionsText"])
    if q.get("optionCells"):
        return 86
    return 0


BANNED = ("block", "program", "tile", "instruction", "stupid", "dumb", "wrong!")
REQUIRED = {
    "equation": ("left", "op", "right", "result", "hide"), "card": ("lines",),
    "bars": ("names", "values", "shown", "hide"), "series": ("terms",),
    "line": ("n",), "compass": ("lines", "start", "moves"),
    "shelf": ("items", "target", "side", "steps"), "wordPairs": ("pairs",),
    "numPairs": ("pairs",), "example": ("example", "word", "mode"),
    "numExample": ("example", "word", "mode"), "letter": ("base", "offset"),
    "words": ("words",), "clock": ("h", "m", "form"),
}


def check(qid, q):
    p = q.get("pic") or {}
    pr = q.get("prompt") or ""
    for f in REQUIRED.get(p.get("kind"), ("?",)):
        if f not in p:
            bad(qid, f"picture has no {f}")
    if "tap" not in pr.lower():
        bad(qid, f'the question never says what to do: "{pr}"')
    if words(pr) > 8:
        bad(qid, f"the question is {words(pr)} words; the band b cap is 8")
    lines = p.get("lines") or []
    if len(lines) > 3:
        bad(qid, f"{len(lines)} clue lines; the cap is 3")
    for l in lines:
        if words(l) > 8:
            bad(qid, f'clue "{l}" is {words(l)} words; the cap is 8')
    for t in [pr] + lines + list(q.get("optionsText") or []):
        for b in BANNED:
            if re.search(rf"\b{re.escape(b)}\b", t.lower()):
                bad(qid, f'banned word "{b}"')
    if not q.get("hint"):
        bad(qid, "no hint")

    a = q["answer"]
    if a["type"] == "number":
        ch = q.get("choices") or []
        if len(ch) != 4 or len(set(ch)) != 4:
            bad(qid, f"needs four different numbers, has {ch}")
        elif a["value"] not in ch:
            bad(qid, "the answer is not among the numbers")
        elif ch != sorted(ch):
            bad(qid, "numbers are not in order")
        if any(c < 0 for c in ch):
            bad(qid, "a negative number is offered to a seven year old")
    else:
        opts = q.get("optionsText") or q.get("optionCells")
        if not opts:
            bad(qid, "no options")
        else:
            if not 0 <= a["value"] < len(opts):
                bad(qid, "the answer is not one of the options")
            if len({json.dumps(o, sort_keys=True) for o in opts}) != len(opts):
                bad(qid, "two options are the same")
            if len(opts) < 3:
                bad(qid, "fewer than three options")

    sh = q["shape"]
    if sh in ("relation",) and (p["x"] not in pr or p["y"] not in pr):
        bad(qid, "the question asks about other people")
    if sh == "relationWho" and (p["y"] not in pr or p["term"] not in pr):
        bad(qid, "the question asks for someone else")
    if sh == "queueBack" and p["name"] not in pr:
        bad(qid, "the question is about another child")
    if sh == "turns" and p["lines"][0].split(" ")[0] not in pr:
        bad(qid, "the question is about another child")
    if sh == "shelf" and (p["target"] not in pr or p["side"] not in pr):
        bad(qid, "the question and the row disagree")
    if sh == "alphabet" and p["base"] not in pr:
        bad(qid, "the question names another letter")
    if sh == "clock" and (p["form"] == "read") != ("clock shows" in pr):
        bad(qid, "the question and the clock disagree about what is asked")

    nlines = wrap_count(pr, 18, "Black", CW)
    if nlines > 2:
        bad(qid, f"the question wraps to {nlines} lines")
    y = TOP + nlines * 26 + 10
    ph = pic_h(q)
    if ph:
        y += ph + 16
    end = y + opts_h(q)
    if end > BOTTOM:
        bad(qid, f"runs {end - BOTTOM:.0f}dp past the bottom of the card")
    for t in q.get("optionsText") or []:
        if tw(t, 16, "Bold") > CW - 24:
            bad(qid, f'answer "{t}" is too wide for its row')


def canon_people(names, *structs):
    """Replace names by the order they first appear, so a puzzle retold with
    other names is recognised as the same puzzle."""
    order = {}
    def swap(x):
        if isinstance(x, str) and x in names:
            order.setdefault(x, f"P{len(order)}")
            return order[x]
        if isinstance(x, (list, tuple)):
            return [swap(v) for v in x]
        return x
    return json.dumps([swap(s) for s in structs])


def puzzle_key(q):
    """What makes two questions the same puzzle, whatever the wording."""
    p, sh = q.get("pic") or {}, q["shape"]
    if sh == "equation":
        return (sh, p["left"], p["op"], p["right"], p["hide"])
    if sh == "riddle":
        return (sh, json.dumps(p["steps"]), p["result"])
    if sh == "story":
        return (sh, p["schema"], tuple(p["nums"]))
    if sh == "bars":
        return (sh, tuple(p["values"]), p["hide"])
    if sh in ("series", "seriesRule"):
        return (sh, json.dumps(p["terms"]))
    if sh in ("rank", "rankCount"):
        extra = p.get("ask") or p.get("who")
        return (sh, p["dim"], canon_people(p["people"], p["clues"], extra))
    if sh == "queueBack":
        return (sh, p["n"], p["mark"])
    if sh == "queueCalc":
        return (sh, p["calc"], tuple(sorted(p["nums"])))
    if sh == "queueWho":
        return (sh, p["n"], p["nth"], p["end"])
    if sh == "turns":
        return (sh, p["start"], tuple(p["moves"]))
    if sh == "shelf":
        return (sh, len(p["items"]), p["items"].index(p["target"]), p["side"], p["steps"])
    if sh in ("relation", "relationWho"):
        names = sorted({f[0] for f in p["facts"]} | {f[2] for f in p["facts"]})
        return (sh, canon_people(names, p["facts"], p.get("x"), p.get("y"), p.get("term")))
    if sh == "wordAnalogy":
        return (sh, p["pairs"][0][0], p["pairs"][1][0])
    if sh == "numberAnalogy":
        return (sh, json.dumps(p["pairs"]))
    if sh in ("wordCode", "numCode"):
        return (sh, json.dumps(p["example"]), p["word"])
    if sh == "alphabet":
        return (sh, p["base"], p["offset"])
    if sh in ("oddWord", "oddNumber"):
        return (sh, tuple(sorted(p["words"])))
    if sh == "weekday":
        return (sh, p["form"], p["day"], p.get("n"))
    if sh == "month":
        return (sh, p["base"], p["offset"])
    if sh == "clock":
        return (sh, p["h"], p["m"], p["form"], p.get("delta"))
    if sh == "combos":
        return (sh, tuple(sorted(p["nums"])))
    return (sh, json.dumps(p, sort_keys=True))


def screen_key(q):
    return json.dumps([q.get(k) for k in ("prompt", "pic", "optionsText", "optionCells", "choices")],
                      sort_keys=True)


def main():
    d = json.load(open(PATH, encoding="utf-8"))
    items, stops, bosses = [], 0, 0
    for sec in d["sections"]:
        for u in sec["units"]:
            shapes_here = set()
            for st in u["stops"]:
                stops += 1
                bosses += bool(st.get("boss"))
                teach = st.get("teach")
                if st.get("boss") and teach:
                    bad(st["id"], "a boss has a teach card")
                if not st.get("boss") and not (teach and teach.get("line") and teach.get("pic")):
                    bad(st["id"], "no teach card")
                for i, q in enumerate(st["questions"]):
                    qid = f"{st['id']}#{i}"
                    items.append((qid, q))
                    shapes_here.add(q["shape"])
                    check(qid, q)
                    if teach and json.dumps(teach["pic"], sort_keys=True) == \
                            json.dumps(q.get("pic"), sort_keys=True):
                        bad(st["id"], f"the teach card shows question #{i}")
            if len(shapes_here) < 2:
                bad(f"unit {sec['n']}.{u['n']}", "uses only one kind of question")

    seen_screen, seen_puzzle = {}, {}
    for qid, q in items:
        k = screen_key(q)
        if k in seen_screen:
            bad(qid, f"the same question as {seen_screen[k]}")
        seen_screen[k] = qid
        pk = json.dumps(puzzle_key(q))
        if pk in seen_puzzle:
            bad(qid, f"the same puzzle as {seen_puzzle[pk]}, retold")
        seen_puzzle[pk] = qid
    for folder, other in (("curriculum", "number_sense.json"), ("curriculum", "think_like_a_coder.json"),
                          ("curriculum", "reasoning.json")):
        o = json.load(open(os.path.join(ROOT, "assets", folder, other), encoding="utf-8"))
        for sec in o["sections"]:
            for u in sec["units"]:
                for st in u["stops"]:
                    for q in st["questions"]:
                        if screen_key(q) in seen_screen:
                            bad(seen_screen[screen_key(q)], f"already exists in {other}")

    slots = collections.defaultdict(collections.Counter)
    for qid, q in items:
        a = q["answer"]
        slot = q["choices"].index(a["value"]) if a["type"] == "number" else a["value"]
        slots[q["shape"]][slot] += 1
    for sh, c in slots.items():
        n = sum(c.values())
        top, hits = c.most_common(1)[0]
        if n >= 8 and hits / n > 0.45:
            bad(sh, f"{hits} of {n} answers ({hits * 100 // n}%) in slot {top}")

    if (stops, bosses, len(items)) != (48, 12, 324):
        bad("ladder", f"{stops} stops, {bosses} bosses, {len(items)} questions")

    shapes = collections.Counter(q["shape"] for _, q in items)
    print(f"stops {stops} ({bosses} bosses), questions {len(items)}, "
          f"{len(seen_puzzle)} different puzzles")
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
