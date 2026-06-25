// screens/intro_screen.dart — spec §9.1
//
// A single welcoming screen: what BrainPass does + the privacy promise.

import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets.dart';

class IntroScreen extends StatelessWidget {
  final VoidCallback onNext;
  const IntroScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Welcome to BrainPass',
      subtitle: 'Your child earns screen time by solving a few quick problems.',
      buttonLabel: 'Get started',
      onButton: onNext,
      child: Column(
        children: const [
          _Point(
            icon: Icons.school_rounded,
            title: 'Learn, then play',
            body:
                'When your child opens a game or video app, a friendly card asks '
                'them to solve a few age-appropriate questions first.',
          ),
          _Point(
            icon: Icons.lock_rounded,
            title: 'You stay in control',
            body:
                'A PIN protects every setting. Your child cannot turn BrainPass '
                'off — only you can.',
          ),
          _Point(
            icon: Icons.shield_rounded,
            title: 'Everything stays on this device',
            body:
                'BrainPass collects nothing. No accounts, no ads, no tracking. '
                'Your child’s data never leaves the phone.',
          ),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Point({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
