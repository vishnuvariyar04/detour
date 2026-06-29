// main.dart — parent app entry point.
//
// The kid lock is now 100% native (see android/.../GuardService + LockUi), so
// Flutter is ONLY the parent UI: onboarding, settings, dashboard. On startup we
// push saved config down to the native engine and start the guard.

import 'package:flutter/material.dart';

import 'engine.dart';
import 'screens/age_band_screen.dart';
import 'screens/app_picker_screen.dart';
import 'screens/app_rules_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/permission_step.dart';
import 'screens/pin_create_screen.dart';
import 'screens/pin_entry_screen.dart';
import 'screens/parent_home_screen.dart';
import 'storage.dart';
import 'theme.dart';

/// Push all saved parent config down to the native engine (after launch / update
/// / reboot) and start the guard.
Future<void> syncToEngine() async {
  await Engine.setRules(Storage.rulesForEngine());
  await Engine.setMasterEnabled(Storage.masterEnabled);
  await Engine.setAgeBand(Storage.ageBand);
  final h = Storage.pinHash, s = Storage.pinSalt;
  if (h != null && s != null) await Engine.setPin(h, s);
  await Engine.startGuard();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  if (Storage.onboardingComplete) {
    await syncToEngine();
  }
  runApp(const BrainPassApp());
}

class BrainPassApp extends StatelessWidget {
  const BrainPassApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Widget home =
        Storage.onboardingComplete ? const ActiveLanding() : const OnboardingFlow();
    return MaterialApp(
      title: 'Nupo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.parent(),
      home: home,
    );
  }
}

// ---------------------------------------------------------------------------
// Onboarding flow (spec §15 step 5)
// ---------------------------------------------------------------------------
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});
  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _step = 0;
  bool _autostartRelevant = false;

  @override
  void initState() {
    super.initState();
    Engine.autostartRelevant().then((v) {
      if (mounted) setState(() => _autostartRelevant = v);
    });
  }

  void _next() => setState(() => _step++);

  Future<void> _finish() async {
    await Storage.setOnboardingComplete(true);
    // Push everything down to the native engine so gating starts immediately.
    await syncToEngine();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ActiveLanding()),
    );
  }

  List<Widget> _permissionSteps() {
    final total = 3 + (_autostartRelevant ? 1 : 0);
    return [
      PermissionStepScreen(
        key: const ValueKey('perm-overlay'),
        emoji: '🛡️',
        title: 'Show the lock',
        subtitle: 'Lets Nupo cover apps with the questions.',
        buttonLabel: 'Allow',
        check: Engine.canDrawOverlays,
        request: Engine.requestOverlay,
        step: 1,
        total: total,
        onNext: _next,
      ),
      PermissionStepScreen(
        key: const ValueKey('perm-usage'),
        emoji: '👀',
        title: "Know what's open",
        subtitle: 'So Nupo knows when to ask questions.',
        buttonLabel: 'Allow',
        check: Engine.hasUsageAccess,
        request: Engine.openUsageAccessSettings,
        showFindCard: true,
        step: 2,
        total: total,
        onNext: _next,
      ),
      PermissionStepScreen(
        key: const ValueKey('perm-battery'),
        emoji: '🔋',
        title: "Don't fall asleep",
        subtitle: 'Keeps Nupo working in the background.',
        buttonLabel: 'Allow',
        check: Engine.isIgnoringBattery,
        request: Engine.requestIgnoreBattery,
        skippable: true,
        step: 3,
        total: total,
        onNext: _next,
      ),
      if (_autostartRelevant)
        PermissionStepScreen(
          key: const ValueKey('perm-autostart'),
          emoji: '🚀',
          title: 'Auto-restart',
          subtitle: 'Lets Nupo turn itself back on.',
          buttonLabel: 'Open settings',
          check: null, // can't be read on Xiaomi/etc. — advance on return
          request: Engine.openAutostartSettings,
          showFindCard: true,
          skippable: true,
          step: 4,
          total: total,
          onNext: _next,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final steps = <Widget>[
      IntroScreen(onNext: _next),
      PinCreateScreen(onNext: _next),
      ..._permissionSteps(),
      AgeBandScreen(onNext: _next),
      AppPickerScreen(onNext: _next),
      AppRulesScreen(onNext: _finish),
    ];
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) setState(() => _step--);
      },
      child: steps[_step.clamp(0, steps.length - 1)],
    );
  }
}

// ---------------------------------------------------------------------------
// Landing shown after setup
// ---------------------------------------------------------------------------
class ActiveLanding extends StatefulWidget {
  const ActiveLanding({super.key});

  @override
  State<ActiveLanding> createState() => _ActiveLandingState();
}

class _ActiveLandingState extends State<ActiveLanding>
    with WidgetsBindingObserver {
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
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    await Storage.fresh();
    if (!mounted) return;
    setState(() => _enabled = Storage.masterEnabled);
  }

  Future<void> _openSettings(BuildContext context) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PinEntryScreen()),
    );
    if (ok == true && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ParentHomeScreen()),
      );
    }
    _refresh(); // reflect any pause/resume change made in settings
  }

  @override
  Widget build(BuildContext context) {
    final color = _enabled ? AppColors.correct : AppColors.textMuted;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _enabled ? Icons.check_rounded : Icons.pause_rounded,
                  color: color,
                  size: 54,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _enabled ? 'Nupo is active' : 'Nupo is paused',
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark),
              ),
              const SizedBox(height: 10),
              Text(
                _enabled
                    ? 'Your child now earns screen time by solving quick '
                        'problems. You can hand them the phone.'
                    : 'Gating is turned off — apps open freely. Turn it back on '
                        'in Parent settings.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 16, color: AppColors.textMuted, height: 1.4),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _openSettings(context),
                icon: const Icon(Icons.lock_rounded),
                label: const Text('Parent settings'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
