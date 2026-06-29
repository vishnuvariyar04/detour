# Nupo — Version 1 (complete reference)

> **Status:** v1, working and device-verified (Xiaomi Redmi/POCO, HyperOS, Android 16).
> **App name:** **Nupo** · **applicationId:** `app.nupo.kids` · **code namespace:** `com.brainpass.brainpass` (internal only).
> **Platform:** Android only. **Framework:** Flutter (Dart) parent UI + a native Kotlin engine.
> **Promise:** A child earns time on chosen apps by answering quick questions. 100% on-device, zero data collection, no accounts, no ads.
> **Project root:** `c:\dev\detour\brainpass` (folder still named `brainpass`; the product is Nupo).

This is the full reference: concept, exact runtime behavior, architecture and *why*, every source file, data model, permissions, the onboarding flow, reliability design, build/signing/test workflow, bugs fixed, and known limits. (History note: the engine was rewritten twice — accessibility → UsageStats, and Activity-lock → native overlay-lock — see §14.)

---

## 1. What it does (the concept)

A parent installs Nupo on the child's phone, sets a 4-digit PIN, picks which apps to "gate," and sets a **per-app rule**. When the child opens a gated app, a full-screen card of age-appropriate questions appears. Answer enough and the app unlocks for a number of minutes; while the app is on screen a small countdown ticks down; when it runs out the app closes. To get back in, the child opens the app again and answers a fresh set.

**Each gated app is fully independent** — its own questions count, minutes, optional daily cap, and timer. Nothing is shared across apps.

---

## 2. The exact runtime lifecycle

1. **Open a gated app with no time left** → full-screen **lock** appears with questions ("entry lock").
2. **Answer the required number of questions** (wrong answers are gentle: reveal the correct answer, serve a new question, never lock out, never lose a star) → the app's minute block is granted and the lock closes, returning to the app.
3. **While the app is on screen**, a floating **countdown chip** shows at top, e.g. `Instagram   1:48 left   •   11 min used`, ticking each second. Time is consumed **only while that app is in the foreground**.
4. **Switch away** → the timer **pauses**. Come back → it **resumes** where it left off.
5. **Time runs out while in the app** → the app **closes to home**. **No questions at this moment.**
6. **Open the app again** → entry lock (questions) again. Cycle repeats forever.
7. **Daily cap reached** (if set) → on next open, **"All done for today"** instead of questions; only the parent PIN overrides. Resets at local midnight.
8. **Parent PIN** is an instant bypass on any lock (emergency/override) and grants a block even past the cap.

> Design rule: **questions appear on ENTRY only.** Running out of time just closes the app.

---

## 3. Architecture overview

```
┌──────────────────────────────┐        ┌───────────────────────────────────┐
│  FLUTTER (Dart) — PARENT UI  │        │  NATIVE (Kotlin) — THE ENGINE     │
│  • onboarding wizard         │ Method │  • GuardService (foreground svc)  │
│  • PIN create/entry/change   │ Channel│     – polls UsageStats 1×/sec     │
│  • age band, app picker,     │◄──────►│     – per-app active-time on disk │
│    per-app rules, dashboard  │ brain  │     – draws countdown chip        │
│  • "keep it running" guide   │ pass/  │     – shows the native LOCK (LockUi)│
│  • pause toggle              │ engine │  • EnginePrefs (native storage)   │
│  (NO kid lock UI in Flutter) │        │  • Questions/Gk (native generators)│
│                              │        │  • WatchdogReceiver (self-heal)   │
│                              │        │  • BootReceiver, Autostart helper │
└──────────────────────────────┘        └───────────────────────────────────┘
        │ shared_preferences                        │ SharedPreferences "brainpass_engine"
        ▼ FlutterSharedPreferences.xml              ▼ gated set, per-app config + counters
   PIN hash, age band, gated apps, rules      (pushed down from Flutter via MethodChannel)
```

- **The kid-facing lock is 100% native** (`GuardService` + `LockUi`). Flutter has **no** kid UI — only parent setup/dashboard.
- **Detection + enforcement run entirely in native Kotlin**, independent of the Flutter UI being alive.
- Flutter **pushes config down** (rules, age band, PIN hash, master switch) over the `brainpass/engine` MethodChannel; native owns the live counters and reads them back for the dashboard.

### Why this architecture (two hard-won decisions)
1. **UsageStats polling, not an Accessibility Service.** Xiaomi/HyperOS silently *disables* accessibility services (killed all gating). Usage Access is a query permission the OS won't silently revoke. Polled 1×/sec inside the foreground service.
2. **The lock is a native overlay, not a launched Activity.** Many OEMs (MIUI's "display pop-up while running in background") block background Activity starts, so a launched lock didn't appear. An overlay only needs "Draw over other apps" (universal) → the lock shows on every phone. Questions are therefore rendered **natively** (see `LockUi.kt`).

---

## 4. The native engine (Kotlin) — `android/app/src/main/kotlin/com/brainpass/brainpass/`

### 4.1 `GuardService.kt` — the heart
A foreground `Service` (`START_STICKY`, `stopWithTask="false"`). 
- **Detection:** a 1-second tick loop (only while screen on — a `SCREEN_ON/OFF` receiver starts/stops it). Each tick reads the current foreground app via `UsageStatsManager.queryEvents` (with a persisted `lastFg` so it doesn't lose the app after the query window — that was a "countdown froze after 10s" bug).
- **Per-app active-time:** each tick books elapsed time straight to disk (`EnginePrefs.consume`), so a process kill/restart resumes exactly (restart-safe).
- **Countdown chip:** a small `WindowManager` overlay (`TYPE_APPLICATION_OVERLAY`, not focusable/touchable) showing "App • m:ss left • n min used".
- **Lock decision:** gated app with cap reached → `LockUi` "done"; no time → `LockUi` "earn"; has time → count down; hits 0 → go **home** (no questions).
- **The lock** (`showLock`) builds a full-screen `LockUi` overlay (focusable-but-not-key-grabbing, opaque, **forced portrait** so the keypad always fits) — see 4.4. On success it calls `EnginePrefs.addEarned`; parent PIN → `addOverride`; then removes the overlay.
- **Self-heal:** schedules the `WatchdogReceiver`; restarts on `onTaskRemoved`. Every OS call is wrapped in try/catch so a failure can't crash (and kill) the service.
- **Notification:** white status-bar icon (`R.drawable.ic_stat_nupo`) + the colour owl as the large icon (read from the bundled Flutter asset `flutter_assets/assets/icon/nupo.png`).

### 4.2 `EnginePrefs.kt` — native on-device state (`brainpass_engine` prefs)
Per app: `q_`, `min_`, `cap_`, `name_` (config) and `rem_`, `used_`, `capx_` (runtime, reset at midnight). Global: `gatedApps`, `masterEnabled`, `dayStamp`, plus parent `ageBand` and `pinHash`/`pinSalt`. Key methods: `setRules` (writes config, sets the gated set, **prunes** keys for apps no longer gated), `addEarned`/`addOverride`, `consume`, `capReached`, `effectiveBudget`, `clearBudgets` (so a changed rule applies immediately), `rollDayIfNeeded`, `verifyPin` (salted SHA-256, matches the Dart format).

### 4.3 `Questions.kt` / `Gk` — native question engine
Kotlin port of the math + number-pattern generators and the per-band general-knowledge bank (mirrors `lib/questions.dart`). The native lock generates its own questions; the Dart copy is only used by the unit test.

### 4.4 `LockUi.kt` — the kid-facing lock, rendered as native views
Builds the overlay view: star progress, big question card, numeric keypad (math/pattern) or three option buttons (GK), gentle wrong-answer handling, a discreet "Parent" PIN bypass (native 4-digit pad → `EnginePrefs.verifyPin` → override), and the "all done for today" screen. Callbacks (`onEarned`, `onOverride`) are wired by `GuardService`.

### 4.5 `MainActivity.kt` — Flutter host + bridge
Starts `GuardService` and hosts the `brainpass/engine` MethodChannel: `setRules`, `setMasterEnabled`, `setAgeBand`, `setPin`, `clearBudgets`, `appStatus`, `startGuard`, permission checks/opens (`hasUsageAccess`/`openUsageAccessSettings` [best-effort package target], `canDrawOverlays`/`requestOverlay`, `isIgnoringBattery`/`requestIgnoreBattery`), and `autostartRelevant`/`openAutostartSettings`.

### 4.6 Reliability components
- **`WatchdogReceiver.kt`** — an AlarmManager alarm (~every 3 min, re-armed each fire) that restarts the guard if killed and, if a required permission is missing, posts a visible **"Nupo is not protecting — tap to fix"** notification (never fails silently).
- **`BootReceiver.kt`** — restarts the guard + watchdog after reboot / app update.
- **`Autostart.kt`** — deep-links to the OEM Autostart page (Xiaomi/Oppo/Vivo/Huawei/…); `isRelevant()` detects whether to show the step.

---

## 5. The Flutter app (Dart) — `lib/`

| File | Purpose |
|---|---|
| `main.dart` | Boot, `syncToEngine()` (push config + start guard), routing, the **onboarding wizard**, and the post-setup **landing** (active/paused). |
| `engine.dart` | Dart wrapper around the `brainpass/engine` MethodChannel + `AppStatus` model. |
| `storage.dart` | Parent config in `shared_preferences`: PIN hash/salt, age band, gated apps, **per-app `AppRule{questions,minutes,cap}`** (JSON), master switch, onboarding flag. `rulesForEngine()` builds the native payload (incl. display names). |
| `pin.dart` | Salted SHA-256 PIN; `setPin` also pushes the hash to native. |
| `questions.dart` | The generators/GK (now mainly for the unit test; the live lock is native). |
| `safe_apps.dart` | Preset gateable apps + the never-gate safety lists + `displayNameFor`. |
| `theme.dart`, `widgets.dart` | Theme + shared widgets (`StepScaffold`, `SelectCard`, `IntStepper`). |
| `screens/intro_screen.dart` | Welcome + **owl logo header** + privacy promise. |
| `screens/permission_step.dart` | **Reusable one-permission-per-screen** wizard step: big emoji, short copy, auto-detect + **auto-advance** on return, "find this" preview card, progress dots. |
| `screens/keep_running_screen.dart` | Reliability step / settings page (Autostart deep-link + battery), used from the dashboard. |
| `screens/permissions_screen.dart` | Permissions status list (used from the dashboard for re-checking). |
| `screens/pin_create_screen.dart` | Create / **change** PIN. |
| `screens/pin_entry_screen.dart` | Enter PIN to reach the dashboard + **"Forgot PIN?"** reset info. |
| `screens/age_band_screen.dart` | Age band (5–7 / 8–10 / 11–13); pushes to native. |
| `screens/app_picker_screen.dart` | Pick gated apps (presets + installed via `installed_apps`), §13 safety filter. |
| `screens/app_rules_screen.dart` | Per-app rules editor (questions / minutes / daily cap). |
| `screens/parent_home_screen.dart` | PIN-protected dashboard: status banner, master on/off, **live per-app usage**, edit rules/apps/band/permissions/keep-running/**change PIN**. |

### Onboarding wizard (the current flow)
`Welcome (logo) → Create PIN → [Show the lock] → [Know what's open] → [Don't fall asleep] → [Auto-restart*] → Age band → Pick apps → Per-app rules → Done (landing)`
The four permission steps use `PermissionStepScreen`: each opens the right system screen, then **auto-advances when the permission is detected on return** (no "Continue"/"I did it" taps). Autostart (`*` only on Xiaomi/etc.) can't be read, so it advances optimistically on return. Each `PermissionStepScreen` has a **unique key** (otherwise Flutter reused State across the same-typed screens — a fixed bug).

---

## 6. Per-app rules & data model
Flutter `AppRule{questions(1–10, def 3), minutes(1–60, def 15), cap(daily mins, 0=none)}` per package, pushed to native as `{package,name,questions,minutes,cap}`. Native owns `rem_`/`used_` per app. Each earn adds `minutes×60000` ms to `rem`; the guard consumes `rem` only while foreground; `effectiveBudget = min(rem, cap−used)` enforces the cap.

---

## 7. Question content
Compiled in (no network): **math** (per band), **number patterns**, **general knowledge** MCQs (~12/band, shuffled options). An "earn plan" mixes mostly math/pattern with GK sprinkled. Wrong answers reveal the answer and serve a new question — never penalize.

---

## 8. Permissions (and only these)

| Permission | Why | UX |
|---|---|---|
| **Usage access** (`PACKAGE_USAGE_STATS`) | Detect the foreground app (poll) | List + "find this" card; auto-detected |
| **Draw over other apps** (`SYSTEM_ALERT_WINDOW`) | Draw the chip + the lock overlay | Opens on Nupo's toggle; auto-detected |
| **Battery exemption** (`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`) | Keep the guard alive | One-tap system dialog; auto-detected |
| **Foreground service** (`FOREGROUND_SERVICE` + `_SPECIAL_USE`, `POST_NOTIFICATIONS`) | Run the guard + its notification | — |
| **Autostart** (Xiaomi/etc., no Android API) | Allow background run/restart | Deep-linked; **can't be read** → optimistic |
| **Query all packages** (`QUERY_ALL_PACKAGES`) | List installed apps in the picker | — |
| `RECEIVE_BOOT_COMPLETED` | Restart guard after reboot | — |

**No INTERNET permission** — the app cannot transmit anything. No camera/mic/location/contacts. No analytics/ads/crash SDKs.

---

## 9. Safety rules (non-negotiable)
The picker can **never** gate the dialer, SMS/messaging, contacts, clock/alarm, settings, or Nupo itself (`safe_apps.dart`). The parent PIN is always an instant bypass.

---

## 10. Privacy / compliance
Everything stays on the device; nothing collected or transmitted. See `PRIVACY_POLICY.md`. Get real legal review + complete Play's Families/Data-safety before scaling.

---

## 11. App icon & branding
`assets/icon/nupo.png` (purple owl on yellow `#FDC703` rounded square). `flutter_launcher_icons` generates all launcher densities + the adaptive icon (yellow background). The same asset is the **onboarding header** and the **notification large icon**; the status-bar small icon is the white vector `res/drawable/ic_stat_nupo.xml`.

---

## 12. Build, signing & dependencies
- **Flutter** 3.44.3 (Dart 3.12.2) at `C:\dev\flutter`; JDK: `flutter config --jdk-dir "C:\Program Files\Java\jdk-19"` (Android Studio's bundled JBR is JDK 11 — too old).
- **minSdk 24**; target/compile per Flutter (36).
- **Release signing:** `android/key.properties` (gitignored) + a keystore; `build.gradle.kts` uses the release key when present, else debug. `applicationId = app.nupo.kids`.
- **Dart deps:** `shared_preferences`, `crypto`, `installed_apps`, `cupertino_icons`; dev: `flutter_launcher_icons`. (The old accessibility/overlay/foreground plugins were removed — all native now.)
- Build: `flutter build apk --release` → `build\app\outputs\flutter-apk\app-release.apk`. Generate icons: `dart run flutter_launcher_icons`. (Transient "Unable to determine engine version" → `flutter clean` + retry.)

---

## 13. Install & test workflow (HyperOS)
`adb` at `%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe`.
- **First install of a new package is blocked** by MIUI ("Install via USB" / `INSTALL_FAILED_USER_RESTRICTED`) → install from the phone's **Downloads** (`Nupo.apk`, tap → "Install anyway"). **Updates** to an already-installed package work via `adb install -r` *only if signatures match* (release-vs-debug mismatch otherwise).
- Grant via adb for testing: `appops set app.nupo.kids GET_USAGE_STATS allow`, `appops set app.nupo.kids SYSTEM_ALERT_WINDOW allow`, `dumpsys deviceidle whitelist +app.nupo.kids`.
- Fresh onboarding without uninstalling: `adb shell pm clear app.nupo.kids`.
- Inspect engine: `adb shell run-as app.nupo.kids cat /data/data/app.nupo.kids/shared_prefs/brainpass_engine.xml`.
- Logs: `adb logcat -s NupoGuard NupoWatchdog`.
- Device-verified in v1: detection, native lock renders + answers register + stars advance, countdown at 1× rate, time-up→home, watchdog alarm scheduled, Autostart deep-link opens, launcher icon applied.

---

## 14. Bugs fixed (do not regress)
1. **Accessibility disabled by HyperOS** → UsageStats polling in a foreground service.
2. **Countdown froze after ~10s** (fixed-window usage query returned null) → persist `lastFg`.
3. **Timer lost/drifted on process restart** → book time incrementally to disk.
4. **Service crash killed all gating after first lock** → wrap every OS call in try/catch.
5. **Changing a rule didn't apply** (old `rem` masked it) → `clearBudgets` on save.
6. **Questions at time-up + pre-granting next block** → time-up just goes home; questions on next open.
7. **Lock didn't show / showed late on other phones** (background Activity-launch blocked) → render the lock as a **native overlay** (no Activity).
8. **Detection died after first cycle / on background-kill** → watchdog + boot receiver + `onTaskRemoved` restart + health-monitor notification.
9. **Onboarding screen 2 showed "Done" with no button** (Flutter reused State across same-typed screens) → unique keys per permission step.
10. **Parent PIN pad missing its first column** (mismatched grid cell params) → uniform weighted cells.
11. **Landing always said "active" when paused** → reflect the master switch.

---

## 15. Known limits (honest)
- **~1s detection latency** (poll) before the lock appears.
- **Usage access + Autostart can only open a list** — Android/Xiaomi won't let an app pre-flip them; mitigated by auto-advance + the "find this" card.
- **Background survival on Xiaomi needs Autostart + battery-unrestricted** (+ "Pause app activity if unused" turned off, + locking in recents). The watchdog + health-monitor recover/alert, but a force-killed app with Autostart off can have a gap until the watchdog fires.
- **Determined older kids** can disable Usage access or clear data; v1 targets ages 5–10 and relies on the PIN.
- **Android only.** No iOS.

---

## 16. Next ideas (not in v1)
Active-use vs wall-clock toggle (already active-use), reward/streak layer, difficulty escalation, parent-authored questions, richer question types, two-device parent dashboard (⚠️ adds data transmission), multiple child profiles, iOS.

---

## 17. Companion docs
`README.md` (overview/quick start), `SETUP_AND_TESTING.md` (beginner setup/testing), `PRIVACY_POLICY.md` (we-collect-nothing), `../brainpass_kids_build_spec.md` (original spec).

---

_v1 — Nupo: native UsageStats engine + native overlay lock, per-app active-time gating, self-healing reliability, guided one-tap-style onboarding, owl branding. Device-verified._
