// questions.dart
//
// The "brain" of Nupo: it produces the questions in a child's learning moment.
// Two kinds of content live here and BOTH are compiled into the app:
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
enum Band { a, b, c, d }

/// Convert the stored string ("a"/"b"/"c"/"d") to a [Band], defaulting to band B.
Band bandFromString(String? s) {
  switch (s) {
    case 'a':
      return Band.a;
    case 'c':
      return Band.c;
    case 'd':
      return Band.d;
    case 'b':
    default:
      return Band.b;
  }
}

/// Convert a [Band] back to its stored string form.
String bandToString(Band b) => b.name; // "a" | "b" | "c" | "d"

/// Map a child's age to a band (spec §2 updated for 4 bands).
Band bandFromAge(int age) {
  if (age <= 6) return Band.a;
  if (age <= 8) return Band.b;
  if (age <= 10) return Band.c;
  return Band.d;
}

/// A human-friendly label for a band, used in the parent UI.
String bandLabel(Band b) {
  switch (b) {
    case Band.a:
      return 'Ages 5–6';
    case Band.b:
      return 'Ages 7–8';
    case Band.c:
      return 'Ages 9–10';
    case Band.d:
      return 'Age 11';
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
// MATH (procedurally generated)
// ---------------------------------------------------------------------------
Question generateMath(Band band) {
  switch (band) {
    case Band.a: // Ages 5-6: adding/subtracting within 10, plus symbol math
      final type = _r(0, 2);
      if (type == 0) {
        final x = _r(1, 5), y = _r(1, 4);
        return Question('$x + $y = ?', '${x + y}');
      } else if (type == 1) {
        final x = _r(2, 9), y = _r(1, x - 1);
        return Question('$x − $y = ?', '${x - y}');
      } else {
        final x = _r(1, 5);
        final symbols = ['🍎', '⭐', '🎈', '🍦', '🍩', '🦊'];
        final sym = symbols[_rng.nextInt(symbols.length)];
        return Question('$sym + $sym = ${x + x}\nWhat is $sym?', '$x');
      }
    case Band.b: // Ages 7-8: add/sub within 30, simple multiplication
      final type = _r(0, 2);
      if (type == 0) {
        final x = _r(5, 20), y = _r(1, 10);
        return Question('$x + $y = ?', '${x + y}');
      } else if (type == 1) {
        final x = _r(10, 30), y = _r(1, 9);
        return Question('$x − $y = ?', '${x - y}');
      } else {
        final x = _r(2, 5), y = _r(2, 6);
        return Question('$x × $y = ?', '${x * y}');
      }
    case Band.c: // Ages 9-10: add/sub within 100, times tables to 12, simple division
      final type = _r(0, 3);
      if (type == 0) {
        final x = _r(10, 89), y = _r(10, 89);
        return Question('$x + $y = ?', '${x + y}');
      }
      if (type == 1) {
        final x = _r(30, 99), y = _r(10, 29);
        return Question('$x − $y = ?', '${x - y}');
      }
      if (type == 2) {
        final x = _r(2, 12), y = _r(2, 12);
        return Question('$x × $y = ?', '${x * y}');
      }
      final y = _r(2, 10), q = _r(2, 10);
      return Question('${y * q} ÷ $y = ?', '$q');
    case Band.d: // Age 11: order of operations, division, squares, larger multiplication
      final type = _r(0, 3);
      if (type == 0) {
        final a = _r(2, 8), b = _r(2, 8), c = _r(2, 15);
        return Question('$a × $b + $c = ?', '${a * b + c}');
      }
      if (type == 1) {
        final y = _r(3, 12), q = _r(4, 12);
        return Question('${y * q} ÷ $y = ?', '$q');
      }
      if (type == 2) {
        final a = _r(2, 9), b = _r(2, 9), c = _r(2, 9);
        return Question('$a × $b − $c = ?', '${a * b - c}');
      }
      final n = _r(4, 15);
      return Question('$n² = ?', '${n * n}');
  }
}

// ---------------------------------------------------------------------------
// NUMBER PATTERN ("what comes next?")
// ---------------------------------------------------------------------------
Question generatePattern(Band band) {
  switch (band) {
    case Band.a: // Ages 5-6: count up by 1 or 2
      final step = _r(1, 2);
      final start = _r(1, 5);
      final seq = [start, start + step, start + 2 * step, start + 3 * step];
      final next = start + 4 * step;
      return Question('${seq.join(', ')}, ?', '$next');
    case Band.b: // Ages 7-8: skip count up/down by 2, 3, 5, 10
      final step = [2, -2, 3, 5, 10][_rng.nextInt(5)];
      final start = step < 0 ? _r(10, 20) : _r(1, 10);
      final seq = [start, start + step, start + 2 * step, start + 3 * step];
      final next = start + 4 * step;
      return Question('${seq.join(', ')}, ?', '$next');
    case Band.c: // Ages 9-10: skip count by 3, 4, 6, 8, or negative steps
      final step = [3, 4, 6, 8, -3, -5][_rng.nextInt(6)];
      final start = step < 0 ? _r(25, 40) : _r(1, 15);
      final seq = [start, start + step, start + 2 * step, start + 3 * step];
      final next = start + 4 * step;
      return Question('${seq.join(', ')}, ?', '$next');
    case Band.d: // Age 11: multiplying patterns or alternating patterns
      if (_rng.nextBool()) {
        final start = _r(2, 3);
        const factor = 2;
        final seq = [start, start * factor, start * factor * factor, start * factor * factor * factor];
        final next = start * factor * factor * factor * factor;
        return Question('${seq.join(', ')}, ?', '$next');
      } else {
        final start = _r(1, 10);
        final seq = [start, start + 3, start + 2, start + 5, start + 4];
        final next = start + 7;
        return Question('${seq.join(', ')}, ?', '$next');
      }
  }
}

// ---------------------------------------------------------------------------
// GENERAL KNOWLEDGE (hardcoded MCQs)
// ---------------------------------------------------------------------------
class GkCard {
  final String prompt;
  final List<String> options;
  final int correctIndex;
  const GkCard(this.prompt, this.options, this.correctIndex);
}

const List<GkCard> gkBandA = [ // ages 5-6
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
  GkCard('Which animal is known as the king of the jungle?', ['Lion', 'Monkey', 'Elephant'], 0),
  GkCard('Which fruit is yellow and sweet?', ['Banana', 'Apple', 'Grape'], 0),
  GkCard('How many legs does a dog have?', ['4', '2', '6'], 0),
  GkCard('Which is the odd one out?', ['Car', 'Truck', 'Apple'], 2),
  GkCard('What sound does a cow make?', ['Moo', 'Meow', 'Oink'], 0),
  GkCard('Which one is hot?', ['Fire', 'Snow', 'Ice cream'], 0),
  GkCard('Which one is cold?', ['Ice', 'Soup', 'Sun'], 0),
  GkCard('Which is the largest animal on land?', ['Elephant', 'Mouse', 'Rabbit'], 0),
  GkCard('Which is the odd one out?', ['Blue', 'Red', 'Square'], 2),
  GkCard('What season comes after winter?', ['Spring', 'Autumn', 'Summer'], 0),
  GkCard('Which animal hops and carries its baby in a pouch?', ['Kangaroo', 'Koala', 'Panda'], 0),
  GkCard('How many fingers do you have on one hand?', ['5', '10', '4'], 0),
  GkCard('Which bird can mimic human words?', ['Parrot', 'Penguin', 'Eagle'], 0),
];

const List<GkCard> gkBandB = [ // ages 7-8
  GkCard('Which is the fastest land animal?', ['Cheetah', 'Elephant', 'Turtle'], 0),
  GkCard('A group of lions is called a...?', ['Pride', 'Pack', 'Herd'], 0),
  GkCard('How many legs does a spider have?', ['8', '6', '4'], 0),
  GkCard('Water freezes at what temperature (°C)?', ['0', '50', '100'], 0),
  GkCard('Bats are...?', ['Mammals', 'Birds', 'Insects'], 0),
  GkCard('Which word is spelled correctly?', ['Elephant', 'Elefant', 'Elaphent'], 0),
  GkCard('What is the closest star to Earth?', ['The Sun', 'Proxima Centauri', 'Polaris'], 0),
  GkCard('Which animal is a herbivore (eats only plants)?', ['Rabbit', 'Lion', 'Wolf'], 0),
  GkCard('Which shape has 5 sides?', ['Pentagon', 'Hexagon', 'Octagon'], 0),
  GkCard('Which is the odd one out?', ['Carrot', 'Broccoli', 'Banana'], 2),
  GkCard('How many months are in a year?', ['12', '10', '14'], 0),
  GkCard('What gas do we breathe to stay alive?', ['Oxygen', 'Carbon Dioxide', 'Nitrogen'], 0),
  GkCard('Which ocean is the biggest on Earth?', ['Pacific', 'Atlantic', 'Indian'], 0),
  GkCard('What is the capital of the United Kingdom?', ['London', 'Paris', 'New York'], 0),
  GkCard('Which is the odd one out?', ['Bus', 'Train', 'Bicycle'], 2),
  GkCard('Which bird cannot fly?', ['Penguin', 'Sparrow', 'Robin'], 0),
  GkCard('How many colors are in a rainbow?', ['7', '6', '8'], 0),
  GkCard('What is the name of our galaxy?', ['Milky Way', 'Andromeda', 'Solar System'], 0),
  GkCard('Which force pulls everything down to Earth?', ['Gravity', 'Magnetism', 'Wind'], 0),
  GkCard('What do bees collect from flowers to make honey?', ['Nectar', 'Water', 'Seeds'], 0),
  GkCard('Which animal can live both in water and on land?', ['Frog', 'Fish', 'Whale'], 0),
  GkCard('What is the main ingredient of paper?', ['Wood', 'Plastic', 'Glass'], 0),
  GkCard('Which is the tallest mammal on Earth?', ['Giraffe', 'Elephant', 'Moose'], 0),
  GkCard('How many hours are in one day?', ['24', '12', '48'], 0),
  GkCard('I have a spine but no bones. I have leaves but no branches. What am I?', ['Book', 'Tree', 'Cactus'], 0),
];

const List<GkCard> gkBandC = [ // ages 9-10
  GkCard('Which is the largest planet in our solar system?', ['Jupiter', 'Earth', 'Mars'], 0),
  GkCard('On which continent is the Sahara Desert?', ['Africa', 'Asia', 'Europe'], 0),
  GkCard('Roughly how many bones are in an adult human body?', ['206', '100', '500'], 0),
  GkCard('In which country is the Great Wall?', ['China', 'India', 'Egypt'], 0),
  GkCard('How plants make food using sunlight is called...?', ['Photosynthesis', 'Digestion', 'Evaporation'], 0),
  GkCard('What currency is used in Japan?', ['Yen', 'Dollar', 'Rupee'], 0),
  GkCard('Which instrument is used to measure temperature?', ['Thermometer', 'Barometer', 'Speedometer'], 0),
  GkCard('What is the hardest natural substance on Earth?', ['Diamond', 'Gold', 'Iron'], 0),
  GkCard('Which is the smallest continent by land area?', ['Australia', 'Europe', 'South America'], 0),
  GkCard('What do we call a scientist who studies stars and space?', ['Astronomer', 'Biologist', 'Geologist'], 0),
  GkCard('What is the boiling point of water (°C)?', ['100', '0', '50'], 0),
  GkCard('Which organ pumps blood through your body?', ['Heart', 'Brain', 'Lungs'], 0),
  GkCard('I can fill a room but take up no space. What am I?', ['Light', 'Water', 'Air'], 0),
  GkCard('If you mix blue and yellow, what color do you get?', ['Green', 'Orange', 'Purple'], 0),
  GkCard('Which country is famous for pyramids?', ['Egypt', 'Mexico', 'Greece'], 0),
  GkCard('What is the name of the long sleep animals take in winter?', ['Hibernation', 'Migration', 'Snoozing'], 0),
  GkCard('Which planet is closest to the Sun?', ['Mercury', 'Venus', 'Mars'], 0),
  GkCard('How many players are on a soccer field for one team?', ['11', '9', '7'], 0),
  GkCard('Which animal is the largest mammal in the world?', ['Blue Whale', 'Elephant', 'Giraffe'], 0),
  GkCard('Who was the first person to step on the Moon?', ['Neil Armstrong', 'Buzz Aldrin', 'Yuri Gagarin'], 0),
  GkCard('What is the capital of France?', ['Paris', 'Rome', 'Berlin'], 0),
  GkCard('Which language has the most native speakers in the world?', ['Chinese Mandarin', 'English', 'Spanish'], 0),
  GkCard('What gas do plants release during photosynthesis?', ['Oxygen', 'Carbon Dioxide', 'Hydrogen'], 0),
  GkCard('I have keys but no locks. You can play me but can\'t enter me. What am I?', ['Piano', 'Computer', 'Door'], 0),
  GkCard('Which country is also a continent?', ['Australia', 'India', 'Brazil'], 0),
];

const List<GkCard> gkBandD = [ // age 11
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
  GkCard('What is the capital of Canada?', ['Ottawa', 'Toronto', 'Vancouver'], 0),
  GkCard('Which country is home to the Kangaroo?', ['Australia', 'South Africa', 'India'], 0),
  GkCard('What is the main gas found in the air we breathe?', ['Nitrogen', 'Oxygen', 'Carbon dioxide'], 0),
  GkCard('How many seconds are in one hour?', ['3600', '60', '120'], 0),
  GkCard('What is the name of the process when liquid turns into gas?', ['Evaporation', 'Condensation', 'Freezing'], 0),
  GkCard('Which planet is famous for its beautiful rings?', ['Saturn', 'Uranus', 'Neptune'], 0),
  GkCard('What is the square root of 121?', ['11', '12', '9'], 0),
  GkCard('How many degrees are in a right angle?', ['90', '180', '45'], 0),
  GkCard('What is the largest hot desert in the world?', ['Sahara', 'Gobi', 'Kalahari'], 0),
  GkCard('Which historical figure discovered gravity under an apple tree?', ['Isaac Newton', 'Albert Einstein', 'Galileo Galilei'], 0),
  GkCard('What is the value of Pi rounded to two decimal places?', ['3.14', '3.16', '3.12'], 0),
  GkCard('I speak without a mouth and hear without ears. I have no body, but I come alive with wind. What am I?', ['Echo', 'Kite', 'Cloud'], 0),
  GkCard('Unscramble this word to find an animal: "P H N E T L A E"', ['Elephant', 'Panther', 'Antelope'], 0),
  GkCard('Which is the largest ocean on Earth?', ['Pacific', 'Atlantic', 'Indian'], 0),
];

const Map<Band, List<GkCard>> gkByBand = {
  Band.a: gkBandA,
  Band.b: gkBandB,
  Band.c: gkBandC,
  Band.d: gkBandD,
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
