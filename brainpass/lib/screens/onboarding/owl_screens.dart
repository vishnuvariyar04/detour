// screens/onboarding/owl_screens.dart
//
// S23 + S25 — the "will my kid quit?" killers: the owl as a collectible the
// child owns and grows, then the 30-day projection.

import 'package:flutter/material.dart';

import '../../questions.dart';
import '../../storage.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'onb_widgets.dart';

// ---------------------------------------------------------------------------
// S23 — meet the owl (collectible card with level + streak + XP)
// ---------------------------------------------------------------------------

class MeetOwlScreen extends StatelessWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const MeetOwlScreen({super.key, required this.onNext, this.step, this.total});

  @override
  Widget build(BuildContext context) {
    final child = Storage.childNameOr();
    return StatementScreen(
      step: step,
      total: total,
      hero: const _OwlCard(),
      title: 'Meet Nupo — $child’s learning buddy.',
      body: 'Nupo levels up every time $child learns something.\n'
          'Kids don’t fight Nupo. They look after him.',
      ctaLabel: 'Continue',
      onNext: onNext,
    );
  }
}

class _OwlCard extends StatelessWidget {
  const _OwlCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.35),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const HaloMascot('assets/mascot_opening.png',
              size: 110, sparkles: true),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chip('Level 1', AppColors.primarySoft, AppColors.primary),
              const SizedBox(width: 8),
              _chip('🔥 0 day streak', AppColors.accentSoft,
                  AppColors.accentDeep),
            ],
          ),
          const SizedBox(height: 14),
          // XP bar at 5% — brand-new buddy, ready to grow.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('XP', style: AppText.overline),
                  Text('5 / 100', style: AppText.overline),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFEDF6),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.05,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// S25 — the 30-day projection (Cal AI-style future pacing)
// ---------------------------------------------------------------------------

class ProjectionScreen extends StatefulWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const ProjectionScreen(
      {super.key, required this.onNext, this.step, this.total});

  @override
  State<ProjectionScreen> createState() => _ProjectionScreenState();
}

class _ProjectionScreenState extends State<ProjectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String get _skillLine {
    switch (bandFromString(Storage.ageBand)) {
      case Band.a:
        return 'Counting: shaky → solid';
      case Band.b:
        return 'Number facts: shaky → solid';
      case Band.c:
        return 'Times tables: shaky → solid';
      case Band.d:
        return 'Mental math: shaky → solid';
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = Storage.childNameOr();
    return OnbScaffold(
      step: widget.step,
      total: widget.total,
      title: 'Here’s $child, 30 days from now.',
      centerText: true,
      ctaLabel: 'I want that',
      onCta: widget.onNext,
      child: Column(
        children: [
          const SizedBox(height: 4),
          // 30 squares filling one by one — a month of learning moments.
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final filled =
                  (Curves.easeOut.transform(_c.value) * 30).round();
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: AppColors.cardDecoration(),
                child: Column(
                  children: [
                    GridView.count(
                      crossAxisCount: 10,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      children: [
                        for (var i = 0; i < 30; i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: i < filled
                                  ? AppColors.accent
                                  : const Color(0xFFEFEDF6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: i < filled
                                ? const Icon(Icons.star_rounded,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text('ONE MONTH OF LEARNING MOMENTS',
                        style: AppText.overline),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: AppColors.cardDecoration(),
            child: Column(
              children: [
                _statRow('🧠', '540+ questions answered'),
                const Divider(height: 20),
                _statRow('🔥', '30-day learning streak'),
                const Divider(height: 20),
                _statRow('📈', _skillLine),
              ],
            ),
          ),
          const SizedBox(height: 14),
          InfoPill(
            icon: Icons.schedule_rounded,
            text: '…all inside time they were already spending',
          ),
        ],
      ),
    );
  }

  Widget _statRow(String emoji, String label) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
