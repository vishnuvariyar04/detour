// screens/roadmap_screen.dart
//
// The shared screen. A child sees how far up the skill they have climbed and
// what the next stop is; a parent sees the same thing plus the week, which is
// the whole promise of the product made visible: play time bought a specific
// piece of learning, and here it is.
//
// The path is deliberately one long scroll rather than a dashboard. Progress
// you can scroll back down through reads as distance travelled.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../curriculum.dart';
import '../engine.dart';
import '../safe_apps.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets.dart';

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
    return Container(
      decoration: AppColors.bgDecoration(),
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
                    child: _Header(skill: skill, progress: _progress),
                  ),
                  SliverToBoxAdapter(child: _AppsCard(status: _status)),
                  for (final section in skill.sections) ...[
                    SliverToBoxAdapter(child: _SectionBanner(section: section)),
                    for (final unit in section.units)
                      SliverToBoxAdapter(
                        child: _UnitPath(
                          unit: unit,
                          skill: skill,
                          progress: _progress,
                          onTap: _showStop,
                        ),
                      ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                ],
              ),
            ),
    );
  }

  void _showStop(Stop stop, StopState state) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _StopSheet(stop: stop, state: state),
    );
  }
}

// ---------------------------------------------------------------- header

class _Header extends StatelessWidget {
  final Curriculum skill;
  final LearningProgress progress;
  const _Header({required this.skill, required this.progress});

  @override
  Widget build(BuildContext context) {
    final done = progress.stopsDone;
    final total = skill.totalStops;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'SKILL',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryDeep,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Ages ${skill.ages}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(skill.name, style: AppText.title),
          const SizedBox(height: 8),
          Text(skill.promise, style: AppText.body),
          const SizedBox(height: 18),

          // Overall climb
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 10,
              backgroundColor: AppColors.line,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$done of $total stops',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 18),
          // The gate refuses to serve a skill written above the child's band
          // (Curriculum.skillFor), so say why the path is not moving rather
          // than leaving a roadmap that never fills in.
          if (Storage.ageBand.toLowerCase().compareTo(skill.band.toLowerCase()) < 0) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent, width: 1.5),
              ),
              child: Text(
                'This skill is written for ages ${skill.ages}. Nupo is asking '
                'your child easier questions for now — their own skill path is '
                'on the way.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentDeep,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _WeekCard(progress: progress),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

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

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
        decoration: AppColors.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Your apps', style: AppText.cardTitle),
                const Spacer(),
                Icon(
                  Symbols.visibility_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                const Text(
                  'View only',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final pkg in apps)
              _AppTimeRow(package: pkg, status: status[pkg]),
          ],
        ),
      ),
    );
  }
}

class _AppTimeRow extends StatelessWidget {
  final String package;
  final AppStatus? status;
  const _AppTimeRow({required this.package, required this.status});

  @override
  Widget build(BuildContext context) {
    final rem = status?.remMinutes ?? 0;
    final unlocked = rem > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          AppBrandIcon(package, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayNameFor(package),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: unlocked ? AppColors.correctSoft : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  unlocked ? Symbols.timer_rounded : Symbols.lock_rounded,
                  size: 14,
                  color: unlocked ? AppColors.correct : AppColors.primaryDeep,
                ),
                const SizedBox(width: 5),
                Text(
                  unlocked ? '$rem min left' : 'Locked',
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

/// The week at a glance: the thing a parent is actually buying.
class _WeekCard extends StatelessWidget {
  final LearningProgress progress;
  const _WeekCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final week = progress.week;
    final total = week.fold<int>(0, (a, b) => a + b);
    final peak = week.fold<int>(1, math.max);
    final today = DateTime.now();
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: AppColors.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('This week', style: AppText.cardTitle),
              const Spacer(),
              if (progress.streak > 0) ...[
                const Icon(
                  Symbols.local_fire_department_rounded,
                  size: 18,
                  color: AppColors.accentDeep,
                ),
                const SizedBox(width: 4),
                Text(
                  '${progress.streak} day${progress.streak == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accentDeep,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            // Tall enough for the largest bar (6 + 40) plus the gap and the
            // day label underneath it.
            height: 78,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 6 + 40 * (week.length > i ? week[i] / peak : 0),
                            decoration: BoxDecoration(
                              color: (week.length > i && week[i] > 0)
                                  ? AppColors.primary
                                  : AppColors.line,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            // The bars run oldest to newest, ending today.
                            names[(today.weekday - 1 - (6 - i) + 7) % 7],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(label: 'Questions', value: '$total'),
              const SizedBox(width: 20),
              _Stat(
                label: 'Correct',
                value: progress.accuracy == null ? '—' : '${progress.accuracy}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- path

class _SectionBanner extends StatelessWidget {
  final Section section;
  const _SectionBanner({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryBright],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SECTION ${section.n}',
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 1.3,
                fontWeight: FontWeight.w900,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              section.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              section.subtitle,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One unit's stops, laid out as a gentle zig-zag so the eye follows a path
/// rather than reading a list.
class _UnitPath extends StatelessWidget {
  final Unit unit;
  final Curriculum skill;
  final LearningProgress progress;
  final void Function(Stop, StopState) onTap;

  const _UnitPath({
    required this.unit,
    required this.skill,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 2),
          child: Text(
            'Unit ${unit.n} · ${unit.title}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.textMuted,
            ),
          ),
        ),
        for (var i = 0; i < unit.stops.length; i++)
          _StopNode(
            stop: unit.stops[i],
            state: stateOf(skill, unit.stops[i], progress),
            // A repeating swing, offset by the stop's place in the unit.
            offset: math.sin(i * math.pi / 2) * 46,
            onTap: onTap,
          ),
      ],
    );
  }
}

class _StopNode extends StatelessWidget {
  final Stop stop;
  final StopState state;
  final double offset;
  final void Function(Stop, StopState) onTap;

  const _StopNode({
    required this.stop,
    required this.state,
    required this.offset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final current = state == StopState.current;
    final done = state == StopState.done;
    final soon = state == StopState.soon;

    final face = done
        ? AppColors.primary
        : current
            ? AppColors.accent
            : Colors.white;
    final ledge = done
        ? AppColors.primaryDeep
        : current
            ? AppColors.accentDeep
            : AppColors.line;
    final icon = done
        ? Symbols.check_rounded
        : current
            ? (stop.boss ? Symbols.trophy_rounded : Symbols.play_arrow_rounded)
            : soon
                ? Symbols.more_horiz_rounded
                : Symbols.lock_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Transform.translate(
        offset: Offset(offset, 0),
        child: Center(
          child: GestureDetector(
            onTap: () => onTap(stop, state),
            child: Column(
              children: [
                // The node itself: a face on a ledge, matching the gate's
                // buttons so the app and the learning moment feel like one thing.
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    color: ledge,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 66,
                    height: 61,
                    decoration: BoxDecoration(
                      color: face,
                      shape: BoxShape.circle,
                      border: soon
                          ? Border.all(color: AppColors.line, width: 2)
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: done || current
                          ? Colors.white
                          : AppColors.textMuted.withValues(alpha: soon ? 0.5 : 1),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 150,
                  child: Text(
                    stop.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.2,
                      fontWeight: current ? FontWeight.w900 : FontWeight.w700,
                      color: soon
                          ? AppColors.textMuted.withValues(alpha: 0.55)
                          : current
                              ? AppColors.textDark
                              : AppColors.textMuted,
                    ),
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

// ---------------------------------------------------------------- sheet

class _StopSheet extends StatelessWidget {
  final Stop stop;
  final StopState state;
  const _StopSheet({required this.stop, required this.state});

  @override
  Widget build(BuildContext context) {
    final (badge, badgeColor) = switch (state) {
      StopState.done => ('Completed', AppColors.correct),
      StopState.current => ('Up next', AppColors.accentDeep),
      StopState.locked => ('Locked', AppColors.textMuted),
      StopState.soon => ('Coming soon', AppColors.textMuted),
    };

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: AppColors.cardDecoration(radius: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w900,
                      color: badgeColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (stop.boss)
                  const Icon(
                    Symbols.trophy_rounded,
                    size: 20,
                    color: AppColors.accentDeep,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(stop.title, style: AppText.title),
            if (stop.teach.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(stop.teach, style: AppText.body),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Symbols.help_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  stop.authored
                      ? '${stop.questions} questions'
                      : 'Puzzles are being written',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              state == StopState.current
                  ? 'This is what Nupo asks next time an app is opened.'
                  : state == StopState.done
                      ? 'Done. It comes back later as a quick review.'
                      : 'Unlocks once the stops before it are finished.',
              style: AppText.caption,
            ),
          ],
        ),
      ),
    );
  }
}
