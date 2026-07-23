// screens/onboarding/hook_screen.dart
//
// Phase 0 of the funnel (spec S1–S4): four swipeable cards ending in the
// micro-aha — the parent answers a real question themselves within ~20 seconds
// of install. On the correct tap the owl celebrates and the setup CTA appears.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme.dart';
import '../../widgets.dart';
import 'onb_widgets.dart';

class HookScreen extends StatefulWidget {
  final VoidCallback onNext;
  const HookScreen({super.key, required this.onNext});

  @override
  State<HookScreen> createState() => _HookScreenState();
}

class _HookScreenState extends State<HookScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _solved = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _advance() {
    if (_page < 3) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onSolved() {
    HapticFeedback.mediumImpact();
    setState(() => _solved = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_solved) return _CelebrationCard(onNext: widget.onNext);

    return Scaffold(
      body: Container(
        decoration: AppColors.bgDecoration(),
        height: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (p) => setState(() => _page = p),
                  children: [
                    _HookPage(
                      hero: const HaloMascot('assets/mascot_opening.png',
                          size: 170),
                      badge: '📱',
                      title: 'Every day, your child reaches for the phone.',
                      body:
                          'And “we’ll do some learning later” turns into… later.',
                    ),
                    _HookPage(
                      hero: const HaloMascot('assets/mascot_opening.png',
                          size: 170, sparkles: true),
                      title: 'Nupo turns that reach into a learning habit.',
                    ),
                    const _HookPage(
                      hero: _LockedAppsRow(),
                      title: 'It’s simple. Before games and videos open…',
                    ),
                    _QuizPage(onSolved: _onSolved),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
                child: Column(
                  children: [
                    ProgressDots(step: _page + 1, total: 4),
                    const SizedBox(height: 18),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _page < 3 ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: _page >= 3,
                        child:
                            PrimaryButton(label: 'Continue', onPressed: _advance),
                      ),
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

class _HookPage extends StatelessWidget {
  final Widget hero;
  final String? badge;
  final String title;
  final String? body;
  const _HookPage({
    required this.hero,
    required this.title,
    this.body,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, viewport) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: viewport.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              badge == null
                  ? hero
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        hero,
                        Positioned(
                          right: 18,
                          bottom: 22,
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: AppColors.softShadow,
                            ),
                            child: Text(badge!,
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
              Text(title, textAlign: TextAlign.center, style: AppText.title),
              if (body != null) ...[
                const SizedBox(height: 10),
                Text(body!, textAlign: TextAlign.center, style: AppText.body),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

/// Greyed-out app icons with little locks (spec S3).
class _LockedAppsRow extends StatelessWidget {
  const _LockedAppsRow();

  @override
  Widget build(BuildContext context) {
    const apps = [
      'com.google.android.youtube',
      'com.roblox.client',
      'com.kiloo.subwaysurf',
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final pkg in apps)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Opacity(
                  opacity: 0.45,
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.mode(
                        Color(0xFFB9B4CE), BlendMode.saturation),
                    child: AppBrandIcon(pkg, size: 66),
                  ),
                ),
                Positioned(
                  right: -6,
                  bottom: -6,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: AppColors.softShadow,
                    ),
                    child: const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 15),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// S4 — the micro-aha. The parent taps a real answer before giving any data.
class _QuizPage extends StatefulWidget {
  final VoidCallback onSolved;
  const _QuizPage({required this.onSolved});

  @override
  State<_QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<_QuizPage> {
  String? _wrongPick;

  void _tap(String v) {
    if (v == '42') {
      widget.onSolved();
    } else {
      HapticFeedback.lightImpact();
      setState(() => _wrongPick = v);
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) setState(() => _wrongPick = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, viewport) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: viewport.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('…they answer a few quick questions.',
                  textAlign: TextAlign.center, style: AppText.title),
              const SizedBox(height: 26),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: AppColors.cardDecoration(),
                child: Column(
                  children: [
                    const Text('TRY IT YOURSELF', style: AppText.overline),
                    const SizedBox(height: 10),
                    const Text('What’s 6 × 7?',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        )),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        for (final v in const ['42', '48', '36'])
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: _AnswerChip(
                                label: v,
                                wrong: _wrongPick == v,
                                onTap: () => _tap(v),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnswerChip extends StatelessWidget {
  final String label;
  final bool wrong;
  final VoidCallback onTap;
  const _AnswerChip({
    required this.label,
    required this.wrong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 56,
      decoration: BoxDecoration(
        color: wrong ? AppColors.wrongSoft : const Color(0xFFF7F5FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: wrong ? AppColors.wrong : const Color(0xFFDCD4F8),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: wrong ? AppColors.wrong : AppColors.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown the moment the parent gets it right: the fast aha, then the setup CTA.
class _CelebrationCard extends StatelessWidget {
  final VoidCallback onNext;
  const _CelebrationCard({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return StatementScreen(
      hero: const HaloMascot('assets/mascot_opening.png',
          size: 170, sparkles: true),
      title: '🎉 That’s it. That’s Nupo.',
      body: '90 seconds of learning. Then they play.',
      ctaLabel: 'Set it up for your child',
      onNext: onNext,
    );
  }
}
