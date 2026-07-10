// remote_config_service.dart
//
// A tiny remote kill-switch for paywall enforcement, backed by a single
// Firestore doc (`config/app`, field `paywallEnabled`). This lets us turn the
// hard paywall on/off for every installed user WITHOUT shipping a new Play
// Store release — essential while a payment processor (Billdesk) is still
// being verified, and useful again for any future RevenueCat/Play Billing
// outage.
//
// Fail-safe by design: defaults to NOT enforcing the paywall. A user must be
// PROVEN (by a successful Firestore read) to be under an active enforcement
// flag before the gate shows — any read failure (offline, first launch, rules
// misconfigured) falls back to the safe "let them in" state rather than
// bricking the app.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RemoteConfigService {
  static const _docPath = 'config/app';
  static const _cacheKey = 'nupo_paywall_enabled';

  /// Whether the paywall gate should be enforced right now.
  static final ValueNotifier<bool> paywallEnabled = ValueNotifier(false);

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      paywallEnabled.value = prefs.getBool(_cacheKey) ?? false;
    } catch (_) {}
    unawaited(refresh());
  }

  static Future<void> refresh() async {
    try {
      final snap = await FirebaseFirestore.instance.doc(_docPath).get();
      final enabled = snap.data()?['paywallEnabled'] as bool? ?? false;
      paywallEnabled.value = enabled;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cacheKey, enabled);
    } catch (_) {
      // Keep the cached/default value — never let a config-fetch problem
      // change whether the app is usable.
    }
  }
}
