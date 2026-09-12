// curriculum.dart
//
// The Dart half of the skill curriculum. It reads the SAME JSON assets the
// native gate reads (assets/curriculum/*.json) and picks the skill the same way
// the gate does, so the roadmap a parent scrolls through and the questions a
// child answers can never describe two different curricula.
//
// Progress is NOT stored here. The gate runs inside the accessibility service,
// in another process from this UI, so native owns the cursor and the roadmap
// reads it back over the method channel (Engine.learningProgress).

import 'dart:convert';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;

import 'engine.dart';
import 'storage.dart';

class Curriculum {
  final String id;
  final String name;
  final String band;
  final String ages;
  final String promise;
  final List<Section> sections;

  const Curriculum({
    required this.id,
    required this.name,
    required this.band,
    required this.ages,
    required this.promise,
    required this.sections,
  });

  static const dir = 'assets/curriculum/';
  static Curriculum? _cache;
  static String? _cachedFor;

  static Curriculum _fromJson(Map<String, dynamic> json) => Curriculum(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        // Lowercased here so every comparison downstream is case-safe.
        // Curriculum.kt lowercases too; when this did not, an uppercase
        // "band" in the asset made load() pick a different skill than the
        // gate served, and the roadmap drew a path the child was not on.
        band: (json['band'] as String? ?? '').toLowerCase(),
        ages: json['ages'] as String? ?? '',
        promise: json['promise'] as String? ?? '',
        sections: (json['sections'] as List? ?? [])
            .map((s) => Section.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  /// Every skill shipped with the app.
  ///
  /// Read through [AssetManifest], not by loading AssetManifest.json: current
  /// Flutter ships only AssetManifest.bin, so the old path threw and left the
  /// roadmap spinning forever with nothing in the log to say why.
  static Future<List<Curriculum>> all() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final paths = manifest
        .listAssets()
        .where((k) => k.startsWith(dir) && k.endsWith('.json'))
        .toList()
      ..sort();
    final out = <Curriculum>[];
    for (final path in paths) {
      try {
        out.add(_fromJson(
            jsonDecode(await rootBundle.loadString(path)) as Map<String, dynamic>));
      } catch (_) {
        // One bad file must not cost the roadmap every skill.
      }
    }
    out.sort((a, b) => a.band.compareTo(b.band));
    return out;
  }

  /// The skill this child is on.
  ///
  /// Mirrors Curriculum.skillFor on the native side: the most advanced skill
  /// whose band the child has reached. The gate owns which skill is actually
  /// served, so the roadmap must pick the same one or it would draw a path the
  /// child is not walking.
  static Future<Curriculum> load({String? band}) async {
    final child = (band ?? Storage.ageBand).toLowerCase();
    if (_cache != null && _cachedFor == child) return _cache!;
    final skills = await all();
    final fit = skills.where((s) => s.band.isNotEmpty && child.compareTo(s.band) >= 0);
    final chosen = fit.isNotEmpty
        ? fit.reduce((a, b) => a.band.compareTo(b.band) >= 0 ? a : b)
        : skills.first;
    _cachedFor = child;
    return _cache = chosen;
  }

  /// Every stop, in the order a child meets them.
  List<Stop> get allStops =>
      [for (final s in sections) for (final u in s.units) ...u.stops];

  /// The stops that can actually be played today — the rest are written but
  /// not yet filled in with real puzzles, and the roadmap shows them as such.
  List<Stop> get ladder =>
      allStops.where((s) => s.authored && s.questions > 0).toList();

  int get totalStops => allStops.length;
}

class Section {
  final int n;
  final String title;
  final String subtitle;
  final List<Unit> units;

  const Section({
    required this.n,
    required this.title,
    required this.subtitle,
    required this.units,
  });

  factory Section.fromJson(Map<String, dynamic> j) => Section(
        n: j['n'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        subtitle: j['subtitle'] as String? ?? '',
        units: (j['units'] as List? ?? [])
            .map((u) => Unit.fromJson(u as Map<String, dynamic>))
            .toList(),
      );

  List<Stop> get stops => [for (final u in units) ...u.stops];
}

class Unit {
  final int n;
  final String title;
  final List<Stop> stops;

  const Unit({required this.n, required this.title, required this.stops});

  factory Unit.fromJson(Map<String, dynamic> j) => Unit(
        n: j['n'] as int? ?? 0,
        title: j['title'] as String? ?? '',
        stops: (j['stops'] as List? ?? [])
            .map((s) => Stop.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

class Stop {
  final String id;
  final String title;
  final bool boss;
  final bool authored;
  final String teach;
  final int questions;

  const Stop({
    required this.id,
    required this.title,
    required this.boss,
    required this.authored,
    required this.teach,
    required this.questions,
  });

  factory Stop.fromJson(Map<String, dynamic> j) => Stop(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        boss: j['boss'] as bool? ?? false,
        authored: j['authored'] as bool? ?? false,
        teach: (j['teach'] as Map<String, dynamic>?)?['line'] as String? ?? '',
        questions: (j['questions'] as List? ?? []).length,
      );
}

/// Where the child has reached, read back from the native gate.
class LearningProgress {
  final int stopsDone;
  final int stopsPlayable;
  final String currentStopId;
  final int questionIndex;
  final int asked;
  final int right;
  final int streak;
  final int answeredToday;

  /// Questions answered on each of the last seven days, oldest first.
  final List<int> week;

  const LearningProgress({
    this.stopsDone = 0,
    this.stopsPlayable = 0,
    this.currentStopId = '',
    this.questionIndex = 0,
    this.asked = 0,
    this.right = 0,
    this.streak = 0,
    this.answeredToday = 0,
    this.week = const [0, 0, 0, 0, 0, 0, 0],
  });

  static Future<LearningProgress> load() async {
    try {
      final m = await Engine.learningProgress();
      int i(String k) => (m[k] as num?)?.toInt() ?? 0;
      return LearningProgress(
        stopsDone: i('stopsDone'),
        stopsPlayable: i('stopsPlayable'),
        currentStopId: m['currentStopId'] as String? ?? '',
        questionIndex: i('questionIndex'),
        asked: i('asked'),
        right: i('right'),
        streak: i('streak'),
        answeredToday: i('answeredToday'),
        week: ((m['week'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
      );
    } catch (_) {
      // The channel is unavailable in tests and before the engine starts.
      return const LearningProgress();
    }
  }

  /// Accuracy as a whole percentage, or null before anything was answered.
  int? get accuracy => asked == 0 ? null : ((right / asked) * 100).round();
}

/// How one stop should be drawn on the roadmap.
enum StopState {
  /// Answered every question in it.
  done,

  /// The stop the next gate will serve.
  current,

  /// Written and playable, but not reached yet.
  locked,

  /// Authored in outline only — no puzzles behind it yet.
  soon,
}

StopState stateOf(Curriculum skill, Stop stop, LearningProgress p) {
  final i = skill.ladder.indexWhere((s) => s.id == stop.id);
  if (i < 0) return StopState.soon;
  if (i < p.stopsDone) return StopState.done;
  if (i == p.stopsDone) return StopState.current;
  return StopState.locked;
}
