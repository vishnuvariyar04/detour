# -*- coding: utf-8 -*-
"""Captures one screenshot of every question type, for a human to look at.

The tap-through proves a question can be answered and grades correctly. It says
nothing about whether the screen looks right — text can overlap, a picture can
run off the card, two things can collide. Only eyes catch that, and eyes need
the pictures laid out side by side rather than found by scrolling a phone.

Run:  python shots.py number_sense        (one shot per shape)
      python shots.py number_sense all    (every stop's first question)
"""
import os
import subprocess
import sys
import time

import answers
import drive

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "shots")


def jump(skill, stop_i, q_i, stop_id):
    """Put the ladder on one exact question and open the gate on it."""
    drive.sh("shell", "am", "force-stop", drive.PKG)
    time.sleep(0.8)
    # Built as a list joined by newlines: escaping newlines inside nested
    # quoting kept mangling the file.
    rows = [
        "<?xml version='1.0' encoding='utf-8' standalone='yes' ?>",
        "<map>",
        f'    <int name="stopIndex__{skill}" value="{stop_i}" />',
        f'    <int name="questionIndex__{skill}" value="{q_i}" />',
        f'    <string name="review__{skill}"></string>',
        # Marking the stop taught opens the gate on the QUESTION rather
        # than its teach card, which is the point of these shots.
        f'    <boolean name="taught_{stop_id}__{skill}" value="true" />',
        "</map>",
    ]
    xml = chr(10).join(rows) + chr(10)
    tmp = os.path.join(os.environ["TEMP"], "p.xml")
    open(tmp, "w", encoding="utf-8").write(xml)
    subprocess.run([drive.ADB, "push", tmp, "/data/local/tmp/p.xml"],
                   capture_output=True)
    drive.sh("shell", f"run-as {drive.PKG} cp /data/local/tmp/p.xml "
                      f"/data/data/{drive.PKG}/shared_prefs/nupo_progress.xml")
    drive.open_gate()


def main():
    skill = sys.argv[1] if len(sys.argv) > 1 else "number_sense"
    every = len(sys.argv) > 2 and sys.argv[2] == "all"
    L = answers.ladder(skill)

    # Ladder index for each stop, in order.
    stops, seen = [], None
    for q in L:
        if q["stop"] != seen:
            stops.append(q["stop"])
            seen = q["stop"]
    idx_of = {s: i for i, s in enumerate(stops)}

    # One question per shape, or the first of every stop.
    picks = []
    if every:
        for s in stops:
            picks.append((s, 0, next(q["shape"] for q in L if q["stop"] == s)))
    else:
        done = set()
        for q in L:
            if q["shape"] in done:
                continue
            done.add(q["shape"])
            picks.append((q["stop"], q["qi"], q["shape"]))

    os.makedirs(OUT, exist_ok=True)
    for stop, qi, shape in picks:
        jump(skill, idx_of[stop], qi, stop)
        time.sleep(1.4)
        im = drive.shot()
        if not drive.gate_up(im):
            # Never save a frame that is not the gate — it could be anything
            # the phone's owner has on screen.
            drive.dismiss_shade()
            im = drive.shot()
            if not drive.gate_up(im):
                print(f"  {shape:14} {stop}#{qi}  SKIPPED (gate not up)")
                continue
        name = f"{shape}__{stop.replace('.', '_')}_{qi}.png"
        im.save(os.path.join(OUT, name))
        print(f"  {shape:14} {stop}#{qi}")
    print(f"\n{len(picks)} shots in {OUT}")


if __name__ == "__main__":
    main()
