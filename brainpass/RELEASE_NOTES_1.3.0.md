# Release 5 (1.3.0) — Play Console notes

## "What's new" (paste into Play Console, <500 chars)

Setup now finishes cleanly the first time — we fixed a rare case where the
last step could run twice.

We also added privacy-safe analytics so we can see where setup gets stuck and
fix it. Still no ads and no advertising ID, and nothing your child types or
answers ever leaves their device.

## What actually changed

- **Firebase Analytics added** (`lib/analytics.dart`, `Analytics.kt`). Measures
  the onboarding funnel and real retention. Configured for a child audience:
  AD_ID stripped, ad personalisation / ad-user-data / SSAID all disabled in the
  manifest. See `ANALYTICS.md`.
- **Bug fix:** onboarding's `_finish()` was scheduled from `build()` with no
  guard, so a rebuild in the window before the router swapped the widget out
  could run it two or three times — firing the engine sync, the profile sync
  and the activation event more than once. Now guarded.
- **`AuthFailure` carries a stable `code`**, so a sign-in failure is reportable
  by machine reason rather than by parent-facing copy.
- Legal docs updated (`legal/DATA_SAFETY.md`, `legal/PRIVACY_POLICY.md`) to
  declare analytics.

## BEFORE rolling out — required

1. **Re-submit the Play Data Safety form.** Tick App activity → App
   interactions, purposes Analytics + App functionality. The build must not go
   live ahead of this: the previous declaration says no analytics SDK, which
   this build makes false.
2. Confirm the website's updated privacy policy is deployed (nupo-website
   commit `12f34e4` is pushed; check it is live).

## Verify the artifact before upload

    unzip -p build/app/outputs/bundle/release/app-release.aab \
      base/manifest/AndroidManifest.xml | strings | grep permission.AD_ID

Must print NOTHING. INTERNET must be present, and the four
`google_analytics_*` flags must be there.
