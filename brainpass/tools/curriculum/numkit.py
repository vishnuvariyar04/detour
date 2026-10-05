# -*- coding: utf-8 -*-
"""Authoring kit for Number Sense — the ages 5-8 skill.

Same discipline as the coder kit: where an answer follows from the picture, it
is COMPUTED here rather than typed. "Seven stars, and the answer is seven" is
the kind of thing that is obviously right until the fortieth time, when a
mistyped 8 tells a child their correct answer is wrong.

The distractors matter as much as the answers. A five year old counting seven
things gets six or eight, never eleven, so the wrong numbers offered are the
mistakes children actually make: off by one, the two parts unadded, the count of
the wrong colour. Random wrong answers can be eliminated without doing the work.
"""

STAR, HEART, CIRCLE, SQUARE = "star", "heart", "circle", "square"
TRIANGLE, DIAMOND, HEXAGON, FLOWER = "triangle", "diamond", "hexagon", "flower"

PRIMARY, ACCENT = "primary", "accent"


def cell(kind, color=PRIMARY, rotation=0):
    return {"kind": kind, "color": color, "rotation": rotation}


def _q(shape, prompt, hint, pic, answer, **extra):
    q = {"shape": shape, "prompt": prompt, "hint": hint, "pic": pic,
         "answer": answer}
    q.update(extra)
    return q


def near(n, lo=0, hi=99, count=4):
    """Four numbers around [n]: the answer plus the near misses.

    Off-by-one is the mistake, so the choices sit either side of the answer
    rather than being scattered. They are returned in ascending order, so the
    position of the answer is not a tell.
    """
    out = {n}
    step = 1
    while len(out) < count:
        for cand in (n - step, n + step):
            if lo <= cand <= hi and len(out) < count:
                out.add(cand)
        step += 1
        if step > 40:
            break
    return sorted(out)


# ---------------------------------------------------------------- counting

def _plural(glyph):
    return {"star": "stars", "heart": "hearts", "circle": "circles",
            "square": "squares", "triangle": "triangles",
            "diamond": "diamonds", "hexagon": "hexagons",
            "flower": "flowers"}.get(glyph, glyph + "s")


# Hints are written for the question they sit under: the first step a child
# can take, in the words of that picture, and never the answer itself. A hint
# shared by every question of a kind ended up wrong for some of them ("the
# heavier side goes down" under two level pans).

def count_objects(prompt, n, glyph=STAR, hint=None):
    """How many things. The answer is the number drawn — never typed twice."""
    return _q("countObjects", prompt,
              hint or "Touch each one once. Say the numbers as you go.",
              {"kind": "count", "n": n, "glyph": glyph},
              {"type": "int", "value": n}, choices=near(n, 0, 20))


def count_colour(prompt, n, split, yellow=True, glyph=STAR, hint=None):
    """How many of ONE colour.

    Counters from [split] on are yellow, so the two answers are split and
    n - split. Asking for one colour and answering with the total was a bug the
    checker caught; computing both here means it cannot come back.
    """
    want = (n - split) if yellow else split
    return _q("countObjects", prompt,
              hint or (f"Count only the {'yellow' if yellow else 'purple'} ones. "
                       "Skip the others."),
              {"kind": "count", "n": n, "glyph": glyph, "splitAt": split},
              {"type": "int", "value": want}, choices=near(want, 0, 20))


def _frame_hint(filled, second):
    if second is not None:
        return "The first frame is full. That is 10. Count on from 10."
    if filled == 10:
        return "Both rows are full. Each row has 5."
    if filled > 5:
        return "The top row is full. That is 5. Count on from 5."
    return "Touch each one once. Say the numbers as you go."


def ten_frame(prompt, filled, second=None, glyph=CIRCLE, hint=None):
    """A ten frame, or two for a teen number. The answer is the total."""
    pic = {"kind": "tenFrame", "filled": filled, "glyph": glyph}
    total = filled
    if second is not None:
        pic["second"] = second
        total = filled + second
    return _q("tenFrame", prompt,
              hint or _frame_hint(filled, second),
              pic, {"type": "int", "value": total}, choices=near(total, 0, 20))


def frame_gap(prompt, filled, glyph=CIRCLE, hint=None):
    """How many empty cells are left. The gap is what a ten frame is FOR."""
    gap = 10 - filled
    return _q("tenFrame", prompt,
              hint or "A full frame has 10. Count the empty squares.",
              {"kind": "tenFrame", "filled": filled, "glyph": glyph},
              {"type": "int", "value": gap}, choices=near(gap, 0, 10))


def dice(prompt, faces, hint=None):
    """One face, or two for a domino. The answer is the total."""
    total = sum(faces)
    return _q("dice", prompt, hint or (
        "Count the dots on one dice. Then count on with the other."
        if len(faces) > 1 else "Touch each dot once. Say the numbers as you go."),
              {"kind": "dice", "faces": list(faces)},
              {"type": "int", "value": total}, choices=near(total, 0, 20))


def rods(prompt, value, hint=None):
    """Tens and ones. The answer is the number the blocks show."""
    # Swapping the tens and ones is the classic slip, so it is offered — but
    # only when it is actually a different number, and the pad always shows four.
    swapped = int(str(value).zfill(2)[::-1]) if value >= 10 else -1
    picks = [value, value + 1, value - 1]
    if swapped > 0 and swapped != value:
        picks.append(swapped)
    out = []
    for c in picks:
        if c >= 0 and c not in out:
            out.append(c)
    step = 2
    while len(out) < 4:
        for cand in (value + step, value - step):
            if cand >= 0 and cand not in out and len(out) < 4:
                out.append(cand)
        step += 1
    return _q("rods", prompt, hint or (
        "Count the tall sticks: 10, 20, 30. Then count on the small ones."
        if value >= 10 else "Count the small blocks one by one."),
              {"kind": "rods", "n": value},
              {"type": "int", "value": value}, choices=sorted(out))


# ---------------------------------------------------------------- parts

def bond(prompt, whole, left, gap="right", hint=None):
    """A number bond with one node blank. The blank is computed, not typed."""
    right = whole - left
    pic = {"kind": "bond", "gap": gap}
    if gap == "right":
        pic.update({"whole": whole, "left": left})
        ans = right
    elif gap == "left":
        pic.update({"whole": whole, "right": right})
        ans = left
    else:
        pic.update({"left": left, "right": right})
        ans = whole
    if gap == "whole":
        default = f"Start at {left}. Count on {right} more."
    else:
        known = left if gap == "right" else right
        default = f"Start at {known}. Count up to {whole}. How many steps?"
    return _q("bond", prompt, hint or default,
              pic, {"type": "int", "value": ans}, choices=near(ans, 0, 20))


def number_line(prompt, frm, to, start, steps, hint=None, label_every=1):
    """Counting on. The marker hops from [start], and the answer is where it lands."""
    end = start + steps
    return _q("numberLine", prompt,
              hint or f"Put your finger on {start}. Hop {steps} times. Say each hop.",
              {"kind": "numberLine", "from": frm, "to": to,
               "labelEvery": label_every, "hopFrom": start, "marker": start},
              {"type": "int", "value": end})


def balance(prompt, left, right, glyph=STAR, hint=None):
    """Which side is heavier. 0 = left, 1 = right, 2 = the same."""
    ans = 0 if left > right else (1 if right > left else 2)
    return _q("balance", prompt, hint or (
        "Count each pan. More goes down. The same means level."),
              {"kind": "balance", "leftCount": left, "rightCount": right,
               "glyph": glyph},
              {"type": "int", "value": ans})


def fraction(prompt, slices, shaded, other=None, hint=None, options=None):
    """One circle with options, or two circles where the child picks the bigger."""
    pic = {"kind": "fraction", "slices": slices, "shaded": shaded}
    if other is not None:
        os_, osh = other
        pic.update({"otherSlices": os_, "otherShaded": osh})
        ans = 0 if shaded / slices > osh / os_ else 1
        return _q("fraction", prompt,
                  hint or "Look at how much of each circle is coloured in.",
                  pic, {"type": "int", "value": ans})
    return _q("fraction", prompt, hint or "Count the coloured slices.",
              pic, {"type": "int", "value": options.index(True)},
              optionsText=[o if isinstance(o, str) else "" for o in options])


# ---------------------------------------------------------------- looking

def shape_hunt(prompt, figure, target, hint=None):
    """Tap every drawn piece of one kind.

    The geometry travels with the question so the app, the checker and the
    review page all draw the same figure — it used to be written out three
    times and drifted.
    """
    import figures as _FG
    return _q("shapeHunt", prompt,
              hint or f"Look for every {target}, big and small.",
              {"kind": "shapeHunt", "figure": figure, "target": target,
               "parts": _FG.parts_json(figure)},
              {"type": "kind", "value": target})


def _same(a, b):
    return (a["kind"], a["color"], a.get("rotation", 0)) ==            (b["kind"], b["color"], b.get("rotation", 0))


def pattern(prompt, cells, gap_at, options, hint=None):
    """A run with a gap. The options are drawn, not written.

    Which option is right is worked out from the strip, not passed in: hand
    indices were wrong in four places, and a pattern question that marks the
    right shape wrong is the worst kind of bug for a child who cannot yet read
    an explanation.
    """
    want = cells[gap_at]
    idx = [i for i, o in enumerate(options) if _same(o, want)]
    if len(idx) != 1:
        raise ValueError(f"pattern gap matches {len(idx)} options, need exactly 1")
    return _q("pattern", prompt,
              hint or "Say each shape out loud. Listen for what repeats.",
              {"kind": "pattern", "cells": cells, "gapAt": gap_at},
              {"type": "int", "value": idx[0]}, optionCells=options)


def odd_one_out(prompt, cells, hint=None):
    """Four things, one different. Which one is worked out, not declared.

    The odd one is whichever cell disagrees with the majority on shape or
    colour. If that is not exactly one cell the row is not a fair question, and
    saying so here beats shipping a puzzle with two defensible answers.
    """
    def sig(c):
        return (c["kind"], c["color"], c.get("rotation", 0))

    counts = {}
    for c in cells:
        counts[sig(c)] = counts.get(sig(c), 0) + 1
    odd = [i for i, c in enumerate(cells) if counts[sig(c)] == 1]
    common = [k for k, n in counts.items() if n == len(cells) - 1]
    if len(odd) != 1 or len(common) != 1:
        raise ValueError(f"odd-one-out is ambiguous: {[sig(c) for c in cells]}")
    o = cells[odd[0]]
    other = cells[(odd[0] + 1) % len(cells)]
    if o["kind"] != other["kind"]:
        default = "Look at the shapes. Which one is not like the others?"
    elif o["color"] != other["color"]:
        default = "Look at the colours. Which one is not like the others?"
    else:
        default = "Look at which way each one points."
    return _q("oddOneOut", prompt, hint or default,
              {"kind": "oddOneOut", "cells": cells},
              {"type": "int", "value": odd[0]})


def sort_two(prompt, cells, sides, left_label, right_label, hint=None):
    """Two trays. [sides] is which tray each item belongs in: 0 left, 1 right."""
    return _q("sortTwo", prompt,
              hint or f"Look at one shape at a time. Is it {left_label.lower()}?",
              {"kind": "sortTwo", "cells": cells,
               "leftLabel": left_label, "rightLabel": right_label},
              {"type": "ints", "value": list(sides)})


def size_order(prompt, sizes, glyph=STAR, hint=None):
    """Tap smallest first. The answer is the sorted order, computed."""
    return _q("sizeOrder", prompt,
              hint or "Find the smallest one first. Then the next one.",
              {"kind": "sizeOrder", "sizes": list(sizes), "glyph": glyph},
              {"type": "ints",
               "value": sorted(range(len(sizes)), key=lambda i: sizes[i])})


def mirror(prompt, given, cols=6, rows=5, hint=None):
    """Fold the picture. The answer is the reflection, computed."""
    return _q("mirror", prompt,
              hint or "Each square has a twin just as far from the line.",
              {"kind": "mirror", "cols": cols, "rows": rows,
               "given": [list(g) for g in given]},
              {"type": "cells",
               "value": [[cols - 1 - c, r] for (c, r) in given]})


# ================================================================ heavier
#
# Everything below is for the rebuilt skill: multiplication, sharing, applied
# comparison and real fraction work. No money anywhere — the app ships
# worldwide, and a coin a child has never seen teaches nothing.

import figures as _F


def array(prompt, rows, cols, glyph=CIRCLE, hint=None):
    """Rows and columns. The picture IS the times fact.

    A child who counts 4 rows of 6 one by one still gets 24; one who sees the
    rows stops counting. Both are progress, which is why the array is the
    picture multiplication is taught from.
    """
    n = rows * cols
    return _q("array", prompt,
              hint or f"Count one row. It has {cols}. Count on {cols} for each row.",
              {"kind": "array", "rows": rows, "cols": cols, "glyph": glyph},
              {"type": "int", "value": n}, choices=near(n, 0, 120))


def groups(prompt, n, per, glyph=STAR, hint=None, share=False):
    """[n] groups with [per] in each.

    Read forwards it is multiplication; read backwards — "these 12 shared into
    3 groups" — it is division, and it is the same picture, which is the whole
    point of teaching them together.
    """
    total = n * per
    ans = per if share else total
    return _q("groups", prompt,
              hint or (f"Share them into {n} bags, one at a time." if share
                       else f"Count one bag. It has {per}. Count on {per} for each bag."),
              {"kind": "groups", "groups": n, "per": per, "glyph": glyph,
               "share": share},
              {"type": "int", "value": ans}, choices=near(ans, 0, 120))


def skip_line(prompt, to, start, step, hops, hint=None):
    """Hops of the same size along the line: skip counting, then tables."""
    end = start + step * hops
    return _q("numberLine", prompt,
              hint or f"Start at {start}. Each hop jumps {step}. Count on {step} each time.",
              {"kind": "numberLine", "from": 0, "to": to, "labelEvery": 5,
               "hopFrom": start, "marker": start, "step": step, "hops": hops},
              {"type": "int", "value": end})


def bar_model(prompt, a, b, ask="more", hint=None):
    """Two bars side by side: the standard picture for "how many more".

    The bars are drawn to scale, so the gap between them is the answer before
    any arithmetic happens.
    """
    ans = abs(a - b) if ask == "more" else a + b
    return _q("barModel", prompt,
              hint or ("Look at the bit of the long bar that sticks out."
                       if ask == "more" else f"Start at {a}. Count on {b} more."),
              {"kind": "barModel", "a": a, "b": b, "ask": ask},
              {"type": "int", "value": ans}, choices=near(ans, 0, 120))


def fraction_wall(prompt, rows, ask="biggest", hint=None):
    """Strips of the same length, cut into different numbers of pieces.

    "Which strip reaches the same place as the top one" was a weak question:
    vague to read, and answerable by eyeballing a coloured edge without
    thinking about fractions at all.

    These two are worth asking instead:

      biggest - the more pieces you cut something into, the SMALLER each piece
                gets. Every child first believes the opposite, because eight is
                a bigger number than four, and the wall is the picture that
                settles it.
      same    - two different cuts can colour the same amount.

    [rows] is a list of (pieces, coloured) for each strip.
    """
    if ask == "biggest":
        sizes = [r[0] for r in rows]
        fewest = min(sizes)
        if sizes.count(fewest) != 1:
            raise ValueError("two strips tie for the biggest pieces")
        ans = sizes.index(fewest)
        default_hint = "Fewer pieces means each piece is bigger."
    else:
        top = rows[0][1] / rows[0][0]
        matches = [i for i in range(1, len(rows))
                   if abs(rows[i][1] / rows[i][0] - top) < 1e-9]
        if len(matches) != 1:
            raise ValueError(f"{len(matches)} strips match the top one")
        ans = matches[0]
        default_hint = "Where does the colour stop on the top strip? Find the same."
    return _q("fractionWall", prompt, hint or default_hint,
              {"kind": "fractionWall", "rows": [list(r) for r in rows],
               "ask": ask},
              {"type": "int", "value": ans})


def shape_count(prompt, figure, kind, hint=None):
    """How many of a shape are hiding in the figure — composites included.

    Harder than tapping them: a child has to notice that four small triangles
    also make one big one. The count comes from figures.py, never typed.
    """
    n = _F.counts(figure, kind)
    return _q("shapeCount", prompt,
              hint or f"Count the small {kind}s. Then look for big ones made of them.",
              {"kind": "shapeCount", "figure": figure, "target": kind,
               "parts": _F.parts_json(figure)},
              {"type": "int", "value": n}, choices=near(n, 0, 20))
