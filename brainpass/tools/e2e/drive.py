# -*- coding: utf-8 -*-
"""Answers a whole skill on a real phone and checks the gate agrees.

The simulator proves a question CAN be answered. This proves the answer can be
TAPPED: that the thing the child touches maps to the thing the engine grades.
Those are different failures, and only this one catches a mis-wired shape.

Run:  python drive.py                      (the coder skill, whole ladder)
      python drive.py 12                   (smoke test, 12 questions)
      python drive.py 12 number_sense      (a different skill)

The device must already be on the band that skill serves; the gate picks the
skill, not this driver.
"""
import os, re, subprocess, sys, time

import answers, vision

# Mirrors ShapeHuntView.build() and ns_simulate.FIGURES.
FIGURES = {
    "triangle4": ["triangle"] * 4,
    "house": ["triangle", "square", "square"],
    "square4": ["square"] * 4,
    "hex6": ["triangle"] * 6,
    "rocket": ["triangle", "square", "triangle", "triangle"],
    "tree": ["triangle", "triangle", "square"],
}

ADB = os.path.join(os.environ["LOCALAPPDATA"], "Android", "Sdk",
                   "platform-tools", "adb.exe")
PKG = "app.nupo.kid"
YT = "com.google.android.youtube"
SHOT = os.path.join(os.environ["TEMP"], "nupo_shot.png")
FAILDIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "failures")


def sh(*a, **kw):
    return subprocess.run([ADB] + list(a), capture_output=True, text=True,
                          timeout=kw.get("timeout", 60)).stdout


def shot():
    raw = subprocess.run([ADB, "exec-out", "screencap", "-p"],
                         capture_output=True, timeout=60).stdout
    open(SHOT, "wb").write(raw)
    return vision.load(SHOT)


def tap(x, y):
    sh("shell", "input", "tap", str(int(x)), str(int(y)))


def progress(skill=""):
    """The ladder cursor, which the gate namespaces per skill.

    Reading the bare "stopIndex" always returned 0 once progress became
    per-skill, so the driver thought it was on question 0 while the gate had
    moved on — every target lookup then missed.
    """
    x = sh("shell", "run-as", PKG,
           f"cat /data/data/{PKG}/shared_prefs/nupo_progress.xml")

    def g(k):
        for key in (f"{k}__{skill}", k) if skill else (k,):
            m = re.search(rf'name="{re.escape(key)}" value="(-?\d+)"', x)
            if m:
                return int(m.group(1))
        return 0

    return g("stopIndex"), g("questionIndex")


def gate_up(im):
    """The gate paints the whole screen its own pale lavender page."""
    w, h = im.size
    px = im.load()
    hits = 0
    for y in (0.22, 0.34, 0.46):
        p = px[6, int(h * y)]
        if 238 <= p[0] <= 252 and 232 <= p[1] <= 248 and p[2] >= 248:
            hits += 1
    return hits >= 2


def dismiss_shade():
    """Close anything the phone has pulled over the gate.

    A stray tap near the top edge opens the notification shade, which hides the
    gate and — worse — puts the owner's private notifications on screen where a
    test would otherwise photograph them.
    """
    sh("shell", "input", "keyevent", "KEYCODE_BACK")
    time.sleep(0.6)


def open_gate():
    """Clear earned time and put a gated app in front so the gate fires.

    The app has to be stopped first: the guard holds the engine prefs in memory
    and flushes them back, so editing the file under a live process is undone a
    moment later.
    """
    sh("shell", "am", "force-stop", PKG)
    time.sleep(1.0)
    sh("shell", "run-as", PKG,
       f"sed -i '/rem_/d;/used_/d' /data/data/{PKG}/shared_prefs/brainpass_engine.xml")
    sh("shell", "appops", "set", PKG, "SYSTEM_ALERT_WINDOW", "allow")
    sh("shell", "monkey", "-p", PKG, "-c", "android.intent.category.LAUNCHER", "1")
    time.sleep(5)
    sh("shell", "input", "keyevent", "KEYCODE_HOME")
    time.sleep(1.2)
    sh("shell", "am", "force-stop", YT)
    sh("shell", "am", "start", "-n",
       f"{YT}/com.google.android.apps.youtube.app.WatchWhileActivity")
    time.sleep(7)


def is_teach(im):
    """A teach card has one wide button; a question has Hint beside Check.

    Scanned across the Hint pill rather than sampled at one point: a single
    sample landed on the letter H, read dark, and called every question a teach
    card — which made the driver tap "Got it" forever.
    """
    w, h = im.size
    px = im.load()
    y = int(h * 0.925)
    white = sum(1 for x in range(int(w * 0.05), int(w * 0.27), 3)
                if all(c >= 248 for c in px[x, y]))
    total = len(range(int(w * 0.05), int(w * 0.27), 3))
    return white < total * 0.35


def action_point(im, teach):
    w, h = im.size
    return (w * 0.5, h * 0.925) if teach else (w * 0.64, h * 0.925)


def targets():
    """Parse the gate's own report of where this question's controls landed."""
    log = sh("logcat", "-d", "-s", "NupoGate:D")
    line = None
    for ln in reversed(log.splitlines()):
        if " targets " in ln:
            line = ln
            break
    if not line:
        return None, None, {}
    parts = line.split(" targets ", 1)[1].split()
    qid, shape = parts[0], parts[1]
    pts = {}
    for kv in parts[2:]:
        if "=" in kv:
            k, v = kv.split("=", 1)
            try:
                x, y = v.split(",")
                pts[k] = (int(x), int(y))
            except ValueError:
                pass
    return qid, shape, pts


def target(q, pts):
    """Which reported point is the correct answer for [q].

    Multi-tap shapes (finding every triangle, sorting, ordering, mirroring)
    return a LIST of points to tap in turn; everything else returns one point.
    """
    shape, ans = q["shape"], q["answer"]
    pic = q.get("pic") or {}

    # ---- Number Sense -------------------------------------------------
    if shape in ("countObjects", "tenFrame", "rods", "dice", "bond"):
        ch = q.get("choices") or []
        return pts.get(f"opt{ch.index(ans)}") if ans in ch else None

    if shape == "numberLine":
        return pts.get(f"tick{ans}")

    if shape in ("balance", "oddOneOut", "pattern", "fraction"):
        key = "tile" if shape == "oddOneOut" else "opt"
        return pts.get(f"{key}{ans}")

    if shape == "shapeHunt":
        kinds = FIGURES.get(pic.get("figure"), [])
        want = [i for i, k in enumerate(kinds) if k == pic.get("target")]
        got = [pts.get(f"part{i}") for i in want]
        return got if all(got) else None

    if shape == "sortTwo":
        # Everything starts in the left tray; tap only what belongs on the right.
        got = [pts.get(f"item{i}") for i, sd in enumerate(ans) if sd == 1]
        return got if all(got) else None

    if shape == "sizeOrder":
        got = [pts.get(f"size{i}") for i in ans]
        return got if all(got) else None

    if shape == "mirror":
        got = [pts.get(f"mc{c}_{r}") for (c, r) in ans]
        return got if all(got) else None


    if shape == "predict":
        return pts.get("cell")

    if shape in ("count", "trace"):
        ch = q.get("choices") or []
        if ans not in ch:
            return None
        return pts.get(f"opt{ch.index(ans)}")

    if shape in ("truth", "compare"):
        return pts.get("opt0" if ans else "opt1")

    if shape in ("choose", "chooseText", "complete"):
        return pts.get(f"opt{ans}") if isinstance(ans, int) else None

    if shape in ("spot", "debug"):
        return pts.get(f"row{ans}") if isinstance(ans, int) else None

    return None


def read_grade(qid):
    """(correct, matched) for [qid] from the gate's own grading line.

    Matched by id and never followed by a log wipe: clearing the buffer after
    grading also threw away the next question's geometry line, which the gate
    had already written by then.
    """
    log = sh("logcat", "-d", "-s", "NupoGate:D")
    for line in reversed(log.splitlines()):
        mm = re.search(r"grade (\S+) (\S+) correct=(true|false)", line)
        if mm and mm.group(1) == qid:
            return mm.group(3) == "true", mm
    return False, None


def build_program(q, pts):
    """Tap tray chips in the answer's order.

    The tray is the JSON's `blocks` in order and is not shuffled, so each token
    in the answer maps to a chip index. A non-reusable chip is spent when it is
    placed, which matters when the same step appears twice.
    """
    blocks = q.get("blocks") or []
    order = q.get("answer")
    if not blocks or not isinstance(order, list):
        return False
    chips = [pts.get(f"chip{i}") for i in range(len(blocks))]
    if any(c is None for c in chips):
        return False
    used = set()
    for tok in order:
        idx = next((i for i, b in enumerate(blocks)
                    if b == tok and (q.get("reusable") or i not in used)), None)
        if idx is None:
            return False
        used.add(idx)
        tap(*chips[idx])
        time.sleep(0.45)
    return True


def main():
    limit = int(sys.argv[1]) if len(sys.argv) > 1 else 10 ** 9
    skill = sys.argv[2] if len(sys.argv) > 2 else "think_like_a_coder"
    L = answers.ladder(skill)
    sh("logcat", "-c")
    results, n = [], 0

    stuck = 0
    last_id, repeats = None, 0
    while n < limit:
        im = shot()
        if not gate_up(im):
            # Something is covering the gate; close it before deciding the gate
            # itself failed to open.
            dismiss_shade()
            im = shot()
        if not gate_up(im):
            open_gate()
            im = shot()
            if not gate_up(im):
                stuck += 1
                if stuck > 5:
                    print("gate will not open"); break
                continue
        stuck = 0

        si, qi = progress(skill)
        stop = stop_of(L, si)
        if stop is None:
            print("ladder finished"); break
        here = [x for x in L if x["stop"] == stop and x["qi"] == qi]
        if not here:
            print(f"cannot locate {stop}#{qi}"); break
        q = here[0]

        if is_teach(im):
            x, y = action_point(im, True)
            tap(x, y); time.sleep(1.6)
            continue

        # A question that will not resolve must not stall the whole run.
        if q["id"] == last_id:
            repeats += 1
            if repeats > 2:
                os.makedirs(FAILDIR, exist_ok=True)
                if gate_up(im):
                    im.save(os.path.join(FAILDIR,
                            f"{q['id'].replace('#','_')}_stuck.png"))
                results.append((q["id"], q["shape"], "STUCK"))
                print(f"  {q['id']:10} {q['shape']:10} stuck - stepping over")
                sh("shell", "am", "force-stop", PKG)
                time.sleep(0.8)
                sh("shell", "run-as", PKG,
                   "sed -i 's/questionIndex\" value=\"[0-9]*\"/"
                   f"questionIndex\" value=\"{qi + 1}\"/' "
                   f"/data/data/{PKG}/shared_prefs/nupo_progress.xml")
                last_id, repeats = None, 0
                n += 1
                open_gate()
                continue
        else:
            last_id, repeats = q["id"], 0


        # The gate reports geometry once the board has finished growing, which
        # is a beat after the question appears — longer on the first question of
        # a stop, where a teach card was dismissed first.
        pts = {}
        for _ in range(5):
            time.sleep(0.7)
            qid, _, got = targets()
            if qid == q["id"]:
                pts = got
                break

        if q["shape"] in ("fix", "inverse", "constrain"):
            if pts and build_program(q, pts):
                sh("logcat", "-c")
                ax, ay = pts.get("action") or action_point(im, False)
                tap(ax, ay); time.sleep(2.2)
                ok, m = read_grade(q['id'])
                results.append((q["id"], q["shape"], "ok" if ok else "WRONG"))
                print(f"  {q['id']:10} {q['shape']:10} "
                      f"{'ok' if ok else ('GRADED WRONG' if m else 'no grade')}")
                n += 1
                time.sleep(0.8)
                continue
            os.makedirs(FAILDIR, exist_ok=True)
            im.save(os.path.join(FAILDIR, f"{q['id'].replace('#','_')}_notray.png"))
            results.append((q["id"], q["shape"], "no-tray"))
            print(f"  {q['id']:10} {q['shape']:10} tray not found")
            n += 1
            continue

        pt = target(q, pts) if pts else None
        if pt is None:
            # Keep going: one unhandled shape must not hide the other 300.
            os.makedirs(FAILDIR, exist_ok=True)
            if gate_up(im):
                im.save(os.path.join(FAILDIR,
                        f"{q['id'].replace('#','_')}_notarget.png"))
            results.append((q["id"], q["shape"], "no-target"))
            print(f"  {q['id']:10} {q['shape']:10} no target")
            pt = (im.size[0] * 0.5, im.size[1] * 0.55)   # something, to move on
        if isinstance(pt, list):
            # A sort tray reflows after every move, so the remaining targets
            # have shifted. Wait for the gate to REPORT the new layout rather
            # than guessing a delay: a fixed sleep worked at 1.5s and failed at
            # 0.95s, which is the kind of flake that hides real bugs.
            reflows = q["shape"] == "sortTwo"
            # Indexed, not enumerated: enumerate() snapshots the list, so the
            # re-read positions below were computed correctly and then thrown
            # away while the loop kept tapping where things used to be.
            k = -1
            while k + 1 < len(pt):
                k += 1
                point = pt[k]
                before = None
                if reflows:
                    _, _, p0 = targets()
                    before = {kk: vv for kk, vv in p0.items()
                              if kk.startswith("item")}
                tap(*point)
                time.sleep(0.35)
                if reflows and k + 1 < len(pt):
                    for _ in range(12):
                        time.sleep(0.2)
                        qid2, _, pts2 = targets()
                        now = {kk: vv for kk, vv in pts2.items()
                               if kk.startswith("item")}
                        if qid2 == q["id"] and now and now != before:
                            fresh = target(q, pts2)
                            if isinstance(fresh, list) and len(fresh) == len(pt):
                                pt = fresh
                            break
        else:
            tap(*pt)
        time.sleep(0.5)
        sh("logcat", "-c")
        ax, ay = pts.get("action") or action_point(im, False)
        tap(ax, ay); time.sleep(1.8)

        ok, m = read_grade(q["id"])
        if not m:
            os.makedirs(FAILDIR, exist_ok=True)
            if gate_up(im):
                im.save(os.path.join(FAILDIR,
                        f"{q['id'].replace('#','_')}_nograde.png"))
            results.append((q["id"], q["shape"], "no-grade"))
            print(f"  {q['id']:10} {q['shape']:10} no grade line")
            tap(*action_point(im, False)); time.sleep(1.2)
            n += 1
            continue
        if not ok:
            os.makedirs(FAILDIR, exist_ok=True)
            if gate_up(im):
                im.save(os.path.join(FAILDIR,
                        f"{q['id'].replace('#','_')}_wrong.png"))
        results.append((q["id"], q["shape"], "ok" if ok else "WRONG"))
        print(f"  {q['id']:10} {q['shape']:10} {'ok' if ok else 'GRADED WRONG'}")
        n += 1
        time.sleep(0.6)

    bad = [r for r in results if r[2] != "ok"]
    print(f"\nanswered {len(results)}  failures {len(bad)}")
    for b in bad:
        print("  ", b)


def stop_of(L, si):
    seen, last = [], None
    for q in L:
        if q["stop"] != last:
            seen.append(q["stop"]); last = q["stop"]
    return seen[si] if si < len(seen) else None


if __name__ == "__main__":
    main()
