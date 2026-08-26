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
  → **Yes** (in-app: Settings → Account → Delete account; plus the deletion URL)

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

### App activity → Other user-generated content
- Collected: **Yes** · Shared: **No**
- Purposes: **App functionality**
- Covers the parent's chosen apps and their per-app rules, saved to the
  account so a reinstall restores them. Child ANSWERS remain on-device and are
  never collected.

### App activity → App interactions  → **only if you add analytics later**
- **You currently have NO analytics SDK.** If that stays true, **do NOT tick
  this** — declare nothing here.
- If you later add analytics: Collected **Yes**, Shared **No** (or Yes if a
  third-party SDK), Purpose **Analytics** + **App functionality**, identifier
  **App Set ID only (no AAID)**.

### Financial info → Purchase history
- Collected: **Yes** · Shared: **No**
- Purposes: **App functionality** (manage the subscription / entitlement)
- Note: payments are processed by **Google Play Billing**; RevenueCat stores
  purchase/subscription status tied to the account.

### Device or other IDs
- Collected: **No**
- Rationale (keep for your records): the **AD_ID permission is removed**
  (`tools:node="remove"`, verified absent in the merged manifest), and the app
  reads **no** Android ID / IMEI / IMSI / MAC / SIM serial / device phone
  number. The only device fields sent are **model, manufacturer, and Android
  version** — these are NOT "Device or other IDs" (they're not resettable/
  hardware identifiers), so this category stays **Not collected**.

---

## Explicitly NOT collected (do not tick these)

- Location (any) — **No**
- Address, race, religion, political views — **No**
- Name and email — **now collected**; see the Personal info sections above
  (changed 2026-08-25 with Google Sign-In and saved-setup restore)
- Contacts, Calendar, SMS/Call logs — **No**
- Photos / videos / audio / files — **No**
- **Child's learning data** (questions shown, answers, accuracy, streaks) —
  **No.** It is computed and stored **on-device only** and never transmitted,
  so it is not "collected" under Play's definition.
- Web browsing history, installed-apps list — **No** (the gated-app list stays
  on-device; only a *count* is sent, which is not a listed data type).

---

## Also required in "App content"

- **Target audience & content:** select the age bands including children;
  keep this **consistent with the no-AAID technical config** (they must agree,
  or you get flagged).
- **Ads:** **No, my app does not contain ads.**
- **Privacy policy URL:** _<host PRIVACY_POLICY.md and paste the URL>_
- **Account deletion URL:** _<host DATA_DELETION.md and paste the URL>_
- **Financial features / Play Billing:** declare subscriptions.

---

## Sanity cross-check before submitting

- [ ] Phone number = the only Personal info; purposes Account mgmt + App func.
- [ ] Purchase history = Yes (Play Billing).
- [ ] Device or other IDs = **No** (AD_ID removed; no hardware IDs read).
- [ ] Nothing ticked for location, contacts, messages, photos, child answers.
- [ ] Encryption in transit = Yes; Deletion available = Yes + URL.
- [ ] If no analytics SDK: App interactions left **unticked**.
