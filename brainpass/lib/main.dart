// main.dart — parent app entry point.
//
// The kid lock is 100% native (see android/.../GuardService + LockUi), so
// Flutter is ONLY the parent UI: onboarding, settings, dashboard. On startup we
// push saved config down to the native engine and start the guard.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'auth_service.dart';
import 'engine.dart';
import 'profile_service.dart';
import 'remote_config_service.dart';
import 'subscription_service.dart';
import 'screens/paywall_gate_screen.dart';
import 'screens/age_band_screen.dart';
import 'screens/app_picker_screen.dart';
import 'screens/app_rules_screen.dart';
import 'screens/login/login_flow.dart';
import 'screens/splash_screen.dart';
import 'screens/permission_step.dart';
import 'screens/pin_create_screen.dart';
import 'screens/pin_entry_screen.dart';
import 'screens/parent_home_screen.dart';
import 'storage.dart';
import 'theme.dart';
import 'widgets.dart';

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
  // Firebase powers optional parent login. It must never block the offline
  // app, so a failure here is swallowed — the app runs exactly as before.
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  // RevenueCat (Nupo Pro). Fail-safe: falls back to the cached entitlement.
  await SubscriptionService.init();
  // Remote kill-switch for paywall enforcement (see remote_config_service.dart).
  await RemoteConfigService.init();
  if (Storage.onboardingComplete) {
    await syncToEngine();
  }
  runApp(const BrainPassApp());
}

class BrainPassApp extends StatelessWidget {
  const BrainPassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nupo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.parent(),
      // Always open on the yellow brand splash, then hand off to the router.
      home: SplashScreen(nextBuilder: () => const RootRouter()),
    );
  }
}

// ---------------------------------------------------------------------------
// Root router — decides what to show after the splash, and reacts to login /
// logout / entitlement changes so every gate is always enforced.
//   not signed in         -> LoginFlow (mandatory)
//   signed in, no setup    -> OnboardingFlow
//   set up, no Nupo Pro     -> PaywallGateScreen (hard paywall)
//   set up + Nupo Pro        -> ActiveLanding
// ---------------------------------------------------------------------------
class RootRouter extends StatefulWidget {
  const RootRouter({super.key});

  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> {
  late bool _loggedIn = AuthService.isLoggedIn;
  StreamSubscription<Object?>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = AuthService.authState().listen((user) {
      if (user != null) {
        // Fires on app start and on every sign-in.
        ProfileService.sync();
        SubscriptionService.logIn(user.uid); // purchases follow the account
      } else {
        SubscriptionService.logOut();
      }
      if (mounted) setState(() => _loggedIn = user != null);
    });
    SubscriptionService.hasPro.addListener(_onGateChanged);
    RemoteConfigService.paywallEnabled.addListener(_onGateChanged);
  }

  void _onGateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    SubscriptionService.hasPro.removeListener(_onGateChanged);
    RemoteConfigService.paywallEnabled.removeListener(_onGateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loggedIn) return const LoginFlow();
    if (!Storage.onboardingComplete) {
      return OnboardingFlow(onComplete: () => setState(() {}));
    }
    // Remote kill-switch: lets us disable the paywall for everyone instantly
    // (e.g. while a payment processor is still being verified) without a new
    // Play Store release. See remote_config_service.dart.
    if (RemoteConfigService.paywallEnabled.value &&
        !SubscriptionService.hasPro.value) {
      return const PaywallGateScreen();
    }
    return const ActiveLanding();
  }
}

// ---------------------------------------------------------------------------
// Onboarding flow
// ---------------------------------------------------------------------------
class OnboardingFlow extends StatefulWidget {
  /// Called once setup is finished; the router then shows the home screen.
  final VoidCallback? onComplete;
  const OnboardingFlow({super.key, this.onComplete});
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
    // Capture age band / app count in the parent's profile (fire-and-forget).
    ProfileService.sync();
    if (!mounted) return;
    widget.onComplete?.call();
  }

  List<Widget> _permissionSteps(int firstStep, int total) {
    var n = firstStep;
    return [
      PermissionStepScreen(
        key: const ValueKey('perm-overlay'),
        icon: Icons.shield_rounded,
        mascot: 'assets/mascot_pin.png',
        title: 'Let Nupo pop up',
        subtitle: 'So a quick lesson can appear over the app.',
        buttonLabel: 'Allow',
        check: Engine.canDrawOverlays,
        request: Engine.requestOverlay,
        step: n++,
        total: total,
        onNext: _next,
      ),
      PermissionStepScreen(
        key: const ValueKey('perm-usage'),
        icon: Icons.visibility_rounded,
        heroColor: AppColors.primary,
        heroBackground: AppColors.primarySoft,
        title: "See what's open",
        subtitle: 'So Nupo knows the right moment for a lesson.',
        buttonLabel: 'Allow',
        check: Engine.hasUsageAccess,
        request: Engine.openUsageAccessSettings,
        showFindCard: true,
        step: n++,
        total: total,
        onNext: _next,
      ),
      PermissionStepScreen(
        key: const ValueKey('perm-battery'),
        icon: Icons.bolt_rounded,
        heroColor: AppColors.accent,
        heroBackground: AppColors.accentSoft,
        title: 'Stay awake',
        subtitle: 'Keeps Nupo ready in the background.',
        buttonLabel: 'Allow',
        check: Engine.isIgnoringBattery,
        request: Engine.requestIgnoreBattery,
        skippable: true,
        step: n++,
        total: total,
        onNext: _next,
      ),
      if (_autostartRelevant)
        PermissionStepScreen(
          key: const ValueKey('perm-autostart'),
          icon: Icons.rocket_launch_rounded,
          heroColor: AppColors.correct,
          heroBackground: AppColors.correctSoft,
          title: 'Auto-restart',
          subtitle: 'Nupo needs this to keep working. Switch it on for Nupo.',
          buttonLabel: 'Open settings',
          check: null, // can't be read on Xiaomi/etc. — advance on return
          request: Engine.openAutostartSettings,
          showFindCard: true,
          skippable: false,
          step: n++,
          total: total,
          onNext: _next,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Steps after the intro: pin, permissions (3–4), age, apps, rules.
    final permCount = 3 + (_autostartRelevant ? 1 : 0);
    final total = permCount + 4;
    final steps = <Widget>[
      PinCreateScreen(
        key: const ValueKey('pin'),
        onNext: _next,
        step: 1,
        total: total,
      ),
      ..._permissionSteps(2, total),
      AgeBandScreen(
        key: const ValueKey('age'),
        onNext: _next,
        step: permCount + 2,
        total: total,
      ),
      AppPickerScreen(
        key: const ValueKey('picker'),
        onNext: _next,
        step: permCount + 3,
        total: total,
      ),
      AppRulesScreen(
        key: const ValueKey('rules'),
        onNext: _finish,
        step: permCount + 4,
        total: total,
      ),
    ];
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) setState(() => _step--);
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.06, 0), end: Offset.zero)
                .animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(_step),
          child: steps[_step.clamp(0, steps.length - 1)],
        ),
      ),
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
      body: Container(
        decoration: AppColors.bgDecoration(),
        height: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              // Mascot on its sunny halo, with celebration stars when active
              HaloMascot('assets/mascot_opening.png',
                  size: 200, sparkles: _enabled),
              const SizedBox(height: 12),

              // Status pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _enabled ? AppColors.correctSoft : const Color(0xFFEFEDF6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _enabled ? 'Learning on' : 'Paused',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Text(
                _enabled ? 'All set!' : 'Nupo is paused',
                style: AppText.display,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 44),
                child: Text(
                  _enabled
                      ? 'Your child gets a quick lesson before the apps they already love.'
                      : 'Apps open freely. Turn Nupo back on in settings.',
                  textAlign: TextAlign.center,
                  style: AppText.body,
                ),
              ),
              const SizedBox(height: 28),

              // How it works — three tiny chips, no paragraphs
              if (_enabled)
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MiniStep(
                      icon: Icons.touch_app_rounded,
                      label: 'Reach',
                      color: AppColors.primary,
                      background: AppColors.primarySoft,
                    ),
                    _StepArrow(),
                    _MiniStep(
                      icon: Icons.auto_stories_rounded,
                      label: 'Learn',
                      color: AppColors.accentDeep,
                      background: AppColors.accentSoft,
                    ),
                    _StepArrow(),
                    _MiniStep(
                      icon: Icons.play_arrow_rounded,
                      label: 'Play',
                      color: AppColors.correct,
                      background: AppColors.correctSoft,
                    ),
                  ],
                ),
              const Spacer(),

              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 20),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: 'Parent settings',
                      icon: Icons.lock_rounded,
                      onPressed: () => _openSettings(context),
                    ),
                    const SizedBox(height: 14),
                    const InfoPill(
                      icon: Icons.favorite_rounded,
                      text: 'A few minutes of learning, every day',
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

class _MiniStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  const _MiniStep({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
            boxShadow: AppColors.softShadow,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}

class _StepArrow extends StatelessWidget {
  const _StepArrow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 14, right: 14, bottom: 20),
      child: Icon(Icons.arrow_forward_rounded,
          color: Color(0xFFC9C2E8), size: 18),
    );
  }
}
