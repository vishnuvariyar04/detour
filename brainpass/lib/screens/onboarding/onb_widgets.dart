// screens/onboarding/onb_widgets.dart
//
// Shared building blocks for the onboarding funnel (nupo_onboarding_spec.md).
// Every screen is ONE tap: progress up top, one hero/title block, one CTA —
// or auto-advance the moment a choice is made.

import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets.dart';

// ---------------------------------------------------------------------------
// Scaffolds
// ---------------------------------------------------------------------------

/// Standard light onboarding screen: progress bar, title block, body, CTA.
/// When [ctaLabel] is null no button is shown (auto-advance screens).
class OnbScaffold extends StatelessWidget {
  final int? step;
  final int? total;
  final String title;
  final String? subtitle;
  final Widget? child;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final Widget? belowCta;
  final bool centerText;

  const OnbScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.child,
    this.step,
    this.total,
    this.ctaLabel,
    this.onCta,
    this.belowCta,
    this.centerText = false,
  });

  @override
  Widget build(BuildContext context) {
    final align =
        centerText ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return Scaffold(
      body: Container(
        decoration: AppColors.bgDecoration(),
        height: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              NupoTopBar(step: step, total: total),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                  child: Column(
                    crossAxisAlignment: align,
                    children: [
                      Text(title,
                          style: AppText.title,
                          textAlign:
                              centerText ? TextAlign.center : TextAlign.start),
                      if (subtitle != null) ...[
                        const SizedBox(height: 8),
                        Text(subtitle!,
                            style: AppText.body,
                            textAlign: centerText
                                ? TextAlign.center
                                : TextAlign.start),
                      ],
                      const SizedBox(height: 20),
                      ?child,
                    ],
                  ),
                ),
              ),
              if (ctaLabel != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    children: [
                      PrimaryButton(label: ctaLabel!, onPressed: onCta),
                      if (belowCta != null) ...[
                        const SizedBox(height: 12),
                        belowCta!,
                      ],
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

/// A full-screen statement: hero (emoji / mascot), a few big lines, one CTA.
/// [brand] flips it to the bold purple "reflection" treatment from the spec.
class StatementScreen extends StatelessWidget {
  final int? step;
  final int? total;
  final String? emoji;
  final String? mascot;
  final Widget? hero; // custom hero overrides emoji/mascot
  final String title;
  final String? body;
  final Widget? extra; // rendered between body and CTA
  final String ctaLabel;
  final VoidCallback onNext;
  final bool brand; // purple gradient background, white text

  const StatementScreen({
    super.key,
    required this.title,
    required this.ctaLabel,
    required this.onNext,
    this.body,
    this.extra,
    this.emoji,
    this.mascot,
    this.hero,
    this.step,
    this.total,
    this.brand = false,
  });

  @override
  Widget build(BuildContext context) {
    final ink = brand ? Colors.white : AppColors.textDark;
    final sub = brand ? Colors.white.withValues(alpha: 0.86) : AppColors.textMuted;

    Widget heroWidget;
    if (hero != null) {
      heroWidget = hero!;
    } else if (mascot != null) {
      heroWidget = HaloMascot(mascot!, size: 150);
    } else if (emoji != null) {
      heroWidget = EmojiHero(emoji!, onBrand: brand);
    } else {
      heroWidget = const SizedBox.shrink();
    }

    return Scaffold(
      body: Container(
        decoration: brand
            ? const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryBright],
                ),
              )
            : AppColors.bgDecoration(),
        height: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              NupoTopBar(step: brand ? null : step, total: brand ? null : total),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, viewport) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: viewport.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          heroWidget,
                          const SizedBox(height: 24),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AppText.title.copyWith(color: ink),
                          ),
                          if (body != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              body!,
                              textAlign: TextAlign.center,
                              style: AppText.body.copyWith(color: sub),
                            ),
                          ],
                          if (extra != null) ...[
                            const SizedBox(height: 20),
                            extra!,
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 4, 28, 16),
                child: brand
                    ? WhitePillButton(label: ctaLabel, onPressed: onNext)
                    : PrimaryButton(label: ctaLabel, onPressed: onNext),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White CTA used on brand-purple statement screens.
class WhitePillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const WhitePillButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(29),
        elevation: 6,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(29),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// A big emoji inside a soft tinted circle — the standard statement hero.
class EmojiHero extends StatelessWidget {
  final String emoji;
  final bool onBrand;
  final double size;
  const EmojiHero(this.emoji, {super.key, this.onBrand = false, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: onBrand
              ? Colors.white.withValues(alpha: 0.16)
              : AppColors.accentSoft,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: TextStyle(fontSize: size * 0.46)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Choice screens
// ---------------------------------------------------------------------------

class OnbChoice {
  final String id;
  final String emoji;
  final String label;
  final String? sub;
  const OnbChoice(this.id, this.emoji, this.label, {this.sub});
}

/// One-tap single select: tapping a card highlights it, then advances on its
/// own — no Continue button (spec §2: every screen is one tap).
class SingleChoiceScreen extends StatefulWidget {
  final int? step;
  final int? total;
  final String title;
  final String? subtitle;
  final List<OnbChoice> options;
  final ValueChanged<String> onPicked;

  const SingleChoiceScreen({
    super.key,
    required this.title,
    required this.options,
    required this.onPicked,
    this.subtitle,
    this.step,
    this.total,
  });

  @override
  State<SingleChoiceScreen> createState() => _SingleChoiceScreenState();
}

class _SingleChoiceScreenState extends State<SingleChoiceScreen> {
  String? _picked;

  void _pick(String id) {
    if (_picked != null) return;
    setState(() => _picked = id);
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) widget.onPicked(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return OnbScaffold(
      step: widget.step,
      total: widget.total,
      title: widget.title,
      subtitle: widget.subtitle,
      child: Column(
        children: [
          for (final o in widget.options)
            SelectCard(
              title: o.label,
              subtitle: o.sub,
              selected: _picked == o.id,
              leading: ChoiceEmoji(o.emoji),
              onTap: () => _pick(o.id),
            ),
        ],
      ),
    );
  }
}

/// Multi-select with an optional cap and a Continue button.
class MultiChoiceScreen extends StatefulWidget {
  final int? step;
  final int? total;
  final String title;
  final String? subtitle;
  final List<OnbChoice> options;
  final int? max;
  final ValueChanged<List<String>> onDone;
  final String ctaLabel;

  const MultiChoiceScreen({
    super.key,
    required this.title,
    required this.options,
    required this.onDone,
    this.subtitle,
    this.max,
    this.step,
    this.total,
    this.ctaLabel = 'Continue',
  });

  @override
  State<MultiChoiceScreen> createState() => _MultiChoiceScreenState();
}

class _MultiChoiceScreenState extends State<MultiChoiceScreen> {
  final _picked = <String>[];

  void _toggle(String id) {
    setState(() {
      if (_picked.contains(id)) {
        _picked.remove(id);
      } else {
        if (widget.max != null && _picked.length >= widget.max!) return;
        _picked.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return OnbScaffold(
      step: widget.step,
      total: widget.total,
      title: widget.title,
      subtitle: widget.subtitle,
      ctaLabel: widget.ctaLabel,
      onCta: _picked.isEmpty ? null : () => widget.onDone(List.of(_picked)),
      child: Column(
        children: [
          for (final o in widget.options)
            SelectCard(
              title: o.label,
              subtitle: o.sub,
              selected: _picked.contains(o.id),
              leading: ChoiceEmoji(o.emoji),
              onTap: () => _toggle(o.id),
            ),
        ],
      ),
    );
  }
}

/// Rounded emoji tile used as the leading element of every choice card.
class ChoiceEmoji extends StatelessWidget {
  final String emoji;
  const ChoiceEmoji(this.emoji, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F5FF),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 22)),
    );
  }
}

// ---------------------------------------------------------------------------
// Name input
// ---------------------------------------------------------------------------

/// One big friendly text field + Continue. Used for the two names and the owl.
class NameInputScreen extends StatefulWidget {
  final int? step;
  final int? total;
  final String title;
  final String? subtitle;
  final String hint;
  final String initial;
  final String ctaLabel;
  final String? mascot;
  final ValueChanged<String> onDone;

  const NameInputScreen({
    super.key,
    required this.title,
    required this.hint,
    required this.onDone,
    this.subtitle,
    this.initial = '',
    this.ctaLabel = 'Continue',
    this.mascot,
    this.step,
    this.total,
  });

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _c.text.trim();
    if (v.isEmpty) return;
    widget.onDone(v);
  }

  @override
  Widget build(BuildContext context) {
    return OnbScaffold(
      step: widget.step,
      total: widget.total,
      title: widget.title,
      subtitle: widget.subtitle,
      centerText: true,
      ctaLabel: widget.ctaLabel,
      onCta: _c.text.trim().isEmpty ? null : _submit,
      child: Column(
        children: [
          if (widget.mascot != null) ...[
            HaloMascot(widget.mascot!, size: 120),
            const SizedBox(height: 8),
          ],
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.line, width: 1.5),
              boxShadow: AppColors.softShadow,
            ),
            child: TextField(
              controller: _c,
              autofocus: true,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.words,
              maxLength: 20,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB9B4CE),
                ),
                counterText: '',
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
          ),
        ],
      ),
    );
  }
}
