// screens/keep_running_screen.dart
//
// Reliability setup. On Xiaomi/Oppo/Vivo/etc., the app being killed in the
// background is the #1 cause of gating silently stopping — and "Autostart" is
// the master switch that fixes it. We deep-link the parent straight to it (and
// to the battery setting) so they don't have to hunt through settings.

import 'package:flutter/material.dart';

import '../engine.dart';
import '../theme.dart';
import '../widgets.dart';

class KeepRunningScreen extends StatefulWidget {
  final VoidCallback onNext;
  final bool isOnboarding;
  const KeepRunningScreen({
    super.key,
    required this.onNext,
    this.isOnboarding = true,
  });

  @override
  State<KeepRunningScreen> createState() => _KeepRunningScreenState();
}

class _KeepRunningScreenState extends State<KeepRunningScreen>
    with WidgetsBindingObserver {
  bool _battery = false;
  bool _autostartRelevant = false;
  bool _autostartConfirmed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
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

  Future<void> _load() async {
    final relevant = await Engine.autostartRelevant();
    if (!mounted) return;
    setState(() => _autostartRelevant = relevant);
    _refresh();
  }

  Future<void> _refresh() async {
    final b = await Engine.isIgnoringBattery();
    if (!mounted) return;
    setState(() => _battery = b);
  }

  // If the phone has Autostart, require the parent to confirm they enabled it
  // (there's no API to read it). Otherwise this step is informational.
  bool get _canContinue => !_autostartRelevant || _autostartConfirmed;

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Keep Nupo running',
      subtitle:
          'Phones aggressively close background apps. These keep Nupo '
          'working so gating never silently stops.',
      buttonLabel: widget.isOnboarding ? 'Finish setup' : 'Done',
      onButton: _canContinue ? widget.onNext : null,
      child: Column(
        children: [
          if (_autostartRelevant)
            _ReliabilityCard(
              icon: Icons.rocket_launch_rounded,
              title: 'Turn on Autostart',
              important: true,
              body: 'THE most important one on your phone. In the screen that '
                  'opens, find Nupo and switch Autostart ON.',
              action: FilledButton(
                onPressed: () async {
                  await Engine.openAutostartSettings();
                },
                child: const Text('Open Autostart settings'),
              ),
              footer: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                value: _autostartConfirmed,
                onChanged: (v) =>
                    setState(() => _autostartConfirmed = v ?? false),
                title: const Text("I've turned Autostart ON for Nupo"),
              ),
            ),
          _ReliabilityCard(
            icon: Icons.battery_charging_full_rounded,
            title: 'Allow background battery use',
            important: false,
            granted: _battery,
            body: 'Set Nupo to "No restrictions" / "Don\'t optimise" so it '
                'isn\'t put to sleep.',
            action: _battery
                ? null
                : OutlinedButton(
                    onPressed: () async {
                      await Engine.requestIgnoreBattery();
                      _refresh();
                    },
                    child: const Text('Allow'),
                  ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'Tip: in the recent-apps screen, lock Nupo (pull its card '
              'down or tap the lock icon) so it isn\'t swiped away.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReliabilityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool important;
  final bool granted;
  final Widget? action;
  final Widget? footer;
  const _ReliabilityCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.important,
    this.granted = false,
    this.action,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: important ? AppColors.primary : const Color(0xFFE8EAF2),
          width: important ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
              ),
              if (granted)
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.correct, size: 22),
            ],
          ),
          const SizedBox(height: 6),
          Text(body,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textMuted, height: 1.35)),
          if (action != null) ...[const SizedBox(height: 10), action!],
          ?footer,
        ],
      ),
    );
  }
}
