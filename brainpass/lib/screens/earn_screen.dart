// screens/earn_screen.dart — the kid-facing lock/earn screen (spec §9.8).
//
// This is launched as a full-screen Activity by the native accessibility service
// when a gated app is opened (or when its time runs out). It is NOT an overlay
// anymore — being a real launched screen is what lets the native engine summon
// it reliably even after the app was killed.
//
// Flow (mode comes from the native engine):
//   - mode "done" -> "All done for today" for this app (parent PIN overrides).
//   - mode "earn" -> solve this app's question count; each correct fills a star.
//     Wrong answers are gentle (reveal answer, new question, no star lost).
//   - On the last star: tell the native engine the child EARNED (it adds this
//     app's minute block), then close.
//   - Back button is disabled; only solving or the parent PIN dismisses it.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine.dart';
import '../pin.dart';
import '../questions.dart';
import '../storage.dart';
import '../theme.dart';

class EarnScreen extends StatelessWidget {
  final LockInfo info;
  const EarnScreen({super.key, required this.info});

  Future<void> _earnedAndClose() async {
    await Engine.earned(info.package);
    await Engine.finishLock();
  }

  Future<void> _overrideAndClose() async {
    await Engine.parentOverride(info.package);
    await Engine.finishLock();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // a child can't back out of the lock
      child: info.mode == 'done'
          ? DoneForTodayView(onParentOverride: _overrideAndClose)
          : EarnFlowView(
              package: info.package,
              target: info.questions,
              minutes: info.minutes,
              onEarned: _earnedAndClose,
              onParentBypass: _overrideAndClose,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
class _Gradient extends StatelessWidget {
  final Widget child;
  const _Gradient({required this.child});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.kidTop, AppColors.kidBottom],
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EARN FLOW
// ---------------------------------------------------------------------------
class EarnFlowView extends StatefulWidget {
  final String package;
  final int target; // this app's questions-to-earn
  final int minutes; // this app's minutes earned (for display)
  final Future<void> Function() onEarned;
  final Future<void> Function() onParentBypass;
  const EarnFlowView({
    super.key,
    required this.package,
    required this.target,
    required this.minutes,
    required this.onEarned,
    required this.onParentBypass,
  });

  @override
  State<EarnFlowView> createState() => _EarnFlowViewState();
}

class _EarnFlowViewState extends State<EarnFlowView> {
  late Band _band;
  late int _target;
  late List<QuestionKind> _plan;
  late Question _q;
  int _solved = 0;
  String _typed = '';
  bool _revealing = false;
  String _feedback = '';

  @override
  void initState() {
    super.initState();
    _band = bandFromString(Storage.ageBand);
    _target = widget.target;
    _plan = buildEarnPlan(_target);
    _q = generateOne(_band, _plan[0]);
  }

  void _nextQuestion() {
    setState(() {
      _typed = '';
      _revealing = false;
      _feedback = '';
      final idx = _solved < _plan.length ? _solved : _plan.length - 1;
      _q = generateOne(_band, _plan[idx]);
    });
  }

  Future<void> _submit(String given) async {
    if (_revealing || _feedback == 'done') return;
    if (isCorrect(_q, given)) {
      HapticFeedback.lightImpact();
      final willComplete = _solved + 1 >= _target;
      setState(() {
        _solved++;
        _feedback = 'correct';
      });
      if (willComplete) {
        setState(() => _feedback = 'done');
        await Future.delayed(const Duration(milliseconds: 1100));
        await widget.onEarned();
      } else {
        await Future.delayed(const Duration(milliseconds: 650));
        if (mounted) _nextQuestion();
      }
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _revealing = true;
        _feedback = 'wrong';
      });
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) _nextQuestion();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Gradient(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _StarBar(total: _target, filled: _solved),
                const SizedBox(height: 6),
                Text(
                  'Solve $_target to play!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _QuestionCard(question: _q, typed: _typed, feedback: _feedback),
                const Spacer(),
                if (_q.isMultipleChoice)
                  _OptionButtons(
                    options: _q.options!,
                    enabled: !_revealing && _feedback != 'done',
                    correctAnswer: _q.answer,
                    revealing: _revealing,
                    onPick: _submit,
                  )
                else
                  _Keypad(
                    enabled: !_revealing && _feedback != 'done',
                    onKey: (k) => setState(() {
                      if (k == 'del') {
                        if (_typed.isNotEmpty) {
                          _typed = _typed.substring(0, _typed.length - 1);
                        }
                      } else if (k == 'ok') {
                        if (_typed.isNotEmpty) _submit(_typed);
                      } else if (_typed.length < 6) {
                        _typed += k;
                      }
                    }),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: _ParentLink(onSuccess: widget.onParentBypass),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _StarBar extends StatelessWidget {
  final int total;
  final int filled;
  const _StarBar({required this.total, required this.filled});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Icon(
              i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: AppColors.accent,
              size: 40,
            ),
          ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final Question question;
  final String typed;
  final String feedback;
  const _QuestionCard({
    required this.question,
    required this.typed,
    required this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    String banner = '';
    Color bannerColor = Colors.transparent;
    if (feedback == 'correct') {
      banner = 'Great job! 🎉';
      bannerColor = AppColors.correct;
    } else if (feedback == 'wrong') {
      banner = 'Try again — the answer was ${question.answer}';
      bannerColor = AppColors.wrong;
    } else if (feedback == 'done') {
      banner = 'You earned your time! 🎉';
      bannerColor = AppColors.correct;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            question.prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          if (!question.isMultipleChoice) ...[
            const SizedBox(height: 18),
            Container(
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                typed.isEmpty ? ' ' : typed,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
          if (banner.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: bannerColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                banner,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: bannerColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final bool enabled;
  final void Function(String key) onKey;
  const _Keypad({required this.enabled, required this.onKey});
  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', 'del', '0', 'ok'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.9,
      children: [
        for (final k in keys)
          _KeyButton(label: k, enabled: enabled, onTap: () => onKey(k)),
      ],
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _KeyButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final isOk = label == 'ok';
    final isDel = label == 'del';
    Widget content;
    if (isDel) {
      content = const Icon(Icons.backspace_rounded, size: 26);
    } else if (isOk) {
      content = const Icon(Icons.check_rounded, size: 30, color: Colors.white);
    } else {
      content = Text(label,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800));
    }
    return Material(
      color: isOk ? AppColors.correct : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? onTap : null,
        child: Center(child: content),
      ),
    );
  }
}

class _OptionButtons extends StatelessWidget {
  final List<String> options;
  final bool enabled;
  final bool revealing;
  final String correctAnswer;
  final void Function(String picked) onPick;
  const _OptionButtons({
    required this.options,
    required this.enabled,
    required this.revealing,
    required this.correctAnswer,
    required this.onPick,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final opt in options)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: SizedBox(
              width: double.infinity,
              height: 64,
              child: Material(
                color: revealing && opt == correctAnswer
                    ? AppColors.correct
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: enabled ? () => onPick(opt) : null,
                  child: Center(
                    child: Text(
                      opt,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: revealing && opt == correctAnswer
                            ? Colors.white
                            : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Parent bypass (spec §9.8 / §13)
// ---------------------------------------------------------------------------
class _ParentLink extends StatelessWidget {
  final Future<void> Function() onSuccess;
  const _ParentLink({required this.onSuccess});

  Future<void> _open(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const ParentPinDialog(),
    );
    if (ok == true) await onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => _open(context),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white70,
        textStyle: const TextStyle(fontSize: 13),
      ),
      child: const Text('Parent'),
    );
  }
}

class ParentPinDialog extends StatefulWidget {
  const ParentPinDialog({super.key});
  @override
  State<ParentPinDialog> createState() => _ParentPinDialogState();
}

class _ParentPinDialogState extends State<ParentPinDialog> {
  final _controller = TextEditingController();
  String? _error;

  void _check() {
    if (Pin.verify(_controller.text)) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Wrong PIN');
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Parent PIN'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 4,
        autofocus: true,
        decoration: InputDecoration(
          counterText: '',
          errorText: _error,
          hintText: '••••',
        ),
        onSubmitted: (_) => _check(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _check, child: const Text('Unlock')),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// DONE FOR TODAY (spec §9.9)
// ---------------------------------------------------------------------------
class DoneForTodayView extends StatelessWidget {
  final Future<void> Function() onParentOverride;
  const DoneForTodayView({super.key, required this.onParentOverride});

  Future<void> _override(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const ParentPinDialog(),
    );
    if (ok == true) await onParentOverride();
  }

  @override
  Widget build(BuildContext context) {
    return _Gradient(
      child: Stack(
        children: [
          const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🌙', style: TextStyle(fontSize: 72)),
                  SizedBox(height: 16),
                  Text(
                    'All done for today!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "You've used all your screen time.\nSee you tomorrow! 👋",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: TextButton(
              onPressed: () => _override(context),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('Parent'),
            ),
          ),
        ],
      ),
    );
  }
}
