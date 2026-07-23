// screens/onboarding/onboarding_flow.dart
//
// The full onboarding funnel (nupo_onboarding_spec.md): hook → names →
// diagnostic → shock/reframe/hope → goals + mirror → empathy → gate demo →
// owl → projection → commitment → setup (apps, rules, PIN) → permissions →
// attribution → why-it-works → done (the router then shows the paywall).
//
// The four permission steps are UNCHANGED from the previous flow — same
// screens, same checks, same auto-advance behaviour.

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../engine.dart';
import '../../profile_service.dart';
import '../../storage.dart';
import '../../theme.dart';
import '../app_picker_screen.dart';
import '../app_rules_screen.dart';
import '../permission_step.dart';
import '../pin_create_screen.dart';
import 'building_screen.dart';
import 'demo_gate_screen.dart';
import 'hook_screen.dart';
import 'onb_widgets.dart';
import 'owl_screens.dart';
import 'survey_screens.dart';

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

  // The four permission steps — kept exactly as before (overlay, usage,
  // battery, and Autostart on OEMs that have it).
  List<Widget> _permissionSteps(int firstStep, int total) {
    var n = firstStep;
    return [
      PermissionStepScreen(
        key: const ValueKey('perm-overlay'),
        icon: Symbols.layers_rounded,
        mascot: 'assets/mascot_pin.png',
        title: 'Let lessons appear',
        subtitle:
            'Turn on “Display over other apps”. This lets Nupo show a quick '
            'question before a game or video opens.',
        buttonLabel: 'Turn it on',
        check: Engine.canDrawOverlays,
        request: Engine.requestOverlay,
        videoKey: 'perm_overlay',
        returnKind: 'overlay',
        footnote: "You'll be brought right back here.",
        step: n++,
        total: total,
        onNext: _next,
      ),
      PermissionStepScreen(
        key: const ValueKey('perm-usage'),
        icon: Symbols.visibility_rounded,
        heroColor: AppColors.primary,
        heroBackground: AppColors.primarySoft,
        title: 'Let Nupo see app opens',
        subtitle:
            'Find Nupo in the list and switch it on. This is how Nupo knows '
            "it's lesson time.",
        buttonLabel: 'Turn it on',
        check: Engine.hasUsageAccess,
        request: Engine.openUsageAccessSettings,
        showFindCard: true,
        videoKey: 'perm_usage',
        returnKind: 'usage',
        footnote: "You'll be brought right back here.",
        step: n++,
        total: total,
        onNext: _next,
      ),
      PermissionStepScreen(
        key: const ValueKey('perm-battery'),
        icon: Symbols.bolt_rounded,
        heroColor: AppColors.accent,
        heroBackground: AppColors.accentSoft,
        title: 'Keep Nupo awake',
        subtitle:
            "Tap Allow on the popup, so your phone doesn't put Nupo to sleep.",
        buttonLabel: 'Allow',
        check: Engine.isIgnoringBattery,
        request: Engine.requestIgnoreBattery,
        videoKey: 'perm_battery',
        skippable: true,
        step: n++,
        total: total,
        onNext: _next,
      ),
      if (_autostartRelevant)
        PermissionStepScreen(
          key: const ValueKey('perm-autostart'),
          icon: Symbols.rocket_launch_rounded,
          heroColor: AppColors.correct,
          heroBackground: AppColors.correctSoft,
          title: 'Let Nupo restart itself',
          subtitle:
              'Phones sometimes close apps to save power. Find Nupo in the '
              'list and switch Autostart on.',
          buttonLabel: 'Open settings',
          check: null, // can't be read on Xiaomi/etc. — advance on return
          request: Engine.openAutostartSettings,
          showFindCard: true,
          videoKey: 'perm_autostart',
          skippable: false,
          step: n++,
          total: total,
          onNext: _next,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final permCount = 3 + (_autostartRelevant ? 1 : 0);
    // Screens before / after the permissions block (counts must match the
    // lists below so the progress bar is honest).
    const preCount = 28;
    const postCount = 2;
    final total = preCount + permCount + postCount;

    var n = 0; // running step number for the progress bar
    final steps = <Widget>[
      // PHASE 0 — hook + micro-aha (S1–S4). Immersive, no progress bar.
      HookScreen(key: ValueKey('hook-${++n}'), onNext: _next),
      // PHASE 1 — names (S5–S6). Stored locally; never transmitted (§7).
      NameInputScreen(
        key: const ValueKey('parent-name'),
        step: ++n,
        total: total,
        title: 'First — what should we call you?',
        hint: 'Your name',
        initial: Storage.parentName,
        onDone: (v) async {
          await Storage.setParentName(v);
          _next();
        },
      ),
      NameInputScreen(
        key: const ValueKey('child-name'),
        step: ++n,
        total: total,
        title: 'And what’s your child’s name?',
        subtitle: 'Nupo will use it to make everything personal. '
            'It never leaves this phone.',
        hint: 'Child’s name',
        initial: Storage.childName,
        onDone: (v) async {
          await Storage.setChildName(v);
          _next();
        },
      ),
      // PHASE 2 — honest diagnostic (S7–S9)
      DiagnosticIntroScreen(
          key: const ValueKey('diag'), step: ++n, total: total, onNext: _next),
      ChildAgeScreen(
          key: const ValueKey('age'), step: ++n, total: total, onNext: _next),
      ScreenTimeScreen(
          key: const ValueKey('screentime'),
          step: ++n,
          total: total,
          onNext: _next),
      // PHASE 3 — shock → reframe → hope (S10–S12)
      ShockScreen(
          key: const ValueKey('shock'), step: ++n, total: total, onNext: _next),
      ReframeScreen(
          key: const ValueKey('reframe'),
          step: ++n,
          total: total,
          onNext: _next),
      HopeScreen(
          key: const ValueKey('hope'), step: ++n, total: total, onNext: _next),
      // PHASE 4 — goals + mirror (S13–S14)
      GoalsScreen(
          key: const ValueKey('goals'), step: ++n, total: total, onNext: _next),
      MirrorScreen(
          key: const ValueKey('mirror'),
          step: ++n,
          total: total,
          onNext: _next),
      // PHASE 5 — empathy (S15–S18)
      VibeScreen(
          key: const ValueKey('vibe'), step: ++n, total: total, onNext: _next),
      TriedScreen(
          key: const ValueKey('tried'), step: ++n, total: total, onNext: _next),
      WhyBuiltScreen(
          key: const ValueKey('whybuilt'),
          step: ++n,
          total: total,
          onNext: _next),
      ReachAppsScreen(
          key: const ValueKey('reach'), step: ++n, total: total, onNext: _next),
      // PHASE 6 — building animation (S19). Full-bleed moment.
      BuildingPlanScreen(key: ValueKey('building-${++n}'), onNext: _next),
      // PHASE 7 — the big aha: the parent plays the gate (S20–S22)
      DemoIntroScreen(
          key: const ValueKey('demo-intro'),
          step: ++n,
          total: total,
          onNext: _next),
      DemoGateScreen(key: ValueKey('demo-gate-${++n}'), onNext: _next),
      DemoPayoffScreen(
          key: const ValueKey('demo-payoff'),
          step: ++n,
          total: total,
          onNext: _next),
      // PHASE 8 — meet + name the owl (S23–S24)
      MeetOwlScreen(
          key: const ValueKey('owl'), step: ++n, total: total, onNext: _next),
      NameInputScreen(
        key: const ValueKey('owl-name'),
        step: ++n,
        total: total,
        title: 'What should ${Storage.childNameOr()} call him?',
        subtitle: 'He can change it any time.',
        hint: 'Nupo',
        initial: Storage.owlName,
        ctaLabel: 'Let’s go',
        onDone: (v) async {
          await Storage.setOwlName(v);
          _next();
        },
      ),
      // PHASE 9–10 — projection + commitment (S25–S27)
      ProjectionScreen(
          key: const ValueKey('projection'),
          step: ++n,
          total: total,
          onNext: _next),
      CommitmentScreen(
          key: const ValueKey('commitment'),
          step: ++n,
          total: total,
          onNext: _next),
      ValidationScreen(
          key: const ValueKey('validation'),
          step: ++n,
          total: total,
          onNext: _next),
      // PHASE 11 — functional setup (S28–S30)
      AppPickerScreen(
          key: const ValueKey('picker'), step: ++n, total: total, onNext: _next),
      AppRulesScreen(
          key: const ValueKey('rules'), step: ++n, total: total, onNext: _next),
      PinCreateScreen(
          key: const ValueKey('pin'), step: ++n, total: total, onNext: _next),
      PermissionsIntroScreen(
        key: const ValueKey('perm-intro'),
        step: ++n,
        total: total,
        autostart: _autostartRelevant,
        onNext: _next,
      ),
      // Permissions — UNCHANGED (n advances by permCount inside)
      ..._permissionSteps(n + 1, total),
      // PHASE 12–13 — attribution + honest science (S34–S35)
      AttributionScreen(
        key: const ValueKey('attribution'),
        step: n + permCount + 1,
        total: total,
        onNext: _next,
      ),
      WhyItWorksScreen(
        key: const ValueKey('why-works'),
        step: n + permCount + 2,
        total: total,
        ctaLabel: 'Finish setup',
        onNext: _finish,
      ),
    ];
    assert(steps.length == total,
        'onboarding step count drifted: ${steps.length} vs $total');

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
