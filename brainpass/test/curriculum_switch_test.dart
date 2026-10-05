import 'package:brainpass/curriculum.dart';
import 'package:brainpass/storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('each saved age band selects its matching complete syllabus', () async {
    SharedPreferences.setMockInitialValues({});
    await Storage.init();

    const expected = {
      'a': ('number_sense', '5-6'),
      'b': ('puzzles_and_logic', '7-8'),
      'c': ('think_like_a_coder', '9–10'),
      'd': ('reasoning', '11-12'),
    };

    for (final entry in expected.entries) {
      await Storage.setAgeBand(entry.key);
      Curriculum.invalidate();
      final syllabus = await Curriculum.load();
      expect(syllabus.band, entry.key);
      expect(syllabus.id, entry.value.$1);
      expect(syllabus.ages, entry.value.$2);
      expect(syllabus.ladder.length, 48);
    }
  });
}
