# -*- coding: utf-8 -*-
"""Builds the question wall: every question in both skills, drawn as the phone
draws it, on one scrollable page.

This exists because reviewing 648 questions on a device means 648 taps and no
way to compare stop 3.2.1 against stop 1.1.4 without walking the whole ladder
again. The wall renders the same shapes with the same measurements, so what is
on the page is what a child will see.

The renderers live in wall_template.html and mirror the Kotlin views. The data is
spliced in at build time rather than fetched, so the published page has no
network dependency and keeps working when this machine is off.
"""
import base64
import io
import json
import os
import sys
from collections import Counter

HERE = os.path.dirname(os.path.abspath(__file__))
CUR = os.path.join(HERE, "..", "..", "assets", "curriculum")
# The template is part of the repo, not of whoever's scratch directory happened
# to be live the day the wall was first built. It was a temp path for exactly
# one session, and the wall became unbuildable the moment that was cleared.
TEMPLATE = os.path.join(HERE, "wall_template.html")

# Where the built page lands. Untracked: 280KB of generated HTML whose every
# byte comes from the template and the JSON sitting next to it.
OUT = os.environ.get("NUPO_OUT", os.path.join(HERE, "..", "..", "build", "wall"))
# The fields a rendered screen needs. Anything else is authoring bookkeeping
# and would only bloat the page.
KEEP = ("shape", "prompt", "hint", "pic", "visual", "truth", "choices",
        "optionCells", "optionsText", "options", "caption", "kind",
        "criterion", "blocks", "slots", "reusable", "varName", "traceOf",
        "gapRow", "expr", "state", "answer",
        # band d's drawn answers
        "optionBits", "optionNets", "optionViews", "optionCubes", "optionShapes",
        "optionSections")

SKILLS = [("coder", "Think Like a Coder", "think_like_a_coder.json"),
          ("number", "Number Sense", "number_sense.json"),
          ("puzzles", "Puzzles & Logic", os.path.join("..", "curriculum",
                                                    "puzzles_and_logic.json")),
          # Band d is not bundled with the app yet (see rs_emit.py), but it is
          # exactly what needs reviewing, so the wall reads it from where it waits.
          ("reasoning", "Reasoning", os.path.join("..", "curriculum",
                                                  "reasoning.json"))]

# NUPO_SKILLS=reasoning builds a wall of just those skills, for reviewing one
# band on its own without scrolling past the other 972 questions.
ONLY = [x for x in os.environ.get("NUPO_SKILLS", "").split(",") if x]


def nupo_b64():
    """The owl, shrunk to board size and inlined.

    GridBotView draws assets/nupo/focused.png; the wall must draw the same
    file, or a reviewer is checking a picture the child will never see. It is
    scaled down here because a tile is about 40px on the rendered card and the
    full asset would add a megabyte of base64 to every page load.
    """
    src = os.path.join(HERE, "..", "..", "assets", "nupo", "focused.png")
    try:
        from PIL import Image
        im = Image.open(src).convert("RGBA")
        im.thumbnail((128, 128), Image.LANCZOS)
        buf = io.BytesIO()
        im.save(buf, format="PNG", optimize=True)
        raw = buf.getvalue()
    except Exception:
        raw = open(src, "rb").read()
    return base64.b64encode(raw).decode("ascii")


def load(fn):
    return json.load(open(os.path.join(CUR, fn), encoding="utf-8"))


def screen_key(q):
    """Everything a child actually sees. Two questions matching here are the
    same question, however they were authored."""
    return json.dumps([q.get("prompt"), q.get("pic"), q.get("visual"),
                       q.get("optionsText"), q.get("options"),
                       q.get("optionCells"), q.get("optionBits"),
                       q.get("optionNets"), q.get("optionViews"), q.get("optionCubes"),
                       q.get("optionShapes"), q.get("optionSections")], sort_keys=True)


def main():
    skills, prompts, screens = [], Counter(), Counter()
    raw = []
    for sid, name, fn in SKILLS:
        if ONLY and sid not in ONLY:
            continue
        d = load(fn)
        units = []
        for sec in d["sections"]:
            for u in sec["units"]:
                qs = []
                for st in u["stops"]:
                    # Was "not authored -> skip", because unauthored used to
                    # mean an empty skeleton. Band b marks a fully authored stop
                    # unauthored when the gate cannot draw its shapes yet, and
                    # those are the ones most needing review, so skip only what
                    # genuinely has nothing in it.
                    if not st.get("questions"):
                        continue
                    for i, q in enumerate(st["questions"]):
                        item = {k: q[k] for k in KEEP if k in q}
                        item["id"] = f"{st['id']}#{i}"
                        prompts[q["prompt"]] += 1
                        screens[screen_key(item)] += 1
                        qs.append(item)
                if qs:
                    # The two skills were emitted by different scripts and
                    # name the field differently. Not worth a migration; worth
                    # one line here.
                    units.append({"id": u["stops"][0]["id"][:3],
                                  "name": u.get("title") or u.get("name", ""),
                                  "qs": qs})
        skills.append({"id": sid, "name": name, "units": units})
        raw.append(d)

    # Two different things get confused under the word "repeat", and only one
    # of them is a fault:
    #
    #   same screen  the identical question asked twice. Always wrong.
    #   same words   one prompt over many different pictures. In Number Sense
    #                that is deliberate — the picture IS the question, and a
    #                five-year-old re-reading the same sentence each time is
    #                spending their attention on the picture instead.
    #
    # The page shows them separately so a reviewer can judge the second on its
    # own merits rather than seeing 232 alarms.
    dups = echoes = 0
    for sk in skills:
        for u in sk["units"]:
            for q in u["qs"]:
                if screens[screen_key(q)] > 1:
                    q["dup"] = screens[screen_key(q)]
                    dups += 1
                elif prompts[q["prompt"]] > 1:
                    q["echo"] = prompts[q["prompt"]]
                    echoes += 1

    if not os.path.exists(TEMPLATE):
        print(f"missing {TEMPLATE}")
        return 1
    tpl = io.open(TEMPLATE, encoding="utf-8").read()
    if "/*__DATA__*/" not in tpl:
        print("wall_template.html has no /*__DATA__*/ placeholder")
        return 1
    out = tpl.replace("/*__DATA__*/",
                      json.dumps({"skills": skills}, ensure_ascii=False,
                                 separators=(",", ":")))
    # Nupo himself. The page has always drawn him from a data URI — the
    # placeholder just was not being filled, so every board fell back to the
    # plain purple circle and the review was looking at a different character
    # from the one on the phone.
    out = out.replace("__NUPO__", nupo_b64())
    os.makedirs(OUT, exist_ok=True)
    path = os.path.abspath(os.path.join(OUT, "question_wall.html"))
    io.open(path, "w", encoding="utf-8").write(out)

    total = sum(len(u["qs"]) for sk in skills for u in sk["units"])
    shapes = Counter(q["shape"] for sk in skills for u in sk["units"]
                     for q in u["qs"])
    print(f"{total} questions, {dups} on a repeated screen, "
          f"{echoes} reusing a prompt, {len(shapes)} kinds -> {path}")
    for s, n in shapes.most_common():
        print(f"  {s:14} {n}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
