// screens/onboarding/perm_heroes.dart — one picture per permission step,
// showing the parent what the switch does or exactly which one to find.

import 'package:flutter/material.dart';

import '../../theme.dart';
import 'onb_kit.dart';

/// "Display over other apps": a lesson card floating over a game.
class OverlayHero extends StatelessWidget {
  const OverlayHero({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 200,
    height: 200,
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 128,
          height: 200,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: AppColors.textDark, borderRadius: BorderRadius.circular(22)),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color.lerp(AppColors.textDark, Colors.white, 0.12),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Column(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  if (i < 2) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 58,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: AppColors.textDark.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 14)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Chip2('Lesson time'),
                const SizedBox(height: 8),
                Container(height: 9, width: 120, decoration: BoxDecoration(color: kLilac, borderRadius: BorderRadius.circular(5))),
                const SizedBox(height: 8),
                Container(height: 26, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(9))),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// A settings row, highlighted and switched on.
class _SettingRow extends StatelessWidget {
  final String label;
  final bool on;
  final bool focus;
  const _SettingRow(this.label, {this.on = false, this.focus = false});

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: focus ? 1 : 0.5,
    child: Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 12, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: focus ? Border.all(color: AppColors.correct, width: 3) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: focus ? AppColors.primary : const Color(0xFFD7D1E3),
              borderRadius: BorderRadius.circular(9),
            ),
            child: focus
                ? const Text('N', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: focus ? AppColors.textDark : const Color(0xFFA9A3B8),
              ),
            ),
          ),
          _Switch(on: on),
        ],
      ),
    ),
  );
}

class _Switch extends StatelessWidget {
  final bool on;
  const _Switch({required this.on});

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 26,
    padding: const EdgeInsets.all(3),
    alignment: on ? Alignment.centerRight : Alignment.centerLeft,
    decoration: BoxDecoration(
      color: on ? AppColors.correct : const Color(0xFFE3DDEE),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
    ),
  );
}

/// "Usage access": find Nupo in the list.
class UsageHero extends StatelessWidget {
  const UsageHero({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 250,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SettingRow('Calculator'),
        SizedBox(height: 8),
        _SettingRow('Nupo', on: true, focus: true),
        SizedBox(height: 8),
        _SettingRow('Calendar'),
      ],
    ),
  );
}

/// Battery: a full battery with a bolt.
class BatteryHero extends StatelessWidget {
  const BatteryHero({super.key});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 34,
        height: 14,
        decoration: BoxDecoration(color: kAmberLedge, borderRadius: const BorderRadius.vertical(top: Radius.circular(5))),
      ),
      Container(
        width: 96,
        height: 150,
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: kAmberLedge, width: 5),
        ),
        child: Column(
          children: [
            Expanded(flex: 2, child: Container(decoration: BoxDecoration(color: tint(AppColors.accent, 0.6), borderRadius: BorderRadius.circular(9)))),
            const SizedBox(height: 6),
            Expanded(
              flex: 3,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.bolt_rounded, size: 42, color: AppColors.accentDeep),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Autostart: a rocket over the Autostart switch.
class AutostartHero extends StatelessWidget {
  const AutostartHero({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 250,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.rocket_launch_rounded, size: 72, color: AppColors.correct),
        SizedBox(height: 12),
        _SettingRow('Autostart', on: true, focus: true),
      ],
    ),
  );
}
