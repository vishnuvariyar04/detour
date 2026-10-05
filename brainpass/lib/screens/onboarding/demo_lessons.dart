// screens/onboarding/demo_lessons.dart — what each age band is shown.
//
// One entry per course. The demo lesson in the story is a REAL lesson from that
// course: the teach line and the question are copied from the curriculum
// assets, and the idea on the "new idea" screen is exactly the idea the
// question asks about. `test/onboarding_demo_test.dart` re-reads the JSON and
// fails if any of this drifts from the course a child is actually served.
//
// Parent-facing copy (outcomes, path milestones) is written here on purpose:
// the curriculum's own titles are written for children ("Nupo does one step at
// a time") and do not belong on a parent's screen.

import 'package:flutter/material.dart';

import '../../theme.dart';
import 'onb_kit.dart';

enum DemoKind { number, word, cell }

class Outcome {
  final IconData icon;
  final String title;
  final String line;
  const Outcome(this.icon, this.title, this.line);
}

class DemoCourse {
  /// Age band as stored by `Storage.ageBand`.
  final String band;

  /// The curriculum asset id — also what onboarding records as the "subject".
  final String id;
  final String name;
  final String ages;
  final int lessons;
  final int questions;

  /// The demo lesson: its position in the course, its stop id and title.
  final int lesson;
  final String stopId;
  final String stop;

  final String teach;
  final WidgetBuilder teachPic;

  final String prompt;
  final DemoKind kind;
  final List<String> choices;
  final String answer; // number/word: the choice; cell: "x,y"
  final String why;
  final String hint;

  final List<Outcome> outcomes;
  final List<String> path;

  const DemoCourse({
    required this.band,
    required this.id,
    required this.name,
    required this.ages,
    required this.lessons,
    required this.questions,
    required this.lesson,
    required this.stopId,
    required this.stop,
    required this.teach,
    required this.teachPic,
    required this.prompt,
    required this.kind,
    this.choices = const [],
    required this.answer,
    required this.why,
    required this.hint,
    required this.outcomes,
    required this.path,
  });
}

DemoCourse demoFor(String band) =>
    kDemoCourses.firstWhere((c) => c.band == band, orElse: () => kDemoCourses[1]);

final kDemoCourses = <DemoCourse>[
  // Number Sense 2.1.2 "Friends of ten".
  DemoCourse(
    band: 'a',
    id: 'number_sense',
    name: 'Number Sense',
    ages: '5–6',
    lessons: 48,
    questions: 324,
    lesson: 14,
    stopId: '2.1.2',
    stop: 'Friends of ten',
    teach: 'Two parts that make ten are a pair worth knowing.',
    teachPic: (_) => const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TenFrame(filled: 6, ghost: true),
        SizedBox(height: 10),
        Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.textDark),
            children: [
              TextSpan(text: '6 '),
              TextSpan(text: '+ 4', style: TextStyle(color: AppColors.accentDeep)),
              TextSpan(text: ' = 10'),
            ],
          ),
        ),
      ],
    ),
    prompt: 'How many more counters would fill the frame?',
    kind: DemoKind.number,
    choices: ['1', '2', '3', '4'],
    answer: '3',
    why: '7 and 3 make 10.',
    hint: 'Count the empty ones.',
    outcomes: [
      Outcome(Icons.filter_9_plus_rounded, 'Counts anything, fast', 'Up to 50, by tens and ones.'),
      Outcome(Icons.grid_view_rounded, 'Knows what makes 10', 'The root of every sum.'),
      Outcome(Icons.category_rounded, 'Spots patterns', 'What comes next, what doesn’t fit.'),
      Outcome(Icons.pie_chart_rounded, 'Gets parts of a whole', 'Which slice is bigger, and why.'),
    ],
    path: ['Counting', 'Making ten', 'Patterns', 'All of it'],
  ),
  // Puzzles & Logic 3.3.3 "Number codes".
  DemoCourse(
    band: 'b',
    id: 'puzzles_and_logic',
    name: 'Puzzles & Logic',
    ages: '7–8',
    lessons: 48,
    questions: 324,
    lesson: 35,
    stopId: '3.3.3',
    stop: 'Number codes',
    teach: 'A is 1, B is 2, C is 3.',
    teachPic: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CodeTiles(
          const ['A', 'B', 'C', 'D'],
          ink: AppColors.textDark,
          fill: tint(AppColors.accent, 0.22),
        ),
        const SizedBox(height: 8),
        const CodeTiles(['1', '2', '3', '4']),
        const SizedBox(height: 10),
        const Text.rich(
          TextSpan(
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textMuted),
            children: [
              TextSpan(text: 'so '),
              TextSpan(text: '3 1 2', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900)),
              TextSpan(text: ' spells '),
              TextSpan(text: 'CAB', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ],
    ),
    prompt: 'A is 1. Which word does this code spell?',
    kind: DemoKind.word,
    choices: ['CFE', 'ADC', 'BED', 'DEB'],
    answer: 'BED',
    why: 'B is 2, E is 5, D is 4.',
    hint: 'Count along the alphabet from A.',
    outcomes: [
      Outcome(Icons.calculate_rounded, 'Solves word problems', 'One step at a time.'),
      Outcome(Icons.groups_rounded, 'Reasons about order', 'Queues, heights, left and right.'),
      Outcome(Icons.key_rounded, 'Cracks codes', 'Letter codes and family puzzles.'),
      Outcome(Icons.schedule_rounded, 'Checks every clue', 'Clocks, calendars, all the ways.'),
    ],
    path: ['Number puzzles', 'Order', 'Codes', 'Logic'],
  ),
  // Think Like a Coder 2.1.1 "Spot the repeat" — the teach board is the stop's
  // own (DO 2 TIMES: RIGHT, UP) and the question is its predict question
  // (DO 3 TIMES: RIGHT, UP on a 5×5 board, ends on 3,3).
  DemoCourse(
    band: 'c',
    id: 'think_like_a_coder',
    name: 'Think Like a Coder',
    ages: '9–10',
    lessons: 48,
    questions: 324,
    lesson: 13,
    stopId: '2.1.1',
    stop: 'Spot the repeat',
    teach: 'When the same steps come back again and again, use a loop.',
    teachPic: (_) => const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 170,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CodeBlock('DO 2 TIMES', loop: true),
              CodeBlock('RIGHT', icon: Icons.arrow_forward_rounded, inside: true),
              CodeBlock('UP', icon: Icons.arrow_upward_rounded, inside: true),
            ],
          ),
        ),
        SizedBox(height: 6),
        GridBoard(w: 5, h: 5, cell: 30, trail: [(1, 0), (1, 1), (2, 1), (2, 2)]),
        SizedBox(height: 8),
        MoveIcons([
          Icons.arrow_forward_rounded,
          Icons.arrow_upward_rounded,
          Icons.arrow_forward_rounded,
          Icons.arrow_upward_rounded,
        ]),
      ],
    ),
    prompt: 'Tap the square this loop ends on.',
    kind: DemoKind.cell,
    answer: '3,3',
    why: 'Right, up, three times over.',
    hint: 'Right, up. Then again, and again.',
    outcomes: [
      Outcome(Icons.code_rounded, 'Reads a program', 'Predicts it before it runs.'),
      Outcome(Icons.repeat_rounded, 'Uses loops', 'Says it once, repeats it right.'),
      Outcome(Icons.call_split_rounded, 'Writes decisions', 'IF this, ELSE that.'),
      Outcome(Icons.bug_report_rounded, 'Fixes bugs', 'Finds where it goes wrong.'),
    ],
    path: ['Reading code', 'Loops', 'Decisions', 'Debugging'],
  ),
  // Reasoning 3.1.1 "Reading the bulbs".
  DemoCourse(
    band: 'd',
    id: 'reasoning',
    name: 'Reasoning',
    ages: '11–12',
    lessons: 48,
    questions: 324,
    lesson: 25,
    stopId: '3.1.1',
    stop: 'Reading the bulbs',
    teach: 'Each bulb is worth double the one on its right. Add the lit ones.',
    teachPic: (_) => const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Bulbs(on: [false, true, true, true], width: 210),
        SizedBox(height: 4),
        Text(
          '4 + 2 + 1 = 7',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.done),
        ),
      ],
    ),
    prompt: 'Add up the lit bulbs. Tap the number.',
    kind: DemoKind.number,
    choices: ['10', '11', '12', '13'],
    answer: '11',
    why: '8 + 2 + 1 = 11. That’s binary.',
    hint: 'Add only the bulbs that are lit.',
    outcomes: [
      Outcome(Icons.trending_up_rounded, 'Finds the rule', 'Even the 100th number.'),
      Outcome(Icons.grid_on_rounded, 'Proves what must be true', 'Logic grids, truth and lies.'),
      Outcome(Icons.lightbulb_rounded, 'Reads binary', 'And breaks secret codes.'),
      Outcome(Icons.view_in_ar_rounded, 'Turns shapes in their head', 'Cube nets and 3D cuts.'),
    ],
    path: ['Patterns', 'Logic', 'Codes', '3D space'],
  ),
];

/// The question picture for [c] — kept separate from the data because the
/// coding grid is interactive.
Widget demoQuestionPic(
  DemoCourse c, {
  (int, int)? pick,
  bool? pickRight,
  ValueChanged<(int, int)>? onCell,
}) {
  switch (c.band) {
    case 'a':
      return const TenFrame(filled: 7);
    case 'b':
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SECRET CODE',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.6, color: AppColors.textMuted),
          ),
          SizedBox(height: 8),
          CodeTiles(['2', '5', '4'], size: 50),
        ],
      );
    case 'c':
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 170,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CodeBlock('DO 3 TIMES', loop: true),
                CodeBlock('RIGHT', icon: Icons.arrow_forward_rounded, inside: true),
                CodeBlock('UP', icon: Icons.arrow_upward_rounded, inside: true),
              ],
            ),
          ),
          const SizedBox(height: 6),
          GridBoard(w: 5, h: 5, cell: 40, pick: pick, pickRight: pickRight, onTap: onCell),
        ],
      );
    default:
      return const Bulbs(on: [true, false, true, true], width: 220);
  }
}

/// The small picture on each age card.
Widget ageArt(String band) {
  switch (band) {
    case 'a':
      return const TenFrame(filled: 7, cell: 15);
    case 'b':
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CodeTiles(['B'], ink: Colors.white, fill: AppColors.done, size: 28),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 7),
            child: Text('=', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.done)),
          ),
          CodeTiles(['2'], ink: AppColors.done, fill: Colors.white, size: 28),
        ],
      );
    case 'c':
      return const SizedBox(
        width: 96,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CodeBlock('DO 2', loop: true),
            CodeBlock('', icon: Icons.arrow_forward_rounded, inside: true),
          ],
        ),
      );
    default:
      return const Bulbs(on: [true, false, true, true], width: 92);
  }
}

/// The background of each age card, one chapter colour per course.
Color ageTint(String band) => switch (band) {
  'a' => tint(AppColors.primary, 0.12),
  'b' => tint(AppColors.done, 0.14),
  'c' => tint(AppColors.accent, 0.2),
  _ => tint(AppColors.wrong, 0.1),
};
