// engine.dart
//
// Dart side of the bridge to the native gating engine. Everything is per-app
// now: the parent pushes per-app rules down, and the native service tracks each
// app's active-time budget and daily cap independently.

import 'package:flutter/services.dart';

/// Describes a lock launch from native: which app, and whether to show the earn
/// questions ("earn") or the all-done screen ("done").
class LockInfo {
  final String package;
  final String mode; // "earn" | "done"
  final int questions;
  final int minutes;
  const LockInfo(this.package, this.mode, this.questions, this.minutes);

  static LockInfo? fromMap(dynamic m) {
    if (m == null) return null;
    return LockInfo(
      m['package'] as String,
      (m['mode'] as String?) ?? 'earn',
      (m['questions'] as num?)?.toInt() ?? 3,
      (m['minutes'] as num?)?.toInt() ?? 15,
    );
  }
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

  /// Register a callback for when the native service launches us as a lock while
  /// the app is already running (warm relaunch).
  static void init(void Function(LockInfo info) onShowLock) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'showLock') {
        final info = LockInfo.fromMap(call.arguments);
        if (info != null) onShowLock(info);
      }
      return null;
    });
  }

  // ---- settings pushed to native ----
  /// [rules] is a list of {package, questions, minutes, cap} maps.
  static Future<void> setRules(List<Map<String, Object>> rules) =>
      _channel.invokeMethod('setRules', {'rules': rules});

  static Future<void> setMasterEnabled(bool enabled) =>
      _channel.invokeMethod('setMasterEnabled', {'enabled': enabled});

  /// Clear leftover earned time so newly-saved rules take effect immediately.
  static Future<void> clearBudgets() => _channel.invokeMethod('clearBudgets');

  // ---- earn / override (called by the lock screen) ----
  /// Child solved the questions: add one earned block for [package].
  static Future<void> earned(String package) =>
      _channel.invokeMethod('earned', {'package': package});

  /// Parent PIN bypass: grant a block AND lift the cap for today.
  static Future<void> parentOverride(String package) =>
      _channel.invokeMethod('parentOverride', {'package': package});

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

  // ---- guard lifecycle ----
  static Future<void> startGuard() => _channel.invokeMethod('startGuard');

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

  // ---- lock lifecycle ----
  static Future<LockInfo?> getLaunchLockInfo() async =>
      LockInfo.fromMap(await _channel.invokeMethod('getLaunchLockInfo'));
  static Future<void> finishLock() => _channel.invokeMethod('finishLock');
}
