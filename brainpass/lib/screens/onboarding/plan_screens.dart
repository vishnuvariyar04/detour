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
List<List<String>> monthPlanFor({required String subject, required String band}) {
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
      line: 'Four weeks. I have it planned already.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            "$childName's first month",
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 20),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('WEEK $index',
                style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              topics.join(' · '),
              style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  height: 1.35),
            ),
          ),
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
                color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            "In 30 days — and you won't have\nnagged once.",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 17,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.78)),
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
            "It's the oldest trick there is: the good stuff comes right "
            'before the fun stuff.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.45,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 26),

          // The mechanism, which is the whole point of the screen and which
          // the reference build reduced to another paragraph. Old loop faded,
          // new loop solid, so the change reads at a glance.
          const _LoopRow(
            left: 'Bored, again',
            right: 'Phone comes out',
            solid: false,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Icon(Icons.arrow_downward_rounded,
                size: 22, color: Colors.white),
          ),
          const _LoopRow(
            left: 'Two questions',
            right: 'Then the app opens',
            solid: true,
          ),

          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Image.asset(Nupo.meditate, height: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    // "they", not "he": onboarding never asks the child's
                    // gender, so a pronoun here is a guess the app has no
                    // basis for — and it sits right under their name.
                    "Veggies before dessert. $childName won't fight it the "
                    'way they fight a workbook.',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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

/// One rung of the before/after loop on the closing step.
class _LoopRow extends StatelessWidget {
  final String left;
  final String right;

  /// The "after" rung is solid white so it reads as the thing that changed.
  final bool solid;

  const _LoopRow({
    required this.left,
    required this.right,
    required this.solid,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: _cell(left)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward_rounded,
                size: 18,
                color: Colors.white.withValues(alpha: solid ? 1 : 0.6)),
          ),
          Expanded(child: _cell(right)),
        ],
      );

  Widget _cell(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: solid ? Colors.white : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: solid
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.3,
            fontWeight: FontWeight.w800,
            color: solid ? AppColors.done : Colors.white.withValues(alpha: 0.9),
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
