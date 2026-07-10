# Nupo — Privacy Policy

**Effective date:** July 6, 2026
**App:** Nupo (Android, package `app.nupo.kid`)
**Provided by:** InternSpirit Private Limited (India)
**Contact:** vishnu@internspirit.com

Nupo is a daily learning app for children aged 5–11, set up and controlled entirely by a parent or guardian. This policy explains what we collect, why, and the choices you have. We wrote it to be read, not skimmed — it's short because we collect very little.

## The short version

- The **parent** creates the account with their **phone number**. That's the only personal identifier we collect.
- **Children never create accounts, enter personal information, or see ads.**
- Almost everything Nupo does — detecting apps, showing lessons, counting minutes — happens **entirely on the device** and is never uploaded.
- We show no ads, use no advertising or marketing SDKs, and **never sell or share data** with anyone except our infrastructure provider (Google Firebase).

## Information we collect (parent account)

When a parent signs in and uses Nupo, we store the following in our cloud database (Google Firebase, operated by Google LLC):

| Data | Purpose |
|---|---|
| Parent's phone number | Account sign-in (one-time SMS code) and, occasionally, to contact you about Nupo — e.g. to ask for feedback or tell you about important changes |
| Account created / last active timestamps | Understanding whether Nupo is being used |
| App version, device model, manufacturer, Android version | Debugging and support |
| Child's **age band** (a coarse range, never a birth date or name) | Understanding which age groups use Nupo |
| Number of apps selected for lessons (a count only — **not** which apps) | Understanding how Nupo is configured |

We do **not** collect: your child's name, birth date, photos, contacts, messages, location, browsing history, the apps installed on the device, which apps you gate, or your child's answers to questions.

## Information that stays on the device

The following is stored **only on the device** and is never transmitted to us or anyone else:

- The parent PIN (stored as a salted cryptographic hash — we cannot read it)
- The list of apps you chose to attach lessons to, and each app's rules
- Daily usage and earned-time counters
- Everything about the child's learning session (questions shown, answers given)

Nupo uses the **Usage Access** permission to detect, on-device, when a chosen app comes to the foreground. This information is processed in the moment and is **never uploaded, logged, or shared**. The **Display over other apps** permission is used solely to show the lesson screen. Nupo requests no SMS, contacts, camera, microphone, or location permissions.

## Children's privacy

Nupo is used by children under a parent-controlled lock, and we take that seriously:

- We collect **no personal information from children**. The account, phone number, and all settings belong to the parent.
- The child-facing screens contain **no ads, no external links, no purchases, and no data entry** beyond answering learning questions, which are processed on-device and never stored or transmitted.
- The only child-related data we hold is the coarse age band the **parent** selected, which cannot identify a child.

If you believe we have inadvertently collected personal information from a child, contact vishnu@internspirit.com and we will delete it promptly.

## Where your data lives, and who processes it

Account data is stored in **Google Firebase** (Authentication and Cloud Firestore), a service operated by Google LLC. Google acts as our data processor; its handling of data is described in Google's own privacy documentation. SMS sign-in codes are delivered through Google's SMS infrastructure and carrier networks. All data is encrypted in transit (TLS), and database access rules ensure each account can only ever read or write its own record.

We use **no analytics SDKs, no advertising SDKs, and no data brokers**. We do not sell, rent, or share your personal information with third parties for their own purposes.

## How long we keep data

We keep your account record for as long as your account exists. When you delete your account (see below), your account and profile record are permanently deleted from our systems. Data stored only on your device is yours: it's removed when you clear Nupo's storage or uninstall the app.

## Your rights and choices

You can, at any time:

- **View** what we hold about you — email us and we'll send you a copy.
- **Delete** your account and all associated data — in the app (Settings → Account → Delete account) or by emailing us. See our [Data Deletion page](DATA_DELETION.md).
- **Correct** the phone number by deleting the account and signing up with a new one.

We respond to all requests within 30 days. Depending on where you live, you may have additional rights under laws such as the GDPR or India's DPDP Act; we honour reasonable requests regardless of jurisdiction.

## Changes to this policy

If we change what we collect or how we use it, we will update this policy and its effective date, and — for material changes — inform you in the app before the change applies.

## Contact

Questions, requests, or concerns: **vishnu@internspirit.com**
