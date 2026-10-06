// ad_attribution.dart
//
// How Nupo tells which ads bring parents who stay and pay. Three pieces:
//
//  1. Meta (Facebook/Instagram) app events. The Meta SDK logs the install and
//     app opens by itself; this file adds `CompleteRegistration` when a parent
//     finishes setup. Purchases (trial, conversion, renewals, refunds, with
//     revenue) are NOT logged here: RevenueCat sends them to Meta from its
//     servers, which is exact and survives the app being deleted. Sending them
//     from the phone as well would count every purchase twice.
//
//  2. The link between the two. RevenueCat needs Meta's anonymous install id
//     to tie a purchase back to the ad that brought the install.
//
//  3. The campaign behind the install, read ONCE from the Play install
//     referrer (utm_source / utm_medium / utm_campaign, or Meta's own
//     referrer for app-install ads) and stored on the parent in PostHog and
//     Firebase, so every funnel and retention chart can be split by campaign.
//
// The advertising ID stays switched off (see AndroidManifest.xml): Meta matches
// Play installs to ad taps through the install referrer instead.
//
// Fail-safe like the rest of the analytics: nothing here can block or crash
// the app, and with no Meta app id configured it does nothing at all.

import 'dart:io' show Platform;

import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdAttribution {
  static final _meta = FacebookAppEvents();
  static const _kReferrerRead = 'install_referrer_read';
  static bool? _metaOn;

  /// Whether this build carries a Meta app id (android/meta.properties). The
  /// Meta SDK is never started without one, and calling it would throw.
  static Future<bool> _metaReady() async {
    if (_metaOn != null) return _metaOn!;
    try {
      _metaOn = await const MethodChannel('brainpass/engine')
              .invokeMethod<bool>('metaConfigured') ??
          false;
    } catch (_) {
      _metaOn = false;
    }
    return _metaOn!;
  }

  /// Call once at start-up, after RevenueCat is configured.
  static Future<void> init() async {
    if (await _metaReady()) {
      try {
        // Never collect the advertising ID, whatever the manifest says.
        await _meta.setAdvertiserIdCollectionEnabled(false);
      } catch (_) {}
      await _linkRevenueCat();
    }
    await _readInstallReferrer();
  }

  /// After sign-in RevenueCat switches to the parent's account: give it the
  /// Meta install id again so purchases on that account keep their ad link.
  static Future<void> relink() => _linkRevenueCat();

  /// A parent finished setup: the conversion Meta should optimise for before
  /// purchases have enough volume.
  static Future<void> completedRegistration() async {
    if (!await _metaReady()) return;
    try {
      await _meta.logCompletedRegistration(registrationMethod: 'setup');
    } catch (_) {}
  }

  static Future<void> _linkRevenueCat() async {
    if (!await _metaReady()) return;
    try {
      final id = await _meta.getAnonymousId();
      if (id != null && id.isNotEmpty) await Purchases.setFBAnonymousID(id);
    } catch (_) {}
  }

  static Future<void> _readInstallReferrer() async {
    if (!Platform.isAndroid) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kReferrerRead) == true) return;
      final details = await PlayInstallReferrer.installReferrer;
      await prefs.setBool(_kReferrerRead, true);
      final raw = details.installReferrer ?? '';
      final q = Uri.splitQueryString(raw);
      final source = q['utm_source'] ?? (raw.isEmpty ? 'none' : 'unknown');
      final props = <String, Object>{
        'install_source': _short(source),
        'install_medium': _short(q['utm_medium'] ?? ''),
        'install_campaign': _short(q['utm_campaign'] ?? ''),
        'install_content': _short(q['utm_content'] ?? ''),
      };
      if (kDebugMode) debugPrint('[attribution] referrer "$raw" -> $props');
      // On the person, once: later re-installs must not overwrite the first
      // campaign that brought this parent.
      await Posthog().capture(
        eventName: 'install_attributed',
        properties: props,
        userPropertiesSetOnce: props,
      );
    } catch (_) {
      // No Play services, or the referrer service was unavailable; try again
      // next start (the flag is only set after a successful read).
    }
  }

  /// Meta's own referrer content is an encrypted blob; keep only what fits a
  /// property and is useful to read.
  static String _short(String v) => v.length <= 100 ? v : v.substring(0, 100);
}
