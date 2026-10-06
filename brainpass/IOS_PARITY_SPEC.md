# Nupo iOS ↔ Android parity spec

**What iOS must look like and do so it matches Nupo for Android 1.4.5 (October 2026).**

This document describes **outputs only**: what each screen shows, what the parent or child can do on it, what gets saved, and what the result must be, as it works on Android today. It does not say how to build anything on iOS. Where this document and the Android behaviour disagree, the Android build and its source files win. The repo is shared with you, and each section names the files to look at.

**Out of scope:** the PostHog setup, payments and the paywall. §12 lists the analytics events the new screens send. §13 covers measuring Meta ads, §14 the store listing.

**What Android has today:**

1. A new **tapped onboarding story** with a real demo lesson (§3).
2. A new **setup flow** after sign-in (§5).
3. A real **curriculum**: four skills, one per age band, 48 lessons and 324 questions each, which replaces the random quiz entirely (§6–§7).
4. A redesigned **lesson screen** (§8).
5. Redesigned **Learning** and **Parent** tabs (§9–§10), including the child-age screen (§10.1).
6. **Ad measurement** for Facebook and Instagram ads aimed at parents (§13).
7. A new **store listing**: copy, eight screenshots and a feature graphic (§14).

---

## 0. Where the truth lives (Android repo)

| Area | Source of truth |
|---|---|
| Curriculum content (all four skills) | `brainpass/assets/curriculum/*.json`. **Bundle these exact files.** Do not retype or regenerate them. |
| How content is generated and checked | `brainpass/tools/curriculum/` (Python). Never edit the JSON by hand; regenerate it with these tools. |
| Session, progress, and review rules | `android/.../Curriculum.kt` (the `session`, `Progress`, and `Sim` objects) |
| Lesson screen | `android/.../CoderGate.kt`, `GateChrome.kt`, `Design.kt` |
| Question pictures (what each looks like) | `android/.../NumberViews.kt`, `GroupViews.kt`, `SortViews.kt`, `ShapeViews.kt`, `PlayViews.kt`, `PuzzleViews.kt`, `ReasonViews.kt`, `GridBotView.kt`, `BlockViews.kt` |
| Onboarding story | `lib/screens/onboarding/story_flow.dart`, `demo_lessons.dart`, `onb_kit.dart` |
| Setup after sign-in | `lib/screens/onboarding/onboarding_flow.dart`, `course_steps.dart` |
| Learning tab | `lib/screens/roadmap_screen.dart` |
| Parent tab and bottom bar | `lib/screens/parent_home_screen.dart`, `home_shell.dart` |
| Design tokens | `lib/theme.dart`, `lib/screens/onboarding/onb_kit.dart` |
| Analytics events | `lib/analytics.dart`, `android/.../Analytics.kt`, `ANALYTICS.md` |
| Child-age screen (Parent tab) | `lib/screens/age_band_screen.dart`, `AgeCard` in `story_flow.dart` |
| Ad measurement | `lib/ad_attribution.dart`, the Meta block in `android/app/src/main/AndroidManifest.xml`, `android/meta.properties.example` |
| Store listing and screenshots | `store_assets/listing_en.md`, `store_assets/screenshots/`, `store_assets/feature_graphic.png` |
| Privacy wording | `legal/PRIVACY_POLICY.md` (also live at nupo.app/privacy), `legal/DATA_SAFETY.md` |

All copy quoted below is the exact Android text. Use it word for word.

---

## 1. Visual language (applies everywhere)

- **Font:** Nunito, weights 400–900, on every screen including the lesson.
- **Colours** (`lib/theme.dart`):
  - Purple `#7C3AED` is the brand and primary action. Deep purple `#5B21B6` is its "ledge" colour. Bright purple `#8B5CF6` is the gradient partner.
  - Logo yellow `#F9C13C` (accent) means **reward, warmth, or current**. Use it for streaks, "up next", minutes earned, and hints.
  - Green `#12B76A` means correct or on. Red `#F04438` means wrong or danger. Teal `#0E9384` and blue `#6D8BFF` are secondary section colours.
  - The page background is lilac `#F6F1FF`. Text is ink `#241C3B`, and muted text is `#7C7789`.
- **Chunky buttons.** Every main button is a flat face sitting on a darker ledge about 4–6pt deep. Pressing it moves the face down onto the ledge (Duolingo style). Variants: purple, amber (dark text), green, white, and ghost.
- **Cards** are white with a 2pt lilac border (`#EADFFB`) and a 3pt ledge in the same lilac, not a soft blur shadow.
- **Mascot (the owl).** Use the PNG poses in `assets/nupo/`, never redrawn:
  - `teacher`: new idea
  - `focused`: asks the question or waits on the path
  - `idea`: hint
  - `cheer`: correct
  - `shrug`: not quite
  - `trophy`: stop complete, end of course
  - `cool`: Pro member
  - `star-student`: Pro upsell
  - `wave`: welcome or footer
  - `ohno`: destructive confirm
- **Little text.** One headline and one short line per screen. No tip boxes or paragraphs.

---

## 2. App order (what a parent sees, in order)

1. **Splash:** solid logo yellow with the owl.
2. **Onboarding story** (§3). Shown until it has been seen once. A returning parent can tap "I already have an account" to skip straight to sign-in.
3. **Sign-in.** Mandatory (Android: Google, or email and password). If the story picked a course, the header says "Save <course name>".
4. **Setup** (§5). Skipped entirely if the account already has a saved setup (§11). In that case only the parent PIN and the permissions are asked, then the parent goes straight home.
5. **Paywall**, if the account has no Pro (only while the paywall switch is on).
6. **Home:** two tabs, Learning (§9) and Parent (§10).

---

## 3. Onboarding story (before sign-in): 10 tapped screens

There is no scrolling. Each screen has one button, and a thin 10-segment progress bar runs across the top. Screens 6–9 are drawn **as the child's phone** (a dark rounded "phone" frame) so the parent can tell child-facing screens apart. Copy and layout: `story_flow.dart`.

| # | Screen | Shows | Needs | Button |
|---|---|---|---|---|
| 1 | Welcome | The phone illustration with four skill cards around it (Count, Code, Loops, Binary) and the owl with a trophy. Title **"Turn phone time into real skills."** Subtitle **"A short lesson before every game or video."** | — | **Get started**, plus a text link **I already have an account** |
| 2 | Their afternoon | Eyebrow **SOUND FAMILIAR?** Title **"After school, the same apps. Again and again."** A card showing "New skills today: 0". | — | Continue |
| 3 | The idea | Eyebrow **THE IDEA** (yellow). Title **"What if every app opened after a short lesson?"** A diagram: Lesson → app open for 15 min → "Daily limit. Done for today." Line **"Same apps. A new skill, a little every day."** | — | Continue (white) |
| 4 | Age | The owl asks in a speech bubble: **"How old is your child?"** Four course cards: 5–6, 7–8, 9–10, 11–12, each with its picture and course name. | **Must pick.** Saves age and age band (a/b/c/d) and picks the child's course (§6). | Continue (disabled until picked) |
| 5 | Their app | The owl asks: **"Which app do they open first?"** Four choices with real icons: YouTube, Roblox, TikTok, Minecraft. | **Must pick.** The app name is used for the rest of the story and is pre-ticked later in the real app picker. | Show me |
| 6 | Lesson time | On the child's phone: the lesson card. **"Then <app> opens."** | — | Start |
| 7 | A new idea | The child's phone shows the demo lesson's **teach line and picture** (§4). | — | Got it |
| 8 | Try it | The child's phone shows the **real demo question** (§4). | **Must answer correctly to go on.** A wrong tap shows **Not quite** with "<hint> Try again." There is also a Hint option. | After a correct answer: **Nailed it!**, then **Unlock <app>** (green) |
| 9 | Unlocked | The app opens, the course moves on, and the owl cheers. | — | Continue |
| 10 | The whole course | **"That was lesson N.\nThere are 48."** and **"<Course name>, built for ages <ages>."** Soft chips include "You set the limits". | — | **Build their course** (goes to sign-in) |

---

## 4. Demo lesson per age band (must equal the real curriculum)

The demo is a **real lesson from the child's own course**. The teach line and the question are copied from the curriculum, and the idea shown is exactly what the question asks. Full content, outcomes, and path copy are in `demo_lessons.dart`. Android has a test that fails if the demo drifts from the JSON.

| Band | Course | Lesson | Teach line | Question | Answer |
|---|---|---|---|---|---|
| a (5–6) | Number Sense | stop 2.1.2 (ten-frame) | "Two parts that make ten are a pair worth knowing." | "How many more counters would fill the frame?" (hint: "Count the empty ones.") | the number of empty cells |
| b (7–8) | Puzzles & Logic | stop 3.3.3 (number code) | "A is 1, B is 2, C is 3." | "A is 1. Which word does this code spell?" with code 2-5-4 (hint: "Count along the alphabet from A.") | **BED** |
| c (9–10) | Think Like a Coder | stop 2.1.1 (loops) | "When the same steps come back again and again, use a loop." | "Tap the square this loop ends on." Program: repeat 3× [RIGHT, UP] (hint: "Right, up. Then again, and again.") | square (3,3) |
| d (11+) | Reasoning | stop 3.1.1 (binary bulbs) | "Each bulb is worth double the one on its right. Add the lit ones." | "Add up the lit bulbs. Tap the number." (hint: "Add only the bulbs that are lit.") | **11** |

Each course also has four parent-facing **outcomes** (icon, title, line). These are used in setup (§5). Examples: Number Sense "Counts anything, fast / Up to 50, by tens and ones."; Reasoning "Reads binary / And breaks secret codes."

---

## 5. Setup after sign-in

A back circle and a slim progress track sit at the top. Order (`onboarding_flow.dart`, `course_steps.dart`):

1. **Child's name.** **"What's your child's name?"** Text field. The next screen greets them: **"Hi, <name>!"**
2. **Buddy.** **"Name <child>'s buddy"**, with the owl in sunglasses. Idea chips: Nupo, Hoot, Ziggy, Pip. Button **That's the one**. If left empty, the name is "Nupo".
3. **What they'll learn.** Header **"<CHILD>'S COURSE"**, then "<48> lessons · ages <ages>" and the four outcome rows, each in its own colour (purple, teal, dark gold, red).
4. **How Nupo teaches.** Three rows:
   - **Learn, then practise**: "One idea, then questions."
   - **Mistakes come back**: "Until they stick."
   - a boss row: "One to finish every unit."
5. **Their path.** **"<child>'s path"** on purple. Milestones run from **STARTS TODAY** through **WEEK 2, WEEK 3…** Button **Set up <child>'s course** (amber).
6. **Apps.** The parent picks which apps need a lesson first. The app picked in the story is pre-selected.
7. **The trade:**
   - **Each lesson earns** N min (5–60 in steps of 5; default 15).
   - **Daily limit** per app (steps of 15; default 60; never less than the per-lesson minutes), labelled "per app, then done for today".
   - **THAT ADDS UP TO**:
     - lessons a day = limit ÷ minutes
     - play earned = lessons × minutes
     - time **to finish the course** = 324 ÷ (3 × lessons a day), shown as "~N days", "~N wks" or "~N mo"
   - Footer: "Change it any time." The values are saved to **every** chosen app's rule.
8. **Parent PIN.** Four digits, entered twice.
9. **Permissions.** A short intro, then one screen per permission (display over other apps, usage access, background battery, and auto-start on phones that have it). Each shows an illustration, says what it is for, opens the setting, and moves on by itself once it is granted.
10. **Ready.** The owl with a trophy. **"Lesson 1 starts the next time they open <first app>."** It shows "<minutes> min · <limit>" per app. Button **Go to dashboard** (amber). This is where "setup complete" is recorded.

---

## 6. The curriculum (replaces the random quiz)

Four skills. Each has 4 sections × 3 units × 4 stops (48 stops, called "lessons" in parent copy), with 6–7 questions per stop: **324 questions per skill**. Every stop has a teach card (a line plus a picture or demo), and every question has its own hint.

| File | Skill | Band | Ages | Sections |
|---|---|---|---|---|
| `number_sense.json` | Number Sense | a | 5–6 | Counting · Making numbers · Looking · Putting it together |
| `puzzles_and_logic.json` | Puzzles & Logic | b | 7–8 | Number thinking · Order and position · Relations and codes · Logic |
| `think_like_a_coder.json` | Think Like a Coder | c | 9–10 | Sequences · Loops · Conditions · Debugging |
| `reasoning.json` | Reasoning | d | 11–12 | Sequences · Logic · Codes · Space |

**Which skill a child gets:** the most advanced skill whose band is at or below the child's band. A child is never given a skill written for older children. Every band currently has exactly its own skill.

**Structure per stop** (JSON): `id` (e.g. "2.1.3" = section.unit.stop), `title`, `boss` (the last stop of each unit is the boss), `authored`, `teach` (`line`, plus a `pic`, a `demo` board, or a `compare` pair), and `questions[]`. Each question has a `shape` and a `prompt`, optionally a `pic`, the answer fields, and a `hint`. The JSON is the single source of content and answers. **Grade against the stored answer.** Never compute the answer from the picture at runtime.

### 6.1 Question shapes and how each is answered

The look of each picture is defined by the matching Android view (§0). Match it.

**Number Sense (band a)**

- **Pick a number:** countObjects, dice, tenFrame, rods, bond, shapeCount, array, groups, barModel. Show the picture, then a row of number buttons.
- **numberLine:** tap the right point or number on the line.
- **Pick an option:** balance, pattern, fraction, fractionWall, oddOneOut. For oddOneOut, the child taps the odd item in the picture itself.
- **shapeHunt:** tap **every** piece of the target shape (multi-select). It is graded on *which kind* was found, so any matching piece counts.
- **sizeOrder:** tap the items in order. **mirror:** tap cells to complete the mirror image. **sortTwo:** move items between two trays. It is always submittable, because "none belong" can be a valid answer.

**Think Like a Coder (band c).** These use a grid board with the owl as the robot. A board can have a start, a flag (goal), stars, walls, a key and a door, and named boxes (variables). An illegal move is skipped and the program carries on.

- **predict:** tap the square the program ends on.
- **spot / debug:** tap a step in the program list.
- **count / trace:** pick a number. For trace, a trace table has one blank row to fill.
- **choose:** pick one of four programs (A–D).
- **chooseText / complete / compare / yesno:** pick a sentence (compare: "the same square" vs. "different squares").
- **fix / inverse / constrain:** build a program by tapping blocks into slots. The button reads **Run it**. The program **runs on the board, animated, before it is judged**.

**Puzzles & Logic (band b) and Reasoning (band d):** 52 shapes, but only four ways to answer:

1. Pick one of four **numbers**.
2. Pick one of several **sentences**.
3. Pick one of four **drawn shapes** (`optionCells` / `optionShapes`).
4. Pick one of several **drawings of their own kind**: nets, cube views, cross-sections, side views, rows of binary bulbs.

The drawing above the answers comes from `pic.kind`:

- band b: card, equation, bars, series, line, shelf, compass, wordPairs, numPairs, letter, example, numExample, words, clock
- band d: sequence, clues, truth, claim, grid, binary, binaryAsk, shift, symbols, letters, mirrorAlpha, example, net, polycube, turnCube, roll, stack, section

A small caption under the answers says what to tap, for example "Tap the number." or "Tap a net."

**Clue and story cards** (pic kinds `card`, `clues`, `truth`, `claim`, `grid`, `compass`) must use the **new card design** in §8.4, not a cream or yellow box.

---

## 7. Lesson rules (behaviour that must match exactly)

- **One lesson is one stop.** When a lesson is due, the child gets the **rest of the current stop**: all its remaining questions, about a minute. If the app's question setting is higher than what the stop has left, the next stop is added. Questions are not skipped to reach a round number.
- **The teach card comes first**, the first time a stop is opened. It does not count as a question. Once seen it is not shown again.
- **One review question first.** If the child got a question wrong earlier, one missed question is asked at the start of the next lesson. Rules:
  - A right answer removes it from the review queue; a wrong one sends it back to the end.
  - The queue holds at most 20, oldest dropped first.
  - Review questions **do not move** the child's place on the path.
- **The place on the path moves once per question**, on its first showing, right or wrong. A repeat of a missed question (in the same lesson or from the review queue) never moves it again. An interrupted lesson resumes at the exact question.
- **Wrong answers come back in the same lesson.** The right answer is shown, along with the line "You'll see this one again at the end." The **same question is then added to the end of the lesson** (its choices shuffled again). **The lesson only ends when every question has been answered right**, with no attempt limit. The missed question also stays on the review queue until it is answered right. No stars or points are lost.
- **Minutes are earned when the lesson is finished**, i.e. once every question in it is right. The finish button is **Start playing**. The score line on the finish screen counts every attempt ("<right> of <attempts> right").
- **Parent PIN on the lesson.** A **Parent** button on the lesson opens a PIN pad. The correct PIN gives an untimed, free session for that app.
- **Stats kept:** questions answered (total, today, and each of the last 7 days), questions correct, and a streak (consecutive days with at least one answer). These drive the Learning tab. On Android they stay on the device. The setup is restored on a new phone (§11), but progress starts over.
- **Videos must not play under the lesson.** If the gated app was already playing (e.g. YouTube resumed a video), it must be paused while the lesson is up. Pressing Home must not leave a video playing in picture-in-picture outside the lesson. *(Android 1.4.3 fixed exactly this.)*
- **A floating window must not lift the lock.** Opening a floating or side-bar app (e.g. ChatGPT) over a locked app must not drop the lesson while the locked app is still on screen. *(Android 1.4.4.)*
- **Number choices are shuffled every time a question is shown.** The authored lists are in ascending order, which put the right answer in the same slot nearly every time. Applies to every "pick a number" row in all four skills. *(Android 1.4.4.)*
- **Negative numbers are real answers.** The Reasoning stop "Below zero" has negative answers, and picking −19 must be submittable. *(Android 1.4.2 fixed a bug where it wasn't.)*

---

## 8. The lesson screen

Light background (`#F6F7FB`). Top to bottom: progress segments, then the content, then a pinned action bar. Reference: `CoderGate.kt`, `GateChrome.kt`.

### 8.1 Chrome
- **Top bar:** one rounded segment per item, filled purple as questions are answered **right** (a missed question fills its segment only once it is answered right), and a small **Parent** button on the right.
- **Bottom bar:** **Hint** (warm yellow face, gold ledge, light-bulb icon with "Hint") next to the main purple button. The main button reads **Check**, or **Run it** for build-a-program questions, and stays disabled until an answer is picked.

### 8.2 The question
- **Boss question:** a chip **BOSS QUESTION** (dark gold on cream) above the prompt.
- **Prompt:** the `focused` owl on the left with the prompt in a **white speech bubble** whose tail points at the owl (Duolingo style).
  - **Exception:** coding questions that show a board. There the owl is already on the board as the robot, so the prompt is plain bold text with no bubble.
- Then the picture, the answer row, and the small caption.

### 8.3 Hint (redesigned: this is the main fix)
- Tapping **Hint** opens a **card docked just above the bottom buttons**. It must **not** push the question down; the question and answers stay exactly where they were.
- The card: cream (`#FFF6DA`) with a 2pt yellow border and rounded corners. The `idea` owl on the left, a small bulb, the label **HINT** in dark gold, the hint text, and a ✕ on the right.
- Tapping the card, the ✕, or the Hint button again closes it, and it can be reopened. While it is open, the Hint button turns solid yellow and its bulb turns white.
- It closes on its own when the child answers. Opening it at least once counts as "hint used" for that question.

### 8.4 Clue and story card (replaces the yellow box)
- A white card with a 2pt light border and a small grey ledge.
- **Each sentence is its own numbered clue:** a small lilac circle with 1, 2, 3, then the text. A single sentence gets no number.
- **Every number in the text sits in a lilac pill** (`#EDE6FF` background, purple bold digits) with a little space on each side, so "Riya has 38 marbles. She gets 27 more." reads as two facts and two numbers. This also applies to "2nd", "9th", and negative numbers.
- **A final sentence ending in "?"** goes in its own band at the foot of the card: a light lilac background with a purple "?" badge and bold purple text, e.g. "How many now?".
- The words are exactly the question's `lines`. Only the presentation changes.

### 8.5 Verdict sheet
- A sheet slides up from the bottom over the buttons, with rounded top corners. Green wash if right, red wash if wrong.
- One row: a round badge (white tick or cross on green or red), then the title **Correct!** or **Not quite**, then the message, then the owl reacting (`cheer` or `shrug`) on the right.
- **Right:** a short praise line, e.g. "Sharp thinking." or "Spot on."
- **Wrong:** says **which answer was right**, in the question's own words: "The answer is −19." / "It was step 3." / "The answer is the cube." / "It is the 2nd one." Never just "wrong".
- On a wrong answer, a muted line under the message: **"You'll see this one again at the end."**
- The answer the child tapped is tinted green or red. Then **Continue** (green or red chunky button); on the last item it reads **Finish**.
- After a build-a-program question (which runs and locks the main button), the next screen's main button, including a **Got it** on a teach card, must be tappable again. *(Android 1.4.4 fixed a teach card left with a faded, dead "Got it".)*

### 8.6 Teach card ("New idea")
- A chip **NEW IDEA** with a small bulb (purple on light lilac). Below it, the stop title, large, with the `teacher` owl on the right. Then the teach line.
- Then the teach picture or demo. **There is no "Watch again" button anymore.** Anything animated **loops on its own**, with a short pause at the end:
  - the robot running the demo program
  - two programs running side by side
  - a TRUE/FALSE verdict landing
  - Number Sense pictures building up
- Still pictures (story cards, drawn clues) just sit there. If the teach picture still has its gap, the answer is shown under it ("Answer: …").
- Button: **Got it**.

### 8.7 Finish
- The `trophy` owl (or `cheer` if the stop isn't complete yet) inside falling confetti.
- **Stop complete** (or **Nice work**), then "<right> of <asked> right • <skill name>".
- A ticket in logo yellow: **+<minutes> min** with **of play unlocked**.
- Button **Start playing** (green).

---

## 9. Home: Learning tab

Lilac background. Reference: `roadmap_screen.dart`. Top to bottom:

1. **Greeting:** eyebrow **<SKILL NAME> · AGES <ages>**, title **"<child>'s path"**, and a streak pill on the right (flame and number; grey at 0).
2. **Up next card** (purple gradient on a deep-purple ledge, with the `teacher` owl in the corner):
   - A yellow chip **UP NEXT · UNIT n** (or **BOSS STOP**).
   - The current stop's title, large and white, then its teach line.
   - A progress bar with "done / 48".
   - When the course is finished: **SKILL COMPLETE**, "Every stop done", and the trophy owl.
   - Tapping the card opens the stop sheet.
3. **Three stat tiles:** **Today** (questions answered today), **This week** (sum of the last 7 days), and **Correct** (% overall, or "—").
4. **This week** chart: 7 bars from oldest to today. Each bar has its count above it. Today's bar is yellow and today's day letter sits in a dark chip.
5. **Play time** card, marked "View only": each gated app with its icon, "N questions for M min", and a pill: green **"N min left"** or lilac **"Lesson first"**.
6. **The path:**
   - **Section banners** in rotating colours (purple, teal, blue) with "SECTION n", the title, the subtitle, and a ring showing "done/12".
   - **Unit dividers:** "Unit n · title" between two lines.
   - **Stops** are chunky round nodes on a **winding trail**. The trail is solid in the section colour up to the current stop and dotted after it.
   - **Node states:**
     - done: section colour with a white tick (a trophy if it's a boss)
     - current: yellow with a dark star, a progress ring for how far into its questions the child is, and the title in a dark pill; the `focused` owl sits beside it
     - locked: white with a grey lock (a trophy outline if it's a boss)
   - Labels sit on a lilac pill so the trail passes behind them.
   - The path ends with the trophy owl and "The end of this skill".
7. **Stop sheet** (tap any node):
   - chips for state (Completed / Up next / Locked / Coming soon), BOSS, and UNIT n
   - the title, with a matching owl (`cheer` / `idea` / `focused`)
   - the teach line in a lilac box with a bulb
   - "N questions"
   - one line for the state: "Nupo asks this the next time an app opens." / "Done. It comes back later as a quick review." / "Unlocks once the stops before it are finished."
   - button **Got it**
8. If the skill is written for an older band than the child's, show a small cream note: "Written for ages X. Easier questions come first for now."
9. If Nupo is paused, a cream banner sits above the tabs: "Nupo is paused — apps open without a learning moment."

---

## 10. Home: Parent tab and bottom bar

**Bottom bar.** Two wide tabs, **Learning** (school icon) and **Parent** (shield-lock icon; an open lock once unlocked). The selected tab fills purple on a deep-purple ledge with white icon and label; the other is muted. Opening Parent asks for the PIN **once per visit**. Leaving the app forgets it and returns to Learning.

**Parent tab** (reference: `parent_home_screen.dart`):

1. **Greeting:** eyebrow **PARENT**, then **"Hi, <parent name>"** or **"Dashboard"**, and a yellow initial avatar.
2. **Permission alert** (only when something is off): a red card, **"A permission is off"** / "Lessons are not showing. Tap to fix."
3. **Status hero card:**
   - On: purple gradient, shield icon, **"Learning is on"** / "A lesson before N apps", and a switch with a yellow track.
   - Off: white card, pause icon, **"Nupo is paused"** / "Apps open with no lesson".
   - Inside: three numbers, **questions today**, **played today** (minutes), and **stops done**.
4. **Apps** header with a purple **+ Add** pill. One card per app:
   - real icon and name
   - a chip "N Q for M min"
   - a green "N min left" chip, or "No daily cap"
   - a ring of today's use against the daily cap, showing "used / cap m"; it turns red when the cap is reached
   - tapping a card opens that app's rules
5. **Nupo Pro card:**
   - Active: dark ink card with **NUPO PRO · ACTIVE** in yellow, **"Every skill, every day"**, "Manage subscription", and the `cool` owl. Tap opens subscription management.
   - Not active: yellow card with **NUPO PRO**, **"Try every skill free"**, "7 days free, cancel anytime", and the `star-student` owl. Tap opens the (closable) paywall.
6. **Learning** group (settings-style rows: a solid colour tile with a white glyph, then title, value, chevron):
   - Child: "<name>" / "Ages 5–6", "Ages 7–8", "Ages 9–10" or "Ages 11–12" (orange). Opens the child-age screen (§10.1).
   - Rules per app: count (blue)
   - Permissions: "All on" or "Fix" (green or red)
   - Parent PIN: •••• (purple)
7. **Account** group:
   - Signed in: shows the account email
   - Sign out
   - **Delete account**, alone in its own group, in red
8. **Confirm dialogs:** rounded cards with an owl (`shrug`, or `ohno` for delete), the title, a line, a chunky confirm button, and Cancel.
9. **Footer:** the waving owl and "Nupo · learning before play".

### 10.1 Child-age screen (from the Child row) *(Android 1.4.5)*

It must look like the story's age step (§3, screen 4), not a settings list. Reference: `age_band_screen.dart`.

- **Top:** only a white round back button (chevron). No title bar and no progress track.
- **The owl asks:** the `teacher` owl on the left and a speech bubble **"How old is <child>?"** ("your child" if no name is saved).
- **Four course cards** in a 2×2 grid, the same cards as the story: picture, age (**5–6, 7–8, 9–10, 11–12**) and course name. The child's current band is selected (purple border).
- **Status line** under the cards, centred and muted:
  - unchanged: **"<child> is learning <course name>."**
  - a different card picked: **"Lessons switch to <course name>."**
- **Button** (chunky, purple): **Done** when unchanged, **Switch course** when a different card is picked.
- **What saving does:**
  - saves the age band (a/b/c/d)
  - if the band changed, saves the age in years as the top of the band: 6, 8, 10 or 12
  - saves the course id for that band (`number_sense`, `puzzles_and_logic`, `think_like_a_coder`, `reasoning`)
  - the next lesson comes from the new course
  - the saved setup (§11) is updated
- **Labels everywhere** read "5–6, 7–8, 9–10, 11–12" (or "Ages …"). Nothing says "Age 11" or "11+" any more.

---

## 11. Saved setup and restore

The account document stores the setup so a reinstall or new phone restores it. Android writes these fields:

- `setup.childName`, `setup.owlName`, `setup.childAge` (years), `setup.ageBand` (a/b/c/d), `setup.subject` (curriculum id, e.g. `reasoning`), `setup.gatedApps`, `setup.appRules` ({app: {q, m, c}}), `setup.updatedAt`
- Plus `email`, `displayName`, `provider`, `lastActive`, `appVersion`, device model and OS version, `onboardingComplete`, `createdAt`

Not saved, by design: the parent PIN and the child's learning progress.

On restore, the parent signs in, the setup comes back, only the PIN and the permissions are asked again, and **Pro comes back automatically** because it follows the account.

---

## 12. Analytics events the new screens send

Event names and properties as Android sends them to the shared PostHog project. Full list and meanings: `ANALYTICS.md`. The ones the new screens need:

- **Story:**
  - `story_shown`
  - `story_started`
  - `story_app_picked {app}`
  - `story_answered {wrongs}`
  - `story_finished`
  - `story_login_tapped`
- **Setup:**
  - `onb_step {step_index, step_name}` with step names `child_name, owl_name, course, how_it_teaches, roadmap, app_picker, app_rules, pin, permissions_intro, …`
  - `apps_picked {count}`
  - `setup_complete`
  - `setup_restored`
- **Lesson:**
  - `lesson_shown {app, mode, target}`
  - `teach_shown {skill, stop}`
  - `hint_opened {skill, stop, shape}`
  - `question_answered {skill, stop, shape, boss, correct, hint_used, review, seconds}`
  - `lesson_session_done {skill, asked, correct}`
  - `stop_reached {skill, stop, position}`
  - `lesson_earned {app, minutes}`
  - `parent_override {app}`
  - `kid_active_day`
- **Install (once per install, Android):** `install_attributed {install_source, install_medium, install_campaign, install_content}`. The same four values are set **once** on the person (never overwritten). See §13.
- **Home:**
  - `home_shown {enabled}`
  - `home_tab {tab: roadmap|parent}`
  - `pin_unlock {ok}`
  - `protection_toggled {on}`
  - `settings_opened {what}`
  - `signed_out`
  - `account_deleted`
- **Every event carries `surface`:** `parent_app` or `kid_gate`.
- **Never send:** question text, the child's answer, names, or anything typed. Only ids, counts, and right/wrong. This is a child-directed app, and the privacy policy (nupo.app/privacy) promises exactly this.

---

## 13. Ad measurement: Facebook and Instagram ads for parents *(Android 1.4.4)*

Nupo is advertised **to parents** on Facebook and Instagram, and the ads send people straight to the store. The app **shows no ads**. This section describes what Android sends so the ads can be judged on installs, finished setups and subscriptions, and what it never sends. Reference: `lib/ad_attribution.dart` and the Meta block in `AndroidManifest.xml`.

### 13.1 The accounts (already set up, shared with iOS)

Parents see **Nupo**. Everything business-side and on invoices is **Internspirit Private Limited**.

| Thing | Value |
|---|---|
| Meta business portfolio | **Internspirit Private Limited** (ID 1653452276307120) |
| Meta app (developer app) | **Internspirit**, App ID **2159559387974262**, live, owned by the portfolio. Use case: "Create & manage app ads with Meta Ads Manager". |
| Platform registered on that Meta app | Android: Google Play, package `app.nupo.kid`. iOS is **not** registered yet. |
| Ad account | **Internspirit** (ID 1984569382232410), INR, Asia/Kolkata, owned by the portfolio and authorised on the Meta app |
| Identity in ads | Facebook Page **nupo**, Instagram **@nupo.app** (both owned by the portfolio) |
| Client token | Not in the repo. Android reads it from `android/meta.properties`, which is gitignored. Ask Vishnu for it. |
| RevenueCat → Meta | Set on the RevenueCat project (`7ec6caad`), not in app code. See §13.3. |
| Privacy URLs on the Meta app | nupo.app/privacy, nupo.app/terms, nupo.app/data-deletion |

**The iOS app must report into this same Meta app (2159559387974262)** so both platforms' installs and purchases land in one place and on one ad account. Do not create a second Meta app.

### 13.2 What Meta receives from the phone

| When | Meta event | Sent by |
|---|---|---|
| First open after install | install / app activation (Meta's automatic event) | Meta SDK, automatically |
| Every app open | app activation (automatic) | Meta SDK, automatically |
| Parent finishes setup (the Ready screen, same moment as `setup_complete`) | **CompleteRegistration**, with registration method `setup` | `AdAttribution.completedRegistration()` |

Rules:
- **Purchases are not sent from the phone.** RevenueCat sends them (§13.3). Sending them from the app too would count every purchase twice. Meta's "log in-app purchases automatically" option is **off** on the Meta app.
- **The advertising identifier is never collected.** On Android, the AD_ID permission is removed from the manifest, `com.facebook.sdk.AdvertiserIDCollectionEnabled` is false, and the app also turns collection off in code at start-up. Android matches an install to an ad tap through the **Google Play install referrer** instead.
- **The link to purchases.** At start-up, and again after every sign-in, the app reads Meta's **anonymous install id** from the Meta SDK and hands it to RevenueCat (RevenueCat's Facebook anonymous id attribute). This is how a subscription is tied back to the ad that brought the install.
- **Fail-safe.** With no Meta app id in the build, none of this runs and the app behaves exactly as before. Nothing here may block or crash the app.

### 13.3 What Meta receives from RevenueCat (server to server)

Configured on the RevenueCat project, using the **App Events API**, with Meta App ID 2159559387974262 and its client token. Sales are reported as **gross revenue**. Event mapping:

| RevenueCat event | Meta event |
|---|---|
| Trial Started | `StartTrial` |
| Trial Converted | `Subscribe` |
| Initial Purchase | `Subscribe` |
| Renewal | `Subscribe` |
| Non-Subscription Purchase | `fb_mobile_purchase` |

The sandbox App ID was removed on 6 Oct 2026, so **test purchases do not reach Meta**. Keep it that way, or test purchases will show up as ad results.

### 13.4 Which campaign brought the parent (our own analytics)

On the first start after install, Android reads the **Play install referrer once** and records:

- event `install_attributed` in PostHog, with `install_source`, `install_medium`, `install_campaign`, `install_content` (from the `utm_*` values; for Meta app-install ads, Meta's own referrer)
- `install_source` is `none` when there is no referrer, and `unknown` when there is one with no `utm_source`
- each value is cut to 100 characters
- the same four values are set **once** on the person, so a reinstall never overwrites the first campaign
- it is read only once per install; if reading fails, it is tried again on the next start

Every funnel and retention chart can then be split by campaign.

### 13.5 What must never reach Meta

The parent's name or email, the child's name or age, anything about lessons, questions or answers, and any advertising identifier. Meta gets only the events above, plus Meta's random app-scoped id and the basic technical details its SDK attaches (device model, OS version, app version, language, IP address).

### 13.6 Privacy documents (update before iOS sends anything to Meta)

Today the policy says Meta measurement happens **on Android only**:
- `legal/PRIVACY_POLICY.md` and nupo.app/privacy: the section "Measuring our own ads (Android)", and Meta listed as a processor with "(Android)"
- the line "Nupo contains no advertising identifier (IDFA or Android advertising ID) and no App Tracking Transparency prompt"

If iOS starts sending events to Meta, these must be changed first to cover iOS, and the iOS store's privacy declaration must match. What Android declares in Google Play's Data safety form (`legal/DATA_SAFETY.md`, "Meta ad measurement"):
- **App interactions:** shared with Meta (install, app open, setup completed), for Advertising or marketing and Analytics
- **Purchase history:** shared with Meta by RevenueCat (trial start, conversion, renewal, refund, amount, currency), for Advertising or marketing
- **Device or other IDs:** collected and shared (Meta's app-scoped anonymous id, **not** the advertising ID), for Advertising or marketing and Analytics

---

## 14. Store listing *(Android, live October 2026)*

The Play listing was rewritten around what makes Nupo different: **it blocks the apps a child already uses, teaches a short lesson first, and limits daily use.** It is not "another learning app". Files: `store_assets/`.

**Name:** Nupo: Kids Earn Screen Time

**Short line:** "A short lesson before YouTube and games. Screen time that teaches, ages 5-12."

**Full description:** `store_assets/listing_en.md`. Use it word for word, except the SETUP paragraph. That paragraph describes Android's two permissions (Usage access, Display over other apps) and must say whatever iOS actually asks for.

**Screenshots** (`store_assets/screenshots/`, 1080×1920), in this order. The order tells the story: block, earn, limit, control, then the course.

| # | File | Headline | Line under it | Shows |
|---|---|---|---|---|
| 1 | `01_steps_in.png` | Nupo steps in before games and videos | Their favourite apps, with a short lesson first | A home screen with a dashed arrow from the **YouTube** icon to a coding boss question ("Put the steps in order to get the star, then the flag."); tag "YouTube opens after this"; waving owl |
| 2 | `02_earn_time.png` | A short lesson earns play time | Finish the lesson and the app opens, on a timer | The finish screen (Stop complete, "+15 min of play unlocked", Start playing), then a YouTube-style kids video page with Nupo's countdown chip on top ("YouTube · 14:59 left"); tag "+15 min" |
| 3 | `03_daily_limit.png` | Then the daily limit says: done for today | Healthy limits on every app you choose | A home screen with the gated apps locked and the daily-limit card: trophy owl, "You are a star today!", "Great learning. See you tomorrow.", "60 of 60 min played today"; tag "Daily limit reached" |
| 4 | `04_you_choose.png` | You choose the apps and the minutes | Minutes per lesson, a daily limit, a parent PIN | The Parent tab (status card, app cards with usage rings, Pro card, Learning rows); tags "15 min per lesson", "1 hr a day", "Parent PIN" |
| 5 | `05_real_course.png` | Every lesson is a step in a real course | 48 lessons that build, written for their age | The Learning tab path: done, current (with owl) and locked stops, a section banner, a boss stop; tags "Up next", "Boss level" |
| 6 | `06_progress.png` | See what they learned today | Streaks, scores and what comes next | The top of the Learning tab: greeting and streak, Up next card, Today / This week / Correct tiles, week chart, Play time card; tag "6 day streak" |
| 7 | `07_hints_mistakes.png` | Hints when stuck, retries until right | Every question, finally answered right | Two lessons: a number question with the docked hint open, and a wrong-answer verdict ("Not quite", "You'll see this one again at the end."); tags "A nudge, not the answer", "Asked again at the end" |
| 8 | `08_ages.png` | A course for every age, 5 to 12 | Numbers, logic, coding and reasoning | Four course cards: AGES 5-6 Number Sense, AGES 7-8 Puzzles & Logic, AGES 9-10 Coding, AGES 11-12 Reasoning, each with a small picture |

These show Android phone screens. iOS needs the same eight slides, in the same order and with the same words, at the sizes its store asks for.

**Feature graphic** (`feature_graphic.png`, 1024×500, Play only): "A lesson first. **Then play.**" / "Screen time that teaches kids 5 to 12", chips "Real courses" and "Daily limits", a home screen with an arrow from YouTube to a coding boss question, and the waving owl. There is **no "No ads" claim**; don't add one to any store art.

---

## 15. Acceptance checklist

- [ ] The story's 10 screens match §3, and the demo for each band equals §4 exactly.
- [ ] Setup steps and copy match §5, including the trade arithmetic.
- [ ] All four JSON skills are bundled unchanged. The right skill is served per band. All 324 questions per skill render and grade against the stored answer.
- [ ] Lesson rules in §7 hold: one stop per lesson, teach card shown once, one review first, cursor moves once per question, a wrong question comes back at the end until it is right, minutes earned when every question is right, shuffled number choices, PIN override.
- [ ] A floating window over a locked app does not lift the lock. "Got it" is tappable after a build-a-program question.
- [ ] The hint is docked and never moves the question. The verdict names the right answer. The teach demo loops with no "Watch again". Clue cards use the new design.
- [ ] Negative answers submit. Video stays paused under the lesson, with no picture-in-picture escape.
- [ ] The Learning and Parent tabs match §9–§10, including streak, week chart, path states, Pro card states, and the email in "Signed in".
- [ ] The saved setup uses §11's fields, and restore brings back the setup and Pro.
- [ ] The §12 events fire with these names and properties.
- [ ] The child-age screen matches §10.1, and every age label reads 5–6 / 7–8 / 9–10 / 11–12.
- [ ] Ad measurement matches §13: the same Meta app, the events Meta receives, nothing from the "never sent" list, and the privacy documents updated before release.
- [ ] The store listing matches §14.
