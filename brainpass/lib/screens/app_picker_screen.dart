// screens/app_picker_screen.dart
//
// Parent toggles which apps to gate. Two sources:
//   1. The curated preset list (always shown).
//   2. The phone's installed apps (loaded on demand), filtered so the dialer,
//      messaging, contacts, clock, and settings can NEVER be selected.
//
// Saves the selected package names to `gatedApps`.

import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../engine.dart';
import '../safe_apps.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets.dart';

class AppPickerScreen extends StatefulWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const AppPickerScreen({
    super.key,
    required this.onNext,
    this.step,
    this.total,
  });

  @override
  State<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends State<AppPickerScreen> {
  late Set<String> _selected;
  List<AppInfo>? _installed;
  bool _loadingInstalled = false;

  @override
  void initState() {
    super.initState();
    _selected = Storage.gatedApps.toSet();
    // First run: pre-select what the parent said the child reaches for in the
    // onboarding survey (spec §2.6 — pre-fill everything you can).
    if (_selected.isEmpty) {
      _selected = Storage.reachApps.where(isGateable).toSet();
    }
  }

  Future<void> _loadInstalled() async {
    setState(() => _loadingInstalled = true);
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: true,
      );
      // Safety filter + drop anything already in the preset list.
      final presetPkgs = kPresetGateableApps.map((p) => p.package).toSet();
      apps.retainWhere(
          (a) => isGateable(a.packageName) && !presetPkgs.contains(a.packageName));
      apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (!mounted) return;
      setState(() => _installed = apps);
    } finally {
      if (mounted) setState(() => _loadingInstalled = false);
    }
  }

  void _toggle(String pkg) {
    if (!isGateable(pkg)) return; // hard safety guard
    setState(() {
      _selected.contains(pkg) ? _selected.remove(pkg) : _selected.add(pkg);
    });
  }

  Future<void> _save() async {
    final apps = _selected.toList();
    await Storage.setGatedApps(apps);
    await Storage.reconcileRules(); // give new apps default rules, drop old ones
    await Engine.setRules(Storage.rulesForEngine()); // push to native engine
    widget.onNext();
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
                      Text('Where should lessons appear?',
                          style: AppText.title),
                      const SizedBox(height: 8),
                      Text(
                        'A short lesson runs before each of these opens for '
                        'your kid.',
                        style: AppText.body,
                      ),
                      const SizedBox(height: 20),

                      // Preset apps
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        decoration: AppColors.cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 10),
                              child: Row(
                                children: [
                                  Icon(
                                    Symbols.star_rounded,
                                    color: AppColors.accent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('POPULAR', style: AppText.overline),
                                ],
                              ),
                            ),
                            for (final p in kPresetGateableApps)
                              _AppToggle(
                                name: p.name,
                                package: p.package,
                                selected: _selected.contains(p.package),
                                onTap: () => _toggle(p.package),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Other installed apps
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        decoration: AppColors.cardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_installed == null)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: _loadingInstalled ? null : _loadInstalled,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 8),
                                    child: Row(
                                      children: [
                                        const IconBadge(Icons.apps_rounded,
                                            size: 18),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text('More apps on this phone',
                                              style: AppText.cardTitle),
                                        ),
                                        if (_loadingInstalled)
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        else
                                          const Icon(
                                              Icons.expand_more_rounded,
                                              color: AppColors.textMuted),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else ...[
                              const Padding(
                                padding: EdgeInsets.only(left: 4, bottom: 10, top: 4),
                                child: Text('ON THIS PHONE', style: AppText.overline),
                              ),
                              if (_installed!.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text('No other apps found.',
                                      style: AppText.body),
                                )
                              else
                                for (final a in _installed!)
                                  _AppToggle(
                                    name: a.name,
                                    package: a.packageName,
                                    iconBytes: a.icon,
                                    selected: _selected.contains(a.packageName),
                                    onTap: () => _toggle(a.packageName),
                                  ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: _selected.isEmpty
                          ? 'Pick at least one app'
                          : 'Continue',
                      onPressed: _selected.isEmpty ? null : _save,
                    ),
                    const SizedBox(height: 12),
                    InfoPill(
                      icon: Symbols.call_rounded,
                      text: 'Phone, messages and clock always stay open.',
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

class _AppToggle extends StatelessWidget {
  final String name;
  final String package;
  final bool selected;
  final VoidCallback onTap;
  final dynamic iconBytes; // Uint8List? from installed_apps
  const _AppToggle({
    required this.name,
    required this.package,
    required this.selected,
    required this.onTap,
    this.iconBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: selected ? AppColors.primarySoft : Colors.transparent,
            ),
            child: Row(
              children: [
                AppBrandIcon(package, size: 40, iconBytes: iconBytes),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        categoryFor(package),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(value: selected, onChanged: (_) => onTap()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
