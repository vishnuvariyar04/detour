// widgets.dart
//
// Shared UI components. Every screen is assembled from these so the whole app
// speaks one visual language: NupoTopBar + ProgressDots up top, one big
// PrimaryButton pinned at the bottom, white cards on the soft purple wash.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';

import 'theme.dart';

// ---------------------------------------------------------------------------
// Top bar + progress
// ---------------------------------------------------------------------------

/// Circular back button used on every screen.
class BackCircle extends StatelessWidget {
  final VoidCallback? onTap;
  const BackCircle({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
      onPressed: onTap ?? () => Navigator.of(context).maybePop(),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        shadowColor: Colors.black12,
        elevation: 1,
        padding: const EdgeInsets.all(12),
        shape: const CircleBorder(),
      ),
    );
  }
}

/// Slim progress dots: done = soft purple, current = wide pill, rest = grey.
class ProgressDots extends StatelessWidget {
  final int step;
  final int total;
  const ProgressDots({super.key, required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == step ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == step
                  ? AppColors.primary
                  : i < step
                      ? AppColors.primary.withValues(alpha: 0.30)
                      : const Color(0xFFE1DDF0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

/// Standard header row: back circle (optional), centered dots or title.
class NupoTopBar extends StatelessWidget {
  final bool showBack;
  final VoidCallback? onBack;
  final int? step;
  final int? total;
  final String? title;

  const NupoTopBar({
    super.key,
    this.showBack = true,
    this.onBack,
    this.step,
    this.total,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final Widget center;
    if (step != null && total != null) {
      center = ProgressDots(step: step!, total: total!);
    } else if (title != null) {
      center = Text(
        title!,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
        ),
      );
    } else {
      center = const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (showBack)
            BackCircle(onTap: onBack)
          else
            const SizedBox(width: 44, height: 44),
          Expanded(child: Center(child: center)),
          const SizedBox(width: 44, height: 44),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons + small pieces
// ---------------------------------------------------------------------------

/// The one primary CTA: gradient pill with a soft glow.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 58,
      decoration: BoxDecoration(
        gradient: enabled
            ? const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryBright])
            : null,
        color: enabled ? null : const Color(0xFFE3E0F0),
        borderRadius: BorderRadius.circular(29),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(29),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    color: enabled ? Colors.white : AppColors.textMuted,
                    size: 20),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: enabled ? Colors.white : AppColors.textMuted,
                ),
              ),
              if (enabled) ...[
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Mascot on a warm sunny halo, optionally with little star sparkles —
/// the signature "hero" treatment (logo yellow + brand purple).
class HaloMascot extends StatelessWidget {
  final String asset;
  final double size;
  final bool sparkles;

  const HaloMascot(
    this.asset, {
    super.key,
    this.size = 190,
    this.sparkles = false,
  });

  @override
  Widget build(BuildContext context) {
    final box = size * 1.3;
    return SizedBox(
      width: box,
      height: box,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 1.08,
            height: size * 1.08,
            decoration: const BoxDecoration(
              color: AppColors.accentSoft,
              shape: BoxShape.circle,
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1),
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeOutBack,
            builder: (context, v, child) =>
                Transform.scale(scale: v, child: child),
            child: Image.asset(asset,
                width: size, height: size, fit: BoxFit.contain),
          ),
          if (sparkles) ...[
            Positioned(
              top: box * 0.10,
              right: box * 0.14,
              child: const Icon(Icons.star_rounded,
                  color: AppColors.accent, size: 26),
            ),
            Positioned(
              top: box * 0.30,
              left: box * 0.08,
              child: Icon(Icons.star_rounded,
                  color: AppColors.accent.withValues(alpha: 0.65), size: 16),
            ),
            Positioned(
              bottom: box * 0.16,
              right: box * 0.06,
              child: Icon(Icons.star_rounded,
                  color: AppColors.accent.withValues(alpha: 0.8), size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

/// Rounded icon badge (soft tint background).
class IconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final Color background;

  const IconBadge(
    this.icon, {
    super.key,
    this.size = 20,
    this.color = AppColors.primary,
    this.background = AppColors.primarySoft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(size * 0.45),
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: size),
    );
  }
}

/// One-line footnote pill: replaces every paragraph-long tip/footer.
class InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const InfoPill({
    super.key,
    required this.text,
    this.icon = Icons.verified_user_rounded,
    this.color = AppColors.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              color: color,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// Small uppercase section label.
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8),
      child: Text(text.toUpperCase(), style: AppText.overline),
    );
  }
}

// ---------------------------------------------------------------------------
// App icons — real launcher icons with a branded fallback
// ---------------------------------------------------------------------------

class _Brand {
  final Color color;
  final IconData icon;
  final String category;
  const _Brand(this.color, this.icon, this.category);
}

_Brand _brandFor(String package) {
  final p = package.toLowerCase();
  if (p.contains('youtube.kids')) {
    return const _Brand(Color(0xFFFF0000), Icons.child_care_rounded, 'Videos');
  }
  if (p.contains('youtube')) {
    return const _Brand(Color(0xFFFF0000), Icons.play_arrow_rounded, 'Videos');
  }
  if (p.contains('instagram')) {
    return const _Brand(Color(0xFFE1306C), Icons.camera_alt_rounded, 'Social');
  }
  if (p.contains('musically') || p.contains('tiktok')) {
    return const _Brand(Color(0xFF111111), Icons.music_note_rounded, 'Videos');
  }
  if (p.contains('snapchat')) {
    return const _Brand(Color(0xFFFFFC00), Icons.chat_bubble_rounded, 'Social');
  }
  if (p.contains('roblox')) {
    return const _Brand(Color(0xFF393B3D), Icons.extension_rounded, 'Games');
  }
  if (p.contains('subwaysurf')) {
    return const _Brand(Color(0xFFFF9800), Icons.run_circle_rounded, 'Games');
  }
  return const _Brand(AppColors.primary, Icons.smartphone_rounded, 'Apps');
}

/// Short category tag for a known package ("Videos", "Games", …).
String categoryFor(String package) => _brandFor(package).category;

/// Shows the app's REAL launcher icon when the app is installed, falling back
/// to a branded glyph. Icons are cached for the app session.
class AppBrandIcon extends StatefulWidget {
  final String package;
  final double size;
  final Uint8List? iconBytes; // pass through when the caller already has them

  const AppBrandIcon(this.package, {super.key, this.size = 40, this.iconBytes});

  static final Map<String, Uint8List?> _cache = {};

  @override
  State<AppBrandIcon> createState() => _AppBrandIconState();
}

class _AppBrandIconState extends State<AppBrandIcon> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = widget.iconBytes ?? AppBrandIcon._cache[widget.package];
    if (_bytes == null && !AppBrandIcon._cache.containsKey(widget.package)) {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    try {
      final info = await InstalledApps.getAppInfo(widget.package);
      AppBrandIcon._cache[widget.package] = info?.icon;
      if (mounted && info?.icon != null) setState(() => _bytes = info!.icon);
    } catch (_) {
      AppBrandIcon._cache[widget.package] = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    if (_bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(s * 0.26),
        child: Image.memory(_bytes!, width: s, height: s, fit: BoxFit.cover,
            gaplessPlayback: true),
      );
    }
    final b = _brandFor(widget.package);
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: b.color,
        borderRadius: BorderRadius.circular(s * 0.26),
      ),
      alignment: Alignment.center,
      child: Icon(
        b.icon,
        color: b.color == const Color(0xFFFFFC00) ? Colors.black : Colors.white,
        size: s * 0.55,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PIN input
// ---------------------------------------------------------------------------

/// Rounded boxes; filled ones show a dot, the active one is highlighted.
/// Defaults to a 4-digit PIN; pass [count] (e.g. 6) for an OTP.
class PinBoxes extends StatelessWidget {
  final int filled;
  final int count;
  const PinBoxes({super.key, required this.filled, this.count = 4});

  @override
  Widget build(BuildContext context) {
    final gap = count > 4 ? 8.0 : 14.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          _box(i),
          if (i < count - 1) SizedBox(width: gap),
        ],
      ],
    );
  }

  Widget _box(int index) {
    final hasValue = index < filled;
    final isActive = index == filled;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: count > 4 ? 44 : 56,
      height: count > 4 ? 54 : 64,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? AppColors.primary
              : hasValue
                  ? AppColors.primary.withValues(alpha: 0.45)
                  : AppColors.line,
          width: isActive ? 2 : 1.5,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: hasValue
          ? Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

/// A 0–9 + backspace pad. Shared by PIN creation and PIN entry.
class PinPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  const PinPad({super.key, required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 4; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var col = 0; col < 3; col++)
                  _key(keys[row * 3 + col]),
              ],
            ),
          ),
      ],
    );
  }

  Widget _key(String k) {
    if (k.isEmpty) {
      return const SizedBox(width: 92, height: 58);
    }
    final isDel = k == 'del';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        width: 80,
        height: 58,
        child: Material(
          color: isDel ? Colors.transparent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          elevation: isDel ? 0 : 1.5,
          shadowColor: const Color(0x22311B92),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              HapticFeedback.selectionClick();
              isDel ? onDelete() : onDigit(k);
            },
            child: Center(
              child: isDel
                  ? const Icon(Icons.backspace_outlined,
                      size: 22, color: AppColors.textDark)
                  : Text(
                      k,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cards + steppers
// ---------------------------------------------------------------------------

/// A selectable card row (used for age bands, etc.).
class SelectCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  const SelectCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF8F5FF) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.line,
            width: selected ? 2 : 1.5,
          ),
          boxShadow: AppColors.softShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: 14),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppText.cardTitle),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AppColors.accent : Colors.transparent,
                      border: Border.all(
                        color:
                            selected ? AppColors.accent : const Color(0xFFCBC6DE),
                        width: 2,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            color: AppColors.textDark, size: 17)
                        : null,
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

/// A +/- stepper for integer settings.
class IntStepper extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String suffix;
  final ValueChanged<int> onChanged;
  final Widget? leading;

  const IntStepper({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.suffix = '',
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F7FD),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          _RoundIcon(
            icon: Icons.remove_rounded,
            enabled: value > min,
            onTap: () => onChanged((value - step).clamp(min, max)),
          ),
          SizedBox(
            width: 64,
            child: Text(
              '$value$suffix',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
          ),
          _RoundIcon(
            icon: Icons.add_rounded,
            enabled: value < max,
            onTap: () => onChanged((value + step).clamp(min, max)),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _RoundIcon({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.primary : const Color(0xFFE1DDF0),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step scaffold (settings sub-screens)
// ---------------------------------------------------------------------------

/// Page layout for settings sub-screens: title, optional subtitle, scrollable
/// body, one primary button pinned to the bottom.
class StepScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final String buttonLabel;
  final VoidCallback? onButton; // null => button disabled
  final bool showBack;
  final int? currentStep;
  final int? totalSteps;

  const StepScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    required this.buttonLabel,
    required this.onButton,
    this.showBack = true,
    this.currentStep,
    this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppColors.bgDecoration(),
        height: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              NupoTopBar(
                showBack: showBack,
                step: currentStep,
                total: totalSteps,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.title),
                      if (subtitle != null) ...[
                        const SizedBox(height: 8),
                        Text(subtitle!, style: AppText.body),
                      ],
                      const SizedBox(height: 20),
                      child,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: PrimaryButton(label: buttonLabel, onPressed: onButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
