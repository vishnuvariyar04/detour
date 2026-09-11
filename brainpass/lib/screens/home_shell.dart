// screens/home_shell.dart
//
// The app's home once setup is finished: two tabs behind a bottom bar.
//
//   Progress  the skill roadmap — the one screen a parent and a child are
//             meant to look at together
//   Parent    everything configurable, behind the PIN
//
// The PIN is asked once per visit to the Parent tab and forgotten as soon as the
// app leaves the foreground, so a child who picks the phone up later cannot walk
// back into settings.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../storage.dart';
import '../theme.dart';
import 'parent_home_screen.dart';
import 'pin_entry_screen.dart';
import 'roadmap_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _tab = 0;
  bool _parentUnlocked = false;
  bool _asking = false;
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    } else if (state == AppLifecycleState.paused) {
      // Leaving the app drops the unlock.
      if (mounted) {
        setState(() {
          _parentUnlocked = false;
          if (_tab == 1) _tab = 0;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await Storage.fresh();
    if (!mounted) return;
    setState(() => _enabled = Storage.masterEnabled);
  }

  Future<void> _select(int i) async {
    if (i == _tab) return;
    if (i == 1 && !_parentUnlocked) {
      if (_asking) return;
      _asking = true;
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const PinEntryScreen()),
      );
      _asking = false;
      if (!mounted || ok != true) return;
      setState(() {
        _parentUnlocked = true;
        _tab = 1;
      });
      return;
    }
    setState(() => _tab = i);
    if (i == 0) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (!_enabled) const _PausedBanner(),
            Expanded(
              child: _tab == 0
                  ? const RoadmapScreen()
                  : const ParentHomeScreen(embedded: true),
            ),
          ],
        ),
      ),
      // A floating pill rather than a full-width bar: it reads as a control
      // sitting on top of the page instead of a wall closing it off, and the
      // rounded shape matches every other surface in the app.
      //
      // The body stops above it rather than scrolling under: with a pill there
      // are gaps down each side, and content sliding through those gaps read as
      // a glitch rather than as depth.
      bottomNavigationBar: Container(
        color: AppColors.bg,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 10),
            child: Container(
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.cardBorder, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x146D28D9),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _Tab(
                    icon: Symbols.route_rounded,
                    label: 'Progress',
                    selected: _tab == 0,
                    onTap: () => _select(0),
                  ),
                  _Tab(
                    icon: Symbols.lock_rounded,
                    label: 'Parent',
                    selected: _tab == 1,
                    onTap: () => _select(1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.textMuted;
    // The selected tab is a filled pill, so which one you are on is legible at
    // a glance rather than from a colour difference alone.
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Material(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 21, color: color),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Nupo being off is the one state that makes the roadmap misleading, so it is
/// said plainly at the top rather than left to the settings tab.
class _PausedBanner extends StatelessWidget {
  const _PausedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.accentSoft,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Icon(
            Symbols.pause_circle_rounded,
            size: 18,
            color: AppColors.accentDeep,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Nupo is paused — apps open without a learning moment.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.accentDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
