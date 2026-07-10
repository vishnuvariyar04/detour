// screens/permission_step.dart
//
// One permission per screen, with auto-detect + auto-advance: when the parent
// returns from the system settings and the permission is granted, the screen
// shows a ✓ and slides to the next step on its own — no "Continue" / "I did it"
// taps. For permissions Android won't let us read (Autostart), we advance
// optimistically once the parent has opened the settings.

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

class PermissionStepScreen extends StatefulWidget {
  final IconData icon;
  final String? mascot; // optional asset shown instead of the icon badge

  /// Hero tint — each step gets its own colour so the flow feels alive.
  final Color heroColor;
  final Color heroBackground;

  final String title;
  final String subtitle;
  final String buttonLabel;

  /// Returns whether the permission is granted. Null = can't be read (Autostart).
  final Future<bool> Function()? check;

  /// Opens the relevant system settings / dialog.
  final Future<void> Function() request;

  /// Show the "find Nupo in the list" preview (for list-based settings pages).
  final bool showFindCard;

  /// Allow a discreet "Skip for now" (for recommended-but-not-required steps).
  final bool skippable;

  final int step;
  final int total;
  final VoidCallback onNext;

  const PermissionStepScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.request,
    required this.step,
    required this.total,
    required this.onNext,
    this.heroColor = AppColors.primary,
    this.heroBackground = Colors.white,
    this.mascot,
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
      if (granted) _advance();
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
    return Scaffold(
      body: Container(
        decoration: AppColors.bgDecoration(),
        height: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              NupoTopBar(step: widget.step, total: widget.total),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, viewport) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: viewport.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _hero(),
                          const SizedBox(height: 26),
                          Text(
                            _granted ? 'Done!' : widget.title,
                            textAlign: TextAlign.center,
                            style: AppText.title,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _granted ? 'Permission granted.' : widget.subtitle,
                            textAlign: TextAlign.center,
                            style: AppText.body,
                          ),
                          if (!_granted && widget.showFindCard) ...[
                            const SizedBox(height: 26),
                            _findCard(),
                          ],
                          // Keep the block optically centered (hero is tall).
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_granted) ...[
                      PrimaryButton(
                        label: widget.buttonLabel,
                        icon: widget.icon,
                        onPressed: _onButton,
                      ),
                      if (widget.skippable)
                        TextButton(
                          onPressed: widget.onNext,
                          child: const Text('Skip for now'),
                        )
                      else ...[
                        const SizedBox(height: 12),
                        const InfoPill(
                          icon: Icons.favorite_rounded,
                          text: 'A quick lesson, then straight to play',
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    if (_granted) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.6, end: 1),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        builder: (context, v, child) => Transform.scale(scale: v, child: child),
        child: Container(
          width: 140,
          height: 140,
          decoration: const BoxDecoration(
            color: AppColors.correctSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded,
              color: AppColors.correct, size: 72),
        ),
      );
    }
    if (widget.mascot != null) {
      return Image.asset(
        widget.mascot!,
        width: 160,
        height: 160,
        fit: BoxFit.contain,
      );
    }
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: widget.heroBackground,
        shape: BoxShape.circle,
        boxShadow: AppColors.softShadow,
      ),
      child: Icon(widget.icon, color: widget.heroColor, size: 56),
    );
  }

  /// Compact "find Nupo in the list and switch it on" preview.
  Widget _findCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppColors.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('In the screen that opens, turn this on:',
              style: AppText.caption),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.shield_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Nupo',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const Icon(Icons.toggle_on_rounded,
                    color: AppColors.correct, size: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
