// screens/parent_home_screen.dart — spec §9.7
//
// The PIN-protected parent dashboard. Shows status, the PER-APP rules + today's
// per-app usage, and lets the parent edit everything. Surfaces a warning if a
// required permission was revoked later (spec §8).

import 'dart:async';

import 'package:flutter/material.dart';

import '../engine.dart';
import '../questions.dart';
import '../safe_apps.dart';
import '../storage.dart';
import '../theme.dart';
import 'age_band_screen.dart';
import 'app_picker_screen.dart';
import 'app_rules_screen.dart';
import 'permissions_screen.dart';

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
    _liveTimer = Timer.periodic(
        const Duration(seconds: 2), (_) => _refreshStatuses());
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
      appBar: AppBar(title: const Text('BrainPass')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            if (!_permissionsOk)
              _Banner(
                color: AppColors.wrong,
                icon: Icons.warning_amber_rounded,
                title: 'A permission is off',
                body: 'BrainPass can’t gate apps until you re-enable it. Tap to fix.',
                onTap: () => _edit((onNext) => PermissionsScreen(onNext: onNext)),
              )
            else if (!_enabled)
              _Banner(
                color: AppColors.textMuted,
                icon: Icons.pause_circle_rounded,
                title: 'BrainPass is paused',
                body: 'Gating is turned off. Turn it back on below.',
              )
            else
              const _Banner(
                color: AppColors.correct,
                icon: Icons.check_circle_rounded,
                title: 'BrainPass is active',
                body: 'Your child must earn time on each gated app.',
              ),
            const SizedBox(height: 16),

            Card(
              child: SwitchListTile(
                title: const Text('Gating enabled',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(_enabled ? 'On' : 'Off'),
                value: _enabled,
                onChanged: (v) async {
                  await Storage.setMasterEnabled(v);
                  await Engine.setMasterEnabled(v);
                  _refresh();
                },
              ),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text('APPS & TODAY’S USE',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.6)),
                ),
                TextButton.icon(
                  onPressed: () => _edit(
                      (onNext) => AppRulesScreen(onNext: onNext, isOnboarding: false)),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit rules'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (gated.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No apps gated yet.',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              )
            else
              for (final pkg in gated)
                _AppStatusCard(
                  name: displayNameFor(pkg),
                  rule: rules[pkg] ?? const AppRule(),
                  status: _status[pkg],
                ),

            const SizedBox(height: 20),
            const Text('SETTINGS',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.6)),
            const SizedBox(height: 8),
            _EditTile(
              icon: Icons.child_care_rounded,
              title: 'Age band',
              value: bandLabel(band),
              onTap: () => _edit((onNext) => AgeBandScreen(onNext: onNext)),
            ),
            _EditTile(
              icon: Icons.apps_rounded,
              title: 'Gated apps',
              value: '${gated.length} app${gated.length == 1 ? '' : 's'}',
              onTap: () => _edit((onNext) => AppPickerScreen(onNext: onNext)),
            ),
            _EditTile(
              icon: Icons.tune_rounded,
              title: 'Permissions',
              value: _permissionsOk ? 'All granted' : 'Needs attention',
              onTap: () => _edit((onNext) => PermissionsScreen(onNext: onNext)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppStatusCard extends StatelessWidget {
  final String name;
  final AppRule rule;
  final AppStatus? status;
  const _AppStatusCard({
    required this.name,
    required this.rule,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final used = status?.usedMinutes ?? 0;
    final capText = rule.cap > 0 ? '$used / ${rule.cap} min today' : '$used min today';
    final remMin = status?.remMinutes ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.smartphone_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(
                    'Solve ${rule.questions} → ${rule.minutes} min'
                    '${rule.cap > 0 ? ' · cap ${rule.cap}/day' : ''}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(capText,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
                if (remMin > 0)
                  Text('$remMin min left now',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.correct)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onTap;
  const _Banner({
    required this.color,
    required this.icon,
    required this.title,
    required this.body,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: color)),
                    const SizedBox(height: 2),
                    Text(body,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  const _EditTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(value),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
