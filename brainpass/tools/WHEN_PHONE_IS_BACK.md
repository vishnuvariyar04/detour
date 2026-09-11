# Device checks queued while the phone was away

Everything below compiles and passes every check that can run without hardware.
None of it has been seen on a real screen. Work top to bottom — the later
checks assume the earlier ones passed.

## 0. Setup

```bash
cd brainpass
flutter build apk --debug
ADB=$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe
"$ADB" install -r build/app/outputs/flutter-apk/app-debug.apk
```

HyperOS drops the overlay permission on every reinstall, so the gate silently
never appears until this is re-granted. `tools/reset_progress.sh` does it.

## 1. The new drawings, on a real screen

```bash
"$ADB" shell am start -n app.nupo.kid/com.brainpass.brainpass.NumberPreviewActivity
```

Sixteen cards, replaying every 2.6s. What to look for:

- **rocket** and **tree** are brand new and have never been drawn. They are the
  figures that make "tap every triangle" a real question rather than "tap
  everything", so if they are misshapen the whole shape-hunt unit is affected.
- Does anything overflow its card at this screen size?
- Are the yellow counters readable on white? Yellow-on-white is the weakest
  contrast pair in the palette and it is used for the second colour everywhere.

## 2. Number Sense in the actual gate

The gate serves the most advanced skill the child's band allows, so a band-c
child gets the coder skill. To see Number Sense, put the device on band b:

```bash
"$ADB" shell am force-stop app.nupo.kid
"$ADB" shell "run-as app.nupo.kid sed -i \
  's|<string name=\"ageBand\">c</string>|<string name=\"ageBand\">b</string>|' \
  /data/data/app.nupo.kid/shared_prefs/brainpass_engine.xml"
bash tools/reset_progress.sh
```

Then open a gated app. **Put the band back to `c` afterwards** — that is the
real child's setting.

This is the first time any Number Sense question renders inside the gate, under
a prompt, a Check button and the board-grow pass. Expect layout problems here
rather than in the gallery: the gallery gives each drawing a whole card, the
gate does not.

## 3. Tap through the whole skill

```bash
cd tools/e2e
python drive.py 15 number_sense     # smoke test first
python drive.py 0 number_sense      # then all 324
```

The driver knows every new shape and a dry run confirms each of the 324 has a
tappable target, but **the geometry has never been read from a live gate**. The
multi-tap shapes are the risky ones — shape hunts, sorting, ordering and
mirrors all tap several targets in sequence, and nothing has confirmed the gate
reports `part0..n`, `item0..n`, `size0..n` and `mc<c>_<r>` at the right places.

Re-run the coder skill too, since the gate changed underneath it:

```bash
python drive.py 0
```

## 4. Watch one animation actually play

`screencap` takes about a second, so it cannot catch a 400ms animation — every
screenshot shows the settled state. Use video:

```bash
"$ADB" shell screenrecord --time-limit 6 /sdcard/a.mp4
"$ADB" pull /sdcard/a.mp4 . && ffmpeg -i a.mp4 -vf fps=20 f%03d.png
```

The number-line hop is the one worth confirming: the marker must pass through
every whole number, not slide to the answer. Counting on is a movement, and the
hop is the teaching.

## Known gaps, not yet addressed

- **Finishing a skill still falls back to the old random questions.** Running
  past the last stop leaves `stopIndex` one past the end and the gate quietly
  serves `Questions` instead. Flagged earlier; still open.
- **Number Sense teach cards have a line but no demo.** The coder skill plays a
  worked example before each stop; these just show the sentence. The pictures to
  build one from now exist.
- **No parent-facing copy** for the new skill beyond its promise line.
