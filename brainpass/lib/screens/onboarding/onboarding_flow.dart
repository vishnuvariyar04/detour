// screens/onboarding/onboarding_flow.dart — the value-first onboarding,
// ported from the iOS build (`iOS-conversion/`) so both platforms tell the
// same story with the same motion.
//
//   1-4    Make it personal   child's name → age → subject → name the owl
//   5-6    Show the future    curated month plan → projection
//   7      Close              why it works (Premack, no fake stats)
//   ——     ANDROID ONLY       apps → rules → PIN → the four permissions
//   —      Sign in + paywall  handled by the router, not this widget
//
// The scrolled story (`story_screen.dart`) runs BEFORE this, from the router,
// because on Android it also has to sell the app before the mandatory phone
// login. On iOS it is step 0 of this widget instead.
//
// ## What Android adds
//
// The iOS build ends here and does its real setup through Screen Time after
// the paywall. Android cannot: the gating engine needs usage access, an
// overlay, a battery exemption and (on some OEMs) autostart, plus a real app
// picker and a parent PIN. Those steps are appended, in the same visual
// language, and the four permission steps are UNCHANGED from the previous
// flow.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../analytics.dart';
import '../../engine.dart';
import '../../profile_service.dart';
import '../../storage.dart';
import '../../theme.dart';
import '../app_picker_screen.dart';
import '../app_rules_screen.dart';
import '../permission_step.dart';
import '../pin_create_screen.dart';
import 'onb_widgets.dart';
import 'permissions_intro.dart';
import 'plan_screens.dart';
import 'story_beats.dart' show Nupo;

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
  bool _transitioning = false;

  /// Guards [_finish] against being scheduled twice. It is triggered from
  /// build(), and build can run again in the async window between the last
  /// permission step and the router swapping this widget out — a late
  /// autostart probe, or the keyboard closing, is enough. Without this the
  /// engine sync, the profile sync AND the `setup_complete` activation event
  /// all fire more than once for one setup.
  bool _finishing = false;
  Timer? _transitionTimer;

  /// The questions carry the progress bar; the Android setup block that
  /// follows keeps counting so the parent can see the end.
  static const _total = 7;

  @override
  void initState() {
    super.initState();
    _logStep(0);
    Engine.autostartRelevant().then((v) {
      if (mounted) setState(() => _autostartRelevant = v);
    });
  }

  /// Emit the funnel step for [index]. Only the named steps are logged here —
  /// the permission screens that follow report themselves per permission, so
  /// it is visible WHICH one loses the parent. Logged from [_move] rather than
  /// build() so a rebuild (keyboard, autostart probe returning) cannot double
  /// count. See analytics.dart.
  void _logStep(int index) {
    if (index < 0 || index >= Analytics.onbSteps.length) return;
    Analytics.onbStep(index, Analytics.onbSteps[index]);
  }

  void _move(int delta) {
    // A second tap during the route animation used to advance another screen,
    // which looked like a random jump on fast phones. One gesture now always
    // equals one story beat.
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

  String get _child => Storage.childNameOr();

  Future<void> _finish() async {
    await Storage.setOnboardingComplete(true);
    // THE activation event — mark it as a key event in GA4. Everything before
    // it is funnel; everything after it is retention.
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
        permissionId: 'overlay',
        icon: Symbols.layers_rounded,
        mascot: 'assets/mascot_pin.png',
        title: 'Let lessons appear',
        subtitle:
            'Turn on “Display over other apps”. This is what lets Nupo show a '
            'question before a game or video opens.',
        buttonLabel: 'Turn it on',
        check: Engine.canDrawOverlays,
        request: Engine.requestOverlay,
        videoKey: 'perm_overlay',
        returnKind: 'overlay',
        footnote: 'You will come straight back here.',
        step: n++,
        total: total,
        onNext: _next,
      ),
      PermissionStepScreen(
        key: const ValueKey('perm-usage'),
        permissionId: 'usage',
        icon: Symbols.visibility_rounded,
        heroColor: AppColors.primary,
        heroBackground: AppColors.primarySoft,
        title: 'Let Nupo notice app opens',
        subtitle:
            'Find Nupo in the list and switch it on. This is how Nupo knows '
            'it is lesson time.',
        buttonLabel: 'Turn it on',
        check: Engine.hasUsageAccess,
        request: Engine.openUsageAccessSettings,
        showFindCard: true,
        videoKey: 'perm_usage',
        returnKind: 'usage',
        footnote: 'You will come straight back here.',
        step: n++,
        total: total,
        onNext: _next,
      ),
      PermissionStepScreen(
        key: const ValueKey('perm-battery'),
        permissionId: 'battery',
        icon: Symbols.bolt_rounded,
        heroColor: AppColors.accent,
        heroBackground: AppColors.accentSoft,
        title: 'Keep Nupo awake',
        subtitle:
            'Tap Allow on the popup so your phone does not put Nupo to sleep.',
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
          permissionId: 'autostart',
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
    // Android's own steps continue the count past the seven questions.
    final grandTotal = _total + 4 + permCount;
    var n = _total; // the setup block starts after the questions

    final screens = <Widget>[
      // ---- 1-4 · Make it personal ----
      NameInputScreen(
        step: 1,
        total: _total,
        title: "First, what is your kid's name?",
        hint: 'Their name',
        initialValue: Storage.childName,
        eyebrow: 'Step 1 of 5',
        stepLabel: '1/5',
        greeting: (v) => 'Nice to meet you, $v.',
        emptyGreeting: 'Type a name and I will remember it.',
        onNext: (v) async {
          await Storage.setChildName(v);
          _next();
        },
      ),
      SingleChoiceScreen(
        step: 2,
        total: _total,
        question: 'How old is *$_child*?',
        stepLabel: '2/5',
        // One band per question bank. `Questions.kt` already knows A-D
        // (5–6 / 7–8 / 9–10 / 11+), so what the parent picks IS what the
        // native engine uses.
        options: const [
          ChoiceOption(
            'a',
            '5 and 6',
            chip: '5 · 6',
            description: 'Counting, first words',
          ),
          ChoiceOption(
            'b',
            '7 and 8',
            chip: '7 · 8',
            description: 'Mental maths, nature and the world',
          ),
          ChoiceOption(
            'c',
            '9 and 10',
            chip: '9 · 10',
            description: 'Times tables, fractions',
          ),
          ChoiceOption(
            'd',
            '11 and 12',
            chip: '11 · 12',
            description: 'Word problems, logic',
          ),
        ],
        mascotFor: Nupo.teacher,
        lineFor: (band) => const {
          'a': 'Pictures and counting to start.',
          'b': 'Mental maths and the world around them.',
          'c': 'Tables and fractions land well here.',
          'd': 'Word problems and logic it is.',
        }[band],
        onBack: _back,
        initiallySelected: Storage.bandFromAge(Storage.childAge),
        onNext: (band) async {
          const upperBound = {'a': 6, 'b': 8, 'c': 10, 'd': 12};
          await Storage.setChildAge(upperBound[band]!);
          await Storage.setAgeBand(band);
          _next();
        },
      ),
      SingleChoiceScreen(
        step: 3,
        total: _total,
        question: 'What should *$_child* get better at?',
        stepLabel: '3/5',
        grid: true,
        options: const [
          ChoiceOption(
            'maths',
            'Maths',
            chip: '7×8',
            chipColor: AppColors.primary,
            description: 'Confidence with numbers',
          ),
          ChoiceOption(
            'reading',
            'Reading',
            chip: 'Aa',
            chipColor: AppColors.done,
            description: 'Stronger words and stories',
          ),
          ChoiceOption(
            'gk',
            'General knowledge',
            chip: '?',
            chipColor: AppColors.accentDeep,
            description: 'A wider view of the world',
          ),
          ChoiceOption(
            'mix',
            'A bit of everything',
            icon: Icons.star_rounded,
            chipColor: AppColors.wrong,
            description: 'A balanced daily mix',
          ),
        ],
        spot: MascotSpot.right,
        mascotFor: Nupo.idea,
        lineFor: (goal) => const {
          'maths': 'Numbers first. I will slip the rest in.',
          'reading': 'Words and stories it is.',
          'gk': 'Capitals, planets and odd facts.',
          'mix': 'A little of each, every day.',
        }[goal],
        onBack: _back,
        initiallySelected: Storage.onbSubject.isEmpty
            ? 'mix'
            : Storage.onbSubject,
        onNext: (id) async {
          await Storage.setOnbSubject(id);
          _next();
        },
      ),
      NameInputScreen(
        step: 4,
        total: _total,
        title: "Meet $_child's buddy. What should they call him?",
        hint: 'Nupo',
        initialValue: Storage.owlName,
        buttonLabel: "Let's go",
        onBack: _back,
        tone: StepTone.cream,
        buttonTone: ButtonTone.amber,
        stepLabel: '4/5',
        greeting: (v) => '$v it is. Good name.',
        emptyGreeting: 'Nupo works too. That is me.',
        mascotTyped: Nupo.cool,
        mascotEmpty: Nupo.shrug,
        onNext: (v) async {
          await Storage.setOwlName(v.trim().isEmpty ? 'Nupo' : v);
          _next();
        },
      ),

      // ---- 5-6 · Show the future ----
      MonthPlanScreen(
        step: 5,
        total: _total,
        childName: _child,
        subject: Storage.onbSubject.isEmpty ? 'mix' : Storage.onbSubject,
        band: Storage.ageBand,
        onBack: _back,
        stepLabel: '5/5',
        onNext: _next,
      ),
      PlanProjectionScreen(
        step: 6,
        total: _total,
        childName: _child,
        onBack: _back,
        onNext: _next,
      ),

      // ---- 7 · Close ----
      WhyItWorksScreen(
        step: 7,
        total: _total,
        childName: _child,
        onBack: _back,
        onNext: _next,
      ),

      // ---- ANDROID ONLY · the real setup the iOS build does via Screen Time --
      AppPickerScreen(
        key: const ValueKey('picker'),
        step: ++n,
        total: grandTotal,
        onNext: () {
          // Zero apps means the gate can never fire and the product does
          // nothing — worth seeing separately from "finished setup".
          Analytics.appsPicked(Storage.gatedApps.length);
          _next();
        },
      ),
      AppRulesScreen(
        key: const ValueKey('rules'),
        step: ++n,
        total: grandTotal,
        onNext: _next,
      ),
      PinCreateScreen(
        key: const ValueKey('pin'),
        step: ++n,
        total: grandTotal,
        onNext: _next,
      ),
      PermissionsIntroScreen(
        key: const ValueKey('perm-intro'),
        step: ++n,
        total: grandTotal,
        autostart: _autostartRelevant,
        onNext: _next,
      ),
      ..._permissionSteps(n + 1, grandTotal),
    ];

    final index = _step.clamp(0, screens.length - 1);
    // The last permission step finishes onboarding. Exactly once — see
    // [_finishing].
    if (_step >= screens.length && !_finishing) {
      _finishing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    }

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step > 0) _back();
      },
      // Key each step so Flutter never reuses one step's State for the next —
      // without this the two adjacent NameInputScreens share a State and the
      // field keeps the previous value.
      child: KeyedSubtree(
        key: ValueKey('onb-step-$index'),
        child: screens[index],
      ),
    );
  }
}
