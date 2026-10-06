// screens/age_band_screen.dart
//
// The child's age, changed later from the Parent tab. Built from the same
// pieces as the onboarding age step (the owl asking, the four course cards,
// a chunky button) so the setting looks like the place it was first chosen.
//
// Picking an age picks the course: it saves the age band, an age in years at
// the top of that band (as onboarding does), and the course id, then tells the
// engine, so the next lesson comes from the new course.

import 'package:flutter/material.dart';

import '../curriculum.dart';
import '../engine.dart';
import '../storage.dart';
import '../theme.dart';
import 'onboarding/demo_lessons.dart';
import 'onboarding/onb_kit.dart';
import 'onboarding/story_flow.dart' show AgeCard;

class AgeBandScreen extends StatefulWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const AgeBandScreen({super.key, required this.onNext, this.step, this.total});

  @override
  State<AgeBandScreen> createState() => _AgeBandScreenState();
}

class _AgeBandScreenState extends State<AgeBandScreen> {
  late String _band = Storage.ageBand;
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    const upper = {'a': 6, 'b': 8, 'c': 10, 'd': 12};
    final changed = _band != Storage.ageBand;
    await Storage.setAgeBand(_band);
    if (changed) await Storage.setChildAge(upper[_band]!);
    await Storage.setOnbSubject(demoFor(_band).id);
    Curriculum.invalidate();
    await Engine.setAgeBand(_band);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final child = Storage.childNameOr('your child');
    final course = demoFor(_band);
    final changed = _band != Storage.ageBand;
    return OnbPage(
      top: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.textDark.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.chevron_left_rounded, color: AppColors.textDark),
          ),
        ),
      ),
      content: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Image.asset(Nupo.teacher, width: 84, semanticLabel: 'Nupo'),
            const SizedBox(width: 8),
            Flexible(child: SpeechBubble('How old is $child?')),
          ],
        ),
        const SizedBox(height: 18),
        // Rows, not a GridView: the page body sizes itself to its content.
        for (var r = 0; r < 2; r++) ...[
          if (r > 0) const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < 2; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 0.98,
                    child: AgeCard(
                      course: kDemoCourses[r * 2 + i],
                      selected: _band == kDemoCourses[r * 2 + i].band,
                      onTap: () =>
                          setState(() => _band = kDemoCourses[r * 2 + i].band),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(
            changed
                ? 'Lessons switch to ${course.name}.'
                : '$child is learning ${course.name}.',
            key: ValueKey('$_band$changed'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textMuted,
            ),
          ),
        ),
        const Spacer(),
      ],
      bottom: [
        ChunkyButton(
          label: changed ? 'Switch course' : 'Done',
          arrow: false,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
