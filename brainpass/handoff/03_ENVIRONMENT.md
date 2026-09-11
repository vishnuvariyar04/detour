# Environment and daily commands

What the machine needs, and the handful of commands you will actually type.

`brainpass/SETUP_AND_TESTING.md` is the older guide and is **out of date** — it
describes a Dart overlay that no longer exists. Its section on why a real phone
is required is still correct and worth reading; ignore its file layout.

## What you need

| Tool | Version here | Why |
|---|---|---|
| Flutter | 3.44.3 stable (Dart 3.12.2) | builds the APK; the parent screens are Flutter |
| JDK | 19, at `C:\Program Files\Java\jdk-19` | Gradle and the Kotlin unit tests |
| Android SDK | platform-tools on PATH as `adb` | installing and driving the phone |
| Python | 3.12 | the entire authoring and checking toolchain |
| Pillow | 12.x | `build_wall.py` shrinks the mascot for the review page |
| ffmpeg | any | only for catching animations on video |

If Flutter cannot find the JDK:

```bash
flutter config --jdk-dir "C:\Program Files\Java\jdk-19"
```

`adb` lives at `$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe`. Most scripts
here expect that path; `reset_progress.sh` takes an `ADB` override.

## You need a real Android phone

Three things the gate depends on are Android OS features that do not exist on
Windows and barely work on an emulator:

1. **Accessibility service** — notices which app opened
2. **Overlay window** — draws the card over that app
3. **Foreground service** — keeps it alive in the background

Parent screens run on an emulator. The gate does not. The test device is a
HyperOS (Xiaomi) phone, and HyperOS has its own traps — see below.

## The app

- Package `app.nupo.kid`, `minSdk 24`
- The gate: `GuardService.kt` detects the app → `LockUi.kt` puts up the card →
  `CoderGate.kt` runs the curriculum questions inside it
- Progress lives in `nupo_progress.xml`, separate from anything Flutter stores,
  and in a **different process** from the Flutter UI

## Daily commands

### Author and check

```bash
cd brainpass/tools/curriculum

# coder skill
python emit_json.py && python simulate.py && python fits.py

# number sense
python figures.py && python ns_emit.py && python ns_simulate.py && python ns_grade.py
```

`fits.py` is red today (one label clips) — see the build guide. Everything else
is green; keep it that way.

### Build the review wall

```bash
cd brainpass/tools/curriculum
python build_wall.py
```

Writes `brainpass/build/wall/question_wall.html`. Open it in a browser. The copy
in `handoff/` is a snapshot from 2026-09-12 — rebuild rather than trusting it
once you have changed any content.

### The JVM answer gate

```bash
cd brainpass/android
./gradlew :app:testDebugUnitTest
```

Re-derives every answer using the same simulator that grades the child. If
Gradle reports `UP-TO-DATE`, it did **not** run — add `--rerun-tasks` when you
need to be sure. Results land in
`build/app/test-results/testDebugUnitTest/`.

### Install on the phone

```bash
cd brainpass
flutter build apk --debug
ADB=$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe
"$ADB" install -r build/app/outputs/flutter-apk/app-debug.apk
bash tools/reset_progress.sh
```

### See the drawings on their own

```bash
"$ADB" shell am start -n app.nupo.kid/com.brainpass.brainpass.NumberPreviewActivity
```

A gallery of every drawing, replaying every 2.6s. Fastest way to check a new
view before wiring it into the gate.

### Drive the whole skill

```bash
cd brainpass/tools/e2e
python drive.py 15 number_sense    # smoke test
python drive.py 0  number_sense    # all 324
```

## HyperOS traps

These have each cost a day before.

**The overlay permission is revoked on every reinstall.** The gate then silently
never appears — no error, no log, nothing. `tools/reset_progress.sh` re-grants
it along with usage access:

```bash
adb shell appops set app.nupo.kid SYSTEM_ALERT_WINDOW allow
adb shell appops set app.nupo.kid GET_USAGE_STATS allow
```

**The gate will not fire while the child still has earned minutes.** Clearing
progress alone is not enough; `reset_progress.sh` clears the minutes too.

**The gate serves the skill for the device's band**, not the one you are working
on. To see a band-b skill you must set the device to band b — the command is in
the build guide, step 4. Put it back to `c` afterwards; that is the real child's
setting.

**Screenshots cannot catch animations.** `screencap` takes about a second, so
every screenshot shows the settled state. Use `screenrecord` and pull frames.

## Git

Work on a branch off `codex-ui`. The curriculum JSON is generated — always
commit the Python that produced it in the same commit, or the next person
regenerates it and gets a different file.

Do not commit: `build/`, `__pycache__/`, `tools/e2e/failures/`, `.pyc`, `.log`.
The gitignore already covers these; check `git status` before committing anyway,
because `tools/e2e/shots/` is tracked and it is easy to add megabytes of PNGs
without noticing.
