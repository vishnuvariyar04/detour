// screens/onboarding/permissions_intro.dart — what is coming, before Android
// asks. Android-only: the gating engine cannot work without these switches.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../theme.dart';
import 'onb_kit.dart';

class PermissionsIntroScreen extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final bool autostart;
  final double progress;
  const PermissionsIntroScreen({
    super.key,
    required this.onNext,
    required this.autostart,
    required this.progress,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, Color, String)>[
      (Symbols.layers_rounded, AppColors.primary, 'Show lessons over apps'),
      (Symbols.visibility_rounded, AppColors.done, 'Notice when an app opens'),
      (Symbols.bolt_rounded, AppColors.accentDeep, 'Stay on in the background'),
      if (autostart) (Symbols.restart_alt_rounded, AppColors.correct, 'Restart if the phone closes it'),
    ];
    return OnbPage(
      top: StepChrome(progress: progress, onBack: onBack),
      bottom: [ChunkyButton(label: 'Let’s do it', onPressed: onNext)],
      content: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Image.asset(Nupo.focused, width: 90, semanticLabel: 'Nupo'),
            const SizedBox(width: 8),
            const Flexible(child: SpeechBubble('Last step. Under a minute.')),
          ],
        ),
        const SizedBox(height: 16),
        Text('${rows.length} quick switches', style: OnbText.titleSm),
        const SizedBox(height: 16),
        for (var i = 0; i < rows.length; i++) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: tint(rows[i].$2, 0.14), borderRadius: BorderRadius.circular(13)),
                  child: Icon(rows[i].$1, color: rows[i].$2, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(rows[i].$3, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
                Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 9),
        ],
        const Spacer(),
      ],
    );
  }
}
