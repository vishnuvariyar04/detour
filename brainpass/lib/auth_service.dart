// auth_service.dart
//
// Thin wrapper around Firebase Auth so the rest of the app never imports
// firebase directly. Login is a MANDATORY parent gate (a hard paywall
// follows), but the app stays offline-first: once signed in, the session is
// cached by Firebase and the kid experience needs no network.
//
// ## Providers
//
// ANDROID: Google through the NATIVE account sheet (`google_sign_in`), plus
// email + password. Phone/OTP was removed on 2026-08-25 — the whole
// `verifyPhoneNumber` path is gone, not merely unused.
//
// Email/password needs the provider ENABLED in the Firebase console
// (Authentication → Sign-in method → Email/Password). Without it every attempt
// fails with `operation-not-allowed`.
//
// Apple is deliberately NOT offered on Android: it is mandatory on iOS only,
// and on Android it can only be done as a browser redirect. An account created
// with Apple on iOS therefore cannot sign in here — [reauthenticate] still
// handles `apple.com` so such an account can be deleted, but there is no way
// to sign INTO one from this build.
//
// ## Setup this depends on (Firebase console, one-off)
//
// The native sheet needs the app's signing certificate registered, otherwise
// Google returns no ID token and sign-in fails:
//   1. Firebase console → project `nupo-e6a13` → Android app `app.nupo.kid`
//      → add the release SHA-1 AND SHA-256 (and the debug ones for local runs).
//   2. Re-download `google-services.json` into `android/app/`. It must contain
//      a non-empty `oauth_client` array afterwards — an empty one means the
//      fingerprints were never registered and login WILL fail.
//   3. The Web client id (client_type 3) is the `serverClientId` below; pass it
//      via `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` if the plugin cannot
//      infer it.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'engine.dart';
import 'storage.dart';

/// A sign-in problem already phrased for a parent. [cancelled] marks the user
/// backing out, which should never be shown as an error.
class AuthFailure implements Exception {
  final String message;
  final bool cancelled;
  const AuthFailure(this.message, {this.cancelled = false});

  @override
  String toString() => message;
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Web OAuth client id (`client_type: 3` in `google-services.json`).
  ///
  /// On Android the native sheet only returns an ID TOKEN when it knows the
  /// backend it is authenticating for, so this is required rather than
  /// optional. OAuth client ids are public — they ship inside the APK — so
  /// this is not a secret. Override per-build with
  /// `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` if the project changes.
  static const _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '1070595284454-m5vk28f4lluckdhgdbkk4mg95v250t5g.apps.googleusercontent.com',
  );

  static bool _googleInitialised = false;

  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;
  static String? get email => _auth.currentUser?.email;
  static String? get displayName => _auth.currentUser?.displayName;
  static String? get uid => _auth.currentUser?.uid;

  /// Which provider this account was created with.
  static String? get providerId {
    final providers = _auth.currentUser?.providerData ?? const [];
    return providers.isEmpty ? null : providers.first.providerId;
  }

  static String get providerLabel => switch (providerId) {
        'google.com' => 'Google',
        'apple.com' => 'Apple',
        'password' => 'your email',
        _ => 'your account',
      };

  /// Emits on sign-in / sign-out. Drives the top-level router.
  static Stream<User?> authState() => _auth.authStateChanges();

  // ---------------------------------------------------------------------------
  // Google
  // ---------------------------------------------------------------------------

  static Future<void> _ensureGoogle() async {
    if (_googleInitialised) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
    );
    _googleInitialised = true;
  }

  static Future<UserCredential> signInWithGoogle() async {
    try {
      await _ensureGoogle();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        // Almost always the missing SHA fingerprint — see the header note.
        throw const AuthFailure(
          "Google didn't return a sign-in token. Check that this app's "
          'signing certificate is registered in Firebase.',
        );
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure('cancelled', cancelled: true);
      }
      throw AuthFailure(errorMessage(e));
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(errorMessage(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Email + password
  // ---------------------------------------------------------------------------

  static Future<UserCredential> signInWithEmail(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(errorMessage(e));
    }
  }

  static Future<UserCredential> createWithEmail(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(errorMessage(e));
    }
  }

  /// Firebase always reports success here, even for an address with no
  /// account — that is deliberate on their side (it stops the endpoint being
  /// used to test whether an email is registered), so the UI must not claim
  /// the mail was definitely sent to an existing account.
  static Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(errorMessage(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Sign out / delete
  // ---------------------------------------------------------------------------

  static Future<void> signOut() async {
    try {
      if (_googleInitialised) await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Clearing the Google session is best-effort.
    }
    await _auth.signOut();
  }

  /// Firebase requires a RECENT login before `delete()`. Re-runs whichever
  /// provider the account was created with.
  ///
  /// `apple.com` is handled through the web provider flow only so an account
  /// made on iOS can still be deleted from Android; there is no Apple SIGN-IN
  /// on this platform.
  static Future<void> reauthenticate() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Not signed in.');

    if (providerId == 'apple.com') {
      await user.reauthenticateWithProvider(AppleAuthProvider());
      return;
    }

    if (providerId == 'password') {
      // Handled by the caller, which has to collect the password — there is
      // nothing to re-run silently.
      throw const AuthFailure('reauth-password');
    }

    try {
      await _ensureGoogle();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure("Google didn't return a sign-in token.");
      }
      await user.reauthenticateWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure('cancelled', cancelled: true);
      }
      throw AuthFailure(errorMessage(e));
    }
  }

  /// Deletes the account and ALL data: the Firestore profile doc first (must
  /// happen while still authenticated — security rules require the matching
  /// uid), then the Auth user. Throws `requires-recent-login` if the session
  /// is stale — callers should re-authenticate first.
  static Future<void> deleteAccount() async {
    final u = _auth.currentUser;
    if (u == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(u.uid).delete();
    } catch (_) {
      // Don't block account deletion if the profile doc removal hiccups.
    }
    await u.delete();

    // "Delete my account" has to mean the device too. Without this the child's
    // name, the parent PIN, the gated apps and their rules survived on the
    // phone, and the next account to sign in inherited them.
    try {
      await Storage.clearLocal();
      await syncToEngine(); // stop gating with rules that no longer exist
    } catch (_) {}
  }

  static bool isRecentLoginError(Object e) =>
      e is FirebaseAuthException && e.code == 'requires-recent-login';

  /// Parent-friendly message for any auth error.
  static String errorMessage(Object e) {
    if (e is AuthFailure) return e.message;
    if (e is GoogleSignInException) {
      return switch (e.code) {
        GoogleSignInExceptionCode.canceled =>
          'Sign in was cancelled. Try again when you are ready.',
        GoogleSignInExceptionCode.interrupted =>
          'That was interrupted. Please try again.',
        _ => 'Google sign-in did not work. Try again.',
      };
    }
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          return 'That email is already signed up with a different method.';
        case 'email-already-in-use':
          return 'That email already has an account. Sign in instead.';
        case 'invalid-email':
          return "That email address doesn't look right.";
        case 'weak-password':
          return 'Use at least 6 characters for the password.';
        case 'wrong-password':
        case 'user-not-found':
          return 'That email or password is not right.';
        case 'operation-not-allowed':
          return 'Email sign-in is not enabled yet. Try Google for now.';
        case 'invalid-credential':
          return 'That sign-in could not be verified. Try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many tries. Please wait a bit and try again.';
        case 'web-context-cancelled':
        case 'popup-closed-by-user':
          return 'Sign in was cancelled. Try again when you are ready.';
        case 'network-request-failed':
          return 'No internet. Connect and try again.';
        case 'quota-exceeded':
          return 'Nupo is busy right now. Try again in a moment.';
        case 'requires-recent-login':
          return 'For your security, sign in again first.';
        default:
          return 'That did not work. Try again.';
      }
    }
    return 'That did not work. Try again.';
  }
}
