# -*- coding: utf-8 -*-
"""Measures every Puzzles and Logic question with the real font and fails if it
will not fit on the phone.

Clipped text is invisible to every other check here. The simulator sees a
correct question, the grader works the answer out correctly, and the child sees
"Tap the shape just left of the hea". It only ever shows up on the ONE question
with the longest word in the narrowest layout, which is exactly the question no
one thinks to look at.

So this measures actual Nunito glyphs against the actual widths in
PuzzleViews.kt and CoderGate.kt. When one of those changes, this must change
with it, or it is measuring a screen that no longer exists.

Geometry mirrored:
  CoderGate.body padding 20dp each side       -> 320dp usable
  textOptions   full width, 16sp, 14dp inset each side
  numberChoices four across, 10dp gaps, 22sp
  cellOptions   four across, 10dp gaps (glyphs, nothing to clip)
  Draw.tokenBox fitSize(label, w-8, 24, min 12)
  Draw.letterRow / numRow  cells 30 wide + 4 gap, starting 14 in
  series boxes  min(56, (w-gap*(n-1))/n), fitSize(label, box-6, 20, min 11)
  queue names   fitSize(name, w/n - 2, 12, min 8)
  shelf tiles   min(58, (w-8*(n-1))/n)
"""
import json, os, sys
from PIL import ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FONTS = os.path.join(HERE, "..", "..", "assets", "fonts")
SCALE = 8                      # measure big, divide down: dp are floats on device

_cache = {}


def font(name, size_dp):
    key = (name, round(size_dp * SCALE))
    if key not in _cache:
        _cache[key] = ImageFont.truetype(
            os.path.join(FONTS, name), int(round(size_dp * SCALE)))
    return _cache[key]


def width(s, size_dp, weight=900):
    """Width of [s] in dp, in the weight the view actually draws it."""
    name = {900: "Nunito-Black.ttf", 800: "Nunito-ExtraBold.ttf",
            700: "Nunito-Bold.ttf", 600: "Nunito-SemiBold.ttf"}[weight]
    return font(name, size_dp).getlength(str(s)) / SCALE


def fit_size(s, max_w, size, lo, weight=900):
    """Mirrors Draw.fitSize: shrink to fit, but never below [lo]."""
    z = size
    while z > lo and width(s, z, weight) > max_w:
        z -= 1
    return z


BODY = 360 - 40          # the card minus CoderGate's body padding
fails = []


def bad(qid, what):
    fails.append("%s: %s" % (qid, what))


def check_options(qid, q):
    """The answer row, which is where a long word actually gets cut."""
    if q["answer"]["type"] == "number":
        # four numbers across; the button does NOT shrink its text
        cell = (BODY - 30) / 4
        for n in q.get("choices", []):
            if width(n, 22, 800) > cell - 12:
                bad(qid, "number %s too wide for a %.0fdp button" % (n, cell))
    elif q.get("optionsText"):
        for t in q["optionsText"]:
            # PushButton draws the label at a fixed size and does not wrap
            if width(t, 16, 800) > BODY - 28:
                bad(qid, "option %r is %.0fdp wide, button holds %.0f"
                    % (t, width(t, 16, 800), BODY - 28))


def check_pic(qid, q):
    pic = q.get("pic") or {}
    k = pic.get("kind")

    if k == "series":
        terms = pic.get("terms") or []
        n = max(len(terms), 1)
        box = min(56, (BODY - 6 * (n - 1)) / n)
        for v in terms:
            lab = "?" if v is None else str(v)
            if fit_size(lab, box - 6, 20, 11) == 11 and width(lab, 11) > box - 6:
                bad(qid, "series term %r does not fit a %.0fdp box" % (lab, box))

    elif k == "equation":
        for v in (pic.get("left"), pic.get("right"), pic.get("result")):
            if v is None:
                continue
            if fit_size(v, 58 - 8, 24, 12) == 12 and width(v, 12) > 50:
                bad(qid, "equation number %s does not fit its box" % v)

    elif k == "line":
        n = max(pic.get("n", 1), 1)
        sp = BODY / n
        for nm in (pic.get("names") or []):
            if fit_size(nm, sp - 2, 12, 8) == 8 and width(nm, 8, 800) > sp - 2:
                bad(qid, "queue name %r needs %.0fdp, has %.0f"
                    % (nm, width(nm, 8, 800), sp - 2))
        who = pic.get("name") or ""
        if who and width(who, 13) > sp * 2:
            bad(qid, "marked name %r may collide with its neighbours" % who)

    elif k == "shelf":
        n = max(len(pic.get("items") or []), 1)
        tile = min(58, (BODY - 8 * (n - 1)) / n)
        if tile < 30:
            bad(qid, "shelf of %d leaves %.0fdp tiles" % (n, tile))

    elif k == "wordPairs":
        bw = (BODY - 80) / 2
        for pr in (pic.get("pairs") or []):
            for half in pr:
                if half is None:
                    continue
                if fit_size(half, bw - 8, 24, 12) == 12 and width(half, 12) > bw - 8:
                    bad(qid, "analogy word %r does not fit a %.0fdp box" % (half, bw))

    elif k == "numPairs":
        for pr in (pic.get("pairs") or []):
            for half in pr:
                if half is None:
                    continue
                if fit_size(half, 70 - 8, 24, 12) == 12 and width(half, 12) > 62:
                    bad(qid, "analogy number %s does not fit its box" % half)

    elif k in ("example", "numExample"):
        # Example row: 14 in, the word, an arrow, then the code.
        def letters(w):
            return len(w) * 34 - 4

        def nums(s):
            return len(str(s).split()) * 34 - 4
        ex, code = (pic.get("example") or ["", ""])[:2]
        row1 = 14 + letters(ex) + 36 + (nums(code) if k == "numExample" else letters(code))
        word = pic.get("word") or ""
        if k == "numExample" and pic.get("mode") != "encode":
            row2 = 14 + nums(word) + 36 + 42
        else:
            row2 = 14 + letters(word) + 36 + 42
        for label, w in (("example", row1), ("question", row2)):
            if w > BODY:
                bad(qid, "code %s row is %.0fdp, card holds %d" % (label, w, BODY))

    elif k == "letter":
        seq = 2 if abs(pic.get("offset", 1)) == 1 else 3
        if seq * 56 + (seq - 1) * 10 > BODY:
            bad(qid, "alphabet strip too wide")

    elif k == "bars":
        vals = pic.get("values") or [0, 0]
        if vals[0] <= 0:
            bad(qid, "top bar is %s, nothing to scale against" % vals[0])
        for nm in (pic.get("names") or []):
            if width(nm, 14, 800) > 56:
                bad(qid, "bar name %r needs %.0fdp, column is 56"
                    % (nm, width(nm, 14, 800)))

    elif k == "card":
        # The card wraps, so nothing clips; but a card that wraps to many rows
        # pushes the answer buttons off the first screen.
        rows = 0
        for line in (pic.get("lines") or []):
            words, cur, n = line.split(" "), "", 1
            for w in words:
                t = (cur + " " + w) if cur else w
                if width(t, 15, 700) > BODY - 28 and cur:
                    n += 1
                    cur = w
                else:
                    cur = t
            rows += n
        if rows > 5:
            bad(qid, "clue card wraps to %d rows" % rows)


def main():
    path = os.path.join(HERE, "..", "..", "assets", "curriculum_pending",
                        "puzzles_and_logic.json")
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
        print("%d of %d questions do not fit:" % (len(set(f.split(":")[0] for f in fails)), n))
        for f in fails[:40]:
            print("  " + f)
        if len(fails) > 40:
            print("  ... and %d more" % (len(fails) - 40))
        sys.exit(1)
    print("OK  (%d questions measured with real Nunito against the 360dp card)" % n)


if __name__ == "__main__":
    main()
