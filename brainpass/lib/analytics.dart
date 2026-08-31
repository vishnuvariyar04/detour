// analytics.dart
//
// Thin wrapper around Firebase Analytics (GA4) so the rest of the app never
// imports the SDK directly, and so every event name lives in ONE list that can
// be read top-to-bottom as the funnel.
//
// ## Why this exists
//
// Until 2026-08-31 the app shipped with no analytics at all. Play Console only
// reports an INSTALL BASE (how many devices currently have the app), so a drop
// anywhere between "installed" and "set up" was invisible — including the
// 1.1.x bug where the phone-login country list had no Portugal/Türkiye/France
// and every unlisted country was hard-blocked at the mandatory gate with zero
// signal. [loginFailed] is the direct answer to that class of bug.
//
// ## CHILD-DIRECTED CONFIGURATION — read before adding anything
//
// Nupo's audience is children 5-11 (Play Families). Three rules:
//
//   1. NO advertising id, no ad personalisation. Enforced in
//      AndroidManifest.xml (AD_ID stripped + the `google_analytics_*`
//      meta-data flags), not here.
//   2. NO personal data in any event or user property. The child's name and
//      the owl's name must NEVER be logged — only the age BAND, the subject
//      and counts. Free text typed by a parent is never a parameter value.
//   3. Adding an event means re-checking `legal/DATA_SAFETY.md` and
//      `legal/PRIVACY_POLICY.md`, which declare exactly what is collected.
//
// The kid never touches Flutter — the lock is 100% native — so the events that
// measure REAL daily usage are logged from Kotlin (`Analytics.kt`, called by
// GuardService), not from here. Retention read only from this file would be
// retention of the parent settings screen, which nobody opens twice.
//
// ## Fail-safe
//
// Every call swallows its errors and returns void. Analytics must never break
// the app, block a screen, or delay a gate.

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class Analytics {
  static FirebaseAnalytics? _fa;

  /// Call once from main(), after Firebase.initializeApp(). Safe to skip —
  /// every other method no-ops when this never ran or threw.
  static Future<void> init() async {
    try {
      final fa = FirebaseAnalytics.instance;
      await fa.setAnalyticsCollectionEnabled(true);
      _fa = fa;
    } catch (_) {}
  }

  static Future<void> _log(String name, [Map<String, Object?>? params]) async {
    final fa = _fa;
    if (kDebugMode) debugPrint('[analytics] $name ${params ?? ''}');
    if (fa == null) return;
    try {
      await fa.logEvent(
        name: name,
        parameters: params == null
            ? null
            : {
                for (final e in params.entries)
                  if (e.value != null) e.key: _clean(e.value as Object),
              },
      );
    } catch (_) {}
  }

  /// GA4 takes only String/num parameter values, strings capped at 100 chars.
  static Object _clean(Object v) {
    if (v is num) return v;
    if (v is bool) return v ? 1 : 0;
    final s = v.toString();
    return s.length <= 100 ? s : s.substring(0, 100);
  }

  static Future<void> _prop(String name, String? value) async {
    final fa = _fa;
    if (fa == null) return;
    try {
      await fa.setUserProperty(name: name, value: value);
    } catch (_) {}
  }

  // -------------------------------------------------------------------------
  // Identity — lets a GA4 user be joined to their Firestore `users/{uid}` doc.
  // -------------------------------------------------------------------------

  static Future<void> setUser(String? uid, {String? method}) async {
    final fa = _fa;
    if (fa != null) {
      try {
        await fa.setUserId(id: uid);
      } catch (_) {}
    }
    if (method != null) await _prop('signin_method', method);
  }

  /// Segmentation properties. Never personal — band and counts only.
  static Future<void> setProfile({
    String? ageBand,
    String? subject,
    int? appsGated,
    bool? hasPro,
    bool? onboardingDone,
  }) async {
    if (ageBand != null && ageBand.isNotEmpty) await _prop('age_band', ageBand);
    if (subject != null && subject.isNotEmpty) await _prop('subject', subject);
    if (appsGated != null) await _prop('apps_gated', '$appsGated');
    if (hasPro != null) await _prop('has_pro', hasPro ? 'yes' : 'no');
    if (onboardingDone != null) {
      await _prop('setup_done', onboardingDone ? 'yes' : 'no');
    }
  }

  static Future<void> setPermissionProp(String permission, bool granted) =>
      _prop('perm_$permission', granted ? 'yes' : 'no');

  // -------------------------------------------------------------------------
  // 1 · The scroll story (`story_screen.dart`) — the pitch, before login.
  // -------------------------------------------------------------------------

  /// The story screen painted. The gap between `first_open` (automatic) and
  /// this is install-to-open drop.
  static Future<void> storyShown() => _log('story_shown');

  /// "Get started" tapped — the parent is actually scrolling.
  static Future<void> storyStarted() => _log('story_started');

  /// Beat 5 gate: they picked the app their kid opens most.
  static Future<void> storyAppPicked(String app) =>
      _log('story_app_picked', {'app': app});

  /// Beat 6 gate: they answered the sample question. [wrongs] is how many
  /// tries it took — a high number means the demo question is too hard.
  static Future<void> storyAnswered(int wrongs) =>
      _log('story_answered', {'wrongs': wrongs});

  /// Reached the closing CTA and tapped it.
  static Future<void> storyFinished() => _log('story_finished');

  /// "I already have an account" — a returning parent skipping the pitch.
  static Future<void> storyLoginTapped() => _log('story_login_tapped');

  // -------------------------------------------------------------------------
  // 2 · Login (`login_flow.dart`) — the MANDATORY gate. Everything below it is
  //     invisible unless the parent gets an account, so this is the single
  //     most important block in the file.
  // -------------------------------------------------------------------------

  static Future<void> loginShown() => _log('login_shown');

  /// [method] is 'google' | 'email' | 'email_create' | 'password_reset'.
  static Future<void> loginAttempt(String method) =>
      _log('login_attempt', {'method': method});

  static Future<void> loginSuccess(String method) =>
      _log('login_success', {'method': method});

  /// [reason] is a stable code, never the parent-facing sentence — that
  /// changes with copy and would fragment the report. A spike on one reason in
  /// one country is how a region-specific auth break gets caught.
  static Future<void> loginFailed(String method, String reason) =>
      _log('login_failed', {'method': method, 'reason': reason});

  static Future<void> loginCancelled(String method) =>
      _log('login_cancelled', {'method': method});

  // -------------------------------------------------------------------------
  // 3 · Onboarding (`onboarding_flow.dart`) — the 7 questions plus the Android
  //     setup block. ONE event with a step name, so a GA4 funnel exploration
  //     steps on `step_name` instead of burning 15 event names.
  // -------------------------------------------------------------------------

  /// Named steps, in flow order. Keep in sync with the screen list in
  /// `onboarding_flow.dart`; the index IS the funnel order.
  static const onbSteps = <String>[
    'child_name',
    'child_age',
    'subject',
    'owl_name',
    'month_plan',
    'projection',
    'why_it_works',
    'app_picker',
    'app_rules',
    'pin',
    'permissions_intro',
  ];

  /// A setup step was shown. [index] is its position in the whole flow so the
  /// funnel keeps its order even though the permission steps vary by OEM.
  static Future<void> onbStep(int index, String name) =>
      _log('onb_step', {'step_index': index, 'step_name': name});

  /// The app picker: how many apps were actually ticked. Zero means the gate
  /// can never fire and the product does nothing.
  static Future<void> appsPicked(int count) =>
      _log('apps_picked', {'count': count});

  // -------------------------------------------------------------------------
  // 4 · Permissions — the steepest cliff in any Android parental-control app.
  //     Logged per permission so it is obvious WHICH one loses people.
  // -------------------------------------------------------------------------

  /// [permission] is 'overlay' | 'usage' | 'battery' | 'autostart'.
  static Future<void> permissionShown(String permission) =>
      _log('permission_shown', {'permission': permission});

  /// They tapped the button that sends them to the system screen. A big gap
  /// between this and [permissionGranted] means they got lost in Settings.
  static Future<void> permissionRequested(String permission) =>
      _log('permission_requested', {'permission': permission});

  /// The system check came back granted — fires on return from Settings,
  /// which is why it is separate from [permissionRequested].
  static Future<void> permissionGranted(String permission) =>
      _log('permission_granted', {'permission': permission});

  static Future<void> permissionSkipped(String permission) =>
      _log('permission_skipped', {'permission': permission});

  // -------------------------------------------------------------------------
  // 5 · Setup done, paywall, home.
  // -------------------------------------------------------------------------

  /// Onboarding finished and the engine has the rules. THE activation event —
  /// mark this as a key event in GA4.
  static Future<void> setupComplete({
    required String ageBand,
    required String subject,
    required int appsGated,
  }) => _log('setup_complete', {
    'age_band': ageBand,
    'subject': subject,
    'apps_gated': appsGated,
  });

  /// A returning parent whose saved setup was pulled back down on sign-in.
  static Future<void> setupRestored() => _log('setup_restored');

  static Future<void> paywallShown() => _log('paywall_shown');
  static Future<void> purchaseCompleted() => _log('purchase_completed');
  static Future<void> restoreCompleted() => _log('restore_completed');

  /// The post-setup landing. [enabled] false means a parent who turned the
  /// whole thing off — churn about to happen.
  static Future<void> homeShown(bool enabled) =>
      _log('home_shown', {'enabled': enabled});
}
