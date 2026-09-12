# -*- coding: utf-8 -*-
"""Authoring kit for Puzzles & Logic — the band b skill, ages 7-8.

Same discipline as numkit.py and kit.py: where an answer follows from the
picture it is COMPUTED here, never typed beside it. Over 324 questions a typed
answer is a coin flip that only lands wrong once, and when it does a child is
told their correct answer is wrong with no way to argue.

Three rules this skill is built on, beyond that one.

EVERY QUESTION IS A PICTURE. The gate has no text-option question in it by
design: CoderGate deleted its old "truth" shape because it "drew a condition in
mid-air beside a list of facts", and a child cannot look at a condition. So band
b asks nothing in words that it cannot also show. "True or false" is a YES tray
and a NO tray with shapes to sort into them, not a sentence.

NOTHING HERE NEEDS READING FLUENCY. Band b is seven and eight, and Nupo ships
in India where many of those children are learning in their second or third
language. A puzzle that is really a reading test fails the wrong child. That is
why the shift ciphers and decode-a-word puzzles in the original spine are not
here: they test the alphabet, not reasoning.

SIX SECONDS. The card sits over the app a child actually wanted to open. A
question that needs a paragraph read, or two separate ideas held at once, is the
wrong question for this surface however good it would be on paper.
"""

# The vocabulary the existing views already draw. Staying inside it is what lets
# band b reuse PlayViews, SortViews and the option rows unchanged.
STAR, HEART, CIRCLE, SQUARE = "star", "heart", "circle", "square"
TRIANGLE, DIAMOND, HEXAGON, FLOWER = "triangle", "diamond", "hexagon", "flower"

PRIMARY, ACCENT = "primary", "accent"

SHAPES = [STAR, HEART, CIRCLE, SQUARE, TRIANGLE, DIAMOND, HEXAGON, FLOWER]


def cell(kind, color=PRIMARY, rotation=0):
    return {"kind": kind, "color": color, "rotation": rotation}


def _same(a, b):
    return ((a["kind"], a["color"], a.get("rotation", 0), a.get("n", 1),
             a.get("size", 1)) ==
            (b["kind"], b["color"], b.get("rotation", 0), b.get("n", 1),
             b.get("size", 1)))


def _q(shape, prompt, hint, pic, answer, **extra):
    q = {"shape": shape, "prompt": prompt, "hint": hint, "pic": pic,
         "answer": answer}
    q.update(extra)
    return q


def near(n, lo=0, hi=99, count=4):
    """Four numbers around [n]: the answer and the near misses.

    Identical in spirit to numkit.near. Off-by-one is the mistake a child of
    this age actually makes, so the wrong options sit either side of the answer.
    Scattered wrong numbers can be eliminated without doing the puzzle, which
    makes the question free.
    """
    out = {n}
    step = 1
    while len(out) < count:
        for cand in (n - step, n + step):
            if lo <= cand <= hi and len(out) < count:
                out.add(cand)
        step += 1
        if step > 60:
            break
    return sorted(out)


def _one_match(options, want, what):
    """Index of the single option equal to [want], or raise.

    Every drawn-option question in this file goes through here. Two matching
    options is a question with two right answers, and none is a question with no
    way forward; both have shipped in this repo before and both are caught here
    rather than by a child.
    """
    idx = [i for i, o in enumerate(options) if _same(o, want)]
    if len(idx) != 1:
        raise ValueError(f"{what}: {len(idx)} of {len(options)} options match "
                         f"the answer, need exactly 1")
    return idx[0]


# ============================================================ section 1: patterns

def pattern(prompt, cells, gap_at, options, hint=None):
    """A run with one cell hidden. Which option fills it is computed.

    Mirrors numkit.pattern exactly so PlayViews.PatternStripView draws it with
    no change. Band b's strips are longer and vary two properties at once —
    band a already covers ABAB, and a seven year old meeting it again would
    learn the screen rather than the idea.
    """
    want = cells[gap_at]
    idx = _one_match(options, want, "pattern gap")
    return _q("pattern", prompt, hint or "Say the pattern out loud as you point.",
              {"kind": "pattern", "cells": cells, "gapAt": gap_at},
              {"type": "int", "value": idx}, optionCells=options)


def repeat_strip(unit, times, extra=0):
    """[unit] laid end to end, so the strip is a repeat by construction.

    Building the strip from its repeating unit rather than writing out the cells
    means a strip can never accidentally not be a pattern — which is the one way
    a "what comes next" question can have no defensible answer at all.
    """
    out = []
    while len(out) < times * len(unit) + extra:
        out.append(unit[len(out) % len(unit)])
    return out


def grow_strip(start, step, count):
    """Counts that grow by a fixed step: 1, 3, 5, 7 drawn as groups."""
    return [start + step * i for i in range(count)]


def skip_line(prompt, to, start, step, hops, hint=None):
    """Hops of the same size along a number line.

    The one place in band b where something genuinely happens over time, which
    is why it is also the only unit whose teach cards animate.
    """
    end = start + step * hops
    if end > to:
        raise ValueError(f"skip line lands on {end}, past the end of the line ({to})")
    if end < 0:
        raise ValueError(f"skip line lands on {end}, before the start of the line")
    return _q("numberLine", prompt,
              hint or f"Every hop moves {abs(step)}. Count them as they land.",
              {"kind": "numberLine", "from": 0, "to": to, "labelEvery": 5,
               "hopFrom": start, "marker": start, "step": step, "hops": hops},
              {"type": "int", "value": end})


def count_objects(prompt, n, glyph=STAR, hint=None):
    """How many, with the answer taken from the number actually drawn."""
    return _q("countObjects", prompt, hint or "Point at each one as you count it.",
              {"kind": "count", "n": n, "glyph": glyph},
              {"type": "int", "value": n}, choices=near(n, 0, 20))


def array(prompt, rows, cols, glyph=CIRCLE, hint=None):
    """Rows and columns — a growing pattern seen all at once."""
    n = rows * cols
    return _q("array", prompt, hint or "Count one row, then count the rows.",
              {"kind": "array", "rows": rows, "cols": cols, "glyph": glyph},
              {"type": "int", "value": n}, choices=near(n, 0, 60))


# ============================================================ section 2: rules

def odd_one_out(prompt, cells, hint=None):
    """Four things, one different. Which one is worked out, not declared.

    Mirrors numkit.odd_one_out, but compares on count and size too, because band
    b's odd-one-out is not always about shape or colour — that is the "why" the
    unit is named for. If the row does not have exactly one outlier on exactly
    one property it is not a fair question and this refuses it.
    """
    def sig(c):
        return (c["kind"], c["color"], c.get("rotation", 0),
                c.get("n", 1), c.get("size", 1))

    counts = {}
    for c in cells:
        counts[sig(c)] = counts.get(sig(c), 0) + 1
    odd = [i for i, c in enumerate(cells) if counts[sig(c)] == 1]
    common = [k for k, n in counts.items() if n == len(cells) - 1]
    if len(odd) != 1 or len(common) != 1:
        raise ValueError(f"odd-one-out is ambiguous: {[sig(c) for c in cells]}")
    return _q("oddOneOut", prompt, hint or "What do three of them have in common?",
              {"kind": "oddOneOut", "cells": cells},
              {"type": "int", "value": odd[0]})


def sort_two(prompt, cells, rule, left_label, right_label, hint=None):
    """Two trays, and [rule] decides which tray each shape belongs in.

    [rule] is a FUNCTION, not a list of sides. Writing the sides out by hand is
    the same coin flip as typing an answer, and worse here because one wrong
    entry in eight looks exactly like seven right ones. Passing the rule means
    the sides are derived from the same sentence the child is reading.

    Returns sides as 0 = left tray, 1 = right tray.
    """
    sides = [0 if rule(c) else 1 for c in cells]
    if 0 not in sides or 1 not in sides:
        raise ValueError(f"sort puts every shape in one tray ({left_label}/"
                         f"{right_label}); nothing to decide")
    return _q("sortTwo", prompt, hint or "Check each one against the label.",
              {"kind": "sortTwo", "cells": cells,
               "leftLabel": left_label, "rightLabel": right_label},
              {"type": "ints", "value": sides})


def yes_no(prompt, cells, rule, hint=None):
    """True or false, as a picture.

    The gate has no sentence-and-two-buttons shape, on purpose. This is what
    replaces it: the claim is in the prompt, the evidence is the shapes, and the
    child sorts them into YES and NO. Same idea, but there is something to look
    at, and it takes several judgements instead of a coin flip.
    """
    return sort_two(prompt, cells, rule, "YES", "NO",
                    hint or "Check the rule against one shape at a time.")


def size_order(prompt, sizes, glyph=STAR, hint=None):
    """Tap smallest first. The order is computed, never written out."""
    if len(set(sizes)) != len(sizes):
        raise ValueError(f"two shapes are the same size ({sizes}); the order is "
                         f"not decidable")
    return _q("sizeOrder", prompt, hint or "Find the smallest one first.",
              {"kind": "sizeOrder", "sizes": list(sizes), "glyph": glyph},
              {"type": "ints",
               "value": sorted(range(len(sizes)), key=lambda i: sizes[i])})


# ============================================================ section 3: codes

def item(kind, color=PRIMARY, rotation=0, n=1, size=1):
    """A cell that can also carry a count and a size.

    Analogies need more relations than colour and rotation to be worth asking —
    "one becomes three" and "small becomes big" are relations a seven year old
    can see and name, and neither fits in the plain cell. AnalogyView is new, so
    it can draw these; nothing older is asked to.
    """
    c = cell(kind, color, rotation)
    c["n"] = n
    c["size"] = size
    return c


# The relations an analogy may use. Each is a function from item to item, so the
# fourth term is COMPUTED by applying to C exactly what A -> B did.
def rel_colour(it):
    out = dict(it); out["color"] = ACCENT if it["color"] == PRIMARY else PRIMARY
    return out


def rel_count(mult):
    def f(it):
        out = dict(it); out["n"] = it.get("n", 1) * mult
        return out
    return f


def rel_bigger(it):
    out = dict(it); out["size"] = it.get("size", 1) + 1
    return out


def rel_smaller(it):
    out = dict(it); out["size"] = max(1, it.get("size", 1) - 1)
    return out


def rel_turn(it):
    out = dict(it); out["rotation"] = (it.get("rotation", 0) + 90) % 360
    return out


def analogy(prompt, a, c, rel, options, hint=None):
    """A is to B as C is to what.

    B is computed by applying [rel] to A, and the answer by applying the SAME
    [rel] to C. That is the whole reason this helper exists: an analogy whose
    two halves do not perform the same transformation is not an analogy, and
    written out by hand that is invisible until a child meets it.
    """
    b = rel(a)
    want = rel(c)
    if _same(a, b):
        raise ValueError("analogy relation changes nothing; A and B are identical")
    idx = _one_match(options, want, "analogy")
    return _q("analogy", prompt, hint or "What changed from the first to the second?",
              {"kind": "analogy", "a": a, "b": b, "c": c},
              {"type": "int", "value": idx}, optionCells=options)


def code_read(prompt, key, row, hint=None):
    """A key of symbol -> number, and a row of symbols to add up.

    [key] is a list of (shape, value). The answer is the row's total, computed
    from the key, so the arithmetic is done once by the machine rather than
    twice by a person.

    The answer is a number, which the gate already renders as four tappable
    options — so this needs a new drawing but no new answer control.
    """
    table = {k: v for k, v in key}
    missing = [s for s in row if s not in table]
    if missing:
        raise ValueError(f"row uses {missing} which the key does not define")
    total = sum(table[s] for s in row)
    return _q("codeRead", prompt, hint or "Read the key first, then the row.",
              {"kind": "code", "key": [{"glyph": k, "n": v} for k, v in key],
               "row": list(row)},
              {"type": "int", "value": total}, choices=near(total, 0, 40))


def code_pick(prompt, key, row, gap_at, total, options, hint=None):
    """The same key, but one symbol in the row is missing and the total is given.

    Two steps instead of one: add what is there, take it from the total, then
    find the symbol worth the difference. The missing value and the matching
    option are both computed, and a difference no symbol can supply raises here
    rather than trapping a child on a question with no answer.
    """
    table = {k: v for k, v in key}
    known = [s for i, s in enumerate(row) if i != gap_at]
    missing_syms = [s for s in known if s not in table]
    if missing_syms:
        raise ValueError(f"row uses {missing_syms} which the key does not define")
    need = total - sum(table[s] for s in known)
    want = [k for k, v in key if v == need]
    if len(want) != 1:
        raise ValueError(f"the gap needs a symbol worth {need}; the key has "
                         f"{len(want)} of those")
    idx = _one_match([cell(o) for o in options], cell(want[0]), "code gap")
    return _q("codePick", prompt,
              hint or "Add what you can see, then find what is left.",
              {"kind": "code", "key": [{"glyph": k, "n": v} for k, v in key],
               "row": list(row), "gapAt": gap_at, "total": total},
              {"type": "int", "value": idx},
              optionCells=[cell(o) for o in options])
