// main.dart — parent app entry point.
//
// The kid lock is 100% native (see android/.../GuardService + LockUi), so
// Flutter is ONLY the parent UI: onboarding, settings, dashboard. On startup we
// push saved config down to the native engine and start the guard.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

import 'analytics.dart';
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
import 'screens/pin_create_screen.dart';
import 'screens/home_shell.dart';
import 'storage.dart';
import 'theme.dart';
import 'widgets.dart';

/// Lets design-QA builds open onboarding without clearing saved family data.
/// Enable with `--dart-define=NUPO_PREVIEW_ONBOARDING=true`.
const _previewOnboarding = bool.fromEnvironment(
  'NUPO_PREVIEW_ONBOARDING',
  defaultValue: false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The scroll story derives its position from the viewport HEIGHT
  // (t = 1 + offset / vh), so a rotation mid-story rescales t past the last
  // beat and the screen goes blank. The whole parent UI is designed portrait;
  // lock it here as well as in the manifest.
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );
  await Storage.init();
  // Firebase powers optional parent login. It must never block the offline
  // app, so a failure here is swallowed — the app runs exactly as before.
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  // Funnel + retention. Fail-safe like everything else here: if it throws,
  // every Analytics call downstream quietly no-ops. See analytics.dart.
  await Analytics.init();
  await Analytics.setProfile(
    ageBand: Storage.ageBand,
    subject: Storage.onbSubject,
    appsGated: Storage.gatedApps.length,
    onboardingDone: Storage.onboardingComplete,
  );
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
//   set up + Nupo Pro        -> HomeShell (roadmap + parent tabs)
// ---------------------------------------------------------------------------
class RootRouter extends StatefulWidget {
  const RootRouter({super.key});

  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> {
  late bool _loggedIn = AuthService.isLoggedIn;
  late bool _storySeen = Storage.storySeen;

  /// True while a saved setup is being pulled down after sign-in. Without
  /// this the router paints OnboardingFlow for a frame or two and a returning
  /// parent sees the questions flash past before landing home.
  bool _restoring = false;
  bool _previewStoryDone = false;
  bool _previewFlowDone = false;
  StreamSubscription<Object?>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = AuthService.authState().listen((user) {
      // Tie the GA4 user to the Firestore `users/{uid}` doc so a funnel drop
      // can be traced to an actual account.
      Analytics.setUser(user?.uid, method: AuthService.providerId);
      if (user != null) {
        SubscriptionService.logIn(user.uid); // purchases follow the account
        _afterSignIn();
      } else {
        SubscriptionService.logOut();
      }
      if (mounted) setState(() => _loggedIn = user != null);
    });
    SubscriptionService.hasPro.addListener(_onGateChanged);
    RemoteConfigService.paywallEnabled.addListener(_onGateChanged);
    Analytics.setProfile(hasPro: SubscriptionService.hasPro.value);
  }

  /// Fires on app start and on every sign-in. A returning parent's setup
  /// lives on their account, so pull it back before deciding whether to show
  /// onboarding — otherwise signing in restores the account but re-asks every
  /// question, which is no account at all.
  Future<void> _afterSignIn() async {
    if (!Storage.onboardingComplete) {
      if (mounted) setState(() => _restoring = true);
      final restored = await ProfileService.restore();
      if (restored) {
        // A returning parent, not a new one — they never see onboarding, so
        // without this event they would look like a funnel drop-out.
        Analytics.setupRestored();
        Analytics.setProfile(
          ageBand: Storage.ageBand,
          subject: Storage.onbSubject,
          appsGated: Storage.gatedApps.length,
          onboardingDone: true,
        );
        // Push the restored rules down so gating works on this device now,
        // not at next launch.
        await syncToEngine();
      }
      if (mounted) {
        setState(() {
          _restoring = false;
          _storySeen = Storage.storySeen;
        });
      }
    }
    await ProfileService.sync();
  }

  void _onGateChanged() {
    Analytics.setProfile(hasPro: SubscriptionService.hasPro.value);
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
    if (_previewOnboarding && !_previewStoryDone) {
      return OnboardingStory(
        onFinished: () => setState(() => _previewStoryDone = true),
        onLogIn: () => setState(() => _previewStoryDone = true),
        onAppPicked: (_) {},
      );
    }
    if (_previewOnboarding && !_previewFlowDone) {
      return OnboardingFlow(
        onComplete: () => setState(() => _previewFlowDone = true),
      );
    }
    // Signed in, and their saved setup is on its way down.
    if (_restoring) return const _RestoringScreen();
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
    // A restored setup arrives WITHOUT a PIN: the PIN is a salted hash that
    // deliberately never leaves the device, so a parent signing in on a new
    // phone (or after clearing data) had completed setup and no PIN to match.
    // Parent settings then rejected every PIN they tried, with no way to set
    // one. Setup-complete-but-no-PIN is not a valid state; heal it here.
    if (!Storage.hasPin) {
      return PinCreateScreen(
        key: const ValueKey('pin-after-restore'),
        onNext: () async {
          await syncToEngine(); // push the new PIN down to the native lock
          if (mounted) setState(() {});
        },
      );
    }
    // Remote kill-switch: lets us disable the paywall for everyone instantly
    // (e.g. while a payment processor is still being verified) without a new
    // Play Store release. See remote_config_service.dart.
    if (RemoteConfigService.paywallEnabled.value &&
        !SubscriptionService.hasPro.value) {
      return const PaywallGateScreen();
    }
    return const HomeShell();
  }
}

// ---------------------------------------------------------------------------
// Shown for the moment between signing in and the saved setup landing.
// ---------------------------------------------------------------------------
class _RestoringScreen extends StatelessWidget {
  const _RestoringScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppColors.bgDecoration(),
        height: double.infinity,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const HaloMascot('assets/nupo/wave.png', size: 150),
              const SizedBox(height: 26),
              const Text('Welcome back', style: AppText.title),
              const SizedBox(height: 10),
              const Text(
                'Getting your saved setup...',
                style: AppText.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
