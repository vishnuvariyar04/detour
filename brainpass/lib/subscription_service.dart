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
// Debug builds use RevenueCat's Test Store (simulated purchases); release builds
// use the Google Play app. Play products: subscription `nupo_premium` (base
// plans `weekly`, `yearly`) and one-time `nupo_premium_lifetime`.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Result of a purchase, so the UI need not know RevenueCat's error types.
enum PurchaseOutcome { success, cancelled, failed }

class SubscriptionService {
  // Debug builds use the RevenueCat Test Store (simulated purchases); release
  // builds use the production Google Play key. RevenueCat blocks a test key in
  // a release build, so this split is required, not just tidy.
  static final String _apiKey = kDebugMode
      ? 'test_qKnEaBphbeAGpRQcgmVISKWcKSr'
      // RevenueCat project "Internspirit Private Limited" → app "Nupo Android"
      // (appd24701db4a, package app.nupo.kid). The old goog_ key here matched
      // no app in the project, so release-build purchases could never work.
      : 'goog_GLkUYxwNVSOaNgfwfWSkzdsThfX';

  /// Entitlement identifier exactly as configured in the RevenueCat dashboard
  /// (Product catalog → Entitlements). RevenueCat names the default entitlement
  /// after the project, and the project is "Internspirit Private Limited", so
  /// this is NOT "nupo Pro": checking that name would leave a parent who paid
  /// stuck on the paywall. Identifiers cannot be renamed in RevenueCat.
  static const entitlementId = 'Internspirit Private Limited Pro';

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
  /// a purchase happened on another device). True when Pro is active after.
  static Future<bool> restore() async {
    if (!_configured) return false;
    try {
      _onCustomerInfo(await Purchases.restorePurchases());
    } catch (_) {}
    return hasPro.value;
  }

  // ---------------------------------------------------------------------------
  // Offerings and purchase — used by the custom paywall (paywall_screen.dart),
  // ported from the iOS app's `Pro` class so both stores sell the same way.
  // ---------------------------------------------------------------------------

  /// The current offering's packages, ordered weekly → yearly → lifetime.
  /// Empty when RevenueCat isn't configured or the store returned nothing; the
  /// reason is kept in [lastPackagesError] for the paywall's error card.
  static Future<List<Package>> packages() async {
    if (!_configured) {
      lastPackagesError = 'sdk-not-configured';
      return const [];
    }
    try {
      final current = (await Purchases.getOfferings()).current;
      if (current == null) {
        lastPackagesError = 'no-current-offering';
        return const [];
      }
      final list = [...current.availablePackages];
      // RevenueCat drops a package whose Play product the store will not
      // return (wrong id, inactive, not sold in this country). That is a
      // configuration problem, not a network one, and says so.
      if (list.isEmpty) {
        lastPackagesError =
            'offering "${current.identifier}" has 0 fetchable products';
        return const [];
      }
      lastPackagesError = null;
      int rank(Package p) => switch (p.packageType) {
            PackageType.weekly => 0,
            PackageType.monthly => 1,
            PackageType.annual => 2,
            PackageType.lifetime => 3,
            _ => 4,
          };
      list.sort((a, b) => rank(a).compareTo(rank(b)));
      return list;
    } catch (e) {
      lastPackagesError = 'getOfferings failed: $e';
      return const [];
    }
  }

  /// Why the last [packages] call came back empty, or null if it didn't.
  static String? lastPackagesError;

  /// Buy [package]. A parent backing out is [PurchaseOutcome.cancelled], which
  /// the paywall must not show as an error.
  static Future<PurchaseOutcome> purchase(Package package) async {
    if (!_configured) return PurchaseOutcome.failed;
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _onCustomerInfo(result.customerInfo);
      return hasPro.value ? PurchaseOutcome.success : PurchaseOutcome.failed;
    } on PlatformException catch (e) {
      if (PurchasesErrorHelper.getErrorCode(e) ==
          PurchasesErrorCode.purchaseCancelledError) {
        return PurchaseOutcome.cancelled;
      }
      return PurchaseOutcome.failed;
    } catch (_) {
      return PurchaseOutcome.failed;
    }
  }

  static String labelFor(Package p) => switch (p.packageType) {
        PackageType.weekly => 'Weekly',
        PackageType.monthly => 'Monthly',
        PackageType.annual => 'Yearly',
        PackageType.lifetime => 'Lifetime',
        _ => p.storeProduct.title,
      };

  static String? unitFor(Package p) => switch (p.packageType) {
        PackageType.weekly => '/week',
        PackageType.monthly => '/month',
        PackageType.annual => '/year',
        _ => null,
      };

  /// RevenueCat Customer Center: manage / cancel / refund flows.
  static Future<void> presentCustomerCenter() async {
    if (!_configured) return;
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (_) {}
    unawaited(refresh());
  }
}
