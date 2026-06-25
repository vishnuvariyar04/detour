// screens/app_picker_screen.dart — spec §9.5, §10, §13
//
// Parent toggles which apps to gate. Two sources:
//   1. The curated preset list (always shown).
//   2. The phone's installed apps (loaded on demand), filtered so the dialer,
//      messaging, contacts, clock, and settings can NEVER be selected (§13).
//
// Saves the selected package names to `gatedApps`.

import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

import '../engine.dart';
import '../safe_apps.dart';
import '../storage.dart';
import '../theme.dart';
import '../widgets.dart';

class AppPickerScreen extends StatefulWidget {
  final VoidCallback onNext;
  const AppPickerScreen({super.key, required this.onNext});

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
  }

  Future<void> _loadInstalled() async {
    setState(() => _loadingInstalled = true);
    try {
      final apps = await InstalledApps.getInstalledApps(
        excludeSystemApps: true,
        withIcon: true,
      );
      // Safety filter (§13) + drop anything already in the preset list.
      final presetPkgs = kPresetGateableApps.map((p) => p.package).toSet();
      apps.retainWhere(
          (a) => isGateable(a.packageName) && !presetPkgs.contains(a.packageName));
      apps.sort((a, b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (!mounted) return;
      setState(() => _installed = apps);
    } finally {
      if (mounted) setState(() => _loadingInstalled = false);
    }
  }

  void _toggle(String pkg) {
    if (!isGateable(pkg)) return; // hard guard (§13)
    setState(() {
      if (_selected.contains(pkg)) {
        _selected.remove(pkg);
      } else {
        _selected.add(pkg);
      }
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
    return StepScaffold(
      title: 'Apps to gate',
      subtitle:
          'Pick the games, video, and social apps your child must earn. '
          'Phone, messages, contacts, and clock can never be gated for safety.',
      buttonLabel: _selected.isEmpty ? 'Pick at least one app' : 'Save',
      onButton: _selected.isEmpty ? null : _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Common apps'),
          for (final p in kPresetGateableApps)
            _AppToggle(
              name: p.name,
              package: p.package,
              selected: _selected.contains(p.package),
              onTap: () => _toggle(p.package),
            ),
          const SizedBox(height: 16),
          const _SectionLabel('Other installed apps'),
          if (_installed == null)
            OutlinedButton.icon(
              onPressed: _loadingInstalled ? null : _loadInstalled,
              icon: _loadingInstalled
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.apps_rounded),
              label: Text(_loadingInstalled
                  ? 'Loading…'
                  : 'Show apps installed on this phone'),
            )
          else if (_installed!.isEmpty)
            const Text('No other gateable apps found.',
                style: TextStyle(color: AppColors.textMuted))
          else
            for (final a in _installed!)
              _AppToggle(
                name: a.name,
                package: a.packageName,
                icon: a.icon,
                selected: _selected.contains(a.packageName),
                onTap: () => _toggle(a.packageName),
              ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 0.6,
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
  final dynamic icon; // Uint8List? from installed_apps
  const _AppToggle({
    required this.name,
    required this.package,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : const Color(0xFFE8EAF2),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                if (icon != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(icon, width: 36, height: 36),
                  )
                else
                  const Icon(Icons.smartphone_rounded,
                      color: AppColors.primary, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
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
