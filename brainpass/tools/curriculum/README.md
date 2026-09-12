# Curriculum authoring

> Building a skill for a NEW age band? Start at `../../handoff/README.md`.
> This file is the authoring reference for the two skills that already ship.

The gate's content is a JSON asset, not code. A new skill is a new file; no
Kotlin or Dart changes.

```
data.py       the skill spine: sections, units, stop titles, teach lines
kit.py        the authoring kit — board/question helpers and COMPUTED ANSWERS
u12..u43.py   one file per unit: the real puzzles
authored.py   aggregates the units, plus kid-facing titles and teach lines
emit_json.py  writes ../../assets/curriculum/think_like_a_coder.json
validate.py   are the stored answers the RIGHT answers?
simulate.py   plays the whole skill: can it be asked, can it be answered,
              does it grade, does the ladder terminate — plus reading level
fits.py       measures every row with the real font against the real column
              width, so no label can quietly clip on the phone
```

## Computed answers

Where an answer follows from the board it is worked out by the reference
simulator, not typed in by hand: `ends(board)`, `shortest_steps(board)`,
`only_winner(board, options)`, `box_value(board, "COINS")`. Hand arithmetic over
three hundred questions is a reliable way to ship "the app said my right answer
was wrong", which is the one bug there is no recovering from once a child hits
it. Answers that are a design choice are still written by hand and checked
independently.

`only_winner` also refuses a multiple choice with two correct options — which it
caught repeatedly, usually because the board edge clamped an overshooting loop
onto the right square.

## Editing content

```
python emit_json.py && python simulate.py && python fits.py
```

`simulate.py` runs validate.py's pass too, so it is the one command that has to
be green. It is not optional. It re-runs every board through a reference
simulator and rejects:

- a stated answer that disagrees with what the program actually does
- a multiple-choice question where none or several options clear the board
- a build-a-list puzzle whose steps cannot reach the goal, or where every
  arrangement can (a puzzle with no wrong answer teaches nothing)
- a missing hint, or a "first step that fails" index that is not the first

`simulate.py` adds the checks a phone test would not reliably find:

- an answer a child cannot physically give — a square behind a wall
  (GridBotView ignores taps on walls) traps a child with no way forward. There
  is no upper bound on a number answer: the `count` row above is four tappable
  options, not a 1-9 keypad, and shipped answers already go to 20.
- a question every answer passes, or one where a wrong answer is accepted
- a teach card whose demo board is one of its own question boards, so the
  animation plays the answer before the question is asked
- a ladder that does not serve every question exactly once, or does not
  terminate — checked twice, once answering everything right and once
  answering everything wrong, because a child who gets everything wrong must
  still reach the end

A content bug reaches a child as the app marking a right answer wrong, which
there is no way to recover from in the field. Nothing ships that these scripts
have not passed.

## Words

Kid-facing copy (prompts, hints, teach lines, titles, text options) is checked
against a banned list and a sentence-length cap. The vocabulary is fixed:

| say | not |
|---|---|
| square | tile, box on the board |
| step | block, instruction |
| list of steps | program |

"Block" is banned outright. It read as either an instruction or a board square
depending on who you asked, which is the worst possible property for the one
noun a question hangs on. "Program" stays in the parent-facing roadmap copy and
in the skill's name, but never in a question a child has to read.

## What a question can be

| shape | the child does |
|---|---|
| `predict` | taps the square Nupo ends on |
| `spot` / `debug` | taps a row of the program |
| `count` / `trace` | taps one of four numbers |
| `choose` | taps one of several whole programs |
| `chooseText` / `complete` | taps one of several written answers |
| `compare` | Same square / Different squares |
| `truth` | TRUE / FALSE against a set of facts |
| `fix` / `inverse` | taps steps into slots, then runs it |
| `constrain` | builds a route from a reusable palette, to a step budget |

Numbers are tapped, never typed. A keypad is two gestures instead of one, can be
left half-entered, and cost four rows on a screen already carrying a board and a
listing. The three wrong numbers are the mistakes children actually make — one
too many, one too few — so the answer still has to be worked out.

## Program tokens

```
up down left right      moves
pick open               pick up a star or key, open a door
repeat:N ... end        a loop, drawn as DO N TIMES; nests
if:<sensor> ... end     a condition; optional else
                        sensors: star, key, door, wall-up/down/left/right,
                        any of them prefixed not-
set:BOX:N  add:BOX:N    named boxes holding numbers
?                       a deliberate gap for a `complete` question
```

A program is a FLAT list of tokens. Loops and conditions are written with
`end` rather than nesting the JSON, which keeps the program drawable as numbered
rows and keeps whole tokens placeable in the answer bank.

## The two simulators must agree

`validate.py` runs at author time; `Curriculum.Sim` in
`android/app/src/main/kotlin/com/brainpass/brainpass/Curriculum.kt` runs on the
phone and grades the child. They implement the same rules:

- a move into a wall or off the board is **skipped**, and the list keeps
  running — this is what makes "tap the first step that fails" answerable
- `pick` only works while standing on the key or a star
- `open` only works while standing on the door **holding** the key

Change one and change the other.

## What "authored" means

Stops carry `"authored": true` only when real puzzles have been written for
them. The gate serves authored stops only (`Skill.ladder`); the roadmap draws
the rest greyed out as "coming soon", so the shape of the whole skill is visible
to a parent from day one without pretending it is playable.


## Number Sense (ages 5-8, band a)

A second skill, built on a different set of pictures. Same discipline, separate
files so the two cannot break each other.

```
numkit.py       the authoring helpers; every answer that follows from the
                picture is computed here rather than typed
ns_units.py     the 48 stops, 324 questions
ns_emit.py      builds assets/curriculum/number_sense.json
ns_simulate.py  plays it: is every question answerable, is the reading within
                range, does the picture actually pose the question asked,
                is any question a repeat of another
ns_grade.py     answers all 324 the way the APP grades them, deriving each
                answer from the picture a second time — if it and the authored
                answer disagree, a child would be marked wrong for being right
figures.py      the shapes-inside-shapes figures, defined once and emitted
                into the JSON so the app, the checker and the review page
                cannot drift; audit() measures every piece and fails the build
                if a rectangle has been called a square
```

```bash
python figures.py && python ns_emit.py && python ns_simulate.py && python ns_grade.py
```

`ns_simulate.py` keeps its own table of what each shape-hunt figure is made of,
written independently of the Kotlin that draws it. If the two ever disagree
about how many triangles a figure has, it fails — the same two-simulator rule
the coder skill uses for board runs.

The checker earned its keep immediately: it found 70 authoring faults on the
first run, including patterns whose answer index pointed at the wrong option and
"how many are yellow?" questions that answered with the total. Those are exactly
the bugs that tell a child their right answer is wrong.


### Why there are two Number Sense checkers

`ns_simulate.py` asks whether a question is FAIR: can it be answered, is the
reading within range, does the picture pose the question the words ask, is it a
repeat. `ns_grade.py` asks something different and harder — whether a child who
does the right thing is marked right. It works every answer out from the
picture a second time, independently of how the question was authored, and runs
it through the same comparison `CoderGate.submit()` uses.

Reading an answer out of the JSON and comparing it to itself proves nothing.
Deriving it again from the drawing is what makes the agreement worth having.
