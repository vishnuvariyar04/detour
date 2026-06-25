# BrainPass (Kids)

Kids earn their game and video time by solving a few quick problems first.
Android-only, parent-controlled, **100% on-device — collects and transmits
nothing**.

> New to Flutter? Read **[SETUP_AND_TESTING.md](SETUP_AND_TESTING.md)** — it
> walks you through running and testing this on a real Android phone from zero.

## What it does
A parent installs it on the child's phone, sets a PIN, picks an age band, chooses
which apps to gate, and sets an exchange rate (e.g. *3 correct answers = 15
minutes*). When the child opens a gated app, a full-screen card of
age-appropriate questions appears. Answer enough and the app unlocks for the
earned time; when it expires, it re-locks.

## Quick start
```powershell
cd C:\dev\detour\brainpass
flutter devices          # confirm your phone is connected
flutter run              # build + launch on the phone
```

## How it's built
- **Dart/Flutter** app; two entry points (`main()` parent app, `overlayMain()`
  kid card) sharing state only through on-device `SharedPreferences`.
- **Detection:** `flutter_accessibility_service` sees which app is foreground;
  `flutter_foreground_task` keeps it alive; `flutter_overlay_window` draws the
  earn card over the gated app.
- **Questions:** math + number-pattern generators and a per-age general-knowledge
  bank, all compiled in (`lib/questions.dart`).
- **Safety:** dialer / messaging / contacts / clock / settings can never be
  gated (`lib/safe_apps.dart`); the parent PIN is always an instant bypass.

## Privacy
No accounts, no cloud, no ads, no analytics, no internet permission. See
[PRIVACY_POLICY.md](PRIVACY_POLICY.md). Built per the compliance architecture in
`../brainpass_kids_build_spec.md` §4.

## Project map
See SETUP_AND_TESTING.md §3 for a file-by-file tour.
