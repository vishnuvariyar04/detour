// safe_apps.dart
//
// Spec §13 (NON-NEGOTIABLE safety rule): a child must always be able to call a
// parent or emergency services. So the app picker must NEVER allow gating the
// dialer, messaging, contacts, clock/alarm, or system settings.
//
// We enforce this two ways:
//   1. A preset list of "safe to gate" entertainment apps (spec §10).
//   2. A blocklist used to filter the "pick from installed apps" flow, by exact
//      package name and by substring patterns (brand dialers vary).

class GatePreset {
  final String name;
  final String package;
  const GatePreset(this.name, this.package);
}

/// The curated preset list from spec §10.
const List<GatePreset> kPresetGateableApps = [
  GatePreset('YouTube', 'com.google.android.youtube'),
  GatePreset('YouTube Kids', 'com.google.android.apps.youtube.kids'),
  GatePreset('Instagram', 'com.instagram.android'),
  GatePreset('TikTok', 'com.zhiliaoapp.musically'),
  GatePreset('Snapchat', 'com.snapchat.android'),
  GatePreset('Roblox', 'com.roblox.client'),
  GatePreset('Subway Surfers', 'com.kiloo.subwaysurf'),
];

/// Exact package names that must NEVER be gateable.
const Set<String> kNeverGateExact = {
  // Our own app
  'app.nupo.kids',
  // Common dialers
  'com.google.android.dialer',
  'com.android.dialer',
  'com.samsung.android.dialer',
  'com.android.server.telecom',
  'com.android.phone',
  // Messaging / SMS
  'com.google.android.apps.messaging',
  'com.android.messaging',
  'com.samsung.android.messaging',
  // Contacts
  'com.google.android.contacts',
  'com.android.contacts',
  'com.samsung.android.app.contacts',
  // Clock / alarm
  'com.google.android.deskclock',
  'com.android.deskclock',
  'com.sec.android.app.clockpackage',
  // Settings
  'com.android.settings',
  // Emergency
  'com.google.android.apps.safetyhub',
};

/// Substring patterns: any installed package matching one of these is excluded
/// from the picker, to catch brand-specific dialer/sms/contacts/settings.
const List<String> kNeverGatePatterns = [
  'dialer',
  'telecom',
  '.phone',
  'incallui',
  'contacts',
  'messaging',
  '.mms',
  '.sms',
  'deskclock',
  'clockpackage',
  '.settings',
  'emergency',
  'safetyhub',
];

/// Returns true if [pkg] is allowed to be gated (i.e. NOT on any safety list).
bool isGateable(String pkg) {
  final p = pkg.toLowerCase();
  if (kNeverGateExact.contains(pkg)) return false;
  for (final pattern in kNeverGatePatterns) {
    if (p.contains(pattern)) return false;
  }
  return true;
}

/// A friendly display name for a package: the preset name if known, otherwise a
/// best-effort from the package id (e.g. "com.whatsapp" -> "Whatsapp").
String displayNameFor(String pkg) {
  for (final p in kPresetGateableApps) {
    if (p.package == pkg) return p.name;
  }
  final parts = pkg.split('.');
  final guess = parts.length >= 2 ? parts[1] : pkg;
  if (guess.isEmpty) return pkg;
  return guess[0].toUpperCase() + guess.substring(1);
}
