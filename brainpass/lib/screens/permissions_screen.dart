// screens/permissions_screen.dart
//
// The single parent-settings screen for every permission Nupo relies on:
// draw-over-apps + usage access (core), battery + autostart (reliability). Live
// ✓ status where Android lets us read it; a deep-link "Open" button otherwise.
// (This replaces the old separate "Permissions" and "Keep Nupo running" screens.)

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
  bool _autostartRelevant = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Engine.autostartRelevant().then((v) {
      if (mounted) setState(() => _autostartRelevant = v);
    });
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
    if (overlay && usage) Engine.startGuard();
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Permissions',
      subtitle: 'Keep these on so Nupo works reliably.',
      buttonLabel: 'Done',
      onButton: widget.onNext,
      child: Column(
        children: [
          _PermRow(
            icon: Icons.layers_rounded,
            color: AppColors.primary,
            background: AppColors.primarySoft,
            title: 'Draw over other apps',
            body: 'Shows the learning moment over an app.',
            granted: _overlay,
            onOpen: () async {
              await Engine.requestOverlay();
              _refresh();
            },
          ),
          _PermRow(
            icon: Icons.visibility_rounded,
            color: AppColors.correct,
            background: AppColors.correctSoft,
            title: 'Usage access',
            body: 'Lets Nupo know the right moment for a lesson.',
            granted: _usage,
            onOpen: () async {
              await Engine.openUsageAccessSettings();
              _refresh();
            },
          ),
          _PermRow(
            icon: Icons.bolt_rounded,
            color: AppColors.accentDeep,
            background: AppColors.accentSoft,
            title: 'Background battery',
            body: 'Set to “No restrictions” so Nupo isn’t put to sleep.',
            granted: _battery,
            onOpen: () async {
              await Engine.requestIgnoreBattery();
              _refresh();
            },
          ),
          if (_autostartRelevant)
            _PermRow(
              icon: Icons.rocket_launch_rounded,
              color: const Color(0xFF6D8BFF),
              background: const Color(0xFFEAF0FF),
              title: 'Auto-restart',
              body: 'Switch it on for Nupo so it can turn itself back on.',
              granted: null, // can't be read on Xiaomi/etc.
              onOpen: () => Engine.openAutostartSettings(),
            ),
          const SizedBox(height: 8),
          const InfoPill(
            icon: Icons.push_pin_rounded,
            text: 'In recent apps, lock Nupo so it isn’t swiped away.',
          ),
        ],
      ),
    );
  }
}

class _PermRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String body;

  /// true = granted, false = not granted, null = can't be detected (autostart).
  final bool? granted;
  final VoidCallback onOpen;

  const _PermRow({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.body,
    required this.granted,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final isOn = granted == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppColors.cardDecoration(),
      child: Row(
        children: [
          IconBadge(icon, color: color, background: background),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.cardTitle),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isOn)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.correctSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded,
                      color: AppColors.correct, size: 16),
                  SizedBox(width: 4),
                  Text('On',
                      style: TextStyle(
                          color: AppColors.correct,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5)),
                ],
              ),
            )
          else
            SizedBox(
              height: 38,
              child: FilledButton(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(72, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(19),
                  ),
                ),
                child: const Text('Open',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }
}
