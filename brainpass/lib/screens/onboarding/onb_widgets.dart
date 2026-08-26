// screens/onboarding/onb_widgets.dart — the tapped steps that run after the
// scrolled story hands over on "I want this for them".
//
// Built from `ui-ux/design/Nupo Setup Flow.dc.html` (treatment 2a, "Setup flow
// — nine tapped screens"). Its vocabulary, carried over here:
//
//   * a background TONE per step — lilac, cream, brand purple, green — so the
//     flow moves rather than sitting on one wash;
//   * Nupo present on every step, changing POSE and saying a LINE about the
//     step you are on. This is the thing that makes it feel like one character
//     walking you through rather than a form;
//   * chrome of a round back button, a slim progress track, and an explicit
//     "2/7" step label;
//   * choice cards with a chip, a title and a description of what the answer
//     changes;
//   * a shimmer sweep across the primary button.
//
// ⚠️ The design file predates the 2.3.8 copy fix — it still says "what's your
// kid's name?", "I want this for my kid", and "what should he call him?" of the
// child. Those are the exact strings Apple rejected the listing over (§3.26)
// and that §3.30 fixed in code. **This file follows the design's layout and
// motion, never its copy.** `store_copy_test.dart` fails the build if that slips.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets.dart';
import 'story_beats.dart' show Nupo;

/// The headline style for every tapped step, matching the scrolled story's beat
/// headlines rather than Material's defaults — same size, weight and tracking,
/// so the two halves of onboarding are set in one voice.
const kStepTitle = TextStyle(
  fontSize: 26,
  height: 1.24,
  fontWeight: FontWeight.w800,
  color: AppColors.textDark,
  letterSpacing: -0.4,
);

/// The per-step background. The design cycles lilac → cream → brand → green;
/// every value resolves to an `AppColors` token (CLAUDE.md §8).
enum StepTone {
  /// Default. The story's own ground.
  lilac,

  /// A warm beat, for the steps that are about the child rather than settings.
  cream,

  /// Full brand purple, for a payoff step. Flips the chrome to white.
  brand,

  /// Success green, for the closing step. Flips the chrome to white.
  done;

  bool get isDark => this == StepTone.brand || this == StepTone.done;

  /// The design's `TONE` table paints FLAT fills — `#F6F1FF`, `#FFFCEF`,
  /// `#7C3AED`, `#0E9384` — not gradients. Keeping them flat is what makes a
  /// step read as one stage rather than a wash.
  Color get fill => switch (this) {
    StepTone.lilac => AppColors.primarySoft,
    StepTone.cream => AppColors.accentSoft,
    StepTone.brand => AppColors.primary,
    StepTone.done => AppColors.done,
  };

  Color get ink => isDark ? Colors.white : AppColors.textDark;
}

/// Where Nupo stands on a step, from the rendered frames.
///
/// The frames alternate him left and right between steps and centre him on the
/// two that are about naming someone — which is what stops seven screens of the
/// same layout reading as one long form.
enum MascotSpot {
  none,

  /// Large and centred, no bubble. The step's own copy speaks instead.
  hero,

  /// Small, with the speech bubble to his right.
  left,

  /// Small, with the speech bubble to his left.
  right,
}

/// The design gives amber to two buttons only — "Let's go" and "Start Ram's
/// plan" — where the step is a hand-off rather than another question.
enum ButtonTone { brand, amber, light }

/// The common onboarding page shell: chrome, Nupo, content, primary button.
///
/// This used to be a plain `Scaffold` with a `NupoTopBar`, which meant the
/// handover from the scrolled story swapped its full-bleed frame and amber star
/// for an app bar full of Material progress dots — one tap, and the parent was
/// apparently in a different app.
class OnbScaffold extends StatefulWidget {
  final int step;
  final int total;
  final Widget child;
  final String buttonLabel;
  final VoidCallback? onButton;
  final VoidCallback? onBack;

  /// Nupo's pose for this step, from [Nupo]. Null hides it.
  final String? mascot;

  /// What Nupo says about this step. Shown in a bubble beside the pose.
  final String? line;

  final MascotSpot spot;

  /// Small caps above the title — "STEP 1 OF 5", "THE PLAN", "THE IDEA".
  final String? eyebrow;

  /// The frames label the question steps `1/5` and the ones after `Plan`, so
  /// the count belongs to the questions rather than running to seven.
  final String? stepLabel;

  final ButtonTone buttonTone;

  final StepTone tone;

  /// Centre the content in the space between the chrome and the button.
  ///
  /// Off by default: a `Column(mainAxisAlignment: center)` inside a
  /// `SingleChildScrollView` does nothing, because the scroll view gives it
  /// unbounded height, so short screens silently pile up at the top with a
  /// screen of dead space underneath. Screens with a few lines of content set
  /// this; long ones (a list of options) must not, or the list stops scrolling
  /// from the top.
  final bool centerContent;

  const OnbScaffold({
    super.key,
    required this.step,
    required this.total,
    required this.child,
    required this.buttonLabel,
    required this.onButton,
    this.onBack,
    this.mascot,
    this.line,
    this.spot = MascotSpot.left,
    this.eyebrow,
    this.stepLabel,
    this.buttonTone = ButtonTone.brand,
    this.tone = StepTone.lilac,
    this.centerContent = false,
  });

  @override
  State<OnbScaffold> createState() => _OnbScaffoldState();
}

class _OnbScaffoldState extends State<OnbScaffold>
    with SingleTickerProviderStateMixin {
  // Replays per step: `NarrativeOnboarding` keys each one, so every step gets a
  // fresh State and therefore a fresh entrance.
  late final AnimationController _enter;
  late final CurvedAnimation _fade;

  @override
  void initState() {
    super.initState();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _fade = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tone = widget.tone;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final fraction = widget.total <= 0
        ? 0.0
        : (widget.step / widget.total).clamp(0.0, 1.0);

    return Scaffold(
      // Tone changes are animated: the design transitions the background over
      // .45s rather than cutting, which is most of why the flow feels continuous.
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        color: tone.fill,
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                child: Column(
                  children: [
                    _Chrome(
                      progress: fraction,
                      label:
                          widget.stepLabel ?? '${widget.step}/${widget.total}',
                      onBack: widget.onBack,
                      tone: tone,
                    ),
                    if (!keyboardOpen &&
                        widget.mascot != null &&
                        widget.spot != MascotSpot.none) ...[
                      const SizedBox(height: 10),
                      _MascotLine(
                        pose: widget.mascot!,
                        line: widget.line,
                        tone: tone,
                        spot: widget.spot,
                      ),
                    ],
                    if (widget.eyebrow != null) ...[
                      SizedBox(height: keyboardOpen ? 4 : 14),
                      Text(
                        widget.eyebrow!.toUpperCase(),
                        textAlign: widget.spot == MascotSpot.hero
                            ? TextAlign.center
                            : TextAlign.start,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: tone.isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppColors.primary,
                        ),
                      ),
                    ],
                    SizedBox(
                      height: keyboardOpen
                          ? 6
                          : (widget.eyebrow != null ? 10 : 18),
                    ),
                    Expanded(
                      child: FadeTransition(
                        opacity: _fade,
                        child: SlideTransition(
                          position: Tween(
                            begin: const Offset(0, 0.035),
                            end: Offset.zero,
                          ).animate(_fade),
                          child: LayoutBuilder(
                            builder: (context, c) => SingleChildScrollView(
                              child: widget.centerContent
                                  ? ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: c.maxHeight,
                                      ),
                                      child: IntrinsicHeight(
                                        child: widget.child,
                                      ),
                                    )
                                  : widget.child,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    NupoButton(
                      label: widget.buttonLabel,
                      onPressed: widget.onButton,
                      buttonTone: widget.buttonTone,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Back button, progress track, step label.
class _Chrome extends StatelessWidget {
  final double progress;
  final String label;
  final VoidCallback? onBack;
  final StepTone tone;

  const _Chrome({
    required this.progress,
    required this.label,
    required this.onBack,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final dark = tone.isDark;

    return Row(
      children: [
        SizedBox(
          width: 34,
          height: 34,
          child: onBack == null
              ? null
              : Material(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.white,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onBack,
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: tone.ink,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 12),
        // A plain track with a PURPLE fill, no travelling star. The frames use
        // the star only in the scrolled story; carrying it into the steps was
        // mine, not the design's.
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 7,
              // LayoutBuilder, not FractionallySizedBox: as a non-positioned
              // Stack child that aligns to the CENTRE, so the fill grew from
              // the middle outwards and read as no fill at all.
              child: LayoutBuilder(
                builder: (context, c) => Stack(
                  children: [
                    Positioned.fill(
                      child: ColoredBox(
                        color: dark
                            ? Colors.white.withValues(alpha: 0.22)
                            : AppColors.primary.withValues(alpha: 0.16),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      width: c.maxWidth * progress.clamp(0.0, 1.0),
                      // Amber once the questions are done, which is how the
                      // frames mark the closing screens.
                      color: dark ? AppColors.accent : AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: tone.ink.withValues(alpha: dark ? 0.75 : 0.4),
          ),
        ),
      ],
    );
  }
}

/// Nupo, and what Nupo has to say about this step.
class _MascotLine extends StatefulWidget {
  final String pose;
  final String? line;
  final StepTone tone;
  final MascotSpot spot;

  const _MascotLine({
    required this.pose,
    required this.line,
    required this.tone,
    required this.spot,
  });

  @override
  State<_MascotLine> createState() => _MascotLineState();
}

class _MascotLineState extends State<_MascotLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4600),
    )..repeat();
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hero = widget.spot == MascotSpot.hero;

    final owl = AnimatedBuilder(
      animation: _float,
      builder: (context, child) => Transform.translate(
        // The design's `floaty`: a rise with a slight roll.
        offset: Offset(0, math.sin(_float.value * 2 * math.pi) * -5.5),
        child: Transform.rotate(
          angle: math.sin(_float.value * 2 * math.pi) * -0.03,
          child: child,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Image.asset(
          widget.pose,
          key: ValueKey(widget.pose),
          width: hero ? 168 : 112,
          semanticLabel: 'Nupo',
        ),
      ),
    );

    if (hero) {
      // Centred and large, with the sparkles the frames put either side of him.
      return SizedBox(
        height: 190,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Positioned(
              left: 40,
              top: 34,
              child: _Sparkle(size: 18, amber: true),
            ),
            const Positioned(
              right: 46,
              top: 62,
              child: _Sparkle(size: 12, amber: false),
            ),
            owl,
          ],
        ),
      );
    }

    final bubble = widget.line == null
        ? const SizedBox.shrink()
        : Flexible(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _Bubble(
                key: ValueKey(widget.line),
                text: widget.line!,
                tone: widget.tone,
                tailLeft: widget.spot == MascotSpot.left,
              ),
            ),
          );

    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: widget.spot == MascotSpot.left
            ? [owl, const SizedBox(width: 8), bubble]
            : [bubble, const SizedBox(width: 8), owl],
      ),
    );
  }
}

/// The speech bubble, tail on whichever side Nupo is standing.
class _Bubble extends StatelessWidget {
  final String text;
  final StepTone tone;
  final bool tailLeft;

  const _Bubble({
    super.key,
    required this.text,
    required this.tone,
    required this.tailLeft,
  });

  @override
  Widget build(BuildContext context) {
    final dark = tone.isDark;
    const r = Radius.circular(18);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withValues(alpha: 0.16) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: r,
          topRight: r,
          bottomLeft: tailLeft ? const Radius.circular(4) : r,
          bottomRight: tailLeft ? r : const Radius.circular(4),
        ),
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: AppColors.textDark.withValues(alpha: 0.1),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w700,
          color: tone.ink,
        ),
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  final double size;
  final bool amber;
  const _Sparkle({required this.size, required this.amber});

  @override
  Widget build(BuildContext context) => Icon(
    Icons.auto_awesome,
    size: size,
    color: amber ? AppColors.accent : AppColors.primaryBright,
  );
}

/// The primary button, with the design's shimmer sweep.
/// The onboarding CTA: flat tone fill, a soft drop, a press dip and a slow
/// shimmer sweep. Public because the scrolled story uses it too — before this,
/// the story's CTAs were the plain gradient `PrimaryButton` and the handover
/// into the tapped steps visibly changed button styles mid-flow.
class NupoButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonTone buttonTone;

  const NupoButton({
    super.key,
    required this.label,
    required this.onPressed,
    required this.buttonTone,
  });

  @override
  State<NupoButton> createState() => _NupoButtonState();
}

class _NupoButtonState extends State<NupoButton>
    with SingleTickerProviderStateMixin {
  // Built in initState, NOT as a `late final`. The controller is only read in
  // build() when the button is enabled, so a disabled button (nothing picked
  // yet) left it unconstructed until dispose() touched it — and constructing a
  // Ticker against a deactivated element throws "Looking up a deactivated
  // widget's ancestor is unsafe".
  late final AnimationController _sweep;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _sweep = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.onPressed != null) _sweep.forward();
  }

  @override
  void didUpdateWidget(covariant NupoButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onPressed == null && widget.onPressed != null) {
      _sweep.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    // The frames give amber to the two hand-off steps and white to the closing
    // one; everything else is brand purple.
    final (Color bg, Color fg) = switch (widget.buttonTone) {
      ButtonTone.amber => (AppColors.accent, AppColors.textDark),
      ButtonTone.light => (Colors.white, AppColors.done),
      ButtonTone.brand => (AppColors.primary, Colors.white),
    };

    return AnimatedScale(
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      scale: _pressed ? 0.985 : 1,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        offset: _pressed ? const Offset(0, 0.055) : Offset.zero,
        child: SizedBox(
          width: double.infinity,
          height: 66,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              boxShadow: enabled && !_pressed
                  ? [
                      BoxShadow(
                        color: bg.withValues(alpha: 0.34),
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: enabled
                          ? bg
                          : AppColors.textDark.withValues(alpha: 0.12),
                    ),
                  ),
                  if (enabled)
                    AnimatedBuilder(
                      animation: _sweep,
                      builder: (context, _) {
                        final p = Curves.easeInOutCubic.transform(_sweep.value);
                        return Positioned(
                          left: -110 + p * 600,
                          top: 0,
                          bottom: 0,
                          width: 74,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withValues(alpha: 0),
                                    Colors.white.withValues(alpha: 0.3),
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onHighlightChanged: enabled
                            ? (value) => setState(() => _pressed = value)
                            : null,
                        onTap: widget.onPressed,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.label,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: enabled ? fg : AppColors.textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 9),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                                color: enabled ? fg : AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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

/// A single "statement" beat: headline + body copy.
class StatementScreen extends StatelessWidget {
  final int step;
  final int total;
  final String headline;
  final String body;
  final bool brand;
  final bool showMascot;
  final String buttonLabel;
  final VoidCallback onNext;

  const StatementScreen({
    super.key,
    required this.step,
    required this.total,
    required this.headline,
    required this.body,
    required this.onNext,
    this.brand = false,
    this.showMascot = false,
    this.buttonLabel = 'Continue',
  });

  @override
  Widget build(BuildContext context) {
    return OnbScaffold(
      step: step,
      total: total,
      buttonLabel: buttonLabel,
      onButton: onNext,
      tone: brand ? StepTone.brand : StepTone.lilac,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          if (showMascot) ...[
            const HaloMascot(Nupo.wave, size: 130),
            const SizedBox(height: 24),
          ],
          Text(
            headline,
            textAlign: TextAlign.center,
            style: brand
                ? kStepTitle.copyWith(color: AppColors.primary)
                : kStepTitle,
          ),
          const SizedBox(height: 14),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class ChoiceOption {
  final String id;
  final String label;
  final IconData? icon;

  /// Short badge on the left of the card — the design uses the age range here.
  final String? chip;

  /// The frames tint each goal's chip differently — purple, teal, amber, red —
  /// so four options read as four things rather than one list.
  final Color? chipColor;

  /// What choosing this actually changes, one line. The design puts this under
  /// every option, and it is the difference between picking blind and picking
  /// informed.
  final String? description;

  const ChoiceOption(
    this.id,
    this.label, {
    this.icon,
    this.chip,
    this.chipColor,
    this.description,
  });
}

/// Pick exactly one.
class SingleChoiceScreen extends StatefulWidget {
  final int step;
  final int total;
  final String question;
  final List<ChoiceOption> options;
  final void Function(String id) onNext;
  final String? Function(String id)? lineFor;
  final String? mascotFor;
  final StepTone tone;
  final VoidCallback? onBack;
  final MascotSpot spot;
  final String? eyebrow;
  final String? stepLabel;

  /// Lay the options out two-up. The frames use this for the goal step, where
  /// four short labels in a column wasted most of the screen.
  final bool grid;

  /// Pre-selects an option (e.g. re-entering the flow, or a sensible default).
  final String? initiallySelected;

  const SingleChoiceScreen({
    super.key,
    required this.step,
    required this.total,
    required this.question,
    required this.options,
    required this.onNext,
    this.initiallySelected,
    this.lineFor,
    this.mascotFor,
    this.tone = StepTone.lilac,
    this.onBack,
    this.spot = MascotSpot.left,
    this.eyebrow,
    this.stepLabel,
    this.grid = false,
  });

  @override
  State<SingleChoiceScreen> createState() => _SingleChoiceScreenState();
}

class _SingleChoiceScreenState extends State<SingleChoiceScreen> {
  late String? _selected =
      widget.options.any((o) => o.id == widget.initiallySelected)
      ? widget.initiallySelected
      : null;

  @override
  Widget build(BuildContext context) {
    return OnbScaffold(
      step: widget.step,
      total: widget.total,
      buttonLabel: 'Continue',
      onButton: _selected == null ? null : () => widget.onNext(_selected!),
      tone: widget.tone,
      onBack: widget.onBack,
      mascot: widget.mascotFor,
      spot: widget.spot,
      eyebrow: widget.eyebrow,
      stepLabel: widget.stepLabel,
      line: _selected == null ? null : widget.lineFor?.call(_selected!),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Title(widget.question, tone: widget.tone),
          const SizedBox(height: 20),
          if (widget.grid)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 13,
              crossAxisSpacing: 13,
              childAspectRatio: 0.94,
              children: [
                for (final o in widget.options)
                  ChoiceTile(
                    option: o,
                    selected: _selected == o.id,
                    onTap: () => setState(() => _selected = o.id),
                  ),
              ],
            )
          else
            for (final o in widget.options)
              Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: ChoiceCard(
                  option: o,
                  selected: _selected == o.id,
                  onTap: () => setState(() => _selected = o.id),
                ),
              ),
        ],
      ),
    );
  }
}

/// The design's option card: chip, title, description, check.
class ChoiceCard extends StatelessWidget {
  final ChoiceOption option;
  final bool selected;
  final VoidCallback onTap;

  const ChoiceCard({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDetail = option.chip != null || option.description != null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: 18,
          vertical: hasDetail ? 14 : 18,
        ),
        decoration: BoxDecoration(
          // The design's selected fill.
          color: selected ? const Color(0xFFF8F2FF) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.textDark.withValues(alpha: 0.1),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.22)
                  : AppColors.textDark.withValues(alpha: 0.06),
              blurRadius: selected ? 30 : 16,
              offset: Offset(0, selected ? 14 : 6),
            ),
          ],
        ),
        child: Row(
          children: [
            if (option.chip != null) ...[
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  option.chip!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
            ] else if (option.icon != null) ...[
              IconBadge(option.icon!),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (option.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      option.description!,
                      // One line, always. A wrapped description grows every
                      // card, and four grown cards push the last option off a
                      // 844-tall screen — which is how a parent misses that
                      // their child's band is even offered.
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : AppColors.textDark.withValues(alpha: 0.14),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pick any number (at least one to continue).
class MultiChoiceScreen extends StatefulWidget {
  final int step;
  final int total;
  final String question;
  final List<ChoiceOption> options;
  final List<String> initiallySelected;
  final void Function(List<String> ids) onNext;
  final bool allowEmpty;

  const MultiChoiceScreen({
    super.key,
    required this.step,
    required this.total,
    required this.question,
    required this.options,
    required this.onNext,
    this.initiallySelected = const [],
    this.allowEmpty = false,
  });

  @override
  State<MultiChoiceScreen> createState() => _MultiChoiceScreenState();
}

class _MultiChoiceScreenState extends State<MultiChoiceScreen> {
  late final Set<String> _selected = {...widget.initiallySelected};

  @override
  Widget build(BuildContext context) {
    return OnbScaffold(
      step: widget.step,
      total: widget.total,
      buttonLabel: 'Continue',
      onButton: (_selected.isEmpty && !widget.allowEmpty)
          ? null
          : () => widget.onNext(_selected.toList()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.question, style: kStepTitle),
          const SizedBox(height: 20),
          for (final o in widget.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: ChoiceCard(
                option: o,
                selected: _selected.contains(o.id),
                onTap: () => setState(() {
                  _selected.contains(o.id)
                      ? _selected.remove(o.id)
                      : _selected.add(o.id);
                }),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single free-text name field (child's name, owl name, ...).
///
/// The design gives this the biggest input in the app — 64pt tall, a 2.5pt brand
/// border — and a bubble under it that answers as you type. That bubble is the
/// step's whole personality, so it lives here rather than being optional.
class NameInputScreen extends StatefulWidget {
  final int step;
  final int total;
  final String title;
  final String hint;
  final String initialValue;
  final void Function(String value) onNext;
  final String buttonLabel;

  /// Nupo's line once something has been typed, and before.
  final String Function(String value)? greeting;
  final String emptyGreeting;
  final String mascotTyped;
  final String mascotEmpty;
  final StepTone tone;
  final VoidCallback? onBack;
  final String? eyebrow;
  final String? stepLabel;
  final ButtonTone buttonTone;

  const NameInputScreen({
    super.key,
    required this.step,
    required this.total,
    required this.title,
    required this.hint,
    required this.onNext,
    this.initialValue = '',
    this.buttonLabel = 'Continue',
    this.greeting,
    this.emptyGreeting = 'Type a name and I’ll remember it.',
    this.mascotTyped = Nupo.wave,
    this.mascotEmpty = Nupo.shrug,
    this.tone = StepTone.lilac,
    this.onBack,
    this.eyebrow,
    this.stepLabel,
    this.buttonTone = ButtonTone.brand,
  });

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  late final _controller = TextEditingController(text: widget.initialValue);
  late String _value = widget.initialValue.trim();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final v = _controller.text.trim();
      if (v != _value) setState(() => _value = v);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typed = _value.isNotEmpty;
    final greeting = typed
        ? (widget.greeting?.call(_value) ?? 'Nice to meet you, $_value!')
        : widget.emptyGreeting;

    return OnbScaffold(
      step: widget.step,
      total: widget.total,
      buttonLabel: widget.buttonLabel,
      onButton: () => widget.onNext(_controller.text.trim()),
      tone: widget.tone,
      onBack: widget.onBack,
      eyebrow: widget.eyebrow,
      stepLabel: widget.stepLabel,
      buttonTone: widget.buttonTone,
      // The frames centre Nupo on the two naming steps and let the copy speak,
      // rather than putting him beside a bubble.
      mascot: typed ? widget.mascotTyped : widget.mascotEmpty,
      spot: MascotSpot.hero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(widget.title, textAlign: TextAlign.center, style: kStepTitle),
          const SizedBox(height: 22),
          SizedBox(
            height: 64,
            child: TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 22),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                    color: AppColors.cardBorder,
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2.5,
                  ),
                ),
              ),
              onSubmitted: (v) => widget.onNext(v.trim()),
            ),
          ),
          const SizedBox(height: 16),
          // The frames answer under the field in a small pill, not in a bubble
          // beside Nupo — the reply belongs to what was just typed.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Container(
              key: ValueKey(greeting),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                greeting,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDeep,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A step title. The frames render the child's name inside the question in
/// brand purple — "How old is **Ram**?" — which is what makes the question feel
/// asked about someone rather than filled in.
class _Title extends StatelessWidget {
  final String text;
  final StepTone tone;
  const _Title(this.text, {required this.tone});

  @override
  Widget build(BuildContext context) {
    final base = kStepTitle.copyWith(color: tone.ink);
    final match = RegExp(r'\*(.+?)\*').firstMatch(text);
    if (match == null) return Text(text, style: base);

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: text.substring(0, match.start)),
          TextSpan(
            text: match.group(1),
            style: const TextStyle(color: AppColors.primary),
          ),
          TextSpan(text: text.substring(match.end)),
        ],
      ),
    );
  }
}

/// A square option tile for the two-up grid: chip top-left, label at the foot.
class ChoiceTile extends StatelessWidget {
  final ChoiceOption option;
  final bool selected;
  final VoidCallback onTap;

  const ChoiceTile({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF8F2FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textDark.withValues(
                alpha: selected ? 0.14 : 0.05,
              ),
              blurRadius: selected ? 26 : 14,
              offset: Offset(0, selected ? 12 : 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (option.chipColor ?? AppColors.primary).withValues(
                  alpha: 0.14,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: option.chip == null
                  ? Icon(option.icon, size: 20, color: option.chipColor)
                  : Text(
                      option.chip!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: option.chipColor ?? AppColors.primary,
                      ),
                    ),
            ),
            const Spacer(),
            Text(
              option.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15.5,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            if (option.description != null) ...[
              const SizedBox(height: 5),
              Text(
                option.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
