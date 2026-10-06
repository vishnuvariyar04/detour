# Privacy Policy

**Effective date:** 5 October 2026

**Apps:** Nupo for iOS (bundle `com.app.nupo`) and Nupo for Android (package `app.nupo.kid`)

**Provided by:** InternSpirit Private Limited (India)

**Contact:** vishnu@internspirit.com

Nupo is a daily learning app for children aged 5–12, set up and controlled entirely by a parent or guardian. This policy explains what we collect, why, and the choices you have. It covers both the iOS and Android versions of Nupo; where the two differ, we say so explicitly. We wrote it to be read, not skimmed — it's short because we collect very little.

## The short version

- The **parent** creates the account. On Android that means **Sign in with Google** or an **email address and password**; on iOS it means **Sign in with Apple or Sign in with Google**. Either way we get an email address for the parent.
- **Children never create accounts, enter personal information, or see ads.**
- Almost everything Nupo does — knowing which app was opened, showing lessons, counting minutes — happens **entirely on the device** and is never uploaded.
- Nupo **shows no ads**, to children or to parents, and contains no ad-serving SDK. We do advertise Nupo to parents on Facebook and Instagram, and the Android app tells Meta when one of those ads led to an install, a finished setup or a subscription, so we can see which ads work (see "Measuring our own ads" below). We also use **product analytics** (Google Firebase Analytics, and PostHog) to see where parents get stuck setting Nupo up and whether families keep using it — never to profile anyone and never for advertising. **No advertising identifier is collected, and no child's answers or names are ever sent.** See "Product analytics" below.
- We **never sell data**. Apart from the infrastructure providers listed below, the only data shared is the short list of ad-measurement events sent to Meta, described below.

## Information we collect (parent account)

When a parent signs in and uses Nupo, we store the following in our cloud database (Google Firebase, operated by Google LLC):

| Data | Platform | Purpose |
|---|---|---|
| Parent's email address | Android and iOS | Account sign-in and, occasionally, to contact you about Nupo |
| Your saved setup: your child's first name, the owl's nickname, their age (in years) and age range, chosen subject, the apps you picked for lessons and each app's rules | Android and iOS | So that signing in on a new phone, or after reinstalling, restores what you already set up |
| Parent's email address | iOS | Account sign-in and, occasionally, to contact you about Nupo |
| Parent's name, if the sign-in provider supplies one | iOS | Addressing you correctly in the app |
| Which sign-in method was used (Apple or Google) | iOS | Signing you back into the right account |
| Account created / last active timestamps | Both | Understanding whether Nupo is being used |
| App version, device model, and OS version | Both | Debugging and support |
| Child's **age band** (a coarse range, never a birth date or name) | Both | Understanding which age groups use Nupo |
| Number of apps selected for lessons (a count only — **not** which apps) | Both | Understanding how Nupo is configured |
| Whether setup was completed | Both | Support, and knowing where people get stuck |
| How you heard about Nupo, if you told us during setup | Both | Understanding how people find us |

**A note on Sign in with Apple.** Apple lets you hide your real email address. If you choose that, we receive a relay address ending in `@privaterelay.appleid.com` and never see your actual email. That works perfectly well — you can use Nupo entirely through the relay.

**Subscriptions.** Nupo Pro is sold through **Apple** on iOS and through **Google Play** on Android, and we use **RevenueCat** to confirm whether a subscription is active. Neither we nor RevenueCat ever see your payment card, billing address, or store account password — Apple and Google handle all of that. If you start a free trial on Android, Nupo schedules one **local** reminder notification on your phone for the day before the trial ends; it is created on the device, not sent from our servers. RevenueCat holds only your purchase history and an account identifier so that your subscription follows you across devices and reinstalls. We have deliberately **disabled RevenueCat's optional device-identifier collection**. On Android, RevenueCat also tells Meta when a trial starts, converts, renews or is refunded, with the amount and currency, so we can measure our Facebook and Instagram ads (see "Measuring our own ads").

**Your saved setup.** So that signing in on a new phone (or after a reinstall) restores what you already configured, we store your setup against your account: your child's first name, the name you gave the Nupo owl, their age in years and age range, their chosen subject, the apps you selected for lessons, and each app's rules. This is readable only by your own signed-in account, is never sold or shared, and is deleted with your account.

We do **not** collect: your child's date of birth, photos, contacts, messages, location, browsing history, the full list of apps installed on the device, or your child's answers to questions.

## Information that stays on the device

The following is stored **only on the device** and is never transmitted to us or anyone else:

- The parent PIN (stored as a salted cryptographic hash — we cannot read it)
- Daily usage and earned-time counters
- Everything about the child's learning session (the questions shown, the answers given, progress, streaks). The only part of it that leaves the device is the right/wrong, hint and timing analytics described under "Product analytics".

Your child's first name, the owl's name, and your chosen apps and rules are also kept on the device, and additionally saved to your account so they can be restored — see **Your saved setup** above.

## The permissions Nupo asks for, and why

**On Android**, Nupo uses the **Usage Access** permission to detect, on-device, when a chosen app comes to the foreground, and the **Display over other apps** permission solely to show the lesson screen. This information is processed in the moment and is **never uploaded, logged, or shared**.

**On iOS**, Nupo uses Apple's **Screen Time** framework (Family Controls, Managed Settings, and Device Activity) to pause and resume the apps you chose. This works differently from Android in a way that is worth understanding:

- You choose the apps in **Apple's own picker**, not ours. Apple hands Nupo an opaque token for each app — a meaningless identifier that we cannot decode. **Nupo cannot see what apps are installed on the device, cannot read their names, and cannot see their contents.**
- Nupo asks iOS to tell it when the earned minutes have been used up. iOS reports only that a threshold was reached — never what your child did.
- Nupo sends **local notifications** (generated on the device, not from our servers) when a session is nearly over.
- Screen Time authorization is requested by the parent, on their own device, for their own child.

On **neither** platform does Nupo request SMS, contacts, camera, microphone, or location permissions.

**We never ask for permission to track you across other companies' apps and websites, because we never do it.** Nupo contains no advertising identifier (IDFA or Android advertising ID) and no App Tracking Transparency prompt. The Android app does use Meta's app-events SDK to measure our own ads, as described below, without the advertising ID.

## Children's privacy

Nupo is used by children under parental control, and we take that seriously:

- The account and all settings belong to the **parent**. The one piece of information about a child that reaches our servers is the **first name (or nickname) the parent types during setup**, together with the owl's nickname, stored so the setup can be restored. We also store the age (in years) the parent picks, to choose the right lessons. We ask for nothing else about the child: no date of birth, no photo, no contact details, and never their answers.
- The child-facing screens contain **no ads, no external links, no purchases, and no data entry** beyond answering learning questions, which are processed on-device and never stored on our servers or transmitted.
- The only child-related data we hold is the coarse age band the **parent** selected, which cannot identify a child.

If you believe we have inadvertently collected personal information from a child, contact vishnu@internspirit.com and we will delete it promptly.

## Where your data lives, and who processes it

| Processor | What they handle |
|---|---|
| **Google LLC** (Firebase Authentication, Cloud Firestore and Firebase Analytics) | The parent account record and saved setup described above, plus the product-analytics events listed under "Product analytics". Google also handles Sign in with Google on both platforms, and email/password sign-in on Android. |
| **Apple Inc.** (iOS only) | Sign in with Apple, and all payment processing for iOS subscriptions. |
| **Google LLC** (Google Play, Android only) | All payment processing for Android subscriptions. |
| **RevenueCat, Inc.** (both apps) | Confirming whether a subscription is active. Purchase history and an account identifier only. |
| **Meta Platforms, Inc.** (Android) | The ad-measurement events described under "Measuring our own ads". |
| **PostHog, Inc.** | The product-analytics events listed under "Product analytics". Data from both apps is hosted in PostHog's EU region (Frankfurt, Germany). No session replay and no automatic capture — only the events we write ourselves. |

All data is encrypted in transit (TLS), and database access rules ensure each account can only ever read or write its own record.

We use **no ad-serving SDKs, no crash-reporting SDKs, and no data brokers**. We do not sell, rent, or share your personal information with third parties for their own purposes.

## Product analytics

Nupo uses product analytics so we can tell where the app is failing parents. Before we added it we had no way of knowing that a parent had installed Nupo, tried to sign in, and been blocked. We use two tools:

- **Firebase Analytics** (Google LLC) — on **Android and iOS**.
- **PostHog** (PostHog, Inc.) — on **Android** and **iOS**, hosted in PostHog's EU region.

**Both are configured to record only the events we deliberately write into the app.** We do not use session replay, screen recording, or automatic capture of taps and gestures. Nothing is recorded from the screens your child sees beyond the fact that a lesson happened.

**What we record**

- Which setup step was reached, and where a parent stopped.
- Whether each permission was granted or skipped (Android), or whether Screen Time access was granted (iOS).
- Whether sign-in succeeded or failed, and a short technical *reason code* when it fails (for example `invalid-credential`). We never record what was typed.
- That a lesson was shown on the device, that it was completed, or that a parent used their PIN to skip it — and a once-a-day marker that the app was used.
- How the learning is going (Android): for each question, which lesson it belongs to (for example "lesson 2.1.3 of Number Sense"), the *kind* of question, whether the answer was right or wrong, whether the hint was opened, and how many seconds it took. Also when a new idea is introduced and when a lesson is finished. We use this to find questions that are too hard and lessons that do not teach well.
- Which settings screens a parent opens later (for example "apps" or "age"), whether protection was switched off, and sign-out or account deletion.
- Basic technical details the analytics tools attach to every event: the device model, Android or iOS version, app version and language, and the IP address the event came from (used only to estimate the country).
- The child's age **band** (such as 7-8), the chosen subject, and how many apps are gated.

**What we never record**

- Your child's name, the owl's name, your name, or anything else typed into the app.
- The text of any question your child saw, or what they tapped or typed as an answer. Only whether it was right or wrong is recorded.
- Screen recordings, screenshots, or a general log of what was tapped.
- Your advertising ID. Because Nupo is for children, there is no advertising identifier in either app — on Android it is removed from the app entirely and ad personalisation and ad-user-data signals are switched off; on iOS there is no IDFA and no App Tracking Transparency prompt. Analytics data is tied only to a random, app-specific identifier that is destroyed when you uninstall Nupo.

This data is used solely to improve Nupo. It is never used for advertising, never sold, and never shared with anyone other than Google and PostHog, Inc. as the processors running the service on our behalf. The separate ad-measurement events below are the only exception.

## Measuring our own ads (Android)

We advertise Nupo to **parents** on Facebook and Instagram. To know which of those ads actually help families, the Android app uses **Meta's app-events SDK**, and RevenueCat sends purchase events to Meta from its servers. Nupo itself never shows ads.

What Meta receives:

- That Nupo was installed and opened, and which ad led to the install (from Google Play's install referrer).
- That a parent finished setting Nupo up.
- That a free trial started, converted, renewed or was refunded, with the amount and currency.
- A random, app-specific identifier created by Meta's SDK, and basic technical details its SDK attaches (device model, Android version, app version, language, and the IP address the event came from).

What Meta never receives: your advertising ID (it is removed from the app), your name, your email address, your child's name or age, or anything about your child's lessons, questions or answers.

We also record the ad campaign that led to the install (for example "facebook / spring-campaign") with our own analytics, so we can see how families from each campaign use Nupo.

Meta processes these events under its own terms and privacy policy (facebook.com/privacy/policy). To limit how Meta uses activity from apps for ads shown to you, use Meta's "Activity from ad partners" setting in your Facebook or Instagram account.

## Where your data is processed

Our processors — Google, Apple, RevenueCat and PostHog — are United States companies, and your data is processed on their infrastructure, which may be in the United States or in other countries where they operate. Our PostHog project, used by both apps, is hosted in PostHog's **EU region** (Frankfurt, Germany). Where the law requires a safeguard for such transfers (for example the GDPR), we rely on our processors' standard contractual clauses and equivalent data-protection terms. All data is encrypted in transit.

## How long we keep data

We keep your account record for as long as your account exists. When you delete your account (see below), your account and profile record are permanently deleted from our systems. Data stored only on your device is yours: it is removed when you clear Nupo's storage or uninstall the app.

Note that Apple and Google keep their own records of purchases and refunds under their own retention policies, which we do not control.

## Your rights and choices

You can, at any time:

- **View** what we hold about you — email us and we'll send you a copy.
- **Delete** your account and all associated data:
  - **iOS:** Parent settings → Delete account
  - **Android:** Parent tab → Account → Delete account
  - or by emailing us. See our [Data Deletion page](/data-deletion).
- **Correct** your details by deleting the account and signing up again.
- **Cancel a subscription** at any time: on iOS in Settings → Apple Account → Subscriptions; on Android in the Google Play app → Profile → Payments & subscriptions → Subscriptions (or from Nupo's Parent tab → Nupo Pro). Deleting your Nupo account does not cancel a store subscription; you must cancel it with Apple or Google separately.

We respond to all requests within 30 days. Depending on where you live, you may have additional rights under laws such as the GDPR or India's DPDP Act; we honour reasonable requests regardless of jurisdiction.

## Changes to this policy

If we change what we collect or how we use it, we will update this policy and its effective date, and — for material changes — inform you in the app before the change applies.

## Contact

Questions, requests, or concerns: **vishnu@internspirit.com**
