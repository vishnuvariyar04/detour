// screens/onboarding/story_beats.dart — the individual frames of the scroll
// story, plus the maths the scroll rig and the beats share.
//
// Source of truth for the design: `ui-ux/design/Nupo Onboarding Story.dc.html`,
// treatment **1a** ("Cinematic"), and its scroll engine `support.js`. The
// timings, easings and the bird's flight path are that engine's own numbers,
// kept verbatim so the beats stay in lockstep with it.
//
// Two deliberate departures from the HTML, both required by `CLAUDE.md`:
//
//   * **Palette.** The design paints its own hexes (cream #FFFCEF, purple
//     #7C3AED, ink #241C3B, amber #F9C13C, green #17976A). §8 says the app has
//     ONE palette and these are not it, so every colour here resolves to an
//     `AppColors` token — or is derived from one by `Color.lerp`, never a new
//     literal. The cinematic staging survives; the cream stage reads lilac.
//   * **Type.** The design names Baloo 2 / Figtree. §8 pins Nunito, so the
//     weights and sizes are carried over and the family is not.
//
// See `story_screen.dart` for the scroll rig that drives all of this, and
// `story_phone.dart` for the phone scene (beats 5-7).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets.dart';

// ---------------------------------------------------------------------------
// Shared maths — `support.js`'s `clamp` / `lerp` / its ease-in-out cubic.
// ---------------------------------------------------------------------------

double c01(double v) => v.isNaN ? 0 : v.clamp(0.0, 1.0);

double lerpD(double a, double b, double p) => a + (b - a) * p;

/// The engine's `raw<.5 ? 2*raw*raw : 1-pow(-2*raw+2,2)/2`.
double easeInOut(double p) =>
    p < 0.5 ? 2 * p * p : 1 - math.pow(-2 * p + 2, 2) / 2;

/// A shade of a token, darkened towards black. Used where the design wants a
/// deeper version of a brand colour (the phone body, the unlock gradient's
/// bottom) — deriving it keeps the palette single-sourced instead of
/// introducing a second set of hexes.
Color deepen(Color base, double amount) =>
    Color.lerp(base, Colors.black, amount)!;

// ---------------------------------------------------------------------------
// Assets — the mascot poses, cut from the design's sprite sheets.
// ---------------------------------------------------------------------------

class Nupo {
  static const _dir = 'assets/nupo';

  static const wave = '$_dir/wave.png';
  static const waveBody = '$_dir/wave-body.png';
  static const waveWing = '$_dir/wave-wing.png';
  static const roomBoy = '$_dir/room-boy.png';
  static const idea = '$_dir/idea.png';
  static const phone = '$_dir/phone.png';
  static const teacher = '$_dir/teacher.png';
  static const cheer = '$_dir/cheer.png';
  static const aplus = '$_dir/aplus.png';
  static const ohno = '$_dir/ohno.png';
  static const shrug = '$_dir/shrug.png';
  static const tired = '$_dir/tired.png';
  static const sleep = '$_dir/sleep.png';
  static const fly1 = '$_dir/fly1.png';
  static const fly2 = '$_dir/fly2.png';
  static const fly3 = '$_dir/fly3.png';

  // Added with the Setup Flow design (2a) — the poses its tapped steps use.
  static const cool = '$_dir/cool.png';
  static const starStudent = '$_dir/star-student.png';
  static const medal = '$_dir/medal.png';
  static const trophy = '$_dir/trophy.png';
  static const aplus2 = '$_dir/aplus2.png';
  static const focused = '$_dir/focused.png';
  static const meditate = '$_dir/meditate.png';
  static const takeBreak = '$_dir/break.png';

  /// Everything the story can show, for `precacheImage` — the bird swaps pose
  /// mid-scroll, and an uncached swap flickers.
  static const all = <String>[
    wave,
    waveBody,
    waveWing,
    roomBoy,
    idea,
    phone,
    teacher,
    cheer,
    aplus,
    ohno,
    shrug,
    tired,
    sleep,
    fly1,
    fly2,
    fly3,
    cool,
    starStudent,
    medal,
    trophy,
    aplus2,
    focused,
    meditate,
    takeBreak,
  ];
}

// ---------------------------------------------------------------------------
// Progress — a star travelling the length of the flow.
// ---------------------------------------------------------------------------

/// Shared by the scrolled story and the tapped steps that follow it.
///
/// The two halves of onboarding are different interactions — one scrolls, one
/// taps — but they are one journey, and a parent should not be able to tell
/// where the handover happened. Before this existed, the story's amber star
/// gave way to Material progress dots in an app bar the moment the CTA was
/// tapped, which read as landing in a different app.
class StoryProgressBar extends StatelessWidget {
  /// 0 → 1.
  final double progress;

  /// Inverts the track for the beats that run over a dark stage.
  final bool onDark;

  const StoryProgressBar({
    super.key,
    required this.progress,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = c01(progress);

    return LayoutBuilder(
      builder: (context, c) => SizedBox(
        height: 6,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: onDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.textDark.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const SizedBox(width: double.infinity, height: 6),
            ),
            FractionallySizedBox(
              widthFactor: p,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Positioned(
              left: c.maxWidth * p - 11,
              top: -8,
              child: Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textDark.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Transform.rotate(
                  angle: p * 6.2832,
                  child: const Icon(Icons.star_rounded,
                      size: 13, color: AppColors.accentDeep),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The three apps offered in beat 5.
// ---------------------------------------------------------------------------

/// One row of the story's app picker. `bundleId` is a real preset id from
/// `safe_apps.dart`, so `AppBrandIcon` finds the brand glyph and the host can
/// pre-select the same app for the real picker after the paywall.
///
/// ANDROID: the ids are Android package names, not the iOS bundle ids the
/// design shipped with — `AppBrandIcon` and `safe_apps.dart` both key off
/// these, so using Apple's would lose the icon and the pre-tick.
class StoryApp {
  final String name;
  final String bundleId;
  const StoryApp(this.name, this.bundleId);
}

const kStoryApps = <StoryApp>[
  StoryApp('YouTube', 'com.google.android.youtube'),
  StoryApp('Roblox', 'com.roblox.client'),
  StoryApp('TikTok', 'com.zhiliaoapp.musically'),
];

// ---------------------------------------------------------------------------
// Beat 1 — "They grab the phone the second they're bored."
// ---------------------------------------------------------------------------

class BoredBeat extends StatelessWidget {
  final double t;
  const BoredBeat({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    // The room slides up into place over the first half-beat (`support.js`
    // gives it its own parallax so it lags the type).
    final settle = c01((t - 0.5) / 0.5);
    // "KEEP SCROLLING" is only useful until they actually do.
    final hint = c01(1 - (t - 1) * 4);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, AppColors.primarySoft],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: -26,
            child: Transform.translate(
              offset: Offset(0, (1 - settle) * 60),
              child: Image.asset(
                Nupo.roomBoy,
                fit: BoxFit.contain,
                semanticLabel:
                    'A boy on his bed, phone in hand, Nupo flying in',
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(30, top + 44, 30, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _Eyebrow('FOR PARENTS · AGES 5–12'),
                SizedBox(height: 12),
                Text(
                  "They grab the phone the second they're bored.",
                  style: TextStyle(
                    fontSize: 27,
                    height: 1.24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'You already know how this goes.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 26,
            child: Opacity(
              opacity: hint,
              child: const _ScrollHint(color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w800,
      color: AppColors.primary,
      letterSpacing: 1.7,
    ),
  );
}

class _ScrollHint extends StatelessWidget {
  final Color color;
  const _ScrollHint({required this.color});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'KEEP SCROLLING',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 1.5,
        ),
      ),
      Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: color),
    ],
  );
}

// ---------------------------------------------------------------------------
// Beat 2 — the question, full-bleed brand purple.
// ---------------------------------------------------------------------------

class EarnItBeat extends StatelessWidget {
  const EarnItBeat({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary,
      child: Stack(
        children: [
          const Positioned.fill(child: _FloatingGlyphs()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Center(
              child: Text(
                'What if they had to earn it — with 30 seconds of learning?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  height: 1.24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The faint schoolwork drifting behind beat 2 — 7×8, A B C, ½, ?, ★.
class _FloatingGlyphs extends StatefulWidget {
  const _FloatingGlyphs();

  @override
  State<_FloatingGlyphs> createState() => _FloatingGlyphsState();
}

class _FloatingGlyphsState extends State<_FloatingGlyphs>
    with SingleTickerProviderStateMixin {
  late final _bob = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  // glyph, x fraction, y fraction, size, phase
  static const _items = <(String, double, double, double, double)>[
    ('7×8', 0.05, 0.13, 38, 0.0),
    ('A B C', 0.70, 0.22, 28, 0.2),
    ('½', 0.09, 0.72, 32, 0.45),
    ('?', 0.82, 0.82, 34, 0.65),
    ('★', 0.47, 0.91, 24, 0.85),
  ];

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => AnimatedBuilder(
        animation: _bob,
        builder: (context, _) => Stack(
          children: [
            for (final (glyph, x, y, size, phase) in _items)
              Positioned(
                left: c.maxWidth * x,
                top:
                    c.maxHeight * y +
                    math.sin((_bob.value + phase) * 2 * math.pi) * 7,
                child: Text(
                  glyph,
                  style: TextStyle(
                    fontSize: size,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Beat 3 — "That's Nupo."
// ---------------------------------------------------------------------------

class ThatsNupoBeat extends StatelessWidget {
  const ThatsNupoBeat({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppColors.bgDecoration(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "That's Nupo.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                letterSpacing: -0.6,
              ),
            ),
            SizedBox(height: 14),
            SizedBox(
              width: 290,
              child: Text(
                'A couple of quick questions before their favourite apps open. '
                "That's the whole thing.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Beat 4 — the app picker. The story will not scroll past this until the
// parent picks one; the choice then names the app for the rest of the story.
// ---------------------------------------------------------------------------

class PickerBeat extends StatelessWidget {
  final StoryApp? picked;
  final ValueChanged<StoryApp> onPick;
  const PickerBeat({super.key, required this.picked, required this.onPick});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final chosen = picked;

    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.primarySoft),
      child: Stack(
        children: [
          // The floor the speech cloud and the owl stand on.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 128,
            child: ColoredBox(color: deepen(AppColors.primarySoft, 0.06)),
          ),
          SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            // top + 44, not + 24: the progress bar sits at top + 14 and is 6
            // tall, so + 24 left the "NUPO ASKS" eyebrow four pixels under it
            // and the two read as one crowded block. Matches beat 1's headroom.
            padding: EdgeInsets.fromLTRB(24, top + 44, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: _Eyebrow('Nupo asks')),
                const SizedBox(height: 14),
                _SpeechCloud(
                  text: chosen == null
                      ? 'Which app do they open the most?'
                      : "Great — that's all Nupo needed.",
                ),
                SizedBox(
                  height: 104,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 6,
                        bottom: 16,
                        child: _AsideBubble(
                          chosen == null
                              ? 'Pick the one they reach for first'
                              : 'Nupo will guard this one',
                        ),
                      ),
                      Positioned(
                        right: 14,
                        bottom: 0,
                        child: Image.asset(
                          chosen == null ? Nupo.idea : Nupo.phone,
                          width: 118,
                          semanticLabel: 'Nupo',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                for (final app in kStoryApps) ...[
                  _AppRow(
                    app: app,
                    selected: chosen?.name == app.name,
                    dimmed: chosen != null && chosen.name != app.name,
                    onTap: () => onPick(app),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 10),
                Opacity(
                  opacity: chosen == null ? 0 : 1,
                  child: Column(
                    children: [
                      _Pill(
                        'Nupo remembers ${chosen?.name ?? 'that'}',
                        background: AppColors.textDark,
                        foreground: Colors.white,
                      ),
                      const SizedBox(height: 6),
                      const _BouncingArrow(),
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

/// The hand-drawn speech cloud from the design, transcribed from its SVG path
/// so the silhouette is the designed one rather than an approximation.
class _SpeechCloud extends StatelessWidget {
  final String text;
  const _SpeechCloud({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: CustomPaint(
        painter: _CloudPainter(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 22, 40, 26),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                height: 1.3,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CloudPainter extends CustomPainter {
  // The design's `d` attribute, in its own 330 × 168 viewBox.
  static final _path = Path()
    ..moveTo(62, 150)
    ..cubicTo(30, 150, 14, 128, 26, 110)
    ..cubicTo(8, 94, 22, 66, 46, 68)
    ..cubicTo(50, 38, 86, 26, 108, 44)
    ..cubicTo(126, 12, 176, 10, 194, 40)
    ..cubicTo(224, 24, 262, 38, 262, 66)
    ..cubicTo(294, 64, 310, 90, 296, 112)
    ..cubicTo(312, 128, 298, 152, 270, 150)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final m = Matrix4.identity()
      ..scaleByDouble(size.width / 330, size.height / 168, 1, 1);
    final path = _path.transform(m.storage);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AppColors.cardBorder,
    );
  }

  @override
  bool shouldRepaint(_CloudPainter oldDelegate) => false;
}

class _AsideBubble extends StatelessWidget {
  final String text;
  const _AsideBubble(this.text);

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 150),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(4),
      ),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        height: 1.35,
        fontWeight: FontWeight.w700,
        color: deepen(AppColors.primary, 0.25),
      ),
    ),
  );
}

class _AppRow extends StatelessWidget {
  final StoryApp app;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  const _AppRow({
    required this.app,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: dimmed ? 0.42 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.cardBorder,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.textDark.withValues(
                  alpha: selected ? 0.16 : 0.06,
                ),
                blurRadius: selected ? 26 : 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Android shows the REAL launcher icon; the iOS build could
              // only ever draw a letter tile (Family Controls hides names).
              AppBrandIcon(app.bundleId, size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  app.name,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textDark.withValues(alpha: 0.14),
                    width: 2,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  const _Pill(this.text, {required this.background, required this.foreground});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: foreground,
      ),
    ),
  );
}

class _BouncingArrow extends StatefulWidget {
  const _BouncingArrow();

  @override
  State<_BouncingArrow> createState() => _BouncingArrowState();
}

class _BouncingArrowState extends State<_BouncingArrow>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => Transform.translate(
      offset: Offset(0, math.sin(_c.value * 2 * math.pi) * 3.5 + 3.5),
      child: child,
    ),
    child: const Icon(
      Icons.keyboard_arrow_down_rounded,
      color: AppColors.primary,
      size: 26,
    ),
  );
}

// ---------------------------------------------------------------------------
// Beat 8 — the close. The only button in the whole story.
// ---------------------------------------------------------------------------

class CloseBeat extends StatelessWidget {
  final VoidCallback onCta;
  const CloseBeat({super.key, required this.onCta});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: AppColors.bgDecoration(),
      child: Stack(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "That's it.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    height: 1.14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 14),
                SizedBox(
                  width: 300,
                  child: Text(
                    'Nothing to police. No arguing. They learn a little, then '
                    "they're off — every single time.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.55,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: bottom + 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 7,
                  runSpacing: 7,
                  children: const [
                    _SoftChip('2-min setup'),
                    _SoftChip('No ads'),
                    _SoftChip('You set the rules'),
                  ],
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'I want this for them',
                    trailingArrow: true,
                    onPressed: onCta,
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

class _SoftChip extends StatelessWidget {
  final String text;
  const _SoftChip(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: deepen(AppColors.primary, 0.25),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// The welcome screen — a normal tapped screen; "Get started" begins the scroll.
// ---------------------------------------------------------------------------

class StoryWelcome extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onLogIn;

  const StoryWelcome({
    super.key,
    required this.onGetStarted,
    required this.onLogIn,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, AppColors.primarySoft],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
          // The spacers give tall screens the designed breathing room, but the
          // hero has to come down with the viewport or an SE-class phone
          // overflows: everything below it is fixed-height copy and a button.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final hero = (constraints.maxHeight * 0.24).clamp(96.0, 168.0);
              return Column(
                children: [
                  const Spacer(flex: 2),
                  _WavingNupo(size: hero),
                  const SizedBox(height: 26),
                  const InfoPill(
                    text: 'FOR PARENTS · AGES 5–12',
                    background: AppColors.accentSoft,
                    foreground: AppColors.accentDeep,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Learning they'll\nactually do",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      height: 1.16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(
                    width: 288,
                    child: Text(
                      'A little learning before the apps they love. '
                      'Set it up in two minutes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Get started',
                      trailingArrow: true,
                      onPressed: onGetStarted,
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: onLogIn,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textMuted,
                          ),
                          children: [
                            TextSpan(text: 'I already have an account · '),
                            TextSpan(
                              text: 'Log in',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The hero: Nupo's body with the wing rocking on its own pivot, over the
/// halo rings. Two sprites rather than one so the wave can animate.
class _WavingNupo extends StatefulWidget {
  final double size;
  const _WavingNupo({required this.size});

  @override
  State<_WavingNupo> createState() => _WavingNupoState();
}

class _WavingNupoState extends State<_WavingNupo>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final halo = widget.size * 1.26;
    return SizedBox(
      width: halo,
      height: halo,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.09),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(halo * 0.12),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.07),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: halo * 0.06),
            child: SizedBox(
              width: widget.size,
              child: Stack(
                children: [
                  Image.asset(
                    Nupo.waveBody,
                    width: widget.size,
                    semanticLabel: 'Nupo',
                  ),
                  AnimatedBuilder(
                    animation: _c,
                    builder: (context, child) => Transform.rotate(
                      // The design pivots the wing at 29% / 49% of the sprite.
                      alignment: const Alignment(-0.42, -0.02),
                      angle: _wingAngle(_c.value),
                      child: child,
                    ),
                    child: ExcludeSemantics(
                      child: Image.asset(Nupo.waveWing, width: widget.size),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The design's `wavehand` keyframes: 0° → -9° → 1° → -7° → 0°.
  double _wingAngle(double p) {
    const deg = math.pi / 180;
    if (p < 0.20) return lerpD(0, -9, p / 0.20) * deg;
    if (p < 0.38) return lerpD(-9, 1, (p - 0.20) / 0.18) * deg;
    if (p < 0.56) return lerpD(1, -7, (p - 0.38) / 0.18) * deg;
    if (p < 0.72) return lerpD(-7, 0, (p - 0.56) / 0.16) * deg;
    return 0;
  }
}
