# Nupo — Play Console Data Safety answers (fill-in-the-blank)

Answer the Data Safety form in Play Console exactly as below. These match the
app's actual behaviour (verified in code) — the pre-launch scanner cross-checks
your binary against these declarations, so do not deviate.

App: `app.nupo.kid` · Target audience: **includes children (5–11)**

---

## Overview questions

- **Does your app collect or share any of the required user data types?** → **Yes**
- **Is all of the user data collected by your app encrypted in transit?** → **Yes**
- **Do you provide a way for users to request that their data be deleted?**
  → **Yes** (in-app: Parent tab → Account → Delete account; plus the deletion URL https://www.nupo.app/data-deletion)

---

## Data types — declare EXACTLY these

### Personal info → Email address
- Collected: **Yes** · Shared: **No**
- Processed ephemerally: **No**
- Required or optional: **Required** (login is mandatory)
- Purposes: **Account management**, **App functionality**
- Note: phone/OTP login was REMOVED on 2026-08-25 and replaced with Google
  Sign-In, so **Phone number is no longer collected** — untick it if the
  previous submission declared it. The email is the signing-in PARENT's.

### Personal info → Name
- Collected: **Yes** · Shared: **No**
- Required or optional: **Required** (part of setup)
- Purposes: **App functionality** (restore the parent's saved setup on a new
  device or after a reinstall)
- Collected from children? **Yes** — treat as such. This is the CHILD's first
  name and the nickname given to the owl, typed by the parent during setup and
  saved to the parent's account so it can be restored. It is readable only by
  that account and is deleted with it.
- The parent's own display name from their Google account is also stored.

### Personal info → User IDs
- Collected: **Yes** · Shared: **No**
- Required: **Required**
- Purposes: **App functionality**, **Analytics**, **Account management**
- The parent account's Firebase UID: the account key in Firestore, the
  RevenueCat app user id (so a subscription follows the account), and the id
  analytics events are joined to (Firebase `setUserId`, PostHog `identify`).

### Personal info → Other info
- Collected: **Yes** · Shared: **No** · Required: **Required**
- Purposes: **App functionality**
- The child's AGE in years and age band, picked by the parent and saved to
  the account so the right lessons are chosen and a reinstall restores them.

### App activity → Other user-generated content
- Collected: **Yes** · Shared: **No**
- Purposes: **App functionality**
- Covers the parent's chosen apps and their per-app rules, saved to the
  account so a reinstall restores them. Child ANSWERS remain on-device and are
  never collected.

### App activity → App interactions
- Collected: **Yes** · Shared: **No**
- Purposes: **Analytics** ONLY. Not App functionality — these events are
  write-only telemetry that the app never reads back and no feature depends on,
  and Google defines App functionality as data used to *run a feature*. Not
  Fraud prevention either: `login_failed` exists to catch a BROKEN sign-in, not
  a fraudulent one, and the purpose must match the actual use.
- Ephemeral: **No.** Events are uploaded to Google and retained (the GA4
  property is set to 14 months), and to PostHog Cloud EU (retention per the
  PostHog plan).
- Required or optional: **Required.** `Analytics.init()` enables collection
  unconditionally and there is no opt-out in parent settings. If an opt-out is
  ever added (a switch calling `setAnalyticsCollectionEnabled(false)`), change
  this answer to "users can choose" in the same release.
- **Firebase Analytics was added on 2026-08-31**, in the first release after
  1.2.0 (4) — it must be declared here BEFORE that build is rolled out. It
  records which onboarding step a parent reached, whether each permission was
  granted or skipped, whether sign-in succeeded or failed (a failure CODE such
  as `invalid-credential`, never the email or the message shown), and — from
  the native guard — that a lesson was shown, earned, or skipped by parent PIN,
  plus a once-a-day active marker.
- **PostHog (Cloud EU, Frankfurt) was added alongside Firebase in October
  2026.** The
  same events go to both, plus learning metrics from the gate: per question
  the skill, stop id (e.g. "2.1.3"), question KIND, right/wrong, hint opened,
  and seconds taken; teach card shown; lesson session finished; stop reached.
  Plus parent-home events (settings opened, protection toggled, sign-out,
  account deleted). PostHog attaches device model, OS version, app version,
  locale and the client IP (GeoIP). Turn on "Discard client IP data" in the
  PostHog project settings to drop the IP after geolocation.
- **No child answers, no question text, no names, and no free text** typed by
  a parent are ever sent. Only age BAND, chosen subject, ids, counts and
  right/wrong.
- Identifier: the Firebase **app instance ID**, and PostHog's random
  anonymous id, which is joined to the account's Firebase UID once the parent
  signs in (the same UID Firebase Analytics already gets via `setUserId`). The advertising ID (AAID)
  is stripped from the manifest, `google_analytics_ssaid_collection_enabled` is
  false, and ad personalisation / ad user data are both disabled — see the
  `google_analytics_*` meta-data in `AndroidManifest.xml`. Those flags are what
  keep the SDK compliant for a child audience under Play Families; do not
  remove them.
- The full event list, with the reason each one exists, is `lib/analytics.dart`
  and `android/.../Analytics.kt`. Adding an event means revisiting this file
  and `PRIVACY_POLICY.md`.
- This form covers the ANDROID app only, which sends PostHog events to
  PostHog Cloud EU (PostHog, Inc. as a processor, so "Shared" stays **No**).
  iOS uses PostHog
  Cloud EU project (no session replay, no autocapture) — that belongs in App
  Store Connect's privacy questionnaire and in `PRIVACY_POLICY.md`, not here.

### Financial info → Purchase history
- Collected: **Yes** · Shared: **No**
- Purposes: **App functionality** (manage the subscription / entitlement)
- Note: payments are processed by **Google Play Billing**; RevenueCat stores
  purchase/subscription status tied to the account.

### Device or other IDs
- Collected: **Yes since 1.4.4** (Meta SDK's anonymous app id; see "Meta ad
  measurement"). Before 1.4.4: **No**
- Rationale (keep for your records): the **AD_ID permission is removed**
  (`tools:node="remove"`, verified absent in the merged manifest), and the app
  reads **no** Android ID / IMEI / IMSI / MAC / SIM serial / device phone
  number. The only device fields sent are **model, manufacturer, and Android
  version** — these are NOT "Device or other IDs" (they're not resettable/
  hardware identifiers), so this category stays **Not collected**.

---

## Meta ad measurement (added in 1.4.4)

The Meta app-events SDK and RevenueCat's Meta integration send data to Meta
Platforms for **ad measurement of our own ads**. That makes the data
**Shared** (a third party using it under its own terms), purpose
**Advertising or marketing** (plus **Analytics**):

- **App activity → App interactions:** Shared = **Yes** (install, app open,
  setup completed). Purposes add **Advertising or marketing**.
- **Financial info → Purchase history:** Shared = **Yes** (trial start,
  conversion, renewal, refund, amount, currency, sent by RevenueCat).
  Purposes add **Advertising or marketing**.
- **Device or other IDs:** Collected = **Yes**, Shared = **Yes**. Meta's SDK
  creates an app-scoped anonymous id (not the advertising ID, which stays
  removed). Purposes: **Advertising or marketing**, **Analytics**.
- The advertising ID (AAID) is still NOT collected: AD_ID stays removed and
  `com.facebook.sdk.AdvertiserIDCollectionEnabled` is false.

## Explicitly NOT collected (do not tick these)

- Location (any) — **No**
- Address, race, religion, political views — **No**
- Name and email — **now collected**; see the Personal info sections above
  (changed 2026-08-25 with Google Sign-In and saved-setup restore)
- Contacts, Calendar, SMS/Call logs — **No**
- Photos / videos / audio / files — **No**
- **Child's answers and question text** — **No.** They stay on-device.
  What IS sent is per-question right/wrong, hint opened and seconds taken —
  declared above under **App activity → App interactions** (Analytics).
- Web browsing history, installed-apps list — **No** (the gated-app list stays
  on-device; only a *count* is sent, which is not a listed data type).

---

## Also required in "App content"

- **Target audience & content:** select the age bands including children;
  keep this **consistent with the no-AAID technical config** (they must agree,
  or you get flagged).
- **Ads:** **No, my app does not contain ads.**
- **Privacy policy URL:** https://www.nupo.app/privacy
- **Account deletion URL:** https://www.nupo.app/data-deletion
- **Financial features / Play Billing:** declare subscriptions.

---

## Sanity cross-check before submitting

- [ ] Personal info = Email address, Name, User IDs, Other info (age).
- [ ] Purchase history = Yes (Play Billing).
- [ ] Device or other IDs = **No** (AD_ID removed; no hardware IDs read; the
      Firebase app instance ID is not a "Device or other ID" for this form).
- [ ] Nothing ticked for location, contacts, messages, photos, child answers.
- [ ] Encryption in transit = Yes; Deletion available = Yes + URL.
- [ ] App interactions = **Yes** (Firebase Analytics, added after 1.2.0, and
      PostHog Cloud EU, added October 2026),
      purpose **Analytics only**, ephemeral **No**, collection **required**.
- [ ] Advertising or marketing ticked ONLY on the three Meta-shared types
      above (App interactions, Purchase history, Device or other IDs).
- [ ] Merged manifest re-verified after any release build:
      `unzip -p app-release.aab base/manifest/AndroidManifest.xml | strings | grep permission.AD_ID`
      must be EMPTY, and the four `google_analytics_*` flags must be present.
