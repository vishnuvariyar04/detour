# Nupo — iOS Build Specification
### Architecture: App Intents + Shortcuts Personal Automations

> **Status:** v3 — architecture verified against Apple docs and developer forums. This supersedes earlier drafts that proposed the Screen Time API (wrong: can't open your app from a shield) and a URL-scheme approach (wrong: forced a curated app list and caused a visible flash).
>
> **Audience:** An iOS developer with a Mac + iPhone and **no prior context** on this project. Read §1–§4 before writing code.
>
> **Companion docs:** the Android build spec, the onboarding spec, the marketing/positioning brief.

---

## 0. HOW TO USE THIS DOCUMENT

**If you are Claude Code (editing this file):** fill every `🔧 TO BE FILLED BY CLAUDE CODE` block from the actual Flutter/Kotlin codebase. Add detail; don't change the architecture in §3.

**If you are the iOS developer:** read §1 (product), §2 (why it's not a port), §3 (architecture), §4 (the timer — the part most likely to be got wrong). §11 Phase 0 is a hard gate: prove the mechanism on a real device before building anything else.

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

### Brand
| Token | Hex |
|---|---|
| Primary purple | `#8B3DEC` |
| Deep purple (text) | `#2C1A4D` |
| Sunny yellow | `#FFCE3A` |
| Soft lilac (bg) | `#F3ECFE` |
| Cream | `#FFFCF4` |

Mascot: a friendly purple owl named **Nupo**. Fonts: **Fredoka** (display), **Plus Jakarta Sans** (body).

### Age bands
| Band | Ages | Content |
|---|---|---|
| A | 5–7 | Counting & simple sums |
| B | 8–10 | Mental math & general knowledge |
| C | 11–13 | Logic puzzles & tricky questions |

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

| App | Android package | Candidate iOS scheme | Verified? | Notes |
|---|---|---|---|---|
| YouTube | `com.google.android.youtube` | `youtube://` | ☐ | |
| YouTube Kids | `com.google.android.apps.youtube.kids` | ? | ☐ | may have none |
| Roblox | `com.roblox.client` | `roblox://` | ☐ | |
| Instagram | `com.instagram.android` | `instagram://` | ☐ | |
| TikTok | `com.zhiliaoapp.musically` | `snssdk1233://` / `tiktok://` | ☐ | region-dependent |
| Snapchat | `com.snapchat.android` | `snapchat://` | ☐ | |
| WhatsApp | `com.whatsapp` | `whatsapp://` | ☐ | likely never gated |
| Subway Surfers | `com.kiloo.subwaysurf` | ? | ☐ | most games have none |
| Minecraft | — | `minecraft://` | ☐ | |
| Netflix | — | `nflx://` | ☐ | |

> Most **games** have no public URL scheme. Expect Tier 1 to be the real path for a meaningful share of gated apps — design the Tier 1 success screen to feel good, not like a degraded fallback.

🔧 **TO BE FILLED BY CLAUDE CODE:** cross-reference this table against `safe_apps.dart` and add every app in the Android curated list.

### 3.4 The App parameter (`GatedAppEntity`)
🔧 **VERIFY IN PHASE 0 — this is the one genuinely open technical question.**

The Shortcuts action needs an app-picker parameter. Determine which is true on the target iOS version:
- **(a)** Apple provides a system app-entity type usable as an `@Parameter` — ideal, gives every installed app.
- **(b)** No such type exists, so define your own `AppEntity` backed by a bundled list of common kids' apps, with an `EntityQuery` for search.

If **(b)**, the *automation trigger* still uses Apple's full picker (so the gate fires for any app); only the *parameter* is limited. Mitigate by shipping a generous list plus a "Something else" catch-all that gates generically.

🔧 **TO BE FILLED BY CLAUDE CODE:** dump `safe_apps.dart` (display names, package names, categories, icon assets) as the seed list for case (b).

---

## 4. ⭐ THE TIMER MODEL (get this exactly right)

This is the part most likely to be built wrong. It must behave the way Android does.

### 4.1 Android's current semantics
The Android "App rules" screen states: **"Minutes only count while the app is open."** Earned minutes are consumed as **foreground time in the gated app**, not wall-clock. Put the phone down for an hour with 12 minutes left, and you still have 12 minutes.

🔧 **TO BE FILLED BY CLAUDE CODE — required before implementation:**
> Read `GuardService.kt` and `EnginePrefs.kt` and document precisely:
> - Is the countdown foreground-time or wall-clock? (Confirm the UI claim.)
> - Tick granularity and where remaining time is persisted (key names, types).
> - Behaviour when the child switches away mid-session — pause, or keep running?
> - Grace period, if any, for brief app switches.
> - Midnight rollover: how is the daily counter reset, in what timezone?
> - Daily cap: enforced per-app or globally? What happens when hit?
> - Behaviour on device reboot mid-session.
> - Are earned minutes per-app or shared across all gated apps?

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
- **The onboarding funnel** (see the onboarding spec — 38 screens)
- **The quiz UI** — owl, ⭐⭐☆, question card, keypad, celebration
- **`questions.dart`** — the question engine, pure Dart, zero OS dependency
- **`ParentHomeScreen`**, app rules, PIN entry, progress view, paywall
- **The guided Shortcuts setup wizard** (§7.2)
- **`shared_preferences`**, **`crypto`**, **`video_player`**, **`material_symbols_icons`**

Minor work only: safe areas, iOS back-swipe, native polish.

> 🎉 **`questions.dart` does NOT need a Swift duplicate.** On Android, `Questions.kt` / `Gk.kt` exist because the overlay renders in a separate native process. On iOS the quiz renders *inside Nupo*, in Flutter — so Dart is the single source of truth for questions. One less thing to keep in sync.

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

🔧 **TO BE FILLED BY CLAUDE CODE:** paste `questions.dart` in full into Appendix A; produce a `lib/` inventory marking each file **PORTS AS-IS / NEEDS CHANGES / iOS N/A / MOVES TO SWIFT**.

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

🔧 **TO BE FILLED BY CLAUDE CODE:** exact Play Console product IDs, base plans, pricing tiers, and the RevenueCat entitlement identifier.

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
14. Wire `questions.dart` to the launch router
15. Parent PIN, per-app rules, progress view

### Phase 3 — Setup experience
16. Guided Shortcuts wizard + `shortcuts://` deep link (§7.2)
17. **Record the setup screen-recording asset**
18. Per-app verification flow
19. Gate health / re-verify (§7.4)

### Phase 4 — Refinement
20. Model B foreground-time accounting, if verified (§4.3)
21. Tier 2 auto-return for apps with known URL schemes (§3.3)

### Phase 5 — Commerce & ship
22. Firebase phone auth (APNs key, Push capability) — verify on TestFlight
23. RevenueCat + App Store Connect subscriptions
24. Privacy labels, demo account, review notes + demo video
25. TestFlight → App Store submission

---

## 12. 🔧 APPENDICES TO BE FILLED BY CLAUDE CODE

The iOS developer has no access to the Android repo.

- **A. `questions.dart` in full** — generators, age-band logic, GK banks, answer validation
- **B. `lib/` inventory** — PORTS AS-IS / NEEDS CHANGES / iOS N/A per file
- **C. Storage schema** — every `EnginePrefs` / `shared_preferences` key: type, default, meaning
- **D. `AppRule` model** — fields, defaults, keying, persistence
- **E. ⭐ Timer semantics** — the full §4.1 questionnaire. **Highest priority appendix.**
- **F. Parent PIN** — hashing/salting, storage, bypass behaviour
- **G. `safe_apps.dart`** — full list, for the §3.4 case (b) fallback
- **H. Onboarding inventory** — built vs spec'd-but-unbuilt
- **I. RevenueCat config** — product IDs, entitlement identifier, base plans, pricing
- **J. Firebase config** — auth flow, Firestore writes, exactly what leaves the device
- **K. `pubspec.yaml`** — full dependency list, each marked iOS-compatible / needs replacement

---

## 13. OPEN DECISIONS

1. **Model A or B at launch** (§4.3) — ship wall-clock, or wait for verified foreground accounting?
2. **Age-band scope** — is iOS v1 aimed at 5–10, leaving 11–13 to Android where enforcement is real?
3. **Setup gating** — force one verified app before the paywall, or allow skip-and-nag?
4. **Screen Time backstop** — filing the Family Controls entitlement is free and takes weeks. Worth filing now purely to keep the tamper-proof option open later?

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
