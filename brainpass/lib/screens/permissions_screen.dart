// screens/permissions_screen.dart — spec §8, §9.3
//
// Guided permission rows with live ✓/✗ status and deep-link buttons, now backed
// by the native engine channel. "Continue" stays disabled until overlay +
// accessibility are granted (battery exemption is strongly recommended).

import 'package:flutter/material.dart';

import '../engine.dart';
import '../theme.dart';
import '../widgets.dart';

class PermissionsScreen extends StatefulWidget {
  final VoidCallback onNext;
  const PermissionsScreen({super.key, required this.onNext});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  bool _overlay = false;
  bool _usage = false;
  bool _battery = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final overlay = await Engine.canDrawOverlays();
    final usage = await Engine.hasUsageAccess();
    final battery = await Engine.isIgnoringBattery();
    if (!mounted) return;
    setState(() {
      _overlay = overlay;
      _usage = usage;
      _battery = battery;
    });
    // Once both core permissions are on, make sure the guard is running.
    if (overlay && usage) Engine.startGuard();
  }

  bool get _canFinish => _overlay && _usage;

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Allow these permissions',
      subtitle:
          'BrainPass needs these to show the earn card and keep working in the '
          'background. It uses nothing else — no camera, location, or contacts.',
      buttonLabel: _canFinish ? 'Continue' : 'Grant the first two to continue',
      onButton: _canFinish ? widget.onNext : null,
      child: Column(
        children: [
          _PermissionRow(
            icon: Icons.layers_rounded,
            title: 'Draw over other apps',
            body: 'So the earn card can appear over games and videos.',
            granted: _overlay,
            onTap: () async {
              await Engine.requestOverlay();
              _refresh();
            },
          ),
          _PermissionRow(
            icon: Icons.bar_chart_rounded,
            title: 'Usage access',
            body: 'So BrainPass knows when your child opens a gated app. '
                'Find "BrainPass" in the list and turn it on.',
            granted: _usage,
            onTap: () async {
              await Engine.openUsageAccessSettings();
              _refresh();
            },
          ),
          _PermissionRow(
            icon: Icons.battery_charging_full_rounded,
            title: 'Ignore battery optimisation',
            body: 'Recommended — stops Android from killing BrainPass in the '
                'background. On Xiaomi/Redmi also enable Autostart.',
            granted: _battery,
            optional: true,
            onTap: () async {
              await Engine.requestIgnoreBattery();
              _refresh();
            },
          ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool granted;
  final bool optional;
  final VoidCallback onTap;
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.granted,
    required this.onTap,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      if (optional)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('recommended',
                              style: TextStyle(fontSize: 11)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textMuted, height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  if (granted)
                    const Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.correct, size: 20),
                        SizedBox(width: 6),
                        Text('Granted',
                            style: TextStyle(
                                color: AppColors.correct,
                                fontWeight: FontWeight.w600)),
                      ],
                    )
                  else
                    OutlinedButton(
                      onPressed: onTap,
                      child: const Text('Open settings'),
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
