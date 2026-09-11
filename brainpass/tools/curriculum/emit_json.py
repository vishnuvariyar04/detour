# Emits assets/curriculum/think_like_a_coder.json
#
# Section 1 is authored in full with real GridBot parameters so it is playable
# end to end. Sections 2-4 carry their stop/teach/question skeleton from the
# spec and are marked "authored": false so the loader can skip them until the
# params are written.
import io, json, os
from data import SKILL, SECTIONS

# ---- helpers ---------------------------------------------------------------
def grid(w=5, h=5, start=(0,0), goal=None, walls=None, stars=None, program=None):
    d = {"w": w, "h": h, "start": list(start)}
    if goal:    d["goal"]    = list(goal)
    if walls:   d["walls"]   = [list(x) for x in walls]
    if stars:   d["stars"]   = [list(x) for x in stars]
    if program: d["program"] = program
    return d

def q(shape, prompt, hint, answer, visual=None, options=None, blocks=None, slots=None):
    o = {"shape": shape, "prompt": prompt, "hint": hint, "answer": answer}
    if visual:  o["visual"]  = visual
    if options: o["options"] = options
    if blocks:  o["blocks"]  = blocks
    if slots is not None: o["slots"] = slots
    return o

U, D, L, R = "up", "down", "left", "right"

from authored import (AUTHORED, TEACH_BOARDS, TEACH_LINES, TITLES,
                      TEACH_TRUTH, TEACH_COMPARE)
from kit import evaluate, prettify

# ---- assemble ---------------------------------------------------------------
out = {
  "id": "think_like_a_coder",
  "name": SKILL["name"],
  "band": SKILL["band"],
  "ages": SKILL["ages"],
  "promise": SKILL["promise"],
  "sections": [],
}

for si,(stitle,ssub,units) in enumerate(SECTIONS, start=1):
    sec = {"n": si, "title": stitle, "subtitle": ssub, "units": []}
    for ui,(utitle,stops) in enumerate(units, start=1):
        unit = {"n": ui, "title": utitle, "stops": []}
        for (sid,title,teach,demo,qs) in stops:
            authored = AUTHORED.get(sid)
            stop = {
              "id": sid,
              # Authored stops carry kid-facing titles and teach lines; the
              # spine in data.py is written for whoever is building the
              # curriculum, not for the child reading it on the gate.
              "title": TITLES.get(sid, title),
              "boss": teach is None,
              "authored": authored is not None,
            }
            if teach:
                stop["teach"] = {"line": TEACH_LINES.get(sid, teach), "demo": demo}
                board = TEACH_BOARDS.get(sid)
                if board:
                    stop["teach"]["board"] = board
                cmp = TEACH_COMPARE.get(sid)
                if cmp:
                    cb, pa, pb = cmp
                    stop["teach"]["compare"] = {
                        "board": cb, "a": list(pa), "b": list(pb),
                    }
                demo_truth = TEACH_TRUTH.get(sid)
                if demo_truth:
                    facts, expr, state = demo_truth
                    stop["teach"]["truth"] = {
                        "facts": list(facts),
                        "expr": prettify(expr),
                        "exprRaw": expr,
                        "state": dict(state),
                        "value": evaluate(expr, state),
                    }
            if authored:
                stop["questions"] = authored
            else:
                # skeleton only — prompt + shape carried from the spec
                stop["questions"] = [
                    {"shape": s, "prompt": p, "hint": "", "answer": {}}
                    for (s, p, _a) in qs
                ]
            unit["stops"].append(stop)
        sec["units"].append(unit)
    out["sections"].append(sec)

path = r"C:\dev\detour\brainpass\assets\curriculum\think_like_a_coder.json"
io.open(path,"w",encoding="utf-8").write(json.dumps(out, indent=1, ensure_ascii=False))

stops = sum(len(u["stops"]) for s in out["sections"] for u in s["units"])
auth  = sum(1 for s in out["sections"] for u in s["units"] for st in u["stops"] if st["authored"])
qs    = sum(len(st["questions"]) for s in out["sections"] for u in s["units"] for st in u["stops"])
print(f"stops={stops} authored={auth} questions={qs}")
