// screens/parent_home_screen.dart
//
// The PIN-protected parent dashboard. Shows status, the PER-APP rules + today's
// per-app usage, and lets the parent edit everything. Surfaces a warning if a
// required permission was revoked later.
//
// October 2026 redesign, in the onboarding's language: a greeting, a status
// hero that carries today's numbers (Screen Time-style), one card per app with
// a usage ring, the Nupo Pro card, then grouped settings rows.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../analytics.dart';
import '../auth_service.dart';
import '../curriculum.dart';
import '../engine.dart';
import '../subscription_service.dart';
import '../questions.dart';
import '../safe_apps.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets.dart';
import 'age_band_screen.dart';
import 'app_picker_screen.dart';
import 'app_rules_screen.dart';
import 'paywall_screen.dart';
import 'login/reauth_delete_screen.dart';
import 'onboarding/onb_kit.dart';
import 'permissions_screen.dart';
import 'pin_create_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  /// True when the screen is a tab inside [HomeShell] rather than a pushed
  /// route: it drops its own Scaffold and back button, since the bottom bar is
  /// already the way out.
  final bool embedded;
  final Future<void> Function()? onConfigurationChanged;

  const ParentHomeScreen({
    super.key,
    this.embedded = false,
    this.onConfigurationChanged,
  });

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen>
    with WidgetsBindingObserver {
  bool _permissionsOk = true;
  bool _enabled = true;
  final Map<String, AppStatus?> _status = {};
  LearningProgress _progress = const LearningProgress();
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    // Live-update per-app usage while the dashboard is open.
    _liveTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshStatuses(),
    );
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refreshStatuses() async {
    final statuses = <String, AppStatus?>{};
    for (final pkg in Storage.gatedApps) {
      statuses[pkg] = await Engine.appStatus(pkg);
    }
    if (!mounted) return;
    setState(() {
      _status
        ..clear()
        ..addAll(statuses);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    await Storage.fresh();
    final overlay = await Engine.canDrawOverlays();
    final acc = await Engine.hasUsageAccess();
    final progress = await LearningProgress.load();
    final statuses = <String, AppStatus?>{};
    for (final pkg in Storage.gatedApps) {
      statuses[pkg] = await Engine.appStatus(pkg);
    }
    if (!mounted) return;
    setState(() {
      _permissionsOk = overlay && acc;
      _enabled = Storage.masterEnabled;
      _progress = progress;
      _status
        ..clear()
        ..addAll(statuses);
    });
  }

  Future<void> _edit(
    String what,
    Widget Function(VoidCallback onNext) builder,
  ) async {
    Analytics.settingsOpened(what);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => builder(() => Navigator.of(ctx).pop()),
      ),
    );
    await _refresh();
    await widget.onConfigurationChanged?.call();
    // Keep the person properties in step with what the parent just changed.
    Analytics.setProfile(
      ageBand: Storage.ageBand,
      appsGated: Storage.gatedApps.length,
    );
  }

  Future<void> _toggle(bool v) async {
    Analytics.protectionToggled(v);
    await Storage.setMasterEnabled(v);
    await Engine.setMasterEnabled(v);
    await _refresh();
    await widget.onConfigurationChanged?.call();
  }

  Future<void> _openSubscription() async {
    Analytics.settingsOpened('subscription');
    if (SubscriptionService.hasPro.value) {
      // Manage, cancel or ask for a refund.
      SubscriptionService.presentCustomerCenter();
      return;
    }
    // Not subscribed: the same paywall the hard gate uses, but closable. Lets
    // a parent subscribe while the gate is switched off (paywallEnabled).
    Analytics.paywallShown();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => PaywallScreen(
          dismissible: true,
          onClose: () => Navigator.of(ctx).pop(),
          onPurchased: () {
            SubscriptionService.refresh();
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  void _editRules() => _edit(
    'app_rules',
    (onNext) => AppRulesScreen(onNext: onNext, isOnboarding: false),
  );

  @override
  Widget build(BuildContext context) {
    final band = bandFromString(Storage.ageBand);
    final gated = Storage.gatedApps;
    final rules = Storage.appRules;
    final child = Storage.childName;
    final parent = Storage.parentName;
    final playedToday = _status.values.fold<int>(
      0,
      (a, s) => a + (s?.usedMinutes ?? 0),
    );

    final content = ColoredBox(
      color: AppColors.primarySoft,
      child: SafeArea(
        child: Column(
          children: [
            if (!widget.embedded)
              const NupoTopBar(title: 'Parent settings', showBack: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                children: [
                  // Greeting
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PARENT', style: OnbText.eyebrow),
                            const SizedBox(height: 6),
                            Text(
                              parent.isEmpty ? 'Dashboard' : 'Hi, $parent',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: OnbText.title,
                            ),
                          ],
                        ),
                      ),
                      _Avatar(letter: (parent.isNotEmpty ? parent : 'P')[0]),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (!_permissionsOk) ...[
                    _AlertCard(
                      onTap: () => _edit(
                        'permission_alert',
                        (onNext) => PermissionsScreen(onNext: onNext),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  _StatusHero(
                    enabled: _enabled,
                    apps: gated.length,
                    questionsToday: _progress.answeredToday,
                    minutesToday: playedToday,
                    stopsDone: _progress.stopsDone,
                    onChanged: _toggle,
                  ),
                  const SizedBox(height: 26),

                  // Apps
                  _GroupHeader(
                    'Apps',
                    action: _PillAction(
                      icon: Symbols.add_rounded,
                      label: 'Add',
                      onTap: () => _edit(
                        'apps',
                        (onNext) => AppPickerScreen(onNext: onNext),
                      ),
                    ),
                  ),
                  if (gated.isEmpty)
                    _EmptyApps(
                      onTap: () => _edit(
                        'apps',
                        (onNext) => AppPickerScreen(onNext: onNext),
                      ),
                    )
                  else
                    for (final pkg in gated) ...[
                      _AppCard(
                        package: pkg,
                        rule: rules[pkg] ?? const AppRule(),
                        status: _status[pkg],
                        onTap: _editRules,
                      ),
                      const SizedBox(height: 10),
                    ],
                  const SizedBox(height: 16),

                  // Pro
                  ValueListenableBuilder<bool>(
                    valueListenable: SubscriptionService.hasPro,
                    builder: (_, pro, _) =>
                        _ProCard(pro: pro, onTap: _openSubscription),
                  ),
                  const SizedBox(height: 26),

                  // Child + device
                  const _GroupHeader('Learning'),
                  _Group(
                    children: [
                      _Row(
                        icon: Symbols.face_rounded,
                        // The streak flame's orange: warm, and readable
                        // under a white glyph where the logo yellow is not.
                        color: const Color(0xFFFF8A00),
                        title: child.isEmpty ? 'Child' : child,
                        value: bandLabel(band),
                        onTap: () => _edit(
                          'age',
                          (onNext) => AgeBandScreen(onNext: onNext),
                        ),
                      ),
                      _Row(
                        icon: Symbols.timer_rounded,
                        color: AppColors.kidTop,
                        title: 'Rules per app',
                        value: gated.isEmpty ? 'None' : '${gated.length}',
                        onTap: _editRules,
                      ),
                      _Row(
                        icon: Symbols.verified_user_rounded,
                        color: _permissionsOk
                            ? AppColors.correct
                            : AppColors.wrong,
                        title: 'Permissions',
                        value: _permissionsOk ? 'All on' : 'Fix',
                        valueColor: _permissionsOk ? null : AppColors.wrong,
                        onTap: () => _edit(
                          'permissions',
                          (onNext) => PermissionsScreen(onNext: onNext),
                        ),
                      ),
                      _Row(
                        icon: Symbols.pin_rounded,
                        color: AppColors.primary,
                        title: 'Parent PIN',
                        value: '••••',
                        onTap: () => _edit(
                          'pin',
                          (onNext) => PinCreateScreen(onNext: onNext),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  const _GroupHeader('Account'),
                  _Group(
                    children: [
                      _Row(
                        icon: Symbols.account_circle_rounded,
                        color: AppColors.done,
                        title: 'Signed in',
                        value: _signedInAs(),
                        chevron: false,
                        onTap: null,
                      ),
                      _Row(
                        icon: Symbols.logout_rounded,
                        color: AppColors.textMuted,
                        title: 'Sign out',
                        onTap: _signOut,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Group(
                    children: [
                      _Row(
                        icon: Symbols.delete_rounded,
                        color: AppColors.wrong,
                        title: 'Delete account',
                        titleColor: AppColors.wrong,
                        chevron: false,
                        onTap: _deleteAccount,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Opacity(
                      opacity: 0.55,
                      child: Image.asset(Nupo.wave, width: 54),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'Nupo · learning before play',
                      style: AppText.caption,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return widget.embedded ? content : Scaffold(body: content);
  }

  Future<bool> _confirm(
    String title,
    String body,
    String confirmLabel, {
    bool danger = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(danger ? Nupo.ohno : Nupo.shrug, height: 84),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: OnbText.titleSm.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                body,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 20),
              ChunkyButton(
                label: confirmLabel,
                arrow: false,
                tone: danger ? Chunky.ghost : Chunky.purple,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return ok ?? false;
  }

  Future<void> _signOut() async {
    final ok = await _confirm(
      'Sign out?',
      'You will need to sign in again to use Nupo.',
      'Sign out',
    );
    if (!ok) return;
    await Analytics.signedOut();
    await AuthService.signOut();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _deleteAccount() async {
    final ok = await _confirm(
      'Delete account?',
      'This permanently deletes your Nupo account and cannot be undone.',
      'Delete',
      danger: true,
    );
    if (!ok) return;
    try {
      // Works if the sign-in is still "recent".
      await AuthService.deleteAccount();
      Analytics.accountDeleted();
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      return;
    } catch (e) {
      if (!AuthService.isRecentLoginError(e)) {
        if (mounted) _showError(AuthService.errorMessage(e));
        return;
      }
      // Stale session — re-verify the number, then delete.
    }
    if (!mounted) return;
    final deleted = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const ReauthDeleteScreen()));
    if (deleted == true) Analytics.accountDeleted();
    if (deleted == true && mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  void _showError(String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Could not delete',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        content: Text(message, style: AppText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- pieces

/// The number or address the parent signed in with, or nothing if Firebase
/// is not up (it never throws into the build).
String _signedInAs() {
  try {
    // A Google account reports an EMPTY phone number, not a missing one, so
    // `??` alone would show nothing.
    final phone = AuthService.currentUser?.phoneNumber ?? '';
    return phone.isNotEmpty ? phone : (AuthService.email ?? '');
  } catch (_) {
    return '';
  }
}

/// White card with the onboarding's 2px lilac border and a short ledge.
BoxDecoration _cardBox({double radius = 22}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: AppColors.cardBorder, width: 2),
  boxShadow: const [
    BoxShadow(color: AppColors.cardBorder, blurRadius: 0, offset: Offset(0, 3)),
  ],
);

class _Avatar extends StatelessWidget {
  final String letter;
  const _Avatar({required this.letter});

  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.accent,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: [
        BoxShadow(
          color: AppColors.textDark.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Text(
      letter.toUpperCase(),
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w900,
        color: AppColors.textDark,
      ),
    ),
  );
}

/// The master switch, with what it achieved today underneath — the numbers a
/// parent opens the app to see.
class _StatusHero extends StatelessWidget {
  final bool enabled;
  final int apps;
  final int questionsToday;
  final int minutesToday;
  final int stopsDone;
  final ValueChanged<bool> onChanged;
  const _StatusHero({
    required this.enabled,
    required this.apps,
    required this.questionsToday,
    required this.minutesToday,
    required this.stopsDone,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final ink = enabled ? Colors.white : AppColors.textDark;
    final sub = enabled
        ? Colors.white.withValues(alpha: 0.8)
        : AppColors.textMuted;
    return Container(
      decoration: BoxDecoration(
        color: enabled ? AppColors.primaryDeep : AppColors.cardBorder,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.only(bottom: 5),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: enabled ? null : Colors.white,
          gradient: enabled
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primaryBright, AppColors.primary],
                )
              : null,
        ),
        child: Stack(
          children: [
            if (enabled)
              Positioned(
                right: -50,
                top: -60,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: enabled
                              ? Colors.white.withValues(alpha: 0.16)
                              : AppColors.line,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          enabled
                              ? Symbols.shield_with_heart_rounded
                              : Symbols.pause_rounded,
                          size: 26,
                          color: enabled
                              ? AppColors.accent
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              enabled ? 'Learning is on' : 'Nupo is paused',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              enabled
                                  ? 'A lesson before ${apps == 1 ? '1 app' : '$apps apps'}'
                                  : 'Apps open with no lesson',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: sub,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: enabled,
                        onChanged: onChanged,
                        thumbColor: WidgetStatePropertyAll(
                          enabled ? AppColors.primary : Colors.white,
                        ),
                        trackColor: WidgetStatePropertyAll(
                          enabled ? AppColors.accent : const Color(0xFFD9D4E8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: enabled
                          ? Colors.white.withValues(alpha: 0.12)
                          : AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        _HeroStat(
                          value: '$questionsToday',
                          label: 'questions today',
                          ink: ink,
                          sub: sub,
                        ),
                        _HeroDivider(enabled: enabled),
                        _HeroStat(
                          value: '${minutesToday}m',
                          label: 'played today',
                          ink: ink,
                          sub: sub,
                        ),
                        _HeroDivider(enabled: enabled),
                        _HeroStat(
                          value: '$stopsDone',
                          label: 'stops done',
                          ink: ink,
                          sub: sub,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final Color ink;
  final Color sub;
  const _HeroStat({
    required this.value,
    required this.label,
    required this.ink,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 21,
            height: 1.1,
            fontWeight: FontWeight.w900,
            color: ink,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: sub,
          ),
        ),
      ],
    ),
  );
}

class _HeroDivider extends StatelessWidget {
  final bool enabled;
  const _HeroDivider({required this.enabled});

  @override
  Widget build(BuildContext context) => Container(
    width: 1.5,
    height: 30,
    color: enabled ? Colors.white.withValues(alpha: 0.2) : AppColors.line,
  );
}

class _AlertCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AlertCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: AppColors.wrongSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFCACA), width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.wrong,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Symbols.warning_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A permission is off',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.wrong,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Lessons are not showing. Tap to fix.',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.wrong,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String text;
  final Widget? action;
  const _GroupHeader(this.text, {this.action});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
        ),
        ?action,
      ],
    ),
  );
}

class _PillAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PillAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyApps extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyApps({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 20),
      decoration: _cardBox(),
      child: const Column(
        children: [
          Icon(Symbols.add_circle_rounded, size: 34, color: AppColors.primary),
          SizedBox(height: 8),
          Text(
            'Pick the apps that need a lesson first',
            textAlign: TextAlign.center,
            style: AppText.cardTitle,
          ),
        ],
      ),
    ),
  );
}

/// One gated app: icon, the trade, and a ring of today's use against the cap.
class _AppCard extends StatelessWidget {
  final String package;
  final AppRule rule;
  final AppStatus? status;
  final VoidCallback onTap;
  const _AppCard({
    required this.package,
    required this.rule,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final used = status?.usedMinutes ?? 0;
    final rem = status?.remMinutes ?? 0;
    final hasCap = rule.cap > 0;
    final frac = hasCap ? (used / rule.cap).clamp(0.0, 1.0) : 0.0;
    final over = hasCap && used >= rule.cap;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: _cardBox(),
        child: Row(
          children: [
            AppBrandIcon(package, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayNameFor(package),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _MiniChip(
                        icon: Symbols.quiz_rounded,
                        text: '${rule.questions} Q for ${rule.minutes} min',
                        ink: AppColors.primaryDeep,
                        bg: kLilac,
                      ),
                      if (rem > 0)
                        _MiniChip(
                          icon: Symbols.timer_rounded,
                          text: '$rem min left',
                          ink: AppColors.correct,
                          bg: AppColors.correctSoft,
                        )
                      else if (!hasCap)
                        const _MiniChip(
                          icon: Symbols.all_inclusive_rounded,
                          text: 'No daily cap',
                          ink: AppColors.textMuted,
                          bg: AppColors.line,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Today's use: a ring against the cap, or plain minutes without one.
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: hasCap ? frac : (used > 0 ? 1 : 0),
                      strokeWidth: 5,
                      strokeCap: StrokeCap.round,
                      backgroundColor: AppColors.line,
                      valueColor: AlwaysStoppedAnimation(
                        over
                            ? AppColors.wrong
                            : hasCap
                            ? AppColors.primary
                            : AppColors.kidTop,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$used',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        hasCap ? '/${rule.cap}m' : 'min',
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color ink;
  final Color bg;
  const _MiniChip({
    required this.icon,
    required this.text,
    required this.ink,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: ink),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            color: ink,
          ),
        ),
      ],
    ),
  );
}

/// Pro: a dark, quiet "member" card when active; an amber invitation when not.
class _ProCard extends StatelessWidget {
  final bool pro;
  final VoidCallback onTap;
  const _ProCard({required this.pro, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final face = pro ? AppColors.textDark : AppColors.accent;
    final ledge = pro ? Colors.black : kAmberLedge;
    final ink = pro ? Colors.white : AppColors.textDark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: ledge,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.only(bottom: 4),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: face,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 8,
                bottom: -6,
                child: Image.asset(
                  pro ? Nupo.cool : Nupo.starStudent,
                  height: 82,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 110, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Symbols.crown_rounded,
                          size: 18,
                          color: pro ? AppColors.accent : AppColors.textDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          pro ? 'NUPO PRO · ACTIVE' : 'NUPO PRO',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.3,
                            fontWeight: FontWeight.w900,
                            color: pro ? AppColors.accent : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pro ? 'Every skill, every day' : 'Try every skill free',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pro
                          ? 'Manage subscription'
                          : '7 days free, cancel anytime',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: ink.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: _cardBox(),
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const Divider(height: 1, indent: 64, thickness: 1.5),
          children[i],
        ],
      ],
    ),
  );
}

/// A settings row: solid colour tile with a white glyph, as in iOS Settings.
class _Row extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Color? titleColor;
  final String value;
  final Color? valueColor;
  final bool chevron;
  final VoidCallback? onTap;
  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.titleColor,
    this.value = '',
    this.valueColor,
    this.chevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: titleColor ?? AppColors.textDark,
                  ),
                ),
              ),
              if (value.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 170),
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: valueColor ?? AppColors.textMuted,
                    ),
                  ),
                ),
              if (chevron) ...[
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFC5C0DA),
                  size: 22,
                ),
              ] else
                const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}
