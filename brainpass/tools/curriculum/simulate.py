# -*- coding: utf-8 -*-
"""Plays the whole skill without a phone.

validate.py checks that the stored answers are the RIGHT answers. This goes
further and checks that the gate can actually ask each question and that a child
can actually give the answer:

  RENDER      every field CoderGate reads for that shape is present
  ANSWERABLE  the answer can be expressed with the controls on screen —
              GridBotView refuses taps on a wall, so a cell behind a wall is
              unanswerable and would trap a child on a question forever.
              (This said "the number pad only has 1-9, so an answer of 12 is
              unanswerable". That keypad was replaced by four tappable options
              years of commits ago; this file happily passes answers up to 20
              today and enforces no such bound.)
  GRADING     feeding the stored answer through the same logic as
              CoderGate.submit() marks it right, and a wrong answer marks it
              wrong (a question that accepts anything teaches nothing)
  TEACH       the stop's demo board is not one of its own question boards
  LADDER      Curriculum.session() + Progress walk the entire ladder, serving
              every question exactly once, in order, and terminating

Run after any content change:
    python emit_json.py && python validate.py && python simulate.py
"""
import json, os, re, sys
from itertools import permutations

import validate as V
from validate import run, clears, shortest, expand, has_gap, DELTA

FAILS = []
def bad(where, msg):
    FAILS.append(f"{where}: {msg}")

# Fields CoderGate needs to draw each shape.
NEEDS = {
    "predict":    ["board_program"],
    "spot":       ["board_program", "criterion"],
    "debug":      ["board_program"],
    "count":      ["choices"],
    "choose":     ["board", "options"],
    "chooseText": ["optionsText"],
    "complete":   ["board_program", "optionsText", "gap"],
    "compare":    ["board", "two_options"],
    "fix":        ["board", "blocks", "slots"],
    "inverse":    ["board_program", "blocks", "slots"],
    "constrain":  ["board", "blocks", "slots"],
    "yesno":      ["board"],
    "trace":      ["board_program", "traceOf", "choices"],
}

# The answer control each shape puts on screen.
ANSWER_TYPE = {
    "predict": "cell", "spot": "block", "debug": "block", "count": "number",
    "choose": "option", "chooseText": "option", "complete": "option",
    "compare": "bool", "fix": "order", "inverse": "order",
    "constrain": "order",
    "yesno": "bool",
    "trace": "number",
}


def check_render(qid, q):
    shape, vis = q["shape"], q.get("visual")
    for need in NEEDS.get(shape, []):
        if need == "board" and not vis:
            bad(qid, "no board to draw")
        elif need == "board_program":
            if not vis:
                bad(qid, "no board to draw")
            elif not vis.get("program"):
                bad(qid, f"{shape} needs a program listing beside the board")
        elif need == "options" and not q.get("options"):
            bad(qid, "no option programs")
        elif need == "two_options" and len(q.get("options") or []) != 2:
            bad(qid, "compare needs exactly two programs")
        elif need == "optionsText" and not q.get("optionsText"):
            bad(qid, "no text options")
        elif need == "expr" and not q.get("expr"):
            bad(qid, "no condition to show")
        elif need == "traceOf" and not q.get("traceOf"):
            bad(qid, "no trace values to show")
        elif need == "choices" and not q.get("choices"):
            bad(qid, "no numbers to choose between")
        elif need == "criterion" and not q.get("criterion"):
            bad(qid, "does not say what makes one row the right one")
        elif need == "gap" and not any(
                "?" in t for t in (vis or {}).get("program", [])):
            bad(qid, "complete has no ? gap")
        elif need == "blocks" and not q.get("blocks"):
            bad(qid, "no blocks to place")
        elif need == "slots" and not q.get("slots"):
            bad(qid, "no slots")
    if q["answer"].get("type") != ANSWER_TYPE.get(shape):
        bad(qid, f"answer type {q['answer'].get('type')} does not match "
                 f"{shape} (expects {ANSWER_TYPE.get(shape)})")


def check_decorative(qid, q):
    """A board with nothing on it and nothing running on it is decoration.

    An empty grid next to an abstract question is something a child has to look
    past, and it takes the space the real content wants.
    """
    v = q.get("visual")
    if not v:
        return
    if q["shape"] == "compare":
        # A compare board is deliberately bare: it is the shared starting square
        # both programs run from, and the programs live in the options.
        return
    has = any(v.get(k) for k in ("goal", "stars", "walls", "key", "door",
                                 "vars", "program"))
    if not has:
        bad(qid, "the board has nothing on it — drop it or put something on it")


def check_answerable(qid, q):
    """Can a child physically produce this answer with the controls shown?"""
    a, vis, shape = q["answer"], q.get("visual"), q["shape"]
    t, v = a.get("type"), a.get("value")

    if t == "cell":
        x, y = v
        if not (0 <= x < vis["w"] and 0 <= y < vis["h"]):
            return bad(qid, f"answer cell {v} is off the board")
        if [x, y] in vis.get("walls", []):
            bad(qid, f"answer cell {v} is a wall — GridBotView ignores taps "
                     "on walls, so this is unanswerable")
    elif t == "number":
        # Numbers are tapped, not typed, so the answer has to be on offer.
        ch = q.get("choices") or []
        if v not in ch:
            bad(qid, f"answer {v} is not one of the choices {ch}")
    elif t == "block":
        n = len((vis or {}).get("program", []))
        if not (0 <= v < n):
            bad(qid, f"block {v} out of range (program has {n})")
    elif t == "option":
        opts = q.get("options") or q.get("optionsText") or []
        if not (0 <= v < len(opts)):
            bad(qid, f"option {v} out of range ({len(opts)} shown)")
    elif t == "order":
        if q.get("slots") != len(v):
            bad(qid, f"{q.get('slots')} slots but the answer is {len(v)} long")
        if q.get("reusable"):
            # A palette: any step may be used any number of times.
            extra = set(v) - set(q.get("blocks", []))
            if extra:
                bad(qid, f"answer uses {sorted(extra)}, not on the palette")
        elif sorted(q.get("blocks", [])) != sorted(v):
            bad(qid, "the steps on offer cannot spell the answer")


def graded_correct(q, submitted):
    """Mirrors CoderGate.submit() / Question.isCorrectOrder()."""
    a, shape = q["answer"], q["shape"]
    if shape in ("fix", "constrain"):
        return clears(q["visual"], submitted)
    if shape == "inverse":
        return submitted == a["value"]
    return submitted == a["value"]


def wrong_answers(q):
    """Plausible wrong answers a child might actually give.

    Tolerant of malformed content on purpose: the other checks report those,
    and a harness that crashes on bad input hides every fault after it.
    """
    a, vis, shape = q["answer"], q.get("visual") or {}, q["shape"]
    t, v = a.get("type"), a.get("value")
    out = []
    if t == "cell" and isinstance(v, list) and vis.get("w"):
        walls = [tuple(c) for c in vis.get("walls", [])]
        for y in range(vis["h"]):
            for x in range(vis["w"]):
                if [x, y] != v and (x, y) not in walls:
                    out.append([x, y])
    elif t == "number":
        out = [n for n in (q.get("choices") or []) if n != v]
    elif t == "block":
        out = [i for i in range(len(vis.get("program", []))) if i != v]
    elif t == "option":
        opts = q.get("options") or q.get("optionsText") or []
        out = [i for i in range(len(opts)) if i != v]
    elif t == "bool":
        out = [not v]
    elif t == "order" and q.get("blocks"):
        if q.get("reusable"):
            from itertools import product
            out = [list(p) for p in product(q["blocks"], repeat=len(v))
                   if list(p) != v]
        else:
            out = [list(p) for p in set(permutations(q["blocks"])) if list(p) != v]
    return out


def check_grading(qid, q):
    if not graded_correct(q, q["answer"]["value"]):
        bad(qid, "the stored answer does not grade as correct")
    wrongs = wrong_answers(q)
    if not wrongs:
        return bad(qid, "there is no wrong answer available")
    accepted = [w for w in wrongs if graded_correct(q, w)]
    if q["shape"] in ("fix", "constrain"):
        # Several orders legitimately clear the board; that is the design. What
        # must not happen is EVERY order clearing it.
        if len(accepted) == len(wrongs):
            bad(qid, "every arrangement is accepted — the puzzle is free")
    elif accepted:
        bad(qid, f"{len(accepted)} wrong answer(s) graded correct: {accepted[:3]}")


# Words that make a 9-year-old stop reading. "block" is banned outright: it
# meant either an instruction or a board square depending on who read it.
BANNED = {
    "block": "step", "blocks": "steps",
    "tile": "square", "tiles": "squares",
    "program": "list of steps", "programs": "lists",
    "instruction": "step", "instructions": "steps",
    "reorder": "put in order", "execute": "do", "sequence": "order",
}
MAX_WORDS_PER_SENTENCE = 13


def check_reading(where, text, field):
    """Kid-facing copy has to be readable at a glance, not parsed."""
    if not text:
        return
    # snake_case is a programmer's name for a thing, never a child's.
    if re.search(r"[a-z]+_[a-z]+", text):
        bad(where, f"{field} has a code name in it: \"{text[:48]}\"")
    words = re.findall(r"[A-Za-z']+", text)
    for w in words:
        low = w.lower()
        if low in BANNED:
            bad(where, f'{field} says "{w}" — say "{BANNED[low]}" instead')
    for sentence in re.split(r"(?<=[.?!])\s+", text.strip()):
        n = len(re.findall(r"[A-Za-z']+", sentence))
        if n > MAX_WORDS_PER_SENTENCE:
            bad(where, f"{field} has a {n}-word sentence: \"{sentence[:60]}...\"")


# A loop is unrolled before it animates, at ~280ms a move. Past this the child
# is watching, not thinking, and the gate feels stuck.
MAX_ANIMATED_MOVES = 26


def check_loops(qid, q):
    """Loop syntax has to be balanced and the run has to stay watchable."""
    boards = []
    if q.get("visual", {}).get("program"):
        boards.append(("visual", q["visual"]["program"]))
    for i, o in enumerate(q.get("options") or []):
        boards.append((f"option {i}", o))
    if q["answer"].get("type") == "order":
        boards.append(("answer", q["answer"]["value"]))

    for where, prog in boards:
        if has_gap(prog):
            continue        # a `complete` question: it cannot run until filled
        if not any(isinstance(t, str) and
                   (t.startswith("repeat:") or t.startswith("if:") or
                    t in ("end", "else")) for t in prog):
            continue
        try:
            moves = run(q.get("visual") or {"w": 9, "h": 9, "start": [0, 0]},
                        prog)[5]
        except (ValueError, KeyError) as e:
            bad(qid, f"{where}: {e}")
            continue
        if len(moves) > MAX_ANIMATED_MOVES:
            bad(qid, f"{where} unrolls to {len(moves)} moves — over "
                     f"{MAX_ANIMATED_MOVES}, the animation drags")
        if not moves and not any(t.startswith("if:") for t in prog):
            # A condition that never fires legitimately makes no moves; a loop
            # that makes none is a mistake.
            bad(qid, f"{where} unrolls to nothing")


def check_animation(qid, prog, vis, where):
    """The invariant GridBotView.play() relies on to animate a program.

    It walks from path[i] to path[i+1] for every move, so path must be exactly
    one longer than moves. A step that does not move Nupo — SET, ADD — still has
    to record where he is standing. When that broke, the gate crashed outright
    and the child was left with no way forward.
    """
    try:
        r = run(vis, prog)
    except (ValueError, KeyError):
        return                                   # reported elsewhere
    moves, path = r[5], r[9]
    if len(path) != len(moves) + 1:
        bad(qid, f"{where}: {len(moves)} moves but {len(path)} path entries — "
                 "the animation would run off the end")


# A trace table draws one row per step and still has to leave room for the
# number choices underneath. Past this the table scrolls off the screen and the
# child answers a question they cannot see the top of.
MAX_TRACE_ROWS = 7


def check_trace_fits(qid, q):
    if q["shape"] != "trace":
        return
    n = len((q.get("visual") or {}).get("program") or [])
    if n > MAX_TRACE_ROWS:
        bad(qid, f"a {n}-row trace table will not fit above the number "
                 f"choices — {MAX_TRACE_ROWS} rows is the most that does")


def check_teach(stop):
    t = stop.get("teach") or {}
    board = t.get("board")
    truth = t.get("truth")
    if not stop["boss"]:
        if not t.get("line"):
            bad(stop["id"], "no teach line")
        cmp = t.get("compare")
        if cmp:
            # Two runs are only worth showing if they visibly differ — a
            # different ending square, or the same one in fewer rows.
            cb, pa, pb = cmp["board"], cmp["a"], cmp["b"]
            ea, eb = run(cb, pa)[0], run(cb, pb)[0]
            if ea == eb and len(pa) == len(pb):
                bad(stop["id"], "the two demo programs are indistinguishable")
            for nm, pr in (("a", pa), ("b", pb)):
                check_animation(stop["id"], pr, cb, f"demo {nm}")
            return
        if truth:
            # A logic stop demonstrates a condition, not a board.
            from kit import evaluate
            if "_" in truth.get("expr", ""):
                bad(stop["id"], "the demo condition still has an underscore")
            try:
                v = evaluate(truth["exprRaw"], truth["state"])
            except Exception as e:
                return bad(stop["id"], f"demo condition will not evaluate: {e}")
            if v != truth.get("value"):
                bad(stop["id"], f"demo says {truth.get('value')}, really {v}")
            if not truth.get("facts"):
                bad(stop["id"], "the demo shows no facts")
            return
        if not board:
            bad(stop["id"], "no teach demo board")
            return
        if not board.get("program"):
            bad(stop["id"], "teach board has nothing to animate")
        for i, q in enumerate(stop["questions"]):
            if q.get("visual") == board:
                bad(stop["id"], f"teach demo is question {i}'s board — it "
                                "animates the answer before asking it")


# ------------------------------------------------------------------ ladder

class Progress:
    """Mirrors Curriculum.Progress."""
    def __init__(self):
        self.stop = 0
        self.q = 0
        self.review = []
        self.taught = set()
        self.asked = 0

    def resolve(self, qid, correct):
        self.asked += 1
        if qid in self.review:
            self.review.remove(qid)
        if not correct:
            self.review.append(qid)
        while len(self.review) > 20:
            self.review.pop(0)

    def advance(self, ladder):
        if self.stop >= len(ladder):
            return
        self.q += 1
        if self.q >= len(ladder[self.stop]["questions"]):
            self.stop += 1
            self.q = 0


def session(ladder, p, floor=3):
    """Mirrors Curriculum.session()."""
    if p.stop >= len(ladder):
        return []
    out = []
    if p.review:
        rid = p.review[0]
        sid, idx = rid.split("#")
        stop = next((s for s in ladder if s["id"] == sid), None)
        if stop:
            out.append(("review", stop, stop["questions"][int(idx)], rid))
    stop_i, q_i = p.stop, p.q
    asked = lambda: sum(1 for kind, *_ in out if kind != "teach")
    while True:
        stop = ladder[stop_i]
        if q_i == 0 and stop["id"] not in p.taught and (stop.get("teach") or {}).get("line"):
            out.append(("teach", stop, None, None))
        for k in range(q_i, len(stop["questions"])):
            out.append(("q", stop, stop["questions"][k], f"{stop['id']}#{k}"))
        stop_i += 1
        q_i = 0
        if asked() >= floor or stop_i >= len(ladder):
            break
    return out


def walk_ladder(ladder, always_correct):
    """Play the whole ladder and report the order questions were served in."""
    p = Progress()
    served = []
    guard = 0
    while p.stop < len(ladder):
        guard += 1
        if guard > 500:
            bad("ladder", "session loop did not terminate")
            break
        items = session(ladder, p)
        if not items:
            break
        for kind, stop, q, qid in items:
            if kind == "teach":
                p.taught.add(stop["id"])
                continue
            correct = always_correct
            p.resolve(qid, correct)
            if kind != "review":
                served.append(qid)
                p.advance(ladder)
    return p, served


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(here, "..", "..", "assets", "curriculum",
                        "think_like_a_coder.json")
    d = json.load(open(path, encoding="utf-8"))

    stops = [st for s in d["sections"] for u in s["units"] for st in u["stops"]]
    ladder = [st for st in stops if st["authored"] and st["questions"]]

    n = 0
    for st in ladder:
        check_teach(st)
        tb = (st.get("teach") or {}).get("board")
        if tb and tb.get("program"):
            check_animation(st["id"], tb["program"], tb, "teach demo")
        check_reading(st["id"], (st.get("teach") or {}).get("line"), "teach line")
        check_reading(st["id"], st.get("title"), "title")
        for i, q in enumerate(st["questions"]):
            qid = f"{st['id']}#{i}"
            check_render(qid, q)
            check_answerable(qid, q)
            check_grading(qid, q)
            V.check(qid, q)      # is the stored answer actually the right one?
            check_loops(qid, q)
            check_trace_fits(qid, q)
            check_decorative(qid, q)
            if (q.get("visual") or {}).get("program") and not has_gap(q["visual"]["program"]):
                check_animation(qid, q["visual"]["program"], q["visual"], "visual")
            for oi, o in enumerate(q.get("options") or []):
                check_animation(qid, o, q.get("visual") or {}, f"option {oi}")
            check_reading(qid, q.get("prompt"), "prompt")
            check_reading(qid, q.get("hint"), "hint")
            for o in q.get("optionsText") or []:
                check_reading(qid, o, "option")
            n += 1
    from _audit import audit
    audit(ladder, bad)

    FAILS.extend(V.ERRORS)

    # Every authored question must be reachable, once, in order.
    expected = [f"{st['id']}#{i}"
                for st in ladder for i in range(len(st["questions"]))]
    p_ok, served_ok = walk_ladder(ladder, always_correct=True)
    if served_ok != expected:
        bad("ladder", f"all-correct walk served {len(served_ok)} of "
                      f"{len(expected)} questions in the wrong order")
    if p_ok.review:
        bad("ladder", f"all-correct walk left {len(p_ok.review)} in review")

    p_bad, served_bad = walk_ladder(ladder, always_correct=False)
    if served_bad != expected:
        bad("ladder", "all-wrong walk did not still reach every question — a "
                      "child who gets everything wrong must not be stuck")

    print(f"stops authored : {len(ladder)} of {len(stops)}")
    print(f"questions      : {n}")
    print(f"ladder walk    : {len(served_ok)} served, "
          f"{len(expected)} expected, review left {len(p_ok.review)}")
    for f in FAILS:
        print("  FAIL", f)
    print("OK" if not FAILS else f"{len(FAILS)} problem(s)")
    return 1 if FAILS else 0


sys.exit(main())
