// screens/onboarding/survey_screens.dart
//
// The diagnostic + emotional arc of the funnel (spec S7–S18, S26–S27, S34–S35)
// plus the permissions intro. Everything here personalizes ON-DEVICE: answers
// go to Storage and are never transmitted (spec §7).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../engine.dart';
import '../../questions.dart';
import '../../safe_apps.dart';
import '../../storage.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'onb_widgets.dart';

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

/// 7,665 -> "7,600" (floored to the nearest hundred — spec §9.4: round DOWN).
String shockHoursText() {
  final years = 15 - Storage.childAge;
  final h = ((Storage.screenHours * 365 * years) ~/ 100) * 100;
  final s = h.toString();
  if (s.length <= 3) return s;
  return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
}

// ---------------------------------------------------------------------------
// S7 — diagnostic intro
// ---------------------------------------------------------------------------

class DiagnosticIntroScreen extends StatelessWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const DiagnosticIntroScreen(
      {super.key, required this.onNext, this.step, this.total});

  @override
  Widget build(BuildContext context) {
    final p = Storage.parentName;
    return StatementScreen(
      step: step,
      total: total,
      mascot: 'assets/mascot_pin.png',
      title: p.isEmpty ? 'Answer these honestly.' : '$p, answer these honestly.',
      body: 'It’s how we get Nupo right for ${Storage.childNameOr()}. '
          'No judgement — ever.',
      ctaLabel: 'Let’s start',
      onNext: onNext,
    );
  }
}

// ---------------------------------------------------------------------------
// S8 — child age (sets the question band + feeds the shock stat)
// ---------------------------------------------------------------------------

class ChildAgeScreen extends StatefulWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const ChildAgeScreen(
      {super.key, required this.onNext, this.step, this.total});

  @override
  State<ChildAgeScreen> createState() => _ChildAgeScreenState();
}

class _ChildAgeScreenState extends State<ChildAgeScreen> {
  int? _picked;

  Future<void> _pick(int age) async {
    if (_picked != null) return;
    HapticFeedback.selectionClick();
    setState(() => _picked = age);
    await Storage.setChildAge(age);
    final band = bandToString(bandFromAge(age));
    await Storage.setAgeBand(band);
    await Engine.setAgeBand(band);
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) widget.onNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = Storage.childNameOr();
    return OnbScaffold(
      step: widget.step,
      total: widget.total,
      title: 'How old is $child?',
      subtitle: 'Questions will match their age — you can change it any time.',
      child: Column(
        children: [
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              for (var age = 5; age <= 12; age++)
                _AgeTile(
                  label: age == 12 ? '12+' : '$age',
                  selected: _picked == age,
                  onTap: () => _pick(age),
                ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _picked == null
                ? const SizedBox.shrink()
                : _BandPreview(band: bandFromAge(_picked!)),
          ),
        ],
      ),
    );
  }
}

class _AgeTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _AgeTile(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.line,
          width: 1.5,
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: selected ? Colors.white : AppColors.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BandPreview extends StatelessWidget {
  final Band band;
  const _BandPreview({required this.band});

  @override
  Widget build(BuildContext context) {
    final desc = switch (band) {
      Band.a => 'Counting & simple sums',
      Band.b => 'Mental math & nature',
      Band.c => 'Times tables & trivia',
      Band.d => 'Advanced logic & math',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Symbols.auto_awesome_rounded,
              color: AppColors.accent, size: 16),
          const SizedBox(width: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: AppColors.accentDeep,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// S9 — daily screen time (feeds the shock stat)
// ---------------------------------------------------------------------------

class ScreenTimeScreen extends StatelessWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const ScreenTimeScreen(
      {super.key, required this.onNext, this.step, this.total});

  @override
  Widget build(BuildContext context) {
    // Honest midpoints of each range (spec §9.4: never inflate).
    const options = [
      (OnbChoice('u1', '🌤️', 'Under 1 hour'), 0.75),
      (OnbChoice('h12', '⏰', '1–2 hours'), 1.5),
      (OnbChoice('h23', '📱', '2–3 hours'), 2.5),
      (OnbChoice('h34', '📺', '3–4 hours'), 3.5),
      (OnbChoice('h4p', '🌙', '4+ hours'), 4.5),
    ];
    return SingleChoiceScreen(
      step: step,
      total: total,
      title: 'How long is ${Storage.childNameOr()} on a screen each day?',
      subtitle: 'Be honest — no judgement here.',
      options: [for (final o in options) o.$1],
      onPicked: (id) async {
        await Storage.setScreenHours(
            options.firstWhere((o) => o.$1.id == id).$2);
        onNext();
      },
    );
  }
}

// ---------------------------------------------------------------------------
// S10–S12 — shock → reframe → hope (the hinge of the funnel)
// ---------------------------------------------------------------------------

class ShockScreen extends StatelessWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const ShockScreen({super.key, required this.onNext, this.step, this.total});

  @override
  Widget build(BuildContext context) {
    final p = Storage.parentName;
    final child = Storage.childNameOr();
    return StatementScreen(
      step: step,
      total: total,
      emoji: '🤯',
      title: p.isEmpty
          ? 'At this rate, $child will spend over'
          : '$p, at this rate $child will spend over',
      extra: Column(
        children: [
          Text(
            '${shockHoursText()} hours',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'on a screen before they turn 15.',
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(fontSize: 16),
          ),
        ],
      ),
      ctaLabel: 'Continue',
      onNext: onNext,
    );
  }
}

class ReframeScreen extends StatelessWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const ReframeScreen(
      {super.key, required this.onNext, this.step, this.total});

  @override
  Widget build(BuildContext context) {
    return StatementScreen(
      step: step,
      total: total,
      emoji: '📚',
      title: 'That’s the number people say it takes to master a skill.',
      body: 'Right now, those hours are going nowhere.',
      ctaLabel: 'Continue',
      onNext: onNext,
    );
  }
}

class HopeScreen extends StatelessWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const HopeScreen({super.key, required this.onNext, this.step, this.total});

  @override
  Widget build(BuildContext context) {
    return StatementScreen(
      brand: true,
      hero: const HaloMascot('assets/mascot_opening.png',
          size: 150, sparkles: true),
      title: 'Nupo doesn’t take those hours away.',
      body:
          'It borrows 90 seconds of each one — and gives ${Storage.childNameOr()} '
          'a learning habit in return.',
      ctaLabel: 'Continue',
      onNext: onNext,
    );
  }
}

// ---------------------------------------------------------------------------
// S13–S14 — goals + the mirror
// ---------------------------------------------------------------------------

const goalOptions = [
  OnbChoice('habit', '📚', 'Build a daily learning habit'),
  OnbChoice('math', '➗', 'Get stronger at math'),
  OnbChoice('world', '🌍', 'Learn more about the world'),
  OnbChoice('fights', '😤', 'Fewer fights about the phone'),
  OnbChoice('count', '🧠', 'Make screen time actually count'),
  OnbChoice('nonag', '⏰', 'Do it without me nagging'),
  OnbChoice('focus', '🎯', 'Better focus and patience'),
];

class GoalsScreen extends StatelessWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const GoalsScreen({super.key, required this.onNext, this.step, this.total});

  @override
  Widget build(BuildContext context) {
    return MultiChoiceScreen(
      step: step,
      total: total,
      title: 'What do you want for ${Storage.childNameOr()}?',
      subtitle: 'Choose up to 3.',
      options: goalOptions,
      max: 3,
      onDone: (picked) async {
        await Storage.setGoals(picked);
        onNext();
      },
    );
  }
}

class _MirrorContent {
  final String reflection;
  final String headline;
  const _MirrorContent(this.reflection, this.headline);
}

const _mirrorByGoal = <String, _MirrorContent>{
  'habit': _MirrorContent(
    'Small daily reps are how habits stick. Nupo makes the rep automatic.',
    'A daily learning habit — on autopilot',
  ),
  'math': _MirrorContent(
    'Two minutes of math, many times a day, beats a weekly worksheet battle.',
    'Stronger math — 90 seconds at a time',
  ),
  'world': _MirrorContent(
    'Curiosity grows when interesting questions show up every single day.',
    'A little more world knowledge, daily',
  ),
  'fights': _MirrorContent(
    'You shouldn’t have to be the bad guy every evening. Nupo does the asking, '
    'so you don’t have to.',
    'Screen time without the standoff',
  ),
  'count': _MirrorContent(
    'The screen time is happening anyway. Nupo makes it give something back.',
    'Screen time that actually counts',
  ),
  'nonag': _MirrorContent(
    'You shouldn’t have to be the bad guy every evening. Nupo does the asking, '
    'so you don’t have to.',
    'A daily learning habit — on autopilot',
  ),
  'focus': _MirrorContent(
    'Short, steady challenges build patience better than any lecture.',
    'Better focus, built a little every day',
  ),
};

/// S14 — plays their top goal back on the bold brand background.
class MirrorScreen extends StatelessWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const MirrorScreen({super.key, required this.onNext, this.step, this.total});

  @override
  Widget build(BuildContext context) {
    final goals = Storage.goals;
    final topId = goals.isEmpty ? 'habit' : goals.first;
    final top = goalOptions.firstWhere(
      (o) => o.id == topId,
      orElse: () => goalOptions.first,
    );
    final content = _mirrorByGoal[topId] ?? _mirrorByGoal['habit']!;
    final child = Storage.childNameOr();

    return StatementScreen(
      brand: true,
      hero: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(top.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                top.label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      title: content.reflection,
      extra: Column(
        children: [
          Text(
            'WHERE ${child.toUpperCase()} IS HEADED',
            style: AppText.overline
                .copyWith(color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 10),
          Text(
            '🎯 ${content.headline}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'You’re not alone — “fewer fights about the phone” is the most '
            'common thing parents tell us.',
            textAlign: TextAlign.center,
            style: AppText.body
                .copyWith(color: Colors.white.withValues(alpha: 0.82)),
          ),
        ],
      ),
      ctaLabel: 'Continue',
      onNext: onNext,
    );
  }
}

// ---------------------------------------------------------------------------
// S15–S17 — the empathy block
// ---------------------------------------------------------------------------

class VibeScreen extends StatelessWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const VibeScreen({super.key, required this.onNext, this.step, this.total});

  @override
  Widget build(BuildContext context) {
    return SingleChoiceScreen(
      step: step,
      total: total,
      title: 'How does learning time usually go right now?',
      options: [
        const OnbChoice('negotiation', '😤', 'It’s a daily negotiation'),
        const OnbChoice('givenup', '😔', 'Honestly, I’ve mostly given up'),
        OnbChoice('withme', '📖',
            '${Storage.childNameOr('They')}’ll do it — but only if I sit there'),
        const OnbChoice('fine', '✅', 'It’s fine — I just want more'),
      ],
      onPicked: (id) async {
        await Storage.setVibe(id);
        onNext();
      },
    );
  }
}

class TriedScreen extends StatelessWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const TriedScreen({super.key, required this.onNext, this.step, this.total});

  @override
  Widget build(BuildContext context) {
    return MultiChoiceScreen(
      step: step,
      total: total,
      title: 'What have you already tried?',
      subtitle: 'Choose any that apply.',
      options: const [
        OnbChoice('workbooks', '📓', 'Workbooks'),
        OnbChoice('apps', '📱', 'Learning apps',
            sub: 'They stopped opening them'),
        OnbChoice('tuition', '🏫', 'Tuition or coaching'),
        OnbChoice('limits', '⏱️', 'Screen time limits'),
        OnbChoice('takeaway', '🚫', 'Taking the phone away'),
        OnbChoice('nothing', '😮‍💨', 'Honestly — nothing has stuck'),
      ],
      onDone: (picked) async {
        await Storage.setTried(picked);
        onNext();
      },
    );
  }
}

/// S17 — the emotional peak: "that's exactly why we built Nupo."
class WhyBuiltScreen extends StatelessWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const WhyBuiltScreen(
      {super.key, required this.onNext, this.step, this.total});

  @override
  Widget build(BuildContext context) {
    final child = Storage.childNameOr();
    return StatementScreen(
      brand: true,
      hero: const HaloMascot('assets/mascot_opening.png', size: 140),
      title: 'That’s exactly why we built Nupo.',
      body:
          'Every one of those things asks $child to STOP doing what they want. '
          'So they resist. Every time.\n\n'
          'Nupo doesn’t ask them to stop. It just adds 90 seconds first — '
          'then hands them the thing they already wanted.\n\n'
          'That’s the whole trick. And it’s why it works.',
      ctaLabel: 'Continue',
      onNext: onNext,
    );
  }
}

// ---------------------------------------------------------------------------
// S18 — what does the child reach for? (pre-fills the app picker)
// ---------------------------------------------------------------------------

class ReachAppsScreen extends StatefulWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const ReachAppsScreen(
      {super.key, required this.onNext, this.step, this.total});

  @override
  State<ReachAppsScreen> createState() => _ReachAppsScreenState();
}

class _ReachAppsScreenState extends State<ReachAppsScreen> {
  final _picked = <String>{};

  Future<void> _done() async {
    await Storage.setReachApps(_picked.toList());
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return OnbScaffold(
      step: widget.step,
      total: widget.total,
      title: 'What does ${Storage.childNameOr()} reach for most?',
      subtitle: 'Choose any — we’ll set these up in a moment.',
      ctaLabel: _picked.isEmpty ? 'None of these' : 'Continue',
      onCta: _done,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
        children: [
          for (final p in kPresetGateableApps)
            _AppTile(
              name: p.name,
              package: p.package,
              selected: _picked.contains(p.package),
              onTap: () => setState(() {
                _picked.contains(p.package)
                    ? _picked.remove(p.package)
                    : _picked.add(p.package);
              }),
            ),
        ],
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  final String name;
  final String package;
  final bool selected;
  final VoidCallback onTap;
  const _AppTile({
    required this.name,
    required this.package,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF8F5FF) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.line,
          width: selected ? 2 : 1.5,
        ),
        boxShadow: AppColors.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppBrandIcon(package, size: 44),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.textDark, size: 15),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// S26–S27 — commitment ladder + validation
// ---------------------------------------------------------------------------

class CommitmentScreen extends StatelessWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const CommitmentScreen(
      {super.key, required this.onNext, this.step, this.total});

  @override
  Widget build(BuildContext context) {
    return SingleChoiceScreen(
      step: step,
      total: total,
      title:
          'How committed are you to making this happen for ${Storage.childNameOr()}?',
      options: const [
        OnbChoice('extreme', '🔥', 'Extremely committed'),
        OnbChoice('very', '💪', 'Very committed'),
        OnbChoice('somewhat', '🤔', 'Somewhat committed'),
        OnbChoice('little', '🌱', 'A little committed'),
        OnbChoice('exploring', '✨', 'Just exploring'),
      ],
      onPicked: (id) async {
        await Storage.setCommitment(id);
        onNext();
      },
    );
  }
}

class ValidationScreen extends StatelessWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const ValidationScreen(
      {super.key, required this.onNext, this.step, this.total});

  @override
  Widget build(BuildContext context) {
    return StatementScreen(
      brand: true,
      emoji: '👍',
      title: 'We love to see this.',
      body: 'Kids follow their parent’s lead — '
          '${Storage.childNameOr()}’s got a good one.',
      ctaLabel: 'Done',
      onNext: onNext,
    );
  }
}

// ---------------------------------------------------------------------------
// Permissions intro — frames the 4 switches as benefits before the deep links
// ---------------------------------------------------------------------------

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
    final child = Storage.childNameOr();
    final count = autostart ? 4 : 3;
    final rows = <(IconData, Color, Color, String)>[
      (
        Symbols.layers_rounded,
        AppColors.primary,
        AppColors.primarySoft,
        'Show $child their learning moment'
      ),
      (
        Symbols.visibility_rounded,
        AppColors.accentDeep,
        AppColors.accentSoft,
        'Know when a chosen app opens'
      ),
      (
        Symbols.bolt_rounded,
        AppColors.correct,
        AppColors.correctSoft,
        'Keep working in the background'
      ),
      if (autostart)
        (
          Symbols.rocket_launch_rounded,
          Color(0xFFE0642F),
          Color(0xFFFFEFE6),
          'Restart itself if the phone closes it'
        ),
    ];
    return OnbScaffold(
      step: step,
      total: total,
      title: 'One last thing — $count quick switches.',
      subtitle:
          'Android needs your OK for Nupo to do its job. Each one takes a few '
          'seconds, and we’ll bring you right back.',
      ctaLabel: 'Let’s do it',
      onCta: onNext,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: AppColors.cardDecoration(),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 22),
              Row(
                children: [
                  IconBadge(rows[i].$1,
                      size: 19, color: rows[i].$2, background: rows[i].$3),
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
    );
  }
}

// ---------------------------------------------------------------------------
// S34 — attribution
// ---------------------------------------------------------------------------

class AttributionScreen extends StatelessWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const AttributionScreen(
      {super.key, required this.onNext, this.step, this.total});

  @override
  Widget build(BuildContext context) {
    return SingleChoiceScreen(
      step: step,
      total: total,
      title: 'Where did you hear about us?',
      options: const [
        OnbChoice('youtube', '📺', 'YouTube'),
        OnbChoice('instagram', '📸', 'Instagram'),
        OnbChoice('tiktok', '🎵', 'TikTok'),
        OnbChoice('friends', '👨‍👩‍👧', 'Friends or family'),
        OnbChoice('playstore', '🛍️', 'Play Store search'),
        OnbChoice('other', '💬', 'Other'),
      ],
      onPicked: (id) async {
        await Storage.setAttribution(id);
        onNext();
      },
    );
  }
}

// ---------------------------------------------------------------------------
// S35 — why this works (the honest science screen; no fabricated stats)
// ---------------------------------------------------------------------------

class WhyItWorksScreen extends StatelessWidget {
  final VoidCallback onNext;
  final String ctaLabel;
  final int? step;
  final int? total;
  const WhyItWorksScreen({
    super.key,
    required this.onNext,
    this.ctaLabel = 'Finish setup',
    this.step,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    final child = Storage.childNameOr();
    return StatementScreen(
      step: step,
      total: total,
      emoji: '🥦',
      title: 'Why this works',
      body:
          'Nupo is built on one of the most reliable ideas in child psychology: '
          'put the thing they SHOULD do right before the thing they WANT to do.\n\n'
          'It’s the same reason “veggies before dessert” works — and it’s why '
          '$child won’t fight it the way they fight a workbook.',
      extra: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SeqChip(emoji: '📚', label: 'Learn', color: AppColors.accentSoft),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Icon(Icons.arrow_forward_rounded,
                color: Color(0xFFC9C2E8), size: 20),
          ),
          _SeqChip(emoji: '🎮', label: 'Play', color: AppColors.correctSoft),
        ],
      ),
      ctaLabel: ctaLabel,
      onNext: onNext,
    );
  }
}

class _SeqChip extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  const _SeqChip(
      {required this.emoji, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
