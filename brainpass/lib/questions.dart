// questions.dart
//
// The "brain" of BrainPass: it produces the problems a child solves to earn
// screen time. Two kinds of content live here and BOTH are compiled into the
// app (no network, no server — see spec §4 "collect nothing"):
//
//   1. Procedurally GENERATED questions (math + number patterns). These are
//      created by code on the fly, so they are effectively infinite and need
//      no content licensing.
//   2. A small HARDCODED general-knowledge (GK) question bank, one list per
//      age band.
//
// This file is imported by BOTH the parent app AND the kid-facing overlay
// isolate, so it must stay free of any UI or platform code.

import 'dart:math';

/// The three age bands from spec §2.
///  - a = ages 5–7
///  - b = ages 8–10
///  - c = ages 11–13
enum Band { a, b, c }

/// Convert the stored string ("a"/"b"/"c") to a [Band], defaulting to band B.
Band bandFromString(String? s) {
  switch (s) {
    case 'a':
      return Band.a;
    case 'c':
      return Band.c;
    case 'b':
    default:
      return Band.b;
  }
}

/// Convert a [Band] back to its stored string form.
String bandToString(Band b) => b.name; // "a" | "b" | "c"

/// Map a child's age to a band (spec §2). Ages 3–4 are not a target; we clamp
/// them up to band A so the app still works, but the UI discourages this.
Band bandFromAge(int age) {
  if (age <= 7) return Band.a;
  if (age <= 10) return Band.b;
  return Band.c;
}

/// A human-friendly label for a band, used in the parent UI.
String bandLabel(Band b) {
  switch (b) {
    case Band.a:
      return 'Ages 5–7';
    case Band.b:
      return 'Ages 8–10';
    case Band.c:
      return 'Ages 11–13';
  }
}

/// A single question shown to the child.
///
///  - [prompt]  : the text shown, e.g. "7 + 5 = ?"
///  - [answer]  : the correct answer as a String, for an exact compare.
///  - [options] : if non-null, the question is multiple-choice (GK) and these
///                are the buttons to show; if null, the child types a number
///                on the keypad (math / pattern).
class Question {
  final String prompt;
  final String answer;
  final List<String>? options;

  const Question(this.prompt, this.answer, {this.options});

  bool get isMultipleChoice => options != null;
}

final _rng = Random();

/// Inclusive random integer in [min, max].
int _r(int min, int max) => min + _rng.nextInt(max - min + 1);

// ---------------------------------------------------------------------------
// MATH (procedurally generated) — spec §11
// ---------------------------------------------------------------------------
Question generateMath(Band band) {
  switch (band) {
    case Band.a: // add/subtract within 20
      if (_rng.nextBool()) {
        final x = _r(1, 10), y = _r(1, 10);
        return Question('$x + $y = ?', '${x + y}');
      } else {
        final x = _r(2, 20), y = _r(1, x); // y ≤ x => no negative answers
        return Question('$x − $y = ?', '${x - y}');
      }
    case Band.b: // add/sub to 100, times tables, simple division
      final pick = _r(0, 3);
      if (pick == 0) {
        final x = _r(10, 99), y = _r(10, 99);
        return Question('$x + $y = ?', '${x + y}');
      }
      if (pick == 1) {
        final x = _r(20, 99), y = _r(1, x);
        return Question('$x − $y = ?', '${x - y}');
      }
      if (pick == 2) {
        final x = _r(2, 12), y = _r(2, 12);
        return Question('$x × $y = ?', '${x * y}');
      }
      final y = _r(2, 12), q = _r(2, 12);
      final x = y * q; // build division so it always divides evenly
      return Question('$x ÷ $y = ?', '$q');
    case Band.c: // multi-step, 2-digit ×, division, squares
      final pick = _r(0, 3);
      if (pick == 0) {
        final x = _r(11, 49), y = _r(2, 12);
        return Question('$x × $y = ?', '${x * y}');
      }
      if (pick == 1) {
        final y = _r(3, 15), q = _r(3, 15);
        final x = y * q;
        return Question('$x ÷ $y = ?', '$q');
      }
      if (pick == 2) {
        final a = _r(2, 9), b = _r(2, 9), c = _r(2, 9);
        return Question('$a × $b + $c = ?', '${a * b + c}');
      }
      final n = _r(4, 15);
      return Question('$n² = ?', '${n * n}');
  }
}

// ---------------------------------------------------------------------------
// NUMBER PATTERN ("what comes next?") — spec §11
// ---------------------------------------------------------------------------
Question generatePattern(Band band) {
  final step = band == Band.a
      ? _r(1, 3)
      : band == Band.b
          ? _r(2, 6)
          : _r(3, 12);
  final start = _r(1, band == Band.a ? 5 : 12);
  final seq = [start, start + step, start + 2 * step, start + 3 * step];
  final next = start + 4 * step;
  return Question('${seq.join(', ')}, ?', '$next');
}

// ---------------------------------------------------------------------------
// GENERAL KNOWLEDGE (hardcoded MCQs) — spec §12
// ---------------------------------------------------------------------------
class GkCard {
  final String prompt;
  final List<String> options;
  final int correctIndex;
  const GkCard(this.prompt, this.options, this.correctIndex);
}

const List<GkCard> gkBandA = [ // ages 5-7
  GkCard('What is a baby dog called?', ['Puppy', 'Kitten', 'Cub'], 0),
  GkCard('The sun is a...?', ['Star', 'Planet', 'Cloud'], 0),
  GkCard('Which animal gives us milk?', ['Cow', 'Lion', 'Snake'], 0),
  GkCard('How many sides does a triangle have?', ['3', '4', '5'], 0),
  GkCard('Where do fish live?', ['Water', 'Trees', 'Sky'], 0),
  GkCard('What colour is the sky on a clear day?', ['Blue', 'Green', 'Red'], 0),
  GkCard('Which insect makes honey?', ['Bee', 'Ant', 'Spider'], 0),
  GkCard('What do we see with?', ['Eyes', 'Ears', 'Nose'], 0),
  GkCard('How many days are in a week?', ['7', '5', '10'], 0),
  GkCard('Ice is frozen...?', ['Water', 'Milk', 'Juice'], 0),
  GkCard('What is a baby cat called?', ['Kitten', 'Puppy', 'Calf'], 0),
  GkCard('What do plants need to grow?', ['Water and sunlight', 'Candy', 'Toys'], 0),
];

const List<GkCard> gkBandB = [ // ages 8-10
  GkCard('Which is the largest planet in our solar system?', ['Jupiter', 'Earth', 'Mars'], 0),
  GkCard('What is the fastest land animal?', ['Cheetah', 'Elephant', 'Turtle'], 0),
  GkCard('A group of lions is called a...?', ['Pride', 'Pack', 'Herd'], 0),
  GkCard('On which continent is the Sahara Desert?', ['Africa', 'Asia', 'Europe'], 0),
  GkCard('Roughly how many bones are in an adult human body?', ['206', '100', '500'], 0),
  GkCard('In which country is the Great Wall?', ['China', 'India', 'Egypt'], 0),
  GkCard('How plants make food using sunlight is called...?', ['Photosynthesis', 'Digestion', 'Evaporation'], 0),
  GkCard('What is the largest ocean?', ['Pacific', 'Atlantic', 'Indian'], 0),
  GkCard('How many legs does a spider have?', ['8', '6', '4'], 0),
  GkCard('Water freezes at what temperature (°C)?', ['0', '50', '100'], 0),
  GkCard('Bats are...?', ['Mammals', 'Birds', 'Insects'], 0),
  GkCard('What currency is used in Japan?', ['Yen', 'Dollar', 'Rupee'], 0),
];

const List<GkCard> gkBandC = [ // ages 11-13
  GkCard('What is the chemical symbol for gold?', ['Au', 'Gd', 'Go'], 0),
  GkCard('What is the smallest prime number?', ['2', '1', '3'], 0),
  GkCard('Which planet is known as the Red Planet?', ['Mars', 'Venus', 'Jupiter'], 0),
  GkCard('Which travels faster?', ['Light', 'Sound', 'They are equal'], 0),
  GkCard('What is the largest organ of the human body?', ['Skin', 'Heart', 'Liver'], 0),
  GkCard('What is the capital of Australia?', ['Canberra', 'Sydney', 'Melbourne'], 0),
  GkCard('A six-sided polygon is called a...?', ['Hexagon', 'Pentagon', 'Octagon'], 0),
  GkCard('What is often called the powerhouse of the cell?', ['Mitochondria', 'Nucleus', 'Ribosome'], 0),
  GkCard('Who wrote Romeo and Juliet?', ['Shakespeare', 'Dickens', 'Tolkien'], 0),
  GkCard('What is the square root of 64?', ['8', '6', '16'], 0),
  GkCard('Which gas do plants absorb from the air?', ['Carbon dioxide', 'Oxygen', 'Nitrogen'], 0),
  GkCard('Which country is also a continent?', ['Australia', 'India', 'Brazil'], 0),
];

const Map<Band, List<GkCard>> gkByBand = {
  Band.a: gkBandA,
  Band.b: gkBandB,
  Band.c: gkBandC,
};

/// Turn a [GkCard] into a generic [Question] with shuffled options so the
/// correct answer is not always in the same position.
Question gkToQuestion(GkCard card) {
  final indexed = List.generate(card.options.length, (i) => i);
  indexed.shuffle(_rng);
  final shuffledOptions = [for (final i in indexed) card.options[i]];
  final correctText = card.options[card.correctIndex];
  return Question(card.prompt, correctText, options: shuffledOptions);
}

/// The kind of question to generate next.
enum QuestionKind { math, pattern, gk }

/// Produce one question of a specific kind for a band.
Question generateOne(Band band, QuestionKind kind) {
  switch (kind) {
    case QuestionKind.math:
      return generateMath(band);
    case QuestionKind.pattern:
      return generatePattern(band);
    case QuestionKind.gk:
      final pool = gkByBand[band]!;
      return gkToQuestion(pool[_rng.nextInt(pool.length)]);
  }
}

/// Build the sequence of question kinds for one "earn cycle" of [count]
/// questions. Per spec §9.8 we lean on generated math/pattern and sprinkle in
/// GK — roughly one GK per three questions, the rest split math/pattern.
List<QuestionKind> buildEarnPlan(int count) {
  final plan = <QuestionKind>[];
  for (var i = 0; i < count; i++) {
    if (i % 3 == 2) {
      plan.add(QuestionKind.gk);
    } else if (i.isEven) {
      plan.add(QuestionKind.math);
    } else {
      plan.add(QuestionKind.pattern);
    }
  }
  return plan;
}

/// Compare a typed/selected answer to the correct one. For numeric answers we
/// compare as integers (so "07" == "7"); otherwise we compare trimmed text.
bool isCorrect(Question q, String given) {
  final a = q.answer.trim();
  final g = given.trim();
  final ai = int.tryParse(a);
  final gi = int.tryParse(g);
  if (ai != null && gi != null) return ai == gi;
  return a.toLowerCase() == g.toLowerCase();
}
