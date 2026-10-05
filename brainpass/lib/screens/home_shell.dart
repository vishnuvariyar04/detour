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

import '../analytics.dart';
import '../storage.dart';
import '../curriculum.dart';
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
  String _ageBand = Storage.ageBand;

  @override
  void initState() {
    super.initState();
    Analytics.homeShown(Storage.masterEnabled);
    Analytics.homeTab('roadmap');
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
    final nextBand = Storage.ageBand;
    if (nextBand != _ageBand) Curriculum.invalidate();
    setState(() {
      _enabled = Storage.masterEnabled;
      _ageBand = nextBand;
    });
  }

  Future<void> _select(int i) async {
    if (i == _tab) return;
    if (i == 1 && !_parentUnlocked) {
      if (_asking) return;
      _asking = true;
      final ok = await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => const PinEntryScreen()));
      _asking = false;
      Analytics.pinUnlock(ok == true);
      if (!mounted || ok != true) return;
      Analytics.homeTab('parent');
      setState(() {
        _parentUnlocked = true;
        _tab = 1;
      });
      return;
    }
    setState(() => _tab = i);
    Analytics.homeTab(i == 0 ? 'roadmap' : 'parent');
    if (i == 0) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primarySoft,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (!_enabled) const _PausedBanner(),
            Expanded(
              child: _tab == 0
                  ? RoadmapScreen(key: ValueKey('roadmap-$_ageBand'))
                  : ParentHomeScreen(
                      embedded: true,
                      onConfigurationChanged: _refresh,
                    ),
            ),
          ],
        ),
      ),
      // Two tabs, so each gets half the bar: the selected one fills with
      // its colour like a pressed chunky button; the other stays quiet.
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppColors.cardBorder, width: 1.5),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Symbols.school_rounded,
                    label: 'Learning',
                    selected: _tab == 0,
                    onTap: () => _select(0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NavItem(
                    icon: _parentUnlocked
                        ? Symbols.lock_open_right_rounded
                        : Symbols.shield_lock_rounded,
                    label: 'Parent',
                    selected: _tab == 1,
                    onTap: () => _select(1),
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 50,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AppColors.primaryDeep,
                      blurRadius: 0,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: selected ? Colors.white : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ],
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
