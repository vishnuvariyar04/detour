# -*- coding: utf-8 -*-
"""Writes the reworded prompts back into the unit files.

Prompts are written as adjacent string literals wrapped across lines, so a
plain search-and-replace misses almost all of them. This reconstructs each
literal group, matches on its VALUE, and re-wraps the replacement at the same
indent — which keeps the source readable instead of leaving 90-column lines
behind.
"""
import io
import json
import os
import re
import sys

FILES = ["authored.py", "u12.py", "u13.py", "u21.py", "u22.py", "u23.py",
         "u31.py", "u32.py", "u33.py", "u41.py", "u42.py", "u43.py"]

# One or more double-quoted literals separated only by whitespace.
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
    """Re-emit [text] as adjacent literals that fit inside [width]."""
    words, lines, cur = text.split(" "), [], ""
    room = width - indent - 2          # the two quote characters
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
    return ('\n' + pad).join('"%s"' % l for l in lines)


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    pairs = {r["old"]: r["new"]
             for r in json.load(open(os.path.join(here, "_reword.json"),
                                     encoding="utf-8"))}
    done, missed = 0, set(pairs)

    for name in FILES:
        path = os.path.join(here, name)
        if not os.path.exists(path):
            continue
        src = io.open(path, encoding="utf-8").read()

        def sub(m):
            nonlocal done
            v = value_of(m.group(0))
            if v is None or v not in pairs:
                return m.group(0)
            line_start = src.rfind("\n", 0, m.start()) + 1
            indent = m.start() - line_start
            done += 1
            missed.discard(v)
            return wrap(pairs[v], indent)

        out = GROUP.sub(sub, src)
        if out != src:
            io.open(path, "w", encoding="utf-8").write(out)

    print(f"rewrote {done} prompts")
    for m in sorted(missed):
        print("  MISSED", m[:70])
    return 1 if missed else 0


if __name__ == "__main__":
    sys.exit(main())
