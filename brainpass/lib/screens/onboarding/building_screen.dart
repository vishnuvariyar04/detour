// screens/onboarding/building_screen.dart
//
// S19 — "Building {child}'s learning plan…": a ~4 second progress moment with
// checklist items ticking over, then auto-advances into the gate demo.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../questions.dart';
import '../../storage.dart';
import '../../theme.dart';

class BuildingPlanScreen extends StatefulWidget {
  final VoidCallback onNext;
  const BuildingPlanScreen({super.key, required this.onNext});

  @override
  State<BuildingPlanScreen> createState() => _BuildingPlanScreenState();
}

class _BuildingPlanScreenState extends State<BuildingPlanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  Timer? _doneTimer;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _doneTimer = Timer(const Duration(milliseconds: 450), () {
          if (mounted) widget.onNext();
        });
      }
    });
  }

  @override
  void dispose() {
    _doneTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = Storage.childNameOr();
    final band = bandFromString(Storage.ageBand);
    final items = [
      'Matching questions to age ${Storage.childAge}',
      'Mixing ${_bandMix(band)}',
      'Calibrating difficulty',
      'Preparing the first lesson…',
    ];
    return Scaffold(
      body: Container(
        decoration: AppColors.bgDecoration(),
        height: double.infinity,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = Curves.easeInOutCubic.transform(_c.value);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Progress ring with the percentage inside
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: CircularProgressIndicator(
                              value: t,
                              strokeWidth: 10,
                              strokeCap: StrokeCap.round,
                              backgroundColor: const Color(0xFFE1DDF0),
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primary),
                            ),
                          ),
                          Text(
                            '${(t * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Building $child’s learning plan…',
                      textAlign: TextAlign.center,
                      style: AppText.title,
                    ),
                    const SizedBox(height: 26),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: AppColors.cardDecoration(),
                      child: Column(
                        children: [
                          for (var i = 0; i < items.length; i++) ...[
                            if (i > 0) const SizedBox(height: 14),
                            _ChecklistRow(
                              label: items[i],
                              done: t > (i + 1) / (items.length + 0.5),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _bandMix(Band b) {
    switch (b) {
      case Band.a:
        return 'counting, shapes & animals';
      case Band.b:
        return 'mental math, nature & words';
      case Band.c:
        return 'times tables, logic & trivia';
      case Band.d:
        return 'math, logic & general knowledge';
    }
  }
}

class _ChecklistRow extends StatelessWidget {
  final String label;
  final bool done;
  const _ChecklistRow({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: done ? AppColors.correct : const Color(0xFFEFEDF6),
            shape: BoxShape.circle,
          ),
          child: done
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 17)
              : const Padding(
                  padding: EdgeInsets.all(6),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Color(0xFFB9B4CE)),
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: done ? AppColors.textDark : AppColors.textMuted,
            ),
            child: Text(label),
          ),
        ),
      ],
    );
  }
}
