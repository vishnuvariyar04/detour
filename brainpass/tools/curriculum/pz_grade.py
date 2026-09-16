# -*- coding: utf-8 -*-
"""Works out every Puzzles & Logic answer a SECOND time, from what the child reads.

Wherever a question is words, this reads the WORDS -- the clue lines and the
question on screen -- not the numbers and names the author passed to the kit. So
if a story says "gives away" but was built as an adding story, or a family clue
says "sister" but was built as "brother", the answer this file reaches will
disagree with the stored one and the build fails. That is the check a
hand-written question bank never gets.

It shares no code with puzzles_kit.py, with one declared exception: the word
facts behind analogies and odd-one-out ("a baby cow is a calf", "a crow is a
bird"). Facts like that cannot be re-derived, only looked up. For those, this
file checks the question is FAIR against the facts -- exactly one option fits,
and the example pair is not also some other relation -- not that the facts are
true. Checking the facts is a job for a person, on the review wall.
"""
import calendar, datetime, itertools, json, os, re, sys

from puzzles_kit import REL, CATEGORIES      # facts only; see the docstring

HERE = os.path.dirname(os.path.abspath(__file__))
PATH = os.path.join(HERE, "..", "..", "assets", "curriculum", "puzzles_and_logic.json")
FAILS, COUNT = [], {}


def bad(qid, msg):
    FAILS.append(f"{qid}: {msg}")


def nums_in(text):
    return [int(x) for x in re.findall(r"\d+", text)]


# ---- word tables written here, not imported --------------------------------
COMPARE = {"taller": ("tall", 1), "shorter": ("tall", -1), "older": ("old", 1),
           "younger": ("old", -1), "faster": ("fast", 1), "slower": ("fast", -1),
           "heavier": ("heavy", 1), "lighter": ("heavy", -1)}
SUPER = {"tallest": ("tall", 1), "shortest": ("tall", -1), "oldest": ("old", 1),
         "youngest": ("old", -1), "fastest": ("fast", 1), "slowest": ("fast", -1),
         "heaviest": ("heavy", 1), "lightest": ("heavy", -1)}
ORD = {"1st": 1, "2nd": 2, "3rd": 3, **{f"{n}th": n for n in range(4, 11)}}
FEMALE = {"mother", "sister", "daughter", "grandmother", "aunt", "wife", "granddaughter"}
COMPASS = {"North": (0, 1), "East": (1, 0), "South": (0, -1), "West": (-1, 0)}


def grade(qid, q):
    sh, p = q["shape"], q.get("pic") or {}
    a = q["answer"]["value"]
    opts = q.get("optionsText")
    pr = q["prompt"]
    lines = p.get("lines") or []
    COUNT[sh] = COUNT.get(sh, 0) + 1

    def pick(want):
        hits = [i for i, o in enumerate(opts) if o == want]
        if hits != [a]:
            bad(qid, f"the words give {want!r}, stored option {a} ({opts[a]!r})")

    if sh == "equation":
        hide = p["hide"]
        sols = []
        for v in range(0, 101):
            l, r, res = (v if hide == "left" else p["left"], v if hide == "right" else p["right"],
                         v if hide == "result" else p["result"])
            if (l + r if p["op"] == "+" else l - r) == res:
                sols.append(v)
        if sols != [a]:
            bad(qid, f"numbers that fill the box: {sols}, stored {a}")

    elif sh == "riddle":
        m = re.match(r"I (.+)\.$", lines[1])
        steps = []
        for part in m.group(1).split(", then "):
            part = part.replace(" it", "")
            if part.startswith("add "):
                steps.append(lambda x, k=int(part[4:]): x + k)
            elif part.startswith("take away "):
                steps.append(lambda x, k=int(part[10:]): x - k)
            elif part == "double":
                steps.append(lambda x: x * 2)
            elif part == "halve":
                steps.append(lambda x: x // 2 if x % 2 == 0 else None)
            else:
                return bad(qid, f"cannot read the riddle step {part!r}")
        end = nums_in(lines[2])[0]
        sols = []
        for x in range(0, 101):
            v = x
            for f in steps:
                v = None if v is None else f(v)
            if v == end:
                sols.append(x)
        if sols != [a]:
            bad(qid, f"numbers that fit the riddle: {sols}, stored {a}")

    elif sh == "story":
        text = " ".join(lines)
        n = nums_in(text)
        if n != p["nums"]:
            return bad(qid, f"the story shows {n} but was built from {p['nums']}")
        if len(n) == 3:
            x, y, z = n
            if re.search(r"gets \d+, then gives away \d+", text):
                want = x + y - z
            elif re.search(r"gives away \d+, then gets \d+", text):
                want = x - y + z
            elif "bags of" in text and "are eaten" in text:
                want = x * y - z
            elif "red and" in text and "blue" in text:
                want = x + y + z
            else:
                return bad(qid, "cannot tell what the two-step story is doing")
        else:
            x, y = n
            if "gets" in text and "more" in text:
                want = x + y
            elif "gives away" in text:
                want = x - y
            elif " had " in text and "Now" in text:
                want = y - x
            elif "red" in text and "blue" in text:
                want = x + y
            elif "of them are big" in text:
                want = x - y
            elif "more than" in text:
                want = x + y
            elif "fewer" in text:
                want = x - y
            elif "How many more does" in text:
                want = x - y
            elif "Each bag has" in text or "Each has" in text:
                want = x * y
            elif "shared equally" in text:
                want = x // y if x % y == 0 else None
            else:
                return bad(qid, "cannot tell what the story is doing")
        if want != a:
            bad(qid, f"reading the story gives {want}, stored {a}")

    elif sh == "bars":
        top, low = p["values"]
        want = {"top": top, "low": low, "diff": top - low}[p["hide"]]
        shown = [v for v in p["shown"].values() if v is not None]
        if len(shown) != 2 or want != a:
            bad(qid, f"the bars give {want}, stored {a}")

    elif sh == "series":
        t = p["terms"]
        g = t.index(None)
        known = [(i, v) for i, v in enumerate(t) if v is not None]
        answers = set()
        for cand in range(0, 201):
            full = [cand if v is None else v for v in t]
            d1 = [full[i + 1] - full[i] for i in range(len(full) - 1)]
            d2 = [d1[i + 1] - d1[i] for i in range(len(d1) - 1)]
            ratio = all(full[i] and full[i + 1] == 2 * full[i] for i in range(len(full) - 1))
            if len(set(d1)) == 1 or (len(set(d2)) == 1 and d2[0] == 1) or ratio:
                answers.add(cand)
        if answers != {a}:
            bad(qid, f"numbers that keep a simple rule: {sorted(answers)}, stored {a}")

    elif sh == "seriesRule":
        t = p["terms"]
        hits = []
        for i, r in enumerate(q["optionRules"]):
            v, step, ok = t[0], 1, True
            for want in t[1:]:
                if r[0] == "add":
                    v += r[1]
                elif r[0] == "take":
                    v -= r[1]
                elif r[0] == "double":
                    v *= 2
                else:
                    v += step
                    step += 1
                ok = ok and v == want
            if ok:
                hits.append(i)
        if hits != [a]:
            bad(qid, f"rules that fit: {hits}, stored {a}")

    elif sh in ("rank", "rankCount"):
        facts = []
        for l in lines:
            m = re.match(r"(\w+) is (\w+) than (\w+)\.$", l)
            dim, sign = COMPARE[m.group(2)]
            hi, lo = (m.group(1), m.group(3)) if sign == 1 else (m.group(3), m.group(1))
            facts.append((hi, lo))
        people = sorted({x for f in facts for x in f} | set(p["people"]))
        orders = [o for o in itertools.permutations(people)
                  if all(o.index(h) < o.index(l) for h, l in facts)]
        if sh == "rank":
            m = re.search(r"who is the (second )?(\w+)\.", pr)
            dim, sign = SUPER[m.group(2)]
            idx = (1 if m.group(1) else 0) if sign == 1 else (-2 if m.group(1) else -1)
            ans = {o[idx] for o in orders}
            if len(ans) != 1:
                return bad(qid, f"{len(ans)} people could be the answer")
            pick(ans.pop())
        else:
            m = re.search(r"how many are (\w+) than (\w+)\.", pr)
            who = m.group(2)
            counts = {o.index(who) for o in orders}
            if counts != {a}:
                bad(qid, f"counts the clues allow: {counts}, stored {a}")

    elif sh == "queueBack":
        line = list(range(1, p["n"] + 1))
        from_back = list(reversed(line)).index(p["mark"]) + 1
        if from_back != a or p["name"] not in pr:
            bad(qid, f"counting from the back gives {from_back}, stored {a}")

    elif sh == "queueCalc":
        if "from the back" in " ".join(lines):
            f = ORD[re.search(r"is (\w+) from the front", lines[0]).group(1)]
            b = ORD[re.search(r"is (\w+) from the back", lines[1]).group(1)]
            want = f + b - 1
        else:
            x = ORD[re.search(r"is (\w+) in the line", lines[0]).group(1)]
            y = ORD[re.search(r"is (\w+) in the line", lines[1]).group(1)]
            want = len(range(min(x, y) + 1, max(x, y)))
        if want != a:
            bad(qid, f"the clues give {want}, stored {a}")

    elif sh == "queueWho":
        m = re.search(r"who is (\w+) from the (front|back)", pr)
        k, end = ORD[m.group(1)], m.group(2)
        names = p["names"]
        pick(names[k - 1] if end == "front" else names[-k])

    elif sh == "turns":
        start = re.search(r"faces (\w+)\.", lines[0]).group(1)
        x, y = COMPASS[start]
        for l in lines[1:]:
            if "turns right" in l:
                x, y = y, -x
            elif "turns left" in l:
                x, y = -y, x
            elif "turns around" in l:
                x, y = -x, -y
        want = next(k for k, v in COMPASS.items() if v == (x, y))
        pick(want)

    elif sh == "shelf":
        m = re.search(r"(just|two places) (left|right) of the (\w+)\.", pr)
        steps = 1 if m.group(1) == "just" else 2
        items = p["items"]
        t = items.index(m.group(3))
        j = t - steps if m.group(2) == "left" else t + steps
        want = items[j]
        hits = [i for i, c in enumerate(q["optionCells"]) if c["kind"] == want]
        if hits != [a]:
            bad(qid, f"the row gives the {want}, stored option {a}")

    elif sh in ("relation", "relationWho"):
        parent, sib, spouse, gender = set(), set(), set(), {}
        for l in lines:
            m = re.match(r"(\w+) is (\w+)'s (\w+)\.$", l)
            x, y, term = m.group(1), m.group(2), m.group(3)
            gender[x] = "F" if term in FEMALE else "M"
            if term in ("mother", "father"):
                parent.add((x, y))
            elif term in ("son", "daughter"):
                parent.add((y, x))
            elif term in ("sister", "brother"):
                sib |= {(x, y), (y, x)}
            elif term in ("wife", "husband"):
                spouse |= {(x, y), (y, x)}
            else:
                return bad(qid, f"this grader does not read the word {term!r}")
        people = {v for pair in parent | sib | spouse for v in pair}
        for _ in range(6):                      # close the family under the two rules
            for (s1, s2) in list(sib):          # a brother and sister share parents
                for (par, ch) in list(parent):
                    if ch == s1:
                        parent.add((par, s2))
            for (w1, w2) in list(spouse):       # a parent's husband or wife is a parent
                for (par, ch) in list(parent):
                    if par == w1:
                        parent.add((w2, ch))
            for (par, c1) in list(parent):      # children of one parent are siblings
                for (par2, c2) in list(parent):
                    if par == par2 and c1 != c2:
                        sib.add((c1, c2))

        def term_of(x, y):
            g = gender.get(x)
            parents_of = lambda z: {pp for pp, cc in parent if cc == z}
            if (x, y) in parent:
                return "mother" if g == "F" else "father"
            if (y, x) in parent:
                return "daughter" if g == "F" else "son"
            if (x, y) in sib:
                return "sister" if g == "F" else "brother"
            if (x, y) in spouse:
                return "wife" if g == "F" else "husband"
            if any((x, pp) in parent for pp in parents_of(y)):
                return "grandmother" if g == "F" else "grandfather"
            if any((y, pp) in parent for pp in parents_of(x)):
                return "granddaughter" if g == "F" else "grandson"
            if any((x, pp) in sib for pp in parents_of(y)):
                return "aunt" if g == "F" else "uncle"
            for px in parents_of(x):
                for py in parents_of(y):
                    if (px, py) in sib:
                        return "cousin"
            return None

        if sh == "relation":
            m = re.search(r"who (\w+) is to (\w+)\.", pr)
            want = term_of(m.group(1), m.group(2))
            if want is None:
                return bad(qid, "the clues do not connect them")
            pick(want)
        else:
            m = re.search(r"Tap (\w+)'s (\w+)\.", pr)
            y, term = m.group(1), m.group(2)
            hits = [x for x in sorted(people) if x != y and term_of(x, y) == term]
            if len(hits) != 1:
                return bad(qid, f"{len(hits)} people are {y}'s {term}")
            pick(hits[0])

    elif sh == "wordAnalogy":
        (x, y), (c, _) = p["pairs"]
        rels = [r for r, table in REL.items() if table.get(x) == y]
        if len(rels) != 1:
            return bad(qid, f"the example pair fits {len(rels)} relations")
        want = REL[rels[0]].get(c)
        if want is None:
            return bad(qid, f"{c} has no {rels[0]} in the facts")
        pick(want)

    elif sh == "numberAnalogy":
        pairs = [pp for pp in p["pairs"] if pp[1] is not None]
        ask = p["pairs"][-1][0]
        preds = set()
        for k in range(1, 31):
            for f in (lambda v, k=k: v + k, lambda v, k=k: v - k, lambda v, k=k: v * k):
                if all(f(u) == w for u, w in pairs):
                    preds.add(f(ask))
        if preds != {a}:
            bad(qid, f"rules from the examples predict {preds}, stored {a}")

    elif sh == "wordCode":
        ex, code = p["example"]
        rules = [k for k in range(1, 26)
                 if "".join(chr((ord(ch) - 65 + k) % 26 + 65) for ch in ex) == code]
        rev = ex[::-1] == code
        if len(rules) + rev != 1:
            return bad(qid, f"the example fits {len(rules) + rev} rules")
        w = p["word"]
        want = w[::-1] if rev else "".join(chr((ord(ch) - 65 + rules[0]) % 26 + 65) for ch in w)
        pick(want)

    elif sh == "numCode":
        if p["mode"] == "encode":
            want = " ".join(str(ord(ch) - 64) for ch in p["word"])
        else:
            want = "".join(chr(int(v) + 64) for v in p["word"].split())
        pick(want)

    elif sh == "alphabet":
        m = re.search(r"letter (just|two) (after|before) ([A-Z])\.", pr)
        k = (1 if m.group(1) == "just" else 2) * (1 if m.group(2) == "after" else -1)
        pick(chr(ord(m.group(3)) + k))

    elif sh == "oddWord":
        groups = [next((g for g, ws in CATEGORIES.items() if w in ws), None) for w in opts]
        lone = [w for w, g in zip(opts, groups) if groups.count(g) == 1]
        if len(lone) != 1 or groups.count(groups[opts.index(lone[0])]) != 1:
            return bad(qid, f"groups {groups}: no single odd one")
        pick(lone[0])

    elif sh == "oddNumber":
        ns = [int(o) for o in opts]
        tests = [lambda v: v % 2, lambda v: v % 5 == 0, lambda v: v % 10 == 0,
                 lambda v: v > 9, lambda v: 20 <= v <= 29]
        picks = set()
        for t in tests:
            vals = [t(v) for v in ns]
            lone = [i for i, v in enumerate(vals) if vals.count(v) == 1]
            if len(lone) == 1 and len(set(vals)) == 2:
                picks.add(lone[0])
        if picks != {a}:
            bad(qid, f"numbers that stand out: {picks}, stored {a}")

    elif sh == "weekday":
        monday = datetime.date(2024, 1, 1)                    # a real Monday
        day_of = lambda name: next(monday + datetime.timedelta(days=i) for i in range(7)
                                   if (monday + datetime.timedelta(days=i)).strftime("%A") == name)
        first = re.match(r"(Today is|Tomorrow is|Yesterday was) (\w+)\.", lines[0])
        base = day_of(first.group(2))
        if first.group(1) == "Tomorrow is":
            base -= datetime.timedelta(days=1)
        elif first.group(1) == "Yesterday was":
            base += datetime.timedelta(days=1)
        ask = lines[1]
        if "in" in ask and "days?" in ask:
            base += datetime.timedelta(days=nums_in(ask)[0])
        elif "ago" in ask:
            base -= datetime.timedelta(days=nums_in(ask)[0])
        elif "tomorrow" in ask:
            base += datetime.timedelta(days=1)
        pick(base.strftime("%A"))

    elif sh == "month":
        m = re.search(r"comes (just after|just before|two months after) (\w+)\?", lines[0])
        i = list(calendar.month_name).index(m.group(2))
        k = {"just after": 1, "just before": -1, "two months after": 2}[m.group(1)]
        pick(calendar.month_name[(i - 1 + k) % 12 + 1])

    elif sh == "clock":
        t = datetime.datetime(2024, 1, 1, p["h"] % 12, p["m"])
        if lines:
            hours = nums_in(lines[0])[0]
            t += datetime.timedelta(hours=hours if "later" in lines[0] else -hours)
        hour = t.hour % 12 or 12
        pick(f"{hour} o'clock" if t.minute == 0 else f"half past {hour}")

    elif sh == "combos":
        counts = nums_in(lines[0])
        ways = len(list(itertools.product(*[range(k) for k in counts])))
        if ways != a:
            bad(qid, f"listing every pair gives {ways}, stored {a}")

    else:
        bad(qid, f"no independent check for {sh}")


def main():
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
        for f in FAILS[:60]:
            print("  FAIL", f)
        print(f"\n{len(FAILS)} of {n} answers disagree")
        sys.exit(1)
    print(f"\nevery answer is correct  ({n} worked out again from what the child reads)")


if __name__ == "__main__":
    main()
