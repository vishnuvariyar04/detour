// screens/onboarding/onboarding_flow.dart — setup, after sign-in.
//
//   Their course   name → buddy → what they'll learn → how Nupo teaches → path
//   Setup          apps → the trade → parent PIN
//   Permissions    intro → overlay → usage → battery → (autostart)
//   Ready          what happens next
//
// The story before sign-in (`story_flow.dart`) already asked the child's age
// and which app they open first; both are in Storage by the time this runs.
// Auth and the paywall stay route-level gates in `RootRouter`, never in here.
//
// The four permission steps keep their detection and auto-advance logic
// unchanged (see brainpass-detection-pitfalls); only their look changed.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../analytics.dart';
import '../../engine.dart';
import '../../profile_service.dart';
import '../../storage.dart';
import '../../theme.dart';
import '../app_picker_screen.dart';
import '../permission_step.dart';
import '../pin_create_screen.dart';
import 'course_steps.dart';
import 'perm_heroes.dart';
import 'permissions_intro.dart';

class OnboardingFlow extends StatefulWidget {
  /// Called when the parent leaves the Ready screen; the router then shows home.
  final VoidCallback? onComplete;
  const OnboardingFlow({super.key, this.onComplete});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _step = 0;
  bool _autostartRelevant = false;
  bool _transitioning = false;

  /// Guards [_activate] against running twice: it is scheduled from build(),
  /// and build can run again before it finishes (a late autostart probe, the
  /// keyboard closing). Without this the engine sync, the profile sync AND the
  /// `setup_complete` activation event would fire more than once.
  bool _activated = false;
  Timer? _transitionTimer;

  @override
  void initState() {
    super.initState();
    _logStep(0);
    Engine.autostartRelevant().then((v) {
      if (mounted) setState(() => _autostartRelevant = v);
    });
  }

  /// Emit the funnel step for [index]. Only the named steps are logged here —
  /// the permission screens report themselves per permission. See analytics.dart.
  void _logStep(int index) {
    if (index < 0 || index >= Analytics.onbSteps.length) return;
    Analytics.onbStep(index, Analytics.onbSteps[index]);
  }

  void _move(int delta) {
    // One gesture always equals one step, even on a fast double tap.
    if (_transitioning) return;
    _transitioning = true;
    final next = (_step + delta).clamp(0, 99);
    if (delta > 0) _logStep(next);
    setState(() => _step = next);
    _transitionTimer?.cancel();
    _transitionTimer = Timer(const Duration(milliseconds: 460), () {
      _transitioning = false;
    });
  }

  void _next() => _move(1);
  void _back() => _move(-1);

  @override
  void dispose() {
    _transitionTimer?.cancel();
    super.dispose();
  }

  /// Setup is done the moment the Ready screen shows: gating starts now, not
  /// when the parent taps the last button.
  Future<void> _activate() async {
    await Storage.setOnboardingComplete(true);
    // THE activation event — mark it as a key event in GA4.
    Analytics.setupComplete(
      ageBand: Storage.ageBand,
      subject: Storage.onbSubject,
      appsGated: Storage.gatedApps.length,
    );
    Analytics.setProfile(
      ageBand: Storage.ageBand,
      subject: Storage.onbSubject,
      appsGated: Storage.gatedApps.length,
      onboardingDone: true,
    );
    await syncToEngine();
    ProfileService.sync();
  }

  List<Widget> _permissionSteps(int first, int total) {
    final count = _autostartRelevant ? 4 : 3;
    var n = first;
    var k = 1;
    return [
      PermissionStepScreen(
        key: const ValueKey('perm-overlay'),
        permissionId: 'overlay',
        icon: Symbols.layers_rounded,
        title: 'Let lessons appear',
        subtitle: 'Turn on “Display over other apps”.',
        buttonLabel: 'Turn it on',
        check: Engine.canDrawOverlays,
        request: Engine.requestOverlay,
        videoKey: 'perm_overlay',
        returnKind: 'overlay',
        footnote: 'You’ll come straight back.',
        hero: const OverlayHero(),
        heroTint: Color.lerp(Colors.white, AppColors.primary, 0.12),
        stepLabel: '${k++} of $count',
        step: n++,
        total: total,
        onNext: _next,
      ),
      PermissionStepScreen(
        key: const ValueKey('perm-usage'),
        permissionId: 'usage',
        icon: Symbols.visibility_rounded,
        title: 'Let Nupo see app opens',
        subtitle: 'Find Nupo and switch it on.',
        buttonLabel: 'Turn it on',
        check: Engine.hasUsageAccess,
        request: Engine.openUsageAccessSettings,
        showFindCard: true,
        videoKey: 'perm_usage',
        returnKind: 'usage',
        footnote: 'You’ll come straight back.',
        hero: const UsageHero(),
        heroTint: Color.lerp(Colors.white, AppColors.done, 0.14),
        stepLabel: '${k++} of $count',
        step: n++,
        total: total,
        onNext: _next,
      ),
      PermissionStepScreen(
        key: const ValueKey('perm-battery'),
        permissionId: 'battery',
        icon: Symbols.bolt_rounded,
        title: 'Keep Nupo awake',
        subtitle: 'Tap Allow on the popup.',
        buttonLabel: 'Allow',
        check: Engine.isIgnoringBattery,
        request: Engine.requestIgnoreBattery,
        videoKey: 'perm_battery',
        skippable: true,
        hero: const BatteryHero(),
        heroTint: AppColors.accentSoft,
        stepLabel: '${k++} of $count',
        step: n++,
        total: total,
        onNext: _next,
      ),
      if (_autostartRelevant)
        PermissionStepScreen(
          key: const ValueKey('perm-autostart'),
          permissionId: 'autostart',
          icon: Symbols.rocket_launch_rounded,
          title: 'Let Nupo restart itself',
          subtitle: 'Switch Autostart on for Nupo.',
          buttonLabel: 'Open settings',
          check: null, // can't be read on Xiaomi/etc. — advance on return
          request: Engine.openAutostartSettings,
          showFindCard: true,
          videoKey: 'perm_autostart',
          footnote: 'You’ll come straight back.',
          hero: const AutostartHero(),
          heroTint: AppColors.correctSoft,
          stepLabel: '${k++} of $count',
          step: n++,
          total: total,
          onNext: _next,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final permCount = 3 + (_autostartRelevant ? 1 : 0);
    // 9 named steps + the permissions + Ready.
    final total = 9 + permCount + 1;
    double p(int i) => (i + 1) / total;

    final screens = <Widget>[
      ChildNameStep(key: const ValueKey('name'), progress: p(0), onNext: _next),
      BuddyStep(key: const ValueKey('buddy'), progress: p(1), onBack: _back, onNext: _next),
      OutcomesStep(key: const ValueKey('outcomes'), progress: p(2), onBack: _back, onNext: _next),
      HowItTeachesStep(key: const ValueKey('how'), progress: p(3), onBack: _back, onNext: _next),
      PathStep(key: const ValueKey('path'), progress: p(4), onBack: _back, onNext: _next),
      AppPickerScreen(
        key: const ValueKey('picker'),
        step: 6,
        total: total,
        onNext: () {
          // Zero apps means the gate can never fire — worth seeing separately.
          Analytics.appsPicked(Storage.gatedApps.length);
          _next();
        },
      ),
      TradeStep(key: const ValueKey('trade'), progress: p(6), onBack: _back, onNext: _next),
      PinCreateScreen(key: const ValueKey('pin'), step: 8, total: total, onNext: _next),
      PermissionsIntroScreen(
        key: const ValueKey('perm-intro'),
        progress: p(8),
        autostart: _autostartRelevant,
        onBack: _back,
        onNext: _next,
      ),
      ..._permissionSteps(10, total),
      ReadyStep(
        key: const ValueKey('ready'),
        onDone: () => widget.onComplete?.call(),
      ),
    ];

    final index = _step.clamp(0, screens.length - 1);
    if (index == screens.length - 1 && !_activated) {
      _activated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _activate());
    }

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        // Setup is finished on Ready; going back from there would undo nothing.
        if (!didPop && _step > 0 && index != screens.length - 1) _back();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, a) => FadeTransition(opacity: a, child: child),
        // Key each step so Flutter never reuses one step's State for the next.
        child: KeyedSubtree(key: ValueKey('onb-step-$index'), child: screens[index]),
      ),
    );
  }
}
