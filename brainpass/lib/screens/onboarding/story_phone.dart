// screens/onboarding/story_phone.dart — beats 5-7: the camera pushes into
// their phone, the app is tapped, Nupo's shield covers it, the question is
// answered, the app unlocks.
//
// ⚠️ This beat is the parent's mental model of the whole product, so it shows
// the REAL iOS loop, not the shorter Android one the design drew:
//
//     tap the app → Nupo's shield covers it → "Earn time" → Nupo opens
//     → questions → unlocked for 15 minutes
//
// The design's HTML goes straight from the tap to the question, which is what
// happens on Android (an accessibility-service overlay). On iOS the shield is
// a separate, unavoidable screen drawn by `NupoShieldConfig` in its own
// process, and "Earn time" is the button that foregrounds Nupo
// (`PROJECT_STATUS.md` §3.9). A parent taught the Android flow would meet an
// unexplained extra screen the first time it fires for real.
//
// The shield card below therefore mirrors `NupoShieldConfig`'s
// `ShieldConfiguration` field for field: the "Time to learn" title, the
// "Answer a few quick questions to earn time on <app>." subtitle, and the
// single "Earn time" primary button. If that Swift copy changes, change this.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets.dart';
import 'story_beats.dart';

/// Where the answer buttons come from. 7 × 8, exactly as the design.
const kStoryQuestion = '7 × 8 = ?';
const kStoryAnswers = <int>[54, 56, 48];
const kStoryCorrect = 56;

/// What Nupo says when the parent taps a wrong answer — the same "never
/// punish, just try again" rule the real quiz engine uses (`CLAUDE.md` §5).
const kWrongMoods = <(String, String, String)>[
  (Nupo.ohno, 'Not quite.', 'Try again.'),
  (Nupo.shrug, 'Hmm, nope.', 'Close! Have another go.'),
  (Nupo.tired, 'Still not it.', 'Take your time. Try again.'),
  (Nupo.sleep, 'Oh no…', "Nupo's waiting. One more try."),
];

class PhoneBeat extends StatelessWidget {
  /// Story position, in beats (see `story_screen.dart`).
  final double t;

  final String appName;

  /// How to refer to the child in the banner and the star. Their real name if
  /// onboarding already knows it, otherwise "They" — the name is asked after
  /// the story, and no copy here may imply the audience is children (2.3.8).
  final String childLabel;

  final bool shieldTapped;
  final bool answered;
  final int wrongs;
  final int? lastWrong;

  final VoidCallback onEarnTime;
  final ValueChanged<int> onAnswer;

  const PhoneBeat({
    super.key,
    required this.t,
    required this.appName,
    required this.childLabel,
    required this.shieldTapped,
    required this.answered,
    required this.wrongs,
    required this.lastWrong,
    required this.onEarnTime,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    // The camera push: the phone starts small and far, and fills the stage by
    // the time the tap lands.
    final zoom = c01((t - 4.35) / 0.85);
    final scale = lerpD(0.34, 1, zoom);
    final lift = lerpD(90, 0, zoom);

    final banner = c01((t - 5.05) / 0.35) * (1 - c01((t - 5.6) / 0.2));
    final up = easeInOut(c01((t - 5.75) / 0.55));
    final down = easeInOut(c01((t - 6.75) / 0.45));
    final ok = c01((t - 6.95) / 0.1) * (1 - c01((t - 7.2) / 0.15));
    final showUnlock = answered && t >= 6.85 && t <= 7.55;

    return LayoutBuilder(
      builder: (context, c) {
        final ph = c.maxHeight * 0.83;
        final pw = math.min(c.maxWidth * 0.85, ph * 0.472);

        return Center(
          child: Transform.translate(
            offset: Offset(0, lift),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: pw,
                height: ph,
                decoration: BoxDecoration(
                  color: deepen(AppColors.textDark, 0.72),
                  borderRadius: BorderRadius.circular(38),
                  border: Border.all(
                    color: deepen(AppColors.textDark, 0.88),
                    width: 9,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4 * zoom),
                      blurRadius: 70 * zoom,
                      offset: Offset(0, 30 * zoom),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    children: [
                      const Positioned.fill(child: _MockApp()),

                      // "<Name> just tapped YouTube. Watch ↓"
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 14,
                        child: Opacity(
                          opacity: banner,
                          child: Transform.translate(
                            offset: Offset(0, (1 - banner) * 20),
                            child: _Banner(
                              color: AppColors.primary,
                              child: Text(
                                '$childLabel just tapped $appName. Watch ↓',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // The shield, then the questions — the card that covers
                      // the app.
                      Positioned(
                        left: 10,
                        right: 10,
                        top: 10,
                        bottom: 10,
                        child: FractionalTranslation(
                          translation: Offset(0, (1 - up) * 1.04 + down * 1.04),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            switchInCurve: Curves.easeOutCubic,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween(
                                      begin: const Offset(0, 0.06),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                ),
                            child: shieldTapped
                                ? _QuizCard(
                                    key: const ValueKey('quiz'),
                                    appName: appName,
                                    answered: answered,
                                    wrongs: wrongs,
                                    lastWrong: lastWrong,
                                    onAnswer: onAnswer,
                                  )
                                : _ShieldCard(
                                    key: const ValueKey('shield'),
                                    appName: appName,
                                    onEarnTime: onEarnTime,
                                  ),
                          ),
                        ),
                      ),

                      // The app, running, with time on the clock.
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Opacity(
                          opacity: ok,
                          child: Transform.translate(
                            offset: Offset(0, (1 - ok) * 26),
                            child: _Banner(
                              color: AppColors.correct,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              radius: 20,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$appName is open for 15 minutes.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Then Nupo asks again.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(
                                        alpha: 0.75,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // The payoff.
                      Positioned.fill(
                        child: IgnorePointer(
                          child: _UnlockOverlay(
                            visible: showUnlock,
                            appName: appName,
                            childLabel: childLabel,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// The app behind the shield. Deliberately generic — a mock must not imitate
// any real app's UI beyond its brand colour.
// ---------------------------------------------------------------------------

class _MockApp extends StatelessWidget {
  const _MockApp();

  @override
  Widget build(BuildContext context) {
    final chrome = deepen(AppColors.textDark, 0.55);
    final line = deepen(AppColors.textDark, 0.35);

    return ColoredBox(
      color: deepen(AppColors.textDark, 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 44,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.wrong,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                for (final width in [0.58, 0.70, 0.44, 0.64])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 66,
                          height: 44,
                          decoration: BoxDecoration(
                            color: chrome,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: line,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 6),
                              FractionallySizedBox(
                                widthFactor: width,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: chrome,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

class _Banner extends StatelessWidget {
  final Color color;
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  const _Banner({
    required this.color,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    this.radius = 14,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: child,
  );
}

// ---------------------------------------------------------------------------
// The shield — what iOS actually draws over a gated app.
// ---------------------------------------------------------------------------

class _ShieldCard extends StatelessWidget {
  final String appName;
  final VoidCallback onEarnTime;

  const _ShieldCard({
    super.key,
    required this.appName,
    required this.onEarnTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // `NupoShieldConfig` paints #F7F5FF behind a thin material blur; this
        // is the same near-white lilac, from the token set.
        color: Color.lerp(Colors.white, AppColors.primarySoft, 0.6),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const IconBadge(
            Icons.lock_rounded,
            size: 62,
            color: AppColors.primary,
            background: AppColors.primarySoft,
          ),
          const SizedBox(height: 18),
          const Text(
            'Time to learn',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Answer a few quick questions to earn time on $appName.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              height: 1.45,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(label: 'Start', onPressed: onEarnTime),
          ),
          const SizedBox(height: 14),
          const Text(
            'This is what your kid sees.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The questions — Nupo, now in the foreground.
// ---------------------------------------------------------------------------

class _QuizCard extends StatelessWidget {
  final String appName;
  final bool answered;
  final int wrongs;
  final int? lastWrong;
  final ValueChanged<int> onAnswer;

  const _QuizCard({
    super.key,
    required this.appName,
    required this.answered,
    required this.wrongs,
    required this.lastWrong,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final mood = (lastWrong != null && wrongs > 0)
        ? kWrongMoods[(wrongs - 1) % kWrongMoods.length]
        : null;

    final owl = answered
        ? Nupo.idea
        : mood != null
        ? mood.$1
        : Nupo.teacher;
    final ask = answered
        ? 'Nailed it!'
        : mood != null
        ? mood.$2
        : 'Quick one first!';
    final hint = answered
        ? 'Unlocking $appName…'
        : mood != null
        ? mood.$3
        : 'Tap the answer.';
    final hintColor = answered
        ? AppColors.accent
        : mood != null
        ? Colors.white
        : Colors.white.withValues(alpha: 0.6);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primaryBright, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(owl, width: 76, semanticLabel: 'Nupo'),
          const SizedBox(height: 6),
          Text(
            ask,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == 0
                          ? AppColors.accent
                          : Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 74,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              kStoryQuestion,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final value in kStoryAnswers) ...[
                Expanded(
                  child: _AnswerButton(
                    value: value,
                    correct: answered && value == kStoryCorrect,
                    wrong: !answered && lastWrong == value,
                    faded: answered && value != kStoryCorrect,
                    onTap: () => onAnswer(value),
                  ),
                ),
                if (value != kStoryAnswers.last) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: hintColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final int value;
  final bool correct;
  final bool wrong;
  final bool faded;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.value,
    required this.correct,
    required this.wrong,
    required this.faded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 56,
        alignment: Alignment.center,
        transform: Matrix4.translationValues(0, correct ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: correct
              ? AppColors.accent
              : wrong
              ? Color.lerp(Colors.white, AppColors.wrong, 0.28)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: correct
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.45),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Opacity(
          opacity: faded ? 0.45 : 1,
          child: Text(
            '$value',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The unlock celebration.
// ---------------------------------------------------------------------------

class _UnlockOverlay extends StatefulWidget {
  final bool visible;
  final String appName;
  final String childLabel;

  const _UnlockOverlay({
    required this.visible,
    required this.appName,
    required this.childLabel,
  });

  @override
  State<_UnlockOverlay> createState() => _UnlockOverlayState();
}

class _UnlockOverlayState extends State<_UnlockOverlay>
    with TickerProviderStateMixin {
  late final _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final _fall = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.visible) _play();
  }

  @override
  void didUpdateWidget(_UnlockOverlay old) {
    super.didUpdateWidget(old);
    if (widget.visible && !old.visible) _play();
    if (!widget.visible && old.visible) _fall.stop();
  }

  void _play() {
    _enter.forward(from: 0);
    _fall.repeat();
  }

  @override
  void dispose() {
    _enter.dispose();
    _fall.dispose();
    super.dispose();
  }

  /// A staggered slice of the entrance: 1 once `start`..`start+length` has run.
  double _at(double start, double length) =>
      c01((_enter.value * 1.8 - start) / length);

  @override
  Widget build(BuildContext context) {
    final star = widget.childLabel == 'They'
        ? '+1 star earned'
        : '+1 star for ${widget.childLabel}';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 220),
      opacity: widget.visible ? 1 : 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              deepen(AppColors.correct, 0.15),
              deepen(AppColors.correct, 0.42),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _enter,
          builder: (context, _) {
            final ring = _at(0, 0.55);
            final owl = _at(0.5, 0.5);
            final text = _at(0.66, 0.5);
            final chip = _at(0.92, 0.55);
            final hint = _at(1.25, 0.5);

            return Stack(
              children: [
                Positioned.fill(child: _Confetti(progress: _fall)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: lerpD(
                          0.3,
                          1,
                          Curves.easeOutBack.transform(ring.clamp(0.0, 1.0)),
                        ),
                        child: _TickRing(progress: _at(0.35, 0.45)),
                      ),
                      const SizedBox(height: 18),
                      _rise(
                        owl,
                        Image.asset(
                          Nupo.cheer,
                          width: 96,
                          semanticLabel: 'Nupo',
                        ),
                      ),
                      const SizedBox(height: 12),
                      _rise(
                        text,
                        Column(
                          children: [
                            Text(
                              '${widget.appName} is open for 15 minutes.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 25,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Then Nupo asks again.',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Transform.scale(
                        scale: lerpD(
                          0.25,
                          1,
                          Curves.easeOutBack.transform(chip.clamp(0.0, 1.0)),
                        ),
                        child: Opacity(
                          opacity: chip,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 17,
                                  color: AppColors.accent,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  star,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 30,
                  child: Opacity(opacity: hint, child: const _ScrollOnHint()),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _rise(double p, Widget child) => Opacity(
    opacity: p,
    child: Transform.translate(offset: Offset(0, (1 - p) * 18), child: child),
  );
}

class _ScrollOnHint extends StatelessWidget {
  const _ScrollOnHint();

  @override
  Widget build(BuildContext context) => Text(
    'KEEP SCROLLING ↓',
    textAlign: TextAlign.center,
    style: TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.5,
      color: Colors.white.withValues(alpha: 0.55),
    ),
  );
}

/// The ring with the tick drawing itself inside it.
class _TickRing extends StatelessWidget {
  final double progress;
  const _TickRing({required this.progress});

  @override
  Widget build(BuildContext context) => Container(
    width: 120,
    height: 120,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: 0.14),
    ),
    child: Container(
      width: 88,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.2),
      ),
      child: CustomPaint(
        size: const Size(46, 46),
        painter: _TickPainter(progress),
      ),
    ),
  );
}

class _TickPainter extends CustomPainter {
  final double progress;
  const _TickPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final path = Path()
      ..moveTo(11, 24.5)
      ..lineTo(20, 33)
      ..lineTo(35, 15);

    var drawn = Path();
    for (final metric in path.computeMetrics()) {
      drawn = Path.combine(
        PathOperation.union,
        drawn,
        metric.extractPath(0, metric.length * progress),
      );
    }
    canvas.drawPath(
      drawn,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_TickPainter old) => old.progress != progress;
}

class _Confetti extends StatelessWidget {
  final Animation<double> progress;
  const _Confetti({required this.progress});

  // x fraction, top, width, height, round?, colour index, delay
  static const _pieces = <(double, double, double, double, bool, int, double)>[
    (0.14, 80, 8, 12, false, 0, 0.0),
    (0.34, 60, 8, 8, true, 1, 0.4),
    (0.58, 74, 9, 13, false, 2, 0.8),
    (0.78, 56, 8, 8, true, 0, 1.2),
    (0.46, 96, 7, 11, false, 1, 1.6),
  ];

  @override
  Widget build(BuildContext context) {
    final colours = [AppColors.accent, Colors.white, AppColors.primarySoft];

    return LayoutBuilder(
      builder: (context, c) => AnimatedBuilder(
        animation: progress,
        builder: (context, _) => Stack(
          children: [
            for (final (x, top, w, h, round, colour, delay) in _pieces)
              _piece(c, colours[colour], x, top, w, h, round, delay),
          ],
        ),
      ),
    );
  }

  Widget _piece(
    BoxConstraints c,
    Color colour,
    double x,
    double top,
    double w,
    double h,
    bool round,
    double delay,
  ) {
    // Each piece runs the same 2.4s fall, offset by its own delay.
    final p = ((progress.value + 1 - delay / 2.4) % 1.0);
    final opacity = p < 0.2 ? p / 0.2 : 1 - c01((p - 0.2) / 0.8);

    return Positioned(
      left: c.maxWidth * x,
      top: top + p * 190 - 10,
      child: Opacity(
        opacity: c01(opacity),
        child: Transform.rotate(
          angle: p * 220 * math.pi / 180,
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: colour,
              borderRadius: BorderRadius.circular(round ? w / 2 : 2),
            ),
          ),
        ),
      ),
    );
  }
}
