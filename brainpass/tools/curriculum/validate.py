# -*- coding: utf-8 -*-
"""Simulates every authored question and fails loudly on a wrong or ambiguous answer.

The simulator here is the reference implementation; GridBotView.kt must match it
step for step (blocked move = stay put, program keeps running).
"""
import json, os, sys
from itertools import permutations

DELTA = {"up": (0, 1), "down": (0, -1), "left": (-1, 0), "right": (1, 0)}


MAX_STEPS = 2000  # a runaway loop must fail loudly, not hang the authoring run


def has_gap(prog):
    """True if the program is deliberately incomplete (a `complete` question)."""
    return any(isinstance(t, str) and "?" in t for t in prog)


def _match_end(prog, i, hi):
    """Index of the `end` that closes the block opening at [i]."""
    level, j = 1, i + 1
    while j < hi and level:
        t = prog[j]
        if isinstance(t, str) and (t.startswith("repeat:") or t.startswith("if:")):
            level += 1
        elif t == "end":
            level -= 1
        if level:
            j += 1
    if j >= hi:
        raise ValueError(f"block at {i} has no matching end")
    return j


def _split_else(prog, lo, hi):
    """Index of the `else` at this block's own level, or -1."""
    level, j = 0, lo
    while j < hi:
        t = prog[j]
        if isinstance(t, str) and (t.startswith("repeat:") or t.startswith("if:")):
            level += 1
        elif t == "end":
            level -= 1
        elif t == "else" and level == 0:
            return j
        j += 1
    return -1


def expand(prog):
    """Unrolls loops in a program that has no conditions.

    Conditions cannot be unrolled without knowing where Nupo is standing, so
    programs containing IF are interpreted by run() instead. This stays for the
    questions that only ask "how many moves does this loop make".
    """
    out, origin = [], []

    def walk(lo, hi, depth=0):
        if depth > 12:
            raise ValueError("loops nested too deep")
        i = lo
        while i < hi:
            tok = prog[i]
            if isinstance(tok, str) and tok.startswith("repeat:"):
                times = int(tok.split(":", 1)[1])
                j = _match_end(prog, i, hi)
                for _ in range(times):
                    walk(i + 1, j, depth + 1)
                    if len(out) > MAX_STEPS:
                        raise ValueError("program runs too long")
                i = j + 1
            elif tok == "end":
                raise ValueError(f"end at {i} without a repeat")
            elif isinstance(tok, str) and tok.startswith("if:"):
                raise ValueError("expand() cannot unroll a condition")
            else:
                out.append(tok)
                origin.append(i)
                i += 1

    walk(0, len(prog))
    return out, origin


# ---------------------------------------------------------------- sensors

def sense(name, pos, vis, has_key, stars_left):
    """Answers one yes/no question about where Nupo is standing.

    Sensors are deliberately concrete — "is there a wall above you" — because a
    child can check the answer by looking at the board, which is what makes a
    condition feel like a rule rather than a spell.
    """
    x, y = pos
    w, h = vis["w"], vis["h"]
    walls = {tuple(c) for c in vis.get("walls", [])}
    if name == "star":
        return (x, y) in stars_left
    if name == "key":
        return has_key
    if name == "door":
        return "door" in vis and [x, y] == vis["door"]
    if name.startswith("wall-"):
        d = {"up": (0, 1), "down": (0, -1), "left": (-1, 0), "right": (1, 0)}
        dx, dy = d[name.split("-", 1)[1]]
        n = (x + dx, y + dy)
        return not (0 <= n[0] < w and 0 <= n[1] < h) or n in walls
    raise ValueError(f"unknown sensor {name}")


def test(cond, pos, vis, has_key, stars_left):
    """Evaluates a condition token, honouring a leading not-."""
    if cond.startswith("not-"):
        return not test(cond[4:], pos, vis, has_key, stars_left)
    return sense(cond, pos, vis, has_key, stars_left)


def run(vis, prog):
    """Interprets a program and reports what happened.

    Returns (end_cell, stars_taken, has_key, door_open, fail_index, moves,
    origin). fail_index indexes [prog] as written, so it lines up with the row a
    child sees and taps, even for a step inside a loop.

    Loops AND conditions are handled here together: a condition cannot be
    unrolled ahead of time because whether it fires depends on where Nupo is
    standing when it is reached.
    """
    x, y = vis["start"]
    w, h = vis["w"], vis["h"]
    walls = {tuple(c) for c in vis.get("walls", [])}
    stars = {tuple(c) for c in vis.get("stars", [])}
    key = tuple(vis["key"]) if "key" in vis else None
    door = tuple(vis["door"]) if "door" in vis else None
    taken, has_key, opened, fail = set(), False, False, -1
    moves, origin = [], []
    # Every time a condition is looked at, and what it said. A loop asks the
    # same IF on every pass, so "checked four times, fired twice" is a fact
    # about the run and not about the listing.
    checks = []

    # Named boxes holding numbers. A board declares its starting values; SET
    # replaces what is inside, ADD changes it. The trace records the value of
    # every box after each step, which is what a trace table question shows.
    boxes = dict(vis.get("vars", {}))
    trace = [dict(boxes)]
    # The square Nupo stands on after each move. GridBotView animates between
    # path[i] and path[i+1], so this must always be exactly one longer than
    # moves — a step that does not move him (SET/ADD) still records where he is.
    path = [[x, y]]

    def do(tok, src):
        nonlocal x, y, has_key, opened, fail
        moves.append(tok)
        origin.append(src)
        if isinstance(tok, str) and (tok.startswith("set:") or tok.startswith("add:")):
            op, name, val = tok.split(":", 2)
            n = int(val)
            if op == "set":
                boxes[name] = n
            else:
                boxes[name] = boxes.get(name, 0) + n
            trace.append(dict(boxes))
            path.append([x, y])
            return
        if tok in DELTA:
            dx, dy = DELTA[tok]
            nx, ny = x + dx, y + dy
            blocked = not (0 <= nx < w and 0 <= ny < h) or (nx, ny) in walls
            if blocked:
                # A blocked move still happened — it just went nowhere. It has
                # to record a path entry, or path and moves drift apart and the
                # animation on the phone walks off the end of the path.
                if fail < 0: fail = src
            else:
                x, y = nx, ny
                # On a mustPick board a star has to be picked up deliberately.
                # Without that, "IF ON A STAR THEN PICK UP" teaches nothing:
                # walking over it would already have collected it.
                if (x, y) in stars and not vis.get("mustPick"): taken.add((x, y))
        elif tok == "pick":
            if key is not None and (x, y) == key and not has_key:
                has_key = True
            elif (x, y) in stars:
                taken.add((x, y))
            else:
                if fail < 0: fail = src
        elif tok == "open":
            if door is not None and (x, y) == door and has_key:
                opened = True
            else:
                if fail < 0: fail = src
        trace.append(dict(boxes))
        path.append([x, y])

    def walk(lo, hi, depth=0):
        if depth > 12:
            raise ValueError("nested too deep")
        i = lo
        while i < hi:
            if len(moves) > MAX_STEPS:
                raise ValueError("program runs too long")
            tok = prog[i]
            if isinstance(tok, str) and tok.startswith("repeat:"):
                times = int(tok.split(":", 1)[1])
                j = _match_end(prog, i, hi)
                for _ in range(times):
                    walk(i + 1, j, depth + 1)
                i = j + 1
            elif isinstance(tok, str) and tok.startswith("if:"):
                j = _match_end(prog, i, hi)
                e = _split_else(prog, i + 1, j)
                cond = tok.split(":", 1)[1]
                verdict = test(cond, (x, y), vis, has_key, stars - taken)
                checks.append([i, bool(verdict)])
                if verdict:
                    walk(i + 1, e if e >= 0 else j, depth + 1)
                elif e >= 0:
                    walk(e + 1, j, depth + 1)
                i = j + 1
            elif tok in ("end", "else"):
                i += 1
            else:
                do(tok, i)
                i += 1

    walk(0, len(prog))
    return ([x, y], taken, has_key, opened, fail, moves, origin, boxes,
            trace, path, checks)


def clears(vis, prog):
    """Did this program satisfy everything the board asks for?

    A flag must be reached, every star must be collected, and a door must end up
    open. There is deliberately no rule about where Nupo stops on a board with
    no flag: once a program can collect several stars, "stop on the star" means
    "stop on the last one", which is not something a question ever asks.
    """
    r = run(vis, prog)
    end, taken, opened = r[0], r[1], r[3]
    if "goal" in vis and end != vis["goal"]: return False
    if vis.get("stars") and len(taken) != len(vis["stars"]): return False
    if "door" in vis and not opened: return False
    return True


def shortest(vis):
    """BFS over moves only, ignoring stars/keys."""
    from collections import deque
    w, h = vis["w"], vis["h"]
    walls = {tuple(c) for c in vis.get("walls", [])}
    goal = tuple(vis["goal"])
    seen = {tuple(vis["start"]): 0}
    dq = deque([tuple(vis["start"])])
    while dq:
        c = dq.popleft()
        if c == goal: return seen[c]
        for dx, dy in DELTA.values():
            n = (c[0] + dx, c[1] + dy)
            if 0 <= n[0] < w and 0 <= n[1] < h and n not in walls and n not in seen:
                seen[n] = seen[c] + 1
                dq.append(n)
    return None


ERRORS = []
def bad(qid, msg): ERRORS.append(f"{qid}: {msg}")


def check_choices(qid, q, a):
    """Every number answer is picked from four options, so they must be sane."""
    ch = q.get("choices")
    if not ch: return bad(qid, "a number answer needs choices to pick from")
    if len(ch) != 4: bad(qid, f"expected 4 choices, got {len(ch)}")
    if len(set(ch)) != len(ch): bad(qid, f"duplicate choices {ch}")
    if a["value"] not in ch: bad(qid, f"answer {a['value']} is not among {ch}")
    if any(c < 0 for c in ch): bad(qid, f"negative choice in {ch}")


def check(qid, q):
    shape, a, vis = q["shape"], q["answer"], q.get("visual")
    if not q["hint"]: bad(qid, "no hint")
    if not q["prompt"].endswith(("?", ".")): bad(qid, "prompt has no terminator")

    if shape == "predict":
        if not vis or "program" not in vis: return bad(qid, "predict needs visual.program")
        end, *_ = run(vis, vis["program"])
        if end != a["value"]: bad(qid, f"lands on {end}, answer says {a['value']}")

    elif shape in ("spot", "debug"):
        if not vis or "program" not in vis: return bad(qid, "needs visual.program")
        i = a["value"]
        if not 0 <= i < len(vis["program"]): return bad(qid, f"block {i} out of range")
        if shape == "debug":
            fail = run(vis, vis["program"])[4]
            if fail != i: bad(qid, f"first failing block is {fail}, answer says {i}")

    elif shape == "choose":
        opts = q["options"]
        if not vis: return bad(qid, "choose needs a visual board")
        ok = [i for i, o in enumerate(opts) if clears(vis, o)]
        crit = q.get("criterion", "clears")
        if crit == "clears":
            if ok != [a["value"]]:
                bad(qid, f"lists that clear the board: {ok}, "
                         f"answer says {a['value']}")
        elif crit == "shortest":
            # Several may work; the answer is the one that works in fewest steps.
            if not ok:
                bad(qid, "no list clears the board")
            else:
                lens = sorted((len(opts[i]), i) for i in ok)
                if len(lens) > 1 and lens[0][0] == lens[1][0]:
                    bad(qid, f"two lists tie for shortest: {lens[:2]}")
                elif lens[0][1] != a["value"]:
                    bad(qid, f"shortest working list is {lens[0][1]}, "
                             f"answer says {a['value']}")
        else:
            bad(qid, f"unknown choose criterion {crit}")

    elif shape in ("chooseText", "complete"):
        opts = q["optionsText"]
        if not 0 <= a["value"] < len(opts): bad(qid, "option index out of range")
        if len(set(opts)) != len(opts): bad(qid, "duplicate option text")
        if shape == "complete":
            # The gap is either a whole missing step ("?") or a missing loop
            # count ("repeat:?") — the count is the interesting blank in a loop.
            prog = (vis or {}).get("program", [])
            if not any("?" in t for t in prog):
                bad(qid, "no ? gap in program")

    elif shape == "compare":
        opts = q["options"]
        if len(opts) != 2: return bad(qid, "compare needs exactly 2 programs")
        e0 = run(vis, opts[0])[0]
        e1 = run(vis, opts[1])[0]
        same = e0 == e1
        if same != a["value"]:
            bad(qid, f"ends {e0} vs {e1} (same={same}), answer says {a['value']}")

    elif shape == "count":
        if a["value"] < 0: bad(qid, "count answer cannot be negative")
        check_choices(qid, q, a)
        kind = q.get("kind", "steps")
        if kind == "steps":
            if not vis or "program" not in vis:
                bad(qid, "a steps count needs a program to count")
            elif a["value"] != len(vis["program"]):
                bad(qid, f"the list has {len(vis['program'])} steps, "
                         f"answer says {a['value']}")
        elif kind in ("checks", "fires"):
            if not vis or not any(str(t).startswith("if:")
                                  for t in vis.get("program", [])):
                bad(qid, "asks about a check on a list that has none")
            else:
                ch = run(vis, vis["program"])[10]
                want = len(ch) if kind == "checks" else sum(1 for _, v in ch if v)
                if a["value"] != want:
                    bad(qid, f"the check is {'made' if kind == 'checks' else 'true'} "
                             f"{want} times, answer says {a['value']}")
        elif kind == "shortest":
            if not vis or "goal" not in vis:
                bad(qid, "a shortest count needs a goal")
            else:
                s = shortest(vis)
                if s != a["value"]:
                    bad(qid, f"shortest route is {s}, answer says {a['value']}")
        elif kind == "moves":
            # With loops on screen "steps" is ambiguous, so questions ask how
            # many MOVES Nupo makes — the unrolled count.
            if not vis or "program" not in vis:
                bad(qid, "a moves count needs a program")
            else:
                n = len(run(vis, vis["program"])[5])
                if n != a["value"]:
                    bad(qid, f"the list makes {n} moves, answer says {a['value']}")
        elif kind == "rows":
            if not vis or "program" not in vis:
                bad(qid, "a rows count needs a program")
            elif len(vis["program"]) != a["value"]:
                bad(qid, f"the listing has {len(vis['program'])} rows, "
                         f"answer says {a['value']}")
        elif kind == "var":
            name = q.get("varName")
            if not name:
                bad(qid, "a var count must say which box it means")
            else:
                v = run(vis, vis["program"])[7].get(name)
                if v != a["value"]:
                    bad(qid, f"{name} ends at {v}, answer says {a['value']}")
        elif kind == "stars":
            n = len(run(vis, vis["program"])[1])
            if n != a["value"]:
                bad(qid, f"the list collects {n} stars, answer says {a['value']}")
        elif kind != "stated":
            bad(qid, f"unknown count kind {kind}")

    elif shape == "trace":
        # Re-derive the whole column rather than trusting the stored values.
        prog = (vis or {}).get("program", [])
        name = q.get("varName")
        if not prog or not name: return bad(qid, "a trace needs a program and a box")
        tr = [t.get(name, 0) for t in run(vis, prog)[8]][1:len(prog) + 1]
        if tr != q.get("traceOf"):
            bad(qid, f"trace is {tr}, question shows {q.get('traceOf')}")
        gap = q.get("gapRow", -1)
        if not 0 <= gap < len(tr): return bad(qid, f"gap row {gap} out of range")
        if tr[gap] != a["value"]:
            bad(qid, f"row {gap} is {tr[gap]}, answer says {a['value']}")
        check_choices(qid, q, a)

    elif shape == "truth":
        # Re-evaluate the condition from the facts rather than trusting the
        # value that was computed when the question was written.
        from kit import evaluate
        raw = q.get("exprRaw") or q.get("expr")
        if not raw: return bad(qid, "no condition to judge")
        if not q.get("state"): return bad(qid, "no facts to judge it against")
        if not q.get("optionsText"): bad(qid, "no facts shown to the child")
        if "_" in q.get("expr", ""):
            bad(qid, "the condition on screen still has an underscore in it")
        try:
            v = evaluate(raw, q["state"])
        except Exception as e:
            return bad(qid, f"condition will not evaluate: {e}")
        if v != a["value"]:
            bad(qid, f"{raw} with {q['state']} is {v}, answer says {a['value']}")

    elif shape == "spot":
        # A "tap the row that..." question is only fair when exactly ONE row
        # answers the description. Two questions shipped where several did:
        # "tap a row that changes the box" on a list with two ADD rows, and
        # "tap where the repeated steps start" on a chunk that starts three
        # times. A child who tapped a different right row was marked wrong.
        crit = q.get("criterion") or ""
        prog = (vis or {}).get("program") or []
        want = a["value"]
        if not crit:
            return bad(qid, "a spot question must say what makes a row the one")
        if crit == "skipped" or crit == "ran":
            ran = set(run(vis, prog)[6])
            inside = [i for i, t in enumerate(prog)
                      if not str(t).startswith(("repeat:", "if:"))
                      and t not in ("end", "else")]
            hit = [i for i in inside if (i in ran) == (crit == "ran")]
        elif crit.startswith("changes:"):
            name = crit.split(":", 1)[1]
            hit = [i for i, t in enumerate(prog)
                   if str(t).startswith(("set:%s:" % name, "add:%s:" % name))]
        elif crit == "replaces":
            hit = [i for i, t in enumerate(prog) if str(t).startswith("set:")]
        elif crit == "first":
            hit = [0]
        elif crit == "pickup":
            hit = [i for i, t in enumerate(prog) if t == "pick"]
        elif crit == "undo":
            # A move immediately cancelled by the one before it.
            opp = {"up": "down", "down": "up", "left": "right", "right": "left"}
            hit = [i for i in range(1, len(prog))
                   if opp.get(prog[i - 1]) == prog[i]]
        elif crit == "lastInLoop":
            opens = [i for i, t in enumerate(prog) if str(t).startswith("repeat:")]
            if not opens:
                bad(qid, "asks about a loop in a list that has none")
                hit = []
            else:
                hit = [_match_end(prog, opens[0], len(prog)) - 1]
        elif crit.startswith("firstChanges:"):
            name = crit.split(":", 1)[1]
            rows = [i for i, t in enumerate(prog)
                    if str(t).startswith(("set:%s:" % name, "add:%s:" % name))]
            if len(rows) < 2:
                bad(qid, "only one row changes the box, so 'first' is misleading")
            hit = rows[:1]
        elif crit.startswith("afterChunk:"):
            n = int(crit.split(":", 1)[1])
            i = 0
            while i + 2 * n <= len(prog) and prog[i:i + n] == prog[i + n:i + 2 * n]:
                i += n
            hit = [i + n] if i + n < len(prog) else []
        elif crit == "loopOpen":
            hit = [i for i, t in enumerate(prog) if str(t).startswith("repeat:")]
        elif crit == "innerLoop":
            opens = [i for i, t in enumerate(prog) if str(t).startswith("repeat:")]
            hit = opens[1:] if len(opens) > 1 else []
        elif crit.startswith("chunk:"):
            # "chunk:2" — the first row of the first run of a 2-row group that
            # appears again later. Only the FIRST is the answer, so the prompt
            # has to say first; the check here is that the chunk really repeats.
            n = int(crit.split(":", 1)[1])
            runs = [i for i in range(len(prog) - n + 1)
                    if prog[i:i + n] in [prog[j:j + n]
                                         for j in range(len(prog) - n + 1)
                                         if j != i]]
            if len(runs) < 2:
                bad(qid, f"no {n}-row group repeats in this list")
            hit = runs[:1]
        else:
            return bad(qid, f"unknown spot criterion {crit}")

        if len(hit) > 1 and not crit.startswith("chunk:"):
            bad(qid, f"rows {hit} all fit the description — "
                     "a child tapping any of them would be marked wrong")
        if want not in hit:
            bad(qid, f"the rows that fit are {hit}, answer says {want}")

    elif shape == "yesno":
        # Worked out again from the board here, so a board edited after the
        # question was written cannot leave a stale Yes behind. The criterion
        # is what makes that possible: without it this could only compare the
        # stored answer against itself.
        crit = q.get("criterion") or ""
        if not crit:
            return bad(qid, "a yes/no question must say what it is asking")
        if crit.startswith("canMove:"):
            v = not sense("wall-" + crit.split(":", 1)[1],
                          tuple(vis["start"]), vis, False, set())
        elif crit.startswith("standingOn:"):
            v = sense(crit.split(":", 1)[1], tuple(vis["start"]), vis, False,
                      {tuple(c) for c in vis.get("stars", [])})
        else:
            if not vis.get("program"):
                return bad(qid, "nothing to run, so nothing to answer about")
            end, taken, _, opened, failed = run(vis, vis["program"])[:5]
            if crit == "reachesFlag":
                v = "goal" in vis and list(end) == list(vis["goal"])
            elif crit == "allStars":
                v = len(taken) == len(vis.get("stars") or [])
            elif crit == "throughDoor":
                v = bool(opened)
            elif crit == "anyStepFails":
                v = failed >= 0
            else:
                return bad(qid, f"unknown yes/no criterion {crit}")
        if bool(v) != bool(a["value"]):
            bad(qid, f"the board says {v}, the answer says {a['value']}")
        # A question nobody can get wrong by looking is not a question.
        if crit == "reachesFlag" and "goal" not in vis:
            bad(qid, "asks about a flag the board does not have")
        if crit == "allStars" and not vis.get("stars"):
            bad(qid, "asks about stars the board does not have")
        if crit == "throughDoor" and "door" not in vis:
            bad(qid, "asks about a door the board does not have")
        if crit == "standingOn:star" and not vis.get("stars"):
            bad(qid, "asks about a star the board does not have")

    elif shape == "constrain":
        # Build-to-a-budget: the tray is a palette that can be reused, so the
        # only rules are that the answer fits the boxes and clears the board.
        ans = a["value"]
        if q["slots"] != len(ans): bad(qid, "slots != answer length")
        palette = set(q.get("blocks", []))
        extra = set(ans) - palette
        if extra: bad(qid, f"answer uses {sorted(extra)}, not on the palette")
        if not clears(vis, ans): bad(qid, f"answer {ans} does not clear the board")
        s = shortest(vis) if "goal" in vis else None
        if s is not None and len(ans) < s:
            bad(qid, f"asks for {len(ans)} steps but the shortest route is {s}")

    elif shape in ("fix", "inverse"):
        blocks, ans = q["blocks"], a["value"]
        if q["slots"] != len(ans): bad(qid, "slots != answer length")
        if sorted(blocks) != sorted(ans):
            return bad(qid, f"blocks {blocks} cannot make {ans}")
        if shape == "inverse":
            if list(vis["program"]) != list(ans):
                bad(qid, "inverse answer must equal the shown path program")
        else:
            if not clears(vis, ans): bad(qid, f"answer {ans} does not clear the board")
        # fix is graded by simulation, so several orders may be right. What must
        # hold is that the blocks CAN clear the board and cannot do so trivially
        # (a puzzle every arrangement solves teaches nothing).
        if shape == "fix":
            perms = set(permutations(blocks))
            wins = {p for p in perms if clears(vis, list(p))}
            if not wins: bad(qid, "no arrangement clears the board")
            if len(wins) == len(perms):
                bad(qid, "every arrangement clears the board, so the puzzle is free")
    else:
        bad(qid, f"unknown shape {shape}")


def main(path):
    d = json.load(open(path, encoding="utf-8"))
    n = 0
    for sec in d["sections"]:
        for u in sec["units"]:
            for st in u["stops"]:
                if not st["authored"]: continue
                if not st["boss"] and not st.get("teach"): bad(st["id"], "no teach card")
                for i, q in enumerate(st["questions"]):
                    check(f"{st['id']}#{i}", q); n += 1
    print(f"checked {n} authored questions")
    for e in ERRORS: print("  FAIL", e)
    print("OK" if not ERRORS else f"{len(ERRORS)} problem(s)")
    return 1 if ERRORS else 0


DEFAULT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "..", "..", "assets", "curriculum",
                       "think_like_a_coder.json")

# Guarded so simulate.py can import the simulator without running this pass.
if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else DEFAULT))
