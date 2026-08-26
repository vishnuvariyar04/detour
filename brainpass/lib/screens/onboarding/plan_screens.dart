// screens/onboarding/plan_screens.dart — PDF screens 14-16.
//
//  14 — "<child>'s first month": a curated 4-week syllabus. The PDF notes this
//       screen "lives or dies on genuinely curated content", so the weeks are
//       real topic lists chosen by age band + the subject picked on screen 12,
//       not filler.
//  15 — the projection: ~500 questions in 30 days.
//  16 — "Why this actually works": the honest mechanism (Premack principle).
//       Deliberately NO invented statistics (CLAUDE.md §2 bans them).


import 'package:flutter/material.dart';

import '../../theme.dart';
import 'onb_widgets.dart';
import 'story_beats.dart' show Nupo;

// ---------------------------------------------------------------------------
// Screen 14 — the curated month
// ---------------------------------------------------------------------------

/// Four weeks of topics, chosen by (subject, age band). Kept as plain data so
/// it stays swappable when the real question banks land.
List<List<String>> monthPlanFor({
  required String subject,
  required String band,
}) {
  final young = band == 'a' || band == '5-7';
  switch (subject) {
    case 'maths':
      return young
          ? [
              ['Counting to 100', 'Adding to 10'],
              ['Taking away', 'Shapes around us'],
              ['Counting money', 'Telling the time'],
              ['Doubles and halves', 'Simple word problems'],
            ]
          : [
              ['Times tables to 10', 'Counting money'],
              ['Fractions', 'Place value'],
              ['Multiplication to 12', 'Simple logic'],
              ['Word problems', 'Division basics'],
            ];
    case 'reading':
      return young
          ? [
              ['Letter sounds', 'Rhyming words'],
              ['Sight words', 'Simple sentences'],
              ['Story order', 'Opposites'],
              ['Reading for meaning', 'New words'],
            ]
          : [
              ['Vocabulary builders', 'Synonyms'],
              ['Reading comprehension', 'Prefixes'],
              ['Idioms', 'Story structure'],
              ['Inference', 'Spelling patterns'],
            ];
    case 'gk':
      return young
          ? [
              ['Animals of the world', 'Colours and flags'],
              ['My body', 'Seasons and weather'],
              ['Fruits and plants', 'Community helpers'],
              ['Land and water', 'Famous places'],
            ]
          : [
              ['World capitals', 'Rivers and mountains'],
              ['The solar system', 'Inventions'],
              ['Human body', 'Ancient history'],
              ['Flags and currencies', 'Famous firsts'],
            ];
    default: // 'mix' — a bit of everything
      return young
          ? [
              ['Counting and sums', 'Letter sounds'],
              ['Shapes', 'Animals of the world'],
              ['Telling the time', 'Sight words'],
              ['Simple logic', 'Seasons and weather'],
            ]
          : [
              ['Times tables to 10', 'Counting money'],
              ['Fractions', 'World capitals'],
              ['Multiplication to 12', 'Simple logic'],
              ['Word problems', 'The solar system'],
            ];
  }
}

class MonthPlanScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final String? stepLabel;
  final int step;
  final int total;
  final String childName;
  final String subject;
  final String band;
  final VoidCallback onNext;

  const MonthPlanScreen({
    super.key,
    required this.step,
    required this.total,
    required this.childName,
    required this.subject,
    required this.band,
    required this.onNext,
    this.onBack,
    this.stepLabel,
  });

  @override
  Widget build(BuildContext context) {
    final weeks = monthPlanFor(subject: subject, band: band);
    return OnbScaffold(
      step: step,
      total: total,
      buttonLabel: 'Continue',
      onButton: onNext,
      onBack: onBack,
      stepLabel: stepLabel,
      eyebrow: 'The plan',
      spot: MascotSpot.right,
      mascot: Nupo.starStudent,
      line: 'Four weeks, already planned.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          Text(
            "$childName's first month",
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'One small win every week',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < weeks.length; i++) ...[
            _WeekRow(index: i + 1, topics: weeks[i]),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final int index;
  final List<String> topics;
  const _WeekRow({required this.index, required this.topics});

  @override
  Widget build(BuildContext context) {
    const colors = [
      AppColors.primary,
      AppColors.done,
      AppColors.accentDeep,
      AppColors.wrong,
    ];
    const labels = [
      'Build the base',
      'Add a challenge',
      'Make it stick',
      'Use it with confidence',
    ];
    final color = colors[index - 1];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 14, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labels[index - 1],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  topics.join('  ·  '),
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: color, size: 20),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen 15 — the projection
// ---------------------------------------------------------------------------

class PlanProjectionScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final String? stepLabel;
  final int step;
  final int total;
  final String childName;
  final VoidCallback onNext;

  const PlanProjectionScreen({
    super.key,
    required this.step,
    required this.total,
    required this.childName,
    required this.onNext,
    this.onBack,
    this.stepLabel,
  });

  @override
  Widget build(BuildContext context) {
    return OnbScaffold(
      step: step,
      total: total,
      buttonLabel: "Start $childName's plan",
      onButton: onNext,
      onBack: onBack,
      stepLabel: 'Plan',
      tone: StepTone.brand,
      buttonTone: ButtonTone.amber,
      spot: MascotSpot.none,
      centerContent: true,
      // On the brand tone every colour here has to invert, or the payoff screen
      // is dark ink on brand purple.
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          Image.asset(Nupo.aplus2, width: 132, semanticLabel: 'Nupo'),
          const SizedBox(height: 26),
          // The number is arithmetic, not a claim: ~4 gates/day x 4 questions
          // x 30 days. Honest by construction (CLAUDE.md §2). It counts up,
          // which is the design's own treatment of this screen.
          const _CountUp(to: 500),
          const SizedBox(height: 4),
          const Text(
            'questions answered',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'In thirty days, and you will not have asked once.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen 16 — why it works
// ---------------------------------------------------------------------------

class WhyItWorksScreen extends StatelessWidget {
  final VoidCallback? onBack;
  final String? stepLabel;
  final int step;
  final int total;
  final String childName;
  final VoidCallback onNext;

  const WhyItWorksScreen({
    super.key,
    required this.step,
    required this.total,
    required this.childName,
    required this.onNext,
    this.onBack,
    this.stepLabel,
  });

  @override
  Widget build(BuildContext context) {
    return OnbScaffold(
      step: step,
      total: total,
      buttonLabel: 'Makes sense',
      onButton: onNext,
      onBack: onBack,
      stepLabel: 'Plan',
      eyebrow: 'The idea',
      // The tone was never passed, so this screen painted white type on the
      // default lilac and was all but invisible — the bug is in the reference
      // build too. `done` is what the copy above it always assumed, and it
      // gives the closing step its own stage after the purple projection.
      tone: StepTone.done,
      buttonTone: ButtonTone.light,
      spot: MascotSpot.none,
      centerContent: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Why this actually works',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 27,
              height: 1.2,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The lesson sits in front of something they already want. '
            'That is why it gets done.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 30),

          // The trade itself. A mascot decorated the screen but argued
          // nothing; this answers the parent's actual question — how much am
          // I asking of them? The short amber bar fills first, then the long
          // one, so order and ratio land in one image.
          const _EffortRewardBar(),

          const SizedBox(height: 30),
          Text(
            // "they", not "he": onboarding never asks the child's gender, so
            // a pronoun here is a guess the app has no basis for.
            'Veggies before dessert — and $childName barely notices.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

/// The ask, next to what it buys — animated so the order reads as well as the
/// ratio: a sliver of learning fills, then the long stretch of play it earns.
///
/// The bar is schematic, not a chart: the real ratio (30s to 15min) would make
/// the amber segment three pixels wide. It is drawn generously and the labels
/// carry the honest numbers, so it overstates the cost rather than the reward.
class _EffortRewardBar extends StatefulWidget {
  const _EffortRewardBar();

  @override
  State<_EffortRewardBar> createState() => _EffortRewardBarState();
}

class _EffortRewardBarState extends State<_EffortRewardBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Eased 0..1 for a window of the loop.
  double _phase(double t, double from, double to) =>
      Curves.easeOutCubic.transform(((t - from) / (to - from)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final learn = _phase(t, 0.06, 0.30);
        final play = _phase(t, 0.36, 0.72);
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 26,
                  child: _Segment(
                    fill: learn,
                    color: AppColors.accent,
                    height: 58,
                    icon: Icons.school_rounded,
                    iconColor: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 74,
                  child: _Segment(
                    fill: play,
                    color: Colors.white,
                    height: 58,
                    icon: Icons.play_arrow_rounded,
                    iconColor: AppColors.done,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 26,
                  child: _BarLabel(
                    'About 30 seconds',
                    opacity: learn,
                    bold: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 74,
                  child: _BarLabel('Then the app they wanted', opacity: play),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Segment extends StatelessWidget {
  final double fill;
  final Color color;
  final double height;
  final IconData icon;
  final Color iconColor;

  const _Segment({
    required this.fill,
    required this.color,
    required this.height,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // The empty track, so the shape is legible before it fills.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: fill.clamp(0.001, 1.0),
              child: Container(
                height: height,
                constraints: const BoxConstraints(minWidth: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          if (fill > 0.85)
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: ((fill - 0.85) / 0.15).clamp(0.0, 1.0),
                  child: Icon(icon, size: 24, color: iconColor),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BarLabel extends StatelessWidget {
  final String text;
  final double opacity;
  final bool bold;
  const _BarLabel(this.text, {required this.opacity, this.bold = false});

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            height: 1.25,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
            color: Colors.white.withValues(alpha: bold ? 1 : 0.85),
          ),
        ),
      );
}

/// The projection number, counting up from zero.
///
/// The design eases a counter to ~500 over 1.1s the moment the screen arrives;
/// a number that lands rather than simply being printed is what makes the
/// screen feel earned.
class _CountUp extends StatefulWidget {
  final int to;
  const _CountUp({required this.to});

  @override
  State<_CountUp> createState() => _CountUpState();
}

class _CountUpState extends State<_CountUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _v;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _v = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _v,
      builder: (context, _) => Text(
        '~${(widget.to * _v.value).round()}',
        style: const TextStyle(
          fontSize: 62,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.05,
        ),
      ),
    );
  }
}
