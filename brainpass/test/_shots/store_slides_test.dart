// Store screenshots, drawn with the app's own fonts, owls and lesson
// drawings. Throwaway: renders PNGs into the scratchpad; delete when done.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:brainpass/theme.dart';
import 'package:brainpass/screens/onboarding/onb_kit.dart';

const scratch =
    r'C:\Users\vishn\AppData\Local\Temp\claude\C--dev-detour\b71f8aa8-ef2a-4fb3-8036-40edd9c8e623\scratchpad';
const shots = '$scratch\\shots';
const outDir = '$scratch\\store2';

Future<void> _font(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

// ------------------------------------------------------------------ pieces

const ink = AppColors.textDark;

class Slide extends StatelessWidget {
  final Color bg;
  final Color text;
  final String title;
  final String sub;
  final Widget child;
  const Slide({
    super.key,
    required this.bg,
    required this.title,
    required this.sub,
    required this.child,
    this.text = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 540,
      height: 960,
      color: bg,
      child: Stack(
        children: [
          Positioned(
            right: -90,
            top: -70,
            child: _disc(300, Colors.white.withValues(alpha: 0.10)),
          ),
          Positioned(
            left: -80,
            top: 380,
            child: _disc(220, Colors.white.withValues(alpha: 0.07)),
          ),
          Column(
            children: [
              const SizedBox(height: 54),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 34),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 43,
                    height: 1.08,
                    letterSpacing: -0.6,
                    fontWeight: FontWeight.w900,
                    color: text,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  sub,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 19,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: text.withValues(alpha: 0.85),
                  ),
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _disc(double s, Color c) => Container(
  width: s,
  height: s,
  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
);

/// A phone: dark rounded body, the screen inside.
class Phone extends StatelessWidget {
  final double width;
  final Widget child;
  const Phone({super.key, required this.width, required this.child});

  @override
  Widget build(BuildContext context) {
    final h = width * 2.06;
    return Container(
      width: width,
      height: h,
      padding: EdgeInsets.all(width * 0.035),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1430),
        borderRadius: BorderRadius.circular(width * 0.15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(width * 0.12),
        child: child,
      ),
    );
  }
}

/// A real screen capture, top-aligned.
final _bytes = <String, Uint8List>{};
Widget shot(String name) => Image.memory(
  _bytes.putIfAbsent(name, () => File('$shots\\$name').readAsBytesSync()),
  gaplessPlayback: true,
  fit: BoxFit.cover,
  alignment: Alignment.topCenter,
  width: double.infinity,
  height: double.infinity,
);

Widget owl(String asset, double w) => Image.asset(asset, width: w);

/// The kinds of apps a child opens. Generic tiles, no real logos.
class _App {
  final IconData icon;
  final Color color;
  final String label;
  const _App(this.icon, this.color, this.label);
}

const _apps = [
  _App(Icons.play_arrow_rounded, Color(0xFFFF0000), 'YouTube'),
  _App(Icons.sports_esports_rounded, Color(0xFF43A047), 'Games'),
  _App(Icons.music_note_rounded, Color(0xFF212121), 'Music'),
  _App(Icons.chat_bubble_rounded, Color(0xFF1E88E5), 'Chat'),
  _App(Icons.photo_camera_rounded, Color(0xFF6D4C41), 'Camera'),
  _App(Icons.map_rounded, Color(0xFF00897B), 'Maps'),
  _App(Icons.image_rounded, Color(0xFF8E24AA), 'Photos'),
  _App(Icons.alarm_rounded, Color(0xFF546E7A), 'Clock'),
  _App(Icons.brush_rounded, Color(0xFFFB8C00), 'Draw'),
  _App(Icons.menu_book_rounded, Color(0xFF3949AB), 'Books'),
  _App(Icons.calculate_rounded, Color(0xFF5D4037), 'Calc'),
  _App(Icons.settings_rounded, Color(0xFF757575), 'Settings'),
];

class HomeScreen extends StatelessWidget {
  final int? tap;
  final Set<int> locked;
  final double scale;
  const HomeScreen({super.key, this.tap, this.locked = const {}, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7FB2FF), Color(0xFFC9A7FF)],
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 14 * scale),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14 * scale),
            child: Row(
              children: [
                Text('4:30', style: _w(11 * scale, Colors.white)),
                const Spacer(),
                Icon(Icons.wifi_rounded, size: 11 * scale, color: Colors.white),
                SizedBox(width: 3 * scale),
                Icon(Icons.battery_full_rounded, size: 11 * scale, color: Colors.white),
              ],
            ),
          ),
          SizedBox(height: 22 * scale),
          Text('4:30', style: _w(40 * scale, Colors.white)),
          Text('Monday, after school', style: _w(10 * scale, Colors.white70)),
          SizedBox(height: 24 * scale),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10 * scale),
            child: Wrap(
              spacing: 6 * scale,
              runSpacing: 12 * scale,
              children: [
                for (var i = 0; i < _apps.length; i++)
                  _tile(_apps[i], i == tap, locked.contains(i)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(_App a, bool tapped, bool isLocked) {
    final s = 44.0 * scale;
    return SizedBox(
      width: 50 * scale,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  color: a.color,
                  borderRadius: BorderRadius.circular(12 * scale),
                  border: tapped
                      ? Border.all(color: Colors.white, width: 3 * scale)
                      : null,
                ),
                child: Icon(a.icon, color: Colors.white, size: 24 * scale),
              ),
              if (isLocked)
                Container(
                  width: s,
                  height: s,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12 * scale),
                  ),
                  child: Icon(Icons.lock_rounded, color: Colors.white, size: 20 * scale),
                ),
              if (tapped)
                Positioned(
                  right: -16 * scale,
                  bottom: -22 * scale,
                  child: Icon(
                    Icons.touch_app_rounded,
                    size: 38 * scale,
                    color: Colors.white,
                    shadows: const [Shadow(blurRadius: 8, color: Colors.black38)],
                  ),
                ),
            ],
          ),
          SizedBox(height: 4 * scale),
          Text(a.label, style: _w(8.5 * scale, Colors.white)),
        ],
      ),
    );
  }
}

TextStyle _w(double size, Color c, [FontWeight w = FontWeight.w900]) => TextStyle(
  fontFamily: 'Nunito',
  fontSize: size,
  fontWeight: w,
  color: c,
  height: 1.1,
);

/// A bright little game with the owl as the player, and Nupo's countdown on top.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, c) {
        final w = c.maxWidth, h = c.maxHeight;
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4FC3F7), Color(0xFFB3E5FC)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(right: 26, top: 90, child: _disc(48, const Color(0xFFFFE082))),
              for (final (x, y, s) in [(20.0, 130.0, 1.0), (150.0, 190.0, 0.8)])
                Positioned(left: x, top: y, child: _cloud(s)),
              // ground
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: h * 0.24,
                child: Column(
                  children: [
                    Container(height: 14, color: const Color(0xFF66BB6A)),
                    Expanded(child: Container(color: const Color(0xFF8D6E63))),
                  ],
                ),
              ),
              // floating blocks and coins
              for (var i = 0; i < 3; i++)
                Positioned(
                  left: w * 0.22 + i * 34,
                  bottom: h * 0.47,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA726),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE65100), width: 2),
                    ),
                    child: i == 1
                        ? Center(child: Text('?', style: _w(18, Colors.white)))
                        : null,
                  ),
                ),
              for (var i = 0; i < 4; i++)
                Positioned(
                  left: w * 0.12 + i * 40,
                  bottom: h * 0.36 + (i.isEven ? 0 : 14),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD54F),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFF9A825), width: 2),
                    ),
                  ),
                ),
              Positioned(
                left: w * 0.55,
                bottom: h * 0.24 - 4,
                child: owl(Nupo.cheer, 92),
              ),
              // Nupo's countdown, as it floats over an unlocked app
              Positioned(
                left: 0,
                right: 0,
                top: 40,
                child: Center(child: timeChip('Games', '14:59 left')),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cloud(double s) => Container(
    width: 90 * s,
    height: 30 * s,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(20),
    ),
  );
}

/// What a child watches once YouTube unlocks: a science video for kids, the
/// up-next list, and Nupo's countdown floating on top.
class VideoScreen extends StatelessWidget {
  const VideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F0F),
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF81D4FA), Color(0xFFE1F5FE)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: -40,
                      right: -40,
                      bottom: -150,
                      child: SizedBox(
                        height: 260,
                        child: CustomPaint(painter: _Rainbow()),
                      ),
                    ),
                    Positioned(right: 18, bottom: 8, child: owl(Nupo.cheer, 74)),
                    Positioned(left: 14, top: 12, child: _disc(30, const Color(0xFFFFE082))),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 3.5,
                        alignment: Alignment.centerLeft,
                        color: Colors.white38,
                        child: FractionallySizedBox(
                          widthFactor: 0.37,
                          child: Container(color: const Color(0xFFFF0000)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Text('Make a rainbow at home! Easy science for kids',
                    style: _w(13.5, Colors.white, FontWeight.w800)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('Fun Science Club  ·  1.2M views',
                    style: _w(10, Colors.white60, FontWeight.w700)),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    _pill(Icons.thumb_up_alt_rounded, '24K'),
                    const SizedBox(width: 6),
                    _pill(Icons.share_rounded, 'Share'),
                    const SizedBox(width: 6),
                    _pill(Icons.download_rounded, 'Save'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              for (final (c, ic, t, m) in [
                (const Color(0xFF66BB6A), Icons.pets_rounded, 'Dinosaurs for kids: the big ones', '8:12'),
                (const Color(0xFF5C6BC0), Icons.rocket_launch_rounded, 'How do rockets fly?', '6:40'),
                (const Color(0xFFFFA726), Icons.palette_rounded, 'Draw a cat in 5 steps', '4:05'),
                (const Color(0xFFEC407A), Icons.music_note_rounded, 'Alphabet song with animals', '3:30'),
              ])
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 104,
                        height: 58,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: [
                            Center(child: Icon(ic, size: 28, color: Colors.white)),
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                color: Colors.black87,
                                child: Text(m, style: _w(8, Colors.white, FontWeight.w800)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(t, style: _w(11, Colors.white, FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          ),
          // Nupo's countdown, as it floats over the unlocked app
          Positioned(
            left: 0,
            right: 0,
            top: 6,
            child: Center(child: timeChip('YouTube', '14:59 left')),
          ),
        ],
      ),
    );
  }

  Widget _pill(IconData i, String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white12,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(i, size: 11, color: Colors.white),
        const SizedBox(width: 4),
        Text(t, style: _w(9, Colors.white, FontWeight.w800)),
      ],
    ),
  );
}

class _Rainbow extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cols = [
      Color(0xFFEF5350), Color(0xFFFFA726), Color(0xFFFFEE58),
      Color(0xFF66BB6A), Color(0xFF42A5F5), Color(0xFF7E57C2),
    ];
    final c = Offset(size.width / 2, size.height);
    for (var i = 0; i < cols.length; i++) {
      final r = size.height - i * 16.0;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = cols[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

Widget timeChip(String app, String left) => Container(
  padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
  decoration: BoxDecoration(
    color: const Color(0xEE241C3B),
    borderRadius: BorderRadius.circular(999),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.timer_rounded, size: 15, color: AppColors.accent),
      const SizedBox(width: 6),
      Text('$app  ·  $left', style: _w(12, Colors.white)),
    ],
  ),
);

/// A floating label in the brand style: rounded, on a short ledge.
Widget tag(String text, {IconData? icon, Color bg = Colors.white, Color fg = ink, double size = 16}) {
  return Container(
    decoration: BoxDecoration(
      color: Color.lerp(bg, Colors.black, 0.18),
      borderRadius: BorderRadius.circular(18),
    ),
    padding: const EdgeInsets.only(bottom: 4),
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(18)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: size + 3, color: fg),
            const SizedBox(width: 7),
          ],
          Text(text, style: _w(size, fg)),
        ],
      ),
    ),
  );
}

class Arrow extends CustomPainter {
  final Offset a, b, c;
  final Color color;
  Arrow(this.a, this.b, this.c, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(b.dx, b.dy, c.dx, c.dy);
    // dashed
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length - 14; d += 18) {
        canvas.drawPath(m.extractPath(d, d + 10), p);
      }
      final t = m.getTangentForOffset(m.length)!;
      final dir = t.vector;
      final ang = math.atan2(dir.dy, dir.dx);
      final tip = t.position;
      final head = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - 18 * math.cos(ang - 0.5), tip.dy - 18 * math.sin(ang - 0.5))
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx - 18 * math.cos(ang + 0.5), tip.dy - 18 * math.sin(ang + 0.5));
      canvas.drawPath(head, p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

Widget tilt(double deg, Widget w) =>
    Transform.rotate(angle: deg * math.pi / 180, child: w);

// ------------------------------------------------------------------ slides

Widget s1() => Slide(
  bg: const Color(0xFFEFE6FF),
  text: const Color(0xFF3B1A86),
  title: 'Nupo steps in before\ngames and videos',
  sub: 'Their favourite apps, with a short lesson first',
  child: Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned(
        left: 34,
        top: 70,
        child: tilt(-7, Phone(width: 196, child: const HomeScreen(tap: 0, scale: 0.8))),
      ),
      Positioned(
        right: 20,
        top: 40,
        child: tilt(4, Phone(width: 268, child: shot('s_lesson.png'))),
      ),
      Positioned.fill(
        child: CustomPaint(
          painter: Arrow(const Offset(92, 226), const Offset(170, 110),
              const Offset(262, 196), const Color(0xFF7C3AED)),
        ),
      ),
      Positioned(
        right: 46,
        top: 8,
        child: tag('YouTube opens after this', icon: Icons.lock_rounded, size: 15),
      ),
      Positioned(left: 26, bottom: 24, child: owl('assets/mascot_opening.png', 150)),
    ],
  ),
);

Widget s2() => Slide(
  bg: AppColors.accent,
  text: ink,
  title: 'A short lesson\nearns play time',
  sub: 'Finish the lesson and the app opens, on a timer',
  child: Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned(
        left: 28,
        top: 60,
        child: tilt(-5, Phone(width: 200, child: shot('s_finish.png'))),
      ),
      Positioned(
        right: 26,
        top: 26,
        child: tilt(3, Phone(width: 262, child: const VideoScreen())),
      ),
      Positioned(
        left: 150,
        top: 470,
        child: tag('+15 min', icon: Icons.bolt_rounded, bg: AppColors.primary, fg: Colors.white, size: 26),
      ),
    ],
  ),
);

Widget s3() => Slide(
  bg: AppColors.done,
  title: 'Then the daily limit\nsays: done for today',
  sub: 'Healthy limits on every app you choose',
  child: Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned(
        left: 0,
        right: 0,
        top: 30,
        child: Center(
          child: Phone(
            width: 290,
            child: Stack(
              children: [
                const Positioned.fill(child: HomeScreen(locked: {0, 1}, scale: 1.1)),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        owl(Nupo.trophy, 120),
                        const SizedBox(height: 6),
                        Text('You are a star today!', style: _w(19, ink)),
                        const SizedBox(height: 4),
                        Text('Great learning. See you tomorrow.',
                            style: _w(12.5, AppColors.textMuted, FontWeight.w800)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                value: 1,
                                strokeWidth: 4,
                                color: AppColors.wrong,
                                backgroundColor: AppColors.line,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('60 of 60 min played today',
                                style: _w(12.5, ink)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        left: 26,
        top: 70,
        child: tilt(-4, tag('Daily limit reached', icon: Icons.timer_off_rounded, size: 15)),
      ),
    ],
  ),
);

Widget s4() => Slide(
  bg: const Color(0xFF5B6CFF),
  title: 'You choose the apps\nand the minutes',
  sub: 'Minutes per lesson, a daily limit, a parent PIN',
  child: Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned(
        left: 0,
        right: 0,
        top: 34,
        child: Center(child: Phone(width: 300, child: shot('s_parent.png'))),
      ),
      Positioned(left: 14, top: 300, child: tilt(-5, tag('15 min per lesson', icon: Icons.bolt_rounded, bg: AppColors.accent, size: 15))),
      Positioned(right: 12, top: 420, child: tilt(4, tag('1 hr a day', icon: Icons.timer_rounded, size: 15))),
      Positioned(left: 22, top: 560, child: tilt(-3, tag('Parent PIN', icon: Icons.lock_rounded, size: 15))),
      Positioned(right: 18, top: 70, child: owl('assets/mascot_pin.png', 120)),
    ],
  ),
);

Widget s5() => Slide(
  bg: AppColors.primary,
  title: 'Every lesson is a step\nin a real course',
  sub: '48 lessons that build, written for their age',
  child: Stack(
    children: [
      Positioned(
        left: 0,
        right: 0,
        top: 36,
        child: Center(child: Phone(width: 300, child: shot('s_path.png'))),
      ),
      Positioned(left: 16, top: 200, child: tilt(-5, tag('Up next', icon: Icons.star_rounded, bg: AppColors.accent, size: 15))),
      Positioned(right: 14, top: 470, child: tilt(4, tag('Boss level', icon: Icons.emoji_events_rounded, size: 15))),
    ],
  ),
);

Widget s6() => Slide(
  bg: AppColors.correct,
  title: 'See what they\nlearned today',
  sub: 'Streaks, scores and what comes next',
  child: Stack(
    children: [
      Positioned(
        left: 0,
        right: 0,
        top: 36,
        child: Center(child: Phone(width: 300, child: shot('s_progress.png'))),
      ),
      Positioned(right: 10, top: 30, child: owl(Nupo.starStudent, 130)),
      Positioned(left: 14, top: 420, child: tilt(-5, tag('6 day streak', icon: Icons.local_fire_department_rounded, size: 15))),
    ],
  ),
);

Widget s7() => Slide(
  bg: const Color(0xFFFFE9C7),
  text: ink,
  title: 'Hints when stuck,\nretries until right',
  sub: 'Every question, finally answered right',
  child: Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned(left: 24, top: 40, child: tilt(-5, Phone(width: 232, child: shot('s_hint.png')))),
      Positioned(right: 24, top: 110, child: tilt(4, Phone(width: 232, child: shot('s_retry.png')))),
      Positioned(left: 40, top: 20, child: tag('A nudge, not the answer', icon: Icons.lightbulb_rounded, bg: AppColors.accent, size: 14)),
      Positioned(right: 30, top: 610, child: tag('Asked again at the end', icon: Icons.replay_rounded, size: 14)),
    ],
  ),
);

Widget _course(String ages, String name, Color c, Widget pic) => Container(
  width: 224,
  height: 300,
  decoration: BoxDecoration(
    color: Color.lerp(c, Colors.black, 0.3),
    borderRadius: BorderRadius.circular(28),
  ),
  padding: const EdgeInsets.only(bottom: 6),
  child: Container(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(999)),
          child: Text('AGES $ages', style: _w(12, Colors.white).copyWith(letterSpacing: 1.1)),
        ),
        const SizedBox(height: 10),
        Text(name, style: _w(22, ink)),
        const Spacer(),
        Center(child: pic),
        const Spacer(),
      ],
    ),
  ),
);

Widget s8() => Slide(
  bg: ink,
  title: 'A course for\nevery age, 5 to 12',
  sub: 'Numbers, logic, coding and reasoning',
  child: Padding(
    padding: const EdgeInsets.only(top: 40),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _course('5-6', 'Number Sense', AppColors.correct, const TenFrame(filled: 7, cell: 34)),
            const SizedBox(width: 20),
            _course('7-8', 'Puzzles & Logic', AppColors.accentDeep,
                const CodeTiles(['B', 'E', 'D'], size: 52)),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _course('9-10', 'Coding', AppColors.primary, const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CodeBlock('REPEAT 3', icon: Icons.repeat_rounded, loop: true),
                SizedBox(height: 4),
                CodeBlock('RIGHT', icon: Icons.arrow_forward_rounded, inside: true),
                SizedBox(height: 4),
                CodeBlock('UP', icon: Icons.arrow_upward_rounded, inside: true),
              ],
            )),
            const SizedBox(width: 20),
            _course('11-12', 'Reasoning', AppColors.kidTop,
                const Bulbs(on: [true, false, true, true], width: 184)),
          ],
        ),
      ],
    ),
  ),
);

// ------------------------------------------------------------------ render

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _font('Nunito', [
      for (final w in ['Regular', 'SemiBold', 'Bold', 'ExtraBold', 'Black'])
        'assets/fonts/Nunito-$w.ttf',
    ]);
    await _font('MaterialIcons', [
      r'C:\dev\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf',
    ]);
    await _font('packages/material_symbols_icons/MaterialSymbolsRounded', [
      r'C:\Users\vishn\AppData\Local\Pub\Cache\hosted\pub.dev\material_symbols_icons-4.2951.0\lib\fonts\MaterialSymbolsRounded.ttf',
    ]);
    Directory(outDir).createSync(recursive: true);
  });

  final slides = {
    '01_steps_in': s1,
    '02_earn_time': s2,
    '03_daily_limit': s3,
    '04_you_choose': s4,
    '05_real_course': s5,
    '06_progress': s6,
    '07_hints_mistakes': s7,
    '08_ages': s8,
  };

  testWidgets('feature_graphic', (t) async {
    t.view.physicalSize = const Size(1024, 500);
    t.view.devicePixelRatio = 1;
    final key = GlobalKey();
    await t.pumpWidget(RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.parent(),
        home: Scaffold(body: banner()),
      ),
    ));
    await t.runAsync(() async {
      for (final el in find.byType(Image).evaluate()) {
        await precacheImage((el.widget as Image).image, el);
      }
    });
    await t.pump(const Duration(seconds: 1));
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 1);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$outDir/feature_graphic.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  });

  for (final e in slides.entries) {
    testWidgets(e.key, (t) async {
      t.view.physicalSize = const Size(1080, 1920);
      t.view.devicePixelRatio = 2;
      final key = GlobalKey();
      await t.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.parent(),
          home: Scaffold(body: e.value()),
        ),
      ));
      await t.runAsync(() async {
        for (final el in find.byType(Image).evaluate()) {
          await precacheImage((el.widget as Image).image, el);
        }
      });
      await t.pump(const Duration(seconds: 1));
      await t.runAsync(() async {
        final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 2);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('$outDir\\${e.key}.png').writeAsBytesSync(png!.buffer.asUint8List());
      });
    });
  }
}

// ------------------------------------------------------------------ banner

Widget banner() => Container(
  width: 1024,
  height: 500,
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    ),
  ),
  child: Stack(
    clipBehavior: Clip.hardEdge,
    children: [
      Positioned(right: -60, top: -120, child: _disc(420, Colors.white.withValues(alpha: 0.08))),
      Positioned(left: -80, bottom: -160, child: _disc(320, Colors.white.withValues(alpha: 0.06))),
      Positioned(
        left: 64,
        top: 0,
        bottom: 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('A lesson first.', style: _w(58, Colors.white).copyWith(letterSpacing: -1)),
            Text('Then play.', style: _w(58, AppColors.accent).copyWith(letterSpacing: -1)),
            const SizedBox(height: 14),
            Text('Screen time that teaches kids 5 to 12',
                style: _w(22, Colors.white.withValues(alpha: 0.9), FontWeight.w800)),
            const SizedBox(height: 22),
            Row(
              children: [
                tag('Real courses', icon: Icons.school_rounded, size: 14),
                const SizedBox(width: 10),
                tag('Daily limits', icon: Icons.timer_rounded, size: 14),
              ],
            ),
          ],
        ),
      ),
      Positioned(
        right: 250,
        top: 70,
        child: tilt(-7, Phone(width: 150, child: const HomeScreen(tap: 0, scale: 0.62))),
      ),
      Positioned(
        right: 58,
        top: 36,
        child: tilt(5, Phone(width: 178, child: shot('s_lesson.png'))),
      ),
      Positioned(
        right: 0,
        top: 0,
        width: 460,
        height: 500,
        child: CustomPaint(
          painter: Arrow(const Offset(98, 182), const Offset(150, 84),
              const Offset(232, 150), Colors.white),
        ),
      ),
      Positioned(right: 18, bottom: -6, child: owl('assets/mascot_opening.png', 120)),
    ],
  ),
);

void bannerMain() {}
