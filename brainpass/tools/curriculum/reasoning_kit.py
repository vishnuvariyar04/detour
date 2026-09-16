# -*- coding: utf-8 -*-
"""Authoring kit for Reasoning — the band d skill, ages 11-12.

Every answer that follows from the picture is COMPUTED here, by an engine that
does the reasoning, never typed beside it: a sequence is generated from its rule,
a logic answer comes from enumerating every possible world, a net is folded by
rolling a cube across it, a dice is rolled, a stack is counted cube by cube.
rs_grade.py then derives each answer again with separate code.

Pitched above band c on purpose, and measurably. Think Like a Coder's hardest
questions trace a list of up to ten steps and never ask for a number above 20.
This skill asks for the hundredth term of a pattern without writing out the
ninety-nine before it, for what must follow from a rule when the tempting answer
is a fallacy, and for the face of a cube that has only ever been seen flat.

The wrong options are never random. Each one is a specific mistake a child of
this age actually makes -- extending a times-pattern as if it were an adding
pattern, affirming the consequent, reading bulbs as digits, counting only the
cubes you can see -- so an answer cannot be reached by eliminating nonsense.
"""
import hashlib
import itertools
import json
from fractions import Fraction

STAR, HEART, CIRCLE, SQUARE = "star", "heart", "circle", "square"
TRIANGLE, DIAMOND, HEXAGON, FLOWER = "triangle", "diamond", "hexagon", "flower"
GLYPHS = [STAR, HEART, CIRCLE, SQUARE, TRIANGLE, DIAMOND, HEXAGON, FLOWER]
PRIMARY, ACCENT = "primary", "accent"


def cell(kind, color=PRIMARY, rotation=0):
    return {"kind": kind, "color": color, "rotation": rotation}


def _seed(*parts):
    blob = json.dumps(parts, sort_keys=True, ensure_ascii=False, default=str)
    return int(hashlib.sha256(blob.encode("utf-8")).hexdigest()[:8], 16)


def _q(shape, prompt, hint, pic, answer, **extra):
    q = {"shape": shape, "prompt": prompt, "hint": hint, "pic": pic,
         "answer": answer}
    q.update(extra)
    return q


def _rotate(q, fields, seed):
    """Move the right answer off a fixed slot, keeping parallel lists aligned.

    The shipped coder skill puts every number answer in the second slot, 100% of
    93, so a child tapping it passes without reading. Band b fixed its own copy of
    that; band d never has it.
    """
    n = len(q[fields[0]])
    k = seed % n
    for f in fields:
        lst = q[f]
        q[f] = [lst[(i - k) % n] for i in range(n)]
    q["answer"]["value"] = (q["answer"]["value"] + k) % n
    return q


def _numbers(ans, mistakes, seed, lo=None, allowed=None):
    """Number choices, plus what emit needs to move the answer to a given slot."""
    return {"choices": choices4(ans, mistakes, seed, lo, allowed=allowed),
            "_pool": {"mistakes": list(mistakes), "lo": lo,
                      "allowed": sorted(allowed) if allowed else None}}


def choices4(ans, mistakes, seed, lo=None, k=None, allowed=None):
    """Four ascending numbers: the answer and three specific mistakes.

    Real mistakes are placed before invented near misses, and the answer goes in
    the slot asked for, so slots stay balanced across a question type. Where a
    question only has a few sensible numbers at all -- the sides of a cut face
    are 3, 4, 5, 6 or 8, never 7 or 9 -- [allowed] limits every option to that
    set and the slot is chosen among what the set can fill.
    """
    real = []
    for m in mistakes:
        if isinstance(m, Fraction):
            if m.denominator != 1:
                continue
            m = int(m)
        if m != ans and m not in real and (lo is None or m >= lo) and \
           (allowed is None or m in allowed):
            real.append(m)
    want = seed % 4 if k is None else k
    if allowed is not None:
        rb = [c for c in real if c < ans]
        ra = [c for c in real if c > ans]
        feasible = [j for j in range(4) if len(rb) >= j and len(ra) >= 3 - j]
        if not feasible:
            raise ValueError(f"the allowed numbers cannot make four options round {ans}")
        j = min(feasible, key=lambda f: (abs(f - want), f))
        return sorted((rb[len(rb) - j:] if j else []) + [ans] + ra[:3 - j])
    pad, step = [], 1
    while len(pad) < 8:
        for c in (ans + step, ans - step):
            if c != ans and c not in real and c not in pad and (lo is None or c >= lo):
                pad.append(c)
        step += 1
    below = [c for c in real if c < ans] + [c for c in pad if c < ans]
    above = [c for c in real if c > ans] + [c for c in pad if c > ans]
    j = want
    if len(below) < j:
        j = len(below)
    if len(above) < 3 - j:
        j = 3 - len(above)
    return sorted(below[:j] + [ans] + above[:3 - j])


# ============================================================ sequences

def arith(a, d, n):
    return [a + d * i for i in range(n)]


def geom(a, r, n):
    out, v = [], Fraction(a)
    for _ in range(n):
        if v.denominator != 1:
            raise ValueError(f"geometric term {v} is not a whole number")
        out.append(int(v))
        v *= Fraction(r)
    return out


def grow(a, first_step, inc, n):
    """Differences that grow: a, a+s, a+s+(s+inc), ..."""
    out, v, s = [a], a, first_step
    for _ in range(n - 1):
        v += s
        out.append(v)
        s += inc
    return out


def sum2(a, b, n):
    out = [a, b]
    while len(out) < n:
        out.append(out[-1] + out[-2])
    return out[:n]


def alternate(a, ops, n):
    """Apply ops in turn: ops like [("add", 3), ("mul", 2)]."""
    out, v = [a], a
    i = 0
    while len(out) < n:
        op, k = ops[i % len(ops)]
        v = v + k if op == "add" else v * k
        out.append(v)
        i += 1
    return out


def by_position(f, n, start=1):
    return [f(p) for p in range(start, start + n)]


def _sequence_mistakes(terms, gap):
    """The wrong numbers a child actually reaches for."""
    ans = terms[gap]
    out = []
    if gap >= 2:
        p1, p2 = terms[gap - 1], terms[gap - 2]
        out.append(p1 + (p1 - p2))          # carried the last difference on
        out.append(ans + (p1 - p2))
        out.append(ans - (p1 - p2))
    if 0 < gap < len(terms) - 1:
        a, b = terms[gap - 1], terms[gap + 1]
        if (a + b) % 2 == 0:
            out.append((a + b) // 2)        # took the middle of the neighbours
    if gap + 2 < len(terms):
        n1, n2 = terms[gap + 1], terms[gap + 2]
        out.append(n1 - (n2 - n1))
    out += [ans + 1, ans - 1]
    return out


def sequence(prompt, terms, gap, hint=None, extra_mistakes=()):
    """A run of numbers with one hidden. At least five are always shown.

    Five, because with fewer a pattern stops having one defensible rule: 1, 2, 4
    is doubling to an adult and adding one more each time to a lot of children,
    and both are right. rs_grade.py fits every rule family to the shown numbers
    and fails the question unless all the families that fit agree on the gap.
    """
    shown = [None if i == gap else t for i, t in enumerate(terms)]
    if sum(t is not None for t in shown) < 5:
        raise ValueError("a sequence needs at least five numbers shown")
    ans = terms[gap]
    seed = _seed(prompt, shown)
    return _q("sequence", prompt,
              hint or "Look at how each number becomes the next.",
              {"kind": "sequence", "terms": shown, "gapAt": gap},
              {"type": "number", "value": ans},
              **_numbers(ans, list(extra_mistakes) +
                               _sequence_mistakes(terms, gap), seed))


def nth_term(prompt, a, d, shown_count, position, hint=None):
    """An adding pattern, and the term at a far position.

    The answer is a + d(n-1). The mistakes are the two ways children get the
    formula wrong -- forgetting the start (d x n) and counting one step too many
    (a + d x n) -- plus writing it out and slipping by one step.
    """
    if f"{position}" not in prompt:
        raise ValueError(f"the prompt does not name position {position}")
    terms = arith(a, d, shown_count)
    ans = a + d * (position - 1)
    seed = _seed(prompt, terms, position)
    return _q("nthTerm", prompt,
              hint or "How many steps are there from the 1st term to that one?",
              {"kind": "sequence", "terms": terms, "askPosition": position},
              {"type": "number", "value": ans},
              **_numbers(ans, [d * position, a + d * position,
                                     a + d * (position - 2), ans + 1], seed))


def nth_poly(prompt, f, shown_count, position, mistakes, hint=None):
    """The term at a far position of a square, cube or triangle pattern.

    [mistakes] are passed per question because the tempting wrong answer depends
    on the pattern: for the 12th square number it is 12 x 2 = 24, and the squares
    either side; for triangle numbers it is position x 10.
    """
    if f"{position}" not in prompt:
        raise ValueError(f"the prompt does not name position {position}")
    terms = by_position(f, shown_count)
    ans = f(position)
    seed = _seed(prompt, terms, position)
    return _q("nthTerm", prompt, hint or "What does the position do to make each number?",
              {"kind": "sequence", "terms": terms, "askPosition": position},
              {"type": "number", "value": ans},
              **_numbers(ans, list(mistakes), seed))


def term_position(prompt, a, d, shown_count, position, hint=None):
    """The same pattern read backwards: which term is this number?"""
    if d == 0:
        raise ValueError("a flat pattern has no single position for a value")
    terms = arith(a, d, shown_count)
    value = a + d * (position - 1)
    if f"{value}" not in prompt:
        raise ValueError(f"the prompt asks about the wrong number; this one is {value}")
    seed = _seed(prompt, terms, value)
    guess = Fraction(value, d)
    return _q("termPosition", prompt,
              hint or "Take away the first term, then count the steps.",
              {"kind": "sequence", "terms": terms, "askValue": value},
              {"type": "number", "value": position},
              **_numbers(position, [position - 1, position + 1, guess,
                                          Fraction(value - a, d)], seed, lo=1))


def rule_text(r):
    t = r["t"]
    if t == "add":
        return f"Add {r['k']} each time" if r["k"] > 0 else f"Take away {-r['k']} each time"
    if t == "mul":
        k = Fraction(r["k"])
        if k == 2:
            return "Double each time"
        if k == Fraction(1, 2):
            return "Halve each time"
        return f"Times {k} each time"
    if t == "grow":
        s = r["step"]
        return f"Add {s}, then {s + r['inc']}, then {s + 2 * r['inc']}..."
    if t == "sum2":
        return "Add the two numbers before"
    if t == "pos":
        return f"{r['a']} times the position, add {r['b']}" if r["b"] >= 0 \
            else f"{r['a']} times the position, take {-r['b']}"
    if t == "sq":
        return "The position squared" if r["b"] == 0 else \
            (f"Position squared, add {r['b']}" if r["b"] > 0
             else f"Position squared, take {-r['b']}")
    if t == "cube":
        return "The position cubed" if r["b"] == 0 else \
            (f"Position cubed, add {r['b']}" if r["b"] > 0 else f"Position cubed, take {-r['b']}")
    if t == "alt":
        (o1, k1), (o2, k2) = r["ops"]
        w = lambda o, k: f"add {k}" if o == "add" else ("double" if k == 2 else f"times {k}")
        return f"{w(o1, k1).capitalize()}, then {w(o2, k2)}, repeat"
    raise ValueError(t)


def rule_terms(r, first_terms, n):
    """Generate n terms from a rule, seeded from the shown start where needed."""
    t = r["t"]
    if t == "add":
        return arith(first_terms[0], r["k"], n)
    if t == "mul":
        return geom(first_terms[0], Fraction(r["k"]), n)
    if t == "grow":
        return grow(first_terms[0], r["step"], r["inc"], n)
    if t == "sum2":
        return sum2(first_terms[0], first_terms[1], n)
    if t == "pos":
        return by_position(lambda p: r["a"] * p + r["b"], n)
    if t == "sq":
        return by_position(lambda p: p * p + r["b"], n)
    if t == "cube":
        return by_position(lambda p: p ** 3 + r["b"], n)
    if t == "alt":
        return alternate(first_terms[0], r["ops"], n)
    raise ValueError(t)


def seq_rule(prompt, terms, rules, hint=None):
    """Which rule makes this pattern. rules[0] is the true one.

    The wrong rules are chosen to fit the FIRST step or two and then break, which
    is the trap: a child who checks one step instead of all of them picks one.
    The kit refuses a set where more than one rule fits every shown number.
    """
    fits = []
    for i, r in enumerate(rules):
        try:
            if rule_terms(r, terms, len(terms)) == terms:
                fits.append(i)
        except ValueError:
            pass
    if fits != [0]:
        raise ValueError(f"rules fitting the pattern: {fits}; need exactly the first")
    if len(terms) < 5:
        raise ValueError("show at least five numbers")
    q = _q("seqRule", prompt, hint or "Check the rule against every step, not just the first.",
           {"kind": "sequence", "terms": terms},
           {"type": "option", "value": 0},
           optionsText=[rule_text(r) for r in rules], optionRules=rules)
    return _rotate(q, ["optionsText", "optionRules"], _seed(prompt, terms))


# ============================================================ logic: if-then

ATOMS = {
    "star": ("has a star", "has no star"),
    "purple": ("is purple", "is not purple"),
    "big": ("is big", "is not big"),
    "spots": ("has spots", "has no spots"),
    "stripe": ("has a stripe", "has no stripe"),
    "shiny": ("is shiny", "is not shiny"),
}
CANT_TELL = "You cannot tell."


def lit(atom, val):
    return ATOMS[atom][0 if val else 1]


def rule_sentence(r):
    a, av, b, bv = r
    return f"If a card {lit(a, av)}, it {lit(b, bv)}."


def fact_sentence(f):
    return f"This card {lit(*f)}."


def must(rules, facts, atom):
    """True, False, or None if the rules and facts do not settle [atom]."""
    atoms = sorted({x for r in rules for x in (r[0], r[2])} |
                   {f[0] for f in facts} | {atom})
    seen = set()
    for vals in itertools.product((False, True), repeat=len(atoms)):
        w = dict(zip(atoms, vals))
        if all(w[f[0]] == f[1] for f in facts) and \
           all((not (w[r[0]] == r[1])) or (w[r[2]] == r[3]) for r in rules):
            seen.add(w[atom])
    if not seen:
        raise ValueError("these clues contradict each other")
    return seen.pop() if len(seen) == 1 else None


def if_then(prompt, rules, facts, ask, hint=None):
    """Rules, facts, and one question about a card.

    Options always read in the same order -- it has it, it does not, you cannot
    tell -- because a scale a child can learn is part of the question being fair.
    The answers across the unit are balanced instead, and the checker holds them
    to it. "You cannot tell" is the right answer whenever the only way to reach a
    yes or no is a fallacy: affirming the consequent, or denying the antecedent.
    """
    if any(f[0] == ask for f in facts):
        raise ValueError("the question is already answered by a fact on the card")
    v = must(rules, facts, ask)
    ans = 0 if v is True else 1 if v is False else 2
    return _q("ifThen", prompt, hint or "Only use what the clues actually say.",
              {"kind": "clues",
               "lines": [rule_sentence(r) for r in rules] +
                        [fact_sentence(f) for f in facts],
               "rules": [list(r) for r in rules], "facts": [list(f) for f in facts],
               "ask": ask},
              {"type": "option", "value": ans},
              optionsText=[f"It {lit(ask, True)}.", f"It {lit(ask, False)}.", CANT_TELL],
              fixedOrder=True)


# ============================================================ logic: claims

# Every class is a set of whole numbers whose membership repeats with a period
# dividing 60, so testing enough members settles "always" and "never" exactly,
# not just "as far as we looked". Squares repeat mod 60 with period 30 in the
# root. Primes are deliberately absent: they have no such period.
CLASSES = {
    "odd": ("an odd number", lambda n: n % 2 == 1),
    "even": ("an even number", lambda n: n % 2 == 0),
    "m3": ("a multiple of 3", lambda n: n % 3 == 0),
    "m4": ("a multiple of 4", lambda n: n % 4 == 0),
    "m5": ("a multiple of 5", lambda n: n % 5 == 0),
    "m6": ("a multiple of 6", lambda n: n % 6 == 0),
    "m10": ("a multiple of 10", lambda n: n % 10 == 0),
}
SQUARES = ("a square number", None)
ALWAYS3 = ["Always true", "Sometimes true", "Never true"]


def _members(cls, count=120):
    if cls == "sq":
        return [k * k for k in range(1, count + 1)]
    f = CLASSES[cls][1]
    out, n = [], 1
    while len(out) < count:
        if f(n):
            out.append(n)
        n += 1
    return out


def _phrase(cls):
    return SQUARES[0] if cls == "sq" else CLASSES[cls][0]


def claim_sentence(c):
    a = _phrase(c["a"])
    res = _phrase(c["is"])
    if c["op"] == "is":
        s = f"{a} is {res}."
    elif c["op"] in ("plus", "times"):
        s = f"{a} {c['op']} {_phrase(c['b'])} makes {res}."
    elif c["op"] == "double":
        s = f"doubling {a} makes {res}."
    elif c["op"] == "square":
        s = f"squaring {a} makes {res}."
    else:
        raise ValueError(c["op"])
    return s[0].upper() + s[1:]


def claim_truth(c):
    if c["is"] == "sq":
        raise ValueError("a square number cannot be the result: it has no period")
    test = CLASSES[c["is"]][1]
    A = _members(c["a"])
    if c["op"] == "is":
        vals = list(A)
    elif c["op"] in ("plus", "times"):
        B = _members(c["b"])
        vals = [(x + y if c["op"] == "plus" else x * y) for x in A for y in B]
    elif c["op"] == "double":
        vals = [2 * x for x in A]
    else:
        vals = [x * x for x in A]
    hits = sum(1 for v in vals if test(v))
    return 0 if hits == len(vals) else 2 if hits == 0 else 1


def claim(prompt, c, hint=None):
    ans = claim_truth(c)
    return _q("claim", prompt, hint or "Try a few numbers. Then think about why.",
              {"kind": "claim", "lines": [claim_sentence(c)], "claim": c},
              {"type": "option", "value": ans},
              optionsText=list(ALWAYS3), fixedOrder=True)


# ============================================================ logic: deduction

def _thing(x, noun):
    return f"{x} {noun}".strip()


def clue_sentence(c, noun):
    t = c["t"]
    if t == "has":
        return f"{c['p']} has the {_thing(c['x'], noun)}."
    if t == "not":
        return f"{c['p']} does not have the {_thing(c['x'], noun)}."
    if t == "either":
        return f"The {_thing(c['x'], noun)} is {c['ps'][0]}'s or {c['ps'][1]}'s."
    if t == "neither":
        return f"Neither {c['ps'][0]} nor {c['ps'][1]} has the {_thing(c['x'], noun)}."
    raise ValueError(t)


def _solutions(people, things, clues):
    out = []
    for perm in itertools.permutations(things):
        own = dict(zip(people, perm))
        ok = True
        for c in clues:
            t = c["t"]
            if t == "has" and own[c["p"]] != c["x"]:
                ok = False
            elif t == "not" and own[c["p"]] == c["x"]:
                ok = False
            elif t == "either" and own[c["ps"][0]] != c["x"] and own[c["ps"][1]] != c["x"]:
                ok = False
            elif t == "neither" and c["x"] in (own[c["ps"][0]], own[c["ps"][1]]):
                ok = False
            if not ok:
                break
        if ok:
            out.append(own)
    return out


def deduce(prompt, people, things, noun, clues, who=None, what=None, hint=None):
    """Who has what, from clues that each say only part of it.

    Exactly one arrangement may fit every clue, and NO single clue on its own may
    give the answer away -- otherwise it is a reading question, not a deduction.
    Both are checked by trying every arrangement.
    """
    if who is not None and f"the {_thing(who, noun)}" not in prompt:
        raise ValueError(f"the prompt does not ask about the {_thing(who, noun)}")
    if what is not None and f" {what} " not in f" {prompt} ".replace(".", " "):
        raise ValueError(f"the prompt does not ask about {what}")
    sols = _solutions(people, things, clues)
    if len(sols) != 1:
        raise ValueError(f"{len(sols)} arrangements fit these clues; need exactly 1")
    sol = sols[0]
    if who is not None:
        key = lambda s: next(p for p in people if s[p] == who)
        options = list(people)
    else:
        key = lambda s: s[what]
        options = [f"The {_thing(x, noun)}" for x in things]
    ans_val = key(sol)
    for c in clues:
        alone = _solutions(people, things, [c])
        if len({key(s) for s in alone}) == 1:
            raise ValueError(f"the clue {c} gives the answer away on its own")
    ans = people.index(ans_val) if who is not None else things.index(ans_val)
    q = _q("deduce", prompt, hint or "Cross out what each clue rules out.",
           {"kind": "grid", "people": people, "things": things, "noun": noun,
            "clues": clues, "lines": [clue_sentence(c, noun) for c in clues],
            "who": who, "what": what},
           {"type": "option", "value": ans}, optionsText=options)
    return _rotate(q, ["optionsText"], _seed(prompt, clues))


# ============================================================ codes: binary

def bits_value(values, on):
    return sum(v for v, b in zip(values, on) if b)


def to_bits(n, values):
    out = []
    for v in values:
        if n >= v:
            out.append(1); n -= v
        else:
            out.append(0)
    if n:
        raise ValueError("number too big for these bulbs")
    return out


def binary_read(prompt, values, on, hint=None):
    """Lit bulbs, each worth its label. The number is the sum of the lit ones.

    Mistakes: counting the lit bulbs, adding the unlit ones, reading the row
    backwards, and one bulb misread.
    """
    ans = bits_value(values, on)
    seed = _seed(prompt, values, on)
    lit_count = sum(on)
    unlit = bits_value(values, [1 - b for b in on])
    backwards = bits_value(values, list(reversed(on)))
    smallest_lit = min((v for v, b in zip(values, on) if b), default=1)
    return _q("binaryRead", prompt, hint or "Add up only the bulbs that are lit.",
              {"kind": "binary", "values": values, "on": on},
              {"type": "number", "value": ans},
              # These bulbs cannot show more than all of them lit. Offering a
              # bigger number is a free elimination, and with five bulbs it was
              # worse than that: 31, 32, 33, 34 has exactly one possible answer.
              **_numbers(ans, [backwards, unlit, lit_count, ans - smallest_lit,
                                     ans + smallest_lit], seed, lo=0,
                         allowed=set(range(0, sum(values) + 1))))


def binary_pick(prompt, values, number, hint=None, show=None, plus=0):
    """Pick the bulbs that show [number] (or, with [show], one more than shown).

    Distractors are the row reversed and the numbers either side, which are the
    three slips: wrong end, and one too many or too few.
    """
    target = number + plus
    if not show and f"{target}" not in prompt:
        raise ValueError(f"the prompt does not name {target}")
    right = to_bits(target, values)
    cands = []
    for n in (target - 1, target + 1, target + 2, target - 2):
        if 0 <= n < 2 * values[0]:
            b = to_bits(n, values)
            if b not in cands and b != right:
                cands.append(b)
    rev = list(reversed(right))
    if rev != right and rev not in cands:
        cands.insert(0, rev)
    opts = [right] + cands[:3]
    if len(opts) != 4:
        raise ValueError("could not find three different wrong rows")
    pic = {"kind": "binary", "values": values, "on": to_bits(number, values),
           "askPlus": plus} if show else {"kind": "binaryAsk", "values": values,
                                          "target": target}
    q = _q("binaryPick", prompt, hint or "Start with the biggest bulb that fits.",
           pic, {"type": "option", "value": 0}, optionBits=opts)
    return _rotate(q, ["optionBits"], _seed(prompt, values, number, plus))


# ============================================================ codes: letters

ALPHA = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"

WORDS = {
    3: ["CAT", "BAT", "HAT", "MAT", "RAT", "CAP", "CUP", "CUT", "COT", "DOG",
        "DIG", "BIG", "PIG", "FIG", "SUN", "RUN", "FUN", "BUN", "BUS", "BOX",
        "FOX", "TEN", "HEN", "PEN", "BED", "RED", "NET", "JAM", "ZOO", "ZIP",
        "YES", "WAX", "ANT", "OWL", "EGG", "ICE", "INK", "ARM", "EAR", "EYE",
        "MAP", "TOY", "KEY", "SKY", "BAG", "LOG", "HOT", "POT", "DOT", "TOP"],
    4: ["KITE", "BIKE", "CAKE", "LAKE", "BOOK", "LOOK", "COOK", "FISH", "DISH",
        "WISH", "SHIP", "SHOP", "STOP", "STAR", "MOON", "SOON", "SNOW", "BOAT",
        "COAT", "GOAT", "RAIN", "FROG", "DRUM", "BELL", "BALL", "TREE", "SEED",
        "LEAF", "NEST", "SAND", "WIND", "KING", "RING", "SING", "WING", "MILK",
        "DUCK", "FARM", "GIFT", "HAND", "LAMP", "MASK", "PARK", "ROAD", "SOAP"],
    5: ["MANGO", "TIGER", "LEMON", "TRAIN", "PLANT", "SMILE", "RIVER", "CHAIR",
        "BREAD", "CLOUD", "HOUSE", "MOUSE", "HORSE", "APPLE", "TABLE", "WATER",
        "LIGHT", "NIGHT", "STORM", "BRAIN", "BRUSH", "CLOCK", "STONE", "SHEEP",
        "TRUCK", "PAINT", "GRAPE", "SNAKE", "ZEBRA", "QUEEN"],
}


def shift_word(w, k):
    return "".join(ALPHA[(ALPHA.index(ch) + k) % 26] for ch in w)


def _word_distractors(answer, avoid, seed):
    """Three real words that look like the answer.

    If the wrong options were not words, a child could pick the only real word
    without decoding a letter. These share letters and positions with the answer,
    so decoding the first letter is not enough.
    """
    pool = [w for w in WORDS[len(answer)] if w != answer and w not in avoid]
    def score(w):
        same_pos = sum(a == b for a, b in zip(w, answer))
        shared = len(set(w) & set(answer))
        tie = _seed(w, seed) % 1000
        return (-same_pos, -shared, tie)
    pool.sort(key=score)
    return pool[:3]


def cipher_decode(prompt, plain, shift, hint=None):
    if plain not in WORDS[len(plain)]:
        raise ValueError(f"{plain} is not in the word list")
    coded = shift_word(plain, shift)
    opts = [plain] + _word_distractors(plain, {coded}, _seed(plain, shift))
    q = _q("cipher", prompt, hint or "Find each coded letter on the bottom row, then read the top.",
           {"kind": "shift", "shift": shift, "word": coded, "mode": "decode"},
           {"type": "option", "value": 0}, optionsText=opts)
    return _rotate(q, ["optionsText"], _seed(prompt, plain, shift))


def cipher_encode(prompt, plain, shift, hint=None):
    right = shift_word(plain, shift)
    wrong = []
    for k in (shift - 1, shift + 1, -shift, shift + 2):
        w = shift_word(plain, k)
        if w != right and w not in wrong and w != plain:
            wrong.append(w)
    opts = [right] + wrong[:3]
    q = _q("cipherWrite", prompt, hint or "Find each letter on the top row, then write the one below.",
           {"kind": "shift", "shift": shift, "word": plain, "mode": "encode"},
           {"type": "option", "value": 0}, optionsText=opts)
    return _rotate(q, ["optionsText"], _seed(prompt, plain, shift))


# Six shapes that stay distinct at the 20px a key or a net draws them. Seen on
# the review wall: at that size the six-petal flower reads as a hexagon, and a
# hexagon is not far from a circle. Two such shapes in one key would be a symbol
# code with two answers for anyone whose eyes do not catch the difference.
CLEAR_GLYPHS = [STAR, HEART, CIRCLE, SQUARE, TRIANGLE, DIAMOND]
SYMBOLS = [(g, c) for c in (PRIMARY, ACCENT) for g in CLEAR_GLYPHS]


def symbol_decode(prompt, plain, hint=None):
    """A key of symbol to letter, and a word written in symbols.

    The key covers every letter of EVERY option, not just the answer. A key
    holding only C, A and T beside the options CAT, COT, CUT and BAT would let a
    child pick the one word spelled from keyed letters without decoding anything.
    """
    opts = [plain] + _word_distractors(plain, set(), _seed(plain, "symbols"))
    letters = sorted({ch for w in opts for ch in w})
    if len(letters) > 10:
        raise ValueError(f"{len(letters)} letters is too big a key to read")
    order = sorted(SYMBOLS, key=lambda gc: _seed(plain, gc))
    sym = {ch: order[i] for i, ch in enumerate(letters)}
    key = [{"glyph": sym[ch][0], "color": sym[ch][1], "letter": ch} for ch in letters]
    word = [{"glyph": sym[ch][0], "color": sym[ch][1]} for ch in plain]
    q = _q("symbolCode", prompt, hint or "Swap each symbol for its letter, one at a time.",
           {"kind": "symbols", "key": key, "word": word},
           {"type": "option", "value": 0}, optionsText=opts)
    return _rotate(q, ["optionsText"], _seed(prompt, plain))


def letter_code(prompt, plain, hint=None):
    codes = [ALPHA.index(ch) + 1 for ch in plain]
    opts = [plain] + _word_distractors(plain, set(), _seed(plain, "a1"))
    q = _q("letterCode", prompt, hint or "Count along the alphabet: A is 1.",
           {"kind": "letters", "codes": codes},
           {"type": "option", "value": 0}, optionsText=opts)
    return _rotate(q, ["optionsText"], _seed(prompt, plain))


def letter_sum(prompt, word, hint=None):
    vals = [ALPHA.index(ch) + 1 for ch in word]
    ans = sum(vals)
    seed = _seed(prompt, word)
    return _q("letterSum", prompt, hint or "Write each letter's number first, then add.",
              {"kind": "letters", "word": word},
              {"type": "number", "value": ans},
              **_numbers(ans, [ans - vals[-1], ans + vals[0], ans - 1, ans + 1,
                                     len(word)], seed, lo=1))


# ============================================================ space: nets

# Rolling a cube across a net: the square under the cube is the face that lands
# on it. Positions are named by where they started: Bottom, Top, North, South,
# East, West. A net folds into a cube exactly when the six squares get six
# different faces and every pair of neighbouring squares agrees.
_ROLL = {
    (1, 0): {"B": "E", "E": "T", "T": "W", "W": "B", "N": "N", "S": "S"},
    (-1, 0): {"B": "W", "W": "T", "T": "E", "E": "B", "N": "N", "S": "S"},
    (0, -1): {"B": "N", "N": "T", "T": "S", "S": "B", "E": "E", "W": "W"},
    (0, 1): {"B": "S", "S": "T", "T": "N", "N": "B", "E": "E", "W": "W"},
}
OPPOSITE = {"B": "T", "T": "B", "N": "S", "S": "N", "E": "W", "W": "E"}


def _roll_state(state, d):
    m = _ROLL[d]                    # new_state[pos] = state[m[pos]]
    return {pos: state[m[pos]] for pos in state}


def fold(cells):
    """{cell: face label} if the net folds into a cube, else None."""
    cells = [tuple(c) for c in cells]
    cs = set(cells)
    if len(cs) != 6:
        return None
    start = cells[0]
    states = {start: {p: p for p in "BTNSEW"}}
    stack = [start]
    while stack:
        u = stack.pop()
        for d in _ROLL:
            v = (u[0] + d[0], u[1] + d[1])
            if v in cs:
                sv = _roll_state(states[u], d)
                if v in states:
                    if states[v] != sv:
                        return None
                else:
                    states[v] = sv
                    stack.append(v)
    if len(states) != 6:
        return None
    faces = {c: states[c]["B"] for c in cells}
    if len(set(faces.values())) != 6:
        return None
    return faces


def _norm(cells):
    mx = min(c[0] for c in cells)
    my = min(c[1] for c in cells)
    return tuple(sorted((c[0] - mx, c[1] - my) for c in cells))


def _free(cells):
    variants = []
    pts = list(cells)
    for _ in range(4):
        pts = [(y, -x) for x, y in pts]
        variants.append(_norm(pts))
        variants.append(_norm([(-x, y) for x, y in pts]))
    return min(variants)


def all_hexominoes():
    """Every fixed hexomino, by growing from one square."""
    shapes = {((0, 0),)}
    for _ in range(5):
        nxt = set()
        for s in shapes:
            ss = set(s)
            for (x, y) in s:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    c = (x + dx, y + dy)
                    if c not in ss:
                        nxt.add(_norm(list(ss | {c})))
        shapes = nxt
    return sorted(shapes)


def _has_block(cells):
    s = {tuple(c) for c in cells}
    return any({(x + 1, y), (x, y + 1), (x + 1, y + 1)} <= s for x, y in s)


def net_face(prompt, cells, marks, target, hint=None):
    """Fold the net; which mark ends up opposite [target]."""
    faces = fold(cells)
    if faces is None:
        raise ValueError("this net does not fold into a cube")
    if len(set(marks)) != 6:
        raise ValueError("six different marks needed")
    if target not in prompt:
        raise ValueError(f"the prompt does not name the {target}")
    cells = [tuple(c) for c in cells]
    ti = marks.index(target)
    opp_label = OPPOSITE[faces[cells[ti]]]
    oi = next(i for i, c in enumerate(cells) if faces[c] == opp_label)
    adjacent = [marks[i] for i, c in enumerate(cells) if i not in (ti, oi)]
    seed = _seed(prompt, cells, marks)
    adjacent.sort(key=lambda m: _seed(m, seed))
    opts = [cell(marks[oi])] + [cell(m) for m in adjacent[:3]]
    q = _q("netFace", prompt, hint or "Pick one square to be the bottom and fold the rest up around it.",
           {"kind": "net", "cells": [list(c) for c in cells], "marks": marks,
            "target": target},
           {"type": "option", "value": 0}, optionCells=opts)
    return _rotate(q, ["optionCells"], seed)


def net_pick(prompt, valid, invalid, odd_one="folds", hint=None):
    """Four nets. odd_one="folds": one folds, three do not. "not": the reverse."""
    # A prompt saying NOT must be graded as the NOT question. Four were written
    # asking for the net that does NOT fold while set up to grade the one that
    # does; the counts check below caught it, this makes it impossible.
    if ("NOT" in prompt) != (odd_one == "not"):
        raise ValueError("the prompt and the question disagree about NOT")
    for n in valid:
        if fold(n) is None:
            raise ValueError(f"{n} was offered as folding but does not")
    for n in invalid:
        if fold(n) is not None:
            raise ValueError(f"{n} was offered as not folding but does")
    if odd_one == "folds":
        if len(valid) != 1 or len(invalid) != 3:
            raise ValueError("need one net that folds and three that do not")
        opts = [valid[0]] + invalid
    else:
        if len(valid) != 3 or len(invalid) != 1:
            raise ValueError("need three nets that fold and one that does not")
        opts = [invalid[0]] + valid
    for n in opts:
        if _has_block(n):
            raise ValueError("a 2x2 block gives the answer away at a glance")
    q = _q("netPick", prompt, hint or "Imagine folding each square up. Do two land on the same side?",
           None, {"type": "option", "value": 0},
           optionNets=[[list(c) for c in n] for n in opts], askFolds=(odd_one == "folds"))
    return _rotate(q, ["optionNets"], _seed(prompt, opts))


# ============================================================ space: dice

_DIR = {"right": (1, 0), "left": (-1, 0), "up": (0, -1), "down": (0, 1)}


def roll_dice(top, front, right, moves):
    """Roll a dice across a grid seen from above. 'up' is away from you."""
    s = {"T": top, "B": 7 - top, "S": front, "N": 7 - front, "E": right, "W": 7 - right}
    tops = [top]
    for m in moves:
        if m == "right":
            s = {"T": s["W"], "E": s["T"], "B": s["E"], "W": s["B"], "N": s["N"], "S": s["S"]}
        elif m == "left":
            s = {"T": s["E"], "W": s["T"], "B": s["W"], "E": s["B"], "N": s["N"], "S": s["S"]}
        elif m == "up":
            s = {"T": s["S"], "N": s["T"], "B": s["N"], "S": s["B"], "E": s["E"], "W": s["W"]}
        elif m == "down":
            s = {"T": s["N"], "S": s["T"], "B": s["S"], "N": s["B"], "E": s["E"], "W": s["W"]}
        else:
            raise ValueError(m)
        tops.append(s["T"])
    return s, tops


def dice(prompt, top, front, right, moves, w, h, start, hint=None):
    vals = {top, front, right}
    if len(vals) != 3 or any(a + b == 7 for a in vals for b in vals if a != b):
        raise ValueError("top, front and right must be three faces that meet at a corner")
    x, y = start
    for m in moves:
        dx, dy = _DIR[m]
        x, y = x + dx, y + dy
        if not (0 <= x < w and 0 <= y < h):
            raise ValueError("the path leaves the grid")
    s, tops = roll_dice(top, front, right, moves)
    ans = s["T"]
    seed = _seed(prompt, top, front, right, moves)
    mistakes = [s["B"], tops[-2], s["E"], s["S"], top]
    return _q("roll", prompt, hint or "Opposite faces add up to 7. Follow one roll at a time.",
              {"kind": "roll", "w": w, "h": h, "start": list(start), "moves": moves,
               "top": top, "front": front, "right": right},
              {"type": "number", "value": ans},
              # A dice has six faces. 7 and 8 were being offered as tops.
              **_numbers(ans, mistakes, seed, lo=1, allowed={1, 2, 3, 4, 5, 6}))


# ============================================================ space: stacks

def _check_stack(heights):
    d, w = len(heights), len(heights[0])
    for y in range(d):
        for x in range(w):
            h = heights[y][x]
            if y + 1 < d and heights[y + 1][x] > h:
                raise ValueError("a front column is taller than the one behind it, "
                                 "so cubes could be hidden")
            if x + 1 < w and heights[y][x + 1] > h:
                raise ValueError("a right column is taller than the one to its left, "
                                 "so cubes could be hidden")


def visible_cubes(heights):
    d, w = len(heights), len(heights[0])
    n = 0
    for y in range(d):
        for x in range(w):
            for z in range(heights[y][x]):
                top = z == heights[y][x] - 1
                front = y == d - 1 or heights[y + 1][x] <= z
                right = x == w - 1 or heights[y][x + 1] <= z
                n += top or front or right
    return n


def stack_count(prompt, heights, hint=None):
    """Count every cube, including the ones hidden behind and underneath.

    The stacks step down towards you, so every column's top is in view and the
    count has one answer. The classic slip -- counting only the cubes you can see
    -- is always one of the options.
    """
    _check_stack(heights)
    ans = sum(map(sum, heights))
    seen = visible_cubes(heights)
    seed = _seed(prompt, heights)
    cols = sum(1 for r in heights for h in r if h)
    return _q("stackCount", prompt, hint or "Count one column at a time, from the floor up.",
              {"kind": "stack", "heights": heights},
              {"type": "number", "value": ans},
              **_numbers(ans, [seen, ans - 1, ans + 1, cols], seed, lo=1))


def stack_fill(prompt, heights, full, hint=None):
    """How many more cubes turn this into a solid block of size [full]."""
    _check_stack(heights)
    d, w = len(heights), len(heights[0])
    fw, fd, fh = full
    if fw < w or fd < d or fh < max(map(max, heights)):
        raise ValueError("the block is smaller than the stack")
    have = sum(map(sum, heights))
    ans = fw * fd * fh - have
    seed = _seed(prompt, heights, full)
    return _q("stackFill", prompt, hint or "Work out the whole shape first, then take away.",
              {"kind": "stack", "heights": heights, "full": list(full)},
              {"type": "number", "value": ans},
              **_numbers(ans, [fw * fd * fh - visible_cubes(heights),
                                     fw * fd * fh, ans - 1, ans + 1, have], seed, lo=0))


def views(heights):
    d, w = len(heights), len(heights[0])
    front = [max(heights[y][x] for y in range(d)) for x in range(w)]
    right = [max(heights[y][x] for x in range(w)) for y in reversed(range(d))]
    return front, right


def stack_view(prompt, heights, side, hint=None):
    """What the stack looks like straight from the front, or from the right."""
    _check_stack(heights)
    front, right = views(heights)
    want = front if side == "front" else right
    other = right if side == "front" else front
    cands = [other, list(reversed(want))]
    for i in range(len(want)):
        for dv in (1, -1):
            v = list(want); v[i] += dv
            if v[i] >= 0:
                cands.append(v)
    opts = [want]
    for c in cands:
        if c not in opts and any(c):
            opts.append(c)
        if len(opts) == 4:
            break
    if len(opts) != 4:
        raise ValueError("could not find three different wrong views")
    q = _q("stackView", prompt, hint or "From straight on you only see the tallest cube in each line.",
           {"kind": "stack", "heights": heights, "side": side},
           {"type": "option", "value": 0}, optionViews=opts)
    return _rotate(q, ["optionViews"], _seed(prompt, heights, side))


# ============================================================ logic: truth-tellers and liars
# "Knights and knaves" in the source spine. Called truth-tellers and liars here,
# because that is what the words mean to an eleven year old; knight and knave
# are a vocabulary test in front of a logic puzzle.

KK_RULE = ["Truth-tellers always tell the truth.", "Liars always lie."]
KINDS_TL = ("truth-teller", "liar")


def kk_text(speaker, c):
    t = c[0]
    if t == "is":
        _, p, k = c
        return f"I am a {k}." if p == speaker else f"{p} is a {k}."
    if t in ("same", "diff"):
        _, a, b = c
        word = "the same kind" if t == "same" else "different kinds"
        return f"We are {word}." if speaker in (a, b) else f"{a} and {b} are {word}."
    if t == "both":
        return f"We are both {c[1]}s."
    if t == "one_liar":
        return "At least one of us is a liar."
    raise ValueError(t)


def kk_true(c, world, people):
    t = c[0]
    if t == "is":
        return world[c[1]] == c[2]
    if t == "same":
        return world[c[1]] == world[c[2]]
    if t == "diff":
        return world[c[1]] != world[c[2]]
    if t == "both":
        return all(world[p] == c[1] for p in people)
    if t == "one_liar":
        return any(world[p] == "liar" for p in people)
    raise ValueError(t)


def kk_worlds(people, says):
    out = []
    for combo in itertools.product(KINDS_TL, repeat=len(people)):
        w = dict(zip(people, combo))
        if all(kk_true(c, w, people) == (w[s] == "truth-teller") for s, c in says):
            out.append(w)
    return out


def knights(prompt, people, says, ask, hint=None):
    """Who is telling the truth, from what they say about each other.

    Every possible world is tried. "You cannot tell" is the answer only when the
    worlds that fit disagree about [ask]; a statement that fits no world at all
    (a liar saying "I am a liar") is refused, because it has no answer.
    """
    if ask not in prompt:
        raise ValueError(f"the prompt does not ask about {ask}")
    worlds = kk_worlds(people, says)
    if not worlds:
        raise ValueError("no one can say these things; there is no answer")
    vals = {w[ask] for w in worlds}
    ans = 2 if len(vals) > 1 else (0 if vals.pop() == "truth-teller" else 1)
    return _q("knights", prompt, hint or "Pretend they are a truth-teller. Does it work? Then try liar.",
              {"kind": "truth", "lines": KK_RULE + [f'{s} says: "{kk_text(s, c)}"' for s, c in says],
               "people": people, "says": [[s, list(c)] for s, c in says], "ask": ask},
              {"type": "option", "value": ans},
              optionsText=[f"{ask} is a truth-teller.", f"{ask} is a liar.", CANT_TELL],
              fixedOrder=True)


# ============================================================ codes: substitution

def atbash(w):
    """The back-to-front alphabet: A swaps with Z, B with Y, and so on."""
    return "".join(ALPHA[25 - ALPHA.index(ch)] for ch in w)


def mirror_decode(prompt, plain, hint=None):
    coded = atbash(plain)
    opts = [plain] + _word_distractors(plain, {coded}, _seed(plain, "atbash"))
    q = _q("mirrorCode", prompt, hint or "Find each coded letter, then read the letter it swaps with.",
           {"kind": "mirrorAlpha", "word": coded, "mode": "decode"},
           {"type": "option", "value": 0}, optionsText=opts)
    return _rotate(q, ["optionsText"], _seed(prompt, plain))


def mirror_encode(prompt, plain, hint=None):
    right = atbash(plain)
    wrong = []
    for w in (shift_word(plain, 1), shift_word(right, 1), shift_word(right, -1),
              right[::-1], shift_word(plain, -1)):
        if w != right and w not in wrong and w != plain:
            wrong.append(w)
    q = _q("mirrorWrite", prompt, hint or "Find each letter, then write the letter it swaps with.",
           {"kind": "mirrorAlpha", "word": plain, "mode": "encode"},
           {"type": "option", "value": 0}, optionsText=[right] + wrong[:3])
    return _rotate(q, ["optionsText"], _seed(prompt, plain))


def _apply_rule(rule, w):
    if rule[0] == "shift":
        return shift_word(w, rule[1])
    if rule[0] == "atbash":
        return atbash(w)
    raise ValueError(rule)


def crack(prompt, example, ask, rule, mode, hint=None):
    """A worked example and no key: find the rule, then use it.

    The pattern cipher in the source spine. The kit refuses an example that more
    than one rule could have made -- MN coded as NM fits both "move one on" and
    "swap with the back-to-front letter" -- because then the child cannot know
    which rule to carry over.
    """
    ex_code = _apply_rule(rule, example)
    fits = [r for r in [("shift", k) for k in range(1, 26)] + [("atbash",)]
            if _apply_rule(r, example) == ex_code]
    if len(fits) != 1:
        raise ValueError(f"the example fits {len(fits)} rules; need exactly one")
    if mode == "encode":
        right = _apply_rule(rule, ask)
        shown = ask
        others = [_apply_rule(r, ask) for r in (("shift", 1), ("shift", -1), ("atbash",),
                                                 ("shift", 2), ("shift", 25))]
        wrong = []
        for w in others + [right[::-1]]:
            if w != right and w not in wrong and w != ask:
                wrong.append(w)
        opts = [right] + wrong[:3]
        if ask not in WORDS[len(ask)]:
            raise ValueError(f"{ask} is not in the word list")
    else:
        if ask not in WORDS[len(ask)]:
            raise ValueError(f"{ask} is not in the word list")
        shown = _apply_rule(rule, ask)
        right = ask
        opts = [ask] + _word_distractors(ask, {shown, example}, _seed(ask, rule))
    q = _q("crackCode", prompt, hint or "Compare the example letter by letter. What happened to each one?",
           {"kind": "example", "example": [example, ex_code], "word": shown, "mode": mode},
           {"type": "option", "value": 0}, optionsText=opts)
    return _rotate(q, ["optionsText"], _seed(prompt, example, ask))


# ============================================================ space: rotating in 3D

def _rot24():
    def rx(p): return (p[0], -p[2], p[1])
    def ry(p): return (p[2], p[1], -p[0])
    def rz(p): return (-p[1], p[0], p[2])
    basis = ((1, 0, 0), (0, 1, 0), (0, 0, 1))
    seen, frontier = {basis}, [basis]
    while frontier:
        b = frontier.pop()
        for f in (rx, ry, rz):
            nb = tuple(f(v) for v in b)
            if nb not in seen:
                seen.add(nb)
                frontier.append(nb)
    return sorted(seen)


ROT24 = _rot24()


def _apply_rot(b, p):
    return tuple(sum(b[i][j] * p[i] for i in range(3)) for j in range(3))


def norm3(cells):
    mx = [min(c[i] for c in cells) for i in range(3)]
    return tuple(sorted(tuple(c[i] - mx[i] for i in range(3)) for c in cells))


def canon3(cells):
    return min(norm3([_apply_rot(b, c) for c in cells]) for b in ROT24)


def mirror3(cells):
    return norm3([(-x, y, z) for x, y, z in cells])


def all_polycubes(n):
    shapes = {((0, 0, 0),)}
    for _ in range(n - 1):
        nxt = set()
        for s in shapes:
            ss = set(s)
            for x, y, z in s:
                for d in ((1, 0, 0), (-1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1), (0, 0, -1)):
                    c = (x + d[0], y + d[1], z + d[2])
                    if c not in ss:
                        nxt.add(canon3(list(ss | {c})))
        shapes = nxt
    return sorted(shapes)


def iso_image(cells, res=6):
    """What a stack of cubes looks like from the review wall's viewpoint.

    Rasterised with a depth buffer, so a cube hidden behind another really is
    hidden. Returns the picture (which face type shows at each point, shifted to
    the origin) and the set of cubes that show at all. Used to prove a question
    fair from the PICTURE, not from the cubes: no wrong option may look exactly
    like some turn of the target, and no cube may be completely hidden.
    """
    cells = [tuple(c) for c in cells]
    occ = set(cells)
    buf = {}
    n = res
    for vi, (x, y, z) in enumerate(cells):
        faces = []
        if (x, y, z + 1) not in occ:
            faces.append(("t", lambda u, v, x=x, y=y, z=z: (x + u, y + v, z + 1)))
        if (x, y + 1, z) not in occ:
            faces.append(("f", lambda u, v, x=x, y=y, z=z: (x + u, y + 1, z + v)))
        if (x + 1, y, z) not in occ:
            faces.append(("r", lambda u, v, x=x, y=y, z=z: (x + 1, y + u, z + v)))
        for kind, f in faces:
            for i in range(n):
                for j in range(n):
                    X, Y, Z = f((i + 0.5) / n, (j + 0.5) / n)
                    px = round((X - Y) * n)
                    py = round((X + Y - 2 * Z) * n)
                    depth = X + Y + Z
                    if (px, py) not in buf or depth > buf[(px, py)][0]:
                        buf[(px, py)] = (depth, kind, vi)
    mx = min(p[0] for p in buf)
    my = min(p[1] for p in buf)
    img = frozenset((p[0] - mx, p[1] - my, v[1]) for p, v in buf.items())
    shown = {v[2] for v in buf.values()}
    return img, len(shown) == len(cells)


def polycube_pick(prompt, target, wrong_shapes, seed_word, hint=None):
    """Which picture is the target, turned? One is; one is its mirror image if it
    has one; the rest are different shapes with the same number of cubes."""
    tgt = norm3(target)
    t_img, t_all = iso_image(tgt)
    if not t_all:
        raise ValueError("a cube of the target is hidden in its own picture")
    seed = _seed(prompt, tgt, seed_word)
    order = sorted(ROT24, key=lambda b: _seed(b, seed))

    def turned(cells, avoid_img=None):
        for b in order:
            c = norm3([_apply_rot(b, p) for p in cells])
            img, ok = iso_image(c)
            if ok and img != avoid_img:
                return c, img
        raise ValueError("no turn shows every cube")

    right, r_img = turned(tgt, t_img)
    cands = []
    mir = mirror3(tgt)
    if canon3(mir) != canon3(tgt):
        cands.append(mir)
    cands += [norm3(w) for w in wrong_shapes]
    opts, imgs = [right], [r_img]
    target_imgs = {iso_image(norm3([_apply_rot(b, p) for p in tgt]))[0] for b in ROT24}
    for w in cands:
        if len(opts) == 4:
            break
        if canon3(w) == canon3(tgt) or len(w) != len(tgt):
            raise ValueError("a wrong option is the target itself, or a different size")
        c, img = turned(w)
        if img in target_imgs:
            raise ValueError("a wrong option LOOKS like a turn of the target")
        if img in imgs:
            continue
        opts.append(c)
        imgs.append(img)
    if len(opts) != 4:
        raise ValueError("need three different wrong options")
    q = _q("sameShape", prompt, hint or "Pick one cube in the shape and follow where its neighbours go.",
           {"kind": "polycube", "cubes": [list(c) for c in tgt]},
           {"type": "option", "value": 0}, optionCubes=[[list(c) for c in o] for o in opts])
    return _rotate(q, ["optionCubes"], seed)


TURNS = {  # new position <- old position
    "left": {"T": "R", "L": "T", "B": "L", "R": "B", "F": "F", "K": "K"},
    "right": {"T": "L", "R": "T", "B": "R", "L": "B", "F": "F", "K": "K"},
    "away": {"T": "F", "K": "T", "B": "K", "F": "B", "L": "L", "R": "R"},
    "toward": {"T": "K", "F": "T", "B": "F", "K": "B", "L": "L", "R": "R"},
    "spinR": {"F": "R", "L": "F", "K": "L", "R": "K", "T": "T", "B": "B"},
    "spinL": {"F": "L", "R": "F", "K": "R", "L": "K", "T": "T", "B": "B"},
}
TURN_WORDS = {
    "left": "Tip it over to the left.",
    "right": "Tip it over to the right.",
    "away": "Tip it over, away from you.",
    "toward": "Tip it over, towards you.",
    "spinR": "Turn it so its right side faces you.",
    "spinL": "Turn it so its left side faces you.",
}
SIDE_WORDS = {"T": "on top", "F": "at the front", "R": "on the right"}


def cube_turn(prompt, marks, moves, ask, hint=None):
    """A cube with a mark on each face you can see, turned once or twice.

    Only the top, front and right marks are drawn, so the kit refuses a turn
    whose asked face would have come from a side the child never saw.
    """
    if SIDE_WORDS[ask] not in prompt:
        raise ValueError("the prompt asks about a different side")
    top, front, right = marks
    state = {"T": top, "F": front, "R": right, "B": None, "L": None, "K": None}
    for m in moves:
        state = {pos: state[TURNS[m][pos]] for pos in state}
    ans = state[ask]
    if ans is None:
        raise ValueError("the asked face was never shown")
    opts = [cell(m) for m in marks]
    q = _q("cubeTurn", prompt, hint or "Say where the top goes first, then the front.",
           {"kind": "turnCube", "marks": list(marks), "moves": list(moves),
            "steps": [TURN_WORDS[m] for m in moves], "ask": ask},
           {"type": "option", "value": marks.index(ans)}, optionCells=opts)
    return q


# ============================================================ space: cross-sections

S2 = 2 ** 0.5
SOLIDS = {
    "cube": {"name": "cube", "size": (1, 1, 1)},
    "cuboid": {"name": "cuboid", "size": (2, 1, 1)},
    "pyramid": {"name": "square pyramid", "size": (1, 1, 1)},
    "triprism": {"name": "triangular prism", "size": (1, 1, 1)},
    "hexprism": {"name": "hexagonal prism", "size": (1, 1, 1)},
    "cylinder": {"name": "cylinder", "size": (1, 1, 1)},
    "cone": {"name": "cone", "size": (1, 1, 1)},
    "sphere": {"name": "sphere", "size": (1, 1, 1)},
}

# (solid, cut) -> (shape name, plane point, plane normal). The shape is the
# kit's claim; rs_grade.py computes it from the geometry and must agree.
CUTS = {
    ("cube", "across"): ("square", (0.5, 0.5, 0.5), (0, 0, 1)),
    ("cube", "down"): ("square", (0.5, 0.5, 0.5), (1, 0, 0)),
    ("cube", "diagonal"): ("rectangle", (0.5, 0.5, 0.5), (1, -1, 0)),
    ("cube", "corner"): ("triangle", (1, 0, 0), (1, 1, 1)),
    ("cube", "middle"): ("hexagon", (0.5, 0.5, 0.5), (1, 1, 1)),
    ("cuboid", "across"): ("rectangle", (1, 0.5, 0.5), (0, 0, 1)),
    ("cuboid", "short"): ("square", (1, 0.5, 0.5), (1, 0, 0)),
    ("cuboid", "long"): ("rectangle", (1, 0.5, 0.5), (0, 1, 0)),
    ("pyramid", "across"): ("square", (0.5, 0.5, 0.4), (0, 0, 1)),
    ("pyramid", "down"): ("triangle", (0.5, 0.5, 0.5), (1, 0, 0)),
    ("triprism", "across"): ("triangle", (0.5, 0.5, 0.5), (0, 0, 1)),
    ("triprism", "down"): ("rectangle", (0.5, 0.45, 0.5), (0, 1, 0)),
    ("hexprism", "across"): ("hexagon", (0.5, 0.5, 0.5), (0, 0, 1)),
    ("hexprism", "down"): ("rectangle", (0.5, 0.5, 0.5), (1, 0, 0)),
    ("cylinder", "across"): ("circle", (0.5, 0.5, 0.5), (0, 0, 1)),
    ("cylinder", "down"): ("rectangle", (0.5, 0.5, 0.5), (1, 0, 0)),
    ("cylinder", "slant"): ("oval", (0.5, 0.5, 0.5), (0.5, 0, 1)),
    ("cone", "across"): ("circle", (0.5, 0.5, 0.35), (0, 0, 1)),
    ("cone", "down"): ("triangle", (0.5, 0.5, 0.5), (1, 0, 0)),
    ("cone", "slant"): ("oval", (0.5, 0.5, 0.4), (0.35, 0, 1)),
    ("sphere", "across"): ("circle", (0.5, 0.5, 0.5), (0, 0, 1)),
    ("sphere", "slant"): ("circle", (0.5, 0.5, 0.5), (0.6, 0, 1)),
}
FLAT = ["circle", "oval", "square", "rectangle", "triangle", "hexagon"]
SIDES = {"square": 4, "rectangle": 4, "triangle": 3, "hexagon": 6}

# The mistakes a child actually makes about a cut, per answer.
FLAT_TRAPS = {
    "circle": ["oval", "square", "rectangle"],
    "oval": ["circle", "rectangle", "triangle"],
    "square": ["rectangle", "triangle", "hexagon"],
    "rectangle": ["square", "oval", "triangle"],
    "triangle": ["square", "rectangle", "hexagon"],
    "hexagon": ["square", "triangle", "rectangle"],
}


def _section_pic(solid, cut):
    shape, p0, n = CUTS[(solid, cut)]
    return {"kind": "section", "solid": solid, "cut": cut,
            "point": list(p0), "normal": list(n)}


def section_shape(prompt, solid, cut, hint=None):
    shape = CUTS[(solid, cut)][0]
    opts = [shape] + FLAT_TRAPS[shape]
    q = _q("sectionShape", prompt, hint or "Picture the cut face lying flat on the table.",
           _section_pic(solid, cut), {"type": "option", "value": 0}, optionShapes=opts)
    return _rotate(q, ["optionShapes"], _seed(prompt, solid, cut))


def section_sides(prompt, solid, cut, hint=None):
    shape = CUTS[(solid, cut)][0]
    if shape not in SIDES:
        raise ValueError(f"a {shape} has no straight sides to count")
    ans = SIDES[shape]
    return _q("sectionSides", prompt, hint or "Count the faces of the solid the cut goes through.",
              _section_pic(solid, cut), {"type": "number", "value": ans},
              **_numbers(ans, [3, 4, 5, 6, 8], _seed(prompt, solid, cut), lo=3,
                         allowed={3, 4, 5, 6, 8}))


def section_which(prompt, want, cuts, hint=None):
    """Four cuts; exactly one gives [want]."""
    if want not in prompt:
        raise ValueError(f"the prompt does not name the {want}")
    hits = [i for i, (s, c) in enumerate(cuts) if CUTS[(s, c)][0] == want]
    if hits != [0]:
        raise ValueError(f"cuts giving a {want}: {hits}; need exactly the first")
    q = _q("sectionWhich", prompt, hint or "Imagine each cut face lying flat.",
           None, {"type": "option", "value": 0},
           optionSections=[_section_pic(s, c) for s, c in cuts])
    return _rotate(q, ["optionSections"], _seed(prompt, cuts))
