// screens/permissions_screen.dart
//
// The single parent-settings screen for every permission Nupo relies on:
// draw-over-apps + usage access (core), battery + autostart (reliability). Live
// ✓ status where Android lets us read it; a deep-link "Open" button otherwise.
// (This replaces the old separate "Permissions" and "Keep Nupo running" screens.)

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

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
      subtitle: 'Green means working. Tap Open to fix anything that is off.',
      buttonLabel: 'Done',
      onButton: widget.onNext,
      child: Column(
        children: [
          _PermRow(
            icon: Symbols.layers_rounded,
            color: AppColors.primary,
            background: AppColors.primarySoft,
            title: 'Display over other apps',
            body: _overlay ? 'Working' : 'Needs attention',
            granted: _overlay,
            onOpen: () async {
              Engine.watchReturn('overlay'); // auto-return once granted
              await Engine.requestOverlay();
              _refresh();
            },
          ),
          _PermRow(
            icon: Symbols.visibility_rounded,
            color: AppColors.correct,
            background: AppColors.correctSoft,
            title: 'Usage access',
            body: _usage ? 'Working' : 'Needs attention',
            granted: _usage,
            onOpen: () async {
              Engine.watchReturn('usage'); // auto-return once granted
              await Engine.openUsageAccessSettings();
              _refresh();
            },
          ),
          _PermRow(
            icon: Symbols.bolt_rounded,
            color: AppColors.accentDeep,
            background: AppColors.accentSoft,
            title: 'Background battery',
            body: _battery ? 'Working' : 'Recommended',
            granted: _battery,
            onOpen: () async {
              await Engine.requestIgnoreBattery();
              _refresh();
            },
          ),
          if (_autostartRelevant)
            _PermRow(
              icon: Symbols.rocket_launch_rounded,
              color: const Color(0xFF6D8BFF),
              background: const Color(0xFFEAF0FF),
              title: 'Restart automatically',
              body: 'Open settings',
              granted: null, // can't be read on Xiaomi/etc.
              onOpen: () => Engine.openAutostartSettings(),
            ),
          const SizedBox(height: 8),
          InfoPill(
            icon: Symbols.push_pin_rounded,
            text: 'Nupo only watches the apps you picked.',
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.correctSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, color: AppColors.correct, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Working',
                    style: TextStyle(
                      color: AppColors.correct,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
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
                child: const Text(
                  'Open',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
