# Privacy Policy

**Effective date:** 25 August 2026

**Apps:** Nupo for iOS (bundle `com.app.nupo`) and Nupo for Android (package `app.nupo.kid`)

**Provided by:** InternSpirit Private Limited (India)

**Contact:** vishnu@internspirit.com

Nupo is a daily learning app for children aged 5–12, set up and controlled entirely by a parent or guardian. This policy explains what we collect, why, and the choices you have. It covers both the iOS and Android versions of Nupo; where the two differ, we say so explicitly. We wrote it to be read, not skimmed — it's short because we collect very little.

## The short version

- The **parent** creates the account. On Android that means **Sign in with Google** or an **email address and password**; on iOS it means **Sign in with Apple or Sign in with Google**. Either way we get an email address for the parent.
- **Children never create accounts, enter personal information, or see ads.**
- Almost everything Nupo does — knowing which app was opened, showing lessons, counting minutes — happens **entirely on the device** and is never uploaded.
- We show no ads, use no advertising, analytics, or marketing SDKs, and **never sell or share data** with anyone except the infrastructure providers listed below.

## Information we collect (parent account)

When a parent signs in and uses Nupo, we store the following in our cloud database (Google Firebase, operated by Google LLC):

| Data | Platform | Purpose |
|---|---|---|
| Parent's email address | Android and iOS | Account sign-in and, occasionally, to contact you about Nupo |
| Your saved setup: your child's first name, the owl's nickname, their age range, chosen subject, the apps you picked for lessons and each app's rules | Android and iOS | So that signing in on a new phone, or after reinstalling, restores what you already set up |
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

**Subscriptions (iOS).** Nupo for iOS is a paid app. Purchases are processed by **Apple**, and we use **RevenueCat** to confirm whether a subscription is active. Neither we nor RevenueCat ever see your payment card, billing address, or Apple Account password — Apple handles all of that. RevenueCat holds only your purchase history and an account identifier so that your subscription follows you across devices and reinstalls. We have deliberately **disabled RevenueCat's optional device-identifier and advertising-attribution collection**.

**Your saved setup.** So that signing in on a new phone (or after a reinstall) restores what you already configured, we store your setup against your account: your child's first name, the name you gave the Nupo owl, their age range and chosen subject, the apps you selected for lessons, and each app's rules. This is readable only by your own signed-in account, is never sold or shared, and is deleted with your account.

We do **not** collect: your child's birth date, photos, contacts, messages, location, browsing history, the full list of apps installed on the device, or your child's answers to questions.

## Information that stays on the device

The following is stored **only on the device** and is never transmitted to us or anyone else:

- The parent PIN (stored as a salted cryptographic hash — we cannot read it)
- Daily usage and earned-time counters
- Everything about the child's learning session (questions shown, answers given, progress, streaks)

Your child's first name, the owl's name, and your chosen apps and rules are also kept on the device, and additionally saved to your account so they can be restored — see **Your saved setup** above.

## The permissions Nupo asks for, and why

**On Android**, Nupo uses the **Usage Access** permission to detect, on-device, when a chosen app comes to the foreground, and the **Display over other apps** permission solely to show the lesson screen. This information is processed in the moment and is **never uploaded, logged, or shared**.

**On iOS**, Nupo uses Apple's **Screen Time** framework (Family Controls, Managed Settings, and Device Activity) to pause and resume the apps you chose. This works differently from Android in a way that is worth understanding:

- You choose the apps in **Apple's own picker**, not ours. Apple hands Nupo an opaque token for each app — a meaningless identifier that we cannot decode. **Nupo cannot see what apps are installed on the device, cannot read their names, and cannot see their contents.**
- Nupo asks iOS to tell it when the earned minutes have been used up. iOS reports only that a threshold was reached — never what your child did.
- Nupo sends **local notifications** (generated on the device, not from our servers) when a session is nearly over.
- Screen Time authorization is requested by the parent, on their own device, for their own child.

On **neither** platform does Nupo request SMS, contacts, camera, microphone, or location permissions.

**We never ask for permission to track you across other companies' apps and websites, because we never do it.** Nupo contains no advertising identifier (IDFA), no App Tracking Transparency prompt, and no attribution SDK.

## Children's privacy

Nupo is used by children under parental control, and we take that seriously:

- The account and all settings belong to the **parent**. The one piece of information about a child that reaches our servers is the **first name (or nickname) the parent types during setup**, together with the owl's nickname, stored so the setup can be restored. We ask for nothing else about the child: no birth date, no exact age, no photo, no contact details, and never their answers.
- The child-facing screens contain **no ads, no external links, no purchases, and no data entry** beyond answering learning questions, which are processed on-device and never stored on our servers or transmitted.
- The only child-related data we hold is the coarse age band the **parent** selected, which cannot identify a child.

If you believe we have inadvertently collected personal information from a child, contact vishnu@internspirit.com and we will delete it promptly.

## Where your data lives, and who processes it

| Processor | What they handle |
|---|---|
| **Google LLC** (Firebase Authentication and Cloud Firestore) | The parent account record and saved setup described above. Google also handles Sign in with Google on both platforms, and email/password sign-in on Android. |
| **Apple Inc.** (iOS only) | Sign in with Apple, and all payment processing for subscriptions. |
| **RevenueCat, Inc.** (iOS only) | Confirming whether a subscription is active. Purchase history and an account identifier only. |

All data is encrypted in transit (TLS), and database access rules ensure each account can only ever read or write its own record.

We use **no analytics SDKs, no advertising SDKs, no crash-reporting SDKs, and no data brokers**. We do not sell, rent, or share your personal information with third parties for their own purposes.

## How long we keep data

We keep your account record for as long as your account exists. When you delete your account (see below), your account and profile record are permanently deleted from our systems. Data stored only on your device is yours: it is removed when you clear Nupo's storage or uninstall the app.

Note that Apple and Google keep their own records of purchases and refunds under their own retention policies, which we do not control.

## Your rights and choices

You can, at any time:

- **View** what we hold about you — email us and we'll send you a copy.
- **Delete** your account and all associated data:
  - **iOS:** Parent settings → Delete account
  - **Android:** Settings → Account → Delete account
  - or by emailing us. See our [Data Deletion page](/data-deletion).
- **Correct** your details by deleting the account and signing up again.
- **Cancel a subscription** at any time in Settings → Apple Account → Subscriptions on iOS. Deleting your Nupo account does not cancel an Apple subscription; you must cancel it with Apple separately.

We respond to all requests within 30 days. Depending on where you live, you may have additional rights under laws such as the GDPR or India's DPDP Act; we honour reasonable requests regardless of jurisdiction.

## Changes to this policy

If we change what we collect or how we use it, we will update this policy and its effective date, and — for material changes — inform you in the app before the change applies.

## Contact

Questions, requests, or concerns: **vishnu@internspirit.com**
