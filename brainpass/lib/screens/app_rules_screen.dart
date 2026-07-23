// screens/app_rules_screen.dart — per-app rules.
//
// Each gated app gets its OWN questions / minutes / daily cap. Nothing is shared
// across apps. Saving pushes the rules to the native engine immediately.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../engine.dart';
import '../safe_apps.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets.dart';

class AppRulesScreen extends StatefulWidget {
  final VoidCallback onNext;
  final bool isOnboarding;
  final int? step;
  final int? total;
  const AppRulesScreen({
    super.key,
    required this.onNext,
    this.isOnboarding = true,
    this.step,
    this.total,
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

  void _update(String pkg, AppRule rule) => setState(() => _rules[pkg] = rule);

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
      return Scaffold(
        body: Container(
          decoration: AppColors.bgDecoration(),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('No apps picked yet',
                      textAlign: TextAlign.center, style: AppText.title),
                  const SizedBox(height: 8),
                  const Text('Go back and pick at least one app first.',
                      textAlign: TextAlign.center, style: AppText.body),
                  const SizedBox(height: 24),
                  PrimaryButton(label: 'Back', onPressed: widget.onNext),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: AppColors.bgDecoration(),
        height: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              NupoTopBar(
                step: widget.step,
                total: widget.total,
                title: widget.isOnboarding ? null : 'App rules',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('How much learning?', style: AppText.title),
                      const SizedBox(height: 8),
                      Text(
                        'For each app: how many questions ${Storage.childNameOr()} '
                        'answers, and how many minutes of play that earns.',
                        style: AppText.body,
                      ),
                      const SizedBox(height: 20),
                      for (final pkg in _apps)
                        _AppRuleCard(
                          name: displayNameFor(pkg),
                          package: pkg,
                          rule: _rules[pkg]!,
                          onChanged: (r) => _update(pkg, r),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: widget.isOnboarding ? 'Finish setup' : 'Save',
                      onPressed: _save,
                    ),
                    const SizedBox(height: 12),
                    InfoPill(
                      icon: Symbols.tune_rounded,
                      text: 'You can change these any time',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppRuleCard extends StatelessWidget {
  final String name;
  final String package;
  final AppRule rule;
  final ValueChanged<AppRule> onChanged;
  const _AppRuleCard({
    required this.name,
    required this.package,
    required this.rule,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final capOn = rule.cap > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: AppColors.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App header with a live rule summary
          Row(
            children: [
              AppBrandIcon(package, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Symbols.star_rounded,
                              color: AppColors.accent, size: 15),
                          const SizedBox(width: 4),
                          Text(
                            '${rule.questions} question${rule.questions == 1 ? '' : 's'} → ${rule.minutes} min',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accentDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          IntStepper(
            label: 'Questions per lesson',
            value: rule.questions,
            min: 1,
            max: 10,
            onChanged: (v) => onChanged(rule.copyWith(questions: v)),
          ),
          const SizedBox(height: 8),
          IntStepper(
            label: 'Minutes of play',
            value: rule.minutes,
            min: 1,
            max: 60,
            suffix: 'm',
            onChanged: (v) => onChanged(rule.copyWith(minutes: v)),
          ),
          const SizedBox(height: 8),

          // Daily limit
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FD),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Daily limit',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    Switch(
                      value: capOn,
                      onChanged: (v) => onChanged(rule.copyWith(cap: v ? 60 : 0)),
                    ),
                  ],
                ),
                if (capOn) ...[
                  const Divider(height: 8),
                  IntStepper(
                    label: 'Max per day',
                    value: rule.cap,
                    min: 15,
                    max: 180,
                    step: 15,
                    suffix: 'm',
                    onChanged: (v) => onChanged(rule.copyWith(cap: v)),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
