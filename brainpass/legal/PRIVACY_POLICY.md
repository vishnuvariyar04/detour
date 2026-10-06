# Privacy Policy

**Effective date:** 7 October 2026 (measuring our own ads to parents, now on iOS as well as Android)

**Apps:** Nupo for iOS (bundle `com.app.nupo`) and Nupo for Android (package `app.nupo.kid`)

**Provided by:** InternSpirit Private Limited (India)

**Contact:** vishnu@internspirit.com

Nupo is a daily learning app for children aged 5–12, set up and controlled entirely by a parent or guardian. This policy explains what we collect, why, and the choices you have. It covers both the iOS and Android versions of Nupo; where the two differ, we say so explicitly. We wrote it to be read, not skimmed — it's short because we collect very little.

## The short version

- The **parent** creates the account. On Android that means **Sign in with Google** or an **email address and password**; on iOS it means **Sign in with Apple or Sign in with Google**. Either way we get an email address for the parent.
- **Children never create accounts, enter personal information, or see ads.**
- We store a few things the **parent** tells us about their child during setup — the child's first name, their age range, and the nickname given to the owl — against the parent's account. The details differ slightly between the two apps and are listed under "Information we collect".
- Almost everything else Nupo does — knowing which app was opened, showing lessons, counting minutes, and the answer to every question your child sees — happens **entirely on the device**. Answers are never uploaded.
- Nupo **shows no ads**, to children or to parents, and contains no ad-serving SDK. We do advertise Nupo to **parents** on Facebook and Instagram, and the app tells Meta when one of those ads led to an install, a finished setup or a subscription, so we can see which ads work (see "Measuring our own ads"). This never happens on a screen a child uses.
- We use **product analytics** to see where parents get stuck setting Nupo up and whether families keep using it — never to profile anyone and never for advertising. **No advertising identifier is collected, and nothing your child types or answers is ever sent.** See "Product analytics".
- We **never sell data**. Apart from the infrastructure providers listed below, the only data shared is the short list of ad-measurement events sent to Meta.

## Information we collect (parent account)

When a parent signs in and uses Nupo, we store the following in our cloud database (Google Firebase, operated by Google LLC):

| Data | Platform | Purpose |
|---|---|---|
| Parent's email address | Both | Account sign-in and, occasionally, to contact you about Nupo |
| Parent's name, if the sign-in provider supplies one | Both | Addressing you correctly in the app |
| Which sign-in method was used (Apple, Google, or email) | Both | Signing you back into the right account |
| Child's **first name**, as entered by the parent during setup, and the **nickname given to the owl** | Both | Personalising the app, and restoring your setup |
| Child's **age range** (a coarse band such as 7–8 — never a birth date) | Both | Choosing the right course and difficulty |
| The rest of your **saved setup**: the child's age in years (the top of the age range picked), the chosen course, the apps you picked for lessons, and each app's rules | Android | So that signing in on a new phone, or after reinstalling, restores what you already set up |
| Number of apps selected for lessons (a count only — **not** which apps; iOS cannot see which apps they are) | iOS | Understanding how Nupo is configured |
| How you heard about Nupo, if you told us during setup | iOS | Understanding how people find us |
| Account created / last active timestamps | Both | Understanding whether Nupo is being used |
| App version, device model, and OS version | Both | Debugging and support |
| Whether setup was completed | Both | Support, and knowing where people get stuck |

**A note on Sign in with Apple.** Apple lets you hide your real email address. If you choose that, we receive a relay address ending in `@privaterelay.appleid.com` and never see your actual email. That works perfectly well — you can use Nupo entirely through the relay.

**Subscriptions.** Nupo Pro is sold through **Apple** on iOS and through **Google Play** on Android, and we use **RevenueCat** to confirm whether a subscription is active. Neither we nor RevenueCat ever see your payment card, billing address, or store account password — Apple and Google handle all of that. RevenueCat holds only your purchase history and an account identifier so that your subscription follows you across devices and reinstalls. We have deliberately **disabled RevenueCat's optional device-identifier collection**. If you start a free trial on Android, Nupo schedules one **local** reminder notification on your phone for the day before the trial ends; it is created on the device, not sent from our servers. On both platforms, RevenueCat also tells Meta when a trial starts, converts, renews or is refunded, with the amount and currency, so we can measure our Facebook and Instagram ads (see "Measuring our own ads").

We do **not** collect: your child's date of birth, photos, contacts, messages, location, browsing history, the list of apps installed on the device, the text of any question, or **any answer your child gives**.

## Information that stays on the device

The following is stored **only on the device** and is never transmitted to us or anyone else:

- The parent PIN (stored as a salted cryptographic hash — we cannot read it, and it is never uploaded, so it has to be set again on a new phone)
- Daily usage and earned-time counters
- Everything about the child's learning session — every question shown, every answer given, progress and streaks. On Android, the only part of it that leaves the device is the right/wrong, hint and timing record described under "Product analytics"; on iOS, none of it does.
- On iOS, the apps you chose for lessons and their rules, and the subject your child finds hardest.
- Which app is in the foreground at any moment. This is read on the device to decide when to show a lesson and is never uploaded. The only app names that ever leave the device are the ones you chose for lessons (Android).

## The permissions Nupo asks for, and why

**On Android**, Nupo uses the **Usage Access** permission to detect, on-device, when a chosen app comes to the foreground, and the **Display over other apps** permission solely to show the lesson screen. Nupo also asks to **post notifications**, used for the one free-trial reminder described above.

**On iOS**, Nupo uses Apple's **Screen Time** framework (Family Controls, Managed Settings, and Device Activity) to pause and resume the apps you chose. This works differently from Android in a way that is worth understanding:

- You choose the apps in **Apple's own picker**, not ours. Apple hands Nupo an opaque token for each app — a meaningless identifier that we cannot decode. **Nupo cannot see what apps are installed on the device, cannot read their names, and cannot see their contents.**
- Nupo asks iOS to tell it when the earned minutes have been used up. iOS reports only that a threshold was reached — never what your child did.
- Nupo sends **local notifications** (generated on the device, not from our servers) when a session is nearly over.
- Screen Time authorization is requested by the parent, on their own device, for their own child.

On **neither** platform does Nupo request SMS, contacts, camera, microphone, or location permissions.

**We never ask for permission to track you across other companies' apps and websites, because we never do it.** Nupo contains no advertising identifier (IDFA or Android advertising ID) and no App Tracking Transparency prompt. It does use Meta's app-events SDK to measure our own ads to parents, as described below, without any advertising identifier.

## Children's privacy

Nupo is used by children under parental control, and we take that seriously:

- **Children never create an account.** The account, the email address, the subscription, and every setting belong to the parent, who is an adult.
- **What we store about your child:** their **first name**, their **age range** (never a date of birth), and the **nickname given to the owl** — plus, on Android, the age in years, course and app rules that make up the saved setup. All of it is entered by the **parent** during setup and stored against the parent's account.
- **What we never store or upload:** the text of any question, any answer your child gives, and anything your child types.
- The child-facing screens contain **no ads, no external links, no purchases, and no data entry** beyond answering learning questions. On iOS our analytics and Meta's SDK are switched off entirely once a child's screen appears, until the app is restarted. On Android, the lesson screen records only the right/wrong, hint and timing analytics described below, and never sends anything to Meta.
- **A parent can delete all of it at any time** — see "Your rights and choices".

**Parental consent.** The parent creates the account, enters this information themselves, and can delete it at any time. If you are not the parent or legal guardian of the child using Nupo, do not complete setup.

If you believe we have inadvertently collected personal information from a child, contact vishnu@internspirit.com and we will delete it promptly.

## Where your data lives, and who processes it

| Processor | What they handle |
|---|---|
| **Google LLC** (Firebase Authentication and Cloud Firestore) | The parent account record described above. Google also handles Sign in with Google on both platforms, and email/password sign-in on Android. |
| **Google LLC** (Firebase Analytics) | The product-analytics events listed under "Product analytics", plus the coarse information Google's analytics collects automatically: an app-install identifier, device model, operating system, language, and an approximate country derived from the network address. |
| **Apple Inc.** (iOS only) | Sign in with Apple, and all payment processing for iOS subscriptions. |
| **Google LLC** (Google Play, Android only) | All payment processing for Android subscriptions. |
| **RevenueCat, Inc.** (both apps) | Confirming whether a subscription is active. Purchase history and an account identifier only. |
| **PostHog, Inc.** (both apps) | The product-analytics events listed under "Product analytics". Hosted in PostHog's EU region. No session replay and no automatic capture — only the events we write ourselves. |
| **Meta Platforms, Inc.** (both apps) | The ad-measurement events described under "Measuring our own ads". Never anything from a screen a child uses. |

All data is encrypted in transit (TLS), and database access rules ensure each account can only ever read or write its own record.

We use **no ad-serving SDKs, no crash-reporting SDKs, and no data brokers**. We do not sell, rent, or share your personal information with third parties for their own purposes.

## Product analytics

Nupo uses product analytics so we can tell where the app is failing parents. Before we added it we had no way of knowing that a parent had installed Nupo, tried to sign in, and been blocked. We use **Firebase Analytics** (Google LLC) and **PostHog** (PostHog, Inc., EU region) in both apps.

**Both are configured to record only the events we deliberately write into the app.** We do not use session replay, screen recording, or automatic capture of taps and gestures.

What we record on both platforms:

- The parent's path through sign-up and setup: which step was reached and where a parent stopped — never what was typed or chosen on it.
- Whether each permission was granted or skipped (Android), or whether Screen Time access was granted (iOS).
- Whether signing in succeeded or failed, and a short technical *reason code* when it fails (for example `invalid-credential`).
- Which settings a parent opens later (for example "apps" or "age"), whether Nupo was paused, whether the subscription screen was shown and a purchase completed, and sign-out or account deletion. We also receive subscription events (a trial started, a subscription renewed or cancelled) from RevenueCat.
- On Android, the ad campaign that led to the install (see "Measuring our own ads").
- Basic technical details the analytics tools attach to every event: device model, Android or iOS version, app version and language.

**On iOS**, that is all. Analytics start switched off every time the app opens and are enabled only once the app knows a parent is looking. They are completely disabled on every screen a child uses: once a child's lesson opens, they are switched off for the rest of that session. iOS analytics never receive your child's name, age range, the owl's nickname, or the subject.

**On Android**, lessons run on a separate lock screen, and we also record how the learning is going so we can fix questions that are too hard:

- That a lesson was shown, that it was completed, or that a parent used their PIN to skip it, together with which of the apps **you chose** it came before (for example YouTube) — plus a once-a-day marker that Nupo was used.
- For each question: which lesson it belongs to (for example "lesson 2.1.3 of Number Sense"), the *kind* of question, whether the answer was right or wrong, whether the hint was opened, and how many seconds it took — plus when a new idea is introduced and when a lesson is finished.
- The child's age **band** (such as 7–8), the chosen course, and how many apps have lessons.

What we never record, on either platform:

- Your child's name, the owl's name, your name, or anything else typed into the app.
- The text of any question your child saw, or what they tapped as an answer. Those never leave the device.
- Screen recordings, screenshots, or a general log of what was tapped.
- **Your advertising ID.** Because Nupo is for children, there is no advertising identifier in either app — on Android it is removed from the app entirely and ad personalisation and ad-user-data signals are switched off; on iOS there is no IDFA and no App Tracking Transparency prompt. Analytics data is tied only to a random, app-specific identifier that is destroyed when you uninstall Nupo.

The network (IP) address an event arrives from is used only to estimate an approximate country, which is why a country breakdown appears in our reports. This is not precise location: we cannot tell what city, area or address anyone is in, and we never use it to locate or identify anyone. Analytics events are linked to your account's internal identifier, never to your name or email.

This data is used solely to improve Nupo. It is never used for advertising, never sold, and never shared with anyone other than Google and PostHog as the processors running the service on our behalf. The separate ad-measurement events below are the only exception.

## Measuring our own ads

We advertise Nupo to **parents** on Facebook and Instagram. To know which of those ads actually help families, both apps use **Meta's app-events SDK**, and RevenueCat sends purchase events to Meta from its servers. Nupo itself never shows ads.

What Meta receives:

- That Nupo was installed and opened by a parent, and that a parent finished setting Nupo up.
- Which ad led to the install. On iOS, Apple tells Meta through its own privacy-preserving system (SKAdNetwork), without any identifier from your phone. On Android, Google Play's install referrer is used.
- That a free trial started, converted, renewed or was refunded, with the amount and currency (sent by RevenueCat).
- A random, app-specific identifier created by Meta's SDK, and basic technical details its SDK attaches (device model, operating-system version, app version, language, and the IP address the event came from).

What Meta never receives: any advertising identifier (there is none in either app, and no tracking prompt), your name, your email address, your child's name or age, or anything about your child's lessons, questions or answers.

**Never from a child's screen.** On iOS a child's lessons run inside the Nupo app, so Meta's SDK stays switched off when the app opens and is only started once a parent's screen is showing; once a child's lesson has appeared, nothing is sent to Meta until the app is restarted. On Android, lessons appear on a separate lock screen that never uses Meta's SDK.

On Android we also record the ad campaign that led to the install (for example "facebook / spring-campaign") with our own analytics, so we can see how families from each campaign use Nupo.

Meta processes these events under its own terms and privacy policy (facebook.com/privacy/policy). To limit how Meta uses activity from apps for ads shown to you, use Meta's "Activity from ad partners" setting in your Facebook or Instagram account.

## Where your data is processed

Our processors — Google, Apple, RevenueCat and PostHog — and Meta are United States companies, and your data is processed on their infrastructure, which may be in the United States or in other countries where they operate. Our PostHog project, used by both apps, is hosted in PostHog's **EU region**. Where the law requires a safeguard for such transfers (for example the GDPR), we rely on our processors' standard contractual clauses and equivalent data-protection terms. All data is encrypted in transit.

## How long we keep data

We keep your account record for as long as your account exists. When you delete your account (see below), your account and profile record are permanently deleted from our systems. Data stored only on your device is yours: it is removed when you clear Nupo's storage or uninstall the app.

Note that Apple and Google keep their own records of purchases and refunds under their own retention policies, which we do not control.

## Your rights and choices

You can, at any time:

- **View** what we hold about you — email us and we'll send you a copy.
- **Delete** your account and all associated data:
  - **iOS:** Parent settings → Delete account
  - **Android:** Parent tab → Account → Delete account
  - or by emailing us. See our [Data Deletion page](https://www.nupo.app/data-deletion).
- **Correct** your details in the app's settings, or by deleting the account and signing up again.
- **Cancel a subscription** at any time: on iOS in Settings → Apple Account → Subscriptions; on Android in the Google Play app → Profile → Payments & subscriptions → Subscriptions (or from Nupo's Parent tab → Nupo Pro). Deleting your Nupo account does not cancel a store subscription; cancel it with Apple or Google separately.

We respond to all requests within 30 days. Depending on where you live, you may have additional rights under laws such as the GDPR or India's DPDP Act; we honour reasonable requests regardless of jurisdiction.

## Changes to this policy

If we change what we collect or how we use it, we will update this policy and its effective date, and — for material changes — inform you in the app before the change applies.

## Contact

Questions, requests, or concerns: **vishnu@internspirit.com**
