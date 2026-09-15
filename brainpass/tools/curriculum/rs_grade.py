# -*- coding: utf-8 -*-
"""Derives every Reasoning answer a SECOND time, from the picture alone.

Shares no code with reasoning_kit.py. Where the kit folds a net by rolling a set
of face labels, this folds it with 3D vectors. Where the kit rolls a dice by
swapping named faces, this rotates normals. Where the kit generates a sequence
from the rule the author chose, this is never told the rule: it fits every
family of rule it knows to the numbers on screen, and fails the question unless
every family that fits agrees on the answer. That last check is also the
fairness check -- a pattern two different rules explain is a pattern with two
right answers.
"""
import itertools, json, os, sys
from fractions import Fraction as F

HERE = os.path.dirname(os.path.abspath(__file__))
PATH = os.path.join(HERE, "..", "..", "assets", "curriculum_pending", "reasoning.json")

FAILS, COUNT = [], {}


def bad(qid, msg):
    FAILS.append(f"{qid}: {msg}")


# ============================================================ sequences

def _poly(known, deg):
    """Fit a degree-[deg] polynomial in the position, only if over-determined."""
    if len(known) < deg + 2:
        return None
    pts = known[:deg + 1]

    def f(x):
        tot = F(0)
        for i, (xi, yi) in enumerate(pts):
            term = F(yi)
            for j, (xj, _) in enumerate(pts):
                if j != i:
                    term *= F(x - xj, xi - xj)
            tot += term
        return tot
    return f if all(f(x) == y for x, y in known) else None


def _geometric(known):
    if len(known) < 3 or any(y == 0 for _, y in known):
        return None
    pairs = [(a, b) for a, b in zip(known, known[1:]) if b[0] == a[0] + 1]
    if not pairs:
        return None
    r = F(pairs[0][1][1], pairs[0][0][1])
    x0, y0 = known[0]
    f = lambda x: F(y0) * r ** (x - x0)
    return f if all(f(x) == y for x, y in known) else None


def _iterative(terms):
    """Families defined step by step. Returns predictors for a full list."""
    out = []
    n = len(terms)
    gap = [i for i, t in enumerate(terms) if t is None]
    g = gap[0] if gap else None

    def fill(x):
        return [x if i == g else t for i, t in enumerate(terms)]

    cands = {None} if g is None else set()
    if g is not None:                       # every value a neighbouring rule implies
        for i in range(n - 1):
            a, b = terms[i], terms[i + 1]
            if a is not None and b is not None:
                d, rr = b - a, (F(b, a) if a else None)
                if g > 0 and terms[g - 1] is not None:
                    cands.add(terms[g - 1] + d)
                    if rr is not None:
                        cands.add(F(terms[g - 1]) * rr)
        if 1 < g < n and terms[g - 1] is not None and terms[g - 2] is not None:
            cands.add(terms[g - 1] + terms[g - 2])
        if g + 2 < n and terms[g + 1] is not None and terms[g + 2] is not None:
            cands.add(terms[g + 2] - terms[g + 1])

    # sum of the two before
    for x in cands:
        t = fill(x)
        if all(t[i] == t[i - 1] + t[i - 2] for i in range(2, n)) and n - 2 >= 3:
            out.append(("sum2", t, lambda seq: seq[-1] + seq[-2]))
            break

    # two operations taking turns, each an add or a times
    def op_of(samples):
        if len(samples) < 2:
            return None
        ds = {b - a for a, b in samples}
        if len(ds) == 1:
            d = ds.pop()
            return lambda v, d=d: v + d
        if all(a != 0 for a, _ in samples):
            rs = {F(b, a) for a, b in samples}
            if len(rs) == 1:
                r = rs.pop()
                return lambda v, r=r: v * r
        return None

    for x in cands:
        t = fill(x)
        ops = [op_of([(t[i], t[i + 1]) for i in range(p, n - 1, 2)]) for p in (0, 1)]
        if all(ops):
            out.append(("alternate", t, ops))
            break
    return out


def predict(terms, position=None, value=None):
    """Every answer each fitting family gives. Positions are 1-based."""
    gap = [i for i, t in enumerate(terms) if t is None]
    known = [(i + 1, F(t)) for i, t in enumerate(terms) if t is not None]
    answers = {}
    target = gap[0] + 1 if gap else position
    for name, f in [("linear", _poly(known, 1)), ("quadratic", _poly(known, 2)),
                    ("cubic", _poly(known, 3)), ("geometric", _geometric(known))]:
        if f is None:
            continue
        if value is not None:
            hit = next((p for p in range(1, 3000) if f(p) == value), None)
            if hit is not None:
                answers[name] = hit
        else:
            answers[name] = f(target)
    for name, t, rule in _iterative(terms):
        seq = [F(v) for v in t]
        if value is not None:
            ops = rule
            k = len(seq)
            while k < 3000 and value not in seq:
                seq.append(ops[(k - 1) % 2](seq[-1]) if name == "alternate" else rule(seq))
                k += 1
            if value in seq:
                answers[name] = seq.index(value) + 1
        else:
            while len(seq) < target:
                seq.append(rule[(len(seq) - 1) % 2](seq[-1]) if name == "alternate" else rule(seq))
            answers[name] = seq[target - 1]
    return answers


def rule_seq(r, t0, t1, n):
    t = r["t"]
    if t == "add":
        return [F(t0 + r["k"] * i) for i in range(n)]
    if t == "mul":
        return [F(t0) * F(r["k"]) ** i for i in range(n)]
    if t == "grow":
        out, v, s = [F(t0)], F(t0), r["step"]
        for _ in range(n - 1):
            v += s; out.append(v); s += r["inc"]
        return out
    if t == "sum2":
        out = [F(t0), F(t1)]
        while len(out) < n:
            out.append(out[-1] + out[-2])
        return out
    if t == "pos":
        return [F(r["a"] * p + r["b"]) for p in range(1, n + 1)]
    if t == "sq":
        return [F(p * p + r["b"]) for p in range(1, n + 1)]
    if t == "cube":
        return [F(p ** 3 + r["b"]) for p in range(1, n + 1)]
    if t == "alt":
        out, v = [F(t0)], F(t0)
        for i in range(n - 1):
            o, k = r["ops"][i % 2]
            v = v + k if o == "add" else v * k
            out.append(v)
        return out
    raise ValueError(t)


# ============================================================ logic

def lit(world, atom, val):
    return world[atom] == val


def settle(rules, facts, ask):
    atoms = sorted({r[0] for r in rules} | {r[2] for r in rules} |
                   {f[0] for f in facts} | {ask})
    vals = set()
    for combo in itertools.product([0, 1], repeat=len(atoms)):
        w = {a: bool(v) for a, v in zip(atoms, combo)}
        facts_ok = all(lit(w, a, v) for a, v in facts)
        rules_ok = all((not lit(w, a, av)) or lit(w, b, bv) for a, av, b, bv in rules)
        if facts_ok and rules_ok:
            vals.add(w[ask])
    return vals


def in_class(n, cls):
    if cls == "odd": return n % 2 == 1
    if cls == "even": return n % 2 == 0
    if cls == "sq": return int(round(n ** 0.5)) ** 2 == n
    return n % int(cls[1:]) == 0


def members(cls, count=60):
    out, n = [], 1
    while len(out) < count:
        if in_class(n, cls):
            out.append(n)
        n += 1
    return out


def claim_answer(c):
    A = members(c["a"])
    if c["op"] == "is":
        vals = A
    elif c["op"] == "double":
        vals = [a + a for a in A]
    elif c["op"] == "square":
        vals = [a * a for a in A]
    else:
        B = members(c["b"])
        vals = [a + b if c["op"] == "plus" else a * b for a in A for b in B]
    hits = [in_class(v, c["is"]) for v in vals]
    return 0 if all(hits) else 2 if not any(hits) else 1


def arrangements(people, things, clues):
    out = []
    for perm in itertools.permutations(things):
        has = dict(zip(people, perm))
        ok = True
        for c in clues:
            if c["t"] == "has": ok = has[c["p"]] == c["x"]
            elif c["t"] == "not": ok = has[c["p"]] != c["x"]
            elif c["t"] == "either": ok = c["x"] in (has[c["ps"][0]], has[c["ps"][1]])
            elif c["t"] == "neither": ok = c["x"] not in (has[c["ps"][0]], has[c["ps"][1]])
            if not ok:
                break
        if ok:
            out.append(has)
    return out


# ============================================================ space

def fold3d(cells):
    """Fold with 3D frames: each square carries (east, south, outward normal)."""
    cells = [tuple(c) for c in cells]
    s = set(cells)
    neg = lambda v: tuple(-x for x in v)
    frames = {cells[0]: ((1, 0, 0), (0, 1, 0), (0, 0, -1))}
    stack = [cells[0]]
    while stack:
        u = stack.pop()
        e, so, n = frames[u]
        for (dx, dy), nf in (((1, 0), (neg(n), so, e)), ((-1, 0), (n, so, neg(e))),
                             ((0, 1), (e, neg(n), so)), ((0, -1), (e, n, neg(so)))):
            v = (u[0] + dx, u[1] + dy)
            if v not in s:
                continue
            if v in frames:
                if frames[v] != nf:
                    return None
            else:
                frames[v] = nf
                stack.append(v)
    if len(frames) != 6:
        return None
    normals = {c: frames[c][2] for c in cells}
    return normals if len(set(normals.values())) == 6 else None


def roll3d(top, front, right, moves):
    face = {(0, 0, 1): top, (0, 0, -1): 7 - top, (0, 1, 0): front,
            (0, -1, 0): 7 - front, (1, 0, 0): right, (-1, 0, 0): 7 - right}
    turn = {"right": lambda x, y, z: (z, y, -x), "left": lambda x, y, z: (-z, y, x),
            "up": lambda x, y, z: (x, -z, y), "down": lambda x, y, z: (x, z, -y)}
    for m in moves:
        face = {turn[m](*nrm): v for nrm, v in face.items()}
    return face[(0, 0, 1)]


# ============================================================ grading

def grade(qid, q):
    sh, p = q["shape"], q.get("pic") or {}
    a = q["answer"]["value"]
    COUNT[sh] = COUNT.get(sh, 0) + 1
    opts = q.get("optionsText")

    if sh in ("sequence", "nthTerm", "termPosition"):
        got = predict(p["terms"], p.get("askPosition"), p.get("askValue"))
        if not got:
            return bad(qid, "no rule family explains these numbers")
        vals = set(got.values())
        if len(vals) != 1:
            return bad(qid, f"two rules fit and disagree: {got}")
        if vals.pop() != a:
            bad(qid, f"the numbers give {got}, stored {a}")

    elif sh == "seqRule":
        t = p["terms"]
        fits = [i for i, r in enumerate(q["optionRules"])
                if rule_seq(r, t[0], t[1], len(t)) == [F(v) for v in t]]
        if fits != [a]:
            bad(qid, f"rules that fit: {fits}, stored {a}")

    elif sh == "ifThen":
        vals = settle(p["rules"], p["facts"], p["ask"])
        want = 0 if vals == {True} else 1 if vals == {False} else 2
        if not vals:
            return bad(qid, "the clues contradict each other")
        if want != a or opts[2] != "You cannot tell.":
            bad(qid, f"the clues settle it as option {want}, stored {a}")

    elif sh == "claim":
        if claim_answer(p["claim"]) != a:
            bad(qid, f"checking the numbers gives option {claim_answer(p['claim'])}, stored {a}")

    elif sh == "deduce":
        sols = arrangements(p["people"], p["things"], p["clues"])
        if len(sols) != 1:
            return bad(qid, f"{len(sols)} arrangements fit")
        if p.get("who"):
            want = next(x for x in p["people"] if sols[0][x] == p["who"])
        else:
            want = "The " + f"{sols[0][p['what']]} {p['noun']}".strip()
        if [i for i, o in enumerate(opts) if o == want] != [a]:
            bad(qid, f"the answer is {want}, stored option {a}")

    elif sh == "binaryRead":
        total = sum(v for v, on in zip(p["values"], p["on"]) if on)
        if total != a:
            bad(qid, f"the lit bulbs add to {total}, stored {a}")

    elif sh == "binaryPick":
        vals = p["values"]
        target = p["target"] if p["kind"] == "binaryAsk" else \
            sum(v for v, on in zip(vals, p["on"]) if on) + p.get("askPlus", 0)
        hits = [i for i, bits in enumerate(q["optionBits"])
                if sum(v for v, on in zip(vals, bits) if on) == target]
        if hits != [a]:
            bad(qid, f"rows showing {target}: {hits}, stored {a}")

    elif sh in ("cipher", "cipherWrite"):
        k = p["shift"] if sh == "cipherWrite" else -p["shift"]
        want = "".join(chr((ord(ch) - 65 + k) % 26 + 65) for ch in p["word"])
        if [i for i, o in enumerate(opts) if o == want] != [a]:
            bad(qid, f"shifting gives {want}, stored option {a}")

    elif sh == "symbolCode":
        key = {(e["glyph"], e["color"]): e["letter"] for e in p["key"]}
        want = "".join(key[(g["glyph"], g["color"])] for g in p["word"])
        if [i for i, o in enumerate(opts) if o == want] != [a]:
            bad(qid, f"the key spells {want}, stored option {a}")

    elif sh == "letterCode":
        want = "".join(chr(64 + n) for n in p["codes"])
        if [i for i, o in enumerate(opts) if o == want] != [a]:
            bad(qid, f"the numbers spell {want}, stored option {a}")

    elif sh == "letterSum":
        if sum(ord(ch) - 64 for ch in p["word"]) != a:
            bad(qid, "the letters add to something else")

    elif sh == "netFace":
        nrm = fold3d(p["cells"])
        if nrm is None:
            return bad(qid, "the net does not fold")
        cells = [tuple(c) for c in p["cells"]]
        t = cells[p["marks"].index(p["target"])]
        opp = next(c for c in cells if nrm[c] == tuple(-x for x in nrm[t]))
        want = p["marks"][cells.index(opp)]
        if [i for i, o in enumerate(q["optionCells"]) if o["kind"] == want] != [a]:
            bad(qid, f"folding puts the {want} opposite, stored option {a}")

    elif sh == "netPick":
        folds = [fold3d(n) is not None for n in q["optionNets"]]
        want = [i for i, f in enumerate(folds) if f == bool(q["askFolds"])]
        if want != [a]:
            bad(qid, f"nets that fit the question: {want}, stored {a}")

    elif sh == "roll":
        got = roll3d(p["top"], p["front"], p["right"], p["moves"])
        if got != a:
            bad(qid, f"rolling gives {got} on top, stored {a}")

    elif sh in ("stackCount", "stackFill", "stackView"):
        hs = p["heights"]
        d, w = len(hs), len(hs[0])
        for y in range(d):
            for x in range(w):
                if (y + 1 < d and hs[y + 1][x] > hs[y][x]) or (x + 1 < w and hs[y][x + 1] > hs[y][x]):
                    return bad(qid, "a column could hide cubes behind it")
        cubes = sum(sum(r) for r in hs)
        if sh == "stackCount" and cubes != a:
            bad(qid, f"there are {cubes} cubes, stored {a}")
        if sh == "stackFill":
            fw, fd, fh = p["full"]
            if fw * fd * fh - cubes != a:
                bad(qid, f"{fw * fd * fh - cubes} more are needed, stored {a}")
        if sh == "stackView":
            if p["side"] == "front":
                want = [max(hs[y][x] for y in range(d)) for x in range(w)]
            else:
                want = [max(hs[y][x] for x in range(w)) for y in range(d - 1, -1, -1)]
            if [i for i, v in enumerate(q["optionViews"]) if v == want] != [a]:
                bad(qid, f"the {p['side']} view is {want}, stored option {a}")
    else:
        bad(qid, f"no independent check for {sh}")


def self_test():
    """This file's folding must agree with known mathematics, not with the kit."""
    shapes = {((0, 0),)}
    for _ in range(5):
        nxt = set()
        for sh in shapes:
            ss = set(sh)
            for x, y in sh:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    c = (x + dx, y + dy)
                    if c not in ss:
                        pts = ss | {c}
                        mx, my = min(q[0] for q in pts), min(q[1] for q in pts)
                        nxt.add(tuple(sorted((q[0] - mx, q[1] - my) for q in pts)))
        shapes = nxt

    def free(pts):
        best = None
        for _ in range(4):
            pts = [(y, -x) for x, y in pts]
            for v in (pts, [(-x, y) for x, y in pts]):
                mx, my = min(q[0] for q in v), min(q[1] for q in v)
                t = tuple(sorted((q[0] - mx, q[1] - my) for q in v))
                best = t if best is None or t < best else best
        return best
    nets = {free(list(sh)) for sh in shapes if fold3d(sh)}
    if len(nets) != 11:
        sys.exit(f"fold3d finds {len(nets)} cube nets; there are 11. Grader is wrong.")
    if roll3d(1, 2, 3, ["right"] * 4) != 1:
        sys.exit("roll3d does not return to the start after four rolls. Grader is wrong.")


def main():
    self_test()
    d = json.load(open(PATH, encoding="utf-8"))
    n = 0
    for sec in d["sections"]:
        for u in sec["units"]:
            for st in u["stops"]:
                for i, q in enumerate(st["questions"]):
                    grade(f"{st['id']}#{i}", q)
                    n += 1
    for s, c in sorted(COUNT.items()):
        print(f"  {s:<13} {c:>3}")
    if FAILS:
        print()
        for f in FAILS[:50]:
            print("  FAIL", f)
        print(f"\n{len(FAILS)} of {n} answers disagree")
        sys.exit(1)
    print(f"\nevery answer is correct  ({n} re-derived from the picture; "
          f"fold checked against the 11 known cube nets)")


if __name__ == "__main__":
    main()
