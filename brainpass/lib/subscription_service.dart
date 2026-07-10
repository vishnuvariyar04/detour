// subscription_service.dart
//
// RevenueCat wrapper — the ONLY file that talks to purchases_flutter. Nupo Pro
// is a hard paywall (login -> onboarding -> paywall -> home).
//
// Design rules:
//  - RevenueCat identity = Firebase UID, so the subscription follows the
//    parent's account across devices and reinstalls.
//  - Offline-first: the last-known entitlement is cached in SharedPreferences
//    and used whenever the network/store is unreachable. The kid-facing guard
//    never depends on a live check.
//  - Fail-safe: nothing here may ever crash or block the app.
//
// NOTE: the key below is a RevenueCat TEST STORE key — purchases are simulated.
// Swap in the production `goog_` key (+ real Play Console products) at launch.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionService {
  // Debug builds use the RevenueCat Test Store (simulated purchases); release
  // builds use the production Google Play key. RevenueCat blocks a test key in
  // a release build, so this split is required, not just tidy.
  static final String _apiKey = kDebugMode
      ? 'test_qKnEaBphbeAGpRQcgmVISKWcKSr'
      : 'goog_SaVnrVeaftKhPExZSaDnCslpYCp';

  /// Entitlement identifier exactly as configured in the RevenueCat dashboard.
  static const entitlementId = 'nupo Pro';

  static const _cacheKey = 'nupo_has_pro';

  /// Live entitlement state; RootRouter listens to this to swap screens.
  static final ValueNotifier<bool> hasPro = ValueNotifier(false);

  static bool _configured = false;

  /// Configure the SDK. Called once at app start (after Firebase).
  static Future<void> init() async {
    try {
      // Start from the cached value so a cold offline launch keeps working.
      final prefs = await SharedPreferences.getInstance();
      hasPro.value = prefs.getBool(_cacheKey) ?? false;

      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
      await Purchases.configure(PurchasesConfiguration(_apiKey));
      _configured = true;
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);
      unawaited(refresh());
    } catch (_) {
      // Store unavailable (no Play services, offline first run…) — the cached
      // value stands and the app keeps working.
    }
  }

  static void _onCustomerInfo(CustomerInfo info) {
    final active = info.entitlements.active.containsKey(entitlementId);
    hasPro.value = active;
    SharedPreferences.getInstance().then((p) => p.setBool(_cacheKey, active));
  }

  /// Re-read customer info (cached by the SDK when offline).
  static Future<void> refresh() async {
    if (!_configured) return;
    try {
      _onCustomerInfo(await Purchases.getCustomerInfo());
    } catch (_) {}
  }

  /// Tie purchases to the signed-in parent (Firebase UID).
  static Future<void> logIn(String uid) async {
    if (!_configured) return;
    try {
      _onCustomerInfo((await Purchases.logIn(uid)).customerInfo);
    } catch (_) {}
  }

  /// Back to an anonymous RevenueCat user on sign-out.
  static Future<void> logOut() async {
    if (!_configured) return;
    try {
      if (!await Purchases.isAnonymous) {
        _onCustomerInfo(await Purchases.logOut());
      }
    } catch (_) {}
  }

  /// "Restore purchases" (required by store policy; also the rescue path when
  /// a purchase happened on another device).
  static Future<void> restore() async {
    if (!_configured) return;
    try {
      _onCustomerInfo(await Purchases.restorePurchases());
    } catch (_) {}
  }

  /// RevenueCat Customer Center: manage / cancel / refund flows.
  static Future<void> presentCustomerCenter() async {
    if (!_configured) return;
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (_) {}
    unawaited(refresh());
  }
}
