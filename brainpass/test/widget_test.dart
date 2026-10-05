// A minimal smoke test. The full app needs Android-only plugins (overlay,
// accessibility) that aren't available in the Flutter test environment, so we
// keep this light and just verify the question generators — pure Dart logic.

import 'package:flutter_test/flutter_test.dart';
import 'package:brainpass/questions.dart';

void main() {
  test('math answers are always integers for every band', () {
    for (final band in Band.values) {
      for (var i = 0; i < 200; i++) {
        final q = generateMath(band);
        expect(
          int.tryParse(q.answer),
          isNotNull,
          reason: 'math answer should be an integer: ${q.prompt}',
        );
      }
    }
  });

  test('pattern "next number" follows the sequence step', () {
    for (final band in Band.values) {
      for (var i = 0; i < 200; i++) {
        final q = generatePattern(band);
        final parts = q.prompt.replaceAll(', ?', '').split(', ');
        final nums = parts.map(int.parse).toList();
        final answer = int.parse(q.answer);
        final differences = [
          for (var i = 1; i < nums.length; i++) nums[i] - nums[i - 1],
        ];
        final doubles = nums
            .skip(1)
            .toList()
            .asMap()
            .entries
            .every((e) => e.value == nums[e.key] * 2);
        if (doubles) {
          expect(answer, nums.last * 2);
        } else if (differences.toSet().length == 1) {
          expect(answer, nums.last + differences.first);
        } else {
          expect(differences, [3, -1, 3, -1]);
          expect(answer, nums.last + 3);
        }
      }
    }
  });

  test('isCorrect treats "07" and "7" as equal', () {
    const q = Question('3 + 4 = ?', '7');
    expect(isCorrect(q, '07'), isTrue);
    expect(isCorrect(q, ' 7 '), isTrue);
    expect(isCorrect(q, '8'), isFalse);
  });
}
