// screens/age_band_screen.dart — spec §9.4
//
// Pick an age band (or enter the child's age, which maps to a band). Saves
// `ageBand` to storage.

import 'package:flutter/material.dart';

import '../engine.dart';
import '../questions.dart';
import '../storage.dart';
import '../widgets.dart';

class AgeBandScreen extends StatefulWidget {
  final VoidCallback onNext;
  const AgeBandScreen({super.key, required this.onNext});

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
    await Storage.setAgeBand(bandToString(_band));
    await Engine.setAgeBand(bandToString(_band));
    widget.onNext();
  }

  void _pickAge() async {
    final age = await showModalBottomSheet<int>(
      context: context,
      builder: (_) => _AgePicker(),
    );
    if (age != null) setState(() => _band = bandFromAge(age));
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: "Your child's age",
      subtitle:
          'This sets how hard the questions are. You can change it any time.',
      buttonLabel: 'Save',
      onButton: _save,
      child: Column(
        children: [
          for (final b in Band.values)
            SelectCard(
              title: bandLabel(b),
              subtitle: _bandDescription(b),
              selected: _band == b,
              onTap: () => setState(() => _band = b),
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _pickAge,
            icon: const Icon(Icons.cake_rounded),
            label: const Text("Or enter exact age"),
          ),
        ],
      ),
    );
  }

  String _bandDescription(Band b) {
    switch (b) {
      case Band.a:
        return 'Counting, easy add & subtract, simple picture questions.';
      case Band.b:
        return 'Add/subtract to 100, times tables, simple division, richer GK.';
      case Band.c:
        return 'Multi-step arithmetic, patterns, harder general knowledge.';
    }
  }
}

class _AgePicker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Pick age',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var age = 5; age <= 13; age++)
                  ActionChip(
                    label: Text('$age'),
                    onPressed: () => Navigator.of(context).pop(age),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
