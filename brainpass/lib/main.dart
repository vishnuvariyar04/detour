// main.dart — app entry point and routing.
//
// There is now a SINGLE entry point. The kid earn screen is no longer a separate
// overlay isolate; it's a normal screen the native engine launches this activity
// into (via a "lock_package" intent extra), or pushes onto a running app.

import 'package:flutter/material.dart';

import 'engine.dart';
import 'screens/age_band_screen.dart';
import 'screens/app_picker_screen.dart';
import 'screens/app_rules_screen.dart';
import 'screens/earn_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/permissions_screen.dart';
import 'screens/pin_create_screen.dart';
import 'screens/pin_entry_screen.dart';
import 'screens/parent_home_screen.dart';
import 'storage.dart';
import 'theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();
bool _lockShowing = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  Engine.init(_handleShowLock);

  // Keep the native engine in sync with saved settings (e.g. after an update
  // or reboot, before the parent opens settings).
  if (Storage.onboardingComplete) {
    await Engine.setRules(Storage.rulesForEngine());
    await Engine.setMasterEnabled(Storage.masterEnabled);
    await Engine.startGuard();
  }

  // If the native service launched us as a lock, this describes what to gate.
  final lockInfo = await Engine.getLaunchLockInfo();

  runApp(BrainPassApp(initialLock: lockInfo));
}

/// Warm relaunch as a lock (app already running) — push the earn screen.
void _handleShowLock(LockInfo info) {
  if (_lockShowing) return;
  final nav = navigatorKey.currentState;
  if (nav == null) return;
  _lockShowing = true;
  nav
      .push(MaterialPageRoute(builder: (_) => EarnScreen(info: info)))
      .then((_) => _lockShowing = false);
}

class BrainPassApp extends StatelessWidget {
  final LockInfo? initialLock;
  const BrainPassApp({super.key, this.initialLock});

  @override
  Widget build(BuildContext context) {
    final Widget home;
    if (initialLock != null) {
      _lockShowing = true;
      home = EarnScreen(info: initialLock!);
    } else if (Storage.onboardingComplete) {
      home = const ActiveLanding();
    } else {
      home = const OnboardingFlow();
    }
    return MaterialApp(
      title: 'BrainPass',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.parent(),
      navigatorKey: navigatorKey,
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
  void _next() => setState(() => _step++);

  Future<void> _finish() async {
    await Storage.setOnboardingComplete(true);
    // Push everything down to the native engine so gating starts immediately.
    await Engine.setRules(Storage.rulesForEngine());
    await Engine.setMasterEnabled(Storage.masterEnabled);
    await Engine.startGuard();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ActiveLanding()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final steps = <Widget>[
      IntroScreen(onNext: _next),
      PinCreateScreen(onNext: _next),
      PermissionsScreen(onNext: _next),
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
class ActiveLanding extends StatelessWidget {
  const ActiveLanding({super.key});

  Future<void> _openSettings(BuildContext context) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PinEntryScreen()),
    );
    if (ok == true && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ParentHomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  color: AppColors.correct.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.correct, size: 54),
              ),
              const SizedBox(height: 24),
              const Text(
                'BrainPass is active',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your child now earns screen time by solving quick problems. '
                'You can hand them the phone.',
                textAlign: TextAlign.center,
                style: TextStyle(
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
