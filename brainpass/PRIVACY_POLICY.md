# BrainPass — Privacy Policy

_Last updated: 2026-06-24_

**Short version: BrainPass collects nothing and transmits nothing. Everything
stays on your device.**

## What we collect

Nothing. BrainPass does not collect, store off-device, or transmit any personal
information about you or your child.

## What stays on the device

To do its job, BrainPass saves a few settings **locally on the phone only**:

- The parent PIN (stored as a one-way salted hash, never the actual digits).
- The child's age band and the questions/minutes "exchange rate".
- Which apps you chose to gate.
- How many minutes have been earned/used today, and when each app's earned time
  expires.

This information never leaves the device. There is no account, no login, and no
cloud server. If you uninstall the app, this information is gone.

## What we do NOT use

- No analytics or usage tracking.
- No advertising or ad networks.
- No crash-reporting or attribution SDKs.
- No location, camera, microphone, or contacts access.
- No internet permission at all — the app cannot send data even in principle.

## Permissions and why

- **Display over other apps** — to show the learning card over a gated app.
- **Accessibility service** — to detect which app your child has opened so the
  card can appear. BrainPass reads only which app is in front; it does not read,
  store, or transmit screen contents.
- **Run a foreground service / ignore battery optimisation** — so gating keeps
  working reliably in the background.
- **Query installed apps** — so the parent can pick which apps to gate.

## Children's privacy

BrainPass is designed for children and intentionally collects no personal
information, including no persistent identifiers. Because nothing is collected
or transmitted, there is no data to share, sell, or expose.

## Contact

Questions about this policy: <add your contact email before publishing>.

---

> Note for the developer: this honest "we collect nothing" policy matches the
> build (see build spec §4). Keep it accurate — if you ever add a network
> feature, analytics, or ads, this policy and your Google Play Data Safety
> answers MUST be updated, and a lawyer should review the children's-privacy
> implications first.
