# -*- coding: utf-8 -*-
"""Which question shapes the gate can actually draw, read from the gate itself.

A stop is only put on the ladder when every question in it is one CoderGate can
draw -- `authored` in the JSON, `Curriculum.Skill.ladder` in Kotlin. Get that
wrong in the optimistic direction and a child meets a blank screen. Get it wrong
in the pessimistic direction and the ladder is empty, `session()` returns
nothing, and the skill silently serves no questions at all.

The second is what happened. Each emitter carried its own hand-written
DRAWN_TODAY set, written before the views existed; after the views were built
the sets were never updated, so both new skills shipped with all 48 stops marked
unplayable.

So there is no hand-written set any more. This reads the shape names out of
CoderGate.kt, which is the only place that decides what can be drawn. A shape
the gate does not handle cannot be marked playable here, and a shape the gate
gains becomes playable on the next emit without anyone remembering to do it.
"""
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
GATE = os.path.join(HERE, "..", "..", "android", "app", "src", "main", "kotlin",
                    "com", "brainpass", "brainpass", "CoderGate.kt")


def _block(src, name):
    """The string literals inside `val <name> = setOf( ... )`."""
    m = re.search(r"val\s+%s\s*=\s*setOf\s*\(" % re.escape(name), src)
    if not m:
        raise RuntimeError("CoderGate.kt has no `val %s = setOf(`. If the gate "
                           "was reorganised, fix this reader rather than "
                           "reintroducing a hand-written copy." % name)
    i, depth = m.end(), 1
    while i < len(src) and depth:
        if src[i] == "(":
            depth += 1
        elif src[i] == ")":
            depth -= 1
        i += 1
    return set(re.findall(r'"([^"]+)"', src[m.end():i]))


def gate_shapes(band=None):
    """Every shape CoderGate draws; with [band], only that band's set.

    The band a and band c shapes are listed here rather than parsed, because
    they are spread through the gate's `when` as individual branches rather
    than gathered into a set. They have not changed in either shipped skill and
    a change to them would be a change to a skill children are already on.
    """
    src = io.open(GATE, encoding="utf-8").read()
    if band == "b":
        return _block(src, "bandB")
    if band == "d":
        return _block(src, "bandD")
    shipped = {
        # band a, Number Sense
        "countObjects", "tenFrame", "rods", "dice", "bond", "numberLine",
        "balance", "shapeHunt", "shapeCount", "pattern", "oddOneOut", "sortTwo",
        "array", "groups", "barModel", "fractionWall", "fraction", "sizeOrder",
        "mirror",
        # band c, Think Like a Coder
        "predict", "spot", "debug", "trace", "count", "choose", "chooseText",
        "complete", "compare", "yesno", "fix", "inverse", "constrain",
    }
    return shipped | _block(src, "bandB") | _block(src, "bandD")


import io  # noqa: E402  (kept below the docstring for readability)

if __name__ == "__main__":
    for b in ("b", "d"):
        s = gate_shapes(b)
        print("band %s: %d shapes -> %s" % (b, len(s), ", ".join(sorted(s))))
