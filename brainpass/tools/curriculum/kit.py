# -*- coding: utf-8 -*-
"""Authoring kit: the helpers every unit file uses.

The important idea here is COMPUTED ANSWERS. Where an answer follows from the
board — where a program ends, how many steps it has, the shortest route — it is
worked out by the reference simulator rather than typed in by hand. Hand
arithmetic across three hundred questions is a guaranteed source of "the app
said my right answer was wrong", which is the one bug there is no recovering
from once a child hits it.

Answers that are a design choice (which option is the good one, which step is
structurally interesting) are still written by hand, and validate.py checks
those independently.
"""
from validate import run, clears, shortest, expand

U, D, L, R = "up", "down", "left", "right"
PICK, OPEN = "pick", "open"


# ---------------------------------------------------------------- boards

def g(w=5, h=5, start=(0, 0), goal=None, walls=None, stars=None,
      key=None, door=None, program=None, mustPick=False, vars=None):
    """A GridBot board. x is the column, y counts UP from the bottom row.

    [mustPick] makes stars need a deliberate PICK UP rather than being collected
    by walking over them. Conditions questions need it, or "IF ON A STAR THEN
    PICK UP" is a step that never changes anything.
    """
    d = {"w": w, "h": h, "start": list(start)}
    if mustPick: d["mustPick"] = True
    if vars:     d["vars"] = dict(vars)
    if goal:    d["goal"] = list(goal)
    if walls:   d["walls"] = [list(x) for x in walls]
    if stars:   d["stars"] = [list(x) for x in stars]
    if key:     d["key"] = list(key)
    if door:    d["door"] = list(door)
    if program: d["program"] = list(program)
    return d


# ---------------------------------------------------------------- questions

def q(shape, prompt, hint, answer, visual=None, options=None,
      optionsText=None, blocks=None, slots=None, reusable=False,
      kind=None, criterion=None, expr=None, exprRaw=None, state=None,
      varName=None, traceOf=None, gapRow=None):
    """[kind] and [criterion] tell the validator what the question MEANS.

    Without them it has to guess from the wording, and a count question can
    mean "how many steps are listed", "how many more are needed" or "how many
    stars" — three different right answers for the same board.
    """
    o = {"shape": shape, "prompt": prompt, "hint": hint, "answer": answer}
    # Numbers are answered by tapping one of four, never by typing.
    if answer.get("type") == "number" and "choices" not in o:
        o["choices"] = number_choices(answer["value"])
    if kind:      o["kind"] = kind
    if criterion: o["criterion"] = criterion
    if expr:      o["expr"] = expr
    if exprRaw:   o["exprRaw"] = exprRaw
    if state:     o["state"] = dict(state)
    if varName:   o["varName"] = varName
    if traceOf:   o["traceOf"] = traceOf
    if gapRow is not None: o["gapRow"] = gapRow
    if visual:      o["visual"] = visual
    if options:     o["options"] = [list(x) for x in options]
    if optionsText: o["optionsText"] = list(optionsText)
    if blocks:      o["blocks"] = list(blocks)
    if slots:       o["slots"] = slots
    if reusable:    o["reusable"] = True
    return o


cell  = lambda x, y: {"type": "cell", "value": [x, y]}
opt   = lambda i:    {"type": "option", "value": i}
blk   = lambda i:    {"type": "block", "value": i}
num   = lambda n:    {"type": "number", "value": n}
yes   = lambda b:    {"type": "bool", "value": b}
order = lambda p:    {"type": "order", "value": list(p)}


def rep(times, body):
    """A loop: DO <times> TIMES over [body]. Nests freely."""
    return ["repeat:%d" % times] + list(body) + ["end"]


def number_choices(n, spread=None):
    """Four numbers to choose between, one of them [n].

    Tapping a choice beats typing on a pad: it is one gesture instead of two,
    it cannot be half-finished, and it costs no vertical space on a screen that
    is already carrying a board and a program listing.

    Distractors are the mistakes a child actually makes — one too many, one too
    few, and either double or half — rather than random numbers, so a right
    answer still has to be worked out rather than guessed by shape.
    """
    cands = [n - 1, n + 1, n + 2, n - 2, n * 2, n + 3]
    if spread:
        cands = list(spread) + cands
    out = []
    for c in cands:
        if c >= 0 and c != n and c not in out:
            out.append(c)
        if len(out) == 3:
            break
    while len(out) < 3:                       # tiny answers run out of room
        c = max(out or [n]) + 1
        if c != n and c not in out:
            out.append(c)
    return sorted(out + [n])


# ---------------------------------------------------------------- logic

def _tokenise(expr):
    out, i = [], 0
    while i < len(expr):
        c = expr[i]
        if c.isspace(): i += 1; continue
        if c in "()": out.append(c); i += 1; continue
        if expr[i:i+2] in (">=", "<="): out.append(expr[i:i+2]); i += 2; continue
        if c in "<>=": out.append(c); i += 1; continue
        j = i
        while j < len(expr) and (expr[j].isalnum() or expr[j] == "_"): j += 1
        if j == i: raise ValueError(f"bad character {c!r} in {expr!r}")
        out.append(expr[i:j]); i = j
    return out


def evaluate(expr, state):
    """Evaluates a child-readable condition against a set of facts.

    Grammar: NOT / AND / OR, parentheses, comparisons (> < = >= <=), names and
    numbers. Small on purpose — every condition a child sees has to be one they
    could check by hand.
    """
    toks = _tokenise(expr)
    pos = [0]

    def peek(): return toks[pos[0]] if pos[0] < len(toks) else None
    def take(): t = peek(); pos[0] += 1; return t

    def atom():
        t = take()
        if t == "(":
            v = or_expr()
            if take() != ")": raise ValueError("missing )")
            return v
        if t is not None and t.upper() == "NOT":
            return not atom()
        if t is None: raise ValueError("expression ended early")
        left = int(t) if t.lstrip("-").isdigit() else state[t]
        if peek() in (">", "<", "=", ">=", "<="):
            op = take()
            r = take()
            right = int(r) if r.lstrip("-").isdigit() else state[r]
            return {">": left > right, "<": left < right, "=": left == right,
                    ">=": left >= right, "<=": left <= right}[op]
        if isinstance(left, bool): return left
        raise ValueError(f"{t} is a number, not a yes/no")

    def and_expr():
        v = atom()
        while peek() is not None and peek().upper() == "AND":
            take(); v = atom() and v
        return v

    def or_expr():
        v = and_expr()
        while peek() is not None and peek().upper() == "OR":
            take(); v = and_expr() or v
        return v

    v = or_expr()
    if pos[0] != len(toks): raise ValueError(f"leftover tokens in {expr!r}")
    return bool(v)


def prettify(expr):
    """Turns a machine condition into something a nine-year-old reads.

    `on_star` is programmer syntax. On screen it has to say ON STAR, or the
    question is about decoding an identifier rather than about the logic.
    """
    out = []
    for tok in _tokenise(expr):
        if tok.upper() in ("AND", "OR", "NOT"):
            out.append(tok.upper())
        elif tok in "()<>=" or tok in (">=", "<="):
            out.append(tok)
        elif tok.lstrip("-").isdigit():
            out.append(tok)
        else:
            out.append(tok.replace("_", " ").upper())
    text = " ".join(out)
    return (text.replace("( ", "(").replace(" )", ")"))


def truth(prompt, hint, facts, expr, state, show=None):
    """A yes/no logic question with no board: facts on screen, one condition.

    [expr] is evaluated; what the child sees is [show], or a readable version of
    [expr]. Keeping the two apart means the validator can re-derive the answer
    from the real expression while the screen stays in plain words.
    """
    return q("truth", prompt, hint, yes(evaluate(expr, state)),
             optionsText=list(facts), expr=show or prettify(expr),
             exprRaw=expr, state=state)


# ---------------------------------------------------------------- computed

def ends(board, program=None):
    """Where the board's program finishes — as a cell answer."""
    prog = program if program is not None else board["program"]
    end, *_ = run(board, prog)
    return cell(end[0], end[1])


def ends_at(board, program=None):
    """Where the board's program finishes — as a raw [x, y]."""
    prog = program if program is not None else board["program"]
    return run(board, prog)[0]


def fails_at(board, program=None):
    """Index of the first step that cannot run — as a block answer."""
    prog = program if program is not None else board["program"]
    i = run(board, prog)[4]
    assert i >= 0, "nothing fails on this board — the question has no answer"
    return blk(i)


def step_count(board):
    """How many steps the listing shows."""
    return num(len(board["program"]))


def shortest_steps(board):
    """Fewest moves from start to goal, walls respected."""
    n = shortest(board)
    assert n is not None, "the goal is unreachable on this board"
    return num(n)


def shortest_winner(board, options):
    """Index of the shortest option that clears the board — asserts unique."""
    wins = [(len(o), i) for i, o in enumerate(options) if clears(board, o)]
    assert wins, "no option clears the board"
    wins.sort()
    assert len(wins) == 1 or wins[0][0] < wins[1][0],         f"two options tie for shortest: {wins[:2]}"
    return opt(wins[0][1])


def only_winner(board, options):
    """Index of the one option that clears the board — asserts it is unique."""
    wins = [i for i, o in enumerate(options) if clears(board, o)]
    assert len(wins) == 1, f"expected exactly one winning option, got {wins}"
    return opt(wins[0])


def same_end(board, a, b):
    """Do two programs finish on the same square?"""
    return yes(run(board, a)[0] == run(board, b)[0])


def stars_collected(board, program=None):
    """How many stars the program walks over — as a number answer."""
    prog = program if program is not None else board["program"]
    return num(len(run(board, prog)[1]))


def moves_made(board, program=None):
    """How many moves Nupo actually makes, loops unrolled and conditions run."""
    prog = program if program is not None else board["program"]
    return num(len(run(board, prog)[5]))


def rows(board, program=None):
    """How many rows the program listing shows, loop lines included."""
    prog = program if program is not None else board["program"]
    return num(len(prog))


def setv(name, value):
    """SET <name> = <value>."""
    return "set:%s:%d" % (name, value)


def addv(name, value):
    """ADD <value> to <name>."""
    return "add:%s:%d" % (name, value)


def box_value(board, name, program=None):
    """What ends up in a named box — as a number answer."""
    prog = program if program is not None else board["program"]
    return num(run(board, prog)[7][name])


def box_trace(board, name, program=None):
    """The value of a box after each row, for a trace table."""
    prog = program if program is not None else board["program"]
    tr = run(board, prog)[8]
    return [t.get(name, 0) for t in tr]


def trace_q(prompt, hint, board, name, gap_row):
    """A trace table with one row blank — the child works out that value.

    Flat programs only. The table shows one value per ROW, but a row inside a
    loop runs several times with a different value each time, so a looped
    program cannot be honestly drawn this way.
    """
    prog = board["program"]
    assert not any(t.startswith("repeat:") or t in ("end", "else") for t in prog),         "a trace table cannot show a program with a loop in it"
    vals = box_trace(board, name)
    rows = len(board["program"])
    # trace[0] is the value before anything ran; the table shows one value per
    # row, so drop that first entry.
    shown = vals[1:rows + 1]
    assert 0 <= gap_row < len(shown), f"gap row {gap_row} outside {len(shown)} rows"
    return q("trace", prompt, hint, num(shown[gap_row]), visual=board,
             varName=name, traceOf=shown, gapRow=gap_row)


def route(board, program):
    """Assert a program clears the board, and return it as an order answer."""
    assert clears(board, program), f"{program} does not clear this board"
    return order(program)


# ================================================================ concrete
#
# Everything below exists to replace the abstract logic questions. "Is this
# true or false?" asked a child to evaluate a condition in the air, with no
# board and nothing at stake — thirty-seven times, word for word. A condition
# is worth teaching as something that happens ON the board: the step runs or
# it is skipped, and the child can see which.

def yesno(prompt, hint, board, ask, program=None):
    """A question about what the run actually did. Answer is Yes or No.

    [ask] is one of:
      flag  - does he finish on the flag?
      star  - does he pick up every star?
      door  - does he get through the door?
      stuck - does any step fail?

    The answer is worked out by running the program, never typed, so a board
    edited later cannot leave a stale Yes behind.
    """
    prog = program if program is not None else board["program"]
    end, stars, keys, doors, failed, moves = run(board, prog)[:6]
    if ask == "flag":
        yes = board.get("goal") is not None and list(end) == list(board["goal"])
    elif ask == "star":
        yes = len(stars) == len(board.get("stars") or [])
    elif ask == "door":
        yes = bool(doors)
    elif ask == "stuck":
        yes = failed >= 0
    else:
        raise ValueError(f"unknown yes/no question: {ask}")
    return q("yesno", prompt, hint, {"type": "bool", "value": bool(yes)},
             visual=dict(board, program=prog),
             criterion={"flag": "reachesFlag", "star": "allStars",
                        "door": "throughDoor", "stuck": "anyStepFails"}[ask])


def skipped_step(prompt, hint, board, program=None):
    """Which row does NOT run, because its condition was false.

    Concrete where "when is the step inside an IF skipped?" was not: the child
    points at the step on this screen that will not happen.
    """
    prog = program if program is not None else board["program"]
    # origin[] is the program row each move came from, so the rows that never
    # appear are the rows that never ran.
    ran = set(run(board, prog)[6])
    inside = [i for i, t in enumerate(prog)
              if not t.startswith(("repeat:", "if:")) and t not in ("end", "else")]
    missed = [i for i in inside if i not in ran]
    if len(missed) != 1:
        raise ValueError(f"{len(missed)} steps are skipped; the answer must be one")
    return q("spot", prompt, hint, blk(missed[0]),
             visual=dict(board, program=prog), criterion="skipped")


def can_move(prompt, hint, board, direction):
    """Can Nupo step that way from where he is standing? Yes or No.

    This is what a wall check MEANS, asked so a child can answer it by looking.
    "Is wall_above true?" needed them to hold a fact in their head; "can he
    move up from here?" needs them to look one square up. Edges count as
    blocked, which is also what they look like.
    """
    from validate import sense
    blocked = sense("wall-" + direction, tuple(board["start"]), board, False, set())
    return q("yesno", prompt, hint, {"type": "bool", "value": not blocked},
             visual={k: v for k, v in board.items() if k != "program"},
             criterion="canMove:" + direction)


def standing_on(prompt, hint, board, what):
    """Is Nupo on a star / holding the key / at the door, right now?

    [what] is "star" or "door" — the two the child can settle by looking. "key"
    is deliberately not offered: that sensor asks whether he is CARRYING one,
    which before a program runs is always no, so it would be a question with a
    fixed answer dressed up as a real one.
    """
    from validate import sense
    if what not in ("star", "door"):
        raise ValueError(f"{what} cannot be seen on the board before the run")
    v = sense(what, tuple(board["start"]), board, False,
              {tuple(c) for c in board.get("stars", [])})
    return q("yesno", prompt, hint, {"type": "bool", "value": bool(v)},
             visual={k: v2 for k, v2 in board.items() if k != "program"},
             criterion="standingOn:" + what)


def ran_step(prompt, hint, board, program=None):
    """Which of the two branch steps actually happens.

    The mirror of skipped_step, and the better question for IF/ELSE: a child
    who knows which road was taken knows which one was not.
    """
    prog = program if program is not None else board["program"]
    ran = set(run(board, prog)[6])
    inside = [i for i, t in enumerate(prog)
              if not t.startswith(("repeat:", "if:")) and t not in ("end", "else")]
    did = [i for i in inside if i in ran]
    if len(did) != 1:
        raise ValueError(f"{len(did)} steps run; the answer must be exactly one")
    return q("spot", prompt, hint, blk(did[0]),
             visual=dict(board, program=prog), criterion="ran")


def checks_made(board, program=None):
    """How many times the condition was looked at, fired or not."""
    prog = program if program is not None else board["program"]
    return num(len(run(board, prog)[10]))


def checks_fired(board, program=None):
    """How many of those looks came back yes.

    The pair of these is the whole of 'checked a lot, done rarely' — an idea
    that had been taught by asserting it in a teach line and then asking about
    stars instead.
    """
    prog = program if program is not None else board["program"]
    return num(sum(1 for _, v in run(board, prog)[10] if v))
