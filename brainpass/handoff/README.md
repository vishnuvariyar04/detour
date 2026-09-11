# Start here

You are building the learning content for the two age bands Nupo does not have
yet. Everything you need is in this folder. Read it in order; it is about an
hour before you write any code.

## What Nupo is

A child opens a gated app — YouTube, a game. Before it opens, a card covers the
screen with a few questions. Answer them and the app unlocks for a set number of
minutes. The questions are not filler: they walk a real curriculum ladder, and a
parent can see on a roadmap exactly where their child has reached.

The card is **native Android** (Kotlin, drawn by an accessibility service over
the other app). The parent-facing screens are Flutter. The curriculum itself is
neither — it is a **JSON file**, authored in Python and checked by a stack of
scripts before it is allowed anywhere near a phone.

That last point is the job. You are writing content and the drawings for it, not
rebuilding the app.

## The four files here

| Read | File | What it is |
|---|---|---|
| 1st | **[01_BUILD_GUIDE.md](01_BUILD_GUIDE.md)** | The whole job: the shape of a skill, the five-step procedure, the JSON schema, every check that must pass, and the defects already in the shipped skills that you must not copy. |
| 2nd | **[02_SPINES.md](02_SPINES.md)** | The topic source for the two new bands, from the original curriculum plan. Your proposed spine gets approved before you write 324 questions. |
| 3rd | **[03_ENVIRONMENT.md](03_ENVIRONMENT.md)** | Getting the toolchain running, and the commands you will type every day. |
| when reviewing | **question_wall.html** | Every question in both shipped skills, drawn the way the phone draws it. Open it in a browser — no server, no build. |

## The order of work

```
1. Author the content in Python        →  the JSON asset
2. Build the wall, review it, GET SIGN-OFF   ←  hard stop, do not skip
3. Build it in Kotlin                  →  the drawings
4. Test on a real phone
5. Ship
```

**Step 2 is a gate, not a checkpoint.** Building Kotlin views for questions that
then get rewritten is the most expensive mistake available on this project. Get
the spine approved before authoring, and the questions approved before drawing.

## The one rule

> A content bug reaches a child as **the app marking a right answer wrong**.
> There is no recovering from that in the field.

Every checking script in this repo exists for that sentence. They are not
optional and they are not advisory — if one is red, nothing ships.

## Where things actually live

```
brainpass/
├─ handoff/                    ← you are here
├─ assets/curriculum/*.json    ← the curriculum. This is the deliverable.
├─ tools/curriculum/           ← the Python that authors and checks it
│  ├─ README.md                ← authoring reference, written for the two shipped skills
│  ├─ wall_template.html       ← the wall's renderers, mirroring the Kotlin views
│  └─ build_wall.py            ← builds the review page
├─ tools/e2e/drive.py          ← answers a whole skill on a real phone
├─ tools/WHEN_PHONE_IS_BACK.md ← device checks, and the HyperOS traps
└─ android/app/src/main/kotlin/com/brainpass/brainpass/
   ├─ Curriculum.kt            ← reads the JSON, and the simulator that GRADES the child
   ├─ CoderGate.kt             ← the card itself: layout, taps, verdicts
   └─ *Views.kt                ← one file per family of drawings
```

`tools/curriculum/README.md` is the deep reference for the authoring kit. Read it
after 01_BUILD_GUIDE.md, not before — the guide tells you which parts apply.

## One warning about the older docs

`brainpass/SETUP_AND_TESTING.md` is **out of date**. It describes a Dart-based
overlay (`lib/services/detection_service.dart`, `lib/overlay/earn_card.dart`)
that no longer exists — the gate was rewritten in native Kotlin. Use
[03_ENVIRONMENT.md](03_ENVIRONMENT.md) instead. Its section on *why you need a
real phone* is still true and still worth reading.

## Ask early

Three things are genuinely undecided and are yours to raise, not to guess:

1. **The spines in 02_SPINES.md** cover four weeks per band in the original plan;
   a skill needs twelve units. The expansion in 01_BUILD_GUIDE.md §4.1 is a
   proposal. Get it signed off first.
2. **Band D's 3D section** — nets, rotation, cross-sections — would be the first
   true 3D drawing in the app. Prove one on a phone before authoring twelve
   stops that depend on it.
3. **The count pad stops at 9.** Band D wants answers above that. Either pose
   those as multiple choice or agree on a new input, early.
