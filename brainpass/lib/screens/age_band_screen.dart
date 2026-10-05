// screens/age_band_screen.dart
//
// Pick an age band (or enter the child's age, which maps to a band). Saves
// `ageBand` to storage.

import 'package:flutter/material.dart';

import '../engine.dart';
import '../curriculum.dart';
import '../questions.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets.dart';

class AgeBandScreen extends StatefulWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const AgeBandScreen({super.key, required this.onNext, this.step, this.total});

  @override
  State<AgeBandScreen> createState() => _AgeBandScreenState();
}

class _AgeBandScreenState extends State<AgeBandScreen> {
  late Band _band;

  @override
  void initState() {
    super.initState();
    _band = bandFromString(Storage.ageBand);
  }

  Future<void> _save() async {
    final band = bandToString(_band);
    await Storage.setAgeBand(band);
    Curriculum.invalidate();
    await Engine.setAgeBand(band);
    widget.onNext();
  }

  void _pickAge() async {
    final age = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AgePicker(),
    );
    if (age != null) setState(() => _band = bandFromAge(age));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppColors.bgDecoration(),
        height: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              NupoTopBar(step: widget.step, total: widget.total),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('How old is your kid?', style: AppText.title),
                      const SizedBox(height: 8),
                      const Text(
                        'The complete syllabus changes with the age you pick.',
                        style: AppText.body,
                      ),
                      const SizedBox(height: 20),

                      for (final b in Band.values)
                        SelectCard(
                          title: bandLabel(b),
                          subtitle: _bandDescription(b),
                          selected: _band == b,
                          leading: _bandEmoji(b),
                          onTap: () => setState(() => _band = b),
                        ),

                      Center(
                        child: TextButton.icon(
                          onPressed: _pickAge,
                          icon: const Icon(Icons.cake_rounded, size: 18),
                          label: const Text('Enter exact age'),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _previewCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: PrimaryButton(
                  label: 'Save & switch syllabus',
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bandEmoji(Band b) {
    final (emoji, bg) = switch (b) {
      Band.a => ('🧸', const Color(0xFFFFEFE6)),
      Band.b => ('🚀', const Color(0xFFE6F4EA)),
      Band.c => ('🔬', const Color(0xFFE8F0FE)),
      Band.d => ('🎓', const Color(0xFFF1F0FE)),
    };
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 23)),
    );
  }

  Widget _previewCard() {
    final (name, topics) = switch (_band) {
      Band.a => (
        'Number Sense',
        ['Counting', 'Making numbers', 'Shapes & patterns'],
      ),
      Band.b => (
        'Puzzles & Logic',
        ['Number thinking', 'Order & position', 'Relations & codes'],
      ),
      Band.c => (
        'Think Like a Coder',
        ['Sequences', 'Loops & conditions', 'Debugging'],
      ),
      Band.d => ('Reasoning', ['Sequences & logic', 'Codes', '3D space']),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppColors.cardDecoration(color: const Color(0xFFFAF9FF)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.accent,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'SYLLABUS PREVIEW',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accentDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Column(
              key: ValueKey(_band),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final topic in topics) _topicChip(topic)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicChip(String topic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        topic,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  String _bandDescription(Band b) {
    switch (b) {
      case Band.a:
        return 'Number sense and visual patterns';
      case Band.b:
        return 'Puzzles, order and everyday logic';
      case Band.c:
        return 'Sequences, loops and debugging';
      case Band.d:
        return 'Algebraic, spatial and formal reasoning';
    }
  }
}

class _AgePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How old?', style: AppText.title),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var age = 5; age <= 12; age++)
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(age),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primarySoft,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      minimumSize: const Size(62, 50),
                    ),
                    child: Text(
                      '$age',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
