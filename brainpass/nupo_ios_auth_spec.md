# Nupo — iOS Authentication Specification
### Sign in with Apple + Google (Gmail), Firebase-only, no phone number

> **Status:** v1 — written 2026-07-30, reconciled against the live Android codebase.
>
> **Audience:** an iOS developer (with the Android repo `brainpass/`) building the iOS version. This doc covers **only auth** — login, sign-up, account identity, the Firestore profile the console shows, sign-out, and account deletion. For the rest of the iOS build (App Intents gate, quiz engine, onboarding) see `nupo_ios_spec.md`.
>
> **The one-line decision:** Android uses **Firebase phone-number OTP**. iOS will use **Firebase Auth with two providers — Sign in with Apple and Google** — and **no phone number**. Everything downstream (Firestore `users/{uid}` profile, RevenueCat identity, the RootRouter gate, account deletion) stays structurally identical; only the *credential* changes.

---

## 0. TL;DR for the impatient

1. Keep the **exact same architecture**: a single `AuthService` wrapping Firebase, a reactive `RootRouter` that swaps screens on `authStateChanges()`, a Firestore `users/{uid}` profile doc, and RevenueCat keyed to the Firebase UID. Only the sign-in *method* differs.
2. Offer **two buttons**: "Continue with Apple" and "Continue with Google." No text fields, no OTP, no country picker.
3. **Sign in with Apple is MANDATORY** the moment you offer Google — App Store Review Guideline **4.8**. Shipping Google-only is an automatic rejection.
4. Firebase identity type flips from `phoneNumber` → **`email` + `displayName` + `provider`**. Update the Firestore profile fields accordingly (§6).
5. Apple returns the user's **name/email only on the FIRST authorization, ever**. Capture and persist it then, or it's gone (§4.4 — the #1 gotcha).
6. Account deletion (Guideline **5.1.1(v)**) still required; re-auth uses a fresh provider sign-in instead of a fresh OTP (§7).
7. This is a **Kids Category** app — put the login behind a **parental gate** and keep the privacy posture (no analytics/ads/tracking) intact (§9).

---

## 1. HOW IT WORKS TODAY ON ANDROID (the thing we're mirroring)

### 1.1 The pieces
| File | Role |
|---|---|
| `lib/auth_service.dart` | The **only** file that imports `firebase_auth`. Static wrapper: `sendVerification`, `signInWithSmsCode`, `signOut`, `deleteAccount`, `reauth*`, `authState()`, `errorMessage()`. Everything else calls this. |
| `lib/screens/login/login_flow.dart` | The UI: **phone number → 6-digit OTP**. Country picker (default 🇮🇳 +91), strips leading zeros → E.164, 60 s resend cooldown, supports Firebase on-device auto-verification. |
| `lib/screens/login/reauth_delete_screen.dart` | Sends a fresh OTP to the signed-in number, re-authenticates, then deletes the account. |
| `lib/main.dart` → `RootRouter` | Reactive gate. Subscribes to `AuthService.authState()`; not signed in → `LoginFlow`, signed in + not onboarded → `OnboardingFlow`, onboarded + no Pro → `PaywallGateScreen`, else `ActiveLanding`. Sign-out anywhere drops straight back to login (a child can never pass the gate). |
| `lib/profile_service.dart` | On sign-in / app-start / onboarding-finish, merges a Firestore `users/{uid}` doc (the "information shown in the console"). Fire-and-forget, fully fail-safe. |
| `lib/subscription_service.dart` | `Purchases.logIn(firebaseUid)` — RevenueCat subscription follows the account. |
| `lib/screens/parent_home_screen.dart` | The **Account** section (behind the parent PIN): shows the identity, **Sign out**, **Delete account**. |

### 1.2 The rules that DON'T change on iOS
- **Login is mandatory and non-skippable** — a hard paywall follows, and the kid must never reach settings/purchases. `RootRouter` enforces this; keep it verbatim.
- **Firebase is the whole backend.** No custom auth server. Project **`nupo-e6a13`** (Blaze plan).
- **Identity = Firebase UID.** RevenueCat, Firestore doc key, and security rules all hang off `request.auth.uid`. Providers change; the UID contract does not.
- **Offline-first.** Once signed in, Firebase caches the session; the kid-facing experience needs no network. Auth only matters at the parent gate.
- **Everything auth-related is fail-safe.** `Firebase.initializeApp()` is wrapped in try/catch in `main()` and must never brick the offline app. Profile sync is fire-and-forget. Keep this discipline.

### 1.3 What the console shows today
- **Firebase Auth console:** one user row per parent, identified by **phone number**, with a UID.
- **Firestore `users/{uid}`:** `phoneNumber`, `createdAt` (once) / `lastActive` (serverTimestamp), `appVersion`, `deviceModel` / `deviceManufacturer` / `androidVersion`, `ageBand`, `gatedAppsCount`, `onboardingComplete`, and `attribution` (if set). **No child data ever.**
- `config/app` — a single read-only doc (`paywallEnabled` kill-switch, read by `RemoteConfigService`).

---

## 2. WHAT CHANGES ON iOS (and what doesn't)

| Concern | Android (today) | iOS (this spec) |
|---|---|---|
| Sign-in method | Phone OTP | **Sign in with Apple + Google** |
| Identity shown in console | `phoneNumber` | `email` + `displayName` + `providerId` |
| UI | phone field + OTP keypad | **two provider buttons** |
| Re-auth (for delete) | fresh OTP | fresh provider sign-in |
| APNs / silent push | **required** (phone auth uses it) | **not required** for Apple/Google (only phone auth needs APNs) |
| Firebase backend | `nupo-e6a13` | **same project**, add an iOS app + enable 2 providers |
| RevenueCat identity | Firebase UID | **same** — Firebase UID |
| Firestore rules | uid-scoped | **same** — uid-scoped |
| RootRouter gate | reactive on authState | **same, verbatim** |

**Net:** `auth_service.dart` gets new sign-in methods and `login_flow.dart` becomes a two-button screen. `profile_service.dart` swaps `phoneNumber` for `email`/`displayName`/`provider`. Nearly everything else is untouched.

---

## 3. FIREBASE + APPLE + XCODE SETUP (do this before writing code)

### 3.1 Firebase Console
1. In project **`nupo-e6a13`** → **Add app → iOS**. Bundle ID must match your Xcode target (e.g. `app.nupo.kid` — keep it consistent with Android's package intent, but iOS bundle IDs are independent; pick one and use it everywhere).
2. Download **`GoogleService-Info.plist`** → add to the Xcode `Runner` target (drag in, "Copy items if needed", target-checked). This is the iOS analogue of `google-services.json`.
3. **Authentication → Sign-in method → enable:**
   - **Apple** — no extra fields needed for a **native iOS-only** flow (the Service ID / key are only needed for Android/Web Apple sign-in or the email-relay proxy; you can leave them until you add those platforms).
   - **Google** — note the **Web client ID** it auto-creates (some flows need it as `serverClientId`).
4. **Authentication → Settings → Authorized domains** — already fine for native.

### 3.2 Apple Developer (developer.apple.com)
1. Paid Apple Developer Program membership (already required to ship).
2. **Certificates, Identifiers & Profiles → your App ID → enable the "Sign in with Apple" capability.**
3. (Only if you later add Android/Web Apple sign-in or want Apple's email-relay to forward: create a **Services ID**, a **Sign in with Apple key (.p8)**, note the **Key ID** and **Team ID**, and paste them into Firebase's Apple provider config. **Not needed for iOS-native v1.**)

### 3.3 Xcode capabilities & Info.plist
- **Signing & Capabilities → + Capability → "Sign in with Apple".** (This writes the entitlement.)
- **Google URL scheme:** open `GoogleService-Info.plist`, copy **`REVERSED_CLIENT_ID`**, and add it to `Info.plist` under `CFBundleURLTypes` (Google's SDK completes its flow via this callback):
  ```xml
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>com.googleusercontent.apps.XXXXXXXX-XXXXXXXX</string> <!-- = REVERSED_CLIENT_ID -->
      </array>
    </dict>
  </array>
  ```
- **No APNs key, no Push Notifications capability** are needed for Apple/Google sign-in. (You only need those if you *also* keep phone auth — we are not.)

### 3.4 `pubspec.yaml`
Keep `firebase_core`, `firebase_auth`, `cloud_firestore` (already present). **Remove nothing Firebase.** Add:
```yaml
  google_sign_in: ^7.x        # native Google account picker
  sign_in_with_apple: ^7.x    # native Apple sheet + nonce helper
  crypto: ^3.0.7              # already present — used for the Apple nonce SHA-256
```
> ⚠️ **Version-sensitive:** `google_sign_in` had a **major API redesign at v7** (`GoogleSignIn.instance`, `initialize()`, `authenticate()`). The snippets below show the *shape*; **confirm the exact method names against the version you pin**. `sign_in_with_apple` is stable. If you'd rather avoid the native Google SDK entirely, Firebase also supports a web-based `signInWithProvider(GoogleAuthProvider())` — simpler to wire, slightly worse UX (a Safari sheet instead of the native account picker). Either is acceptable; native is recommended.

---

## 4. THE NEW `auth_service.dart` (iOS)

Same shape as today — one static wrapper, everything else calls it — with the phone methods replaced by two provider methods. `authState()`, `signOut()`, `currentUser`, and `deleteAccount()` are essentially unchanged.

### 4.1 Sign in with Google
```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

static Future<UserCredential> signInWithGoogle() async {
  // NOTE: google_sign_in v7 API shape — verify names against your pinned version.
  final google = GoogleSignIn.instance;
  await google.initialize(); // once; safe to call again
  final account = await google.authenticate(); // native account picker
  final auth = account.authentication;         // { idToken }
  final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
  return FirebaseAuth.instance.signInWithCredential(credential);
}
```

### 4.2 Sign in with Apple (with the required nonce)
Apple credentials must be tied to a **nonce**: you send a SHA-256 hash to Apple and pass the *raw* nonce to Firebase, which prevents replay. This is mandatory — Firebase rejects Apple credentials without it.
```dart
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

static String _rawNonce([int len = 32]) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
  final rng = Random.secure();
  return List.generate(len, (_) => chars[rng.nextInt(chars.length)]).join();
}
static String _sha256(String s) => sha256.convert(utf8.encode(s)).toString();

static Future<UserCredential> signInWithApple() async {
  final raw = _rawNonce();
  final appleCred = await SignInWithApple.getAppleIDCredential(
    scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    nonce: _sha256(raw),          // hashed nonce goes to Apple
  );
  final oauth = OAuthProvider('apple.com').credential(
    idToken: appleCred.identityToken,
    rawNonce: raw,                // raw nonce goes to Firebase
  );
  final result = await FirebaseAuth.instance.signInWithCredential(oauth);

  // ⭐ Apple only sends the name on the FIRST authorization — capture it now.
  final given = appleCred.givenName, family = appleCred.familyName;
  if ((given != null || family != null) &&
      (result.user?.displayName?.isEmpty ?? true)) {
    final name = [given, family].whereType<String>().join(' ').trim();
    if (name.isNotEmpty) await result.user?.updateDisplayName(name);
  }
  return result;
}
```

### 4.3 Unchanged bits
```dart
static User? get currentUser => FirebaseAuth.instance.currentUser;
static bool get isLoggedIn => currentUser != null;
static String? get email => currentUser?.email;
static String? get displayName => currentUser?.displayName;
static Stream<User?> authState() => FirebaseAuth.instance.authStateChanges();
static Future<void> signOut() async {
  await GoogleSignIn.instance.signOut(); // clear the Google session too
  await FirebaseAuth.instance.signOut();
}
```
Keep `errorMessage(Object e)` — remap the codes that matter for OAuth: `account-exists-with-different-credential` (same email already used with the other provider — tell the parent which one to use), `canceled` / `SignInWithAppleAuthorizationException(code: canceled)` (silent no-op, not an error toast), `network-request-failed`, `too-many-requests`.

### 4.4 ⭐ The gotchas (read before you ship)
1. **Apple name/email is first-run-only.** On the very first authorization Apple returns `givenName`/`familyName`/`email`; on every subsequent sign-in they're `null`. If you don't persist them on run one, they're gone forever (short of the user revoking access in iOS Settings and re-authorizing). §4.2 captures the name into `displayName`; do the same if you need the email beyond `user.email`.
2. **"Hide My Email"** gives a relay address like `abc123@privaterelay.appleid.com`. It's a valid, deliverable address (Apple forwards it) — store it as-is; don't try to "fix" it. If you ever email these, you must register your sending domain in Apple's email-relay settings.
3. **Same person, two providers, one email.** If a parent signs in with Google then later taps Apple (or vice-versa) and both resolve to the same email, Firebase raises `account-exists-with-different-credential`. Simplest v1 policy: catch it and tell them "You already sign in with Google — use that button." (Account *linking* is a nice-to-have, not needed for launch.)
4. **Cancel is not failure.** Both sheets can be dismissed; treat cancellation as a no-op (return to the login screen), never an error dialog.

---

## 5. THE LOGIN UI (`login_flow.dart` → two buttons)

Replace the phone + OTP steps with a **single screen**. Keep the existing chrome: `HaloMascot('assets/mascot_pin.png')`, the title, the soft-purple `bgDecoration`, `PrimaryButton` styling language.

```
        🦉  (HaloMascot)

     Hi! Sign in to start
   One tap — it's how we keep
   your child's plan just for them.

   [    Continue with Apple    ]   ← black pill, Apple logo (HIG-compliant)
   [   G  Continue with Google  ]   ← white pill, Google "G"

   Parents only • We never post anything
```

Rules:
- **Apple button must follow Apple's Human Interface Guidelines** (use the official `SignInWithAppleButton` from the package, or an exactly-compliant custom button: correct corner radius, logo, "Continue with Apple" wording, black/white per background). Non-compliant Apple buttons get rejected.
- **Order/prominence:** Apple's guidance is that Sign in with Apple should be presented **at least as prominently** as other options. Put it first (top) with equal size.
- On success, do **nothing navigational** — `RootRouter` sees the auth-state change and swaps the screen (identical to today). The login screen just calls `AuthService.signInWithApple()` / `signInWithGoogle()` and shows a busy spinner in-button.
- Keep the busy/`error` handling pattern from the current `login_flow.dart` (in-button spinner, one-line error text under the buttons).
- **No back button** on this screen (it's the root when signed out), same as today.

---

## 6. THE FIRESTORE PROFILE (the "information shown in the console")

`profile_service.dart` stays fire-and-forget and fail-safe; only the identity fields change. Swap `phoneNumber` for email/name/provider and the device fields for iOS values.

```dart
final user = AuthService.currentUser;
final info = await Engine.deviceInfo(); // native iOS: model + iOS version (see note)
final data = <String, Object?>{
  'email'      : user.email,                         // was: phoneNumber
  'displayName': user.displayName,                   // new (may be null on Google-relay/Apple-hide)
  'provider'   : user.providerData.isNotEmpty
                   ? user.providerData.first.providerId  // 'apple.com' | 'google.com'
                   : null,
  'platform'   : 'ios',                              // new — distinguishes from Android rows
  'lastActive' : FieldValue.serverTimestamp(),
  'appVersion' : info['appVersion'],
  'deviceModel': info['model'],                      // e.g. "iPhone14,3"
  'iosVersion' : info['osVersion'],                  // was: androidVersion
  'ageBand'    : Storage.ageBand,
  'gatedAppsCount': Storage.gatedApps.length,
  'onboardingComplete': Storage.onboardingComplete,
  if (Storage.attribution.isNotEmpty) 'attribution': Storage.attribution,
};
// createdAt stamped once (unchanged logic); merge with SetOptions(merge: true).
```
- **Device info:** the Android side reads model/manufacturer/OS via a native `deviceInfo` MethodChannel (no plugin). Mirror that with a tiny Swift handler returning `UIDevice`/`ProcessInfo` values, or just add the `device_info_plus` package on iOS — either is fine; keep it fail-safe.
- **Console result:** the Firebase **Auth** tab now lists parents by **email** with a provider icon (Apple/Google); **Firestore `users/{uid}`** carries the fields above. Still **no child data** ever leaves the device — names, survey answers, quiz content stay local (matches the privacy posture).
- **Security rules are unchanged** (keep them as-is): `users/{uid}` readable/writable only when `request.auth.uid == uid`. `config/app` world-readable, no client writes.
  ```
  match /users/{uid} {
    allow read, write: if request.auth != null && request.auth.uid == uid;
  }
  match /config/app { allow read: if true; allow write: if false; }
  ```

---

## 7. SIGN-OUT & ACCOUNT DELETION

Apple **requires in-app account deletion** for any app that supports account creation (Guideline **5.1.1(v)**) — same requirement as Play, so the existing **Account** section in `parent_home_screen.dart` carries over. The only change is how **re-authentication** works (Firebase demands a *recent* login before `user.delete()`).

- **Sign out:** `AuthService.signOut()` (now also clears the Google session). `RootRouter` returns to the login screen.
- **Delete:** try `deleteAccount()` (deletes the `users/{uid}` doc first — while still authed so rules pass — then `user.delete()`). If it throws `requires-recent-login`, **re-authenticate by re-running the same provider sign-in**, then retry — replacing the Android "fresh OTP" screen:
  ```dart
  // reauth_delete replacement (no OTP screen needed):
  try {
    await AuthService.deleteAccount();
  } on FirebaseAuthException catch (e) {
    if (e.code == 'requires-recent-login') {
      final provider = AuthService.currentUser?.providerData.first.providerId;
      if (provider == 'apple.com') {
        final raw = _rawNonce();
        final apple = await SignInWithApple.getAppleIDCredential(
          scopes: const [], nonce: _sha256(raw));
        await AuthService.currentUser!.reauthenticateWithCredential(
          OAuthProvider('apple.com').credential(
            idToken: apple.identityToken, rawNonce: raw));
      } else {
        await GoogleSignIn.instance.initialize();
        final acc = await GoogleSignIn.instance.authenticate();
        await AuthService.currentUser!.reauthenticateWithCredential(
          GoogleAuthProvider.credential(idToken: acc.authentication.idToken));
      }
      await AuthService.deleteAccount(); // retry
    } else { rethrow; }
  }
  ```
  This lets you **delete `reauth_delete_screen.dart`'s OTP UI** entirely and replace it with a re-auth-then-delete call (a confirm dialog + a system sign-in sheet).
- **Apple extra credit (not blocking for v1):** Apple *recommends* revoking the token on delete via `SignInWithApple.getKeychainCredential`/the revoke REST endpoint so the app disappears from the user's *Settings → Sign in with Apple* list. Requires the Services ID + key from §3.2. Nice-to-have; document it as a follow-up.
- **RevenueCat on delete:** unchanged — the entitlement is tied to the Firebase UID; a new account is a new UID. (Restore purchases still available on the paywall.)

---

## 8. RootRouter, RevenueCat, RemoteConfig — verbatim

No changes. The gate order stays **login → onboarding → paywall → home**, driven by `authStateChanges()`. `SubscriptionService.logIn(user.uid)` fires on the auth listener exactly as today (the UID is provider-agnostic). `RemoteConfigService` reads `config/app.paywallEnabled` the same way. Keep `MainActivity extends FlutterFragmentActivity`'s iOS analogue concern out of scope — on iOS RevenueCat has no such requirement.

---

## 9. APP STORE REVIEW & KIDS CATEGORY (must-reads)

1. **Guideline 4.8 — Sign in with Apple is mandatory** whenever you offer a third-party or social login (Google counts). Ship both, Apple first/equal prominence. Google-only ⇒ rejection.
2. **Guideline 5.1.1(v) — account deletion** must be reachable in-app (§7).
3. **Kids Category rules (this app targets 5–11):**
   - **No third-party analytics or advertising SDKs**, and **no tracking / IDFA / ATT prompt.** The app already has none — keep it that way. Do not add any analytics to "measure logins."
   - **Parental gate before login.** Sign-in collects the parent's email (personal info) and leads to a paywall — both must sit **behind a parental gate** (a simple "ask a grown-up" math/hold challenge) so a child can't create an account or purchase. Android used a Play-Families gate; add the equivalent on iOS **before** the two provider buttons.
   - The account is the **parent's**; make copy explicit ("Parents only").
4. **Privacy nutrition label** must declare exactly what leaves the device: **email address** (+ optional name) for **App Functionality / Account**, and diagnostics (app version, device model, OS). **Not linked to tracking. No child data.** Mirror the Android Data Safety declaration, swapping "phone number" → "email address."
5. **Demo account for review:** because login now gates everything, give the reviewer either a **test Apple/Google account** or (cleaner) a **Firebase-authenticated demo path** — and grant the demo account **Pro** manually in RevenueCat so they can see past the paywall. Note this in App Review "Notes."
6. **Sign in with Apple button** must be HIG-compliant (§5).

---

## 10. BUILD ORDER

**Phase 0 — Firebase & capabilities (½ day)**
1. Add iOS app to `nupo-e6a13`, drop in `GoogleService-Info.plist`.
2. Enable **Apple** + **Google** providers in Firebase console.
3. Xcode: add **Sign in with Apple** capability; add the **REVERSED_CLIENT_ID** URL scheme.
4. Add `google_sign_in`, `sign_in_with_apple` to `pubspec.yaml`.

**Phase 1 — AuthService (1 day)**
5. Rewrite `auth_service.dart` with `signInWithGoogle()` + `signInWithApple()` (nonce!), keep `authState/signOut/currentUser/deleteAccount`, remap `errorMessage`.
6. Verify a round-trip sign-in on a **real device** (Apple sign-in doesn't work on Simulator reliably; Google does). Confirm a user row appears in the Firebase Auth console.

**Phase 2 — UI (1 day)**
7. Replace `login_flow.dart` with the two-button screen (§5), HIG-compliant Apple button, in-button busy state.
8. Add the **parental gate** ahead of it (§9.3).

**Phase 3 — Profile & delete (1 day)**
9. Update `profile_service.dart` fields (§6); verify the `users/{uid}` doc in the Firestore console.
10. Replace `reauth_delete_screen.dart` with re-auth-then-delete (§7); wire the **Account** section (email, provider, Sign out, Delete).

**Phase 4 — Review prep**
11. Privacy nutrition labels, demo account + manual Pro grant, App Review notes explaining the parental gate + auth.
12. TestFlight → confirm Apple sign-in works on a fresh install (first-run name capture) and a reinstall (name persists from Firestore/`displayName`).

---

## 11. QUICK REFERENCE — Firebase console checklist
- [ ] iOS app added to `nupo-e6a13`, `GoogleService-Info.plist` in the Runner target
- [ ] Auth → Sign-in method → **Apple** enabled
- [ ] Auth → Sign-in method → **Google** enabled (note the Web client ID)
- [ ] Firestore rules published (uid-scoped `users/{uid}`, read-only `config/app`) — same as Android
- [ ] Apple Developer: **Sign in with Apple** capability on the App ID
- [ ] Xcode: Sign in with Apple capability + `REVERSED_CLIENT_ID` URL scheme
- [ ] (later) Apple Services ID + .p8 key in Firebase only if you add Web/Android Apple sign-in or token revocation

---

## 12. WHAT WE EXPLICITLY DROP FROM THE ANDROID FLOW
- **Phone number, OTP, country picker, SMS, resend cooldown** — gone. (No `verifyPhoneNumber`, no APNs, no silent-push verification, no SMS cost, no test-phone-number setup.)
- **The `_PhoneStep` / `_OtpStep` widgets and the OTP `reauth_delete` screen** — replaced by two buttons and a system re-auth sheet.
- **SHA-256 upload/app-signing key registration in Firebase** (that's a *phone-auth* requirement) — not needed for Apple/Google.

Everything else — the mandatory gate, the fail-safe init, the Firestore profile, the RevenueCat-by-UID model, the account-deletion requirement, the offline-first posture — carries over unchanged.
