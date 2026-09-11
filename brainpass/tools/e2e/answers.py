# -*- coding: utf-8 -*-
"""The ladder in order, with the correct answer for every question.

The driver taps what this says is right and then asserts the gate agreed. Any
disagreement is a grading bug between the authored JSON and the Kotlin engine,
which is exactly the thing a simulator cannot catch on its own.
"""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))
CURRIC = os.path.join(HERE, "..", "..", "assets", "curriculum")


def path_for(skill="think_like_a_coder"):
    return os.path.join(CURRIC, f"{skill}.json")


def ladder(skill="think_like_a_coder"):
    d = json.load(open(path_for(skill), encoding="utf-8"))
    out = []
    for sec in d["sections"]:
        for u in sec["units"]:
            for st in u["stops"]:
                if not st["authored"]:
                    continue
                for i, q in enumerate(st["questions"]):
                    a = q.get("answer") or {}
                    out.append({
                        # The gate's own id, so a log line can be matched to it.
                        "id": f"{st['id']}#{i}",
                        "stop": st["id"],
                        "qi": i,
                        "shape": q["shape"],
                        "prompt": q["prompt"],
                        "answerType": a.get("type"),
                        "answer": a.get("value"),
                        "choices": q.get("choices"),
                        "options": q.get("options"),
                        "optionsText": q.get("optionsText"),
                        "visual": q.get("visual"),
                        "pic": q.get("pic"),
                        "optionCells": q.get("optionCells"),
                        "blocks": q.get("blocks"),
                        "slots": q.get("slots"),
                        "reusable": bool(q.get("reusable")),
                        "hasTeach": bool((st.get("teach") or {}).get("line")),
                    })
    return out


if __name__ == "__main__":
    import sys
    L = ladder(sys.argv[1] if len(sys.argv) > 1 else "think_like_a_coder")
    print(len(L), "questions")
    from collections import Counter
    for s, n in Counter(q["shape"] for q in L).most_common():
        print(f"  {s:10} {n}")
