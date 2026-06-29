// screens/permission_step.dart
//
// One permission per screen, with auto-detect + auto-advance: when the parent
// returns from the system settings and the permission is granted, the screen
// shows a ✓ and slides to the next step on its own — no "Continue" / "I did it"
// taps. For permissions Android won't let us read (Autostart), we advance
// optimistically once the parent has opened the settings.

import 'package:flutter/material.dart';

import '../theme.dart';

class PermissionStepScreen extends StatefulWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String buttonLabel;

  /// Returns whether the permission is granted. Null = can't be read (Autostart).
  final Future<bool> Function()? check;

  /// Opens the relevant system settings / dialog.
  final Future<void> Function() request;

  /// Show the "find this in the list" preview (for list-based screens).
  final bool showFindCard;

  /// Allow a discreet "Skip for now" (for recommended-but-not-required steps).
  final bool skippable;

  final int step;
  final int total;
  final VoidCallback onNext;

  const PermissionStepScreen({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.request,
    required this.step,
    required this.total,
    required this.onNext,
    this.check,
    this.showFindCard = false,
    this.skippable = false,
  });

  @override
  State<PermissionStepScreen> createState() => _PermissionStepScreenState();
}

class _PermissionStepScreenState extends State<PermissionStepScreen>
    with WidgetsBindingObserver {
  bool _granted = false;
  bool _opened = false; // user tapped the button (opened settings) at least once
  bool _advancing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _evaluate(initial: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _evaluate();
  }

  Future<void> _evaluate({bool initial = false}) async {
    if (_advancing) return;
    final check = widget.check;
    if (check != null) {
      final granted = await check();
      if (granted) {
        _advance();
      }
    } else {
      // Undetectable (Autostart): advance once they've returned from settings.
      if (_opened && !initial) _advance();
    }
  }

  void _advance() {
    if (_advancing || !mounted) return;
    setState(() {
      _advancing = true;
      _granted = true;
    });
    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted) widget.onNext();
    });
  }

  Future<void> _onButton() async {
    _opened = true;
    await widget.request();
    // The result is picked up in didChangeAppLifecycleState on resume.
  }

  @override
  Widget build(BuildContext context) {
    final color = _granted ? AppColors.correct : AppColors.primary;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
          child: Column(
            children: [
              _ProgressDots(step: widget.step, total: widget.total),
              const Spacer(),
              // Big friendly icon / check
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: _granted
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.correct, size: 64)
                    : Text(widget.emoji, style: const TextStyle(fontSize: 60)),
              ),
              const SizedBox(height: 28),
              Text(
                _granted ? 'Done!' : widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              if (widget.showFindCard && !_granted) ...[
                const SizedBox(height: 24),
                const _FindThisCard(),
              ],
              const Spacer(),
              if (!_granted) ...[
                FilledButton(
                  onPressed: _onButton,
                  child: Text(widget.buttonLabel),
                ),
                if (widget.skippable)
                  TextButton(
                    onPressed: widget.onNext,
                    child: const Text('Skip for now'),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the parent exactly what to look for in a settings list.
class _FindThisCard extends StatelessWidget {
  const _FindThisCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Find this and turn it on:',
          style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Nupo',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark),
              ),
              const Spacer(),
              const Icon(Icons.toggle_on_rounded,
                  color: AppColors.correct, size: 40),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressDots extends StatelessWidget {
  final int step;
  final int total;
  const _ProgressDots({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 1; i <= total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == step ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i <= step ? AppColors.primary : const Color(0xFFD8DCEA),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
