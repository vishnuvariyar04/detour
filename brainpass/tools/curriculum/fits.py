# -*- coding: utf-8 -*-
"""Measures every program row with the real font and fails if it will not fit.

Row height does not change the width available, so the compact listings used
for non-tappable programs are measured the same way.

Text clipping is invisible to a simulator and easy to miss on a phone: it only
shows on the one question with the longest word, in the one layout that is
narrowest. Measuring the actual glyphs against the actual column width catches
all of it at author time.

Mirrors the geometry in BlockViews.ProgramListView.onDraw and CoderGate:
  gutter 17dp for the row number, indent 9dp per nesting level, text starts
  31dp into the box, 8dp of breathing room at the right.
"""
import json, os, sys
from PIL import ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
FONT = os.path.join(HERE, "..", "..", "assets", "fonts", "Nunito-ExtraBold.ttf")

DENSITY = 4          # measure in a big unit then scale; dp are floats on device
GUTTER, INDENT, TEXT_X, PAD = 17, 9, 31, 8

# The two places a listing is drawn, in dp of usable width.
SIDE_BY_SIDE = 134           # beside a board
FULL_WIDTH = 360 - 40        # screen minus the body's padding
HALF_WIDTH = (360 - 40 - 12) // 2   # one column of a side-by-side teach demo


def word(tok):
    """Mirrors Blocks.word()."""
    if tok == "up": return "UP"
    if tok == "down": return "DOWN"
    if tok == "left": return "LEFT"
    if tok == "right": return "RIGHT"
    if tok == "pick": return "PICK UP"
    if tok == "open": return "OPEN"
    if tok == "end": return "END"
    if tok == "else": return "OR ELSE"
    if tok == "?": return "?"
    if tok.startswith("repeat:"): return "DO %s TIMES" % tok.split(":")[1]
    if tok.startswith("if:"): return "IF " + sensor(tok.split(":", 1)[1])
    if tok.startswith("set:") or tok.startswith("add:"):
        p = tok.split(":")
        if len(p) == 3:
            n = int(p[2])
            if p[0] == "set": return "SET %s = %s" % (p[1], p[2])
            if n < 0: return "TAKE %d FROM %s" % (-n, p[1])
            return "ADD %d TO %s" % (n, p[1])
    return tok.upper()


def sensor(c):
    if c.startswith("not-"): return "NO " + sensor(c[4:])
    if c == "star": return "ON A STAR"
    if c == "key": return "HOLDING KEY"
    if c == "door": return "AT THE DOOR"
    if c.startswith("wall-"): return "WALL " + c.split("-", 1)[1].upper()
    return c.upper()


def is_scaffold(t):
    return t.startswith("repeat:") or t.startswith("if:") or t in ("end", "else")


def size_for(text, scaffold):
    """Mirrors Blocks.paint()'s size rule."""
    if scaffold:
        return 11.5 if len(text) > 11 else 13.5
    return 11.5 if len(text) > 12 else 13.5


def depths(prog):
    d, out = 0, []
    for t in prog:
        if t == "end":
            d = max(0, d - 1); out.append(d)
        elif t == "else":
            out.append(max(0, d - 1))
        elif t.startswith("repeat:") or t.startswith("if:"):
            out.append(d); d += 1
        else:
            out.append(d)
    return out


_cache = {}
def text_w(text, size_dp):
    key = round(size_dp, 2)
    if key not in _cache:
        _cache[key] = ImageFont.truetype(FONT, int(round(size_dp * DENSITY)))
    f = _cache[key]
    return f.getlength(text) / DENSITY


FAILS = []


def check_program(where, prog, col_dp):
    for t, d in zip(prog, depths(prog)):
        txt = word(t)
        sc = is_scaffold(t)
        w = text_w(txt, size_for(txt, sc))
        box_left = GUTTER + d * INDENT
        if sc:
            avail = (col_dp - box_left) - PAD * 2      # centred in the box
        else:
            avail = col_dp - box_left - TEXT_X - PAD   # left-aligned after the glyph
        if w > avail:
            FAILS.append(f"{where}: \"{txt}\" needs {w:.0f}dp, has {avail:.0f}dp "
                         f"(depth {d}, column {col_dp}dp)")


def main():
    path = os.path.join(HERE, "..", "..", "assets", "curriculum",
                        "think_like_a_coder.json")
    d = json.load(open(path, encoding="utf-8"))
    n = 0
    for sec in d["sections"]:
        for u in sec["units"]:
            for st in u["stops"]:
                if not st["authored"]: continue
                t = st.get("teach") or {}
                tb = t.get("board")
                if tb and tb.get("program"):
                    check_program(f"{st['id']} teach", tb["program"], FULL_WIDTH); n += 1
                cmp = t.get("compare")
                if cmp:
                    for k in ("a", "b"):
                        check_program(f"{st['id']} demo {k}", cmp[k], HALF_WIDTH); n += 1
                for i, q in enumerate(st["questions"]):
                    qid = f"{st['id']}#{i}"
                    v = q.get("visual") or {}
                    prog = v.get("program")
                    if prog:
                        # A big board stacks the listing full width; otherwise
                        # it sits in the narrow column beside the board.
                        wide = v.get("w", 5) >= 6 or v.get("h", 5) >= 6
                        listing_only = q["shape"] == "count" and len(prog) > 4
                        col = FULL_WIDTH if (wide or listing_only or v.get("vars")) \
                              else SIDE_BY_SIDE
                        check_program(qid, prog, col); n += 1
                    for oi, o in enumerate(q.get("options") or []):
                        # Option cards lay chips out horizontally, not as rows.
                        pass
    print(f"measured {n} listings")
    for f in FAILS: print("  FAIL", f)
    print("OK" if not FAILS else f"{len(FAILS)} row(s) will clip")
    return 1 if FAILS else 0


if __name__ == "__main__":
    sys.exit(main())
