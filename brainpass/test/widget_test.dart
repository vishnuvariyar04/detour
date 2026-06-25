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
        expect(int.tryParse(q.answer), isNotNull,
            reason: 'math answer should be an integer: ${q.prompt}');
      }
    }
  });

  test('pattern "next number" follows the sequence step', () {
    for (final band in Band.values) {
      for (var i = 0; i < 200; i++) {
        final q = generatePattern(band);
        final parts = q.prompt.replaceAll(', ?', '').split(', ');
        final nums = parts.map(int.parse).toList();
        final step = nums[1] - nums[0];
        expect(int.parse(q.answer), nums.last + step);
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
