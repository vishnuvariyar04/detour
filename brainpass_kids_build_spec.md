# BrainPass (Kids) — Build Specification (v1, parent-controlled build)

> **Working name:** BrainPass (placeholder — verify Play Store + trademark + domain; avoid "PlayPass," which collides with Google Play Pass)
> **Platform:** Android only (this version)
> **Framework:** Flutter
> **Audience:** Children, set up and controlled by a parent
> **Core promise to parents:** "Your kid earns their game and video time by solving a few quick problems first."
> **Design principle that shapes everything:** collect **zero** personal data, store everything **on the device**. This is what keeps a kids app legally light (see §4 — read it before building anything).

---

## 1. The idea

Parents are stuck: kids reach straight for games, YouTube, and social apps the moment they pick up a phone or tablet, and screen-time fights are exhausting. Plain blockers just trigger tantrums. The approach that actually works with kids is the oldest one in parenting — **"eat your veggies before dessert"** (the Premack principle): make the thing they want (the game) the reward for doing a little of the thing that's good for them (a few math, puzzle, or general-knowledge questions).

**BrainPass gates the kid's entertainment apps behind a small "earn it" task.** A parent installs it on the child's device, sets a PIN, picks the child's age level, chooses which apps to gate, and sets the "exchange rate" (e.g. *3 correct answers = 15 minutes*). When the child opens a gated app, a full-screen card appears with age-appropriate questions. Answer enough correctly and the app unlocks for the earned time window; when the time runs out, it re-locks and the child earns again.

**Why this version is strategically strong:** in every adult screen-time app, the user is their own enemy — they disable it in a weak moment. Here, the **buyer (the parent) is not the adversary.** The parent *wants* it enforced and protects it with a PIN; the child can't switch it off. That structurally fixes the retention problem that kills most apps in this space. Parents also pay readily for anything educational that reduces screen-time conflict.

**Honest competitive context (so the build is realistic):** this is an existing sub-category, not open space — players include 1Question, Play My Way, Test 4 Time, Kids360, SmartCookie, and various "Math Lock for kids." Most are either bloated parental-control suites or clunky single-purpose apps with poor reliability (parents leave furious reviews when enforcement is flaky). **The wedge is doing one thing — earn-by-learning — extremely reliably, for one age range, with zero data collection as a trust signal.** Reliability is the moat here, not features.

---

## 2. Who it's for — age bands

The original thought was ages 3–13. Be realistic:
- **Ages 3–4:** too young for question-gates, can't read, and screen-time guidance discourages solo device use. **Not a target.**
- **Ages 5–7 (Band A):** the sweet spot's lower end — counting, simple add/subtract, easy picture/GK questions.
- **Ages 8–10 (Band B):** core sweet spot — add/subtract to 100, times tables, simple division, richer GK.
- **Ages 11–13 (Band C):** workable but the upper edge — multi-step arithmetic, logic, harder GK. Note: 12–13-year-olds will *try to circumvent* (see §13); enforcement is socially harder.

**Primary target = Bands A and B (ages 5–10).** The parent selects a band (or enters the child's age, which maps to a band). v1 supports one child profile per device.

---

## 3. Scope of THIS build

### In scope
- Parent onboarding with a **PIN** that locks all settings.
- Parent picks: age band, which apps to gate, the exchange rate (questions per earned minutes), and an optional daily cap.
- Background detection of when a gated app is opened.
- A full-screen overlay "earn" card with age-appropriate questions.
- Three question types: **procedurally generated math**, **procedurally generated number-pattern puzzles**, and a **hardcoded general-knowledge (GK) set** per band.
- "Earn a time window" logic: solve N → unlock for M minutes → re-lock on expiry.
- Gentle wrong-answer handling (no punishment; reveal answer, give another question).
- **Parent PIN emergency bypass** on the gate screen.
- 100% on-device, zero data collection, no accounts, no ads, no analytics (see §4).

### Explicitly OUT of scope (do not build)
- No remote parent dashboard / no second "parent device" app (that's v2 and adds data-transmission + COPPA weight).
- No cloud, no accounts, no login, no backend.
- **No analytics, ads, crash-reporting, or attribution SDKs** (this is a hard rule — see §4).
- No multiple child profiles.
- No iOS, web, or desktop.
- No location, camera, microphone, or contacts access.

---

## 4. Compliance architecture (READ FIRST — it shapes the whole build)

A kids app is regulated the moment it's *directed to children* (which this is) **and** it *collects personal information from a child*. "Personal information" is broad — it includes persistent identifiers like device IDs and advertising IDs, not just names. The fastest way to accidentally collect it is through **default third-party SDKs** (Firebase Analytics, Crashlytics, AdMob, attribution tools), which ship identifiers off-device automatically.

**The strategy: collect nothing, so there's almost nothing to regulate.** Concretely, this build MUST:

1. **Store everything locally** (SharedPreferences / on-device only). The child's age, PIN, progress, and settings never leave the device.
2. **Use NO analytics, ads, crash-reporting, or attribution SDKs.** Do not add Firebase, AdMob, Crashlytics, Sentry, Amplitude, or similar. If a crash logger is ever needed, it must be one that does not transmit device identifiers — but for v1, none.
3. **Request no sensitive permissions** beyond what the gate needs (accessibility + overlay + foreground service + battery exemption). No location, camera, mic, contacts.
4. **Monetize via parent payment, never ads.** A paid app or a parent-facing subscription is fine; behavioral ads to children are the most dangerous part and are simply not present here.

**What you still must do even with zero collection:**
- Ship a clear **privacy policy** (it can honestly say "we collect and transmit no personal data; everything stays on your device").
- Complete the **Google Play "Designed for Families" / data-safety declaration** truthfully (which becomes trivial when the honest answer is "we collect nothing").
- Build and market it **as a children's app from day one** — you can't bolt that on later.
- Expect **slower, pickier Play review** for the families category.

> ⚠️ Not legal advice. Before taking parents' money at scale, get a few hundred dollars of real legal review — "directed to children" determinations and regional rules (US COPPA = under 13; EU = 13–16; India DPDP = under 18) have nuance, and penalties are per-violation.

The payoff: by collecting nothing, you skip the heavy verifiable-parental-consent machinery and keep v1 genuinely buildable.

---

## 5. End-to-end flow

### Parent setup (one time)
1. Parent installs and opens the app on the **child's** device.
2. Parent reads a one-screen explainer, then **creates a 4-digit PIN** (this protects all settings and is the emergency bypass).
3. Parent grants permissions (overlay + accessibility + battery exemption) via guided buttons.
4. Parent sets the **age band** (or enters the child's age → mapped to a band).
5. Parent picks **which apps to gate** (games / YouTube / social — never the dialer or messaging; see §13 safety rule).
6. Parent sets the **exchange rate**: questions-to-earn (default 3) and minutes-earned (default 15), plus optional **daily cap** (e.g. 60 min total).
7. Parent hands the device to the child. Done.

### Child usage (ongoing)
1. Child opens a gated app.
2. If there's an active earned window for it → it just opens.
3. If not → the full-screen earn card appears: solve `questionsToEarn` correct answers.
4. On success → the app unlocks for `minutesEarned` minutes; a small countdown runs.
5. When the window expires → the app re-locks; next open requires earning again.
6. Daily cap reached → a friendly "all done for today" screen; only the parent PIN overrides.

---

## 6. Tech stack

- **Flutter** (stable).
- **flutter_accessibility_service** — detect when a gated app comes to the foreground.
- **flutter_overlay_window** — draw the full-screen earn card over the gated app (separate entry point / isolate).
- **flutter_foreground_task** (or equivalent) — persistent foreground service + notification to survive background-kill on Samsung/Xiaomi/Realme/OnePlus.
- **shared_preferences** — all local state (PIN hash, band, gated apps, exchange rate, earned-window timestamps, daily usage).
- **crypto** (Dart) — to store the PIN as a salted hash, not plaintext.
- **NO** Firebase / AdMob / Crashlytics / analytics / attribution (see §4).

> ⚠️ Plugin APIs change — confirm exact method/stream names on each plugin's current pub.dev README. The architecture below doesn't depend on exact names.

---

## 7. Architecture

Two Flutter worlds, exactly as in the adult build:

1. **Main app** (parent-facing UI behind the PIN): onboarding, PIN, settings, age band, app picker, exchange rate.
2. **Overlay** (the kid-facing earn card): a separate entry point launched by `flutter_overlay_window`, running in its own isolate.

**Detection** lives in the foreground service driven by the accessibility event stream. On a gated app coming to the foreground, it checks whether an earned window is active; if not, it shows the overlay.

**Cross-isolate communication = SharedPreferences as the single source of truth** (same pattern as the adult build — don't attempt live object passing):
- Main app writes: `pinHash`, `ageBand`, `gatedApps`, `questionsToEarn`, `minutesEarned`, `dailyCapMinutes`.
- Detection/service writes per-app earned-window end timestamps: `window:<package>` = epoch-millis when the unlock expires.
- The overlay reads `ageBand` + exchange rate, generates/serves questions, and on success writes the new `window:<package>` timestamp, then closes itself.
- The GK content and the math/puzzle generators are **compiled into the app as Dart** (see §11–12), so only small values pass through prefs.

### Detection sequence
```
Accessibility event (window state changed)
        │ packageName in gatedApps?
        ▼ yes
Is now < window:<package>?  ──yes──▶ allow (still within earned time)
        │ no
        ▼
Daily cap reached?  ──yes──▶ show "done for today" overlay (parent PIN to override)
        │ no
        ▼
Overlay already visible?  ──yes──▶ ignore
        │ no
        ▼
Show earn overlay  ──▶ child solves N  ──▶ write window:<package> = now + minutesEarned
                                          add minutesEarned to today's usage
                                          close overlay
```

---

## 8. Permissions & onboarding

Same three as the adult build, with **child-safe, parent-aimed copy**. Build a guided screen with live ✓/✗ status and deep-link buttons.

| Permission | Why | How |
|---|---|---|
| **Draw over other apps** | To show the earn card over games/videos | `FlutterOverlayWindow.requestPermission()` / overlay settings intent |
| **Accessibility Service** | To know when your child opens a gated app | Plugin opens Accessibility settings; parent toggles it on |
| **Ignore battery optimization** | So it keeps working in the background | `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` |

- "Finish setup" stays disabled until overlay + accessibility are granted.
- After setup, the parent **must create the PIN before the app picker** so settings are protected immediately.
- Re-check permission state on app resume; if revoked later, show a "Tap to re-enable" banner in the parent area.

---

## 9. Screen-by-screen spec

### 9.1 Parent intro
- One screen: what BrainPass does ("Your child earns screen time by solving quick problems"), and the privacy promise ("Everything stays on this device. We collect nothing.").

### 9.2 PIN creation
- 4-digit PIN, entered twice, stored as a **salted hash** (never plaintext). This PIN gates all settings and is the emergency bypass.

### 9.3 Permissions
- The §8 table as guided rows.

### 9.4 Age band
- Three tappable options: **Ages 5–7**, **Ages 8–10**, **Ages 11–13** (or "Enter child's age" → maps to a band). Saves `ageBand`.

### 9.5 App picker
- List of common gateable apps (packages in §10). Toggles. **Pre-warn the parent not to gate phone/messaging** (and the app blocks selecting the dialer — see §13). Saves `gatedApps`.

### 9.6 Exchange rate
- Two simple steppers: **Questions to earn** (1–10, default 3) and **Minutes earned** (5–60, default 15). Optional **daily cap** (off, or 15–180 min). Saves `questionsToEarn`, `minutesEarned`, `dailyCapMinutes`.

### 9.7 Parent home (PIN-protected)
- "BrainPass is active ✅" (or a warning if a permission was revoked).
- Shows current band, gated apps, exchange rate, today's earned/used minutes — all editable.
- Re-enter PIN to access. A simple master ON/OFF is optional.

### 9.8 The earn card (kid-facing overlay — the heart)
Full-screen, opaque, **colorful and friendly** (big buttons, large text, cheerful feedback — this is for a child). Top to bottom:
- A small progress indicator: "Solve 3 to play! ⭐ ⭐ ☆" (filled stars = correct so far).
- The **question** (math, pattern, or GK), large.
- **Answer input:** for math/pattern, a big numeric keypad; for GK, 3 large option buttons.
- Behaviour:
  - **Correct:** happy animation + sound, fill a star, advance. When stars = `questionsToEarn` → "You earned 15 minutes! 🎉", write the window, close.
  - **Wrong (kid-gentle, NO punishment):** soft "try again," show the correct answer briefly, then serve a **new** question. Wrong answers don't fill a star and don't lock the child out — the goal is practice, and the parent PIN is always the safety valve.
  - **Question mix:** rotate types so it's not all math — e.g. 2 math + 1 GK per earn cycle, configurable later. For v1, default to mostly generated math/pattern with GK sprinkled in.
- A small **"Parent" link** in a corner → PIN entry → instant bypass/unlock (for emergencies or parent override). Make it discreet so kids don't fixate on it.

### 9.9 "Done for today"
- Friendly full screen when the daily cap is hit. Only parent PIN overrides.

---

## 10. Package names (gateable preset list)
```
YouTube       com.google.android.youtube
YouTube Kids  com.google.android.apps.youtube.kids
Instagram     com.instagram.android
TikTok        com.zhiliaoapp.musically
Snapchat      com.snapchat.android
Roblox        com.roblox.client
Subway Surf   com.kiloo.subwaysurf
(plus a generic "add by picking from installed apps" flow)
```
> The picker should list installed user apps and let the parent toggle any of them — but **exclude/disallow** the dialer, messaging, contacts, clock, and settings (safety rule §13).

---

## 11. Question generators (procedural — drop-in Dart)

Math and pattern questions are **generated**, not authored: infinite, deterministic answers, no content/licensing burden, and language-light. This is the hero mechanic.

```dart
import 'dart:math';

enum Band { a, b, c } // ages 5-7, 8-10, 11-13

class Question {
  final String prompt;
  final String answer;          // string for exact compare
  final List<String>? options;  // null => numeric keypad input
  const Question(this.prompt, this.answer, {this.options});
}

final _rng = Random();
int _r(int min, int max) => min + _rng.nextInt(max - min + 1);

// ---- MATH ----
Question generateMath(Band band) {
  switch (band) {
    case Band.a: // add/subtract within 20
      if (_rng.nextBool()) {
        final x = _r(1, 10), y = _r(1, 10);
        return Question('$x + $y = ?', '${x + y}');
      } else {
        final x = _r(2, 20), y = _r(1, x); // no negatives
        return Question('$x - $y = ?', '${x - y}');
      }
    case Band.b: // add/sub to 100, times tables, simple division
      final pick = _r(0, 3);
      if (pick == 0) { final x=_r(10,99), y=_r(10,99); return Question('$x + $y = ?', '${x+y}'); }
      if (pick == 1) { final x=_r(20,99), y=_r(1,x); return Question('$x - $y = ?', '${x-y}'); }
      if (pick == 2) { final x=_r(2,12), y=_r(2,12); return Question('$x × $y = ?', '${x*y}'); }
      final y=_r(2,12), q=_r(2,12); final x=y*q; return Question('$x ÷ $y = ?', '$q');
    case Band.c: // multi-step, 2-digit ×, division, squares
      final pick = _r(0, 3);
      if (pick == 0) { final x=_r(11,49), y=_r(2,12); return Question('$x × $y = ?', '${x*y}'); }
      if (pick == 1) { final y=_r(3,15), q=_r(3,15); final x=y*q; return Question('$x ÷ $y = ?', '$q'); }
      if (pick == 2) { final a=_r(2,9),b=_r(2,9),c=_r(2,9); return Question('$a × $b + $c = ?', '${a*b+c}'); }
      final n=_r(4,15); return Question('$n² = ?', '${n*n}');
  }
}

// ---- NUMBER PATTERN ("what comes next") ----
Question generatePattern(Band band) {
  final step = band == Band.a ? _r(1, 3) : band == Band.b ? _r(2, 6) : _r(3, 12);
  final start = _r(1, band == Band.a ? 5 : 12);
  final seq = [start, start + step, start + 2 * step, start + 3 * step];
  final next = start + 4 * step;
  return Question('${seq.join(', ')}, ?', '$next');
}
```

Answer checking: trim input, compare as integers where numeric. For GK (below), compare against the correct option index.

---

## 12. General-knowledge content (drop-in Dart, per band)

Kid-appropriate, fact-checked MCQs. Keep them short and friendly. (Add more over time; these seed v1.)

```dart
class GkCard {
  final String prompt;
  final List<String> options;
  final int correctIndex;
  const GkCard(this.prompt, this.options, this.correctIndex);
}

const List<GkCard> gkBandA = [ // ages 5-7
  GkCard('What is a baby dog called?', ['Puppy', 'Kitten', 'Cub'], 0),
  GkCard('The sun is a...?', ['Star', 'Planet', 'Cloud'], 0),
  GkCard('Which animal gives us milk?', ['Cow', 'Lion', 'Snake'], 0),
  GkCard('How many sides does a triangle have?', ['3', '4', '5'], 0),
  GkCard('Where do fish live?', ['Water', 'Trees', 'Sky'], 0),
  GkCard('What colour is the sky on a clear day?', ['Blue', 'Green', 'Red'], 0),
  GkCard('Which insect makes honey?', ['Bee', 'Ant', 'Spider'], 0),
  GkCard('What do we see with?', ['Eyes', 'Ears', 'Nose'], 0),
  GkCard('How many days are in a week?', ['7', '5', '10'], 0),
  GkCard('Ice is frozen...?', ['Water', 'Milk', 'Juice'], 0),
  GkCard('What is a baby cat called?', ['Kitten', 'Puppy', 'Calf'], 0),
  GkCard('What do plants need to grow?', ['Water and sunlight', 'Candy', 'Toys'], 0),
];

const List<GkCard> gkBandB = [ // ages 8-10
  GkCard('Which is the largest planet in our solar system?', ['Jupiter', 'Earth', 'Mars'], 0),
  GkCard('What is the fastest land animal?', ['Cheetah', 'Elephant', 'Turtle'], 0),
  GkCard('A group of lions is called a...?', ['Pride', 'Pack', 'Herd'], 0),
  GkCard('On which continent is the Sahara Desert?', ['Africa', 'Asia', 'Europe'], 0),
  GkCard('Roughly how many bones are in an adult human body?', ['206', '100', '500'], 0),
  GkCard('In which country is the Great Wall?', ['China', 'India', 'Egypt'], 0),
  GkCard('How plants make food using sunlight is called...?', ['Photosynthesis', 'Digestion', 'Evaporation'], 0),
  GkCard('What is the largest ocean?', ['Pacific', 'Atlantic', 'Indian'], 0),
  GkCard('How many legs does a spider have?', ['8', '6', '4'], 0),
  GkCard('Water freezes at what temperature (°C)?', ['0', '50', '100'], 0),
  GkCard('Bats are...?', ['Mammals', 'Birds', 'Insects'], 0),
  GkCard('What currency is used in Japan?', ['Yen', 'Dollar', 'Rupee'], 0),
];

const List<GkCard> gkBandC = [ // ages 11-13
  GkCard('What is the chemical symbol for gold?', ['Au', 'Gd', 'Go'], 0),
  GkCard('What is the smallest prime number?', ['2', '1', '3'], 0),
  GkCard('Which planet is known as the Red Planet?', ['Mars', 'Venus', 'Jupiter'], 0),
  GkCard('Which travels faster?', ['Light', 'Sound', 'They are equal'], 0),
  GkCard('What is the largest organ of the human body?', ['Skin', 'Heart', 'Liver'], 0),
  GkCard('What is the capital of Australia?', ['Canberra', 'Sydney', 'Melbourne'], 0),
  GkCard('A six-sided polygon is called a...?', ['Hexagon', 'Pentagon', 'Octagon'], 0),
  GkCard('What is often called the powerhouse of the cell?', ['Mitochondria', 'Nucleus', 'Ribosome'], 0),
  GkCard('Who wrote Romeo and Juliet?', ['Shakespeare', 'Dickens', 'Tolkien'], 0),
  GkCard('What is the square root of 64?', ['8', '6', '16'], 0),
  GkCard('Which gas do plants absorb from the air?', ['Carbon dioxide', 'Oxygen', 'Nitrogen'], 0),
  GkCard('Which country is also a continent?', ['Australia', 'India', 'Brazil'], 0),
];

const Map<Band, List<GkCard>> gkByBand = {
  Band.a: gkBandA, Band.b: gkBandB, Band.c: gkBandC,
};
```

---

## 13. Edge cases, safety, and circumvention

**Safety rules (non-negotiable):**
- **Never gate the dialer, emergency calls, SMS/messaging, contacts, clock/alarm, or system settings.** The app picker must exclude these. A child must always be able to call a parent or emergency services.
- The **parent PIN** is always an instant bypass on the gate screen.

**Kid circumvention (be honest about limits):**
- Kids will try to: disable the accessibility service, change the system clock, clear the app, or use another launcher.
- v1 defenses: PIN-lock all settings; detect if accessibility/overlay gets turned off and show a persistent local notification + a locked state until re-enabled; use device time monotonically where possible to reduce clock-cheating. 
- **Uninstall protection** (Device Admin API) is possible but heavy, easy to misuse, and risky for Play approval — **leave it out of v1.** Rely on the PIN and the fact that the primary target (ages 5–10) rarely circumvents. Note clearly to the parent that a determined older child can bypass it.

**Reliability (the make-or-break, per competitor reviews):**
- Foreground service + persistent notification + battery-optimization exemption. Expect brand-specific background-kill (Xiaomi/Realme worst). If the service dies, the gate silently fails and parents leave 1-star reviews — test on at least 2–3 brands.
- Guard against overlay stacking (an `isOverlayVisible` flag + the plugin's active check).

**Earn-window correctness:**
- Store window end as an absolute epoch timestamp per package; re-check on every foreground event. Roll the daily-usage counter at local midnight.
- Overlay isolate must re-read prefs fresh on launch (don't trust a cached instance) and write the new window before closing.

---

## 14. Data model & storage keys

```dart
// All local. Nothing transmitted.
pinHash            : String   // salted hash of the 4-digit PIN
pinSalt            : String
ageBand            : String   // "a" | "b" | "c"
gatedApps          : List<String>   // package names
questionsToEarn    : int      // default 3
minutesEarned      : int      // default 15
dailyCapMinutes    : int      // 0 = no cap
usageToday         : int      // minutes earned/used today
usageDateStamp     : String   // YYYY-MM-DD to reset usageToday
window:<package>   : int      // epoch millis when this app's unlock expires
onboardingComplete : bool
```

---

## 15. Build order (riskiest first)

1. **Overlay proof:** add `flutter_overlay_window`, request permission, draw a full opaque box over everything via a test button.
2. **Detection proof:** add `flutter_accessibility_service`, log when a gated package comes to the foreground; add the foreground service so it survives backgrounding.
3. **Wire detection → overlay**, respecting an active `window:<package>`.
4. **Build the earn card** (overlay): generator-driven questions, star progress, correct/wrong handling, write the earned window on success.
5. **Build the parent flow:** intro → PIN (hashed) → permissions → age band → app picker (with the excluded-apps safety rule) → exchange rate → PIN-protected home.
6. **Daily cap + usage rollover.**
7. **Drop in** the generators (§11) and GK content (§12).
8. **Verify zero SDKs** (§4) — grep the dependency tree; no analytics/ads/crash libs.
9. **Test on 2–3 phone brands.**

**Realistic note:** the engine (steps 1–4) is the core unknown — get it firing first. The parent flow + content is straightforward Flutter once the engine works.

---

## 16. Definition of done (v1)
- [ ] A parent can install, set a PIN, grant permissions, pick a band + apps + exchange rate without help.
- [ ] Opening a gated app reliably shows the earn card; non-gated apps (and the dialer/messaging) never do.
- [ ] Solving `questionsToEarn` unlocks the app for `minutesEarned`; it re-locks on expiry.
- [ ] Wrong answers are gentle and never lock the child out.
- [ ] Parent PIN bypasses the gate; settings are unreachable without the PIN.
- [ ] Daily cap works and resets at midnight.
- [ ] The dependency tree contains no analytics/ads/crash/attribution SDKs.
- [ ] Survives an hour idle on at least one device without the service dying.
- [ ] Privacy policy drafted ("we collect nothing"); Play data-safety answers match.

---

## 17. Next version (NOT now)
- **Two-device parent dashboard** (parent sees progress / adjusts rules remotely). ⚠️ This adds data transmission → re-opens COPPA/GDPR-K weight; design the consent + privacy layer before building it.
- Multiple child profiles.
- Richer question types (reading, spelling, more GK; optional curriculum alignment).
- **Difficulty escalation:** within a band, ramp difficulty as the child earns more in a day (your escalating-difficulty idea, fitted to kids).
- Parent-authored questions ("add this week's spelling words").
- iOS version (Apple Screen Time + Kids Category).
- Reward/streak layer for the child (kept simple; no engagement-maximizing dark patterns — that draws regulatory and reputational fire in kids apps).

---

## 18. Notes for Claude Code
- **Do §4 first in your head:** add no analytics/ads/crash SDKs at any point. Everything local.
- Start with §15 build order — overlay + detection before any UI.
- Plugin APIs may have shifted; read current pub.dev READMEs and adapt method names. Architecture (§7) is name-agnostic.
- Keep generators (§11) and GK (§12) in one `questions.dart` imported by both the main app and the overlay isolate.
- SharedPreferences is the only cross-isolate channel; overlay re-reads fresh on launch and writes the window before closing.
- Store the PIN only as a salted hash.
- Enforce the §13 safety rule in the app picker: dialer, messaging, contacts, clock, settings are never gateable.
- Prioritize gate reliability over polish — a flaky gate is the #1 reason parents 1-star these apps.
