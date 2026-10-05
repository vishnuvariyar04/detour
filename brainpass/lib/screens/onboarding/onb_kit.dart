// screens/onboarding/onb_kit.dart — the building blocks of the course-first
// onboarding (October 2026 redesign).
//
// Every screen in the story and the course steps is built from these, so the
// whole first run reads as one product: a chunky flat button with a ledge
// (Duolingo-style, the same shape the child's lesson uses), a segmented story
// bar, a back-circle-and-track chrome after sign-in, and the drawings a lesson
// is made of (ten-frame, code tiles, coding grid, binary bulbs).
//
// Colours resolve to `AppColors` tokens or are derived from them (CLAUDE.md §8:
// one palette). Type is Nunito via the theme.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme.dart';

// ---------------------------------------------------------------------------
// Assets
// ---------------------------------------------------------------------------

/// The mascot poses, cut from the design's sprite sheets.
class Nupo {
  static const _dir = 'assets/nupo';

  static const wave = '$_dir/wave.png';
  static const waveBody = '$_dir/wave-body.png';
  static const waveWing = '$_dir/wave-wing.png';
  static const idea = '$_dir/idea.png';
  static const teacher = '$_dir/teacher.png';
  static const cheer = '$_dir/cheer.png';
  static const aplus = '$_dir/aplus.png';
  static const ohno = '$_dir/ohno.png';
  static const shrug = '$_dir/shrug.png';
  static const cool = '$_dir/cool.png';
  static const starStudent = '$_dir/star-student.png';
  static const trophy = '$_dir/trophy.png';
  static const focused = '$_dir/focused.png';
  static const pin = 'assets/mascot_pin.png';

  /// Everything the story can show, for `precacheImage` — an uncached pose
  /// swap flickers on first paint.
  static const all = <String>[
    starStudent,
    teacher,
    idea,
    cheer,
    aplus,
    cool,
    focused,
    trophy,
    pin,
  ];
}

/// One app the parent can pick in the story. [bundleId] is the Android package
/// name, so `AppBrandIcon` finds the real launcher icon and the real picker
/// after sign-in can pre-tick the same app.
class StoryApp {
  final String name;
  final String bundleId;
  const StoryApp(this.name, this.bundleId);
}

const kStoryApps = <StoryApp>[
  StoryApp('YouTube', 'com.google.android.youtube'),
  StoryApp('Roblox', 'com.roblox.client'),
  StoryApp('TikTok', 'com.zhiliaoapp.musically'),
  StoryApp('Minecraft', 'com.mojang.minecraftpe'),
];

// ---------------------------------------------------------------------------
// Colour helpers — derived from tokens, never new hexes
// ---------------------------------------------------------------------------

/// The lilac used for chips and blocks: brand purple at low strength.
final Color kLilac = Color.lerp(Colors.white, AppColors.primary, 0.14)!;

/// The near-black stage the child's phone sits on.
final Color kStage = Color.lerp(AppColors.textDark, Colors.black, 0.25)!;

/// The ledge under an amber button.
final Color kAmberLedge = Color.lerp(AppColors.accent, AppColors.accentDeep, 0.35)!;

/// Pale tints for icon tiles, one per chapter colour.
Color tint(Color c, [double a = 0.13]) => Color.lerp(Colors.white, c, a)!;

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

enum Chunky { purple, amber, green, white, ghost }

/// The one CTA shape across onboarding: flat, 54 tall, with a 4px ledge that
/// sinks when pressed.
class ChunkyButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Chunky tone;
  final Widget? leading;
  final bool arrow;

  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = Chunky.purple,
    this.leading,
    this.arrow = true,
  });

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final (Color face, Color ledge, Color ink) = !enabled
        ? (const Color(0xFFE4DFEE), const Color(0xFFCFC8DD), AppColors.textMuted)
        : switch (widget.tone) {
            Chunky.purple => (AppColors.primary, AppColors.primaryDeep, Colors.white),
            Chunky.amber => (AppColors.accent, kAmberLedge, AppColors.textDark),
            Chunky.green => (AppColors.correct, Color.lerp(AppColors.correct, Colors.black, 0.25)!, Colors.white),
            Chunky.white => (Colors.white, Colors.black.withValues(alpha: 0.18), AppColors.primary),
            Chunky.ghost => (Colors.white, AppColors.cardBorder, AppColors.textDark),
          };
    final drop = _down && enabled ? 3.0 : 0.0;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: widget.onPressed,
        child: SizedBox(
          height: 58,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: ledge,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 70),
                left: 0,
                right: 0,
                top: drop,
                height: 54,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: face,
                    borderRadius: BorderRadius.circular(18),
                    border: widget.tone == Chunky.ghost
                        ? Border.all(color: AppColors.cardBorder, width: 2)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.leading != null) ...[
                        widget.leading!,
                        const SizedBox(width: 10),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: ink,
                          ),
                        ),
                      ),
                      if (widget.arrow && enabled) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20, color: ink),
                      ],
                    ],
                  ),
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
// Chrome
// ---------------------------------------------------------------------------

/// Ten segments across the top of the story.
class StoryBar extends StatelessWidget {
  final int filled;
  final bool onDark;
  const StoryBar({super.key, required this.filled, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 10; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: i < filled
                    ? AppColors.accent
                    : (onDark
                          ? Colors.white.withValues(alpha: 0.22)
                          : AppColors.textDark.withValues(alpha: 0.12)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Back circle and a slim progress track — the chrome after sign-in.
class StepChrome extends StatelessWidget {
  final double progress;
  final VoidCallback? onBack;
  final bool onBrand;
  const StepChrome({
    super.key,
    required this.progress,
    this.onBack,
    this.onBrand = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          behavior: HitTestBehavior.opaque,
          child: Opacity(
            opacity: onBack == null ? 0 : 1,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onBrand
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.white,
                boxShadow: onBrand
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.textDark.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: onBrand ? Colors.white : AppColors.textDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: onBrand
                  ? Colors.white.withValues(alpha: 0.22)
                  : AppColors.textDark.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                onBrand ? AppColors.accent : AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Fills the space between a header and a button, centring short content and
/// scrolling tall content on small phones instead of overflowing.
class FitBody extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment cross;
  const FitBody({
    super.key,
    required this.children,
    this.cross = CrossAxisAlignment.stretch,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: IntrinsicHeight(
            child: Column(crossAxisAlignment: cross, children: children),
          ),
        ),
      ),
    );
  }
}

/// The shell every onboarding page uses: a background, a top bar, the page,
/// and the button pinned where a thumb already is.
class OnbPage extends StatelessWidget {
  final Widget? top;
  final List<Widget> content;
  final List<Widget> bottom;
  final Color? background;
  final Gradient? gradient;
  final CrossAxisAlignment cross;

  /// The content fills the page itself (an `Expanded` child, like the child's
  /// phone), so it is laid out directly instead of being sized to fit.
  final bool fill;

  const OnbPage({
    super.key,
    this.top,
    required this.content,
    this.bottom = const [],
    this.background,
    this.gradient,
    this.cross = CrossAxisAlignment.stretch,
    this.fill = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background ?? AppColors.primarySoft,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (top != null) ...[top!, const SizedBox(height: 18)],
                Expanded(
                  child: fill
                      ? Column(crossAxisAlignment: cross, children: content)
                      : FitBody(cross: cross, children: content),
                ),
                if (bottom.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...bottom,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Type
// ---------------------------------------------------------------------------

class OnbText {
  static const eyebrow = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.8,
    color: AppColors.primary,
  );
  static const title = TextStyle(
    fontSize: 28,
    height: 1.12,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    color: AppColors.textDark,
  );
  static const titleSm = TextStyle(
    fontSize: 25,
    height: 1.14,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.4,
    color: AppColors.textDark,
  );
  static const sub = TextStyle(
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
  );
}

/// A white speech bubble with one tucked corner.
class SpeechBubble extends StatelessWidget {
  final String text;
  final bool tailRight;
  const SpeechBubble(this.text, {super.key, this.tailRight = false});

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(20);
    const tuck = Radius.circular(6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: r,
          topRight: r,
          bottomLeft: tailRight ? r : tuck,
          bottomRight: tailRight ? tuck : r,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}

/// Small rounded label — course names, lesson names, step counts.
class Chip2 extends StatelessWidget {
  final String text;
  final Color? background;
  final Color? foreground;
  const Chip2(this.text, {super.key, this.background, this.foreground});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: background ?? kLilac,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
        color: foreground ?? AppColors.primaryDeep,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// The child's phone — the stage for the lesson demo
// ---------------------------------------------------------------------------

/// "● ON THEIR PHONE", then a rounded card that is the child's screen.
class KidPhone extends StatelessWidget {
  final Widget child;
  final Widget? overlay;
  final Color? surface;
  const KidPhone({super.key, required this.child, this.overlay, this.surface});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'ON THEIR PHONE',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: ColoredBox(
              color: surface ?? Color.lerp(Colors.white, AppColors.primarySoft, 0.5)!,
              child: Stack(
                children: [
                  Positioned.fill(child: child),
                  ?overlay,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The three-segment progress inside a lesson (done / current / to do).
class LessonSegments extends StatelessWidget {
  final int done;
  const LessonSegments({super.key, required this.done});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: i < done
                    ? AppColors.correct
                    : i == done
                    ? AppColors.primary
                    : AppColors.textDark.withValues(alpha: 0.08),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Lesson drawings — the same pictures the real lesson draws
// ---------------------------------------------------------------------------

/// Two rows of five. [filled] counters in purple; with [ghost] the empty
/// places are amber, showing the missing part.
class TenFrame extends StatelessWidget {
  final int filled;
  final double cell;
  final bool ghost;
  const TenFrame({
    super.key,
    required this.filled,
    this.cell = 34,
    this.ghost = false,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(cell * 5 + 8, cell * 2 + 8),
    painter: _TenFramePainter(filled, ghost),
  );
}

class _TenFramePainter extends CustomPainter {
  final int filled;
  final bool ghost;
  _TenFramePainter(this.filled, this.ghost);

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(size.height * 0.16),
    );
    canvas.drawRRect(frame, Paint()..color = Colors.white);
    canvas.drawRRect(
      frame.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.cardBorder,
    );
    final cell = (size.width - 8) / 5;
    for (var i = 0; i < 10; i++) {
      final c = Offset(4 + cell * (i % 5) + cell / 2, 4 + cell * (i ~/ 5) + cell / 2);
      final r = cell * 0.36;
      if (i < filled) {
        canvas.drawCircle(c, r, Paint()..color = AppColors.primary);
      } else if (ghost) {
        canvas.drawCircle(c, r, Paint()..color = tint(AppColors.accent, 0.3));
        canvas.drawCircle(
          c,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = AppColors.accent,
        );
      } else {
        _dashedCircle(canvas, c, r * 0.95);
      }
    }
  }

  void _dashedCircle(Canvas canvas, Offset c, double r) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.cardBorder;
    const n = 10;
    for (var k = 0; k < n; k++) {
      final a = k * 2 * math.pi / n;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, math.pi / n, false, p);
    }
  }

  @override
  bool shouldRepaint(_TenFramePainter o) => o.filled != filled || o.ghost != ghost;
}

/// Light bulbs worth 8, 4, 2 and 1 — binary, drawn.
class Bulbs extends StatelessWidget {
  final List<bool> on;
  final double width;
  const Bulbs({super.key, required this.on, this.width = 200});

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size(width, width * 0.4),
    painter: _BulbsPainter(on),
  );
}

class _BulbsPainter extends CustomPainter {
  final List<bool> on;
  _BulbsPainter(this.on);

  static const _values = [8, 4, 2, 1];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / 4;
    final s = w / 48; // drawn on a 48-wide cell
    for (var i = 0; i < 4; i++) {
      final lit = on[i];
      final cx = w * i + w / 2;
      canvas.save();
      canvas.translate(cx, 0);
      canvas.scale(s);
      if (lit) {
        canvas.drawCircle(
          const Offset(0, 22),
          20,
          Paint()..color = AppColors.accent.withValues(alpha: 0.25),
        );
      }
      final bulb = Path()
        ..moveTo(-12, 22)
        ..arcToPoint(const Offset(12, 22), radius: const Radius.circular(12), largeArc: true)
        ..cubicTo(12, 27, 9, 30, 7, 32)
        ..lineTo(7, 36)
        ..lineTo(-7, 36)
        ..lineTo(-7, 32)
        ..cubicTo(-9, 30, -12, 27, -12, 22)
        ..close();
      canvas.drawPath(
        bulb,
        Paint()..color = lit ? AppColors.accent : const Color(0xFFEEEAF5),
      );
      canvas.drawPath(
        bulb,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = lit ? kAmberLedge : const Color(0xFFD6CFE4),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(-6, 38, 12, 6), const Radius.circular(2)),
        Paint()..color = lit ? AppColors.accentDeep : const Color(0xFFC9C2D8),
      );
      final tp = TextPainter(
        text: TextSpan(
          text: '${_values[i]}',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: lit ? AppColors.textDark : const Color(0xFFB3ACC2),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(-tp.width / 2, 52));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BulbsPainter o) => o.on != on;
}

/// A row of letter or number tiles.
class CodeTiles extends StatelessWidget {
  final List<String> items;
  final Color ink;
  final Color? fill;
  final double size;
  const CodeTiles(
    this.items, {
    super.key,
    this.ink = AppColors.primary,
    this.fill,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final bg = fill ?? kLilac;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(width: size * 0.16),
          Container(
            width: size,
            height: size * 1.1,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(size * 0.26),
            ),
            child: Text(
              items[i],
              style: TextStyle(
                fontSize: size * 0.48,
                fontWeight: FontWeight.w900,
                color: ink,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A coding block: amber for a loop, lilac for a step, indented inside a loop.
class CodeBlock extends StatelessWidget {
  final String text;
  final IconData? icon;
  final bool loop;
  final bool inside;
  const CodeBlock(this.text, {super.key, this.icon, this.loop = false, this.inside = false});

  @override
  Widget build(BuildContext context) {
    final ink = loop ? AppColors.accentDeep : AppColors.primaryDeep;
    return Padding(
      padding: EdgeInsets.only(left: inside ? 20 : 0, bottom: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: loop ? tint(AppColors.accent, 0.22) : kLilac,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? (loop ? Icons.repeat_rounded : Icons.arrow_forward_rounded), size: 16, color: ink),
            if (text.isNotEmpty) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(text, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: ink)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A short program read aloud as arrows: → ↑ → ↑.
class MoveIcons extends StatelessWidget {
  final List<IconData> moves;
  const MoveIcons(this.moves, {super.key});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('Runs ', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
      for (final m in moves) Icon(m, size: 17, color: AppColors.textMuted),
    ],
  );
}

/// The coding grid. [y] counts up from the bottom row, as in the course.
/// With [onTap] set, tapping a square reports its cell.
class GridBoard extends StatelessWidget {
  final int w;
  final int h;
  final (int, int) start;
  final List<(int, int)> trail;
  final (int, int)? pick;
  final bool? pickRight; // null = picked, not yet graded
  final double cell;
  final ValueChanged<(int, int)>? onTap;

  const GridBoard({
    super.key,
    required this.w,
    required this.h,
    this.start = (0, 0),
    this.trail = const [],
    this.pick,
    this.pickRight,
    this.cell = 36,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = Size(w * cell + 4, h * cell + 4);
    final paint = CustomPaint(
      size: size,
      painter: _GridPainter(this),
    );
    if (onTap == null) return paint;
    return GestureDetector(
      onTapUp: (d) {
        final x = ((d.localPosition.dx - 2) / cell).floor();
        final row = ((d.localPosition.dy - 2) / cell).floor();
        if (x < 0 || x >= w || row < 0 || row >= h) return;
        onTap!((x, h - 1 - row));
      },
      child: paint,
    );
  }
}

class _GridPainter extends CustomPainter {
  final GridBoard b;
  _GridPainter(this.b);

  Offset _center((int, int) c) => Offset(
    2 + c.$1 * b.cell + b.cell / 2,
    2 + (b.h - 1 - c.$2) * b.cell + b.cell / 2,
  );

  @override
  void paint(Canvas canvas, Size size) {
    for (var x = 0; x < b.w; x++) {
      for (var y = 0; y < b.h; y++) {
        final picked = b.pick == (x, y);
        final onTrail = b.trail.contains((x, y));
        final rect = Rect.fromLTWH(
          2 + x * b.cell + 1.5,
          2 + (b.h - 1 - y) * b.cell + 1.5,
          b.cell - 3,
          b.cell - 3,
        );
        final rr = RRect.fromRectAndRadius(rect, Radius.circular(b.cell * 0.2));
        final Color fill;
        final Color stroke;
        if (picked) {
          final right = b.pickRight;
          fill = right == true
              ? AppColors.correctSoft
              : right == false
              ? AppColors.wrongSoft
              : kLilac;
          stroke = right == true
              ? AppColors.correct
              : right == false
              ? AppColors.wrong
              : AppColors.primary;
        } else {
          fill = onTrail
              ? tint(AppColors.accent, 0.2)
              : ((x + y).isOdd ? const Color(0xFFFAF8FF) : Colors.white);
          stroke = const Color(0xFFE6E0F2);
        }
        canvas.drawRRect(rr, Paint()..color = fill);
        canvas.drawRRect(
          rr,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = picked ? 2.5 : 1.2
            ..color = stroke,
        );
      }
    }
    if (b.trail.isNotEmpty) {
      final pts = [b.start, ...b.trail].map(_center).toList();
      final dot = Paint()..color = AppColors.accent;
      for (var i = 0; i < pts.length - 1; i++) {
        final a = pts[i], z = pts[i + 1];
        final len = (z - a).distance;
        for (var d = 4.0; d < len; d += 8) {
          canvas.drawCircle(Offset.lerp(a, z, d / len)!, 2.2, dot);
        }
      }
    }
    // Nupo: a purple dot with eyes and a beak.
    final c = _center(b.start);
    final r = b.cell * 0.36;
    canvas.drawCircle(c, r, Paint()..color = AppColors.primary);
    final eye = r * 0.3;
    for (final dx in [-r * 0.36, r * 0.36]) {
      canvas.drawCircle(c + Offset(dx, -r * 0.15), eye, Paint()..color = Colors.white);
      canvas.drawCircle(
        c + Offset(dx, -r * 0.15),
        eye * 0.48,
        Paint()..color = AppColors.textDark,
      );
    }
    final beak = Path()
      ..moveTo(c.dx - r * 0.18, c.dy + r * 0.25)
      ..lineTo(c.dx, c.dy + r * 0.5)
      ..lineTo(c.dx + r * 0.18, c.dy + r * 0.25)
      ..close();
    canvas.drawPath(beak, Paint()..color = AppColors.accent);
  }

  @override
  bool shouldRepaint(_GridPainter o) =>
      o.b.pick != b.pick || o.b.pickRight != b.pickRight || o.b.cell != b.cell;
}

/// A white rounded card — the picture frame of a lesson.
class PicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const PicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFECE6F8), width: 2),
    ),
    child: child,
  );
}
