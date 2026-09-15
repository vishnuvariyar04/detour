# -*- coding: utf-8 -*-
"""Authoring kit for Puzzles & Logic — band b, ages 7-8.

REBUILT 2026-09-15 at Sai's request. The first version was shape patterns and
sorting; this one is the reasoning an Olympiad paper asks of a Class 2-3 child,
plus the family-relation puzzles from aptitude papers, pitched down to seven:

  number thinking   missing numbers, number riddles, story sums, number patterns
  order and place   taller/older/faster, places in a line, left, right, turning
  relations, codes  family relations, analogies, letter and number codes
  logic             odd one out, days, months and the clock, "how many ways"

Sources the pitch rests on (see the commit for links): the SOF IMO Class 2 and 3
reasoning syllabi; research that seven and eight year olds handle three-term
comparisons ("A is taller than B, B is taller than C"); schema research that
"change" story sums are easier than "compare" ones; family-relation guidance that
direct relations are easy and in-law or multi-step ones are not; and the Nupo
design memo's budget for band b -- a question of about eight words, one of four
answers, fifteen to twenty-five seconds, contexts from the playground, the shop
and the family.

Every answer is COMPUTED by an engine that does the reasoning. pz_grade.py works
each one out again with different code. The wrong options are the mistakes a
child actually makes: adding when the story takes away, counting from the wrong
end of the line, turning the wrong way, naming the relation backwards.
"""
import datetime
import hashlib
import itertools
import json

# Clues are read by children who may be reading in a second language. Every name
# is short, common in India, and clearly a girl's or a boy's name -- but the
# relation engines never rely on that: a person's gender comes only from a clue
# word ("mother", "brother"), and pz_grade.py reads it from the sentence itself.
GIRLS = ["Asha", "Meera", "Zoya", "Priya", "Isha", "Tara", "Neha", "Anu", "Riya",
         "Sara", "Nina", "Mia", "Diya", "Lila", "Anya", "Rani", "Pooja", "Kavya"]
BOYS = ["Ravi", "Kabir", "Arjun", "Dev", "Rohan", "Imran", "Aman", "Ali", "Om",
        "Veer", "Raj", "Yash", "Karan", "Sahil", "Nikhil", "Tom"]

MAX_WORDS = 8          # per clue line, and for the prompt: the memo's band b budget
MAX_LINES = 3


def _seed(*parts):
    blob = json.dumps(parts, sort_keys=True, ensure_ascii=False, default=str)
    return int(hashlib.sha256(blob.encode("utf-8")).hexdigest()[:8], 16)


def _words(s):
    return len(s.replace("?", " ").replace(".", " ").split())


def _lines_ok(lines):
    if len(lines) > MAX_LINES:
        raise ValueError(f"{len(lines)} clue lines; a seven year old gets at most {MAX_LINES}")
    for l in lines:
        if _words(l) > MAX_WORDS:
            raise ValueError(f'"{l}" is {_words(l)} words; the cap is {MAX_WORDS}')


def _q(shape, prompt, hint, pic, answer, **extra):
    if _words(prompt) > MAX_WORDS:
        raise ValueError(f'prompt "{prompt}" is {_words(prompt)} words; the cap is {MAX_WORDS}')
    if pic and pic.get("lines"):
        _lines_ok(pic["lines"])
    q = {"shape": shape, "prompt": prompt, "hint": hint, "pic": pic, "answer": answer}
    q.update(extra)
    return q


def choices4(ans, mistakes, k=0, lo=0):
    """Four ascending numbers: the answer and three mistakes, answer in slot k.

    Real mistakes come before invented near misses. Nothing below [lo] is ever
    offered, so a seven year old is never shown a negative number.
    """
    real = []
    for m in mistakes:
        if m != ans and m not in real and m >= lo and float(m).is_integer():
            real.append(int(m))
    pad, step = [], 1
    while len(pad) < 8:
        for c in (ans + step, ans - step):
            if c != ans and c not in real and c not in pad and c >= lo:
                pad.append(c)
        step += 1
    below = [c for c in real if c < ans] + [c for c in pad if c < ans]
    above = [c for c in real if c > ans] + [c for c in pad if c > ans]
    j = min(k, len(below))
    if len(above) < 3 - j:
        j = 3 - len(above)
    return sorted(below[:j] + [ans] + above[:3 - j])


def _numbers(ans, mistakes, lo=0):
    return {"choices": choices4(ans, mistakes, 0, lo),
            "_pool": {"mistakes": [int(m) for m in mistakes if float(m).is_integer()], "lo": lo}}


def _options(q, field):
    """Mark a question whose text or picture options the emitter may reorder."""
    q["_rotate"] = [field]
    return q


# ============================================================ 1. number thinking

def equation(prompt, left, op, right, result, hide, hint=None):
    """A number sentence with one box empty: 8 + ? = 15."""
    val = {"+": left + right, "-": left - right}[op]
    if val != result:
        raise ValueError(f"{left} {op} {right} is not {result}")
    if min(left, right, result) < 0 or max(left, right, result) > 100:
        raise ValueError("numbers must stay between 0 and 100")
    ans = {"left": left, "right": right, "result": result}[hide]
    if op == "+":
        mistakes = {"left": [result + right, result], "right": [result + left, result],
                    "result": [abs(left - right), left]}[hide]
    else:
        mistakes = {"left": [result - right, result], "right": [left + result, result],
                    "result": [left + right, right]}[hide]
    pic = {"kind": "equation", "left": left, "op": op, "right": right, "result": result,
           "hide": hide}
    return _q("equation", prompt, hint or "What number makes both sides the same?",
              pic, {"type": "number", "value": ans},
              **_numbers(ans, mistakes + [ans + 1, ans - 1]))


RIDDLE_WORDS = {"add": "add {k}", "take": "take away {k}", "double": "double it",
                "half": "halve it"}


def _riddle_apply(steps, x):
    for s in steps:
        if s[0] == "add":
            x = x + s[1]
        elif s[0] == "take":
            x = x - s[1]
        elif s[0] == "double":
            x = x * 2
        elif s[0] == "half":
            if x % 2:
                return None
            x = x // 2
    return x


def riddle(prompt, steps, result, hint=None):
    """I am a number. Add 4 to me. Now I am 12."""
    hits = [x for x in range(0, 101) if _riddle_apply(steps, x) == result]
    if len(hits) != 1:
        raise ValueError(f"{len(hits)} numbers fit this riddle")
    ans = hits[0]
    said = [RIDDLE_WORDS[s[0]].format(k=s[1] if len(s) > 1 else "") for s in steps]
    middle = ("I " + said[0] + ".") if len(said) == 1 else f"I {said[0]}, then {said[1]}."
    lines = ["I am a number.", middle.replace("I halve it", "I halve").replace(
        "I double it", "I double"), f"Now I am {result}."]
    forward = _riddle_apply(steps, result)
    return _q("riddle", prompt, hint or "Work backwards from the end.",
              {"kind": "card", "lines": lines, "steps": [list(s) for s in steps], "result": result},
              {"type": "number", "value": ans},
              **_numbers(ans, [result, forward if forward is not None else result + 1,
                               ans + 1, ans - 1]))


# ---- story sums, by schema ---------------------------------------------------

def _he(name):
    return "She" if name in GIRLS else "He"


STORY = {
    # change: something is added or taken away
    "join": lambda n, t, a, b: ([f"{n} has {a} {t}.", f"{_he(n)} gets {b} more.", "How many now?"],
                                a + b, [a - b, b, a + b + 1]),
    "leave": lambda n, t, a, b: ([f"{n} has {a} {t}.", f"{_he(n)} gives away {b}.", "How many are left?"],
                                 a - b, [a + b, b, a - b - 1]),
    "gain": lambda n, t, a, b: ([f"{n} had {a} {t}.", f"Now {_he(n).lower()} has {b}.",
                                 "How many did " + _he(n).lower() + " get?"],
                                b - a, [a + b, b, a]),
    # combine: two parts make a whole
    "total": lambda n, t, a, b: ([f"{n} has {a} red {t}.", f"{_he(n)} has {b} blue {t}.",
                                  f"How many {t} in all?"],
                                 a + b, [a - b, a, b]),
    "part": lambda n, t, a, b: ([f"There are {a} {t}.", f"{b} of them are big.",
                                 "How many are not big?"],
                                a - b, [a + b, b, a]),
    # compare
    "more": lambda n, t, a, b, m: ([f"{n} has {a} {t}.", f"{m} has {b} more than {n}.",
                                    f"How many does {m} have?"],
                                   a + b, [a - b, b, a]),
    "fewer": lambda n, t, a, b, m: ([f"{n} has {a} {t}.", f"{m} has {b} fewer.",
                                     f"How many does {m} have?"],
                                    a - b, [a + b, b, a]),
    "diff": lambda n, t, a, b, m: ([f"{n} has {a} {t}.", f"{m} has {b} {t}.",
                                    f"How many more does {n} have?"],
                                   a - b, [a + b, a, b]),
    # equal groups
    "groups": lambda n, t, a, b: ([f"There are {a} bags.", f"Each bag has {b} {t}.",
                                   f"How many {t} in all?"],
                                  a * b, [a + b, a * b + b, a * b - b]),
    "share": lambda n, t, a, b: ([f"{a} {t} are shared equally.", f"{b} friends get them.",
                                  "How many does each get?"],
                                 a // b, [a - b, b, a // b + 1]),
    "legs": lambda n, t, a, b: ([f"{a} {t} are playing.", f"Each has {b} legs.",
                                 "How many legs in all?"],
                                a * b, [a + b, a, a * b + 1]),
}


def story(prompt, schema, name, thing, a, b, other=None, hint=None):
    fn = STORY[schema]
    lines, ans, mistakes = fn(name, thing, a, b, other) if schema in ("more", "fewer", "diff") \
        else fn(name, thing, a, b)
    if schema == "share" and a % b:
        raise ValueError("a fair share must come out even")
    if ans < 0 or ans > 100:
        raise ValueError(f"the answer {ans} is out of range for seven")
    return _q("story", prompt, hint or "Is something joining, leaving, or being compared?",
              {"kind": "card", "lines": lines, "schema": schema, "nums": [a, b]},
              {"type": "number", "value": ans}, **_numbers(ans, mistakes))


def bars(prompt, top_name, top, low_name, low, hide, hint=None):
    """Two bars, drawn to scale, with one number hidden. The picture carries it."""
    if top <= low:
        raise ValueError("the top bar is the bigger one")
    diff = top - low
    ans = {"top": top, "low": low, "diff": diff}[hide]
    shown = {"top": None if hide == "top" else top, "low": None if hide == "low" else low,
             "diff": None if hide == "diff" else diff}
    mistakes = {"top": [low - diff, low, diff], "low": [top + diff, top, diff],
                "diff": [top + low, top, low]}[hide]
    return _q("bars", prompt, hint or "The longer bar is the shorter bar plus the gap.",
              {"kind": "bars", "names": [top_name, low_name], "values": [top, low],
               "shown": shown, "hide": hide},
              {"type": "number", "value": ans}, **_numbers(ans, mistakes))


# ---- number patterns -----------------------------------------------------------

def series(prompt, terms, gap, hint=None):
    shown = [None if i == gap else t for i, t in enumerate(terms)]
    if sum(t is not None for t in shown) < 4:
        raise ValueError("show at least four numbers")
    ans = terms[gap]
    mistakes = [ans + 1, ans - 1]
    if gap >= 2:
        mistakes.append(terms[gap - 1] + (terms[gap - 1] - terms[gap - 2]) + 1)
    if 0 < gap < len(terms) - 1:
        mistakes.append(terms[gap - 1] + 1)
    return _q("series", prompt, hint or "How does each number change to the next?",
              {"kind": "series", "terms": shown, "gapAt": gap},
              {"type": "number", "value": ans}, **_numbers(ans, mistakes))


def rule_words(r):
    t = r[0]
    if t == "add":
        return f"Add {r[1]} each time"
    if t == "take":
        return f"Take away {r[1]} each time"
    if t == "double":
        return "Double each time"
    if t == "grow":
        return "Add 1 more each time"
    raise ValueError(t)


def rule_run(r, first, n):
    out, v, step = [first], first, 1
    for _ in range(n - 1):
        if r[0] == "add":
            v += r[1]
        elif r[0] == "take":
            v -= r[1]
        elif r[0] == "double":
            v *= 2
        elif r[0] == "grow":
            v += step
            step += 1
        out.append(v)
    return out


def series_rule(prompt, terms, rules, hint=None):
    """Which rule makes this row. rules[0] is the one; the others fit a step or two."""
    fits = [i for i, r in enumerate(rules) if rule_run(r, terms[0], len(terms)) == terms]
    if fits != [0]:
        raise ValueError(f"rules that fit: {fits}; need exactly the first")
    q = _q("seriesRule", prompt, hint or "Check the rule on every step, not just the first.",
           {"kind": "series", "terms": terms}, {"type": "option", "value": 0},
           optionsText=[rule_words(r) for r in rules], optionRules=[list(r) for r in rules])
    q["_rotate"] = ["optionsText", "optionRules"]
    return q


# ============================================================ 2. order and position

DIMS = {"tall": ("taller", "shorter", "tallest", "shortest"),
        "old": ("older", "younger", "oldest", "youngest"),
        "fast": ("faster", "slower", "fastest", "slowest"),
        "heavy": ("heavier", "lighter", "heaviest", "lightest")}


def _orders(people, clues):
    """Every order, most first, that agrees with the clues."""
    out = []
    for perm in itertools.permutations(people):
        pos = {p: i for i, p in enumerate(perm)}
        if all((pos[a] < pos[b]) == (w == "more") for a, b, w in clues):
            out.append(perm)
    return out


def rank(prompt, dim, people, clues, ask, hint=None):
    """Who is tallest, from comparisons. ask: "top", "bottom" or "second"."""
    more, less, most, least = DIMS[dim]
    orders = _orders(people, clues)
    pick = {"top": 0, "bottom": -1, "second": 1}[ask]
    answers = {o[pick] for o in orders}
    if len(answers) != 1:
        raise ValueError(f"{len(answers)} people could be the answer")
    word = {"top": most, "bottom": least, "second": f"second {most}"}[ask]
    if word not in prompt:
        raise ValueError(f'the prompt does not ask for the "{word}"')
    ans = answers.pop()
    lines = [f"{a} is {more if w == 'more' else less} than {b}." for a, b, w in clues]
    q = _q("rank", prompt, hint or "Put them in order, one clue at a time.",
           {"kind": "card", "lines": lines, "dim": dim, "people": list(people),
            "clues": [list(c) for c in clues], "ask": ask},
           {"type": "option", "value": list(people).index(ans)}, optionsText=list(people))
    return _options(q, "optionsText")


def rank_count(prompt, dim, people, clues, who, hint=None):
    more = DIMS[dim][0]
    if f"{more} than {who}" not in prompt:
        raise ValueError("the prompt asks about someone else")
    orders = _orders(people, clues)
    counts = {o.index(who) for o in orders}
    if len(counts) != 1:
        raise ValueError("the clues do not settle the count")
    ans = counts.pop()
    lines = [f"{a} is {more if w == 'more' else DIMS[dim][1]} than {b}." for a, b, w in clues]
    return _q("rankCount", prompt, hint or "Put them in order first, then count.",
              {"kind": "card", "lines": lines, "dim": dim, "people": list(people),
               "clues": [list(c) for c in clues], "who": who},
              {"type": "number", "value": ans},
              **_numbers(ans, [len(people) - 1 - ans, ans + 1, len(people) - 1]))


def ordinal(n):
    return {1: "1st", 2: "2nd", 3: "3rd"}.get(n, f"{n}th")


def queue_back(prompt, name, n, front, hint=None):
    """A line drawn with one child marked: what place is that from the back?"""
    if not 1 <= front <= n <= 10:
        raise ValueError("a line of up to ten")
    ans = n - front + 1
    return _q("queueBack", prompt, hint or "Count from the other end of the line.",
              {"kind": "line", "n": n, "mark": front, "name": name},
              {"type": "number", "value": ans},
              **_numbers(ans, [front, n - front, ans + 1], lo=1))


def queue_calc(prompt, kind, a, b, name=None, other=None, hint=None):
    """Places in a line, told in words. kind: "total" or "between"."""
    if kind == "total":
        lines = [f"{name} is {ordinal(a)} from the front.", f"{name} is {ordinal(b)} from the back.",
                 "How many are in the line?"]
        ans, mistakes = a + b - 1, [a + b, a + b + 1, max(a, b)]
    else:
        lines = [f"{name} is {ordinal(a)} in the line.", f"{other} is {ordinal(b)} in the line.",
                 "How many stand between them?"]
        ans, mistakes = abs(a - b) - 1, [abs(a - b), abs(a - b) + 1, a + b]
        if ans < 1:
            raise ValueError("nobody stands between them")
    return _q("queueCalc", prompt, hint or "Draw the line in your head.",
              {"kind": "card", "lines": lines, "calc": kind, "nums": [a, b]},
              {"type": "number", "value": ans}, **_numbers(ans, mistakes, lo=0))


def queue_who(prompt, names, nth, end, hint=None):
    """A named line; who is nth from the front or back."""
    if f"{ordinal(nth)} from the {end}" not in prompt:
        raise ValueError("the prompt asks about another place")
    idx = nth - 1 if end == "front" else len(names) - nth
    ans = names[idx]
    wrong = names[len(names) - nth] if end == "front" else names[nth - 1]
    opts = [ans]
    for c in [wrong] + [names[(idx + d) % len(names)] for d in (1, -1, 2)]:
        if c not in opts:
            opts.append(c)
    q = _q("queueWho", prompt, hint or "Find which end is the front first.",
           {"kind": "line", "n": len(names), "names": list(names), "nth": nth, "end": end},
           {"type": "option", "value": 0}, optionsText=opts[:4])
    return _options(q, "optionsText")


DIRS = ["North", "East", "South", "West"]
TURN_TEXT = {"right": "turns right", "left": "turns left", "around": "turns around"}


def turns(prompt, name, start, moves, hint=None):
    """Facing one way, then turning. The four directions keep the same order on
    screen every time, because a compass a child can learn is part of fairness."""
    if name not in prompt:
        raise ValueError("the prompt is about someone else")
    i = DIRS.index(start)
    for m in moves:
        i = (i + {"right": 1, "left": -1, "around": 2}[m]) % 4
    ans = i
    if len(moves) == 1:
        lines = [f"{name} faces {start}.", f"{_he(name)} {TURN_TEXT[moves[0]]}."]
    else:
        lines = [f"{name} faces {start}.", f"{_he(name)} {TURN_TEXT[moves[0]]}.",
                 f"Then {_he(name).lower()} {TURN_TEXT[moves[1]]}."]
    return _q("turns", prompt, hint or "Turn your own body the same way.",
              {"kind": "compass", "lines": lines, "start": start, "moves": list(moves)},
              {"type": "option", "value": ans}, optionsText=list(DIRS), fixedOrder=True)


SHAPE_WORDS = ["star", "heart", "circle", "square", "triangle", "diamond"]


def shelf(prompt, items, target, side, steps, hint=None):
    """A row of shapes: which is just left (or two places right) of the heart."""
    if target not in prompt or side not in prompt:
        raise ValueError("the prompt does not match the question")
    if len(set(items)) != len(items):
        raise ValueError("every shape in the row must be different")
    t = items.index(target)
    j = t - steps if side == "left" else t + steps
    if not 0 <= j < len(items):
        raise ValueError("that place is off the end of the row")
    ans = items[j]
    wrong_side = t + steps if side == "left" else t - steps
    opts = [ans]
    for c in ([items[wrong_side]] if 0 <= wrong_side < len(items) else []) + \
             [items[k] for k in (j + 1, j - 1, t) if 0 <= k < len(items)] + list(items):
        if c not in opts and c != target:
            opts.append(c)
    q = _q("shelf", prompt, hint or "Hold up your left hand to check which side is left.",
           {"kind": "shelf", "items": list(items), "target": target, "side": side, "steps": steps},
           {"type": "option", "value": 0},
           optionCells=[{"kind": k, "color": "primary", "rotation": 0} for k in opts[:4]])
    return _options(q, "optionCells")


# ============================================================ 3. relations and codes

FEMALE_TERMS = {"mother", "sister", "daughter", "grandmother", "aunt", "wife", "granddaughter"}
TERM_EDGE = {"mother": "P", "father": "P", "son": "C", "daughter": "C", "sister": "S",
             "brother": "S", "wife": "W", "husband": "W", "grandmother": "PP",
             "grandfather": "PP", "aunt": "SP", "uncle": "SP"}
INVERSE = {"P": "C", "C": "P", "S": "S", "W": "W"}
REDUCE = [("PS", "P"), ("SC", "C"), ("WP", "P"), ("CW", "C"), ("SS", "S"), ("CP", "S")]
WORD_TERM = {"P": ("mother", "father"), "C": ("daughter", "son"), "S": ("sister", "brother"),
             "W": ("wife", "husband"), "PP": ("grandmother", "grandfather"),
             "CC": ("granddaughter", "grandson"), "SP": ("aunt", "uncle"),
             "CSP": ("cousin", "cousin")}


def _reduce(word):
    changed = True
    while changed:
        changed = False
        for a, b in REDUCE:
            if a in word:
                word = word.replace(a, b, 1)
                changed = True
    return word


def relation_of(facts, x, y):
    """Every relation word x can be to y, walking only the facts given."""
    edges = {}
    for a, term, b in facts:
        w = TERM_EDGE[term]
        edges.setdefault(a, []).append((b, w))
        inv = "".join(INVERSE[ch] for ch in reversed(w))
        edges.setdefault(b, []).append((a, inv))
    found = set()
    stack = [(x, "", {x})]
    while stack:
        node, word, seen = stack.pop()
        for nxt, w in edges.get(node, []):
            if nxt in seen:
                continue
            nw = _reduce(word + w)
            if nxt == y:
                found.add(nw)
            else:
                stack.append((nxt, nw, seen | {nxt}))
    return found


def gender_of(facts, person):
    for a, term, b in facts:
        if a == person:
            return "F" if term in FEMALE_TERMS else "M"
    return None


def relation_term(facts, x, y):
    words = relation_of(facts, x, y)
    if len(words) != 1:
        raise ValueError(f"{x} to {y} can be read {len(words)} ways: {words}")
    w = words.pop()
    if w not in WORD_TERM:
        raise ValueError(f"{x} to {y} is '{w}', which is not a relation for seven year olds")
    g = gender_of(facts, x)
    if g is None and w != "CSP":
        raise ValueError(f"no clue says whether {x} is a girl or a boy")
    return WORD_TERM[w][0 if g == "F" else 1]


RELATION_TRAPS = {
    "mother": ["father", "sister", "grandmother", "daughter"],
    "father": ["mother", "brother", "grandfather", "son"],
    "sister": ["brother", "mother", "daughter", "aunt"],
    "brother": ["sister", "father", "son", "uncle"],
    "son": ["daughter", "father", "brother", "grandson"],
    "daughter": ["son", "mother", "sister", "granddaughter"],
    "grandmother": ["grandfather", "mother", "aunt", "granddaughter"],
    "grandfather": ["grandmother", "father", "uncle", "grandson"],
    "grandson": ["granddaughter", "son", "grandfather", "brother"],
    "granddaughter": ["grandson", "daughter", "grandmother", "sister"],
    "aunt": ["uncle", "mother", "sister", "grandmother"],
    "uncle": ["aunt", "father", "brother", "grandfather"],
    "cousin": ["brother", "sister", "uncle", "aunt"],
    "wife": ["husband", "mother", "sister", "daughter"],
    "husband": ["wife", "father", "brother", "son"],
}


def fact_line(f):
    a, term, b = f
    return f"{a} is {b}'s {term}."


def relation(prompt, facts, x, y, hint=None):
    """Who is x to y, from what the clues say and nothing else."""
    if x not in prompt or y not in prompt:
        raise ValueError("the prompt asks about other people")
    ans = relation_term(facts, x, y)
    opts = [ans] + RELATION_TRAPS[ans][:3]
    q = _q("relation", prompt, hint or "Draw the family: who is above, who is beside?",
           {"kind": "card", "lines": [fact_line(f) for f in facts],
            "facts": [list(f) for f in facts], "x": x, "y": y},
           {"type": "option", "value": 0}, optionsText=opts)
    return _options(q, "optionsText")


def relation_who(prompt, facts, y, term, hint=None):
    """Tap Riya's grandmother: the one person in the clues who is that to y."""
    if term not in prompt or y not in prompt:
        raise ValueError("the prompt asks for something else")
    people = []
    for a, _, b in facts:
        for p in (a, b):
            if p not in people and p != y:
                people.append(p)
    hits = []
    for p in people:
        try:
            if relation_term(facts, p, y) == term:
                hits.append(p)
        except ValueError:
            pass
    if len(hits) != 1:
        raise ValueError(f"{len(hits)} people are {y}'s {term}")
    if len(people) < 3:
        raise ValueError("need at least three names to choose from")
    opts = [hits[0]] + [p for p in people if p != hits[0]][:3]
    q = _q("relationWho", prompt, hint or "Find each person's place in the family.",
           {"kind": "card", "lines": [fact_line(f) for f in facts],
            "facts": [list(f) for f in facts], "y": y, "term": term},
           {"type": "option", "value": 0}, optionsText=opts)
    return _options(q, "optionsText")


# ---- analogies -------------------------------------------------------------------
# Facts a seven year old in India can be expected to know, one relation per pair.
# pz_grade.py checks the questions are fair against these facts -- exactly one
# option fits, and the example pair is not also another relation -- but it
# cannot re-derive a fact like "a baby cow is a calf". That is said plainly here
# so nobody later mistakes the check for more than it is.
REL = {
    "baby": {"cow": "calf", "dog": "puppy", "cat": "kitten", "hen": "chick", "sheep": "lamb",
             "duck": "duckling", "frog": "tadpole", "lion": "cub", "horse": "foal"},
    "home": {"bird": "nest", "bee": "hive", "lion": "den", "horse": "stable", "dog": "kennel",
             "spider": "web", "rabbit": "burrow"},
    "opposite": {"hot": "cold", "big": "small", "up": "down", "day": "night", "happy": "sad",
                 "fast": "slow", "wet": "dry", "full": "empty", "tall": "short", "in": "out"},
    "sense": {"eye": "see", "ear": "hear", "nose": "smell", "tongue": "taste"},
    "work": {"doctor": "hospital", "teacher": "school", "farmer": "farm", "pilot": "plane",
             "cook": "kitchen"},
    "colour": {"grass": "green", "banana": "yellow", "snow": "white", "coal": "black",
               "tomato": "red", "sky": "blue"},
}
REL_ARROW = {"baby": "baby", "home": "home", "opposite": "opposite", "sense": "does",
             "work": "works in", "colour": "colour"}


def word_analogy(prompt, rel, a, c, extra_wrong=(), hint=None):
    """cow → calf, dog → ? . The wrong options are the classic slips: a word from a
    different relation to the same thing, the example's own answer, and the right
    relation to a different thing."""
    table = REL[rel]
    b, ans = table[a], table[c]
    other_rels = [r for r, t in REL.items() if r != rel and t.get(a) == b]
    if other_rels:
        raise ValueError(f"{a} → {b} is also a {other_rels} pair")
    wrong = list(extra_wrong)
    for r, t in REL.items():
        if r != rel and c in t:
            wrong.append(t[c])
    wrong.append(b)
    for k, v in table.items():
        if k not in (a, c):
            wrong.append(v)
    opts = [ans]
    for w in wrong:
        if w not in opts and w != ans:
            opts.append(w)
    opts = opts[:4]
    if sum(1 for o in opts if o == ans) != 1:
        raise ValueError("the answer appears twice")
    q = _q("wordAnalogy", prompt, hint or "Say how the first two go together. Use the same link.",
           {"kind": "wordPairs", "pairs": [[a, b], [c, None]], "rel": rel},
           {"type": "option", "value": 0}, optionsText=opts)
    return _options(q, "optionsText")


NUM_RULES = {"add": lambda x, k: x + k, "take": lambda x, k: x - k, "times": lambda x, k: x * k}


def number_analogy(prompt, rule, k, examples, ask, hint=None):
    """2 → 4, 3 → 6, 5 → ? . Two examples, so "add 2" and "double" cannot both fit."""
    f = NUM_RULES[rule]
    pairs = [[x, f(x, k)] for x in examples]
    fitting = set()
    for r2, g in NUM_RULES.items():
        for k2 in range(1, 11):
            if all(g(x, k2) == y for x, y in pairs):
                fitting.add(g(ask, k2))
    if len(fitting) != 1:
        raise ValueError(f"the examples fit rules giving {fitting}")
    ans = f(ask, k)
    if ans < 0 or ans > 100:
        raise ValueError("out of range")
    first = pairs[0]
    slip = ask + (first[1] - first[0])
    return _q("numberAnalogy", prompt, hint or "What happens to each number? Do the same.",
              {"kind": "numPairs", "pairs": pairs + [[ask, None]]},
              {"type": "number", "value": ans},
              **_numbers(ans, [slip, ans + 1, ans - 1, ask]))


# ---- codes -----------------------------------------------------------------------
ALPHA = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"


def shift_word(w, k):
    return "".join(ALPHA[(ALPHA.index(ch) + k) % 26] for ch in w)


def letter_code(prompt, example, ask, rule, hint=None):
    """CAT is written DBU. How is PEN written? rule: ("shift", k) or ("reverse",)."""
    make = (lambda w: shift_word(w, rule[1])) if rule[0] == "shift" else (lambda w: w[::-1])
    ex = make(example)
    fits = [("shift", k) for k in range(1, 26) if shift_word(example, k) == ex]
    if example[::-1] == ex:
        fits.append(("reverse",))
    if len(fits) != 1:
        raise ValueError(f"the example fits {len(fits)} rules")
    ans = make(ask)
    wrong = [shift_word(ask, -rule[1]) if rule[0] == "shift" else shift_word(ask, 1),
             ask[::-1] if rule[0] == "shift" else ask,
             shift_word(ask, rule[1] + 1) if rule[0] == "shift" else ans[1:] + ans[0],
             shift_word(ask, 2)]
    opts = [ans]
    for w in wrong:
        if w not in opts:
            opts.append(w)
    q = _q("wordCode", prompt, hint or "Look at one letter of the example at a time.",
           {"kind": "example", "example": [example, ex], "word": ask, "mode": "encode"},
           {"type": "option", "value": 0}, optionsText=opts[:4])
    return _options(q, "optionsText")


def _nums(w):
    return " ".join(str(ALPHA.index(ch) + 1) for ch in w)


def number_code(prompt, example, ask, mode, hint=None):
    """A is 1, B is 2: BAD is 2 1 4. mode "encode" asks the numbers, "decode" the word."""
    if max(ALPHA.index(ch) for ch in example + ask) > 9:
        raise ValueError("keep to A to J, so every number is one digit")
    if mode == "encode":
        ans = _nums(ask)
        wrong = [_nums(ask[::-1]), " ".join(str(ALPHA.index(ch) + 2) for ch in ask),
                 " ".join(str(ALPHA.index(ch)) for ch in ask)]
        shown = ask
    else:
        ans = ask
        shown = _nums(ask)
        wrong = [ask[::-1], shift_word(ask, 1), shift_word(ask, -1)]
    opts = [ans]
    for w in wrong:
        if w not in opts:
            opts.append(w)
    q = _q("numCode", prompt, hint or "A is 1. Count along the alphabet for the rest.",
           {"kind": "numExample", "example": [example, _nums(example)], "word": shown, "mode": mode},
           {"type": "option", "value": 0}, optionsText=opts[:4])
    return _options(q, "optionsText")


def alphabet(prompt, base, offset, hint=None):
    """Just after M, just before K, two after P."""
    if base not in prompt:
        raise ValueError("the prompt names another letter")
    i = ALPHA.index(base) + offset
    if not 0 <= i < 26:
        raise ValueError("off the end of the alphabet")
    ans = ALPHA[i]
    wrong = [ALPHA[ALPHA.index(base) - offset]] if 0 <= ALPHA.index(base) - offset < 26 else []
    wrong += [ALPHA[j] for j in (i + 1, i - 1, i + 2) if 0 <= j < 26]
    opts = [ans]
    for w in wrong:
        if w not in opts and w != base:
            opts.append(w)
    q = _q("alphabet", prompt, hint or "Say the alphabet up to that letter.",
           {"kind": "letter", "base": base, "offset": offset},
           {"type": "option", "value": 0}, optionsText=opts[:4])
    return _options(q, "optionsText")


# ============================================================ 4. logic

CATEGORIES = {
    "fruit": ["apple", "mango", "banana", "grapes", "orange", "guava", "papaya", "cherry"],
    "vegetable": ["carrot", "potato", "onion", "cabbage", "peas", "brinjal", "spinach", "radish"],
    "animal": ["lion", "cow", "dog", "cat", "horse", "goat", "zebra", "elephant"],
    "bird": ["crow", "parrot", "sparrow", "peacock", "eagle", "pigeon", "owl", "duck"],
    "vehicle": ["bus", "car", "train", "cycle", "truck", "boat", "plane", "scooter"],
    "colour": ["red", "blue", "green", "yellow", "pink", "black", "white", "brown"],
    "body": ["hand", "leg", "nose", "ear", "eye", "knee", "foot", "elbow"],
    "clothes": ["shirt", "sock", "cap", "dress", "coat", "scarf", "skirt", "shorts"],
    "shape": ["circle", "square", "triangle", "oval", "rectangle"],
}


def category_of(word):
    return [c for c, ws in CATEGORIES.items() if word in ws]


def odd_word(prompt, words, hint=None):
    """Three from one group, one from another. Which is which is worked out."""
    cats = [category_of(w) for w in words]
    if any(len(c) != 1 for c in cats):
        raise ValueError("every word must belong to exactly one group")
    names = [c[0] for c in cats]
    common = [c for c in set(names) if names.count(c) == 3]
    odd = [i for i, c in enumerate(names) if names.count(c) == 1]
    if len(common) != 1 or len(odd) != 1:
        raise ValueError(f"not three-and-one: {names}")
    q = _q("oddWord", prompt, hint or "Say what three of them are.",
           {"kind": "words", "words": list(words), "groups": names},
           {"type": "option", "value": odd[0]}, optionsText=list(words))
    return _options(q, "optionsText")


NUMBER_PROPS = {
    "even": lambda n: n % 2 == 0,
    "fives": lambda n: n % 5 == 0,
    "tens": lambda n: n % 10 == 0,
    "two digits": lambda n: n >= 10,
    "tens digit 2": lambda n: n // 10 == 2,
}


def odd_number(prompt, nums, hint=None):
    """One number breaks what the other three share, on exactly one property."""
    readings = []
    for name, f in NUMBER_PROPS.items():
        vals = [f(n) for n in nums]
        lone = [i for i, v in enumerate(vals) if vals.count(v) == 1]
        if len(lone) == 1:
            readings.append((name, lone[0]))
    picks = {i for _, i in readings}
    if len(picks) != 1:
        raise ValueError(f"readings {readings}: need exactly one odd number")
    q = _q("oddNumber", prompt, hint or "Are they odd or even? Do they end in 0 or 5?",
           {"kind": "words", "words": [str(n) for n in nums], "nums": list(nums)},
           {"type": "option", "value": picks.pop()}, optionsText=[str(n) for n in nums])
    return _options(q, "optionsText")


DAYS = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August",
          "September", "October", "November", "December"]


def weekday(prompt, form, day, n=1, hint=None):
    """forms: after (today + n), ago (today - n), today (tomorrow is day),
    tomorrow (yesterday was day)."""
    i = DAYS.index(day)
    if form == "after":
        lines, ans, slip = [f"Today is {day}.", f"What day is it in {n} days?"], i + n, i - n
    elif form == "ago":
        lines, ans, slip = [f"Today is {day}.", f"What day was it {n} days ago?"], i - n, i + n
    elif form == "today":
        lines, ans, slip = [f"Tomorrow is {day}.", "What day is it today?"], i - 1, i + 1
    elif form == "tomorrow":
        lines, ans, slip = [f"Yesterday was {day}.", "What day is it tomorrow?"], i + 2, i + 1
    else:
        raise ValueError(form)
    ans %= 7
    opts = [DAYS[ans]]
    for j in (slip, ans + 1, ans - 1, ans + 2):
        if DAYS[j % 7] not in opts:
            opts.append(DAYS[j % 7])
    q = _q("weekday", prompt, hint or "Say the days of the week in order.",
           {"kind": "card", "lines": lines, "form": form, "day": day, "n": n},
           {"type": "option", "value": 0}, optionsText=opts[:4])
    return _options(q, "optionsText")


def month(prompt, base, offset, hint=None):
    i = MONTHS.index(base)
    word = {1: "just after", -1: "just before", 2: "two months after"}[offset]
    lines = [f"Which month comes {word} {base}?"]
    ans = (i + offset) % 12
    opts = [MONTHS[ans]]
    for j in (i - offset, ans + 1, ans - 1, i):
        if MONTHS[j % 12] not in opts:
            opts.append(MONTHS[j % 12])
    q = _q("month", prompt, hint or "Say the months in order from January.",
           {"kind": "card", "lines": lines, "base": base, "offset": offset},
           {"type": "option", "value": 0}, optionsText=opts[:4])
    return _options(q, "optionsText")


def time_words(h, m):
    return f"{h} o'clock" if m == 0 else f"half past {h}"


def clock(prompt, h, m, form, delta=0, hint=None):
    """A clock face. forms: read (what time does it show), after, before."""
    if m not in (0, 30) or not 1 <= h <= 12:
        raise ValueError("o'clock and half past only")
    if form == "read":
        lines, nh = [], h
        wrong = [time_words(h, 30 - m), time_words(h % 12 + 1, m), time_words(m // 5 if m else 12, 0)]
    else:
        sign = 1 if form == "after" else -1
        nh = (h - 1 + sign * delta) % 12 + 1
        lines = [f"What time is it {delta} hours later?" if form == "after"
                 else f"What time was it {delta} hours before?"]
        back = (h - 1 - sign * delta) % 12 + 1
        wrong = [time_words(back, m), time_words(nh % 12 + 1, m), time_words(nh, 30 - m)]
    ans = time_words(nh, m)
    opts = [ans]
    for w in wrong:
        if w not in opts:
            opts.append(w)
    q = _q("clock", prompt, hint or "The short hand shows the hour.",
           {"kind": "clock", "h": h, "m": m, "form": form, "delta": delta, "lines": lines},
           {"type": "option", "value": 0}, optionsText=opts[:4])
    return _options(q, "optionsText")


def combos(prompt, name, a, a_noun, b, b_noun, hint=None):
    """3 tops and 2 skirts: how many different outfits."""
    if not (2 <= a <= 4 and 2 <= b <= 4):
        raise ValueError("keep to 2 to 4 of each")
    lines = [f"{name} has {a} {a_noun} and {b} {b_noun}.",
             f"{_he(name)} picks one of each.", "How many different ways?"]
    ans = a * b
    return _q("combos", prompt, hint or "Take one of the first. How many can go with it?",
              {"kind": "card", "lines": lines, "nums": [a, b]},
              {"type": "number", "value": ans}, **_numbers(ans, [a + b, ans + 1, max(a, b)]))
