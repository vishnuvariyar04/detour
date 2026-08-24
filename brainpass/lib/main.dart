// main.dart — parent app entry point.
//
// The kid lock is 100% native (see android/.../GuardService + LockUi), so
// Flutter is ONLY the parent UI: onboarding, settings, dashboard. On startup we
// push saved config down to the native engine and start the guard.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'auth_service.dart';
import 'engine.dart';
import 'profile_service.dart';
import 'remote_config_service.dart';
import 'subscription_service.dart';
import 'screens/paywall_gate_screen.dart';
import 'screens/login/login_flow.dart';
import 'screens/onboarding/onboarding_flow.dart';
import 'screens/onboarding/story_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/pin_entry_screen.dart';
import 'screens/parent_home_screen.dart';
import 'storage.dart';
import 'theme.dart';
import 'widgets.dart';

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
//   story not seen        -> StoryScreen (the scroll story; sells the app)
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
  late bool _storySeen = Storage.storySeen;
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
    // The scroll story runs before anything else for a brand-new install —
    // a returning parent who taps "I already have an account" skips it too.
    if (!_storySeen && !_loggedIn) {
      return OnboardingStory(
        onFinished: () async {
          await Storage.setStorySeen(true);
          if (mounted) setState(() => _storySeen = true);
        },
        onLogIn: () async {
          await Storage.setStorySeen(true);
          if (mounted) setState(() => _storySeen = true);
        },
        // The app they pick in the story pre-ticks the real picker later.
        onAppPicked: (app) => Storage.setReachApps([app.bundleId]),
      );
    }
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
                      ? 'When your child opens a chosen app, Nupo asks a few quick questions first — then they play.'
                      : 'Apps open freely right now. Turn Nupo back on in Parent settings.',
                  textAlign: TextAlign.center,
                  style: AppText.body,
                ),
              ),
              const SizedBox(height: 28),

              // How it works — three tiny chips, no paragraphs
              if (_enabled)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MiniStep(
                      icon: Symbols.touch_app_rounded,
                      label: 'Open app',
                      color: AppColors.primary,
                      background: AppColors.primarySoft,
                    ),
                    const _StepArrow(),
                    _MiniStep(
                      icon: Symbols.auto_stories_rounded,
                      label: 'Answer',
                      color: AppColors.accentDeep,
                      background: AppColors.accentSoft,
                    ),
                    const _StepArrow(),
                    _MiniStep(
                      icon: Symbols.play_arrow_rounded,
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
                      icon: Symbols.lock_rounded,
                      onPressed: () => _openSettings(context),
                    ),
                    const SizedBox(height: 14),
                    InfoPill(
                      icon: Symbols.favorite_rounded,
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
