// screens/login/login_flow.dart — the mandatory parent sign-in gate.
//
// Two ways in, both landing on the same Firebase account: the native Google
// account sheet, and email + password. Phone/OTP was removed on 2026-08-25.
//
// Signing in is what restores a saved setup (see ProfileService.restore), so
// the copy sells it as getting your plan back rather than as a wall.

import 'package:flutter/material.dart';

import '../../auth_service.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../onboarding/onb_widgets.dart';

class LoginFlow extends StatefulWidget {
  const LoginFlow({super.key});

  @override
  State<LoginFlow> createState() => _LoginFlowState();
}

class _LoginFlowState extends State<LoginFlow> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  bool _creating = false; // false = sign in, true = create account
  bool _showPassword = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _emailLooksValid {
    final v = _email.text.trim();
    return v.contains('@') && v.contains('.') && v.length > 5;
  }

  bool get _canSubmit =>
      !_busy && _emailLooksValid && _password.text.length >= 6;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      await action();
      // On success the router swaps this screen out; nothing to do here.
    } catch (error) {
      if (!mounted) return;
      final cancelled = error is AuthFailure && error.cancelled;
      setState(() {
        _busy = false;
        _error = cancelled ? null : AuthService.errorMessage(error);
      });
    }
  }

  Future<void> _submitEmail() => _run(() async {
        if (_creating) {
          await AuthService.createWithEmail(_email.text, _password.text);
        } else {
          await AuthService.signInWithEmail(_email.text, _password.text);
        }
      });

  Future<void> _forgotPassword() async {
    if (!_emailLooksValid) {
      setState(() => _error = 'Type your email first, then tap this again.');
      return;
    }
    await _run(() async {
      await AuthService.sendPasswordReset(_email.text);
      if (!mounted) return;
      setState(() {
        _busy = false;
        // Firebase reports success even for an unregistered address, so this
        // deliberately does not claim the account exists.
        _notice = 'If that email has an account, a reset link is on its way.';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppColors.bgDecoration(),
        height: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              const NupoTopBar(showBack: false),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
                  child: Column(
                    children: [
                      if (MediaQuery.of(context).viewInsets.bottom == 0) ...[
                        const HaloMascot('assets/mascot_pin.png', size: 120),
                        const SizedBox(height: 18),
                      ],
                      Text(_creating ? 'Create your account' : 'Welcome back',
                          style: AppText.title),
                      const SizedBox(height: 8),
                      Text(
                        _creating
                            ? "So Nupo remembers your kid's plan on any phone."
                            : 'Sign in and your saved plan comes right back.',
                        textAlign: TextAlign.center,
                        style: AppText.body,
                      ),
                      const SizedBox(height: 22),

                      NupoButton(
                        label: 'Continue with Google',
                        buttonTone: ButtonTone.brand,
                        onPressed: _busy
                            ? null
                            : () => _run(AuthService.signInWithGoogle),
                      ),

                      const SizedBox(height: 18),
                      const _OrDivider(),
                      const SizedBox(height: 18),

                      _Field(
                        controller: _email,
                        hint: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _password,
                        hint: _creating ? 'Password (6+ characters)' : 'Password',
                        obscure: !_showPassword,
                        onChanged: (_) => setState(() {}),
                        trailing: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                        onSubmitted: _canSubmit ? (_) => _submitEmail() : null,
                      ),
                      const SizedBox(height: 14),

                      NupoButton(
                        label: _creating ? 'Create account' : 'Sign in',
                        buttonTone: ButtonTone.light,
                        onPressed: _canSubmit ? _submitEmail : null,
                      ),

                      if (!_creating) ...[
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: _busy ? null : _forgotPassword,
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],

                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        _Message(_error!, tone: AppColors.wrong),
                      ],
                      if (_notice != null) ...[
                        const SizedBox(height: 10),
                        _Message(_notice!, tone: AppColors.done),
                      ],

                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _creating = !_creating;
                                  _error = null;
                                  _notice = null;
                                }),
                        child: Text(
                          _creating
                              ? 'I already have an account'
                              : 'New here? Create an account',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      const Text(
                        'By continuing you agree to our Terms and Privacy Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _Field({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.trailing,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder, width: 1.5),
        ),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          autocorrect: false,
          enableSuggestions: !obscure,
          textInputAction:
              onSubmitted != null ? TextInputAction.done : TextInputAction.next,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB9B4CE),
            ),
            border: InputBorder.none,
            suffixIcon: trailing,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          ),
        ),
      );
}

class _Message extends StatelessWidget {
  final String text;
  final Color tone;
  const _Message(this.text, {required this.tone});

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: tone,
          fontSize: 13.5,
          height: 1.35,
          fontWeight: FontWeight.w800,
        ),
      );
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const Expanded(child: Divider(color: AppColors.cardBorder)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'or',
              style: AppText.caption.copyWith(color: AppColors.textMuted),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.cardBorder)),
        ],
      );
}
