// profile_service.dart
//
// The signed-in parent's profile + SAVED SETUP at `users/{uid}`.
//
// Two jobs:
//   * [sync]    — push the current setup up, so signing in on another phone
//                 (or after a reinstall) can get it back.
//   * [restore] — pull it down when a signed-in device has no local setup.
//
// Before 2026-08-25 this was write-only and stored nothing but segmentation
// fields, so signing in restored the ACCOUNT but none of the SETUP: a
// returning parent was walked through all five questions again, which is the
// bug this file now exists to fix.
//
// ## Privacy
//
// The child's first name and the owl's name are personal data belonging to a
// child, and they are uploaded here. That is a deliberate, documented change —
// `legal/PRIVACY_POLICY.md` and `legal/DATA_SAFETY.md` were updated in the
// same commit. They are readable only by the owning uid (Firestore rules), are
// never shared, and go with the account when it is deleted (see
// `AuthService.deleteAccount`, which removes this doc first).
//
// Sync stays fire-and-forget and fail-safe: Firestore's offline queue holds
// writes until there is network, and every error is swallowed — profile sync
// must never affect the app.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';
import 'engine.dart';
import 'storage.dart';

class ProfileService {
  static DocumentReference<Map<String, dynamic>>? _doc() {
    final user = AuthService.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.uid);
  }

  /// Push profile + setup. Called on sign-in, app start (when signed in), and
  /// whenever setup changes.
  static Future<void> sync() async {
    try {
      final user = AuthService.currentUser;
      final doc = _doc();
      if (user == null || doc == null) return;
      final info = await Engine.deviceInfo();

      final data = <String, Object?>{
        // Phone auth was removed 2026-08-25; accounts are Google now.
        'email': user.email,
        'displayName': user.displayName,
        'provider': AuthService.providerId,
        'lastActive': FieldValue.serverTimestamp(),
        'appVersion': info['appVersion'],
        'deviceModel': info['model'],
        'deviceManufacturer': info['manufacturer'],
        'androidVersion': info['androidVersion'],
        'onboardingComplete': Storage.onboardingComplete,
        if (Storage.attribution.isNotEmpty) 'attribution': Storage.attribution,
      };

      // The restorable setup. Only written once onboarding has actually
      // finished, so a half-finished run on one phone cannot overwrite a good
      // setup on another.
      if (Storage.onboardingComplete) {
        data['setup'] = <String, Object?>{
          'childName': Storage.childName,
          'owlName': Storage.owlName,
          'childAge': Storage.childAge,
          'ageBand': Storage.ageBand,
          'subject': Storage.onbSubject,
          'gatedApps': Storage.gatedApps,
          'appRules': {
            for (final e in Storage.appRules.entries) e.key: e.value.toJson(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        };
      }

      // Stamp createdAt only once (skip silently when offline-and-uncached).
      try {
        final snap = await doc.get();
        if (!snap.exists || snap.data()?['createdAt'] == null) {
          data['createdAt'] = FieldValue.serverTimestamp();
        }
      } catch (_) {}

      await doc.set(data, SetOptions(merge: true));
    } catch (_) {
      // Never let profile sync break the app.
    }
  }

  /// Pull a saved setup down onto this device.
  ///
  /// Only runs when there is nothing to lose locally — if this install has
  /// already completed onboarding, the local copy wins and nothing is
  /// overwritten. Returns true when a setup was restored.
  static Future<bool> restore() async {
    if (Storage.onboardingComplete) return false;
    try {
      final doc = _doc();
      if (doc == null) return false;

      // Server-first: a cached empty doc from a previous signed-out session
      // must not be mistaken for "this account has no setup".
      final snap = await doc.get(const GetOptions(source: Source.server));
      final setup = snap.data()?['setup'] as Map<String, dynamic>?;
      if (setup == null) return false;

      final apps = (setup['gatedApps'] as List?)?.cast<String>() ?? const [];
      if (apps.isEmpty) return false; // nothing worth restoring

      await Storage.setChildName((setup['childName'] as String?) ?? '');
      final owl = (setup['owlName'] as String?) ?? '';
      if (owl.isNotEmpty) await Storage.setOwlName(owl);
      await Storage.setChildAge((setup['childAge'] as num?)?.toInt() ?? 8);
      await Storage.setAgeBand((setup['ageBand'] as String?) ?? 'b');
      await Storage.setOnbSubject((setup['subject'] as String?) ?? '');
      await Storage.setGatedApps(apps);

      final rawRules = (setup['appRules'] as Map?) ?? const {};
      await Storage.setAppRules({
        for (final e in rawRules.entries)
          e.key as String:
              AppRule.fromJson(Map<String, dynamic>.from(e.value as Map)),
      });
      // Drop rules for apps that are no longer gated, and default any missing.
      await Storage.reconcileRules();
      await Storage.setOnboardingComplete(true);
      // The story is part of the pitch, not the setup — a returning parent
      // has already seen it.
      await Storage.setStorySeen(true);
      return true;
    } catch (_) {
      // Offline or unreadable: fall through to normal onboarding rather than
      // blocking the parent behind a network call.
      return false;
    }
  }
}
