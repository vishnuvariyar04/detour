# Making the two new skills playable

A hand-off inside a hand-off. [01_BUILD_GUIDE.md](01_BUILD_GUIDE.md) covers
writing the questions; both new skills are written. This covers the second half
of the job: making the phone able to DRAW them, and proving it does.

Read [README.md](README.md) and §1 of the build guide first. Everything here
happens on branch **`bands-b-and-d`** of the Android repo.

---

## 1. Where things stand

| Band | Ages | Skill | Questions | Authored | Drawn | On a phone | Served to children |
|---|---|---|---|---|---|---|---|
| a | 5–6 | Number Sense | 324 | yes | yes | yes | **yes** |
| **b** | **7–8** | **Puzzles & Logic** | 324 | yes | **yes** | **verified on an emulator** | not yet |
| c | 9–10 | Think Like a Coder | 324 | yes | yes | yes | **yes** |
| **d** | **11–12** | **Reasoning** | 324 | yes | **yes** | **verified on an emulator** | not yet |

> **Status, 2026-09-16.** Both skills are finished and checked on a
> phone-shaped emulator: every drawing of both bands has been looked at, and
> band b has been played through the real gate (tap, grade, verdict, Continue).
> Neither is served to any child yet — see §5 for the single switch that does
> that, and §6 for what is left before it should be thrown. What remains is a
> run on Sai's own phone.

### What "served" means, and why neither is

`Curriculum.allSkills()` scans **`assets/curriculum/` only**. Both new skills
live in **`assets/curriculum_pending/`**, which is bundled into the APK (so the
preview screen can read it on a real phone) but which that scan never looks at.

This matters more than it sounds. The gate serves **the most advanced skill
whose band the child has reached**, and `CoderGate`'s `when (q.shape)` has no
`else` branch. So dropping a skill into `assets/curriculum/` before its views
exist does not degrade gracefully — it replaces a working skill with one whose
every stop draws a blank screen. The pending folder is what stops that.

---

## 2. How the drawings are organised

The band b and band d skills have **55 question shapes** between them, which
sounds like 55 views. It is not. They have **32 drawings**, and only **four ways
to answer**, all of which the gate already had.

```
CoderGate.renderQuestion()
  └── when (q.shape)
        ├── ... band a and band c branches, untouched ...
        └── in PuzzleShapes.all -> renderPuzzle(q)
                                      │
              ┌───────────────────────┴───────────────────────┐
              │                                               │
        the drawing                                    the answer row
   PuzzlePicView  (band b, 13 kinds)          q.answerType == "number" -> numberChoices
   ReasonPicView  (band d, 18 kinds)          q.optionCells            -> cellOptions
   neither, for kinds with no drawing         q.optionNets/Sections/   -> drawnGrid
                                                Cubes
                                              q.optionViews/Shapes     -> drawnRow
                                              q.optionBits             -> drawnStack
                                              otherwise                -> textOptions
```

**`renderPuzzle` asks the QUESTION which answer row it needs, not the shape.**
A question that stores four numbers gets number buttons; one that stores four
nets gets net cards. So a new shape needs a drawing and nothing else, and no
shape can end up with an answer row that cannot express its answer.

**A shape not listed in `PuzzleShapes` falls through to the gate's `else`**,
which draws nothing and offers nothing. Forgetting to register one is a blank
screen, never a wrong answer marked right. That is the safe direction.

### The files

| File | What it holds |
|---|---|
| `PuzzleViews.kt` | `Draw` (the primitives: rounded boxes, middle-baseline text, shrink-to-fit, clue cards) and `PuzzlePicView` (band b's 13 drawings). |
| `ReasonViews.kt` | `Iso` (the one isometric projection), `Solid` (voxels, solid meshes, cross-sections, cube nets, flat shapes) and `ReasonPicView` (band d's 18 drawings). |
| `CoderGate.kt` | `PuzzleShapes` (which shapes are ready), `renderPuzzle`, the drawn-answer rows, and the `hasAnswer` / `submit` / `explain` entries. |
| `Curriculum.kt` | `Pic` gained the fields the new drawings read. All additive. |
| `PuzzlePreviewActivity.kt` | Debug-only. Two modes, see §4. |
| `tools/curriculum/pz_fits.py` | Measures band b against the real card with the real font. |
| `tools/curriculum/rs_fits.py` | The same for band d. Its solids are not measured; they scale to fit. |

Every drawing is a port of the one on the **review wall**
(`tools/curriculum/wall_template.html`), which is the page the questions were
approved on. Keep them in step: if a drawing changes here, change it there, or
the page a parent signed off stops being the screen a child meets.

---

## 3. Traps already paid for

Do not rediscover these.

**Seven JSON keys mean different things in different bands.** `start` is a
compass direction in band b and a grid square in band d. `steps` is a count and
a list of sentences. `target` is a shape name and a number. `word` is a string
and a row of symbol objects. `cells` is a list of drawn-thing objects in band a
and a list of `[column, row]` pairs in band d. `who` and `what` can be null.
**Each has its own field in `Pic`** — `startCell`, `stepLines`, `targetNum`,
`symWord`, `netCells` — rather than one field that guesses.

**A throw while reading one question costs the child the whole skill.**
`Skill(JSONObject(text))` is constructed inside `allSkills()`, which catches
`Exception` per file so that one bad file does not cost every skill. That means
a parse error does not crash — it silently makes the skill vanish. Reading band
d's net `cells` as band a's CellSpec objects threw exactly this way. Every list
reader in `Pic` now takes only the entries that are the right shape and ignores
the rest.

**Text clipping is invisible to every other check.** The simulator sees a
correct question, the grader works out the right answer, and the child reads
"Tap the shape just left of the hea". `pz_fits.py` measures real Nunito glyphs
against the real widths. It was proven to fail before it was believed: fed a
too-long option, an 11-letter queue name, a 9-row clue card and an over-wide
code row, it caught all four.

**Three bugs only a phone found**, all fixed, all worth knowing because the same
mistake is easy to repeat:
- The compass had its S cut in half. The letter sits 11dp below the circle and
  is drawn from its middle, so the height was 12dp short. Measure the extremes
  of a drawing, not its nominal size.
- Odd-one-out drew its four words above four answer buttons holding the same
  four words **in a different order** (the buttons are shuffled so the answer is
  not always in slot one). Now it draws nothing, which is what the wall does. If
  the options already ARE the picture, do not draw the picture.
- At o'clock the minute hand landed exactly on the 12, because 0.78 of the
  radius is precisely where the hour numbers sit.

**An option a child can rule out without thinking is a broken question.** Three
shipped that way and were caught by looking at the screen, not by any checker: a
dice offering 7 and 8 as its top face, four bulbs offering 16 when they stop at
15, and five bulbs offering 31, 32, 33 and 34 when they stop at 31 — that last
one had exactly one possible answer. `choices4(..., allowed=...)` exists for
this and simply was not being passed. `rs_simulate.py`'s `check_possible` now
fails the build on it.

**The gate scrolls.** `CoderGate` wraps its body in a `ScrollView`, so a tall
drawing is not clipped. Width is the real constraint: **320dp** usable
(360 minus the body's 20dp padding each side).

**The emulator's software renderer is not a phone.** Booted with
`-gpu swiftshader_indirect`, a page of eighteen solids made Android itself
offer to close the app. Boot with **`-gpu host`**. The preview is paged for the
same reason (§4).

---

## 4. How to look at it

Both modes are **debug builds only** — the activity finishes immediately
otherwise. Build with `flutter build apk --debug`, install, then:

**A gallery of every drawing**, one question per kind, paged:
```bash
adb shell am start -n app.nupo.kid/com.brainpass.brainpass.PuzzlePreviewActivity \
  --es skill puzzles_and_logic --ei skip 0 --ei limit 6
```
`skill` is `puzzles_and_logic`, `reasoning`, or either shipped skill
(`number_sense`, `think_like_a_coder`). Each page prints the `--ei skip` for the
next one. Add `--es shape relation` for one kind only.

**The real gate**, over a session built from a pending skill:
```bash
adb shell am start -n app.nupo.kid/com.brainpass.brainpass.PuzzlePreviewActivity \
  --es mode gate --es skill reasoning --es shape sectionShape
```
This hosts the actual `CoderGate`, so the tap, the grade, the verdict wording
and Continue are the shipping code and not a copy of it that could agree with
itself while both are wrong. **This is the mode that matters.** The gallery
cannot show drawn answers at all — it says so and points here.

The gate normally runs in the guard's overlay window, which needs the
accessibility service, the overlay permission and a gated app to open. None of
that changes a line of what the gate draws or how it grades.

> The first screenshot after launching often catches the window background (the
> owl) before the first frame. It is a timing artefact of screencap, not a bug —
> wait a few seconds, or check `adb logcat | grep NupoGate` for the line
> reporting the live tap targets.

---

## 5. Turning a skill on

When a band's views are done and checked on a real phone:

1. `git mv brainpass/assets/curriculum_pending/<skill>.json brainpass/assets/curriculum/`
2. If `curriculum_pending/` is now empty, drop its line from `pubspec.yaml`.
3. Point `build_wall.py` and `rs_simulate.py` / `pz_simulate.py` at the new path.
4. Update the table in §1 here and in `01_BUILD_GUIDE.md` §1.

That is the whole switch. There is no registry and no code change: the gate
finds skills by scanning the folder.

---

## 6. What is left

In order.

**1. Play both skills on Sai's own phone**, through the real gate, not the
emulator. Only he has one. This is the only thing standing between here and §5.

Checked already, on a 1080x2400 emulator with `-gpu host`:
- band b: every drawing; equation, shelf and text questions played end to end —
  tap, grade, green praise, red "The answer is 48.", Continue
- band d: sequences, clue cards, the deduction grid, both alphabet tables, the
  symbol key, the bulbs, cube nets, the net-face question, cross-sections
  through a cube, a cylinder and a hexagonal prism, polycubes, stacks with
  their side views, the turning cube and the rolling dice
- the yellow cutting sheet stays a plain square whatever the cut, so it never
  traces the answer
- the shipped skills still draw: band c its board, band a its tap targets

**2. Then, and only then, §5.**

### Things that turned out NOT to be needed

**A fit checker for band d's solids.** `rs_fits.py` measures its text, and
every solid scales itself to the box it is given — `Solid.voxels` and
`Solid.solidCut` both fit content to the width and height passed in, so neither
can overflow. What they can do is come out too small to read, and no measurement
decides that.

Not needed and deliberately not done: a Kotlin unit test per drawing. The
drawings are geometry; what matters about them is how they look, and a test
asserting that a rectangle is at x=14 would pass while the screen was wrong.

---

## 7. Environment

Beyond [03_ENVIRONMENT.md](03_ENVIRONMENT.md), for the phone work:

```bash
# A phone-shaped emulator. There is no avdmanager in this SDK install, so the
# AVD is two hand-written files; ~/.android/avd/Nupo_Phone.{ini,avd/config.ini}
# already exist. 1080x2400 at 420dpi = 411 x 914 dp, the shape the gate is
# drawn for. Boot with the HOST gpu (see §3).
~/Library/Android/sdk/emulator/emulator -avd Nupo_Phone -no-audio -no-boot-anim -gpu host

# Stop it sleeping mid-session
adb shell settings put system screen_off_timeout 1800000

cd brainpass && flutter build apk --debug
adb install -r -g build/app/outputs/flutter-apk/app-debug.apk
```

Compile-only, much faster than a full APK while iterating on Kotlin:
```bash
cd brainpass/android && ./gradlew :app:compileDebugKotlin
```

Every checker, before any commit:
```bash
cd brainpass/tools/curriculum
python3 ns_simulate.py && python3 ns_grade.py      # band a, shipped
python3 simulate.py    && python3 fits.py          # band c, shipped
python3 pz_simulate.py && python3 pz_grade.py && python3 pz_fits.py
python3 rs_simulate.py && python3 rs_grade.py && python3 rs_fits.py
cd ../../.. && git status --porcelain brainpass/assets/curriculum/   # must be empty
```

That last line is the one that matters most. **The two shipped skills must not
change.** Children are on them.
