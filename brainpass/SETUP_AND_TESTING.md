# BrainPass — Setup & Testing Guide (for someone new to Flutter)

This guide assumes you have **never used Flutter**. It explains what was built,
how to run it on your Android phone, and how to test the "earn your screen time"
gate. Read top to bottom the first time.

---

## 1. What is this, in plain terms

- **Flutter** is a toolkit for building phone apps. You write code in a language
  called **Dart**, and Flutter turns it into a real Android app.
- The Flutter SDK was installed to **`C:\dev\flutter`** and added to your PATH,
  so the `flutter` command works in any terminal.
- Your app lives in **`C:\dev\detour\brainpass`**.

### The app, in one sentence
When your child opens a "gated" app (e.g. YouTube), BrainPass covers the screen
with a card of quick questions; answer enough and the app unlocks for a set
number of minutes, then re-locks.

---

## 2. Why you NEED a real Android phone (not just the PC)

Three of this app's powers are Android operating-system features that **do not
exist on Windows and barely work on emulators**:

1. **Accessibility Service** – notices which app opened.
2. **Overlay window** – draws the lock card over other apps.
3. **Foreground service** – keeps it alive in the background.

You can run the *parent setup screens* on an emulator, but to truly test the
gate you must use a **real phone**. That's the plan here.

---

## 3. Project layout (what each file does)

```
brainpass/
├─ lib/                         ← all the Dart code (the app itself)
│  ├─ main.dart                 ← starts the app + the overlay entry point
│  ├─ questions.dart            ← math/pattern generators + general-knowledge bank
│  ├─ storage.dart              ← saves settings on the device (nothing leaves it)
│  ├─ pin.dart                  ← parent PIN, stored as a salted hash
│  ├─ safe_apps.dart            ← preset apps + the "never gate dialer/SMS" safety rule
│  ├─ theme.dart                ← colors / styling
│  ├─ widgets.dart              ← small reusable UI pieces
│  ├─ services/
│  │  └─ detection_service.dart ← the engine: detect gated app → show overlay
│  ├─ overlay/
│  │  └─ earn_card.dart         ← the kid-facing question card (the heart)
│  └─ screens/                  ← parent setup + home screens
├─ android/                     ← the native Android wrapper (permissions, services)
│  └─ app/src/main/AndroidManifest.xml   ← declares permissions + the 3 services
├─ test/                        ← automated tests for the question logic
├─ pubspec.yaml                 ← the list of plugins this app uses
├─ PRIVACY_POLICY.md            ← the "we collect nothing" policy
└─ SETUP_AND_TESTING.md         ← this file
```

---

## 4. Get your phone ready (one time, ~3 minutes)

You need to turn on "Developer Mode" so the phone will accept the app from your
PC over USB.

1. On the phone: **Settings → About phone**.
2. Find **Build number** (sometimes under "Software information").
3. **Tap "Build number" 7 times.** It will say "You are now a developer!"
4. Go back to **Settings → System → Developer options**.
5. Turn on **USB debugging**.
6. Plug the phone into the PC with a USB cable.
7. On the phone, a popup asks **"Allow USB debugging?"** → tap **Allow**
   (tick "always allow from this computer").

### Confirm the PC sees the phone
In a terminal:
```powershell
flutter devices
```
You should see your phone listed (e.g. `SM-G991B (mobile) • android-arm64`).
If it doesn't show up, see **Troubleshooting → Phone not detected** below.

---

## 5. Run the app on the phone

From the project folder:
```powershell
cd C:\dev\detour\brainpass
flutter run
```
The first run takes a few minutes (it compiles everything). When it's done, the
app opens on your phone and the terminal stays "live".

### The magic keys while `flutter run` is active
- Press **`r`** = **hot reload** (apply code changes in ~1 second, keeping your
  place in the app). This is Flutter's superpower.
- Press **`R`** = **hot restart** (restart the app from scratch).
- Press **`q`** = quit.

> Tip: leave `flutter run` running, edit a `.dart` file, save, press `r`, and
> watch the phone update instantly.

---

## 6. First-time walkthrough on the phone (parent setup)

The app opens into setup. Go through:

1. **Welcome** → Get started.
2. **Create a parent PIN** (enter a 4-digit PIN twice). Remember it — it's also
   the emergency unlock.
3. **Permissions** — three rows. Tap each "Open settings" button:
   - **Draw over other apps** → toggle BrainPass **on** → back.
   - **Accessibility service** → find **BrainPass** in the list → turn it **on**
     → accept the warning → back.
   - **Battery optimisation** + **notification** → allow (recommended).
   - The "Continue" button enables once the first two are granted.
4. **Age band** — pick 5–7 / 8–10 / 11–13.
5. **Apps to gate** — tick a couple. **Use YouTube** as your test app (or any
   game the phone has). Notice the dialer / messages never appear here.
6. **Exchange rate** — e.g. 3 questions = 15 minutes. Tap **Finish setup**.
7. You land on **"BrainPass is active"**.

---

## 7. TEST THE GATE (the important part)

1. Press the phone's **Home** button to leave BrainPass.
2. Open a **gated** app (e.g. YouTube).
3. ✅ **Expected:** the colorful **earn card** slides over it asking questions.
4. Answer correctly until all stars fill → "You earned X minutes!" → the card
   closes and the app is usable.
5. Open the same app again immediately → ✅ it opens with **no card** (you're
   inside the earned window).
6. Open a **non-gated** app (or the dialer) → ✅ **no card ever**.

### Also test
- **Wrong answers**: type a wrong number → it gently shows the right answer and
  gives a new question, never locks the child out.
- **Parent bypass**: tap the small **"Parent"** link (top-right of the card) →
  enter your PIN → it unlocks immediately.
- **Daily cap** (if you set one): set a tiny cap (e.g. 15 min) and earn past it
  to see the "All done for today" screen; the Parent PIN overrides it.
- **Earned window expiry**: set "Minutes earned" to the minimum and wait for it
  to elapse, then reopen the app → the card should appear again.

---

## 8. Editing settings later

On the phone, open BrainPass → **Parent settings** → enter PIN → you can change
the age band, gated apps, exchange rate, and re-check permissions. There's also
a master **Gating enabled** switch.

---

## 9. Make a standalone APK (install without the PC)

To put the app on the phone permanently (or share it for testing):
```powershell
cd C:\dev\detour\brainpass
flutter build apk --release
```
The file appears at:
```
build\app\outputs\flutter-apk\app-release.apk
```
Copy it to the phone and tap it to install (you'll have to allow "install from
unknown sources"). This is fine for personal testing. For the **Play Store** you
later need a proper signing key and the "Designed for Families" declaration —
out of scope for now.

---

## 10. Troubleshooting

### Phone not detected by `flutter devices`
- Make sure **USB debugging** is on and you tapped **Allow** on the phone.
- Try a different USB cable/port (some cables are charge-only).
- Set the USB mode on the phone to **File Transfer / MTP** (not "charging only").
- Run `flutter doctor` and fix anything with a ✗ next to Android.

### The earn card doesn't appear over a gated app
- Re-open BrainPass → Parent settings → Permissions. Both **overlay** and
  **accessibility** must show "Granted". Accessibility often silently turns
  itself off — toggle it on again.
- Make sure the app you opened is actually in your **gated apps** list.
- Some phones (Xiaomi/Redmi, Realme, Oppo, Vivo, OnePlus, Samsung) aggressively
  kill background apps. In the phone's settings, find BrainPass and:
  - allow **Autostart**,
  - set battery usage to **Unrestricted / Don't optimise**,
  - **lock** the app in the recent-apps screen.
  This is the #1 reliability issue for this whole category of app.

### "Accessibility" warning on the phone
Android shows a scary warning when enabling any accessibility service. That's
normal — BrainPass only uses it to detect which app is open (it never reads or
sends screen content; see PRIVACY_POLICY.md).

### A build error mentioning Java / Gradle
Gradle needs **JDK 17 or newer**. On this machine that's already configured for
you — Flutter is pointed at the JDK 19 at `C:\Program Files\Java\jdk-19`:
```powershell
flutter config --jdk-dir "C:\Program Files\Java\jdk-19"
```
(Do NOT use `C:\Program Files\Android\jbr` here — that bundled one is JDK 11 and
Gradle will reject it.) After changing it, run the build again.

### Reset everything to test onboarding again
Uninstall BrainPass from the phone (long-press its icon → Uninstall), then
`flutter run` again — it starts fresh from the welcome screen.

---

## 11. Honest limitations (from the build spec §13)

- A **determined older child** can still disable the accessibility service or
  uninstall the app. v1 relies on the PIN and the fact that 5–10 year-olds
  rarely circumvent. Uninstall-protection (Device Admin) was deliberately left
  out — it's risky for Play approval.
- Reliability depends on the phone brand's background-kill behaviour. **Test on
  the actual phone your child uses.**
- This is **Android only**. No iPhone version yet.

---

## 12. Where to go next

- Tweak questions: edit `lib/questions.dart` (add GK cards, change math ranges),
  save, press `r`.
- Change colors: edit `lib/theme.dart`.
- Read the full product spec: `../brainpass_kids_build_spec.md`.
```
