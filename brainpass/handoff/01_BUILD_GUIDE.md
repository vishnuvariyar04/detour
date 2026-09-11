# Building bands B and D

A hand-off. Two of the four age bands have a real skill; two do not. This
document is everything needed to build the other two, in the order it has to
happen.

Read it with the question wall open beside you — `handoff/question_wall.html`,
or a fresh one from `python build_wall.py`. That page is where this work is
reviewed and approved, and it is step 2 of five.

Read [README.md](README.md) first if you have not. Topic sources for the two new
bands are in [02_SPINES.md](02_SPINES.md); toolchain and daily commands are in
[03_ENVIRONMENT.md](03_ENVIRONMENT.md).

---

## 1. Where things stand

The app sorts children into four age bands. The gate serves **the most advanced
skill whose band the child has reached**, so a skill written for band b is also
what a band-c child sees if nothing better exists.

| Band | Ages | Skill | Stops | Questions | Status |
|---|---|---|---|---|---|
| a | 5–6 | Number Sense | 48 | 324 | shipped |
| **b** | **7–8** | **Puzzles & Logic** | 48 | 324 | **to build** |
| c | 9–10 | Think Like a Coder | 48 | 324 | shipped |
| **d** | **11** | **Reasoning** | 48 | 324 | **to build** |

Band b and band d children currently fall through to the older random-question
engine (`Questions.kt`), which has no ladder, no roadmap and no progress. That
is the gap.

### The one rule everything else serves

> A content bug reaches a child as **the app marking a right answer wrong**.
> There is no recovering from that in the field.

Every gate, every second simulator and every review step below exists for that
one sentence. Nothing ships that the checks have not passed.

---

## 2. The shape of a skill

Both shipped skills have exactly the same shape, and the new ones must too.

```
skill
└── 4 sections          a big idea        "Sequences"
    └── 3 units         a sub-idea        "Order Matters"
        └── 4 stops     one lesson        "One step at a time"
            └── 6–7 questions
```

- 4 × 3 × 4 = **48 stops**, **324 questions**.
- The **last stop in every unit is a boss** (`"boss": true`) — 12 bosses.
- Every stop carries a **teach card**: one sentence, shown before its questions.
- A stop is served only when `"authored": true`. Unauthored stops still appear
  on the parent's roadmap, greyed out as "coming soon", so the shape of the
  whole skill is visible from day one without pretending it is playable.

This is not a target to approximate. The wall, the drivers and the roadmap all
assume it.

---

## 3. The procedure

Five steps, in this order. Do not start step 3 before step 2 is signed off —
building Kotlin views for questions that then get rewritten is the most
expensive mistake available here.

| # | Step | Output |
|---|---|---|
| 1 | Author the content in Python, emit the JSON | `assets/curriculum/<skill>.json` |
| 2 | **Build the wall, review every question, get approval** | sign-off |
| 3 | Build it in Kotlin | new views + registry entries |
| 4 | Test everything on the phone | a green `drive.py` run |
| 5 | Ship | — |

---

## 4. Step 1 — Author the content

### 4.1 Proposed spines

These follow the band B and band D spines in **The Nupo Ladder**, folded into
the 4 × 3 × 4 shape. **Get these approved before writing 324 questions.**

**Band B — Puzzles & Logic (ages 7–8)**

| Section | Units |
|---|---|
| 1. Patterns | Repeating patterns · Number steps · Growing patterns |
| 2. Rules | What is the rule · Odd one out and why · Sorting into groups |
| 3. Codes | Analogies · Symbol codes · Shift codes |
| 4. Logic | True or false · What is missing · Putting it together |

**Band D — Reasoning (age 11)**

| Section | Units |
|---|---|
| 1. Sequences | The next term · The nth term · Squares, cubes, second differences |
| 2. Logic | If–then · Always, sometimes, never · Deduction grids |
| 3. Codes | Binary · Shift ciphers · Substitution |
| 4. Space | 3D nets · Rotating in 3D · Cross-sections |

### 4.2 Files to create

Copy the Number Sense set — it is the cleaner of the two and does not carry the
coder skill's board simulator.

```
puzzles_kit.py      authoring helpers; every answer that follows from the
                    picture is COMPUTED here, never typed
pz_units.py         the 48 stops, 324 questions
pz_emit.py          writes ../../assets/curriculum/puzzles_and_logic.json
pz_simulate.py      is every question fair, answerable, readable, not a repeat
pz_grade.py         derives every answer from the picture a SECOND time and
                    compares against the authored answer
```

Same five files again for band d (`reasoning_*`). Separate files per skill so
the two cannot break each other — that rule already saved the coder skill once.

### 4.3 Computed answers, not typed ones

Where an answer follows from the picture, work it out in code:
`ends(board)`, `shortest_steps(board)`, `only_winner(board, options)`.

Hand arithmetic over three hundred questions is a reliable way to ship "the app
said my right answer was wrong". `only_winner` also refuses a multiple choice
with two correct options — it caught that repeatedly on the coder skill.

Answers that are a design choice are still written by hand, and checked
independently.

### 4.4 The JSON schema

```jsonc
{
  "id": "puzzles_and_logic",
  "name": "Puzzles & Logic",
  "band": "b",                    // LOWERCASE — see §8.1
  "ages": "7–8",
  "promise": "One sentence a parent reads on the roadmap.",
  "sections": [{
    "n": 1,
    "title": "Patterns",          // "title", NOT "name" — see §8.2
    "subtitle": "A pattern is a rule you can see.",
    "units": [{
      "n": 1,
      "title": "Repeating patterns",   // "title", NOT "name"
      "stops": [{
        "id": "1.1.1",
        "title": "What comes next",
        "authored": true,
        "boss": false,
        "teach": { "line": "...", "demo": "...", "board": { } },
        "questions": [{
          "shape": "pattern",
          "prompt": "Tap the shape that comes next.",
          "hint": "Say the pattern out loud.",
          "pic":    { },          // the drawing
          "answer": { "type": "option", "value": 2 },
          "choices": [ ]
        }]
      }]
    }]
  }]
}
```

**Two traps that are already live bugs in Number Sense — do not copy them:**

- `band` must be **lowercase**. See §8.1.
- Sections and units must use `title` / `subtitle`, **not** `name` / `promise`.
  See §8.2.

---

## 5. Step 2 — The wall, and approval

```bash
cd brainpass/tools/curriculum
python build_wall.py
```

Writes `brainpass/build/wall/question_wall.html` — every question in every
skill, drawn the way the phone draws it, on one scrollable page. 648 questions
today; 1296 once both new skills land.

> The template lives at `tools/curriculum/wall_template.html`. It used to live
> in a temp directory belonging to a single session, which made the wall
> unbuildable the moment that directory was cleared. It is in the repo now.
> Keep it there.

The page gives you:

- every question as a rendered phone screen, grouped by unit
- filters by skill, by shape, by prompt text
- **same screen** — two questions a child cannot tell apart
- **same words** — a prompt reused elsewhere (232 today; usually fine, but
  worth a look)
- a basket: tick questions, type a note, **Copy notes for Claude**

**Review the whole wall before asking for sign-off.** What you are looking for:

1. Does the picture actually pose the question the words ask?
2. Could a 7-year-old (or 11-year-old) read the prompt in one go?
3. Is the answer unambiguous — exactly one option correct?
4. Are the three wrong numbers the mistakes children actually make (one too
   many, one too few), so the answer still has to be worked out?
5. Does anything repeat that should not?

Then publish the wall as an artifact and send Vishnu the link — the full loop,
including how to republish to the same URL and what his feedback looks like when
it arrives, is in [04_REVIEW_LOOP.md](04_REVIEW_LOOP.md). **Do not proceed to
Kotlin until you have sign-off.**

---

## 6. Step 3 — Build it in Kotlin

### 6.1 What already exists

32 question shapes are drawn today. Reuse before you build.

| View file | Shapes it draws |
|---|---|
| `GridBotView.kt` | the coder board — `predict`, `fix`, `inverse`, `constrain` |
| `BlockViews.kt` | program listings — `spot`, `debug`, `complete`, `choose` |
| `NumberViews.kt` | `tenFrame`, `rods`, `dice`, `bond`, `numberLine` |
| `GroupViews.kt` | `array`, `groups`, `barModel`, `count` |
| `ShapeViews.kt` | `shapeHunt`, `shapeCount`, `mirror`, `fraction`, `fractionWall` |
| `SortViews.kt` | `sortTwo`, `sizeOrder`, `oddOneOut`, `balance` |
| `PlayViews.kt` | `pattern`, and the shared option rows |
| `Design.kt` / `Glyphs.kt` / `Anim.kt` | palette, icons, the 400ms motion |

**Puzzles & Logic reuses most of this.** `pattern`, `oddOneOut`, `sortTwo`,
`sizeOrder`, `count`, `choose`, `chooseText`, `compare`, `yesno` and `complete`
cover perhaps three quarters of the skill. Genuinely new: an **analogy** view
(A is to B as C is to ?) and a **code** view (a symbol/letter key plus a word to
decode).

**Reasoning is the heavier build.** Sequences and logic reuse the option rows,
but §4 Space needs a **3D net**, a **rotation** and a **cross-section** view —
the first true 3D drawing in the app, and the largest new view work so far.
Budget for it, and consider proving one of them on the phone before authoring
all twelve stops of that section.

### 6.2 Wiring a new shape

Four places, all in `CoderGate.kt` unless noted:

1. **Draw it** — a new `View` in the right `*Views.kt` file.
2. **Register it** — the `when (q.shape)` at `CoderGate.kt:893`.
3. **Accept a tap** — `hasAnswer()` at `:1364`, `submit()` at `:1411`,
   verdict at `:1471`, `explain()` at `:1502`.
4. **Report its tap targets** — the gate logs
   `NupoGate: ... targets <qid> <shape> key=x,y ...`, which is the only way
   `drive.py` can find anything. A shape that does not report targets cannot be
   machine-tested.

### 6.3 Add the skill to the JVM gate

`AnswersTest.kt` has one `@Test` per skill
(`everyCoderAnswerIsTheOneTheBoardGives`,
`everyNumberSenseAnswerIsTheOneThePictureGives`). **Add one per new skill.** It
re-derives every answer using `Curriculum.Sim` — the very code that grades the
child — and fails the build on disagreement.

---

## 7. Step 4 — Test on the phone

### 7.1 Install

```bash
cd brainpass
flutter build apk --debug
ADB=$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe
"$ADB" install -r build/app/outputs/flutter-apk/app-debug.apk
bash tools/reset_progress.sh
```

**HyperOS revokes "draw over other apps" on every reinstall**, and without it
the gate silently never appears. `reset_progress.sh` re-grants it, clears the
ladder back to stop 1.1.1, and clears earned minutes (otherwise the gate will
not fire until the current unlock runs out).

### 7.2 See the drawings alone first

```bash
"$ADB" shell am start -n app.nupo.kid/com.brainpass.brainpass.NumberPreviewActivity
```

A gallery of every new drawing, replaying every 2.6s. Check for overflow and
for contrast — yellow on white is the weakest pair in the palette and it is the
second colour everywhere.

### 7.3 Put the device on the right band

The gate serves the most advanced skill the band allows, so to see a band-b
skill you must set the device to band b:

```bash
"$ADB" shell am force-stop app.nupo.kid
"$ADB" shell "run-as app.nupo.kid sed -i \
  's|<string name=\"ageBand\">c</string>|<string name=\"ageBand\">b</string>|' \
  /data/data/app.nupo.kid/shared_prefs/brainpass_engine.xml"
bash tools/reset_progress.sh
```

**Put it back to `c` afterwards** — that is the real child's setting.

### 7.4 Tap through the whole skill

```bash
cd tools/e2e
python drive.py 15 puzzles_and_logic    # smoke test
python drive.py 0  puzzles_and_logic    # then all 324
```

The simulator proves a question **can** be answered. This proves the answer can
be **tapped** — that the thing the child touches maps to the thing the engine
grades. Those are different failures and only this catches a mis-wired shape.

`drive.py` needs a target rule per shape (`target()` at `tools/e2e/drive.py:163`).
Multi-tap shapes return a list of points tapped in turn. **Re-run the other
skills too** — the gate changes underneath them.

### 7.5 Watch one animation actually play

`screencap` takes about a second, so it cannot catch a 400ms animation; every
screenshot shows the settled state. Use video:

```bash
"$ADB" shell screenrecord --time-limit 6 /sdcard/a.mp4
"$ADB" pull /sdcard/a.mp4 . && ffmpeg -i a.mp4 -vf fps=20 f%03d.png
```

---

## 8. Inherited problems — read before you copy anything

These are real and unfixed **today**. Two of them are patterns you would
otherwise copy straight into the new skills.

### 8.1 `band` is uppercase in the coder skill, and Dart does not lowercase it

`think_like_a_coder.json` has `"band": "C"`. `Curriculum.kt:335` calls
`.lowercase()`; `lib/curriculum.dart:43` does not. Because `'C'` (0x43) sorts
below `'a'` (0x61), `Curriculum.load()` picks the **wrong skill** for a band-c
child: the gate serves Think Like a Coder while the roadmap draws Number Sense.
The file's own header comment says the two "can never describe two different
curricula" — right now they do.

Fix: `"band": "c"` in the JSON, and `.toLowerCase()` in the Dart for safety.
**Write the new skills' bands lowercase.**

### 8.2 Number Sense section and unit names do not render

`number_sense.json` emits `name` / `promise` on sections and `name` on units.
Both readers want `title` / `subtitle` / `title`
(`Curriculum.kt:352,357`, `lib/curriculum.dart:121,138`). Every section header
and unit label on the Number Sense roadmap is therefore **blank** —
`roadmap_screen.dart:524,533,571` renders empty strings.

Fix: emit `title` / `subtitle`. **Use `title` in the new skills.**

### 8.3 `fits.py` currently fails

```
FAIL 3.2.3#5: "IF NO WALL RIGHT" needs 108dp, has 92dp (depth 1, column 134dp)
1 row(s) will clip
```

One label in the coder skill will clip on the phone. It is committed and
unfixed. Shorten the token or widen the column before this compounds.

### 8.4 Finishing a skill falls back to random questions

Running past the last stop leaves `stopIndex` one past the end and the gate
quietly serves the old `Questions` bank instead. Whoever finishes a skill first
hits this. Still open.

### 8.5 Number Sense teach cards have a line but no demo

The coder skill plays a worked example before each stop; Number Sense just
shows the sentence. The pictures to build demos from now exist. Decide early
whether the new skills get demos — it is much cheaper to author them up front.

### 8.6 A docstring disagrees with the data

`ns_units.py:2` says Number Sense is "ages 7-8"; the JSON says band `a`,
ages `5-6`; the README says "ages 5-8". Settle which is true before band b
lands next to it, or the two will overlap.

---

## 9. The gates

`simulate.py` (coder) and `ns_simulate.py` + `ns_grade.py` (Number Sense) are
not optional. They must be green.

```bash
cd brainpass/tools/curriculum

# coder
python emit_json.py && python simulate.py && python fits.py

# number sense
python figures.py && python ns_emit.py && python ns_simulate.py && python ns_grade.py

# both, on the JVM, against the code that grades the child
cd ../../android && ./gradlew :app:testDebugUnitTest
```

Current state: everything green **except `fits.py`** (§8.3).

### What the checks reject

- a stated answer that disagrees with what the program actually does
- a multiple choice where none, or several, options clear the board
- a build-a-list puzzle that cannot reach the goal — or where *every*
  arrangement can, which teaches nothing
- a missing hint, or a "first step that fails" index that is not the first
- **an answer a child cannot physically give** — a count above 9 (the pad stops
  there) or a square behind a wall (taps on walls are ignored). Either traps a
  child on a question with no way forward.
- a question every answer passes, or one where a wrong answer is accepted
- a teach card whose demo board is one of its own question boards — the
  animation would play the answer before the question is asked
- a ladder that does not serve every question exactly once, or does not
  terminate. Checked **twice**: once answering everything right, once answering
  everything wrong, because a child who gets everything wrong must still reach
  the end.

> **The count pad stops at 9.** This bites band d hardest — nth term, binary
> values, squares and roots all want answers above 9. Either pose them as
> multiple choice, or build a new input and say so early.

### The two-simulator rule

`validate.py` runs at author time. `Curriculum.Sim` runs on the phone and
grades the child. They implement the same rules:

- a move into a wall or off the board is **skipped**, and the list keeps
  running — this is what makes "tap the first step that fails" answerable
- `pick` works only while standing on the key or a star
- `open` works only while standing on the door **holding** the key

**Change one and change the other.** They have drifted twice; both times the
symptom was a right answer marked wrong on the device.

Reading an answer out of the JSON and comparing it to itself proves nothing.
Deriving it again from the drawing is what makes the agreement worth having.
That is why `ns_grade.py` exists alongside `ns_simulate.py`, and why
`AnswersTest.kt` exists alongside both.

---

## 10. Words

Kid-facing copy — prompts, hints, teach lines, titles, text options — is
checked against a banned list and a sentence-length cap.

| say | not |
|---|---|
| square | tile, box on the board |
| step | block, instruction |
| list of steps | program |

**"Block" is banned outright.** It read as either an instruction or a board
square depending on who you asked, which is the worst possible property for the
one noun a question hangs on. "Program" is fine in parent-facing roadmap copy
and in a skill's name, never in a question a child reads.

Numbers are **tapped, never typed**. A keypad is two gestures instead of one,
can be left half-entered, and costs four rows on a screen already carrying a
picture and a listing.

---

## 11. Done means

- [ ] Spine approved (§4.1)
- [ ] 48 stops, 324 questions, 12 bosses, every stop `authored: true`
- [ ] `band` lowercase; sections and units use `title` / `subtitle`
- [ ] The skill's own `*_simulate.py` and `*_grade.py` green
- [ ] `fits.py` green — no row clips
- [ ] Wall built, every question reviewed, **sign-off received**
- [ ] A `@Test` for the skill in `AnswersTest.kt`, and `./gradlew
      :app:testDebugUnitTest` green
- [ ] Every new shape reports tap targets
- [ ] `python drive.py 0 <skill>` green on a real phone, on the right band
- [ ] The other skills re-driven — the gate changed underneath them
- [ ] Device band put back to the real child's setting
