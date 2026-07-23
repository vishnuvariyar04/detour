// storage.dart
//
// On-device settings the PARENT UI needs (build spec §4 — nothing transmitted).
// The native engine owns the live time counters (used/remaining/windows); this
// stores the parent-set configuration: PIN, age band, and the PER-APP rules.

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'safe_apps.dart';

/// A per-app rule: how many questions to earn, how many minutes that grants,
/// and an optional daily cap (0 = no cap). All independent per app.
class AppRule {
  final int questions;
  final int minutes;
  final int cap; // daily cap minutes; 0 = none

  const AppRule({this.questions = 3, this.minutes = 15, this.cap = 0});

  AppRule copyWith({int? questions, int? minutes, int? cap}) => AppRule(
        questions: questions ?? this.questions,
        minutes: minutes ?? this.minutes,
        cap: cap ?? this.cap,
      );

  Map<String, dynamic> toJson() => {'q': questions, 'm': minutes, 'c': cap};

  static AppRule fromJson(Map<String, dynamic> j) => AppRule(
        questions: (j['q'] as num?)?.toInt() ?? 3,
        minutes: (j['m'] as num?)?.toInt() ?? 15,
        cap: (j['c'] as num?)?.toInt() ?? 0,
      );
}

class Storage {
  static const kPinHash = 'pinHash';
  static const kPinSalt = 'pinSalt';
  static const kAgeBand = 'ageBand';
  static const kGatedApps = 'gatedApps';
  static const kAppRules = 'appRules'; // JSON: { "<pkg>": {q,m,c} }
  static const kMasterEnabled = 'masterEnabled';
  static const kOnboardingComplete = 'onboardingComplete';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<void> fresh() async {
    _prefs = await SharedPreferences.getInstance();
    await _prefs!.reload();
  }

  static SharedPreferences get _p {
    final p = _prefs;
    if (p == null) throw StateError('Storage.init() must be called first.');
    return p;
  }

  // ---- PIN ----
  static String? get pinHash => _p.getString(kPinHash);
  static String? get pinSalt => _p.getString(kPinSalt);
  static Future<void> setPin(String hash, String salt) async {
    await _p.setString(kPinHash, hash);
    await _p.setString(kPinSalt, salt);
  }

  static bool get hasPin => (pinHash?.isNotEmpty ?? false);

  // ---- Age band ----
  static String get ageBand => _p.getString(kAgeBand) ?? 'b';
  static Future<void> setAgeBand(String b) => _p.setString(kAgeBand, b);

  // ---- Gated apps ----
  static List<String> get gatedApps => _p.getStringList(kGatedApps) ?? const [];
  static Future<void> setGatedApps(List<String> apps) =>
      _p.setStringList(kGatedApps, apps);

  // ---- Per-app rules ----
  static Map<String, AppRule> get appRules {
    final raw = _p.getString(kAppRules);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (k, v) => MapEntry(k, AppRule.fromJson(v as Map<String, dynamic>)),
    );
  }

  static Future<void> setAppRules(Map<String, AppRule> rules) async {
    final encoded = jsonEncode(rules.map((k, v) => MapEntry(k, v.toJson())));
    await _p.setString(kAppRules, encoded);
  }

  /// The rule for [pkg], or a default if none saved yet.
  static AppRule ruleFor(String pkg) => appRules[pkg] ?? const AppRule();

  /// Ensure every gated app has a rule (creating defaults), and drop rules for
  /// apps no longer gated.
  static Future<void> reconcileRules() async {
    final apps = gatedApps;
    final current = appRules;
    final next = <String, AppRule>{};
    for (final pkg in apps) {
      next[pkg] = current[pkg] ?? const AppRule();
    }
    await setAppRules(next);
  }

  /// Build the list of rule maps to push to the native engine.
  static List<Map<String, Object>> rulesForEngine() {
    final rules = appRules;
    return [
      for (final pkg in gatedApps)
        {
          'package': pkg,
          'name': displayNameFor(pkg),
          'questions': (rules[pkg] ?? const AppRule()).questions,
          'minutes': (rules[pkg] ?? const AppRule()).minutes,
          'cap': (rules[pkg] ?? const AppRule()).cap,
        }
    ];
  }

  // ---- Master ON/OFF ----
  static bool get masterEnabled => _p.getBool(kMasterEnabled) ?? true;
  static Future<void> setMasterEnabled(bool v) => _p.setBool(kMasterEnabled, v);

  // ---- Onboarding ----
  static bool get onboardingComplete =>
      _p.getBool(kOnboardingComplete) ?? false;
  static Future<void> setOnboardingComplete(bool v) =>
      _p.setBool(kOnboardingComplete, v);

  // ---- Onboarding survey (LOCAL ONLY — see nupo_onboarding_spec.md §7) ----
  // The child's name never leaves the device. Survey answers personalize the
  // flow on-device; only `attribution` may ever be transmitted (aggregate).
  static const kParentName = 'parentName';
  static const kChildName = 'childName';
  static const kChildAge = 'childAge';
  static const kScreenHours = 'screenHours'; // parent's daily estimate
  static const kGoals = 'onbGoals';
  static const kTried = 'onbTried';
  static const kVibe = 'onbVibe';
  static const kReachApps = 'onbReachApps'; // pre-fills the app picker
  static const kOwlName = 'owlName';
  static const kCommitment = 'onbCommitment';
  static const kAttribution = 'onbAttribution';

  static String get parentName => (_p.getString(kParentName) ?? '').trim();
  static Future<void> setParentName(String v) =>
      _p.setString(kParentName, v.trim());

  static String get childName => (_p.getString(kChildName) ?? '').trim();
  static Future<void> setChildName(String v) =>
      _p.setString(kChildName, v.trim());

  /// The child's name for UI copy, with a graceful fallback.
  static String childNameOr([String fallback = 'your child']) =>
      childName.isEmpty ? fallback : childName;

  static int get childAge => _p.getInt(kChildAge) ?? 8;
  static Future<void> setChildAge(int v) => _p.setInt(kChildAge, v);

  static double get screenHours => _p.getDouble(kScreenHours) ?? 0;
  static Future<void> setScreenHours(double v) =>
      _p.setDouble(kScreenHours, v);

  static List<String> get goals => _p.getStringList(kGoals) ?? const [];
  static Future<void> setGoals(List<String> v) => _p.setStringList(kGoals, v);

  static List<String> get tried => _p.getStringList(kTried) ?? const [];
  static Future<void> setTried(List<String> v) => _p.setStringList(kTried, v);

  static String get vibe => _p.getString(kVibe) ?? '';
  static Future<void> setVibe(String v) => _p.setString(kVibe, v);

  static List<String> get reachApps =>
      _p.getStringList(kReachApps) ?? const [];
  static Future<void> setReachApps(List<String> v) =>
      _p.setStringList(kReachApps, v);

  static String get owlName {
    final v = (_p.getString(kOwlName) ?? '').trim();
    return v.isEmpty ? 'Nupo' : v;
  }

  static Future<void> setOwlName(String v) => _p.setString(kOwlName, v.trim());

  static String get commitment => _p.getString(kCommitment) ?? '';
  static Future<void> setCommitment(String v) =>
      _p.setString(kCommitment, v);

  static String get attribution => _p.getString(kAttribution) ?? '';
  static Future<void> setAttribution(String v) =>
      _p.setString(kAttribution, v);
}
