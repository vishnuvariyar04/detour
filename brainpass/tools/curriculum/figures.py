# -*- coding: utf-8 -*-
"""The shapes-inside-shapes figures, defined once.

These used to live in Kotlin, with a second copy in the checker that had to be
kept in step by hand. They now live here and are EMITTED INTO THE JSON, so the
app and the review page both draw from the same numbers and cannot drift.

Every piece is a polygon in a unit box, y counting down from the top. A piece
is named by what it actually is, and `audit()` measures each one to prove it —
the old set called four rectangles squares, which meant "tap every square" in
the house had no correct answer at all.
"""

# ---------------------------------------------------------------- helpers

def rect(x0, y0, x1, y1):
    return [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]


def tri(a, b, c):
    return [a, b, c]


def _kind_of_quad(pts):
    w = max(p[0] for p in pts) - min(p[0] for p in pts)
    h = max(p[1] for p in pts) - min(p[1] for p in pts)
    return "square" if abs(w - h) <= 0.015 else "rectangle"


# ---------------------------------------------------------------- figures
#
# EASY: few pieces, none hidden inside another.
# MEDIUM: pieces share edges, one may sit on top of another.
# HARD: a piece belongs to two shapes at once, or the outline is itself a
#       shape the child is being asked to find.

FIGURES = {
    # ---- easy ----------------------------------------------------------
    "tree": ("easy", [
        ("triangle", tri((.50, .04), (.16, .44), (.84, .44))),
        ("triangle", tri((.50, .28), (.08, .74), (.92, .74))),
        ("square",   rect(.44, .74, .56, .86)),
    ]),
    "flag": ("easy", [
        ("rectangle", rect(.30, .10, .88, .40)),
        ("rectangle", rect(.24, .10, .30, .92)),
    ]),
    "boat": ("easy", [
        ("triangle",  tri((.50, .06), (.50, .56), (.16, .56))),
        ("triangle",  tri((.56, .18), (.56, .56), (.84, .56))),
        ("rectangle", rect(.14, .62, .86, .84)),
    ]),
    "arrow": ("easy", [
        ("triangle",  tri((.90, .50), (.52, .18), (.52, .82))),
        ("rectangle", rect(.10, .40, .52, .60)),
    ]),
    "kite": ("easy", [
        ("triangle", tri((.50, .06), (.18, .40), (.82, .40))),
        ("triangle", tri((.50, .82), (.18, .40), (.82, .40))),
    ]),

    # ---- medium --------------------------------------------------------
    "house": ("medium", [
        ("triangle",  tri((.50, .06), (.06, .38), (.94, .38))),
        ("square",    rect(.20, .38, .80, .98)),          # 0.60 x 0.60
        ("rectangle", rect(.44, .68, .58, .98)),          # the door
        ("square",    rect(.28, .48, .40, .60)),          # a window
    ]),
    "rocket": ("medium", [
        ("triangle",  tri((.50, .02), (.30, .30), (.70, .30))),
        ("rectangle", rect(.30, .30, .70, .82)),
        ("triangle",  tri((.30, .58), (.30, .96), (.08, .96))),
        ("triangle",  tri((.70, .58), (.70, .96), (.92, .96))),
        ("square",    rect(.42, .40, .58, .56)),          # a porthole
    ]),
    "window4": ("medium", [
        ("square", rect(.14, .14, .50, .50)),
        ("square", rect(.50, .14, .86, .50)),
        ("square", rect(.14, .50, .50, .86)),
        ("square", rect(.50, .50, .86, .86)),
    ]),
    "cross": ("medium", [
        ("square", rect(.36, .06, .64, .34)),
        ("square", rect(.08, .34, .36, .62)),
        ("square", rect(.36, .34, .64, .62)),
        ("square", rect(.64, .34, .92, .62)),
        ("square", rect(.36, .62, .64, .90)),
    ]),
    "envelope": ("medium", [
        ("rectangle", rect(.08, .24, .92, .76)),
        ("triangle",  tri((.08, .24), (.92, .24), (.50, .56))),
    ]),
    "truck": ("medium", [
        ("rectangle", rect(.06, .36, .56, .72)),
        ("square",    rect(.56, .44, .84, .72)),
        ("square",    rect(.62, .48, .74, .60)),
        ("triangle",  tri((.06, .36), (.06, .24), (.30, .36))),
    ]),

    # ---- hard ----------------------------------------------------------
    # Four small triangles that also make one big one: the outline is the
    # fifth triangle, and it is the one children miss.
    "triangle4": ("hard", [
        ("triangle", tri((.50, .04), (.27, .50), (.73, .50))),
        ("triangle", tri((.27, .50), (.04, .96), (.50, .96))),
        ("triangle", tri((.73, .50), (.50, .96), (.96, .96))),
        ("triangle", tri((.27, .50), (.73, .50), (.50, .96))),
    ]),
    "hex6": ("hard", None),          # built at load: six slices of a hexagon
    "quilt": ("hard", [
        ("triangle", tri((.12, .12), (.50, .12), (.12, .50))),
        ("triangle", tri((.50, .12), (.50, .50), (.12, .50))),
        ("triangle", tri((.50, .12), (.88, .12), (.50, .50))),
        ("triangle", tri((.88, .12), (.88, .50), (.50, .50))),
        ("square",   rect(.12, .50, .50, .88)),
        ("square",   rect(.50, .50, .88, .88)),
    ]),
    "nested": ("hard", [
        ("square", rect(.06, .06, .94, .94)),
        ("square", rect(.20, .20, .80, .80)),
        ("square", rect(.34, .34, .66, .66)),
    ]),
    "stairs": ("hard", [
        ("square",    rect(.08, .62, .38, .92)),
        ("square",    rect(.38, .62, .68, .92)),
        ("square",    rect(.38, .32, .68, .62)),
        ("square",    rect(.68, .62, .98, .92)),
        ("square",    rect(.68, .32, .98, .62)),
        ("square",    rect(.68, .02, .98, .32)),
    ]),
    "pinwheel": ("hard", [
        ("triangle", tri((.50, .50), (.50, .08), (.92, .08))),
        ("triangle", tri((.50, .50), (.92, .50), (.92, .92))),
        ("triangle", tri((.50, .50), (.50, .92), (.08, .92))),
        ("triangle", tri((.50, .50), (.08, .50), (.08, .08))),
        ("square",   rect(.38, .38, .62, .62)),
    ]),
}


# Shapes that are not drawn as pieces but are really there, made of pieces
# side by side. "How many triangles?" on the subdivided triangle is four small
# ones AND the big one — and the big one is the answer children miss.
COMPOSITES = {
    "triangle4": [("triangle", [(.50, .04), (.04, .96), (.96, .96)])],
    "window4":   [("square",   rect(.14, .14, .86, .86))],
    "quilt":     [("square",   rect(.12, .12, .50, .50)),
                  ("square",   rect(.50, .12, .88, .50)),
                  ("rectangle", rect(.12, .12, .88, .50)),
                  ("rectangle", rect(.12, .50, .88, .88))],
    "pinwheel":  [("square",   rect(.08, .08, .92, .92))],
    "stairs":    [("square",   rect(.38, .32, .98, .92))],
    "nested":    [],
    "cross":     [],
    "hex6":      [],
}


def _hex():
    import math
    ring = []
    for i in range(6):
        a = math.radians(-90 + i * 60)
        ring.append((0.5 + 0.46 * math.cos(a), 0.5 + 0.46 * math.sin(a)))
    return [("triangle", [(0.5, 0.5), ring[i], ring[(i + 1) % 6]])
            for i in range(6)]


FIGURES["hex6"] = ("hard", _hex())


# ---------------------------------------------------------------- checks

def audit():
    """Every four-sided piece must be named what it measures as.

    The previous figure set called four rectangles squares. A child told a
    1.26 : 1 shape is a square has been taught something they will have to
    unlearn, so this is a build failure, not a warning.
    """
    problems = []
    for name, (tier, parts) in FIGURES.items():
        for kind, pts in list(parts) + list(COMPOSITES.get(name, [])):
            if len(pts) == 4:
                real = _kind_of_quad(pts)
                if kind != real:
                    w = max(p[0] for p in pts) - min(p[0] for p in pts)
                    h = max(p[1] for p in pts) - min(p[1] for p in pts)
                    problems.append(
                        f"{name}: a piece called {kind} measures "
                        f"{w:.2f} x {h:.2f} — it is a {real}")
            elif len(pts) != 3:
                problems.append(f"{name}: a piece with {len(pts)} corners")
        if tier not in ("easy", "medium", "hard"):
            problems.append(f"{name}: unknown difficulty {tier}")
    return problems


def counts(name, kind, with_composites=True):
    """How many shapes of [kind] the figure really contains."""
    n = sum(1 for k, _ in FIGURES[name][1] if k == kind)
    if with_composites:
        n += sum(1 for k, _ in COMPOSITES.get(name, []) if k == kind)
    return n


def parts_json(name):
    return [{"kind": k, "pts": [[round(x, 4), round(y, 4)] for x, y in pts]}
            for k, pts in FIGURES[name][1]]


def tier(name):
    return FIGURES[name][0]


if __name__ == "__main__":
    bad = audit()
    for b in bad:
        print("  FAIL", b)
    print(f"{len(FIGURES)} figures")
    for t in ("easy", "medium", "hard"):
        names = [n for n in FIGURES if tier(n) == t]
        print(f"  {t:7} {len(names):2}  {', '.join(sorted(names))}")
    print("OK" if not bad else f"{len(bad)} problem(s)")
