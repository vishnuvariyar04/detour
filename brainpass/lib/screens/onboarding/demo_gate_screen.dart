// screens/onboarding/demo_gate_screen.dart
//
// S20–S22 — THE BIG AHA: the parent plays the child's actual learning moment.
// The card uses the real question engine (questions.dart) with the band chosen
// for THEIR child, and the kid-gate visual language (gradient, stars, owl), so
// the demo and the product can't drift apart.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../questions.dart';
import '../../storage.dart';
import '../../theme.dart';
import 'onb_widgets.dart';

// ---------------------------------------------------------------------------
// S20 — intro
// ---------------------------------------------------------------------------

class DemoIntroScreen extends StatelessWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const DemoIntroScreen(
      {super.key, required this.onNext, this.step, this.total});

  @override
  Widget build(BuildContext context) {
    final p = Storage.parentName;
    final child = Storage.childNameOr();
    return StatementScreen(
      step: step,
      total: total,
      mascot: 'assets/mascot_opening.png',
      title: p.isEmpty
          ? 'This is exactly what $child will see.'
          : '$p, this is exactly what $child will see.',
      body: 'Go ahead — try it yourself.',
      ctaLabel: 'Show me',
      onNext: onNext,
    );
  }
}

// ---------------------------------------------------------------------------
// S21 — the real gate card
// ---------------------------------------------------------------------------

class DemoGateScreen extends StatefulWidget {
  final VoidCallback onNext;
  const DemoGateScreen({super.key, required this.onNext});

  @override
  State<DemoGateScreen> createState() => _DemoGateScreenState();
}

class _DemoGateScreenState extends State<DemoGateScreen> {
  late final List<Question> _questions;
  int _index = 0;
  String _typed = '';
  bool _wrongFlash = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final band = bandFromString(Storage.ageBand);
    // One of each kind — the same mix a real lesson uses.
    _questions = [
      generateOne(band, QuestionKind.math),
      generateOne(band, QuestionKind.gk),
      generateOne(band, QuestionKind.pattern),
    ];
  }

  Question get _q => _questions[_index];

  void _submit(String answer) {
    if (_done) return;
    if (isCorrect(_q, answer)) {
      HapticFeedback.mediumImpact();
      if (_index == _questions.length - 1) {
        setState(() {
          _index++; // fills the last star
          _done = true;
        });
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) widget.onNext();
        });
      } else {
        setState(() {
          _index++;
          _typed = '';
        });
      }
    } else {
      HapticFeedback.lightImpact();
      setState(() => _wrongFlash = true);
      Future.delayed(const Duration(milliseconds: 420), () {
        if (mounted) {
          setState(() {
            _wrongFlash = false;
            _typed = '';
          });
        }
      });
    }
  }

  void _key(String k) {
    if (_done) return;
    setState(() {
      if (k == 'del') {
        if (_typed.isNotEmpty) _typed = _typed.substring(0, _typed.length - 1);
      } else if (k == 'ok') {
        if (_typed.isNotEmpty) _submit(_typed);
      } else if (_typed.length < 4) {
        _typed += k;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.kidTop, AppColors.kidBottom],
          ),
        ),
        height: double.infinity,
        child: SafeArea(
          child: _done ? _celebration() : _gate(),
        ),
      ),
    );
  }

  // The gate card itself — mirrors the native kid overlay's layout.
  Widget _gate() {
    return Column(
      children: [
        const SizedBox(height: 18),
        Image.asset('assets/mascot_opening.png',
            width: 92, height: 92, fit: BoxFit.contain),
        const SizedBox(height: 8),
        const Text(
          'Here’s your learning moment!',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        _stars(),
        const SizedBox(height: 6),
        Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            'Question ${_index + 1} of ${_questions.length}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Container(
                key: ValueKey(_index),
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33222266),
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _q.prompt,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_q.isMultipleChoice)
                      _options()
                    else
                      _keypadBlock(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _questions.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: AnimatedScale(
              scale: i < _index ? 1 : 0.9,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: Icon(
                Icons.star_rounded,
                size: 34,
                color: i < _index
                    ? AppColors.accent
                    : Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
      ],
    );
  }

  Widget _options() {
    return Column(
      children: [
        for (final o in _q.options!)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: Material(
                color: _wrongFlash
                    ? AppColors.wrongSoft
                    : const Color(0xFFF7F5FF),
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _submit(o),
                  child: Center(
                    child: Text(
                      o,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _keypadBlock() {
    return Column(
      children: [
        // The typed answer
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 130,
          height: 54,
          decoration: BoxDecoration(
            color: _wrongFlash ? AppColors.wrongSoft : const Color(0xFFF7F5FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _wrongFlash ? AppColors.wrong : const Color(0xFFDCD4F8),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            _typed.isEmpty ? '?' : _typed,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: _typed.isEmpty
                  ? const Color(0xFFB9B4CE)
                  : AppColors.textDark,
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['del', '0', 'ok'],
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [for (final k in row) _demoKey(k)],
            ),
          ),
      ],
    );
  }

  Widget _demoKey(String k) {
    final isOk = k == 'ok';
    final isDel = k == 'del';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 76,
        height: 50,
        child: Material(
          color: isOk ? AppColors.correct : const Color(0xFFF7F5FF),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _key(k),
            child: Center(
              child: isDel
                  ? const Icon(Icons.backspace_outlined,
                      size: 20, color: AppColors.textDark)
                  : isOk
                      ? const Icon(Icons.check_rounded,
                          size: 24, color: Colors.white)
                      : Text(
                          k,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }

  // Brief in-gate celebration before moving to the payoff screen.
  Widget _celebration() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutBack,
          builder: (context, v, child) =>
              Transform.scale(scale: v, child: child),
          child: Image.asset('assets/mascot_opening.png',
              width: 170, height: 170, fit: BoxFit.contain),
        ),
        const SizedBox(height: 14),
        _stars(),
        const SizedBox(height: 18),
        const Text(
          '🎉 All three!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The app would open now.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// S22 — the payoff
// ---------------------------------------------------------------------------

class DemoPayoffScreen extends StatelessWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const DemoPayoffScreen(
      {super.key, required this.onNext, this.step, this.total});

  @override
  Widget build(BuildContext context) {
    final child = Storage.childNameOr();
    return StatementScreen(
      step: step,
      total: total,
      emoji: '🎉',
      title: 'That’s it. That’s the whole thing.',
      body: '$child answers 3 quick questions → their app opens.\n\n'
          'No lectures. No study sessions. No arguments.',
      ctaLabel: 'Continue',
      onNext: onNext,
    );
  }
}
