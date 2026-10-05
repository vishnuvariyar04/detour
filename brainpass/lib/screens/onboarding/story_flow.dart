// screens/onboarding/story_flow.dart — the story a parent taps through before
// signing in. Ten screens, one button each, no scrolling:
//
//   1  Welcome           "Turn phone time into real skills."
//   2  Their afternoon   the same apps, again and again — nothing new learned
//   3  The idea          a short lesson before each app, a daily limit at the end
//   4  Age               ← must pick: makes the demo their child's own course
//   5  Their app         ← must pick: names the app for the rest of the story
//   6  Lesson time       what the child sees when they tap that app
//   7  A new idea        the lesson opens with one idea and a picture
//   8  Try it            ← must answer: a real question from that course
//   9  Unlocked          the app opens; the course moves on
//  10  The whole course  "That was lesson N. There are 48." → sign in
//
// Screens 6-9 are drawn as the child's phone, so the parent can tell the
// child-facing lines (the lesson) from the ones written for them.
//
// Replaced the scroll story (`story_screen.dart`) in October 2026. The four
// demo lessons and their content live in `demo_lessons.dart`.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../analytics.dart';
import '../../storage.dart';
import '../../theme.dart';
import '../../widgets.dart';
import 'demo_lessons.dart';
import 'onb_kit.dart';

class OnboardingStory extends StatefulWidget {
  /// The parent tapped "Build their course" — on to sign-in.
  final VoidCallback onFinished;

  /// "I already have an account" — a returning parent.
  final VoidCallback onLogIn;

  /// The app picked on screen 5, so the real picker can pre-tick it.
  final ValueChanged<StoryApp> onAppPicked;

  const OnboardingStory({
    super.key,
    required this.onFinished,
    required this.onLogIn,
    required this.onAppPicked,
  });

  @override
  State<OnboardingStory> createState() => _OnboardingStoryState();
}

class _OnboardingStoryState extends State<OnboardingStory> {
  int _at = 0;
  String? _band;
  StoryApp? _app;

  // The demo question.
  String? _picked;
  bool _solved = false;
  int _wrongs = 0;
  bool _showHint = false;

  bool _precached = false;

  @override
  void initState() {
    super.initState();
    Analytics.storyShown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      for (final a in Nupo.all) {
        precacheImage(AssetImage(a), context);
      }
    }
  }

  DemoCourse get _course => demoFor(_band ?? 'c');
  String get _appName => _app?.name ?? 'YouTube';
  String get _appPkg => _app?.bundleId ?? kStoryApps.first.bundleId;

  void _go(int i) => setState(() => _at = i.clamp(0, 9));
  void _next() => _go(_at + 1);

  Future<void> _pickBand(String band) async {
    setState(() {
      _band = band;
      _picked = null;
      _solved = false;
      _wrongs = 0;
      _showHint = false;
    });
    // The story's age IS the setup's age: the step was moved up from setup so
    // the demo could be their child's own course.
    const upper = {'a': 6, 'b': 8, 'c': 10, 'd': 12};
    await Storage.setAgeBand(band);
    await Storage.setChildAge(upper[band]!);
    await Storage.setOnbSubject(demoFor(band).id);
  }

  void _pickApp(StoryApp app) {
    if (_app == null) Analytics.storyAppPicked(app.name);
    setState(() => _app = app);
    widget.onAppPicked(app);
  }

  void _answer(String value) {
    if (_solved) return;
    final right = value == _course.answer;
    setState(() {
      _picked = value;
      _showHint = false;
      if (right) {
        _solved = true;
      } else {
        _wrongs++;
      }
    });
    // `wrongs` says whether the demo is pitched right for a parent.
    if (right) Analytics.storyAnswered(_wrongs);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _at == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _at > 0) _go(_at - 1);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.04, 0), end: Offset.zero).animate(a),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(_at), child: _screen()),
      ),
    );
  }

  Widget _screen() => switch (_at) {
    0 => _welcome(),
    1 => _afternoon(),
    2 => _idea(),
    3 => _age(),
    4 => _appPick(),
    5 => _lessonTime(),
    6 => _newIdea(),
    7 => _tryIt(),
    8 => _unlocked(),
    _ => _wholeCourse(),
  };

  // ---------------------------------------------------------------- 1
  Widget _welcome() => OnbPage(
    content: [
      const Spacer(),
      const _Hero(),
      const SizedBox(height: 18),
      const Text(
        'Turn phone time into real skills.',
        textAlign: TextAlign.center,
        style: OnbText.title,
      ),
      const SizedBox(height: 10),
      const Text(
        'A short lesson before every game or video.',
        textAlign: TextAlign.center,
        style: OnbText.sub,
      ),
      const Spacer(),
    ],
    bottom: [
      ChunkyButton(
        label: 'Get started',
        onPressed: () {
          Analytics.storyStarted();
          _next();
        },
      ),
      const SizedBox(height: 6),
      TextButton(
        onPressed: () {
          Analytics.storyLoginTapped();
          widget.onLogIn();
        },
        child: const Text(
          'I already have an account',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textMuted),
        ),
      ),
    ],
  );

  // ---------------------------------------------------------------- 2
  Widget _afternoon() {
    const rows = [
      ('3:40', 0, '25 min'),
      ('4:35', 1, '40 min'),
      ('6:10', 0, '20 min'),
      ('7:45', 2, '30 min'),
    ];
    return OnbPage(
      top: const StoryBar(filled: 1),
      content: [
        const Text('SOUND FAMILIAR?', style: OnbText.eyebrow),
        const SizedBox(height: 6),
        const Text('After school, the same apps. Again and again.', style: OnbText.titleSm),
        const SizedBox(height: 20),
        _Card(
          child: Column(
            children: [
              const _CardHeader('A school day', 'Example'),
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const _Dashed(),
                _DayRow(
                  time: rows[i].$1,
                  app: kStoryApps[rows[i].$2],
                  trailing: _Pill(
                    'Nothing new',
                    background: const Color(0xFFF4F1F9),
                    foreground: const Color(0xFFA9A3B8),
                  ),
                  sub: rows[i].$3,
                ),
              ],
              const Divider(height: 18, color: Color(0xFFECE6F8)),
              const Row(
                children: [
                  Text('New skills today', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                  Spacer(),
                  Text('0', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
      bottom: [ChunkyButton(label: 'Continue', onPressed: _next)],
    );
  }

  // ---------------------------------------------------------------- 3
  Widget _idea() => OnbPage(
    background: AppColors.primary,
    top: const StoryBar(filled: 2, onDark: true),
    content: [
      Text('THE IDEA', style: OnbText.eyebrow.copyWith(color: AppColors.accent)),
      const SizedBox(height: 6),
      Text(
        'What if every app opened after a short lesson?',
        style: OnbText.titleSm.copyWith(color: Colors.white),
      ),
      const SizedBox(height: 24),
      for (final app in kStoryApps.take(3)) ...[
        _IdeaRow(app: app),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 2),
      const _LimitRow(),
      const SizedBox(height: 20),
      const Text(
        'Same apps. A new skill, a little every day.',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
      ),
      const Spacer(),
    ],
    bottom: [ChunkyButton(label: 'Continue', tone: Chunky.white, onPressed: _next)],
  );

  // ---------------------------------------------------------------- 4
  Widget _age() => OnbPage(
    top: const StoryBar(filled: 3),
    content: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Image.asset(Nupo.teacher, width: 84, semanticLabel: 'Nupo'),
          const SizedBox(width: 8),
          const Flexible(child: SpeechBubble('How old is your child?')),
        ],
      ),
      const SizedBox(height: 18),
      // Rows, not a GridView: a scrolling grid cannot report an intrinsic
      // height, and the page body sizes itself to its content.
      for (var r = 0; r < 2; r++) ...[
        if (r > 0) const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < 2; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 0.98,
                  child: _AgeCard(
                    course: kDemoCourses[r * 2 + i],
                    selected: _band == kDemoCourses[r * 2 + i].band,
                    onTap: () => _pickBand(kDemoCourses[r * 2 + i].band),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
      const Spacer(),
    ],
    bottom: [ChunkyButton(label: 'Continue', onPressed: _band == null ? null : _next)],
  );

  // ---------------------------------------------------------------- 5
  Widget _appPick() => OnbPage(
    top: const StoryBar(filled: 4),
    content: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Expanded(child: SpeechBubble('Which app do they open first?', tailRight: true)),
          const SizedBox(width: 6),
          Image.asset(Nupo.idea, width: 84, semanticLabel: 'Nupo'),
        ],
      ),
      const SizedBox(height: 18),
      for (final a in kStoryApps) ...[
        _AppRow(app: a, selected: _app?.name == a.name, onTap: () => _pickApp(a)),
        const SizedBox(height: 10),
      ],
      const Spacer(),
    ],
    bottom: [ChunkyButton(label: 'Show me', onPressed: _app == null ? null : _next)],
  );

  // ---------------------------------------------------------------- 6
  Widget _lessonTime() => OnbPage(
    background: kStage,
    fill: true,
    top: const StoryBar(filled: 5, onDark: true),
    content: [
      Expanded(
        child: KidPhone(
          surface: Color.lerp(AppColors.textDark, Colors.black, 0.1),
          child: Stack(
            children: [
              const Positioned.fill(child: _BlurredApp()),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppBrandIcon(_appPkg, size: 54),
                        const SizedBox(height: 12),
                        const Text(
                          'Lesson time',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.primary),
                        ),
                        const SizedBox(height: 4),
                        Text('Then $_appName opens.', style: OnbText.sub),
                        const SizedBox(height: 10),
                        Chip2('${_course.name} · ${_course.lesson}'),
                        const SizedBox(height: 16),
                        ChunkyButton(label: 'Start', onPressed: _next),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  // ---------------------------------------------------------------- 7
  Widget _newIdea() => OnbPage(
    background: kStage,
    fill: true,
    top: const StoryBar(filled: 6, onDark: true),
    content: [
      Expanded(
        child: KidPhone(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FitBody(
              children: [
                const LessonSegments(done: 0),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: AppColors.accentDeep),
                    const SizedBox(width: 4),
                    const Text(
                      'NEW IDEA',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: AppColors.accentDeep),
                    ),
                    const Spacer(),
                    Flexible(child: Chip2(_course.stop)),
                  ],
                ),
                const SizedBox(height: 14),
                PicCard(child: _course.teachPic(context)),
                const SizedBox(height: 16),
                Text(
                  _course.teach,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 19, height: 1.25, fontWeight: FontWeight.w900, color: AppColors.textDark),
                ),
                const Spacer(),
                const SizedBox(height: 12),
                ChunkyButton(label: 'Got it', onPressed: _next),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  // ---------------------------------------------------------------- 8
  Widget _tryIt() {
    final c = _course;
    final wrong = _picked != null && !_solved;
    (int, int)? cell;
    if (c.kind == DemoKind.cell && _picked != null) {
      final p = _picked!.split(',');
      cell = (int.parse(p[0]), int.parse(p[1]));
    }
    final Widget drawer = _solved
        ? _Drawer(
            good: true,
            title: 'Nailed it!',
            line: c.why,
            action: ChunkyButton(label: 'Unlock $_appName', tone: Chunky.green, onPressed: _next),
          )
        : wrong
        ? _Drawer(good: false, title: 'Not quite', line: '${c.hint} Try again.')
        : _showHint
        ? _Drawer(good: null, title: 'Hint', line: c.hint)
        : const SizedBox.shrink();

    return OnbPage(
      background: kStage,
      fill: true,
      top: const StoryBar(filled: 7, onDark: true),
      content: [
        Expanded(
          child: KidPhone(
            overlay: Positioned(left: 0, right: 0, bottom: 0, child: drawer),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FitBody(
                children: [
                  const LessonSegments(done: 1),
                  const SizedBox(height: 14),
                  Text(
                    c.prompt,
                    style: const TextStyle(fontSize: 19, height: 1.25, fontWeight: FontWeight.w900, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 14),
                  PicCard(
                    child: demoQuestionPic(
                      c,
                      pick: cell,
                      pickRight: cell == null ? null : _solved,
                      onCell: (p) => _answer('${p.$1},${p.$2}'),
                    ),
                  ),
                  if (c.kind != DemoKind.cell) ...[
                    const SizedBox(height: 14),
                    _Choices(
                      choices: c.choices,
                      twoUp: c.kind == DemoKind.word,
                      answer: c.answer,
                      picked: _picked,
                      solved: _solved,
                      onTap: _answer,
                    ),
                  ],
                  const Spacer(),
                  const SizedBox(height: 12),
                  if (!_solved && !wrong)
                    Center(
                      child: GestureDetector(
                        onTap: () => setState(() => _showHint = !_showHint),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(color: kLilac, borderRadius: BorderRadius.circular(999)),
                          child: const Text(
                            'Need a hint?',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  // Room for the drawer so it never covers the answers.
                  SizedBox(height: _solved ? 150 : (wrong || _showHint ? 90 : 0)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- 9
  Widget _unlocked() {
    final c = _course;
    return OnbPage(
      background: AppColors.correct,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.correct, Color.lerp(AppColors.correct, Colors.black, 0.25)!],
      ),
      top: const StoryBar(filled: 8, onDark: true),
      cross: CrossAxisAlignment.center,
      content: [
        const Spacer(),
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.16)),
          alignment: Alignment.center,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.22)),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 46),
          ),
        ),
        const SizedBox(height: 12),
        Image.asset(Nupo.cheer, width: 136, semanticLabel: 'Nupo cheering'),
        const SizedBox(height: 10),
        Text(
          '$_appName is open\nfor 15 minutes.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, height: 1.15, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(c.name, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                  const Spacer(),
                  Text(
                    '${c.lesson} / ${c.lessons}',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: c.lesson / c.lessons,
                  minHeight: 7,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
      ],
      bottom: [ChunkyButton(label: 'Continue', tone: Chunky.white, onPressed: _next)],
    );
  }

  // ---------------------------------------------------------------- 10
  Widget _wholeCourse() {
    final c = _course;
    return OnbPage(
      top: const StoryBar(filled: 10),
      cross: CrossAxisAlignment.center,
      content: [
        const Spacer(),
        Image.asset(Nupo.aplus, width: 124, semanticLabel: 'Nupo'),
        const SizedBox(height: 8),
        Text(
          'That was lesson ${c.lesson}.\nThere are ${c.lessons}.',
          textAlign: TextAlign.center,
          style: OnbText.title,
        ),
        const SizedBox(height: 8),
        Text('${c.name}, built for ages ${c.ages}.', textAlign: TextAlign.center, style: OnbText.sub),
        const SizedBox(height: 20),
        _CourseDots(lesson: c.lesson, total: c.lessons),
        const Spacer(),
      ],
      bottom: [
        const Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            _SoftChip('2-minute setup'),
            _SoftChip('You set the limits'),
            _SoftChip('No ads'),
          ],
        ),
        const SizedBox(height: 14),
        ChunkyButton(
          label: 'Build their course',
          onPressed: () {
            Analytics.storyFinished();
            widget.onFinished();
          },
        ),
      ],
    );
  }
}

// ===========================================================================
// Pieces
// ===========================================================================

/// Screen 1: a phone ringed by the four kinds of skill, Nupo in front.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        height: 290,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 25,
              top: 10,
              child: Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Colors.white, AppColors.primarySoft],
                    stops: [0.3, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 92,
              top: 18,
              child: Transform.rotate(
                angle: -0.07,
                child: Container(
                  width: 116,
                  height: 200,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.textDark,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textDark.withValues(alpha: 0.25),
                        blurRadius: 30,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.primaryBright, AppColors.primary],
                      ),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 50),
                  ),
                ),
              ),
            ),
            const _Tile(
              left: 16,
              top: 32,
              angle: -0.14,
              label: 'Count',
              child: TenFrame(filled: 7, cell: 13),
            ),
            _Tile(
              right: 14,
              top: 24,
              angle: 0.12,
              label: 'Code',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CodeTiles(const ['A'], ink: AppColors.textDark, fill: tint(AppColors.accent, 0.22), size: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('=', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                  const CodeTiles(['1'], size: 20),
                ],
              ),
            ),
            const _Tile(
              left: 6,
              top: 128,
              angle: 0.09,
              label: 'Loops',
              child: CodeBlock('DO ×4', loop: true),
            ),
            const _Tile(
              right: 4,
              top: 134,
              angle: -0.1,
              label: 'Binary',
              child: Bulbs(on: [true, false, true, true], width: 70),
            ),
            Positioned(
              left: 96,
              bottom: -6,
              child: Image.asset(Nupo.starStudent, width: 112, semanticLabel: 'Nupo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final double? left, right, top;
  final double angle;
  final String label;
  final Widget child;
  const _Tile({
    this.left,
    this.right,
    this.top,
    required this.angle,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    right: right,
    top: top,
    child: Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.fromLTRB(9, 7, 9, 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.9, color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: AppColors.textDark.withValues(alpha: 0.08),
          blurRadius: 26,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: child,
  );
}

class _CardHeader extends StatelessWidget {
  final String left, right;
  const _CardHeader(this.left, this.right);

  @override
  Widget build(BuildContext context) {
    const s = TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.4, color: AppColors.textMuted);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          Row(children: [Text(left.toUpperCase(), style: s), const Spacer(), Text(right.toUpperCase(), style: s)]),
          const Divider(height: 14, color: Color(0xFFECE6F8)),
        ],
      ),
    );
  }
}

class _Dashed extends StatelessWidget {
  const _Dashed();
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(double.infinity, 1),
    painter: _DashPainter(),
  );
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFECE6F8);
    for (var x = 0.0; x < size.width; x += 6) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 3, 1), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => false;
}

class _DayRow extends StatelessWidget {
  final String time;
  final StoryApp app;
  final String sub;
  final Widget trailing;
  const _DayRow({required this.time, required this.app, required this.sub, required this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            time,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        AppBrandIcon(app.bundleId, size: 34),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(app.name, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
              Text(sub, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
            ],
          ),
        ),
        trailing,
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  final String text;
  final Color background, foreground;
  const _Pill(this.text, {required this.background, required this.foreground});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
    child: Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: foreground)),
  );
}

/// "★ Lesson → [app] 15 min", the core trade in one row.
class _IdeaRow extends StatelessWidget {
  final StoryApp app;
  const _IdeaRow({required this.app});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 98,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(14)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 17, color: AppColors.textDark),
            SizedBox(width: 4),
            Text('Lesson', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textDark)),
          ],
        ),
      ),
      SizedBox(
        width: 34,
        child: Icon(Icons.arrow_forward_rounded, color: Colors.white.withValues(alpha: 0.7), size: 20),
      ),
      Expanded(
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              AppBrandIcon(app.bundleId, size: 30),
              const SizedBox(width: 12),
              const Text('15 min', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.correct)),
            ],
          ),
        ),
      ),
    ],
  );
}

class _LimitRow extends StatelessWidget {
  const _LimitRow();

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedBoxPainter(Colors.white.withValues(alpha: 0.4)),
    child: SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_rounded, color: Colors.white, size: 17),
          const SizedBox(width: 8),
          Text(
            'Daily limit. Done for today.',
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    ),
  );
}

class _DashedBoxPainter extends CustomPainter {
  final Color color;
  _DashedBoxPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)));
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, d + 5), p);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBoxPainter o) => o.color != color;
}

class _AgeCard extends StatelessWidget {
  final DemoCourse course;
  final bool selected;
  final VoidCallback onTap;
  const _AgeCard({required this.course, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: (selected ? AppColors.primary : AppColors.textDark).withValues(alpha: selected ? 0.18 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: ageTint(course.band), borderRadius: BorderRadius.circular(15)),
              child: FittedBox(child: Padding(padding: const EdgeInsets.all(8), child: ageArt(course.band))),
            ),
          ),
          const SizedBox(height: 8),
          Text(course.ages, style: const TextStyle(fontSize: 22, height: 1, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(
            course.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.textMuted),
          ),
        ],
      ),
    ),
  );
}

class _AppRow extends StatelessWidget {
  final StoryApp app;
  final bool selected;
  final VoidCallback onTap;
  const _AppRow({required this.app, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppColors.primary : const Color(0xFFECE6F8), width: 2),
      ),
      child: Row(
        children: [
          AppBrandIcon(app.bundleId, size: 40),
          const SizedBox(width: 14),
          Expanded(child: Text(app.name, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800))),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.primary : Colors.transparent,
              border: Border.all(color: selected ? AppColors.primary : const Color(0xFFD9D2E8), width: 2),
            ),
            child: selected ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
          ),
        ],
      ),
    ),
  );
}

/// The game behind the shield, out of focus.
class _BlurredApp extends StatelessWidget {
  const _BlurredApp();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      children: [
        for (var i = 0; i < 5; i++) ...[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          if (i < 4) const SizedBox(height: 12),
        ],
      ],
    ),
  );
}

class _Choices extends StatelessWidget {
  final List<String> choices;
  final bool twoUp;
  final String answer;
  final String? picked;
  final bool solved;
  final ValueChanged<String> onTap;
  const _Choices({
    required this.choices,
    required this.twoUp,
    required this.answer,
    required this.picked,
    required this.solved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget button(String v) {
      final right = solved && v == answer;
      final wrong = !solved && picked == v;
      final Color face = right ? AppColors.correctSoft : wrong ? AppColors.wrongSoft : Colors.white;
      final Color edge = right ? AppColors.correct : wrong ? AppColors.wrong : const Color(0xFFECE6F8);
      final Color ink = right ? AppColors.correct : wrong ? AppColors.wrong : AppColors.textDark;
      return GestureDetector(
        onTap: () => onTap(v),
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: face,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: edge, width: 2),
            boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 3))],
          ),
          child: Text(v, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: ink)),
        ),
      );
    }

    final per = twoUp ? 2 : choices.length;
    final rows = <Widget>[];
    for (var i = 0; i < choices.length; i += per) {
      final slice = choices.sublist(i, (i + per).clamp(0, choices.length));
      rows.add(Row(
        children: [
          for (var j = 0; j < slice.length; j++) ...[
            if (j > 0) const SizedBox(width: 9),
            Expanded(child: button(slice[j])),
          ],
        ],
      ));
      if (i + per < choices.length) rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }
}

class _Drawer extends StatelessWidget {
  final bool? good;
  final String title;
  final String line;
  final Widget? action;
  const _Drawer({required this.good, required this.title, required this.line, this.action});

  @override
  Widget build(BuildContext context) {
    final bg = good == true ? AppColors.correctSoft : good == false ? AppColors.wrongSoft : kLilac;
    final ink = good == true ? AppColors.correct : good == false ? AppColors.wrong : AppColors.primary;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1, end: 0),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => FractionalTranslation(translation: Offset(0, v), child: child),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: ink)),
            const SizedBox(height: 4),
            Text(line, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}

/// 48 dots, one per lesson, coloured by chapter; the demo lesson glows.
class _CourseDots extends StatelessWidget {
  final int lesson;
  final int total;
  const _CourseDots({required this.lesson, required this.total});

  static const _chapters = [AppColors.primary, AppColors.done, AppColors.accent, AppColors.wrong];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
    child: Column(
      children: [
        for (var row = 0; row < total ~/ 8; row++) ...[
          if (row > 0) const SizedBox(height: 9),
          Row(
            children: [
              for (var col = 0; col < 8; col++) ...[
                if (col > 0) const SizedBox(width: 9),
                Expanded(child: AspectRatio(aspectRatio: 1, child: _dot(row * 8 + col))),
              ],
            ],
          ),
        ],
      ],
    ),
  );

  Widget _dot(int i) => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i + 1 == lesson
                  ? AppColors.accent
                  : _chapters[(i * 4 ~/ total).clamp(0, 3)].withValues(alpha: 0.22),
              boxShadow: i + 1 == lesson
                  ? [
                      const BoxShadow(color: AppColors.accent, spreadRadius: 5),
                      BoxShadow(color: tint(AppColors.accent, 0.25), spreadRadius: 3),
                    ]
                  : null,
            ),
          );
}

class _SoftChip extends StatelessWidget {
  final String text;
  const _SoftChip(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryDeep),
    ),
  );
}
