// screens/app_rules_screen.dart — per-app rules (replaces the old global rate).
//
// Each gated app gets its OWN questions / minutes / daily cap. Nothing is shared
// across apps. Saving pushes the rules to the native engine immediately.

import 'package:flutter/material.dart';

import '../engine.dart';
import '../safe_apps.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets.dart';

class AppRulesScreen extends StatefulWidget {
  final VoidCallback onNext;
  final bool isOnboarding;
  const AppRulesScreen({
    super.key,
    required this.onNext,
    this.isOnboarding = true,
  });

  @override
  State<AppRulesScreen> createState() => _AppRulesScreenState();
}

class _AppRulesScreenState extends State<AppRulesScreen> {
  late List<String> _apps;
  late Map<String, AppRule> _rules;

  @override
  void initState() {
    super.initState();
    _apps = Storage.gatedApps;
    final existing = Storage.appRules;
    _rules = {for (final pkg in _apps) pkg: existing[pkg] ?? const AppRule()};
  }

  void _update(String pkg, AppRule rule) =>
      setState(() => _rules[pkg] = rule);

  Future<void> _save() async {
    await Storage.setAppRules(_rules);
    await Engine.setRules(Storage.rulesForEngine());
    // Wipe any leftover earned time so the new minutes/cap apply right away.
    if (!widget.isOnboarding) await Engine.clearBudgets();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    if (_apps.isEmpty) {
      return StepScaffold(
        title: 'Set each app’s rule',
        subtitle: 'Go back and pick at least one app first.',
        buttonLabel: 'Back',
        onButton: widget.onNext,
        child: const SizedBox.shrink(),
      );
    }
    return StepScaffold(
      title: 'Set each app’s rule',
      subtitle:
          'Every app is independent — its own questions, minutes, and daily '
          'limit. Time only counts while that app is on screen.',
      buttonLabel: widget.isOnboarding ? 'Finish setup' : 'Save',
      onButton: _save,
      child: Column(
        children: [
          for (final pkg in _apps)
            _AppRuleCard(
              name: displayNameFor(pkg),
              rule: _rules[pkg]!,
              onChanged: (r) => _update(pkg, r),
            ),
        ],
      ),
    );
  }
}

class _AppRuleCard extends StatelessWidget {
  final String name;
  final AppRule rule;
  final ValueChanged<AppRule> onChanged;
  const _AppRuleCard({
    required this.name,
    required this.rule,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final capOn = rule.cap > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smartphone_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          IntStepper(
            label: 'Questions to earn',
            value: rule.questions,
            min: 1,
            max: 10,
            onChanged: (v) => onChanged(rule.copyWith(questions: v)),
          ),
          const SizedBox(height: 8),
          IntStepper(
            label: 'Minutes earned',
            value: rule.minutes,
            min: 1,
            max: 60,
            suffix: ' min',
            onChanged: (v) => onChanged(rule.copyWith(minutes: v)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Daily limit for this app',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              value: capOn,
              onChanged: (v) =>
                  onChanged(rule.copyWith(cap: v ? 60 : 0)),
            ),
          ),
          if (capOn)
            IntStepper(
              label: 'Daily limit',
              value: rule.cap,
              min: 15,
              max: 180,
              step: 15,
              suffix: ' min',
              onChanged: (v) => onChanged(rule.copyWith(cap: v)),
            ),
          const SizedBox(height: 4),
          Text(
            'Solve ${rule.questions} → play ${rule.minutes} min'
            '${capOn ? ' · max ${rule.cap} min/day' : ''}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
