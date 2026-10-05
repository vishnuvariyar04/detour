// The onboarding sells each age band a course by showing one real lesson from
// it. These tests re-read the curriculum assets and fail if the demo, the
// lesson numbers or the course counts drift from what a child is served.

import 'dart:convert';
import 'dart:io';

import 'package:brainpass/screens/onboarding/demo_lessons.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _course(String id) =>
    jsonDecode(File('assets/curriculum/$id.json').readAsStringSync())
        as Map<String, dynamic>;

List<Map<String, dynamic>> _stops(Map<String, dynamic> c) => [
  for (final s in c['sections'] as List)
    for (final u in (s as Map)['units'] as List)
      for (final st in (u as Map)['stops'] as List) st as Map<String, dynamic>,
];

void main() {
  for (final demo in kDemoCourses) {
    group('${demo.name} (band ${demo.band})', () {
      final json = _course(demo.id);
      final stops = _stops(json);
      final stop = stops.firstWhere((s) => s['id'] == demo.stopId);
      final questions = (stop['questions'] as List).cast<Map<String, dynamic>>();

      test('course facts match the asset', () {
        expect(json['name'], demo.name);
        expect((json['band'] as String).toLowerCase(), demo.band);
        expect((json['ages'] as String).replaceAll('-', '–'), demo.ages);
        expect(stops.length, demo.lessons);
        final total = stops.fold<int>(0, (n, s) => n + (s['questions'] as List).length);
        expect(total, demo.questions);
      });

      test('the demo is that lesson, at that position', () {
        expect(stop['title'], demo.stop);
        expect(stops.indexOf(stop) + 1, demo.lesson);
        expect((stop['teach'] as Map)['line'], demo.teach);
      });

      test('the question shown is in the lesson, with that answer', () {
        bool found;
        switch (demo.band) {
          case 'a':
            found = questions.any((q) =>
                q['shape'] == 'tenFrame' &&
                (q['pic'] as Map)['filled'] == 7 &&
                (q['answer'] as Map)['value'] == int.parse(demo.answer));
          case 'b':
            found = questions.any((q) {
              final pic = q['pic'] as Map;
              final opts = (q['optionsText'] as List?) ?? const [];
              final idx = (q['answer'] as Map)['value'] as int;
              return pic['word'] == '2 5 4' &&
                  pic['mode'] == 'decode' &&
                  opts[idx] == demo.answer &&
                  opts.toSet().containsAll(demo.choices);
            });
          case 'c':
            final teachProgram = ((stop['teach'] as Map)['board'] as Map)['program'];
            expect(teachProgram, ['repeat:2', 'right', 'up', 'end']);
            found = questions.any((q) {
              final v = q['visual'] as Map?;
              final a = (q['answer'] as Map)['value'];
              return q['shape'] == 'predict' &&
                  v?['w'] == 5 &&
                  v?['h'] == 5 &&
                  (v?['program'] as List?)?.join(' ') == 'repeat:3 right up end' &&
                  '${(a as List)[0]},${a[1]}' == demo.answer;
            });
          default:
            found = questions.any((q) =>
                q['shape'] == 'binaryRead' &&
                ((q['pic'] as Map)['on'] as List).join() == '1011' &&
                (q['answer'] as Map)['value'] == int.parse(demo.answer));
        }
        expect(found, isTrue, reason: 'demo question not found in ${demo.stopId}');
      });

      test('the parent-facing copy is complete', () {
        expect(demo.outcomes, hasLength(4));
        expect(demo.path, hasLength(4));
        if (demo.kind != DemoKind.cell) expect(demo.choices, contains(demo.answer));
      });
    });
  }
}
