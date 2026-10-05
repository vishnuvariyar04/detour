// screens/roadmap_screen.dart
//
// The shared screen. A child sees how far up the skill they have climbed and
// what the next stop is; a parent sees the same thing plus the week, which is
// the whole promise of the product made visible: play time bought a specific
// piece of learning, and here it is.
//
// October 2026 redesign, in the onboarding's language (chunky ledged shapes,
// the mascot, purple + amber): a greeting, an "Up next" hero for the stop the
// gate serves next, three stat tiles, the week, the apps, then the path itself
// as a winding trail of nodes — one long scroll, because progress you can
// scroll back down through reads as distance travelled.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../curriculum.dart';
import '../engine.dart';
import '../safe_apps.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets.dart';
import 'onboarding/onb_kit.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen>
    with WidgetsBindingObserver {
  Curriculum? _skill;
  LearningProgress _progress = const LearningProgress();
  final Map<String, AppStatus?> _status = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The gate runs while this screen is backgrounded, so what it recorded only
    // shows up when the parent comes back to the app.
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      await _loadInner();
    } catch (e) {
      // A failed load used to leave the spinner up forever with nothing in the
      // log; showing the failure at least says the screen is not just slow.
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _loadInner() async {
    await Storage.fresh();
    final skill = await Curriculum.load();
    final progress = await LearningProgress.load();
    // The child is allowed to SEE what is gated and how long is left; the
    // numbers come straight from the native engine, same as the parent tab.
    final status = <String, AppStatus?>{};
    for (final pkg in Storage.gatedApps) {
      status[pkg] = await Engine.appStatus(pkg);
    }
    if (!mounted) return;
    setState(() {
      _skill = skill;
      _progress = progress;
      _status
        ..clear()
        ..addAll(status);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final skill = _skill;
    return ColoredBox(
      color: AppColors.primarySoft,
      child: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'The skill path could not load. $_error',
                  textAlign: TextAlign.center,
                  style: AppText.body,
                ),
              ),
            )
          : _loading || skill == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Greeting(skill: skill, progress: _progress),
                  ),
                  SliverToBoxAdapter(
                    child: _UpNextCard(
                      skill: skill,
                      progress: _progress,
                      onTap: _showStop,
                    ),
                  ),
                  if (Storage.ageBand.toLowerCase().compareTo(
                        skill.band.toLowerCase(),
                      ) <
                      0)
                    SliverToBoxAdapter(child: _BandNote(skill: skill)),
                  SliverToBoxAdapter(child: _StatTiles(progress: _progress)),
                  SliverToBoxAdapter(child: _WeekCard(progress: _progress)),
                  SliverToBoxAdapter(child: _AppsCard(status: _status)),
                  for (var s = 0; s < skill.sections.length; s++) ...[
                    SliverToBoxAdapter(
                      child: _SectionBanner(
                        section: skill.sections[s],
                        tone: _toneFor(s),
                        done: skill.sections[s].stops
                            .where(
                              (st) =>
                                  stateOf(skill, st, _progress) ==
                                  StopState.done,
                            )
                            .length,
                      ),
                    ),
                    for (final unit in skill.sections[s].units)
                      SliverToBoxAdapter(
                        child: _UnitTrail(
                          unit: unit,
                          skill: skill,
                          progress: _progress,
                          tone: _toneFor(s),
                          onTap: _showStop,
                        ),
                      ),
                  ],
                  const SliverToBoxAdapter(child: _PathEnd()),
                ],
              ),
            ),
    );
  }

  void _showStop(Stop stop, StopState state) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          _StopSheet(stop: stop, state: state, unit: _unitOf(_skill!, stop)),
    );
  }
}

// ---------------------------------------------------------------- helpers

/// Each section gets its own colour so the path reads in chapters. Amber is
/// held back for "current" and rewards, so it never appears here.
class _Tone {
  final Color face;
  final Color ledge;
  final Color soft;
  const _Tone(this.face, this.ledge, this.soft);
}

_Tone _toneFor(int i) {
  final base = [AppColors.primary, AppColors.done, AppColors.kidTop][i % 3];
  return _Tone(base, Color.lerp(base, Colors.black, 0.28)!, tint(base, 0.14));
}

Unit? _unitOf(Curriculum skill, Stop stop) {
  for (final s in skill.sections) {
    for (final u in s.units) {
      if (u.stops.any((x) => x.id == stop.id)) return u;
    }
  }
  return null;
}

Stop? _currentStop(Curriculum skill, LearningProgress p) {
  final ladder = skill.ladder;
  if (p.stopsDone < ladder.length) return ladder[p.stopsDone];
  return null;
}

String _childLabel() {
  final n = Storage.childName;
  return n.isEmpty ? 'Your child' : n;
}

// ---------------------------------------------------------------- greeting

class _Greeting extends StatelessWidget {
  final Curriculum skill;
  final LearningProgress progress;
  const _Greeting({required this.skill, required this.progress});

  @override
  Widget build(BuildContext context) {
    final name = _childLabel();
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${skill.name.toUpperCase()}  ·  AGES ${skill.ages}',
                  style: OnbText.eyebrow,
                ),
                const SizedBox(height: 6),
                Text(
                  name == 'Your child' ? 'The learning path' : "$name's path",
                  style: OnbText.title,
                ),
              ],
            ),
          ),
          _StreakBadge(days: progress.streak),
        ],
      ),
    );
  }
}

/// The flame and the day count, like the streak counter in a language app.
/// Grey until the first day, so it never looks like a reward not yet earned.
class _StreakBadge extends StatelessWidget {
  final int days;
  const _StreakBadge({required this.days});

  @override
  Widget build(BuildContext context) {
    final lit = days > 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 13, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: lit ? AppColors.accent : AppColors.cardBorder,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Symbols.local_fire_department_rounded,
            size: 22,
            color: lit ? const Color(0xFFFF8A00) : AppColors.textMuted,
          ),
          const SizedBox(width: 4),
          Text(
            '$days',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: lit ? AppColors.textDark : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- up next

/// The one thing that matters on this screen: what the next learning moment
/// will be. Purple, with the teacher owl leaning in from the corner.
class _UpNextCard extends StatelessWidget {
  final Curriculum skill;
  final LearningProgress progress;
  final void Function(Stop, StopState) onTap;
  const _UpNextCard({
    required this.skill,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stop = _currentStop(skill, progress);
    final unit = stop == null ? null : _unitOf(skill, stop);
    final done = progress.stopsDone;
    final total = skill.totalStops;
    final finished = stop == null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: GestureDetector(
        onTap: stop == null ? null : () => onTap(stop, StopState.current),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primaryDeep,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.only(bottom: 5),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryBright, AppColors.primary],
              ),
            ),
            child: Stack(
              children: [
                // Soft discs for depth, like the onboarding sky.
                Positioned(
                  right: -40,
                  top: -50,
                  child: _Disc(170, Colors.white.withValues(alpha: 0.08)),
                ),
                Positioned(
                  right: 30,
                  bottom: -70,
                  child: _Disc(130, Colors.white.withValues(alpha: 0.06)),
                ),
                Positioned(
                  right: 6,
                  bottom: 46,
                  child: Image.asset(
                    finished ? Nupo.trophy : Nupo.teacher,
                    width: 104,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          finished
                              ? 'SKILL COMPLETE'
                              : stop.boss
                              ? 'BOSS STOP'
                              : 'UP NEXT${unit == null ? '' : '  ·  UNIT ${unit.n}'}',
                          style: const TextStyle(
                            fontSize: 10.5,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(right: 104),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              finished ? 'Every stop done' : stop.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 25,
                                height: 1.1,
                                letterSpacing: -0.4,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              finished
                                  ? 'Stops come back as quick reviews.'
                                  : stop.teach.isNotEmpty
                                  ? stop.teach
                                  : 'Asked the next time an app opens.',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: total == 0 ? 0 : done / total,
                                minHeight: 10,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.accent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$done / $total',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  final double size;
  final Color color;
  const _Disc(this.size, this.color);

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// The gate refuses to serve a skill written above the child's band
/// (Curriculum.skillFor), so say why the path is not moving rather than
/// leaving a roadmap that never fills in.
class _BandNote extends StatelessWidget {
  final Curriculum skill;
  const _BandNote({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(
              Symbols.info_rounded,
              size: 20,
              color: AppColors.accentDeep,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Written for ages ${skill.ages}. Easier questions come first '
                'for now.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentDeep,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- stats

class _StatTiles extends StatelessWidget {
  final LearningProgress progress;
  const _StatTiles({required this.progress});

  @override
  Widget build(BuildContext context) {
    final week = progress.week.fold<int>(0, (a, b) => a + b);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: _Tile(
              icon: Symbols.bolt_rounded,
              color: AppColors.primary,
              value: '${progress.answeredToday}',
              label: 'Today',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Tile(
              icon: Symbols.quiz_rounded,
              color: AppColors.kidTop,
              value: '$week',
              label: 'This week',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Tile(
              icon: Symbols.target_rounded,
              color: AppColors.correct,
              value: progress.accuracy == null ? '—' : '${progress.accuracy}%',
              label: 'Correct',
            ),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _Tile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: _cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tint(color, 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              height: 1,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// White card with the onboarding's 2px lilac border and a short ledge.
BoxDecoration _cardBox({double radius = 20}) => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: AppColors.cardBorder, width: 2),
  boxShadow: [
    BoxShadow(
      color: AppColors.cardBorder,
      blurRadius: 0,
      offset: const Offset(0, 3),
    ),
  ],
);

// ---------------------------------------------------------------- week

/// The week at a glance: the thing a parent is actually buying.
class _WeekCard extends StatelessWidget {
  final LearningProgress progress;
  const _WeekCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final week = progress.week;
    final peak = week.fold<int>(1, math.max);
    final today = DateTime.now();
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        decoration: _cardBox(radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('This week', style: AppText.cardTitle),
                const Spacer(),
                Text(
                  'questions a day',
                  style: AppText.caption.copyWith(fontSize: 11.5),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 7; i++)
                    Expanded(
                      child: _DayBar(
                        value: week.length > i ? week[i] : 0,
                        peak: peak,
                        // The bars run oldest to newest, ending today.
                        label: names[(today.weekday - 1 - (6 - i) + 7) % 7],
                        today: i == 6,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  final int value;
  final int peak;
  final String label;
  final bool today;
  const _DayBar({
    required this.value,
    required this.peak,
    required this.label,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final h = value == 0 ? 8.0 : 10 + 56 * (value / peak);
    final color = value == 0
        ? AppColors.line
        : today
        ? AppColors.accent
        : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (value > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: today ? AppColors.accentDeep : AppColors.primaryDeep,
                ),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            height: h,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 7),
          Container(
            width: 24,
            height: 20,
            alignment: Alignment.center,
            decoration: today
                ? BoxDecoration(
                    color: AppColors.textDark,
                    borderRadius: BorderRadius.circular(7),
                  )
                : null,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: today ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- apps

/// What is gated and how long is left on each one.
///
/// This sits on the shared screen on purpose. A child who can see "YouTube, 12
/// minutes left" knows where they stand without asking, and knowing is what
/// makes the rule feel like a rule rather than an ambush. Nothing here is
/// tappable: seeing the numbers and changing them are different privileges.
class _AppsCard extends StatelessWidget {
  final Map<String, AppStatus?> status;
  const _AppsCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final apps = Storage.gatedApps;
    if (apps.isEmpty) return const SizedBox.shrink();
    final rules = Storage.appRules;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        decoration: _cardBox(radius: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Play time', style: AppText.cardTitle),
                const Spacer(),
                const Icon(
                  Symbols.visibility_rounded,
                  size: 15,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  'View only',
                  style: AppText.caption.copyWith(fontSize: 11.5),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < apps.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              _AppTimeRow(
                package: apps[i],
                status: status[apps[i]],
                rule: rules[apps[i]] ?? const AppRule(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AppTimeRow extends StatelessWidget {
  final String package;
  final AppStatus? status;
  final AppRule rule;
  const _AppTimeRow({
    required this.package,
    required this.status,
    required this.rule,
  });

  @override
  Widget build(BuildContext context) {
    final rem = status?.remMinutes ?? 0;
    final unlocked = rem > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          AppBrandIcon(package, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayNameFor(package),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${rule.questions} questions for ${rule.minutes} min',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: unlocked ? AppColors.correctSoft : kLilac,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  unlocked ? Symbols.timer_rounded : Symbols.lock_rounded,
                  size: 15,
                  color: unlocked ? AppColors.correct : AppColors.primaryDeep,
                ),
                const SizedBox(width: 5),
                Text(
                  unlocked ? '$rem min left' : 'Lesson first',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: unlocked ? AppColors.correct : AppColors.primaryDeep,
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

// ---------------------------------------------------------------- path

class _SectionBanner extends StatelessWidget {
  final Section section;
  final _Tone tone;
  final int done;
  const _SectionBanner({
    required this.section,
    required this.tone,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final total = section.stops.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
      child: Container(
        decoration: BoxDecoration(
          color: tone.ledge,
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.only(bottom: 4),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 14, 16),
          decoration: BoxDecoration(
            color: tone.face,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SECTION ${section.n}',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      section.title,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    if (section.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        section.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Ring(
                value: total == 0 ? 0 : done / total,
                label: '$done/$total',
                track: Colors.white.withValues(alpha: 0.22),
                fill: Colors.white,
                ink: Colors.white,
                size: 54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small progress ring with its count in the middle.
class _Ring extends StatelessWidget {
  final double value;
  final String label;
  final Color track;
  final Color fill;
  final Color ink;
  final double size;
  const _Ring({
    required this.value,
    required this.label,
    required this.track,
    required this.fill,
    required this.ink,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: value.clamp(0.0, 1.0),
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
              backgroundColor: track,
              valueColor: AlwaysStoppedAnimation(fill),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// One unit: a divider label, then its stops on a winding trail. The trail is
/// painted behind the nodes, coloured up to the last finished stop.
class _UnitTrail extends StatelessWidget {
  final Unit unit;
  final Curriculum skill;
  final LearningProgress progress;
  final _Tone tone;
  final void Function(Stop, StopState) onTap;

  const _UnitTrail({
    required this.unit,
    required this.skill,
    required this.progress,
    required this.tone,
    required this.onTap,
  });

  static const _rowH = 116.0;
  static const _node = 70.0;

  @override
  Widget build(BuildContext context) {
    final states = [for (final s in unit.stops) stateOf(skill, s, progress)];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
          child: Row(
            children: [
              const Expanded(child: Divider(thickness: 2, height: 2)),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250),
                child: Text(
                  'Unit ${unit.n}  ·  ${unit.title}',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(child: Divider(thickness: 2, height: 2)),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            // A repeating swing: centre, right, centre, left.
            double x(int i) => w / 2 + math.sin(i * math.pi / 2) * w * 0.2;
            final pts = [
              for (var i = 0; i < unit.stops.length; i++)
                Offset(x(i), i * _rowH + _node / 2),
            ];
            final lastDone = states.lastIndexWhere((s) => s == StopState.done);
            final current = states.indexOf(StopState.current);
            return SizedBox(
              height: unit.stops.length * _rowH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TrailPainter(
                        points: pts,
                        doneUpTo: current >= 0 ? current : lastDone,
                        done: tone.face,
                        todo: AppColors.cardBorder,
                      ),
                    ),
                  ),
                  if (current >= 0)
                    Positioned(
                      // The owl waits on the far side of the current stop.
                      left: pts[current].dx > w / 2 + 1
                          ? pts[current].dx - _node / 2 - 104
                          : pts[current].dx + _node / 2 + 18,
                      top: pts[current].dy - 44,
                      child: Image.asset(Nupo.focused, width: 86),
                    ),
                  for (var i = 0; i < unit.stops.length; i++)
                    Positioned(
                      left: pts[i].dx - 80,
                      top: pts[i].dy - _node / 2,
                      width: 160,
                      child: _StopNode(
                        stop: unit.stops[i],
                        state: states[i],
                        tone: tone,
                        progress:
                            states[i] == StopState.current &&
                                unit.stops[i].questions > 0
                            ? progress.questionIndex / unit.stops[i].questions
                            : null,
                        onTap: onTap,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TrailPainter extends CustomPainter {
  final List<Offset> points;
  final int doneUpTo;
  final Color done;
  final Color todo;
  _TrailPainter({
    required this.points,
    required this.doneUpTo,
    required this.done,
    required this.todo,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i + 1 < points.length; i++) {
      final a = points[i];
      final b = points[i + 1];
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx, a.dy + 50, b.dx, b.dy - 50, b.dx, b.dy);
      final reached = i < doneUpTo;
      final paint = Paint()
        ..color = reached ? done.withValues(alpha: 0.45) : todo
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      if (reached) {
        canvas.drawPath(path, paint);
      } else {
        // Not walked yet: dotted, like a trail on a map.
        for (final m in path.computeMetrics()) {
          for (var d = 0.0; d < m.length; d += 18) {
            final p = m.getTangentForOffset(d)!.position;
            canvas.drawCircle(p, 4.2, paint..style = PaintingStyle.fill);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.points != points || old.doneUpTo != doneUpTo || old.done != done;
}

class _StopNode extends StatelessWidget {
  final Stop stop;
  final StopState state;
  final _Tone tone;
  final double? progress;
  final void Function(Stop, StopState) onTap;

  const _StopNode({
    required this.stop,
    required this.state,
    required this.tone,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final current = state == StopState.current;
    final done = state == StopState.done;
    final soon = state == StopState.soon;
    const size = _UnitTrail._node;

    final (Color face, Color ledge) = done
        ? (tone.face, tone.ledge)
        : current
        ? (AppColors.accent, kAmberLedge)
        : (Colors.white, AppColors.cardBorder);
    final icon = done
        ? (stop.boss ? Symbols.trophy_rounded : Symbols.check_rounded)
        : current
        ? (stop.boss ? Symbols.trophy_rounded : Symbols.star_rounded)
        : stop.boss
        ? Symbols.trophy_rounded
        : soon
        ? Symbols.more_horiz_rounded
        : Symbols.lock_rounded;
    final ink = done
        ? Colors.white
        : current
        ? AppColors.textDark
        : AppColors.textMuted.withValues(alpha: soon ? 0.4 : 0.7);

    Widget node = SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            top: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(color: ledge, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: size - 6,
            child: Container(
              decoration: BoxDecoration(
                color: face,
                shape: BoxShape.circle,
                border: !done && !current
                    ? Border.all(color: AppColors.cardBorder, width: 2.5)
                    : null,
              ),
              child: Icon(
                icon,
                size: stop.boss ? 32 : 30,
                color: ink,
                weight: 700,
              ),
            ),
          ),
        ],
      ),
    );

    if (current) {
      // A progress ring around the current stop, as far as the child has got
      // through its questions.
      node = SizedBox(
        width: size + 20,
        height: size + 20,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: (progress ?? 0).clamp(0.0, 1.0),
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.white,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
            node,
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => onTap(stop, state),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: Offset(0, current ? -10 : 0),
            child: node,
          ),
          SizedBox(height: current ? 0 : 6),
          if (current)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.textDark,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                stop.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            )
          else
            // A pill in the page colour, so the trail passes behind the
            // label instead of through it.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                stop.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: done ? FontWeight.w900 : FontWeight.w800,
                  color: done
                      ? AppColors.textDark
                      : AppColors.textMuted.withValues(alpha: soon ? 0.5 : 0.9),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PathEnd extends StatelessWidget {
  const _PathEnd();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      child: Column(
        children: [
          Image.asset(Nupo.trophy, width: 110),
          const SizedBox(height: 8),
          const Text(
            'The end of this skill',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- sheet

class _StopSheet extends StatelessWidget {
  final Stop stop;
  final StopState state;
  final Unit? unit;
  const _StopSheet({required this.stop, required this.state, this.unit});

  @override
  Widget build(BuildContext context) {
    final (badge, badgeColor, badgeBg) = switch (state) {
      StopState.done => ('Completed', AppColors.correct, AppColors.correctSoft),
      StopState.current => ('Up next', AppColors.textDark, AppColors.accent),
      StopState.locked => ('Locked', AppColors.textMuted, AppColors.line),
      StopState.soon => ('Coming soon', AppColors.textMuted, AppColors.line),
    };
    final mascot = switch (state) {
      StopState.done => Nupo.cheer,
      StopState.current => Nupo.idea,
      _ => Nupo.focused,
    };

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _SheetChip(badge.toUpperCase(), badgeColor, badgeBg),
                          if (stop.boss)
                            _SheetChip(
                              'BOSS',
                              AppColors.accentDeep,
                              AppColors.accentSoft,
                            ),
                          if (unit != null)
                            _SheetChip(
                              'UNIT ${unit!.n}',
                              AppColors.primaryDeep,
                              kLilac,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(stop.title, style: OnbText.titleSm),
                    ],
                  ),
                ),
                Image.asset(mascot, width: 84),
              ],
            ),
            if (stop.teach.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.cardBorder, width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Symbols.lightbulb_rounded,
                      size: 20,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        stop.teach,
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Symbols.quiz_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  stop.authored
                      ? '${stop.questions} questions'
                      : 'Puzzles are being written',
                  style: AppText.caption.copyWith(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              state == StopState.current
                  ? 'Nupo asks this the next time an app opens.'
                  : state == StopState.done
                  ? 'Done. It comes back later as a quick review.'
                  : 'Unlocks once the stops before it are finished.',
              style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 18),
            ChunkyButton(
              label: 'Got it',
              arrow: false,
              tone: state == StopState.current ? Chunky.amber : Chunky.purple,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetChip extends StatelessWidget {
  final String text;
  final Color ink;
  final Color bg;
  const _SheetChip(this.text, this.ink, this.bg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w900,
        color: ink,
      ),
    ),
  );
}
