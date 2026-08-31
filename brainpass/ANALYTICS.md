# Reading Nupo's analytics

Added 2026-08-31. Before this the app shipped with no analytics, so the only
number available was Play Console's **installed audience** — how many devices
currently have Nupo — which says nothing about what those people did.

**This guide is the ANDROID app.** iOS runs its own analytics — Firebase
Analytics plus PostHog (US region, manual events only, no session replay or
autocapture) — wired separately in the iOS project. The two do not share event
names, so do not assume a funnel built here reads the same there.

Two files define everything: `lib/analytics.dart` (parent app) and
`android/app/src/main/kotlin/com/brainpass/brainpass/Analytics.kt` (the kid's
lock). Each event has a comment saying why it exists. **Read those before
adding anything**, and see "Rules" at the bottom.

---

## Before any of this works

1. **Firebase console → Analytics** must be enabled for project `nupo-e6a13`
   (it is created automatically with the linked GA4 property; check
   Project settings → Integrations → Google Analytics shows a property).
2. Ship a build containing this code. Data starts from that build's rollout —
   it is **not** backfilled, so the first useful funnel is a week after
   release, and the first D7 retention number is a week after that.
3. Mark `setup_complete` as a **key event** (Admin → Events → toggle "Mark as
   key event"). That makes it the conversion GA4 reports against by default.
4. **Register the custom dimensions — do this BEFORE shipping.** This is the
   step everyone misses. GA4 collects every event parameter but will not show
   one in any report until it is registered, and **registration is not
   retroactive**: parameters recorded before you register them are lost to the
   UI forever. Without this, `login_failed` is a number with no reason attached
   and the funnel cannot be broken down at all.

   Admin → Custom definitions → Create custom dimension, scope **Event**, one
   per parameter:

   | Parameter | Why you need it |
   |---|---|
   | `reason` | WHICH sign-in failure. The whole point of `login_failed`. |
   | `method` | google vs email |
   | `permission` | which of the four permissions lost them |
   | `step_name` | the onboarding funnel steps |
   | `step_index` | keeps those steps in order |
   | `app` | which gated app a lesson fired for |
   | `mode` | lesson vs daily-cap-spent |
   | `wrongs` | how hard the demo question is |
   | `count`, `minutes`, `target`, `enabled` | the numeric ones |

   Then scope **User**, for the properties set in `analytics.dart`:
   `age_band`, `subject`, `apps_gated`, `has_pro`, `setup_done`,
   `signin_method`, `perm_overlay`, `perm_usage`, `perm_battery`,
   `perm_autostart`.

5. **Change data retention from 2 months to 14.** Admin → Data settings → Data
   retention → "14 months", and turn on "Reset user data on new activity". The
   default of 2 months silently destroys the exploration data behind any
   D30 cohort you try to read later.
6. **Turn on the BigQuery export** (Admin → BigQuery links; the sandbox tier is
   free). Everything in "Where this goes blind" below is answerable with SQL
   and unanswerable in the GA4 UI. Like everything else here it only captures
   data from the day you switch it on, so switch it on now even if you never
   write a query.

While testing on your own phone, use **DebugView** — events appear within
seconds instead of the usual up-to-24-hour delay:

```
adb shell setprop debug.firebase.analytics.app app.nupo.kid
```

Turn it off again with `adb shell setprop debug.firebase.analytics.app .none.`

---

## The funnel, in order

Every step below is one event. A parent should pass through all of them; the
biggest percentage drop between two adjacent rows is what to fix next.

| # | Event | Means |
|---|-------|-------|
| 1 | `first_open` (automatic) | Installed and opened |
| 2 | `story_shown` | The scroll story painted |
| 3 | `story_started` | Tapped "Get started" |
| 4 | `story_app_picked` | Passed gate 1 (picked their kid's app) |
| 5 | `story_answered` | Passed gate 2 (answered the demo question) |
| 6 | `story_finished` | Tapped the closing CTA |
| 7 | `login_shown` | Reached the **mandatory** sign-in gate |
| 8 | `login_attempt` | Tapped Google or submitted email |
| 9 | `login_success` | Got an account |
| 10 | `onb_step` × 11 | The 7 questions + picker, rules, PIN, permissions intro |
| 11 | `permission_shown` / `_granted` | Per permission: overlay, usage, battery, autostart |
| 12 | `setup_complete` | **Activation.** The engine has rules and is gating |
| 13 | `paywall_shown` → `purchase_completed` | Money — dormant while Android is free |

Step 13 will stay empty for now: Android is free, and the paywall sits behind
the `paywallEnabled` kill-switch in `remote_config_service.dart`, which defaults
to off. The events are wired and will start reporting the day you turn it on.

To build it: **Explore → Funnel exploration**, add each event as a step. For
step 10 use one step per `step_name` value (`child_name`, `child_age`, ...) —
they are parameter values on a single `onb_step` event, so the funnel does not
burn eleven event names.

### The two places people actually die

**`login_shown` → `login_success`.** Sign-in is mandatory and everything after
it is invisible if it fails, which is exactly how 1.1.x hard-blocked every
country missing from its phone-number list without a single signal. Watch
`login_failed` broken down by its `reason` parameter and by country: a reason
code that appears in one country only is a market locked out, not a user
problem. `operation-not-allowed` specifically means the provider is switched
off in the Firebase console.

**`permission_shown` → `permission_granted`, per permission.** This is the
steepest cliff in any Android parental-control app. `permission_requested`
fires when they tap the button that opens system settings; a wide gap between
that and `permission_granted` means they got lost inside the OEM's settings and
never found the toggle. `permission_skipped` only exists for battery.

---

## Retention

**Do not read retention from the parent app.** A family using Nupo perfectly
never opens it again after setup — the lock is native, so the Flutter app is
just a settings screen. GA4's built-in Retention report is driven by app opens
and will therefore under-report the truth badly.

Use **`kid_active_day`** instead. It fires from the guard service at most once
per calendar day, the first time a lesson is shown, and means "this family used
Nupo today".

- **D1 / D7 / D30**: Explore → **Cohort exploration**. Inclusion =
  `first_open`, Return criteria = `kid_active_day`, granularity Daily,
  and read columns 1, 7 and 30.
- **Daily actives**: event count of `kid_active_day`.
- **Is the product working?** Ratio of `lesson_earned` to `lesson_shown`. A low
  ratio means kids are giving up — the questions are too hard for the band.
- **Is the gate annoying the parent?** Rate of `parent_override` (they typed
  the PIN to skip the lesson). That is churn one step early.
- **Silent death**: `overlay_missing`. The app is installed, configured, and
  doing nothing because the overlay permission was revoked — by the parent or
  by the OEM. These families are churning and do not know why.

---

## Where this goes blind

Firebase Analytics answers "where in MY APP did they fall off". Everything
outside that sentence is a gap. The honest list:

**Before the install, nothing exists.** The SDK's first event is `first_open`,
so store impressions → listing views → installs are invisible here. That funnel
lives in **Play Console → Acquisition → Store performance**, and at your volume
it is the bigger lever: a listing that converts 3% instead of 1% triples
everything downstream. Check it there, not here.

**No attribution, by design.** The advertising id is stripped for Play Families
compliance, so GA4 cannot tell you which campaign, post, or link produced an
install. Play Console's coarse acquisition channels (organic search / explore /
third-party) are all you get. If you ever run paid acquisition, this is the
thing you will have to solve, and it is a genuine cost of the child-safe
configuration — not an oversight.

**Uninstalls are weak.** Android sends `app_remove`, but it is delayed and
unreliable, and no analytics tool can tell you WHY. Play Console's installed
audience is the better churn number.

**No per-user drill-down.** GA4 aggregates. You cannot pull up one family and
watch their sequence of events, which at ten installs is exactly what you want
to do. `user_id` is set to the Firebase uid, so this IS answerable — but only
through the BigQuery export, with SQL. That is the main thing PostHog would
give you out of the box.

**Sessions are wrong for the kid side.** `kid_active_day` and the other lesson
events fire from the guard service with no foreground Activity, so they do not
open a GA4 session. Read them as **event counts and cohorts**, never through
session-scoped or "engaged users" metrics, which will under-count them.

**Latency.** Standard reports lag 24-48h; Realtime covers 30 minutes; DebugView
is instant but only for a device you flagged. There is no same-day read on a
change you shipped this morning.

**Statistics do not work at ten users.** This is the real limit right now, and
no tool fixes it. One parent quitting at the overlay step is a 10% drop in your
funnel. Treat every number below a few hundred users as a *pointer to go look
at something*, never as a measurement. What the events are genuinely good for
today is catching binary failures — a permission nobody grants, a country where
`login_failed` fires every time — not optimising rates.

**It cannot tell you why.** Nothing here explains a drop-off. At this scale,
three recorded calls with parents who abandoned setup will teach you more than
the entire funnel. Use the funnel to decide WHO to call.

---

## Segments worth saving

- **Country** — the whole reason this exists. Every funnel above should be
  checked with a country breakdown, not just in aggregate.
- `age_band` (a/b/c/d) and `subject` — user properties, set at setup.
- `apps_gated` — a family with 0 gated apps has an app that does nothing.
- `signin_method` — google vs email.

---

## Rules

1. **Never log personal data.** No child name, no owl name, no parent name, no
   email, no answer the child gave, no question text. Age BAND, subject and
   counts only. This is not a style preference: Nupo's audience is children
   5-11 under Play Families.
2. **Never re-enable an advertising signal.** The AD_ID permission is stripped
   and four `google_analytics_*` flags are set false in `AndroidManifest.xml`.
   Those flags are what make the SDK usable for a child audience. After any
   release build, re-verify:
   ```
   unzip -p build/app/outputs/bundle/release/app-release.aab \
     base/manifest/AndroidManifest.xml | strings | grep permission.AD_ID
   ```
   must print nothing.
3. **Adding an event means updating `legal/DATA_SAFETY.md` and
   `legal/PRIVACY_POLICY.md`** in the same commit, and re-submitting the Data
   Safety form before that build rolls out. Both files currently declare
   exactly what is listed here.
