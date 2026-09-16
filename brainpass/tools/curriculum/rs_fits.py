# -*- coding: utf-8 -*-
"""Measures every Reasoning question with the real font and fails if it will not
fit on the phone.

The band b twin of this is pz_fits.py, and the reason for both is the same:
clipped text is invisible to every other check here. What band d adds is longer
sentences ("Asha is a truth-teller." is an option, not a prompt) and two screens
that put thirteen cells across the card, where a single extra letter has
nowhere to go.

The solids are deliberately NOT measured. Every one of them scales itself to the
box it is given -- Solid.voxels and Solid.solidCut both fit their content to the
width and height passed in -- so they cannot overflow. What they can do is come
out too small to read, and that is a judgement a measurement does not make. Look
at those on a screen (handoff/05_NATIVE_VIEWS.md §4).

Geometry mirrored from ReasonViews.kt and CoderGate.kt:
  body padding 20dp each side             -> 320dp usable
  textOptions    full width, 16sp, 14dp inset each side
  numberChoices  four across, 10dp gaps, 22sp
  shift/mirror   13 cells across the full width
  codeWord       38dp label, then min(40, (w - 38 - 6n) / n) per cell
  symbols        5 per row, glyph then "= X" at 15sp
  letters        48dp cells, 18dp gaps for codes and 8dp for letters
  net            cells at min(46, w/cols, 150/rows)
  deduce grid    84dp name column, then three columns of (w - 84) / 3
"""
import json, math, os, sys
from PIL import ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.join(HERE, "..", "..", "assets", "fonts")
SCALE = 8

_cache = {}


def font(name, size_dp):
    key = (name, round(size_dp * SCALE))
    if key not in _cache:
        _cache[key] = ImageFont.truetype(
            os.path.join(FONTS, name), int(round(size_dp * SCALE)))
    return _cache[key]


def width(s, size_dp, weight=900):
    name = {900: "Nunito-Black.ttf", 800: "Nunito-ExtraBold.ttf",
            700: "Nunito-Bold.ttf", 600: "Nunito-SemiBold.ttf"}[weight]
    return font(name, size_dp).getlength(str(s)) / SCALE


def fit_size(s, max_w, size, lo, weight=900):
    z = size
    while z > lo and width(s, z, weight) > max_w:
        z -= 1
    return z


BODY = 360 - 40
fails = []


def bad(qid, what):
    fails.append("%s: %s" % (qid, what))


def check_options(qid, q):
    if q["answer"]["type"] == "number":
        cell = (BODY - 30) / 4
        for n in q.get("choices", []):
            if width(n, 22, 800) > cell - 12:
                bad(qid, "number %s too wide for a %.0fdp button" % (n, cell))
        return
    for t in (q.get("optionsText") or []):
        if width(t, 16, 800) > BODY - 28:
            bad(qid, "option %r is %.0fdp wide, button holds %.0f"
                % (t, width(t, 16, 800), BODY - 28))


def check_code_word(qid, pic):
    """The word under an alphabet table, which is where a long one runs out."""
    word = str(pic.get("word") or "")
    if not word or not isinstance(pic.get("word"), str):
        return
    n = len(word)
    cell = min(40, (BODY - 38 - 6 * n) / n)
    if cell < 18:
        bad(qid, "%d letters leave %.0fdp cells, too narrow to read" % (n, cell))
    if width(word[0], 20) > cell - 4:
        bad(qid, "a letter does not fit its %.0fdp cell" % cell)


def check_pic(qid, q):
    pic = q.get("pic") or {}
    k = pic.get("kind")

    if k == "sequence":
        terms = pic.get("terms") or []
        n = max(len(terms), 1)
        box = min(56, (BODY - 6 * (n - 1)) / n)
        for v in terms:
            lab = "?" if v is None else str(v)
            if fit_size(lab, box - 6, 20, 11) == 11 and width(lab, 11) > box - 6:
                bad(qid, "sequence term %r does not fit a %.0fdp box" % (lab, box))
        if pic.get("askPosition"):
            s = "%dth number  =  ?" % pic["askPosition"]
            if width(s, 18) > BODY:
                bad(qid, "the asking line is wider than the card")

    elif k in ("claim", "clues", "truth"):
        rows = wrap_rows(pic.get("lines") or [])
        if rows > 6:
            bad(qid, "clue card wraps to %d rows" % rows)

    elif k == "grid":
        rows = wrap_rows(pic.get("lines") or [])
        if rows > 6:
            bad(qid, "clue card wraps to %d rows" % rows)
        cw = (BODY - 84) / 3
        for t in (pic.get("things") or []):
            label = ("%s %s" % (t, pic.get("noun") or "")).strip()
            if fit_size(label, cw - 6, 12, 9, 800) == 9 and width(label, 9, 800) > cw - 6:
                bad(qid, "grid heading %r needs more than its %.0fdp column" % (label, cw))
        for n in (pic.get("people") or []):
            if width(n, 13, 800) > 84 - 8:
                bad(qid, "name %r is wider than the 84dp name column" % n)

    elif k in ("binary", "binaryAsk"):
        vals = pic.get("values") or []
        n = max(len(vals), 1)
        cell = BODY / n
        for v in vals:
            if width(v, 13, 800) > cell - 4:
                bad(qid, "place value %s does not fit a %.0fdp column" % (v, cell))

    elif k in ("shift", "mirrorAlpha"):
        cell = BODY / 13
        if width("W", 13) > cell - 4:
            bad(qid, "the alphabet table's %.0fdp cells are too narrow for a letter" % cell)
        check_code_word(qid, pic)

    elif k == "symbols":
        per = 5
        cw = BODY / per
        for s in (pic.get("key") or []):
            if width("= %s" % s.get("letter", ""), 15) > cw - 26:
                bad(qid, "key entry for %r does not fit" % s.get("letter"))
        word = pic.get("word") or []
        if word:
            total = len(word) * 46 + (len(word) - 1) * 8
            if total > BODY:
                bad(qid, "%d symbols need %.0fdp, card holds %d" % (len(word), total, BODY))

    elif k == "letters":
        items = pic.get("codes") or list(str(pic.get("word") or ""))
        if items:
            gap = 18 if pic.get("codes") else 8
            total = len(items) * 48 + (len(items) - 1) * gap
            if total > BODY:
                bad(qid, "%d cells need %.0fdp, card holds %d" % (len(items), total, BODY))
            for v in items:
                if width(v, 22) > 48 - 8:
                    bad(qid, "code %s does not fit its 48dp cell" % v)

    elif k == "example":
        def letters(w):
            return len(str(w)) * 34 - 4
        ex, code = (pic.get("example") or ["", ""])[:2]
        row1 = 14 + letters(ex) + 36 + letters(code)
        row2 = 14 + letters(pic.get("word") or "") + 36 + 42
        for label, w in (("example", row1), ("question", row2)):
            if w > BODY:
                bad(qid, "code %s row is %.0fdp, card holds %d" % (label, w, BODY))

    elif k == "net":
        cells = pic.get("cells") or []
        if cells:
            cols = max(c[0] for c in cells) + 1
            rows = max(c[1] for c in cells) + 1
            size = min(46, BODY / cols, 150 / rows)
            if size < 22:
                bad(qid, "a %dx%d net leaves %.0fdp squares" % (cols, rows, size))

    elif k == "roll":
        if pic.get("w", 0) * 38 > BODY - 90:
            bad(qid, "a %d-wide floor leaves no room for the dice beside it" % pic["w"])

    elif k == "turnCube":
        for t in (pic.get("steps") or []):
            if width(t, 14, 800) > BODY:
                bad(qid, "turn %r is wider than the card" % t)


def wrap_rows(lines):
    rows = 0
    for line in lines:
        cur, n = "", 1
        for w in str(line).split(" "):
            t = (cur + " " + w) if cur else w
            if width(t, 15, 700) > BODY - 28 and cur:
                n += 1
                cur = w
            else:
                cur = t
        rows += n
    return rows


def main():
    path = os.path.join(HERE, "..", "..", "assets", "curriculum", "reasoning.json")
    d = json.load(open(path, encoding="utf-8"))
    n = 0
    for s in d["sections"]:
        for u in s["units"]:
            for st in u["stops"]:
                for i, q in enumerate(st["questions"]):
                    qid = "%s#%d %s" % (st["id"], i, q["shape"])
                    check_options(qid, q)
                    check_pic(qid, q)
                    n += 1
    if fails:
        seen = len(set(f.split(":")[0] for f in fails))
        print("%d of %d questions do not fit:" % (seen, n))
        for f in fails[:40]:
            print("  " + f)
        if len(fails) > 40:
            print("  ... and %d more" % (len(fails) - 40))
        sys.exit(1)
    print("OK  (%d questions measured with real Nunito against the 360dp card;"
          " solids scale to fit and are checked by eye)" % n)


if __name__ == "__main__":
    main()
