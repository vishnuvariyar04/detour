// profile_service.dart
//
// Writes/refreshes the signed-in parent's profile doc at `users/{uid}` so the
// business side (feedback outreach, future subscriptions) has a contactable,
// segmentable list. Fire-and-forget and fail-safe by design: Firestore's
// offline queue holds writes until there's network, and any error is swallowed
// — profile sync must never affect the app.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_service.dart';
import 'engine.dart';
import 'storage.dart';

class ProfileService {
  /// Sync the profile doc. Called on sign-in, app start (when signed in), and
  /// when onboarding completes (to capture age band / app count).
  static Future<void> sync() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;
      final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final info = await Engine.deviceInfo();

      final data = <String, Object?>{
        'phoneNumber': user.phoneNumber,
        'lastActive': FieldValue.serverTimestamp(),
        'appVersion': info['appVersion'],
        'deviceModel': info['model'],
        'deviceManufacturer': info['manufacturer'],
        'androidVersion': info['androidVersion'],
        'ageBand': Storage.ageBand,
        'gatedAppsCount': Storage.gatedApps.length,
        'onboardingComplete': Storage.onboardingComplete,
      };

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
}
