// screens/splash_screen.dart
//
// The brand moment shown on every launch: a solid yellow field with just the
// owl in the middle. It fades in, holds for a beat, then routes on by itself —
// no buttons, purely branding.

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

class SplashScreen extends StatefulWidget {
  /// Builds the screen to show once the splash is done (onboarding or home).
  final Widget Function() nextBuilder;
  const SplashScreen({super.key, required this.nextBuilder});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _opacity = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Fade the owl in on the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _opacity = 1);
    });
    // Hold the brand moment, then move on.
    _timer = Timer(const Duration(milliseconds: 2500), _goNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) => widget.nextBuilder(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Solid logo yellow — no gradient.
      backgroundColor: AppColors.accent,
      body: Center(
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutBack,
            builder: (context, v, child) =>
                Transform.scale(scale: v, child: child),
            child: Image.asset(
              'assets/mascot_opening.png',
              width: 220,
              height: 220,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
