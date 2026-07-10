// screens/parent_home_screen.dart
//
// The PIN-protected parent dashboard. Shows status, the PER-APP rules + today's
// per-app usage, and lets the parent edit everything. Surfaces a warning if a
// required permission was revoked later.

import 'dart:async';

import 'package:flutter/material.dart';

import '../auth_service.dart';
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
import 'login/reauth_delete_screen.dart';
import 'permissions_screen.dart';
import 'pin_create_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen>
    with WidgetsBindingObserver {
  bool _permissionsOk = true;
  bool _enabled = true;
  final Map<String, AppStatus?> _status = {};
  Timer? _liveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    // Live-update per-app usage while the dashboard is open.
    _liveTimer =
        Timer.periodic(const Duration(seconds: 2), (_) => _refreshStatuses());
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
    final statuses = <String, AppStatus?>{};
    for (final pkg in Storage.gatedApps) {
      statuses[pkg] = await Engine.appStatus(pkg);
    }
    if (!mounted) return;
    setState(() {
      _permissionsOk = overlay && acc;
      _enabled = Storage.masterEnabled;
      _status
        ..clear()
        ..addAll(statuses);
    });
  }

  Future<void> _edit(Widget Function(VoidCallback onNext) builder) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => builder(() => Navigator.of(ctx).pop()),
      ),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final band = bandFromString(Storage.ageBand);
    final gated = Storage.gatedApps;
    final rules = Storage.appRules;

    return Scaffold(
      body: Container(
        decoration: AppColors.bgDecoration(),
        height: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              const NupoTopBar(title: 'Parent settings'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    // Permissions revoked warning
                    if (!_permissionsOk) ...[
                      _alertBanner(
                        icon: Icons.warning_amber_rounded,
                        title: 'A permission is off',
                        body: 'Nupo can\'t bring lessons right now. Tap to fix.',
                        onTap: () =>
                            _edit((onNext) => PermissionsScreen(onNext: onNext)),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Protection master switch
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      decoration: AppColors.cardDecoration(),
                      child: Row(
                        children: [
                          IconBadge(
                            _enabled
                                ? Icons.shield_rounded
                                : Icons.pause_rounded,
                            color: _enabled
                                ? AppColors.correct
                                : AppColors.textMuted,
                            background: _enabled
                                ? AppColors.correctSoft
                                : const Color(0xFFEFEDF6),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _enabled ? 'Learning on' : 'Paused',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: _enabled
                                        ? AppColors.correct
                                        : AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  _enabled
                                      ? 'A quick lesson before play'
                                      : 'Apps open freely',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _enabled,
                            onChanged: (v) async {
                              await Storage.setMasterEnabled(v);
                              await Engine.setMasterEnabled(v);
                              _refresh();
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Gated apps + today's usage
                    Row(
                      children: [
                        const Expanded(child: SectionLabel('Learning apps')),
                        TextButton.icon(
                          onPressed: () =>
                              _edit((onNext) => AppPickerScreen(onNext: onNext)),
                          icon: const Icon(Icons.edit_rounded, size: 15),
                          label: const Text('Edit',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: AppColors.cardDecoration(),
                      child: gated.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text('No apps picked yet.',
                                    style: AppText.body),
                              ),
                            )
                          : Column(
                              children: [
                                for (var i = 0; i < gated.length; i++) ...[
                                  if (i > 0) const Divider(height: 1),
                                  _AppStatusRow(
                                    name: displayNameFor(gated[i]),
                                    package: gated[i],
                                    rule: rules[gated[i]] ?? const AppRule(),
                                    status: _status[gated[i]],
                                    onTap: () => _edit((onNext) =>
                                        AppRulesScreen(
                                            onNext: onNext,
                                            isOnboarding: false)),
                                  ),
                                ],
                              ],
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Settings
                    const SectionLabel('Settings'),
                    Container(
                      decoration: AppColors.cardDecoration(),
                      child: Column(
                        children: [
                          _EditRowItem(
                            icon: Icons.cake_rounded,
                            color: AppColors.accentDeep,
                            background: AppColors.accentSoft,
                            title: 'Child age',
                            value: bandLabel(band),
                            onTap: () =>
                                _edit((onNext) => AgeBandScreen(onNext: onNext)),
                          ),
                          const Divider(height: 1, indent: 62),
                          _EditRowItem(
                            icon: Icons.tune_rounded,
                            title: 'Permissions',
                            value: _permissionsOk ? 'All granted' : 'Needs attention',
                            valueColor:
                                _permissionsOk ? null : AppColors.wrong,
                            onTap: () => _edit(
                                (onNext) => PermissionsScreen(onNext: onNext)),
                          ),
                          const Divider(height: 1, indent: 62),
                          _EditRowItem(
                            icon: Icons.password_rounded,
                            title: 'Change PIN',
                            value: '••••',
                            onTap: () => _edit(
                                (onNext) => PinCreateScreen(onNext: onNext)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Account
                    const SectionLabel('Account'),
                    Container(
                      decoration: AppColors.cardDecoration(),
                      child: Column(
                        children: [
                          _EditRowItem(
                            icon: Icons.phone_iphone_rounded,
                            color: AppColors.correct,
                            background: AppColors.correctSoft,
                            title: 'Signed in',
                            value: AuthService.phoneNumber ?? '—',
                            onTap: () {},
                          ),
                          const Divider(height: 1, indent: 62),
                          _EditRowItem(
                            icon: Icons.workspace_premium_rounded,
                            color: AppColors.accentDeep,
                            background: AppColors.accentSoft,
                            title: 'Subscription',
                            value: SubscriptionService.hasPro.value
                                ? 'Nupo Pro'
                                : 'Inactive',
                            onTap: SubscriptionService.presentCustomerCenter,
                          ),
                          const Divider(height: 1, indent: 62),
                          _EditRowItem(
                            icon: Icons.logout_rounded,
                            title: 'Sign out',
                            value: '',
                            onTap: _signOut,
                          ),
                          const Divider(height: 1, indent: 62),
                          _EditRowItem(
                            icon: Icons.delete_outline_rounded,
                            color: AppColors.wrong,
                            background: const Color(0xFFFFE1E1),
                            title: 'Delete account',
                            value: '',
                            valueColor: AppColors.wrong,
                            onTap: _deleteAccount,
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
      ),
    );
  }

  Future<bool> _confirm(
    String title,
    String body,
    String confirmLabel, {
    bool danger = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w900, color: AppColors.textDark)),
        content: Text(body, style: AppText.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel,
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: danger ? AppColors.wrong : AppColors.primary)),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _signOut() async {
    final ok = await _confirm(
      'Sign out?',
      "You'll need to sign in again with your phone number to use Nupo.",
      'Sign out',
    );
    if (!ok) return;
    await AuthService.signOut();
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _deleteAccount() async {
    final ok = await _confirm(
      'Delete account?',
      'This permanently deletes your Nupo account. This cannot be undone.',
      'Delete',
      danger: true,
    );
    if (!ok) return;
    try {
      // Works if the sign-in is still "recent".
      await AuthService.deleteAccount();
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
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ReauthDeleteScreen()),
    );
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
        title: const Text("Couldn't delete",
            style: TextStyle(
                fontWeight: FontWeight.w900, color: AppColors.textDark)),
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

  Widget _alertBanner({
    required IconData icon,
    required String title,
    required String body,
    VoidCallback? onTap,
  }) {
    return Material(
      color: AppColors.wrongSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFFFD2D2), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              IconBadge(icon,
                  color: AppColors.wrong, background: const Color(0xFFFFE1E1)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.wrong,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(body,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.wrong, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppStatusRow extends StatelessWidget {
  final String name;
  final String package;
  final AppRule rule;
  final AppStatus? status;
  final VoidCallback onTap;
  const _AppStatusRow({
    required this.name,
    required this.package,
    required this.rule,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final usedMin = status?.usedMinutes ?? 0;
    final remMin = status?.remMinutes ?? 0;
    final hasCap = rule.cap > 0;
    final progress = hasCap ? (usedMin / rule.cap).clamp(0.0, 1.0) : null;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            AppBrandIcon(package, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      Text(
                        hasCap ? '$usedMin / ${rule.cap}m' : '${usedMin}m today',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${rule.questions} Q → ${rule.minutes} min',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (remMin > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: AppColors.accent, size: 13),
                              const SizedBox(width: 3),
                              Text(
                                '$remMin min left',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accentDeep,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFEFEDF8),
                        valueColor: AlwaysStoppedAnimation(
                          progress >= 1 ? AppColors.wrong : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFC5C0DA), size: 20),
          ],
        ),
      ),
    );
  }
}

class _EditRowItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String value;
  final Color? valueColor;
  final VoidCallback onTap;
  const _EditRowItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
    this.color = AppColors.primary,
    this.background = AppColors.primarySoft,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              IconBadge(icon, size: 18, color: color, background: background),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFC5C0DA), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
