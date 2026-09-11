# -*- coding: utf-8 -*-
"""Proposes a clearer prompt for every question that never says what to do.

A prompt like "Which one gets both stars?" is a fine sentence and a poor
instruction: options are on screen and nothing tells the child to touch one.
The rules below turn the question INTO the instruction, which is the form the
rest of the curriculum already uses.
"""
import json, os, re, sys

TAP_WORDS = ("tap", "touch", "choose", "pick the", "drag", "put", "build",
             "fill", "order", "swap")

BUILDERS = ("fix", "inverse", "constrain")
NUMBERS = ("count", "trace")
OPTIONS = ("choose", "chooseText", "complete", "compare")


# Prompts the rules below cannot improve, because they already contain a verb
# ("fill", "order") that reads as an instruction but does not tell a child that
# the thing to touch is one of the options on screen.
OVERRIDES = {
    "1.1.2#0": "Same three steps, new order. Do they end on the same square? "
               "Tap your answer.",
    "1.2.2#3": "One step is missing from the middle. Tap the step that fills "
               "the gap.",
    "1.3.2#3": "This list matches the path except one gap. Tap the step that "
               "fills it.",
    "2.2.1#3": "The loop count is missing. Tap the count that reaches the flag.",
    "2.2.3#3": "Tap the count that gets Nupo both stars and the flag.",
    "2.2.4#0": "Tap the loop count that gets Nupo to the flag.",
    "2.3.2#3": "Tap the inside count that gets Nupo to the flag.",
    "2.3.4#3": "The inside count is missing. Tap the one that reaches the flag.",
    "4.3.1#4": "Tap the order that does all three jobs.",
}


def reword(shape, p):
    s = p.strip()

    # "Which list of steps X?" / "Which list X?" / "Which one X?"
    m = re.match(r"^(.*?)Which (list of steps|list|one|program|loop|count|"
                 r"order|route|path) (.+?)\?$", s, re.S)
    if m:
        head, noun, rest = m.group(1), m.group(2), m.group(3)
        if noun == "list of steps":
            noun = "list"
        return f"{head}Tap the {noun} that {rest}."

    # "... Which one?"  ->  "... Tap it."
    if s.endswith("Which one?"):
        return s[:-len("Which one?")] + "Tap it."

    # "What does he do?" / "What happens?"
    s = s.replace("What does he do?", "Tap what he does.")
    s = s.replace("What happens?", "Tap what happens.")

    # "Where does this list end?"
    s = s.replace("Where does this list end?",
                  "Tap the square this list ends on.")

    if any(w in s.lower() for w in TAP_WORDS):
        return s

    if shape in NUMBERS or shape == "count":
        return s.rstrip() + " Tap the number."
    if shape == "predict":
        return s.rstrip() + " Tap the square he ends on."
    if shape in ("spot", "debug"):
        return s.rstrip() + " Tap that step."
    if shape in BUILDERS:
        # These are already imperatives ("Get the star, then the flag"). What
        # they leave out is that the answer is built by dragging, not tapped.
        return s.rstrip() + " Drag the steps into order."
    if shape in OPTIONS:
        return s.rstrip() + " Tap your answer."
    return s


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    d = json.load(open(os.path.join(here, "..", "..", "assets", "curriculum",
                                    "think_like_a_coder.json"), encoding="utf-8"))
    out = []
    for sec in d["sections"]:
        for u in sec["units"]:
            for st in u["stops"]:
                for i, q in enumerate(st["questions"]):
                    p = q["prompt"]
                    low = p.lower()
                    has_opts = bool(q.get("options") or q.get("optionsText"))
                    needs = (not any(w in low for w in TAP_WORDS)) or \
                            (has_opts and not re.search(r"\b(tap|choose|pick)\b", low))
                    if not needs:
                        continue
                    qid = f"{st['id']}#{i}"
                    new = OVERRIDES.get(qid) or reword(q["shape"], p)
                    out.append((qid, q["shape"], p, new))
    for qid, sh, old, new in out:
        flag = "  !!" if new.strip() == old.strip() else ""
        print(f"{qid:10} {sh:10}{flag}\n   - {old}\n   + {new}")
    print(f"\n{len(out)} prompts to reword")
    json.dump([{"id": a, "shape": b, "old": c, "new": e} for a, b, c, e in out],
              open(os.path.join(here, "_reword.json"), "w", encoding="utf-8"),
              indent=1, ensure_ascii=False)


if __name__ == "__main__":
    main()
