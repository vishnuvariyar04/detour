// engine.dart
//
// Dart wrapper around the native engine (MethodChannel `brainpass/engine`). The
// kid lock is now 100% native, so this only pushes PARENT config down and reads
// per-app status back. No lock/earn methods anymore.

import 'package:flutter/services.dart';

import 'storage.dart';

/// Push all saved parent config down to the native engine (after launch /
/// update / reboot / onboarding) and start the guard.
Future<void> syncToEngine() async {
  await Engine.setRules(Storage.rulesForEngine());
  await Engine.setMasterEnabled(Storage.masterEnabled);
  await Engine.setAgeBand(Storage.ageBand);
  final h = Storage.pinHash, s = Storage.pinSalt;
  if (h != null && s != null) await Engine.setPin(h, s);
  await Engine.startGuard();
}

/// Live per-app counters read back from native (for the parent dashboard).
class AppStatus {
  final int usedMs;
  final int remMs;
  final int minutes;
  final int questions;
  const AppStatus(this.usedMs, this.remMs, this.minutes, this.questions);

  int get usedMinutes => (usedMs / 60000).floor();
  int get remMinutes => (remMs / 60000).ceil();
}

class Engine {
  static const _channel = MethodChannel('brainpass/engine');

  // ---- config pushed to native ----
  /// [rules] is a list of {package, name, questions, minutes, cap} maps.
  static Future<void> setRules(List<Map<String, Object>> rules) =>
      _channel.invokeMethod('setRules', {'rules': rules});

  static Future<void> setMasterEnabled(bool enabled) =>
      _channel.invokeMethod('setMasterEnabled', {'enabled': enabled});

  static Future<void> setAgeBand(String band) =>
      _channel.invokeMethod('setAgeBand', {'band': band});

  /// Push the salted PIN hash so the native lock can verify the parent bypass.
  static Future<void> setPin(String hash, String salt) =>
      _channel.invokeMethod('setPin', {'hash': hash, 'salt': salt});

  /// Clear leftover earned time so newly-saved rules take effect immediately.
  static Future<void> clearBudgets() => _channel.invokeMethod('clearBudgets');

  static Future<void> startGuard() => _channel.invokeMethod('startGuard');

  // ---- dashboard ----
  static Future<AppStatus?> appStatus(String package) async {
    final m = await _channel.invokeMethod('appStatus', {'package': package});
    if (m == null) return null;
    return AppStatus(
      (m['usedMs'] as num).toInt(),
      (m['remMs'] as num).toInt(),
      (m['minutes'] as num).toInt(),
      (m['questions'] as num).toInt(),
    );
  }

  // ---- permissions ----
  static Future<bool> hasUsageAccess() async =>
      (await _channel.invokeMethod<bool>('hasUsageAccess')) ?? false;
  static Future<void> openUsageAccessSettings() =>
      _channel.invokeMethod('openUsageAccessSettings');
  static Future<bool> canDrawOverlays() async =>
      (await _channel.invokeMethod<bool>('canDrawOverlays')) ?? false;
  static Future<void> requestOverlay() => _channel.invokeMethod('requestOverlay');
  static Future<bool> isIgnoringBattery() async =>
      (await _channel.invokeMethod<bool>('isIgnoringBattery')) ?? false;
  static Future<void> requestIgnoreBattery() =>
      _channel.invokeMethod('requestIgnoreBattery');

  /// Auto-return: poll [kind] ('overlay' | 'usage') and bring Nupo back to the
  /// foreground the moment the parent grants it in system settings.
  static Future<void> watchReturn(String kind) =>
      _channel.invokeMethod('watchReturn', {'kind': kind});

  /// App version + device model/manufacturer/OS (for the user profile doc).
  static Future<Map<String, String>> deviceInfo() async {
    try {
      final m = await _channel.invokeMethod<Map>('deviceInfo');
      return m?.map((k, v) => MapEntry('$k', '$v')) ?? {};
    } catch (_) {
      return {};
    }
  }

  /// True on OEMs that have an "Autostart" control (Xiaomi/Oppo/Vivo/etc.).
  static Future<bool> autostartRelevant() async =>
      (await _channel.invokeMethod<bool>('autostartRelevant')) ?? false;

  /// Deep-link to the OEM Autostart settings page.
  static Future<void> openAutostartSettings() =>
      _channel.invokeMethod('openAutostartSettings');
}

