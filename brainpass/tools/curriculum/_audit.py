# -*- coding: utf-8 -*-
"""The four fairness checks the reading-level pass does not catch.

Every one of these exists because a child — or the person reviewing the
questions on their behalf — hit it and said so:

  repetition   "repetition has to be removed"; "in the later half you have
               just repeated stuff all over again"
  instruction  "which one lands exactly on the flag, why say that? say which
               OPTION because options are given"
  agreement    "i can see mismatch between question and whats on screen"
  variety      "later also same thing is going on, i dont want that"

They live in a module that simulate.py runs on every build, rather than in a
one-off script that gets run once and then forgotten, because every one of
these faults was introduced by an author who believed they were not doing it.
"""
import re
from collections import Counter

# A prompt has to say what to do with the screen. Without one of these the
# child is left to infer the interface from the shape of the controls.
TAP_WORDS = ("tap", "touch", "choose", "pick the", "drag", "put", "build",
             "fill", "order", "swap")

# Saying "a star" while describing a rule is not the same as saying "the star"
# while pointing at one. Only the second needs the thing to be on the board.
def _points_at(low, noun):
    return bool(re.search(
        rf"\b(the|every|both|all|each|that|this|how many)\s+\w*\s*{noun}\b",
        low))


def audit(stops, bad):
    seen_prompt = {}
    seen_pair = {}

    for st in stops:
        kinds = Counter()
        for i, q in enumerate(st["questions"]):
            qid = f"{st['id']}#{i}"
            prompt = (q.get("prompt") or "").strip()
            low = prompt.lower()
            kinds[q["shape"]] += 1

            # ---- repetition -------------------------------------------------
            if prompt in seen_prompt:
                bad(qid, f"asks word for word what {seen_prompt[prompt]} asks")
            else:
                seen_prompt[prompt] = qid

            vis = q.get("visual") or {}
            key = (prompt, repr(sorted(vis.items(), key=lambda kv: kv[0])))
            if key in seen_pair:
                bad(qid, f"same question on the same board as {seen_pair[key]}")
            else:
                seen_pair[key] = qid

            # ---- does it say what to do? ------------------------------------
            if not any(w in low for w in TAP_WORDS):
                bad(qid, f'never tells the child what to do: "{prompt[:52]}"')

            # Options on screen with no verb for choosing one is the complaint
            # that started this check: say which OPTION, because options are
            # what the child is looking at.
            # A compare screen always offers "The same square" against
            # "Different squares". A prompt asking anything else — "is the
            # loop still right?", "does the second draw the same PATH?" —
            # leaves the child answering a question nobody asked.
            if q["shape"] == "compare" and "same square" not in low:
                bad(qid, "a compare offers same/different SQUARE, but the "
                         f'prompt asks something else: "{prompt[:46]}"')

            # An option is painted as ONE row of chips, and a condition chip
            # can only fit the word "IF" — so two different checks look the
            # same and the child is choosing between identical-looking lists.
            # Loops are fine: "x3" says everything the row needs to.
            for oi, o in enumerate(q.get("options") or []):
                if any(str(t).startswith("if:") for t in o):
                    bad(qid, f"option {oi} has a check in it, and an option "
                             "row has no space to say what it checks")

            has_opts = bool(q.get("options") or q.get("optionsText"))
            if has_opts and not re.search(r"\b(tap|choose|pick)\b", low):
                bad(qid, "shows options but never says to tap one: "
                         f'"{prompt[:52]}"')

            # ---- does the screen carry the question? ------------------------
            prog = vis.get("program") or []
            words = set(re.findall(r"[a-z]+", low))
            neg = any(p in low for p in ("no wall", "nothing", "clear",
                                         "no star", "without", "edge"))

            if _points_at(low, "flag") and "goal" not in vis:
                bad(qid, "points at a flag the board does not have")
            if _points_at(low, "stars?") and not vis.get("stars"):
                bad(qid, "points at a star the board does not have")
            if _points_at(low, "door") and "door" not in vis:
                bad(qid, "points at a door the board does not have")
            if _points_at(low, "key") and "key" not in vis:
                bad(qid, "points at a key the board does not have")
            if "wall" in words and not vis.get("walls") and not neg:
                # The board edge is a real wall, but then the prompt has to be
                # the thing that says so.
                bad(qid, "says wall, but nothing is drawn as a wall")
            # "How many times does that pair of steps happen?" is the question
            # that MOTIVATES a loop, and it is asked on a list that has none.
            # Only the word "loop" promises one is on the screen.
            # A prompt saying a loop CANNOT be used is talking about the
            # absence deliberately — that is the question 4.3.2 turns on.
            says_no_loop = any(p in low for p in
                               ("cannot", "will not", "does not fit",
                                "no loop", "without a loop"))
            if "loop" in words and prog and not says_no_loop \
                    and not any(str(t).startswith("repeat:") for t in prog):
                bad(qid, "says loop, but the list has no loop in it")
            if "check" in words and prog \
                    and not any(str(t).startswith("if:") for t in prog):
                bad(qid, "talks about a check, but the list has no IF in it")

        # ---- variety --------------------------------------------------------
        if len(st["questions"]) >= 5:
            if len(kinds) < 3:
                bad(st["id"], f"only {len(kinds)} kinds of question here: "
                              f"{sorted(kinds)}")
            top, n = kinds.most_common(1)[0]
            if n > 4:
                bad(st["id"], f"{n} of its {sum(kinds.values())} questions are "
                              f"{top} — too much of one thing")
