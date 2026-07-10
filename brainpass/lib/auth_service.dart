// auth_service.dart
//
// Thin wrapper around Firebase phone auth so the rest of the app never imports
// firebase directly. Login is a MANDATORY parent gate (a hard paywall follows),
// but the app stays offline-first: once signed in, the session is cached by
// Firebase and the kid experience needs no network.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;
  static String? get phoneNumber => _auth.currentUser?.phoneNumber;

  /// Emits on sign-in / sign-out. Drives the top-level router.
  static Stream<User?> authState() => _auth.authStateChanges();

  /// Send an OTP to [phoneE164] (e.g. "+919876543210"). Firebase may also
  /// auto-verify on-device (instant verification), which fires [onAutoVerified].
  static Future<void> sendVerification({
    required String phoneE164,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    required void Function(FirebaseAuthException e) onFailed,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    int? resendToken,
  }) {
    return _auth.verifyPhoneNumber(
      phoneNumber: phoneE164,
      timeout: const Duration(seconds: 60),
      verificationCompleted: onAutoVerified,
      verificationFailed: onFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
      forceResendingToken: resendToken,
    );
  }

  static Future<void> signInWithCredential(PhoneAuthCredential c) =>
      _auth.signInWithCredential(c);

  static Future<UserCredential> signInWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) {
    final cred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _auth.signInWithCredential(cred);
  }

  static Future<void> signOut() => _auth.signOut();

  /// Re-authenticate the current user with a fresh phone credential. Firebase
  /// requires this before sensitive ops (like delete) when the session is no
  /// longer "recent".
  static Future<void> reauthWithCredential(PhoneAuthCredential c) async {
    final u = _auth.currentUser;
    if (u != null) await u.reauthenticateWithCredential(c);
  }

  static Future<void> reauthWithSmsCode({
    required String verificationId,
    required String smsCode,
  }) {
    final cred = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return reauthWithCredential(cred);
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
  }

  static bool isRecentLoginError(Object e) =>
      e is FirebaseAuthException && e.code == 'requires-recent-login';

  /// Parent-friendly message for any auth error.
  static String errorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-phone-number':
          return "That number doesn't look right. Check and try again.";
        case 'missing-phone-number':
          return 'Please enter your phone number.';
        case 'invalid-verification-code':
          return "That code isn't right. Try again.";
        case 'session-expired':
        case 'code-expired':
          return 'That code expired. Tap Resend for a new one.';
        case 'too-many-requests':
          return 'Too many tries. Please wait a bit and try again.';
        case 'network-request-failed':
          return 'No internet — connect to Wi-Fi and try again.';
        case 'quota-exceeded':
          return 'Service is busy right now. Please try again later.';
        case 'requires-recent-login':
          return 'For your security, please sign in again first.';
        default:
          return e.message ?? 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
