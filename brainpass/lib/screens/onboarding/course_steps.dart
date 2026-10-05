// screens/onboarding/course_steps.dart — the steps after sign-in that turn the
// story's demo into this child's plan:
//
//   Name → Buddy → What they'll learn → How Nupo teaches → Their path
//   … apps … → The trade (minutes per lesson, daily limit) … PIN, permissions …
//   → Ready
//
// Parent-facing copy is about outcomes, never unit titles. Every number shown
// is either counted from the course (48 lessons, 324 questions) or arithmetic
// on the parent's own settings (the trade screen).

import 'package:flutter/material.dart';

import '../../engine.dart';
import '../../safe_apps.dart';
import '../../storage.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'demo_lessons.dart';
import 'onb_kit.dart';

/// Colours for the four outcome rows / chapters.
const _rowColors = [AppColors.primary, AppColors.done, AppColors.accentDeep, AppColors.wrong];

DemoCourse get _course => demoFor(Storage.ageBand);
String get _child => Storage.childNameOr('your child');

// ---------------------------------------------------------------------------
// Name
// ---------------------------------------------------------------------------

class ChildNameStep extends StatefulWidget {
  final double progress;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  const ChildNameStep({super.key, required this.progress, this.onBack, required this.onNext});

  @override
  State<ChildNameStep> createState() => _ChildNameStepState();
}

class _ChildNameStepState extends State<ChildNameStep> {
  late final _c = TextEditingController(text: Storage.childName);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _c.text.trim();
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return OnbPage(
      top: StepChrome(progress: widget.progress, onBack: widget.onBack),
      cross: CrossAxisAlignment.center,
      bottom: [
        ChunkyButton(
          label: 'Continue',
          onPressed: name.isEmpty
              ? null
              : () async {
                  await Storage.setChildName(name);
                  widget.onNext();
                },
        ),
      ],
      content: [
        Chip2('${_course.name} · ${_course.ages}', background: Colors.white),
        if (!keyboard) ...[
          const SizedBox(height: 18),
          SizedBox(
            width: 210,
            height: 180,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(child: Image.asset(Nupo.starStudent, width: 170, semanticLabel: 'Nupo')),
                if (name.isNotEmpty)
                  Positioned(
                    right: 0,
                    bottom: 12,
                    child: Transform.rotate(
                      angle: -0.1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(12)),
                        child: Text(
                          'Hi, $name!',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textDark),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 18),
        const Text('What’s your child’s name?', textAlign: TextAlign.center, style: OnbText.title),
        const SizedBox(height: 18),
        _BigField(controller: _c, hint: 'Their name', onChanged: (_) => setState(() {})),
        const Spacer(),
      ],
    );
  }
}

class _BigField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color accent;
  final ValueChanged<String>? onChanged;
  const _BigField({
    required this.controller,
    required this.hint,
    this.accent = AppColors.primary,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder b(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: c, width: 2.5),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.words,
      cursorColor: accent,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        enabledBorder: b(accent.withValues(alpha: 0.5)),
        focusedBorder: b(accent),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buddy
// ---------------------------------------------------------------------------

class BuddyStep extends StatefulWidget {
  final double progress;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  const BuddyStep({super.key, required this.progress, this.onBack, required this.onNext});

  @override
  State<BuddyStep> createState() => _BuddyStepState();
}

class _BuddyStepState extends State<BuddyStep> {
  late final _c = TextEditingController(text: Storage.owlName);
  static const _ideas = ['Nupo', 'Hoot', 'Ziggy', 'Pip'];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    return OnbPage(
      background: AppColors.accentSoft,
      top: StepChrome(progress: widget.progress, onBack: widget.onBack),
      cross: CrossAxisAlignment.center,
      bottom: [
        ChunkyButton(
          label: 'That’s the one',
          tone: Chunky.amber,
          onPressed: () async {
            final v = _c.text.trim();
            await Storage.setOwlName(v.isEmpty ? 'Nupo' : v);
            widget.onNext();
          },
        ),
      ],
      content: [
        if (!keyboard) Image.asset(Nupo.cool, width: 190, semanticLabel: 'Nupo in sunglasses'),
        const SizedBox(height: 12),
        Text('Name $_child’s buddy', textAlign: TextAlign.center, style: OnbText.title),
        const SizedBox(height: 18),
        _BigField(
          controller: _c,
          hint: 'Nupo',
          accent: AppColors.accentDeep,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final n in _ideas)
              GestureDetector(
                onTap: () => setState(() => _c.text = n),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _c.text.trim() == n ? tint(AppColors.accent, 0.3) : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _c.text.trim() == n ? AppColors.accent : const Color(0xFFECE6F8),
                      width: 1.5,
                    ),
                  ),
                  child: Text(n, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
        const Spacer(),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// What they'll learn
// ---------------------------------------------------------------------------

class OutcomesStep extends StatelessWidget {
  final double progress;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  const OutcomesStep({super.key, required this.progress, this.onBack, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final c = _course;
    return OnbPage(
      top: StepChrome(progress: progress, onBack: onBack),
      bottom: [ChunkyButton(label: 'Continue', onPressed: onNext)],
      content: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(colors: [AppColors.primaryBright, AppColors.primaryDeep]),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_child.toUpperCase()}’S COURSE',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.6, color: AppColors.accent),
                    ),
                    const SizedBox(height: 3),
                    Text(c.name, style: const TextStyle(fontSize: 22, height: 1.1, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 3),
                    Text(
                      '${c.lessons} lessons · ages ${c.ages}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
              Image.asset(Nupo.focused, width: 70),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('$_child will be able to:', style: OnbText.titleSm),
        const SizedBox(height: 14),
        for (var i = 0; i < c.outcomes.length; i++) ...[
          _OutcomeRow(outcome: c.outcomes[i], color: _rowColors[i]),
          const SizedBox(height: 9),
        ],
        const Spacer(),
      ],
    );
  }
}

class _OutcomeRow extends StatelessWidget {
  final Outcome outcome;
  final Color color;
  const _OutcomeRow({required this.outcome, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(9, 9, 12, 9),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: AppColors.textDark.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: tint(color, 0.14), borderRadius: BorderRadius.circular(15)),
          child: Icon(outcome.icon, color: color, size: 26),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(outcome.title, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900)),
              const SizedBox(height: 1),
              Text(outcome.line, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// How Nupo teaches
// ---------------------------------------------------------------------------

class HowItTeachesStep extends StatelessWidget {
  final double progress;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  const HowItTeachesStep({super.key, required this.progress, this.onBack, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return OnbPage(
      top: StepChrome(progress: progress, onBack: onBack),
      bottom: [ChunkyButton(label: 'Continue', onPressed: onNext)],
      content: [
        const Text('How Nupo teaches', style: OnbText.titleSm),
        const SizedBox(height: 18),
        _HowCard(
          tintColor: AppColors.primary,
          art: Container(
            width: 76,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 40, height: 6, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(3))),
                const SizedBox(height: 5),
                Container(height: 24, decoration: BoxDecoration(color: kLilac, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 5),
                Container(height: 11, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(5))),
              ],
            ),
          ),
          title: 'Learn, then practise',
          line: 'One idea, then questions.',
        ),
        const SizedBox(height: 12),
        const _HowCard(
          tintColor: AppColors.wrong,
          art: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.replay_rounded, size: 64, color: AppColors.wrong),
              Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text('?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.wrong)),
              ),
            ],
          ),
          title: 'Mistakes come back',
          line: 'Until they stick.',
        ),
        const SizedBox(height: 12),
        _HowCard(
          tintColor: AppColors.accent,
          art: Image.asset(Nupo.trophy, width: 80),
          title: 'Boss levels',
          line: 'One to finish every unit.',
        ),
        const Spacer(),
      ],
    );
  }
}

class _HowCard extends StatelessWidget {
  final Color tintColor;
  final Widget art;
  final String title;
  final String line;
  const _HowCard({required this.tintColor, required this.art, required this.title, required this.line});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
    child: Row(
      children: [
        Container(
          width: 104,
          height: 98,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: tint(tintColor, 0.14), borderRadius: BorderRadius.circular(16)),
          child: art,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 17, height: 1.2, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(line, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Their path
// ---------------------------------------------------------------------------

class PathStep extends StatelessWidget {
  final double progress;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  const PathStep({super.key, required this.progress, this.onBack, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final c = _course;
    return OnbPage(
      background: AppColors.primary,
      top: StepChrome(progress: progress, onBack: onBack, onBrand: true),
      bottom: [ChunkyButton(label: 'Set up $_child’s course', tone: Chunky.amber, onPressed: onNext)],
      content: [
        Text(c.name.toUpperCase(), style: OnbText.eyebrow.copyWith(color: AppColors.accent)),
        const SizedBox(height: 6),
        Text('$_child’s path', style: OnbText.titleSm.copyWith(color: Colors.white)),
        const SizedBox(height: 18),
        SizedBox(height: 360, child: _PathMap(labels: c.path)),
        const Spacer(),
      ],
    );
  }
}

/// A winding path of four milestones, bottom to top, Nupo at the start.
class _PathMap extends StatelessWidget {
  final List<String> labels;
  const _PathMap({required this.labels});

  // Node centres on a 340-tall map, bottom first.
  static const _nodes = [Offset(92, 314), Offset(132, 224), Offset(92, 134), Offset(132, 44)];

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned.fill(child: CustomPaint(painter: _PathPainter(_nodes))),
        for (var i = 0; i < 4; i++)
          Positioned(
            left: _nodes[i].dx - (i == 0 ? 22 : 19),
            top: _nodes[i].dy - (i == 0 ? 22 : 19),
            child: Container(
              width: i == 0 ? 44 : 38,
              height: i == 0 ? 44 : 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == 0 ? AppColors.accent : Colors.white,
              ),
              child: i == 0
                  ? const Icon(Icons.star_rounded, color: AppColors.textDark, size: 24)
                  : Text('${i + 1}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.primary)),
            ),
          ),
        for (var i = 0; i < 4; i++)
          Positioned(
            left: _nodes[i].dx + 34,
            top: _nodes[i].dy - 20,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  i == 0 ? 'STARTS TODAY' : 'WEEK ${i + 1}',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.4, color: AppColors.accent),
                ),
                Text(labels[i], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
              ],
            ),
          ),
        Positioned(left: -6, bottom: -10, child: Image.asset(Nupo.cool, width: 82)),
      ],
    );
  }
}

class _PathPainter extends CustomPainter {
  final List<Offset> n;
  const _PathPainter(this.n);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()..moveTo(n[0].dx, n[0].dy);
    for (var i = 1; i < n.length; i++) {
      final a = n[i - 1], b = n[i];
      final midY = (a.dy + b.dy) / 2;
      p.cubicTo(a.dx, midY, b.dx, midY, b.dx, b.dy);
    }
    canvas.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.22),
    );
    final dot = Paint()..color = AppColors.accent;
    for (final m in p.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 12) {
        canvas.drawCircle(m.getTangentForOffset(d)!.position, 2.3, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_PathPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// The trade — minutes per lesson, daily limit, and what they add up to
// ---------------------------------------------------------------------------

class TradeStep extends StatefulWidget {
  final double progress;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  const TradeStep({super.key, required this.progress, this.onBack, required this.onNext});

  @override
  State<TradeStep> createState() => _TradeStepState();
}

class _TradeStepState extends State<TradeStep> {
  late int _minutes;
  late int _limit;

  @override
  void initState() {
    super.initState();
    final apps = Storage.gatedApps;
    final rule = apps.isEmpty ? const AppRule() : Storage.ruleFor(apps.first);
    _minutes = rule.minutes;
    _limit = rule.cap > 0 ? rule.cap : 60;
  }

  int get _perDay => (_limit ~/ _minutes).clamp(1, 99);

  /// Days to finish the course at this pace, on one app, with the default
  /// questions per learning moment. Arithmetic, not a promise.
  String get _finish {
    const questionsPerLesson = 3;
    final days = (_course.questions / (questionsPerLesson * _perDay)).ceil();
    if (days <= 13) return '~$days days';
    if (days <= 24) return '~${(days / 7).round()} wks';
    final months = (days / 30).round().clamp(1, 99);
    return '~$months mo';
  }

  String _fmt(int m) => m < 60 ? '$m min' : (m % 60 == 0 ? '${m ~/ 60} hr' : '${m ~/ 60} hr ${m % 60}');

  Future<void> _save() async {
    final rules = Storage.appRules;
    for (final pkg in Storage.gatedApps) {
      rules[pkg] = (rules[pkg] ?? const AppRule()).copyWith(minutes: _minutes, cap: _limit);
    }
    await Storage.setAppRules(rules);
    await Engine.setRules(Storage.rulesForEngine());
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return OnbPage(
      top: StepChrome(progress: widget.progress, onBack: widget.onBack),
      bottom: [ChunkyButton(label: 'Continue', onPressed: _save)],
      content: [
        const Text('Set the trade', style: OnbText.titleSm),
        const SizedBox(height: 6),
        const Text('Change it any time.', style: OnbText.sub),
        const SizedBox(height: 20),
        _Stepper(
          title: 'Each lesson earns',
          sub: 'of play',
          value: _fmt(_minutes),
          onMinus: _minutes > 5 ? () => setState(() => _minutes -= 5) : null,
          onPlus: _minutes < 60 ? () => setState(() => _minutes += 5) : null,
        ),
        const SizedBox(height: 10),
        _Stepper(
          title: 'Daily limit',
          sub: 'per app, then done for today',
          value: _fmt(_limit),
          onMinus: _limit > 15 && _limit - 15 >= _minutes ? () => setState(() => _limit -= 15) : null,
          onPlus: _limit < 240 ? () => setState(() => _limit += 15) : null,
        ),
        const SizedBox(height: 24),
        Text('THAT ADDS UP TO', style: OnbText.eyebrow.copyWith(color: AppColors.accentDeep)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(color: tint(AppColors.accent, 0.18), borderRadius: BorderRadius.circular(20)),
          child: IntrinsicHeight(
            child: Row(
              children: [
                _Sum('$_perDay', 'lessons a day'),
                const VerticalDivider(color: Color(0x2E8A6100), width: 1),
                _Sum(_fmt(_perDay * _minutes), 'of play, earned'),
                const VerticalDivider(color: Color(0x2E8A6100), width: 1),
                _Sum(_finish, 'to finish the course'),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  final String title, sub, value;
  final VoidCallback? onMinus, onPlus;
  const _Stepper({required this.title, required this.sub, required this.value, this.onMinus, this.onPlus});

  @override
  Widget build(BuildContext context) {
    Widget round(IconData icon, VoidCallback? onTap) => GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(shape: BoxShape.circle, color: onTap == null ? const Color(0xFFF1EDF8) : kLilac),
        child: Icon(icon, size: 20, color: onTap == null ? const Color(0xFFB9B2C9) : AppColors.primary),
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                Text(sub, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
              ],
            ),
          ),
          round(Icons.remove_rounded, onMinus),
          SizedBox(
            width: 66,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900, fontFeatures: [FontFeature.tabularFigures()]),
            ),
          ),
          round(Icons.add_rounded, onPlus),
        ],
      ),
    );
  }
}

class _Sum extends StatelessWidget {
  final String big, small;
  const _Sum(this.big, this.small);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(big, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: AppColors.accentDeep)),
        const SizedBox(height: 2),
        Text(
          small,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, height: 1.2, fontWeight: FontWeight.w800, color: AppColors.accentDeep.withValues(alpha: 0.85)),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Ready
// ---------------------------------------------------------------------------

class ReadyStep extends StatelessWidget {
  final VoidCallback onDone;
  const ReadyStep({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final c = _course;
    final apps = Storage.gatedApps;
    final first = apps.isEmpty ? 'their apps' : _appName(apps.first);
    final rule = apps.isEmpty ? const AppRule() : Storage.ruleFor(apps.first);
    final limit = rule.cap <= 0 ? 'no limit' : (rule.cap % 60 == 0 ? '${rule.cap ~/ 60} hr a day' : '${rule.cap} min a day');
    return OnbPage(
      background: AppColors.primary,
      cross: CrossAxisAlignment.center,
      bottom: [ChunkyButton(label: 'Go to dashboard', tone: Chunky.amber, onPressed: onDone)],
      content: [
        const Spacer(),
        Image.asset(Nupo.trophy, width: 170, semanticLabel: 'Nupo with a trophy'),
        const SizedBox(height: 10),
        Text('$_child’s course is ready.', textAlign: TextAlign.center, style: OnbText.title.copyWith(color: Colors.white)),
        const SizedBox(height: 8),
        Text(
          'Lesson 1 starts the next time they open $first.',
          textAlign: TextAlign.center,
          style: OnbText.sub.copyWith(color: Colors.white.withValues(alpha: 0.82)),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
          child: Column(
            children: [
              Row(
                children: [
                  Text(c.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  const Spacer(),
                  Text('0 / ${c.lessons}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final p in apps.take(5)) ...[AppBrandIcon(p, size: 30), const SizedBox(width: 6)],
                  const Spacer(),
                  Text(
                    '${rule.minutes} min · $limit',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
    );
  }
}

String _appName(String pkg) {
  for (final a in kStoryApps) {
    if (a.bundleId == pkg) return a.name;
  }
  return displayNameFor(pkg);
}
