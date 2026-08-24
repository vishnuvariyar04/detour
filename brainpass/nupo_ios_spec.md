# Nupo — iOS Build Specification
### Architecture: App Intents + Shortcuts Personal Automations

> **Status:** v4 — architecture unchanged from v3 (App Intents + Shortcuts). This revision fills every `🔧 TO BE FILLED BY CLAUDE CODE` block from the live codebase (Appendices A–K), corrects the brand/age-band facts to match the shipped app, and adds the single most important thing the earlier drafts got wrong: **the real question engine is the native v2 engine (10 interaction types), not the reduced `questions.dart`.** See §4A — read it before you scope the quiz.
>
> **Audience:** An iOS developer with a Mac + iPhone, **no prior context** on this project, but **full access to the Android repo** (`brainpass/`). Read §1–§4, §4A, then the appendices before writing code. The appendices are the map; the repo's source files are the source of truth (each appendix cites the file to read).
>
> **Companion docs:** the Android build spec, the onboarding spec (`nupo_onboarding_spec.md`), the marketing/positioning brief. Where this doc and those disagree on facts (colours, fonts, bands, screen counts), **this doc wins** — it was reconciled against the actual code on 2026-07-24.

---

## 0. HOW TO USE THIS DOCUMENT

**If you are Claude Code (editing this file):** fill every `🔧 TO BE FILLED BY CLAUDE CODE` block from the actual Flutter/Kotlin codebase. Add detail; don't change the architecture in §3.

**If you are the iOS developer:** read §1 (product), §2 (why it's not a port), §3 (architecture), §4 (the timer — the part most likely to be got wrong). §11 Phase 0 is a hard gate: prove the mechanism on a real device before building anything else.

> **You have access to the Android repo** (`brainpass/`). This document is the **map and the analysis** — where things live, what ports and what doesn't, the platform gotchas, and the decisions already made. **Treat the actual source files as the source of truth** (this doc cites their paths); don't re-type code from here when you can read the live file. The appendices summarize and point; the repo has the exact bytes.

**Two things that make this much easier than it looks:**
1. **No special Apple entitlement is required.** No Family Controls, no multi-week approval queue. Start today.
2. **No curated app list is required.** Apple's own automation picker exposes every app on the device.

---

## 1. PRODUCT CONTEXT (assume zero background)

**Nupo** is an Android app, live in internal testing, built in **Flutter**. Package `app.nupo.kid`. Company: **InternSpirit Private Limited**. Domain: `nupo.app`.

### What it does
A parent installs Nupo on their **child's own device** (ages 5–11) and picks which apps to gate — YouTube, Roblox, games. When the child opens one of those apps, Nupo appears with **3 quick questions** (math, logic patterns, or general knowledge, matched to the child's age band). Answer them and the app is usable for a set time (default 15 minutes). When that time is spent, the next open asks again. A **parent PIN** protects all settings and can skip a lesson.

### Positioning (governs App Store copy and every string in the UI)
Nupo is **not** sold as a screen-time reducer, blocker, or parental-control tool:

> **"A daily learning habit for kids, delivered through the screen time they're already having."**

Tagline: **Learning Kids Will Do.**

The insight: the hard problem in kids' learning isn't content, it's getting the child to *show up*. Workbooks get ignored; learning apps get abandoned. Nupo attaches learning to the one habit kids never abandon — reaching for the phone.

**Banned in user-facing copy:** "screen time" (as the promise), "blocker", "blocking", "parental control", "restrict", and "play" as the reward word (kids use phones for video too — say "unlocks" or name the app).

> 📌 Fortunate alignment: Nupo is a **habit tool**, not a prison. It doesn't need to claim tamper-proof enforcement. **Never write copy promising a child cannot bypass it** (see §5).

### Brand — ⚠️ CORRECTED from live code (`lib/theme.dart`)
Earlier drafts of this doc listed aspirational tokens (`#8B3DEC`, Fredoka, Plus Jakarta Sans) that were never shipped. **The actual, shipped design system is below — use these exact values.** Full token list in Appendix L.

| Token | Hex | Role |
|---|---|---|
| `primary` | `#5A32E9` | brand / primary actions |
| `primaryBright` | `#7A52FF` | gradient partner (buttons) |
| `primarySoft` | `#F1EDFF` | icon-badge / tint bg |
| `accent` (logo yellow) | `#FFC117` | warmth + reward (halo, stars, earn chips) |
| `accentSoft` | `#FFF4D2` | yellow tint bg |
| `accentDeep` | `#B98600` | readable text on `accentSoft` |
| `correct` | `#23B26A` | success / protection-on |
| `wrong` | `#FF6B6B` | errors |
| `bg` | `#F7F5FF` | app background (purple wash → white) |
| `textDark` | `#241E3C` | deep ink |
| `textMuted` | `#74708A` | secondary text |

**Font: `Nunito` only** (weights 400/600/700/800/900), bundled in `assets/fonts/` — **NOT** Fredoka/Plus Jakarta Sans, and **not** `google_fonts` (the app is offline-only; runtime font download is banned). Icons: `material_symbols_icons` (`Symbols.*_rounded`, filled, weight 600). Mascot: a friendly owl named **Nupo** (`assets/mascot_opening.png`, `assets/mascot_pin.png` — transparent PNGs). Signature hero treatment: `HaloMascot` = owl on a sunny yellow halo with star sparkles.

**Colour language (keep it on iOS):** purple = brand/primary; yellow = warmth/reward (halo, stars, "N questions → M min" chips, "min left" pills); green = success/on. Don't make everything purple — colour-code multi-item rows.

### Age bands — ⚠️ CORRECTED: there are **FOUR** bands, not three
The shipped app (`questions.dart`, `Questions.kt`) uses four bands. Stored as the single chars `"a"|"b"|"c"|"d"` (default `"b"`).

| Band | Stored | Ages | Content |
|---|---|---|---|
| A | `a` | 5–6 | Counting & simple sums |
| B | `b` | 7–8 | Mental math & nature |
| C | `c` | 9–10 | Times tables & trivia |
| D | `d` | 11 | Advanced logic & math |

Age→band map (`bandFromAge`): `≤6→A`, `≤8→B`, `≤10→C`, else `D`. Band labels shown to parents: "Ages 5–6", "Ages 7–8", "Ages 9–10", "Age 11".

### Privacy posture (non-negotiable)
- **All child data stays on-device.** Answers, progress, streaks, timers — never transmitted.
- **No analytics, ad, attribution, or crash SDKs.** No Firebase Analytics, AdMob, Crashlytics, AppsFlyer, Adjust, Branch.
- Only personal data collected: the **parent's phone number** (Firebase phone OTP), for auth.
- **Never call `ATTrackingManager`. No IDFA.** (Android has `AD_ID` stripped and RevenueCat attribution disabled — match it.)

---

## 2. WHY THIS IS NOT A PORT

Android's engine rests on two things iOS lacks at any permission level:

1. **`UsageStatsManager` polling** — `GuardService.kt` asks Android which app is foreground, once per second, forever. iOS has no API telling a third-party app what other app is open.
2. **`SYSTEM_ALERT_WINDOW` overlay** — `LockUi` draws over any app. iOS has no cross-app overlay.

Everything protecting those — `WatchdogReceiver.kt`, `Autostart.kt`, `BootReceiver`, battery exemption, the 1-second tick — **is not written for iOS**.

### Approaches considered
| | Screen Time API | URL scheme | **App Intents** ← CHOSEN |
|---|---|---|---|
| Entitlement | ❌ weeks of review | ✅ none | ✅ **none** |
| Curated app list | n/a | ❌ required | ✅ **not required** |
| Visible flash on pass-through | n/a | ❌ yes | ✅ **none** |
| Can open your app from the gate | ❌ **no** | ✅ yes | ✅ yes |

---

## 3. THE ARCHITECTURE

### 3.1 What the parent creates (once per app)
In the **Shortcuts** app:

```
Automation → + → App
  → choose "Roblox"          ← Apple's picker, ALL apps available
  → "Is Opened"
  → Run Immediately          ← must be ON
  → New Blank Automation
  → search "Nupo"
  → choose "Check learning gate"
  → tap the App parameter → choose "Roblox"
  → Done
```

This mirrors One Sec's setup exactly. **No curated list, no URL scheme, no typing.**

### 3.2 The intent pair (the heart of the whole thing)

`openAppWhenRun` is **static** — Apple's forums confirm it "is read and opens the app even before `perform()` is run," so it cannot be made dynamic. Apple's documented workaround (also in the *Dive into App Intents* WWDC session, ~17:19) is an **outer/inner intent pair**:

```swift
// OUTER — runs silently, never opens Nupo by itself
struct CheckLearningGateIntent: AppIntent {
    static let title: LocalizedStringResource = "Check learning gate"
    static var openAppWhenRun: Bool = false          // ← key

    @Parameter(title: "App")
    var targetApp: GatedAppEntity                     // see §3.4

    func perform() async throws -> some IntentResult & OpensIntent {
        let state = GateEngine.evaluate(for: targetApp.id)

        switch state {
        case .allowed:
            // Do nothing. Roblox continues opening normally.
            // NO FLASH — Nupo never appears.
            GateEngine.markSessionStart(targetApp.id)
            return .result()

        case .needsLesson, .dailyCapReached:
            return .result(opensIntent: OpenNupoGateIntent(appId: targetApp.id))
        }
    }
}

// INNER — exists solely to foreground Nupo
struct OpenNupoGateIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Nupo"
    static var openAppWhenRun: Bool = true            // ← key
    static var isDiscoverable: Bool = false           // hide from the Shortcuts library

    @Parameter(title: "App ID") var appId: String

    @MainActor
    func perform() async throws -> some IntentResult {
        GateEngine.stagePendingGate(appId: appId)     // Flutter reads this on launch
        return .result()
    }
}
```

**Why this is the whole game:** in the `.allowed` case Nupo never opens. The child taps Roblox and Roblox opens — indistinguishable from Nupo not being installed. That is why One Sec feels seamless, and it removes the "visible flash" problem that plagued the URL-scheme design.

> ⚠️ **Verify in Phase 0:** one developer reported that the outer/inner pattern "functions as expected but there is an error notification showing every time." Confirm whether a banner appears on your target iOS version, and whether returning `.result()` (rather than throwing) avoids it.
> Refs: https://developer.apple.com/forums/thread/723623 · https://developer.apple.com/forums/thread/740707

### 3.3 ⭐ Returning to the app after the lesson (the "Continue to Roblox" button)

**Understand the platform difference first — this is the single most common misconception about this build.**

On **Android**, Nupo draws an *overlay* on top of Roblox. Roblox is still running underneath. Dismiss the overlay and you're already back — no button needed.

On **iOS there is no overlay at any permission level.** When Nupo's UI is visible, **Nupo has actually been opened and iOS has switched apps.** Roblox is backgrounded. That's why One Sec has a "Continue to Instagram" button — you're not hovering above Instagram, you've *left* it, and you need a way back.

| | Android | iOS |
|---|---|---|
| Mechanism | Overlay window drawn on top | Full app switch |
| Target app during the gate | Still open, underneath | Backgrounded |
| Getting back | Dismiss the overlay | Must re-open the app |
| "Continue to X" button | Not needed | **Required** |

> Note this only applies when a lesson is actually due. When the child has minutes left, the outer intent runs silently and **Nupo never opens at all** (§3.2) — Roblox just launches. Nupo is invisible most of the time.

#### The default: a "Continue to Roblox →" button (Tier 2)

After the quiz is passed, show a success screen with a primary button that returns the child directly to the app:

```swift
// After grantMinutes(appId:minutes:)
return .result(opensIntent: OpenURLIntent(URL(string: "roblox://")!))
```

- Requires the target app's **URL scheme**
- Every scheme used must be declared in **`LSApplicationQueriesSchemes`** in `Info.plist`, or `canOpenURL` fails silently
- Check `canOpenURL` before showing the button; fall back to Tier 1 if it returns false

#### The fallback: "Open Roblox again 🎉" (Tier 1)

For any app **without** a verified scheme, show a success screen instructing the child to reopen it themselves. The automation fires, the gate is now `.allowed`, nothing opens, Roblox launches. One extra tap, zero dependencies.

#### The resulting scope

| | Coverage |
|---|---|
| Apps that can be **gated** | ✅ **All of them** — Apple's automation picker, no list |
| Apps with a **"Continue to X" button** | Only those with a verified URL scheme |
| Apps without a scheme | Still fully gated, just Tier 1 return |

This is almost certainly why One Sec publishes a supported-apps list: the gate works broadly, the polished return does not.

#### 🔧 URL scheme table — verify each on a real device

Test with `canOpenURL` **and** by actually launching. Schemes are undocumented, vary by region/version, and change without notice. Re-verify after major app updates.

The Android curated preset list is **exactly 7 apps** (`kPresetGateableApps` in `safe_apps.dart`). All 7 are below, plus common extras. Verify each `canOpenURL` on a real device and declare every one you use in `LSApplicationQueriesSchemes`.

| App | Android package (from `safe_apps.dart`) | Candidate iOS scheme | Verified? | Notes |
|---|---|---|---|---|
| YouTube | `com.google.android.youtube` | `youtube://` | ☐ | in preset list |
| YouTube Kids | `com.google.android.apps.youtube.kids` | `youtubekids://` ? | ☐ | in preset list; may have none |
| Instagram | `com.instagram.android` | `instagram://` | ☐ | in preset list |
| TikTok | `com.zhiliaoapp.musically` | `snssdk1233://` / `tiktok://` | ☐ | in preset list; region-dependent |
| Snapchat | `com.snapchat.android` | `snapchat://` | ☐ | in preset list |
| Roblox | `com.roblox.client` | `roblox://` | ☐ | in preset list |
| Subway Surfers | `com.kiloo.subwaysurf` | ? | ☐ | in preset list; likely none (game) |
| Minecraft | — | `minecraft://` | ☐ | common extra |
| Netflix | — | `nflx://` | ☐ | common extra |

> Note: Android also lets the parent gate **any installed app** beyond the preset 7 (via the "More apps on this phone" picker, filtered by `safe_apps.dart`'s blocklist). iOS's automation trigger similarly covers all apps, so the URL-scheme table only bounds the **Tier 2** return, never what can be gated.
> Most **games** have no public URL scheme. Expect Tier 1 to be the real path for a meaningful share of gated apps — design the Tier 1 success screen to feel good, not like a degraded fallback.

The Android **safety blocklist** (dialer / SMS / contacts / clock / settings / emergency — never gateable) is in Appendix G; mirror its intent on iOS so a child can always reach Phone/Messages, even though iOS gating is per-automation.

### 3.4 The App parameter (`GatedAppEntity`)
🔧 **VERIFY IN PHASE 0 — this is the one genuinely open technical question.**

The Shortcuts action needs an app-picker parameter. Determine which is true on the target iOS version:
- **(a)** Apple provides a system app-entity type usable as an `@Parameter` — ideal, gives every installed app.
- **(b)** No such type exists, so define your own `AppEntity` backed by a bundled list of common kids' apps, with an `EntityQuery` for search.

If **(b)**, the *automation trigger* still uses Apple's full picker (so the gate fires for any app); only the *parameter* is limited. Mitigate by shipping a generous list plus a "Something else" catch-all that gates generically.

Seed list for case (b): the 7-app preset + brand metadata is in **Appendix G**. Note iOS bundle IDs differ from Android package names — the Appendix G table is keyed by Android package; you'll need to resolve iOS bundle IDs / App Store IDs separately (they're what the Shortcuts picker uses).

---

## 4. ⭐ THE TIMER MODEL (get this exactly right)

This is the part most likely to be built wrong. It must behave the way Android does.

### 4.1 Android's current semantics
The Android "App rules" screen states: **"Minutes only count while the app is open."** Earned minutes are consumed as **foreground time in the gated app**, not wall-clock. Put the phone down for an hour with 12 minutes left, and you still have 12 minutes.

✅ **Answered in full in Appendix E** (verified against `GuardService.kt` + `EnginePrefs.kt`). Summary: foreground/active-time (not wall-clock); 1 s tick, screen-on only, `delta` clamped 0–2000 ms, persisted every tick to `rem_<pkg>`; pauses when the child switches away; per-app counters; midnight reset in device-local time; per-app daily cap → "all done for today" mode. **Read Appendix E before implementing the timer.**

### 4.2 The iOS problem
iOS cannot observe another app's foreground time without the Family Controls entitlement. So foreground-accurate counting is not available for free.

### 4.3 Two implementations — build A, plan for B

**Model A — wall-clock (v1).**
On passing the quiz, store `expiresAt = now + earnedMinutes`. Every gate check compares against `Date()`.
- ✅ Trivial, robust, survives reboot, no extra automations
- ❌ Time burns while the child isn't using the app — a child who answers, gets distracted for 20 minutes, and returns finds the time gone. **Parents and children will both notice this. It is a real behavioural difference from Android.**

**Model B — foreground-approximated (v2, recommended if verified).**
iOS Shortcuts automations also support an **"Is Closed"** trigger. Have the parent create **two** automations per app:

```
When Roblox Is Opened  → Nupo: Check learning gate  [Roblox]
When Roblox Is Closed  → Nupo: Pause learning timer [Roblox]
```

Then:
- `Is Opened` + `.allowed` → `markSessionStart(appId)`
- `Is Closed` → `consume(appId, elapsed: now − sessionStart)`, clear session
- Remaining balance persists; only real in-app time is spent

This reproduces Android's semantics closely.

> 🔧 **VERIFY IN PHASE 0:** confirm the "Is Closed" trigger exists and fires reliably on the target iOS version (including on force-quit, task-switch, and lock). If it's unreliable, Model B silently over-credits time — which is a *safe* failure (child gets a bit more) but must be understood.

**Recommendation:** ship **Model A** for v1 so the loop works end to end, then upgrade to **Model B** once "Is Closed" is verified. Design `GateEngine` so the accounting method is swappable behind one interface.

### 4.4 Robustness rules (both models)
- Persist remaining balance **immediately** on every change — the intent process is short-lived and can be killed at any moment.
- Never trust in-memory state between intent invocations; always read from disk.
- Guard against a clock change: store a monotonic reference alongside wall-clock where possible, and treat a backwards jump as "no time consumed" rather than "infinite time."
- Enforce the **daily cap** in `GateEngine.evaluate()`, before the lesson is offered — a child who's hit the cap should see "all done for today," not another quiz.

### 4.5 The gate decision (single source of truth)
```
evaluate(appId) -> GateState
    if parentPinBypassActive      → .allowed
    if dailyCapReached(appId)     → .dailyCapReached
    if remainingBalance(appId) > 0 → .allowed
    else                          → .needsLesson
```
Everything — the intent, the Flutter UI, and the parent's progress view — reads this one function.

---

## 4A. ⭐⭐ THE QUESTION ENGINE — read this before scoping the quiz

**This is the biggest correction to the earlier drafts.** They said: *"`questions.dart` is the single source of truth; no Swift duplicate needed."* That is true about *where the engine should live* (Dart, rendered inside Nupo) — but **`questions.dart` is NOT the engine Android kids actually use.** There are two engines in this repo:

| | `lib/questions.dart` (Flutter) | `android/.../Questions.kt` + `Gk.kt` (native) — **the real kid experience** |
|---|---|---|
| Interaction types | **3** (keypad math, keypad pattern, MCQ GK) | **10** (see below) |
| GK bank size | ~25 cards/band | **~45 cards/band (~180 total)** + India content |
| Session structure | flat (`buildEarnPlan`: math/pattern/gk mix) | **designed arc**: easy hook → varied middle (no kind twice in a row) → **boss finale** |
| Extra banks | none | true/false, match-pairs, word-builder, memory — all with no-repeat picking |
| Where it renders | nowhere on Android (kid lock is native) | native `LockUi.kt` (Canvas-drawn shape tiles, Nunito, sticker auto-upgrade) |
| What `questions.dart` is actually used for today | the **onboarding demo gate** (S21) and nothing else | the actual daily learning moment |

So on Android, `questions.dart` is a *simplified demo* engine; `Questions.kt` is the product. **If iOS ports only `questions.dart`, iOS kids get a visibly poorer experience than Android kids** (3 boring input types vs 10 playful ones, a third of the content, no arc, no boss star).

### The 10 interaction types (`QKind` in `Questions.kt`)
Each must become a Flutter question-renderer on iOS. Full generator source is in **Appendix A2**.

| `QKind` | How the child answers | Visual needs |
|---|---|---|
| `KEYPAD` | type a number | number pad; used for math, number patterns, and "missing number" (`7 + ⬜ = 12`) |
| `MCQ` | tap 1 of 3 text options | GK question card |
| `TRUE_FALSE` | giant True / False buttons | banked facts **+** generated math statements (`8 × 3 = 25` → false) |
| `ODD_ONE_OUT` | tap the odd tile of 4 | shape/colour tiles (odd differs by colour and/or shape) |
| `COUNT` | count tiles, tap the number | N identical tiles + 3 number choices |
| `COMPARE` | tap the bigger of two | two big cards (numbers, products, or fractions by band) |
| `MATCH` | match 3 left → 3 right | two columns, tap-to-connect (capital↔country, animal↔baby, sum↔answer) |
| `ORDER` | arrange 4 numbers ascending | tap-to-place slots, smallest first |
| `WORD` | unscramble letter tiles to spell a word | letter tiles + a clue string |
| `MEMORY` | memorise 3 tiles, then recall one | flash 3 distinct tiles, then probe with 3 options |

**Shape tiles** (`Shape` enum): CIRCLE, SQUARE, STAR, HEART, TRIANGLE, DIAMOND, MOON — Android draws these on a `Canvas`; on iOS render them with `CustomPainter` or bundled SVG/PNG. `Tile.sticker` is a hook: if `assets/stickers/<name>.png` exists, show that image instead of the drawn shape (keep this hook so illustrations can drop in later).

### Session arc (`buildSession(band, count)`)
1. **Hook:** first question is always from an *easy* kind for the band (`easyKinds`).
2. **Middle:** fill up to `count-1` with kinds from `kindsFor(band)`, never repeating the previous kind back-to-back.
3. **Boss:** the last question is flagged `boss = true` (gold border + "⭐ BOSS QUESTION ⭐" + triple celebration in the UI) and drawn from a harder `bossKinds` pool.
4. **Wrong-answer rule (IMPORTANT, matches Android):** a wrong answer is *never* punished with a lost star. One-shot kinds (keypad/MCQ/etc.) **regenerate a new question of the same kind** and let the child retry; puzzle kinds (MATCH/ORDER/WORD) are gentle infinite-retry. The child cannot fail out — they can only take longer. This is core to the "learning, not a test" positioning (§1).

### No-repeat freshness
Banked kinds (GK, true/false, match, word) call `EnginePrefs.pickFresh(bucket, poolSize)`, which persists the recently-shown indices per bucket so content doesn't repeat across sessions/restarts (remembers up to `min(poolSize/2, 20)`). On iOS, reproduce this in `GateEngine`/Dart with `UserDefaults`-backed recent-index lists keyed `recent_<bucket>` (e.g. `gk_B`, `tf_C`, `word_D`).

### 🔧 Recommendation for iOS
**Port `Questions.kt` + `Gk.kt` to Dart** (not `questions.dart`) as the iOS quiz engine, and build the 10 Flutter renderers. This is the honest way to match Android. `questions.dart` can stay as-is for the onboarding demo gate. **Appendix A2 is the porting brief** for `Questions.kt`/`Gk.kt` (read those files directly — you have the repo). Budget real time for the 10 renderers + the tile/Canvas work — it's the richest single piece of net-new Flutter on iOS.

> The quiz still renders *inside Nupo* (Flutter), exactly as §3.3/§6.1 describe — this section doesn't change the architecture, only *which* engine you port and how much UI it needs.

---

## 5. ⚠️ WHAT WE KNOWINGLY GAVE UP

**1. The child can delete the automation.** Shortcuts automations are unprotected; anyone with device access can disable one in seconds. There is no programmatic way to prevent, detect, or restore this.
- Ages 5–7: largely theoretical.
- Ages 8–10: possible.
- Ages 11–13: near-certain eventually.

Mitigation in §7.4 — you can't prevent it, but you can make the parent notice.

**2. Automations must be created by hand.** They **cannot** be created programmatically (https://developer.apple.com/forums/thread/713012). Gating five apps = five manual setups (ten under Model B). This is the biggest drop-off risk in the product; §7.2 exists to make it survivable.

**3. Automations cannot be paused programmatically** (https://developer.apple.com/forums/thread/744698). The gate fires on every open; `GateEngine.evaluate()` is the only thing preventing a loop.

**4. It is not a "blocker."** Never claim in marketing, App Store metadata, or in-app copy that a child cannot bypass Nupo. It would be false.

---

## 6. FLUTTER OR SWIFT? (the language split)

**It's a hybrid: roughly 85% Flutter, 15% Swift.** The split is not a preference — it's forced by one hard constraint:

> **App Intents cannot be written in Dart.** They must be Swift, in the native iOS target.

And a second, subtler one:

> **The intent runs in a short-lived process that does not boot the Flutter engine.** So anything the intent needs to *decide* must be readable from Swift, without Flutter running. This is why `GateEngine` is Swift, not Dart.

If `GateEngine` lived in Dart, every single app launch would have to spin up the Flutter engine just to answer "does this child have minutes left?" — slow, battery-hungry, and it would destroy the silent pass-through that makes §3.2 work.

### 6.1 Flutter / Dart — everything the user looks at (already written)
- **Design system** — `theme.dart`, `widgets.dart`
- **The onboarding funnel** — ~31 one-tap screens, already built and live (Appendix H)
- **The quiz UI** — owl, ⭐⭐☆, question card, keypad, celebration
- **The question engine, pure Dart, zero OS dependency** — ⚠️ but see §4A: port the *native v2 engine* (`Questions.kt`/`Gk.kt`, Appendix A2) to Dart, not the reduced `questions.dart`, and build the 10 question renderers. This is the largest net-new Flutter piece.
- **`ParentHomeScreen`**, app rules, PIN entry, progress view, paywall
- **The guided Shortcuts setup wizard** (§7.2)
- **`shared_preferences`**, **`crypto`**, **`video_player`**, **`material_symbols_icons`**

Minor work only for what already exists: safe areas, iOS back-swipe, native polish.

> 🎉 **The quiz engine does NOT need a *Swift* duplicate.** It renders *inside Nupo* in Flutter, so Dart is the single source of truth — but "Dart" here means a **Dart port of the native v2 engine (§4A / Appendix A2)**, which is richer than the `questions.dart` that ships today. Don't mistake `questions.dart` for the real engine.

### 6.2 Swift — the parts iOS forces
| Component | Why Swift |
|---|---|
| `CheckLearningGateIntent` | App Intents is Swift-only |
| `OpenNupoGateIntent` | App Intents is Swift-only |
| `PauseLearningTimerIntent` (Model B) | App Intents is Swift-only |
| `GatedAppEntity` + `EntityQuery` | App Intents is Swift-only |
| **`GateEngine`** | Must run without the Flutter engine |
| Timer/balance persistence | Read/written by `GateEngine` |
| `LSApplicationQueriesSchemes` + `canOpenURL` | Native `Info.plist` / UIKit |
| `AppDelegate` wiring | Native |

Realistically a few hundred lines of Swift. It is not a Swift rewrite of the app.

### 6.3 The bridge — and one gotcha that will bite you

Flutter and Swift talk over a **MethodChannel**. Flutter calls Swift for: reading the pending gate, granting minutes after a passed quiz, reading balances for the parent progress view, `canOpenURL` checks, and triggering the Tier 2 return.

⚠️ **`shared_preferences` prefixes every key with `flutter.` on iOS.** It's backed by `UserDefaults`, so it *looks* like Swift and Dart can share storage directly — but the keys won't match unless you account for the prefix.

Pick one and be consistent:
- **(a)** Swift owns all gate/timer state; Flutter reads it **only** via MethodChannel. **Recommended** — one writer, no prefix confusion, no races.
- **(b)** Both read `UserDefaults` directly, with Swift explicitly using the `flutter.`-prefixed keys. Faster to write, easier to get subtly wrong.

Whichever you choose, **Swift must be the writer for anything the intent reads**, since the intent can run when Flutter isn't alive.

✅ **Done:** Appendix A maps the two question engines (read `lib/questions.dart` + `Questions.kt`/`Gk.kt` directly), Appendix A2 is the porting brief for the real v2 engine (§4A), and Appendix B is the full `lib/` inventory (PORTS AS-IS / NEEDS CHANGES / iOS N/A / MOVES TO SWIFT).

---

## 7. WHAT MUST BE BUILT NEW

### 7.1 `GateEngine` (Swift, shared)
Lives in the main app target so both the App Intents and Flutter can reach it. Must be safe to call from a short-lived intent process.

- `evaluate(appId) -> GateState` (§4.5)
- `markSessionStart(appId)` / `consume(appId, elapsed)`
- `grantMinutes(appId, minutes)` — called after a passed quiz
- `stagePendingGate(appId)` — writes the pending app so Flutter knows what to show on launch
- Persistence via `UserDefaults` (App Group not strictly needed without extensions, but harmless and future-proof)

### 7.2 ⭐ Guided Shortcuts setup (the make-or-break screen)
Parents abandon here. Treat it as a first-class product surface.

```
Set up Roblox                         ● ○ ○

1. Open Shortcuts              [ Open Shortcuts → ]
2. Tap "Automation" → +
3. Choose "App" → pick Roblox → "Is Opened"
4. Turn ON "Run Immediately"
5. Tap "New Blank Automation"
6. Search "Nupo" → "Check learning gate"
7. Tap the App box → choose Roblox
8. Tap Done

                        [ I've done this ✓ ]
```

Requirements:
- **Deep-link button** to open Shortcuts (`shortcuts://`)
- **An inline looping screen recording** of the exact taps. This one asset will do more for completion than any amount of text.
- **Verification, not trust:** after "I've done this," ask the parent to open Roblox once. If `CheckLearningGateIntent` fires, mark the app ✅. An unverified automation is a silently broken product.
- Set up **one app, verify, then offer more.** Don't demand five setups before any payoff.
- If using Model B (§4.3), the wizard has a second pass for the "Is Closed" automation — introduce it only *after* the first app works.

⚠️ **"Run Immediately" must be ON**, or the child sees a confirmation prompt they can dismiss. Defaults have changed across iOS versions — verify and instruct explicitly.

### 7.3 Launch router (Flutter)
On every launch, read the staged pending gate:
```
pending gate staged?
   ├─ yes → show quiz for that app  (then grantMinutes + §3.3 return)
   └─ no  → normal parent/child home
```

### 7.4 Gate health (mitigating §5.1)
A deleted automation fails **silently**, so surface it:
- Parent home shows per app: **"Last triggered: 2 hours ago"** / **"⚠️ Not triggered in 3 days"**
- After a long silence, prompt: *"Nupo hasn't run for Roblox recently — tap to re-check the setup"* → re-run §7.2 verification
- Optional local notification to the parent

---

## 8. THE USER JOURNEY

### Parent setup
1. Install on the child's device → onboarding funnel → parent + child names → age band
2. Pick apps to gate
3. Per-app rules: questions per lesson, minutes earned, daily cap
4. **Guided Shortcuts setup + verification** (§7.2)
5. Parent PIN
6. Paywall

### Child daily loop
1. Taps Roblox
2. `CheckLearningGateIntent` runs silently
3. **Balance remaining →** nothing happens, Roblox opens ✅
4. **No balance →** Nupo opens with the quiz (owl, ⭐⭐☆, 3 questions)
5. All correct → celebration → minutes granted → *"Open Roblox again 🎉"* (or auto-return, Tier 2)
6. Plays; time is consumed per §4.3
7. Balance exhausted → next open asks again

---

## 9. FIREBASE, REVENUECAT, SUBSCRIPTIONS

### Firebase phone auth (iOS)
- Upload an **APNs auth key** to Firebase (silent-push verification)
- Enable the **Push Notifications** capability
- Add the iOS bundle ID to the Firebase project
- **Test OTP on a real TestFlight build** — this fails silently in production if the APNs key is missing

### RevenueCat
- `purchases_flutter` / `purchases_ui_flutter` support iOS fully
- Needs a **separate App Store Connect subscription setup** mirroring Google Play (product IDs, pricing, subscription group) and an **App Store Connect API key**
- ⚠️ **No attribution integrations, no IDFA.** Match the Android posture.

✅ **See Appendix I:** entitlement identifier is `nupo Pro`; SDK keys, identity model, offline caching, paywall, and the remote kill-switch are documented there. (Exact Play Console product IDs / pricing tiers are still being finalized — mirror them into App Store Connect when set.)

---

## 10. APP STORE REVIEW

- **Kids Category / Guideline 1.3:** Apple may object to phone-number sign-in gating all functionality. Plan a parental gate before the OTP screen.
- **Privacy nutrition labels** must match the Android Data Safety declaration: parent's phone number + diagnostics only; **no** child data, **no** advertising identifiers, **no** tracking.
- **No ATT prompt.**
- **Demo account:** test phone number with fixed OTP + Pro entitlement granted manually in RevenueCat.
- **Explain the Shortcuts dependency in review notes** — otherwise a reviewer opens the app and sees nothing happen. Include what the automation does, how to create one, and a demo video.
- **Never claim tamper-proof blocking** in metadata (§5.4).

---

## 11. BUILD ORDER

### Phase 0 — Prove the mechanism (hard gate, ~1–2 days)
Do this before anything else. If it doesn't feel right, stop and reconsider.

1. Apple Developer Program enrollment as **InternSpirit Private Limited** ($99/yr)
2. Bare app exposing `CheckLearningGateIntent` + `OpenNupoGateIntent` (§3.2)
3. Hand-create the automation for one app
4. **Verify:** does the outer/inner pattern open Nupo only in the intervene case?
5. **Verify:** in the pass-through case, does the target app open with no visible Nupo? Any error banner?
6. **Verify:** what app-parameter type is available (§3.4 — case (a) or (b))?
7. **Verify:** does the **"Is Closed"** trigger exist and fire reliably (§4.3 Model B)?
8. **Verify:** does "Run Immediately" suppress all confirmation prompts?

### Phase 1 — Core loop
9. `GateEngine` with Model A wall-clock accounting (§4.3, §7.1)
10. Pending-gate staging + Flutter launch router (§7.3)
11. Full loop: gate → quiz → grant → pass-through → expiry
12. Tier 1 return flow (§3.3)

### Phase 2 — Port the Flutter app
13. Run existing Flutter app on iOS; safe areas, back-swipe, polish
14. **Port the v2 question engine (Appendix A2) to Dart + build the 10 question renderers** (§4A) — the largest net-new UI piece; don't ship the reduced `questions.dart` as the daily quiz
15. Wire the ported engine to the launch router; keep `questions.dart` for the onboarding demo gate
16. Port the onboarding funnel (Appendix H) — swap the 4-permission block for the Shortcuts wizard
17. Parent PIN, per-app rules, progress view (Appendices D/E/F)

### Phase 3 — Setup experience
18. Guided Shortcuts wizard + `shortcuts://` deep link (§7.2)
19. **Record the setup screen-recording asset**
20. Per-app verification flow
21. Gate health / re-verify (§7.4)

### Phase 4 — Refinement
22. Model B foreground-time accounting, if verified (§4.3)
23. Tier 2 auto-return for apps with known URL schemes (§3.3)

### Phase 5 — Commerce & ship
24. Firebase phone auth (APNs key, Push capability) — verify on TestFlight
25. RevenueCat + App Store Connect subscriptions
26. Privacy labels, demo account, review notes + demo video
27. TestFlight → App Store submission

---

## 12. APPENDICES (reconciled against the live codebase, 2026-07-24)

You have the Android repo (`brainpass/`), so these appendices are **maps + analysis, not verbatim dumps** — each cites the real file to read. The value here is the disposition (what ports, what's iOS-N/A, what moves to Swift), the platform gotchas, and answers the code alone doesn't make obvious (e.g. the timer semantics). Where an appendix shows code, the cited file is authoritative if they ever disagree.

- **A** — `questions.dart` in full (the reduced demo engine; used only by the onboarding gate)
- **A2** — ⭐ `Questions.kt` + `Gk.kt` in full (the **real** v2 engine — port THIS; see §4A)
- **B** — `lib/` inventory (PORTS AS-IS / NEEDS CHANGES / iOS N/A / MOVES TO SWIFT)
- **C** — Storage schema (every key: type, default, meaning)
- **D** — `AppRule` model
- **E** — ⭐ Timer semantics (highest-priority appendix)
- **F** — Parent PIN
- **G** — `safe_apps.dart` (preset list + safety blocklist)
- **H** — Onboarding inventory (what's actually built)
- **I** — RevenueCat config
- **J** — Firebase config (exactly what leaves the device)
- **K** — `pubspec.yaml` dependency list
- **L** — Design tokens + shared widgets

---

### Appendix A — the two question engines (which file to read)

| Engine | File | Role |
|---|---|---|
| **Reduced demo engine** | `brainpass/lib/questions.dart` | 3 kinds (keypad math, number pattern, MCQ GK), ~25 GK/band, 4 bands. **Used only by the onboarding demo gate (S21).** Ports to iOS as-is. |
| **⭐ Real v2 engine** | `brainpass/android/app/src/main/kotlin/com/brainpass/brainpass/Questions.kt` + `Gk.kt` | 10 interaction types, session arc + boss, ~180 GK cards, extra banks. **This is the daily kid experience — port THIS to Dart** (§4A). |

Don't retype either from this doc — read the files. This appendix exists to tell you **which** engine is which (the earlier drafts conflated them) and what the port entails; the structural analysis you need is in §4A and Appendix A2.

### Appendix A2 — ⭐ porting `Questions.kt` + `Gk.kt` to Dart

**Read the files** (`Questions.kt`, `Gk.kt`) as the source of truth. This appendix is the porting brief — the non-obvious bits and the pieces that need a Swift/Dart equivalent.

**Model types to port** (`Questions.kt` top): `enum QKind {KEYPAD, MCQ, TRUE_FALSE, ODD_ONE_OUT, COUNT, COMPARE, MATCH, ORDER, WORD, MEMORY}`; `Shape` (CIRCLE/SQUARE/STAR/HEART/TRIANGLE/DIAMOND/MOON); `Tile(shape, color, label, sticker?)`; and the `Q` data class (only the fields for a given `kind` are set — see the per-kind notes below). The tile palette is 7 bright colours (`0xFFFF7A7A` coral … `0xFFFF8FD1` pink).

**Per-kind generators** (all in `Questions.kt`, pure logic — copy the arithmetic exactly):
- `KEYPAD` = `generateMath` / `generatePattern` / `generateMissing` (the demo engine's `questions.dart` has identical math/pattern ranges, so those two are already Dart if you prefer to copy from there).
- `MCQ` = `generateGk` → `Gk.byBand(band)[pickFresh]`, options shuffled, answer = correct option **text**.
- `TRUE_FALSE` = banked facts **or** (bands B–D, ~50%) a generated math statement with the shown value perturbed by ±1/±2; answer is the string `"true"`/`"false"`.
- `ODD_ONE_OUT` = 4 tiles, odd differs by colour and/or shape; answer = odd index as string.
- `COUNT` = N identical tiles + 3 number choices.
- `COMPARE` = two cards (numbers / products / fractions by band); answer `"0"`=left, `"1"`=right.
- `MATCH` = 3 pairs → `left[]`, shuffled `right[]`, `matchMap[i]` = index in right.
- `ORDER` = 4 distinct band-range numbers shuffled; answer = ascending, joined by `","`.
- `WORD` = a `{word, clue}`; `letters` = shuffled chars (never == word); answer = word.
- `MEMORY` = show 3 distinct tiles, then probe with target + 2 unseen; `memoryAnswer` = index.

**Session arc** — `buildSession(band, count)`: first question from `easyKinds(band)`; middle from `kindsFor(band)` never repeating the previous kind; last flagged `boss=true` from `bossKinds(band)`. `regenerate(band, kind)` makes a same-kind replacement after a wrong answer. `isCorrect`: int-compare when both parse as int, else case-insensitive text.

**Two things that need an iOS equivalent (the only non-mechanical bits):**
1. `EnginePrefs.pickFresh(ctx, bucket, poolSize)` — the no-repeat picker (banks GK/TF/match/word). Reimplement in Dart/`GateEngine` with a `UserDefaults`-backed recent-index list per bucket (`recent_<bucket>`, e.g. `gk_B`), remembering `min(poolSize/2, 20)`.
2. **Tile rendering** — Android's `LockUi.kt` draws the `Shape`s on a `Canvas`. On iOS, render them with a Flutter `CustomPainter` (or bundled SVG/PNG). Keep the `Tile.sticker` hook: if `assets/stickers/<name>.png` exists, show that image instead of the drawn shape.

**Banks (data — copy verbatim from the files, do NOT invent):**
- `Gk.kt` — ~180 `GkCard(prompt, options, correctIndex)` across `bandA/B/C/D` (~45 each). Correct answer at the listed index; engine shuffles at display. Intentionally India-inclusive (national bird/animal, Diwali/Holi, Taj Mahal, New Delhi, Ganga, Gandhi, Bengaluru) alongside global science/geo/math.
- `Questions.kt` banks: `tfA–tfD` (14 true/false facts each), `pairsA–pairsD` (match pairs), `wordsB/C/D` (word-builder words + clues; band A reuses band B's list).

> These banks are curated and age-tuned. Port them 1:1 from `Gk.kt` / `Questions.kt`. Substituting your own questions will de-tune the age bands and lose the India content.

---

### Appendix B — `lib/` inventory

| File | iOS disposition |
|---|---|
| `main.dart` | **NEEDS CHANGES** — RootRouter (login→onboarding→paywall→home) ports; the Android `syncToEngine()` (pushes rules/PIN to native guard) becomes "write gate state via `GateEngine` MethodChannel." Remove `Engine.startGuard()`. |
| `theme.dart`, `widgets.dart` | **PORTS AS-IS** (Appendix L) |
| `screens/onboarding/*` (funnel) | **PORTS AS-IS** — see Appendix H |
| `screens/splash_screen.dart` | PORTS AS-IS |
| `screens/login/login_flow.dart`, `reauth_delete_screen.dart` | PORTS AS-IS (Firebase phone auth works on iOS; §9) |
| `screens/pin_create_screen.dart`, `pin_entry_screen.dart`, `pin.dart` | PORTS AS-IS (Appendix F) |
| `screens/age_band_screen.dart`, `app_picker_screen.dart`, `app_rules_screen.dart` | **NEEDS CHANGES** — app picker uses `installed_apps` (no iOS equivalent, Appendix K); replace with the preset list + the Shortcuts-setup wizard (§7.2). Rules/age screens port as-is. |
| `screens/parent_home_screen.dart` | **NEEDS CHANGES** — replace live per-app `Engine.appStatus` polling with `GateEngine` balances; "Permissions" row → "Automations health" (§7.4). |
| `screens/permission_step.dart`, `permissions_screen.dart` | **iOS N/A** — the 4 Android permissions don't exist; replaced by the Shortcuts wizard. |
| `screens/paywall_gate_screen.dart` | PORTS AS-IS (RevenueCat `PaywallView`; §9) |
| `storage.dart` | **NEEDS CHANGES** — parent config stays in `shared_preferences`; gate/timer state (rem/used/cap counters) **MOVES TO SWIFT `GateEngine`** (§6.3). Appendix C. |
| `engine.dart` | **MOVES TO SWIFT** — this is the Android `MethodChannel('brainpass/engine')` wrapper; replace with the iOS `GateEngine` channel (evaluate/grant/stage/balances/canOpenURL). |
| `questions.dart` | PORTS AS-IS (demo gate) **+** add the A2 engine for the real quiz. |
| `safe_apps.dart` | **NEEDS CHANGES** — preset list ports; the Android package blocklist becomes iOS intent. Appendix G. |
| `auth_service.dart`, `profile_service.dart`, `remote_config_service.dart`, `subscription_service.dart` | PORTS AS-IS (all Firebase/RevenueCat; §9, Appendix I/J) |
| `android/.../*.kt` (Guard/Watchdog/Autostart/Boot/Overlay/PermissionReturn/LockUi) | **iOS N/A** — no foreground service, overlay, or OEM logic on iOS. Only `Questions.kt`/`Gk.kt` content survives, as the Dart port. |

---

### Appendix C — Storage schema

**Parent config — `shared_preferences` (`Storage`), ports to iOS `UserDefaults` (keys get `flutter.` prefix — §6.3):**

| Key | Type | Default | Meaning |
|---|---|---|---|
| `pinHash`, `pinSalt` | String | — | salted SHA-256 parent PIN (Appendix F) |
| `ageBand` | String | `"b"` | `a/b/c/d` |
| `gatedApps` | StringList | `[]` | package names the parent gated |
| `appRules` | String (JSON) | `{}` | `{ "<pkg>": {q,m,c} }` (Appendix D) |
| `masterEnabled` | bool | `true` | global on/off |
| `onboardingComplete` | bool | `false` | routes past onboarding |
| `parentName`, `childName` | String | `""` | **local only, never transmitted** |
| `childAge` | int | `8` | drives shock-stat + band |
| `screenHours` | double | `0` | onboarding estimate (shock stat) |
| `onbGoals`, `onbTried` | StringList | `[]` | survey multi-selects |
| `onbVibe`, `owlName`, `onbCommitment`, `onbAttribution` | String | (owl→`"Nupo"`) | survey answers |
| `onbReachApps` | StringList | `[]` | pre-selects the app picker |

**Gate/timer runtime — Android `EnginePrefs` (`brainpass_engine.xml`); on iOS this MOVES TO SWIFT `GateEngine`:**

| Key pattern | Type | Meaning |
|---|---|---|
| `rem_<pkg>` | Long ms | earned-but-unused **active** time remaining (Appendix E) |
| `used_<pkg>` | Long ms | active ms used today |
| `capx_<pkg>` | Int min | extra daily-cap minutes granted by a parent override today |
| `q_<pkg>` / `min_<pkg>` / `cap_<pkg>` / `name_<pkg>` | Int/String | per-app rule mirror (pushed from Flutter) |
| `dayStamp` | String | `"Y-M-D"` local; triggers midnight reset |
| `recent_<bucket>` | String (CSV) | no-repeat indices for `pickFresh` (Appendix A2) |
| `gatedApps`, `masterEnabled`, `ageBand`, `pinHash`, `pinSalt` | — | native mirror of parent config |

---

### Appendix D — `AppRule` model

```dart
class AppRule { final int questions; final int minutes; final int cap; // cap: daily-cap MINUTES, 0 = none
  const AppRule({this.questions = 3, this.minutes = 15, this.cap = 0}); }
```
- **Per-app, nothing shared.** Keyed by package name in the `appRules` JSON (`{q,m,c}`).
- Defaults: 3 questions → 15 minutes, no daily cap.
- Ranges in the UI: questions 1–10, minutes 1–60, cap 15–180 (step 15) when enabled.
- `reconcileRules()` gives every gated app a default rule and drops rules for un-gated apps.

---

### Appendix E — ⭐ Timer semantics (verified against `GuardService.kt` + `EnginePrefs.kt`)

Answers to the §4.1 questionnaire, from the actual Android code:

1. **Foreground-time or wall-clock?** **Foreground/active time.** Minutes burn only while the gated app is the foreground app. `GuardService` ticks once per second **only when the screen is on** (`ACTION_SCREEN_ON/OFF` gates the loop), and each tick calls `EnginePrefs.consume(pkg, delta)` where `delta` is the ms since the last tick, **clamped to [0, 2000]**. So the UI claim "minutes only count while the app is open" is literally true.
2. **Granularity & persistence.** 1 s tick; `delta` clamped 0–2000 ms. Remaining time persisted **immediately every tick** to `rem_<pkg>` (Long ms); used time to `used_<pkg>`. (iOS must likewise persist on every change — the intent process is short-lived.)
3. **Switch away mid-session?** **Pauses.** When `currentForegroundApp()` isn't the tracked gated app, no `consume` happens. Re-entering resumes. There is a one-tick re-arm: on switching *into* a gated app, that first tick sets `trackedPkg` and consumes nothing (so no double-charge across the transition).
4. **Grace period?** None beyond the 2000 ms per-tick clamp (which quietly absorbs brief scheduler hiccups).
5. **Midnight rollover.** `rollDayIfNeeded()` compares a `"YEAR-MONTH-DAY"` stamp in **device local time**; on change it clears all `rem_`, `used_`, and `capx_` keys. (`Calendar.getInstance()` default TZ.)
6. **Daily cap.** **Per-app.** `capMs = (cap + capx) × 60000`; `capReached` when `used ≥ capMs`. When hit, the next open shows the **"all done for today"** lock mode (`"done"`), not a quiz. A parent PIN override adds one block to both `rem_` and the cap (`capx_`) for that day.
7. **Reboot mid-session.** Counters live in `SharedPreferences` (disk), so `rem_`/`used_` survive reboot; `BootReceiver` restarts the guard. Earned time is preserved. (iOS: `UserDefaults` survives reboot; no service to restart — the next automation just reads the balance.)
8. **Per-app or shared minutes?** **Per-app.** Every counter is keyed by package; nothing is pooled across apps.

**iOS implication (confirms §4):** Model A (wall-clock `expiresAt`) is a *behavioural regression* from this — Android pauses when the child leaves the app; wall-clock does not. Model B (the `Is Closed` automation → `consume(elapsed)`) reproduces items 1 & 3 above. Ship A, plan B, keep the accounting behind one `GateEngine` interface. The daily-cap (item 6) and midnight reset (item 5) must be enforced in `GateEngine.evaluate()` regardless of model.

---

### Appendix F — Parent PIN

- 4-digit PIN, entered twice on create. **Never stored raw.** `salt = 16 random bytes (hex)`; `hash = SHA-256("<salt>:<pin>")` hex. Stored as `pinHash` + `pinSalt`. A fresh salt is generated on every set/change.
- Verify: recompute `SHA-256("<salt>:<pin>")` and compare (`pin.dart` `verify`, mirrored in Kotlin `EnginePrefs.verifyPin`). **Keep this exact scheme in the iOS `GateEngine`** so a PIN set in Flutter verifies natively.
- **Bypass behaviour (Android):** a correct PIN on the kid lock grants a *free, untimed* session for that app (`freePkg`) that lasts only while the app stays foreground — no chip, no consumption. On iOS there's no lock screen to type a PIN into during a gate; the PIN protects **parent settings** and the "skip this lesson / grant time" actions. Map the "skip a lesson" affordance into the quiz UI (parent taps a small lock icon → PIN → grant one block or bypass once).
- The PIN also gates the whole parent dashboard and account actions (sign out, delete, subscription).

---

### Appendix G — `safe_apps.dart`

**Preset gateable apps (`kPresetGateableApps`) — the 7 shown first in the picker:**

| Display name | Android package |
|---|---|
| YouTube | `com.google.android.youtube` |
| YouTube Kids | `com.google.android.apps.youtube.kids` |
| Instagram | `com.instagram.android` |
| TikTok | `com.zhiliaoapp.musically` |
| Snapchat | `com.snapchat.android` |
| Roblox | `com.roblox.client` |
| Subway Surfers | `com.kiloo.subwaysurf` |

**Safety blocklist (`isGateable` returns false) — NEVER gateable:** own app (`app.nupo.kid`); dialers (`*dialer`, `*.phone`, `telecom`, `incallui`); SMS/messaging (`*messaging`, `.mms`, `.sms`); contacts; clock/alarm (`deskclock`, `clockpackage`); settings (`.settings`); emergency/safety (`emergency`, `safetyhub`). Enforced by exact-match set + substring patterns. **iOS parallel:** never help a parent gate Phone, Messages, FaceTime, Clock, Settings, or Emergency SOS — a child must always be able to call for help (this is also an App Review expectation).

**Category tags & real icons:** Android shows each app's real launcher icon via `installed_apps` + `AppBrandIcon` (branded-glyph fallback). **iOS cannot enumerate installed apps or fetch their icons** — use the preset names + bundled brand glyphs, and let Apple's Shortcuts picker handle "any other app."

---

### Appendix H — Onboarding inventory (what's actually BUILT)

The onboarding was rebuilt from `nupo_onboarding_spec.md` and **is live** in `lib/screens/onboarding/` (~31 one-tap steps). It is **not** the "38 screens spec" referenced earlier — this is the shipped reality. All of it **PORTS AS-IS** to iOS (pure Flutter), except the permissions block (see below).

**Flow order (each a screen):** hook (4 swipe cards incl. the "6 × 7?" micro-aha) → parent name → child name → diagnostic intro → child age → screen-time estimate → **shock → reframe → hope** (computed stat) → goals (multi) → mirror (plays top goal back) → vibe → tried-before → why-built → reach-apps → building-plan animation → **demo gate intro → real 3-question gate (uses `questions.dart`) → payoff** → meet-owl (collectible card) → name-the-owl → 30-day projection → commitment → validation → **app picker → app rules → PIN create → permissions intro → [4 permission steps] → attribution → why-it-works → finish**.

**iOS changes to the funnel:**
- The **"permissions intro + 4 permission steps"** (overlay/usage/battery/autostart) are **iOS N/A**. Replace that single stretch with: a Screen-Time-free **Shortcuts setup wizard** (§7.2) — set up + verify one app, then offer more.
- Files: `onboarding_flow.dart` (orchestrator, has a step-count `assert`), `onb_widgets.dart` (OnbScaffold / StatementScreen `brand:` purple variant / Single-&MultiChoiceScreen / NameInputScreen), `hook_screen.dart`, `survey_screens.dart`, `building_screen.dart`, `demo_gate_screen.dart`, `owl_screens.dart`.
- Survey answers are **local-only**; only `attribution` may be sent to Firestore (§7/J). Child's name threads through copy via `Storage.childNameOr()`.
- The shock stat is computed honestly: `screenHours × 365 × (15 − childAge)`, floored to the nearest 100, never inflated. No fabricated statistics anywhere (a hard content rule).

---

### Appendix I — RevenueCat config

- **Entitlement identifier:** `nupo Pro` (exact string, with the space — RootRouter checks `entitlements.active["nupo Pro"]`).
- **SDK keys (Android, for reference):** debug uses the **RevenueCat Test Store** key `test_qKnEaBphbeAGpRQcgmVISKWcKSr` (simulated purchases); release uses `goog_SaVnrVeaftKhPExZSaDnCslpYCp`. **iOS needs its own `appl_…` public key** + an **App Store Connect App-Store Connect API key** wired into RevenueCat.
- **Identity:** `Purchases.logIn(firebaseUid)` — subscription follows the parent's account across devices/reinstalls.
- **Offline-first:** last-known entitlement cached in `shared_preferences` (`nupo_has_pro`); the kid gate never depends on a live check.
- **Paywall:** rendered by RevenueCat's `PaywallView` (dashboard-designed), shown by `PaywallGateScreen` as a **hard gate** after login+onboarding until `nupo Pro` is active. "Restore purchases" + Customer Center wired.
- **Products/pricing:** 🔧 not yet finalized in Play Console — mirror whatever ships there into an App Store Connect subscription group with matching product IDs. **No attribution integrations, no IDFA** (match Android).
- **Remote kill-switch:** `RemoteConfigService` reads Firestore `config/app.paywallEnabled` (bool). When false, the paywall is skipped for everyone (used while a processor is verified). Fail-safe default: **not** enforced. Port as-is.

---

### Appendix J — Firebase config (exactly what leaves the device)

- **Auth:** Firebase **phone OTP**, mandatory parent gate (`auth_service.dart`). Flow: enter E.164 number → `verifyPhoneNumber` (60 s timeout, supports on-device auto-verify) → 6-digit code → `signInWithCredential`. Errors mapped to parent-friendly copy. Re-auth path for account deletion (`requires-recent-login`).
  - **iOS extra work (§9):** upload an **APNs auth key** to Firebase, enable the **Push Notifications** capability, add the iOS bundle ID. **Test OTP on a real TestFlight build** — it fails silently in production if the APNs key is missing.
- **Firestore writes — the ONLY data that leaves the device:**
  - `users/{uid}` (via `profile_service.dart`, fire-and-forget, offline-queued): `phoneNumber`, `lastActive`, `appVersion`, device `model`/`manufacturer`/`androidVersion` (→ iOS model/OS), `ageBand`, `gatedAppsCount`, `onboardingComplete`, `createdAt` (once), and `attribution` **if set**. **No child name, no survey answers, no question data.**
  - `config/app` read-only (paywall kill-switch, Appendix I).
- **Privacy posture (non-negotiable, §1):** child data stays on-device; no analytics/ad/attribution/crash SDKs; no IDFA; never call `ATTrackingManager`.

---

### Appendix K — `pubspec.yaml` dependencies (iOS compatibility)

| Package | iOS? | Note |
|---|---|---|
| `shared_preferences ^2.5.5` | ✅ | `UserDefaults`; **`flutter.` key prefix** (§6.3) |
| `crypto ^3.0.7` | ✅ | PIN hashing |
| `firebase_core / firebase_auth / cloud_firestore` | ✅ | phone auth needs APNs key + Push capability (§9/J) |
| `purchases_flutter / purchases_ui_flutter ^10.4.0` | ✅ | needs iOS `appl_` key + ASC products (Appendix I) |
| `video_player ^2.11.1` | ✅ | onboarding/setup clips; iOS uses AVPlayer |
| `material_symbols_icons ^4.2951.0` | ✅ | icon font |
| `cupertino_icons ^1.0.8` | ✅ | already present |
| **`installed_apps ^2.1.1`** | ❌ | **NO iOS equivalent** — can't list installed apps. Remove; use preset list + Shortcuts picker (Appendix G, §7.2). This is the only hard-incompatible dependency. |
| Fonts | ✅ | bundle Nunito 400/600/700/800/900 (already in `assets/fonts/`) — **not** `google_fonts` |

App version: `1.0.0+2`. Assets: `assets/icon/nupo.png`, `mascot_opening.png`, `mascot_pin.png`, `assets/videos/`.

---

### Appendix L — Design tokens & shared widgets (`theme.dart`, `widgets.dart`) — PORTS AS-IS

- **Colours:** §1 table. Background is a soft purple→white vertical gradient (`bgDecoration`). One soft shadow under every card; 24 px card radius, 1.5 px `#ECE9F8` hairline border.
- **Type (Nunito):** `display` 32/w900, `title` 26/w900, `cardTitle` 16/w800, `body` 15/w600 muted, `caption` 12.5/w700, `overline` 12/w900 tracked.
- **Shared widgets to reuse (don't reinvent):** `NupoTopBar` (+`ProgressDots`, and `SlimProgressBar` when total > 8), `PrimaryButton` (gradient pill + glow — the ONLY CTA style), `HaloMascot` (owl on yellow halo + sparkles — hero treatment), `IconBadge`, `InfoPill`, `SelectCard`, `IntStepper`, `PinBoxes`/`PinPad`, `StepScaffold`, `SetupVideoCard` (renders `assets/videos/<key>.mp4`, hides if absent — reuse for the iOS Shortcuts how-to clip), `AppBrandIcon` (**Android-only real-icon fetch — on iOS fall back to the branded glyph path**).
- Theme uses Material 3 + filled icon style (`IconThemeData(fill: 1, weight: 600)`). Keep the parent UI calm/premium; keep the kid quiz bright.

---

## 13. OPEN DECISIONS

1. **Question engine scope for iOS v1** (§4A) — port the full 10-kind v2 engine (matches Android, but ~10 new Flutter renderers + tile/Canvas work), or ship a subset (e.g. keypad/MCQ/true-false/odd-one-out) first and add the rest later? **Recommendation: port the full engine — it's the product's core delight and the reason kids don't quit.** Don't ship the 3-kind `questions.dart` as the daily quiz.
2. **Model A or B at launch** (§4.3) — ship wall-clock, or wait for verified foreground accounting? (Appendix E shows Android is foreground-time, so B is the faithful match.)
3. **Age-band scope** — four bands ship on Android (A 5–6, B 7–8, C 9–10, D 11). Ship all four on iOS, or aim v1 at 5–10 and leave band D to Android where enforcement is real?
4. **Setup gating** — force one verified app (Shortcuts automation) before the paywall, or allow skip-and-nag?
5. **Screen Time backstop** — filing the Family Controls entitlement is free and takes weeks. Worth filing now purely to keep the tamper-proof option open later?

---

## 14. REFERENCES

- App Intents overview — https://developer.apple.com/documentation/appintents
- Get to know App Intents (WWDC25) — https://developer.apple.com/videos/play/wwdc2025/244/
- Bring your app's core features to users with App Intents (WWDC24) — https://wwdcnotes.com/documentation/wwdcnotes/wwdc24-10210-bring-your-apps-core-features-to-users-with-app-intents/
- **`openAppWhenRun` cannot be dynamic; use the outer/inner pattern** — https://developer.apple.com/forums/thread/723623
- Opening an app conditionally with App Intents — https://developer.apple.com/forums/thread/740707
- Cannot create an automation programmatically — https://developer.apple.com/forums/thread/713012
- Cannot pause/disable an automation programmatically — https://developer.apple.com/forums/thread/744698
- Intro to personal automation — https://support.apple.com/guide/shortcuts/apd690170742/ios
