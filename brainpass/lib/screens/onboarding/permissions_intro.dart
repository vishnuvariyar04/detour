// screens/onboarding/permissions_intro.dart
//
// Android-only: the iOS design has no permission steps (it uses Screen Time),
// but the gating engine here cannot work without them. Lifted out of the
// retired survey_screens.dart when the onboarding was ported from the iOS
// build.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../theme.dart';
import '../../widgets.dart';
import 'onb_widgets.dart';

class PermissionsIntroScreen extends StatelessWidget {
  final VoidCallback onNext;
  final bool autostart;
  final int? step;
  final int? total;
  const PermissionsIntroScreen({
    super.key,
    required this.onNext,
    required this.autostart,
    this.step,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    final count = autostart ? 4 : 3;
    final rows = <(IconData, Color, Color, String)>[
      (
        Symbols.layers_rounded,
        AppColors.primary,
        AppColors.primarySoft,
        'Show lessons over the apps you picked',
      ),
      (
        Symbols.visibility_rounded,
        AppColors.accentDeep,
        AppColors.accentSoft,
        'Notice when one of those apps opens',
      ),
      (
        Symbols.bolt_rounded,
        AppColors.correct,
        AppColors.correctSoft,
        'Keep working in the background',
      ),
      if (autostart)
        (
          Symbols.rocket_launch_rounded,
          Color(0xFFE0642F),
          Color(0xFFFFEFE6),
          'Restart if the phone closes it',
        ),
    ];
    return OnbScaffold(
      step: step ?? 1,
      total: total ?? 1,
      buttonLabel: 'Let’s do it',
      onButton: onNext,
      mascot: 'assets/nupo/focused.png',
      line: 'A few switches and I can get to work.',
      eyebrow: 'ALMOST THERE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last thing. $count quick switches.', style: kStepTitle),
          const SizedBox(height: 8),
          const Text(
            'Android needs your permission for Nupo to do its job. Each takes '
            'a few seconds and brings you straight back.',
            style: AppText.body,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppColors.cardDecoration(),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const Divider(height: 22),
                  Row(
                    children: [
                      IconBadge(
                        rows[i].$1,
                        size: 19,
                        color: rows[i].$2,
                        background: rows[i].$3,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(rows[i].$4, style: AppText.cardTitle),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// S34 — attribution
// ---------------------------------------------------------------------------
