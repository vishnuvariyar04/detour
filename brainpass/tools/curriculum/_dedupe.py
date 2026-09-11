# -*- coding: utf-8 -*-
"""Gives each repeated prompt its own situation.

Twenty questions asked something word for word identical to a question in an
earlier stop. In most cases the BOARD differs and only the wording had
collapsed to a generic form — so the fix is to put the situation back into the
prompt, which makes it both unique and clearer than it was.

Each rewrite is anchored on the question's hint, which is unique across the
curriculum, so a prompt that appears five times is still changed in exactly the
place meant.
"""
import io
import os
import re
import sys

# hint (anchor) -> new prompt
FIXES = {
 # --- section 1 -------------------------------------------------------------
 "Do every step, even the ones after he passes the flag.":
   "Nupo takes four steps right. Tap the square he ends on.",
 "Check where each one ends. Only one lands on the star.":
   "Tap the list that stops on the star.",
 "The star is on the way. Go through it, not round it.":
   "Put the steps in order to cross the star on the way to the flag.",
 "Two walls are in the way. Count the shortest way past them.":
   "Two walls stand in the way. What is the fewest steps to the flag? Tap "
   "the number.",
 "Trace both from the same square and compare only the end.":
   "Same four steps, swapped around. Do they end on the same square? Tap "
   "your answer.",
 "Start at Nupo and follow the dots one square at a time.":
   "The dots show a three step walk. Put the steps in that order.",
 "Three across and two up.":
   "Reach this flag in exactly 5 steps. Drag the steps into order.",
 # --- section 2 -------------------------------------------------------------
 "Two steps inside, twice round.":
   "This loop goes round twice. Tap the square it ends on.",
 "Three turns of up-then-across.":
   "Three goes round, up then across each time. Tap the square it ends on.",
 "Two inside, four turns.":
   "How many moves does this loop make altogether? Tap the number.",
 "Three inside, twice over.":
   "How many moves does this nested loop make? Tap the number.",
 "The flag is four up and four across.":
   "Tap the loop that stops exactly on this flag.",
 # --- section 3 -------------------------------------------------------------
 "IF and END are checks, not moves.":
   "Some rows here are checks, not moves. How many moves does Nupo make? "
   "Tap the number.",
 "Five goes round, and a star on only some of the squares.":
   "How many stars does Nupo end up with? Tap the number.",
 "The checks are not moves. Count only the rows that shift him.":
   "How many moves does Nupo make on this board? Tap the number.",
 # --- section 4 -------------------------------------------------------------
 "He has to go under or over the wall, not through it.":
   "One wall, one flag. Tap the list that gets there.",
 "Watch what the SET row does to the number above it.":
   "The table is missing one row. Tap the number that goes in it.",
 "Only the ADD rows change the number.":
   "Tap the number that belongs in the blank row of this table.",
 "Two up and two across.":
   "Use the named chunk twice to reach the flag in exactly 4 steps. Drag "
   "the steps into order.",
 "Key first. Then the door. Then the flag.":
   "One list fetches the key, opens the door and reaches the flag. Tap it.",
}

FILES = ["authored.py", "u12.py", "u13.py", "u21.py", "u22.py", "u23.py",
         "u31.py", "u32.py", "u33.py", "u41.py", "u42.py", "u43.py"]

GROUP = re.compile('"(?:[^"\\\\\\n]|\\\\.)*"(?:\\s*"(?:[^"\\\\\\n]|\\\\.)*")*')


def value_of(lit):
    try:
        # Parenthesised: a literal wrapped across lines carries the source
        # indent with it, which eval() reads as an IndentationError.
        v = eval("(" + lit + ")", {"__builtins__": {}}, {})
    except Exception:
        return None
    return v if isinstance(v, str) else None


def wrap(text, indent, width=79):
    words, lines, cur = text.split(" "), [], ""
    room = width - indent - 2
    for w in words:
        cand = (cur + " " + w) if cur else w
        if len(cand) > room and cur:
            lines.append(cur + " ")
            cur = w
        else:
            cur = cand
    lines.append(cur)
    if len(lines) == 1:
        return '"%s"' % lines[0]
    pad = " " * indent
    return ("\n" + pad).join('"%s"' % l for l in lines)


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    left = set(FIXES)
    done = 0
    for name in FILES:
        path = os.path.join(here, name)
        src = io.open(path, encoding="utf-8").read()
        groups = [(m.start(), m.end(), value_of(m.group(0)))
                  for m in GROUP.finditer(src)]
        # Walk backwards so earlier offsets stay valid as we splice.
        edits = []
        for i, (s0, e0, v) in enumerate(groups):
            if v not in FIXES:
                continue
            # The prompt is the literal group immediately before the hint.
            if i == 0:
                continue
            ps, pe, pv = groups[i - 1]
            if pv is None:
                continue
            line_start = src.rfind("\n", 0, ps) + 1
            edits.append((ps, pe, wrap(FIXES[v], ps - line_start)))
            left.discard(v)
            done += 1
        for ps, pe, new in sorted(edits, reverse=True):
            src = src[:ps] + new + src[pe:]
        if edits:
            io.open(path, "w", encoding="utf-8").write(src)

    print(f"rewrote {done} prompts")
    for m in sorted(left):
        print("  ANCHOR NOT FOUND:", m[:66])
    return 1 if left else 0


if __name__ == "__main__":
    sys.exit(main())
