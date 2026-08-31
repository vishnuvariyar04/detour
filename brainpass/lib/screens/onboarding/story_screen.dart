// screens/onboarding/story_screen.dart — the scroll-story onboarding.
//
// The parent taps "Get started" once and then scrolls; the story carries no
// buttons at all until the closing CTA. Eight beats:
//
//   1  hero          "Learning they'll actually do"      (tapped, not scrolled)
//   2  recognition   "They grab the phone the second they're bored."
//   3  the question  "What if they had to earn it — with 30 seconds…"
//   4  the answer    "That's Nupo."
//   5  app picker    "Which app do they open the most?"   ← must pick to go on
//   6  the loop      tap → shield → "Earn time" → question ← must answer
//   7  the payoff    "Nice! YouTube's open — 15 mins."
//   8  the close     2-min setup · No ads · You set the rules
//
// ## How the scroll works
//
// Position in the story is one number, `t`, in units of viewport-heights:
// `t = scrollOffset / viewportHeight + 1`, so beat N sits at `t == N` and the
// whole story is 7.6 screens of scroll. Every beat is a full-bleed layer
// stacked in one sticky frame; `_layer` fades and drifts each one in and out
// around its own `t`, so the beats cross-dissolve rather than page. The gaps
// between cross-fades are deliberate — that is where `_Sky` shows through, and
// why the sky has its own colour timeline.
//
// These numbers (the fades, the easings, the bird's flight path, the sky
// stops) are the design's own, from `ui-ux/design/support.js`. Keeping them
// verbatim is what makes this the designed story rather than an impression of
// it. See `story_beats.dart` for the departures forced by `CLAUDE.md` (one
// palette; Nunito only).
//
// ## The two gates
//
// The story will not scroll past the picker until an app is picked, or past
// the phone until the question is answered. Rather than fight the scroll
// physics by yanking the offset back, the scrollable is simply only as tall as
// the current gate allows — the parent hits a natural end-of-scroll, and the
// remaining story grows in behind them once they act.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../analytics.dart';
import '../../storage.dart';
import '../../theme.dart';
import 'story_beats.dart';
import 'story_phone.dart';

// --- the timeline, in beats -------------------------------------------------

/// The last reachable position: 7.6 screens of scroll (`support.js` clamps
/// `t` to exactly this).
const double _tEnd = 8.6;

/// Scroll offsets, in viewport-heights, that the story will not pass until the
/// parent has acted. `support.js` calls these `gate` and `gate2`.
const double _gatePick = 3.02; // → t 4.02, the picker
const double _gateAnswer = 5.58; // → t 6.58, the question

/// Where the story lands itself once the answer is right — the payoff frame.
const double _unlockRest = 6.14; // → t 7.14

class OnboardingStory extends StatefulWidget {
  /// "I want this for them" — the story is over, on to the questions.
  final VoidCallback onFinished;

  /// "I already have an account · Log in" — a returning parent.
  final VoidCallback onLogIn;

  /// The app they picked in beat 5, so the real picker after the paywall can
  /// have it ticked already.
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
  final _controller = ScrollController();

  bool _started = false;
  StoryApp? _picked;
  bool _shieldTapped = false;
  bool _answered = false;
  int _wrongs = 0;
  int? _lastWrong;

  Timer? _moodTimer;
  Timer? _unlockTimer;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    Analytics.storyShown();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The bird swaps pose mid-scroll and the phone swaps owl mid-question —
    // both flicker on an uncached first paint.
    if (!_precached) {
      _precached = true;
      for (final asset in Nupo.all) {
        precacheImage(AssetImage(asset), context);
      }
    }
  }

  @override
  void dispose() {
    _moodTimer?.cancel();
    _unlockTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// The child's own name once onboarding knows it (a parent who comes back to
  /// the story), otherwise "They". Never a word that names the audience as
  /// children — this flow is what App Store screenshots are taken from
  /// (guideline 2.3.8, `PROJECT_STATUS.md` §3.26).
  String get _childLabel {
    final name = Storage.childName.trim();
    return name.isEmpty ? 'They' : name;
  }

  String get _appName => _picked?.name ?? kStoryApps.first.name;

  /// How far the story may currently be scrolled, in viewport-heights.
  double get _reach {
    if (_picked == null) return _gatePick;
    if (!_answered) return _gateAnswer;
    return _tEnd - 1;
  }

  void _pick(StoryApp app) {
    if (_picked?.name == app.name) return;
    // Gate 1 of the story. Everyone who scrolls past beat 5 passes through
    // here, so it is the cleanest mid-pitch funnel step there is.
    if (_picked == null) Analytics.storyAppPicked(app.name);
    setState(() => _picked = app);
    widget.onAppPicked(app);
  }

  void _earnTime() {
    if (_shieldTapped) return;
    setState(() => _shieldTapped = true);
  }

  void _answer(int value) {
    if (_answered) return;

    if (value != kStoryCorrect) {
      // Wrong answers never cost anything — Nupo reacts, then asks again.
      setState(() {
        _wrongs++;
        _lastWrong = value;
      });
      _moodTimer?.cancel();
      _moodTimer = Timer(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _lastWrong = null);
      });
      return;
    }

    _moodTimer?.cancel();
    // Gate 2. `wrongs` says whether the demo question is pitched right — a
    // parent who needs three goes is being made to feel stupid by the pitch.
    Analytics.storyAnswered(_wrongs);
    setState(() {
      _lastWrong = null;
      _answered = true;
    });

    // Let "Nailed it!" land, then carry them into the payoff. The gate has
    // just opened, so wait for the taller scrollable to be laid out before
    // animating into the part of the story that did not exist a frame ago.
    _unlockTimer = Timer(const Duration(milliseconds: 760), () {
      if (!mounted || !_controller.hasClients) return;
      final vh = _controller.position.viewportDimension;
      _controller.animateTo(
        _unlockRest * vh,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_started,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _started) setState(() => _started = false);
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return Stack(
              children: [
                _buildStory(size),
                // The welcome screen sits on top and dissolves into the story,
                // so the story's first frame is already behind it.
                IgnorePointer(
                  ignoring: _started,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOut,
                    opacity: _started ? 0 : 1,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOut,
                      scale: _started ? 1.04 : 1,
                      child: StoryWelcome(
                        onGetStarted: () {
                          Analytics.storyStarted();
                          setState(() => _started = true);
                        },
                        onLogIn: () {
                          Analytics.storyLoginTapped();
                          widget.onLogIn();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStory(Size size) {
    final vh = size.height;

    return SingleChildScrollView(
      controller: _controller,
      // The gates work by limiting how tall the scrollable is; a bouncing
      // overscroll would let the parent peek past one.
      physics: const ClampingScrollPhysics(),
      child: SizedBox(
        height: vh + _reach * vh,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final offset = _controller.hasClients ? _controller.offset : 0.0;
            final t = 1 + offset / vh;
            return Stack(
              children: [
                Positioned(
                  top: offset,
                  left: 0,
                  right: 0,
                  height: vh,
                  child: _stage(t, size),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _stage(double t, Size size) {
    return Stack(
      children: [
        Positioned.fill(child: _Sky(t: t)),
        _layer(t: t, at: 1, child: BoredBeat(t: t)),
        _layer(t: t, at: 2, child: const EarnItBeat()),
        _layer(t: t, at: 3, child: const ThatsNupoBeat()),
        _layer(
          t: t,
          at: 4,
          child: PickerBeat(picked: _picked, onPick: _pick),
        ),
        _layer(
          t: t,
          at: 6,
          span: 1.7,
          hold: const [4.3, 7.3],
          child: PhoneBeat(
            t: t,
            appName: _appName,
            childLabel: _childLabel,
            shieldTapped: _shieldTapped,
            answered: _answered,
            wrongs: _wrongs,
            lastWrong: _lastWrong,
            onEarnTime: _earnTime,
            onAnswer: _answer,
          ),
        ),
        _layer(
          t: t,
          at: 8.4,
          hold: const [7.57, 99],
          child: CloseBeat(onCta: () {
            Analytics.storyFinished();
            widget.onFinished();
          }),
        ),
        Positioned.fill(child: IgnorePointer(child: _Progress(t: t))),
        Positioned.fill(
          child: IgnorePointer(child: _Bird(t: t, stage: size)),
        ),
      ],
    );
  }

  /// One full-bleed beat, faded and drifted around its own position.
  ///
  /// `support.js`'s `paint()`: a beat rises into full opacity over the 0.5
  /// beats before it arrives, holds briefly, then leaves over the next 0.28.
  /// A `hold` overrides that with an explicit in/out window, which is how the
  /// phone scene stays on screen for three beats.
  Widget _layer({
    required double t,
    required double at,
    double span = 1,
    List<double>? hold,
    required Widget child,
  }) {
    final d = (t - at) / span;
    final ad = d.abs();

    final double opacity;
    if (hold != null) {
      opacity = c01((t - hold[0]) / 0.34) * (1 - c01((t - hold[1]) / 0.26));
    } else if (d < 0) {
      opacity = c01((d + 0.68) / 0.5);
    } else {
      opacity = 1 - c01((d - 0.02) / 0.28);
    }

    return Positioned.fill(
      child: IgnorePointer(
        // A `hold` beat sets its own visibility window, so hit-testing has to
        // follow THAT and not the distance from `at`. The close beat holds
        // from t 7.57 but sits at 8.4, so its CTA painted fully opaque while
        // silently swallowing taps for most of a screen of scroll — it looked
        // like the button was simply broken.
        ignoring: hold != null ? opacity < 0.6 : ad >= 0.45,
        child: Visibility(
          visible: opacity > 0.01,
          maintainState: true,
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, hold != null ? 0 : -d * 46),
              child: Transform.scale(
                scale: hold != null ? 1 : 1 - ad * 0.045,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The sky — what shows in the gap between two cross-fading beats. Its stops
// are the design's, with every colour resolved to an `AppColors` token.
// ---------------------------------------------------------------------------

class _Sky extends StatelessWidget {
  final double t;
  const _Sky({required this.t});

  static final _stops = <(double, Color, Color)>[
    (1.00, AppColors.primarySoft, Colors.white),
    (1.05, AppColors.primarySoft, Colors.white),
    (1.40, AppColors.primary, AppColors.primary),
    (2.05, AppColors.primary, AppColors.primary),
    (2.40, AppColors.bg, Colors.white),
    (3.05, AppColors.bg, Colors.white),
    (3.40, AppColors.primarySoft, AppColors.primarySoft),
    (3.75, AppColors.primarySoft, AppColors.primarySoft),
    (4.05, AppColors.textDark, AppColors.textDark),
    (7.20, AppColors.textDark, AppColors.textDark),
    (7.42, AppColors.primaryBright, AppColors.primary),
    (7.62, AppColors.bg, Colors.white),
  ];

  (Color, Color) _sample() {
    if (t <= _stops.first.$1) return (_stops.first.$2, _stops.first.$3);
    if (t >= _stops.last.$1) return (_stops.last.$2, _stops.last.$3);
    for (var i = 0; i < _stops.length - 1; i++) {
      final (at, a1, a2) = _stops[i];
      final (next, b1, b2) = _stops[i + 1];
      if (t >= at && t <= next) {
        final p = (t - at) / (next - at);
        return (Color.lerp(a1, b1, p)!, Color.lerp(a2, b2, p)!);
      }
    }
    return (_stops.last.$2, _stops.last.$3);
  }

  @override
  Widget build(BuildContext context) {
    final (top, bottom) = _sample();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress — a star travelling the length of the story.
// ---------------------------------------------------------------------------

class _Progress extends StatelessWidget {
  final double t;
  const _Progress({required this.t});

  @override
  Widget build(BuildContext context) {
    final p = c01((t - 1) / 6.6);
    final fade = c01(1 - (t - 7.5) / 0.4);
    // Beats 2 and 5-7 are dark; the track has to invert over them to stay
    // visible at all.
    final onDark = (t >= 1.6 && t <= 2.4) || (t >= 4.6 && t <= 7.5);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, MediaQuery.paddingOf(context).top + 14, 24, 0),
      child: Align(
        alignment: Alignment.topCenter,
        child: Opacity(
          opacity: fade,
          child: StoryProgressBar(progress: p, onDark: onDark),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nupo, following the story. Position, scale, rotation and pose all come off
// one keyframed path, sampled at the current `t`.
// ---------------------------------------------------------------------------

class _BirdKey {
  final double t, x, y, scale, rotation;
  final String pose;
  const _BirdKey(this.t, this.x, this.y, this.scale, this.rotation, this.pose);
}

/// `support.js`'s `PATHS.a`. `x`/`y` are percentages of the stage; `_fly` is
/// resolved to one of the three flapping frames at paint time.
const _flyPose = '_fly';
const _birdPath = <_BirdKey>[
  _BirdKey(0, 50, 30, 1, 0, Nupo.wave),
  _BirdKey(1, 80, 45, 0.48, -6, Nupo.ohno),
  _BirdKey(2, 50, 24, 0.92, 0, Nupo.idea),
  _BirdKey(3, 50, 23, 1, 0, Nupo.cheer),
  _BirdKey(3.5, 86, 35, 0.42, 5, Nupo.idea),
  _BirdKey(4, 86, 35, 0.42, 5, Nupo.idea),
  _BirdKey(5, 16, 20, 0.55, -14, _flyPose),
  _BirdKey(5.6, 50, 44, 0.16, 6, _flyPose),
  _BirdKey(6.1, 50, 48, 0.04, 0, _flyPose),
  _BirdKey(7.0, 50, 48, 0.04, 0, _flyPose),
  _BirdKey(8.4, 50, 24, 1, 0, Nupo.aplus),
];

class _Bird extends StatelessWidget {
  final double t;
  final Size stage;
  const _Bird({required this.t, required this.stage});

  static const _width = 132.0;
  static const _height = _width * 112 / 130; // the sprites' aspect

  @override
  Widget build(BuildContext context) {
    final key = _sample();

    // The bird dives into the phone for the demo and comes back for the close;
    // it also yields to the speech cloud and to the bedroom scene, which each
    // have their own owl in frame.
    final dive = c01((t - 5.95) / 0.25);
    final back = c01((t - 7.1) / 0.35);
    final yieldToCloud = c01(1 - (t - 4.05).abs() / 0.8);
    final yieldToScene = c01(1 - (t - 1.02).abs() / 0.62);
    final opacity =
        c01(((1 - dive) + back) * (1 - yieldToCloud) * (1 - yieldToScene));

    if (opacity <= 0.01) return const SizedBox.shrink();

    var pose = key.pose;
    if (pose == _flyPose) {
      pose = [Nupo.fly1, Nupo.fly2, Nupo.fly3][(t * 9).floor() % 3];
    }

    return Stack(
      children: [
        Positioned(
          left: stage.width * key.x / 100 - _width / 2,
          top: stage.height * key.y / 100 - _height / 2,
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: key.rotation * 0.0174533,
              child: Transform.scale(
                scale: key.scale,
                child: Image.asset(pose, width: _width, excludeFromSemantics: true),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Eased interpolation between the two surrounding keyframes; the pose flips
  /// at the halfway point rather than blending.
  _BirdKey _sample() {
    if (t <= _birdPath.first.t) return _birdPath.first;
    if (t >= _birdPath.last.t) return _birdPath.last;
    for (var i = 0; i < _birdPath.length - 1; i++) {
      final k = _birdPath[i];
      final n = _birdPath[i + 1];
      if (t >= k.t && t <= n.t) {
        final p = easeInOut((t - k.t) / (n.t - k.t));
        return _BirdKey(
          t,
          lerpD(k.x, n.x, p),
          lerpD(k.y, n.y, p),
          lerpD(k.scale, n.scale, p),
          lerpD(k.rotation, n.rotation, p),
          p < 0.5 ? k.pose : n.pose,
        );
      }
    }
    return _birdPath.last;
  }
}
