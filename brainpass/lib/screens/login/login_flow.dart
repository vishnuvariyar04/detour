// screens/login/login_flow.dart
//
// MANDATORY parent login (a hard paywall follows, so it can't be skipped).
// Three steps: a light parental gate (Play Families requires a gate before
// collecting personal info from a device kids use) -> phone number -> OTP.
//
// Sign-in state is watched by RootRouter (main.dart), so on success this whole
// flow is simply swapped out for onboarding/home — this widget just performs
// the Firebase calls.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../auth_service.dart';
import '../../theme.dart';
import '../../widgets.dart';

class LoginFlow extends StatefulWidget {
  const LoginFlow({super.key});

  @override
  State<LoginFlow> createState() => _LoginFlowState();
}

class _LoginFlowState extends State<LoginFlow> {
  int _step = 0; // 0 = phone, 1 = otp
  bool _busy = false;
  String? _error;

  String? _phoneE164;
  String? _verificationId;
  int? _resendToken;

  Timer? _cooldown;
  int _resendSeconds = 0;

  @override
  void dispose() {
    _cooldown?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _resendSeconds = 60;
    _cooldown?.cancel();
    _cooldown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          t.cancel();
        }
      });
    });
  }

  Future<void> _sendCode(String e164, {bool resend = false}) async {
    setState(() {
      _busy = true;
      _error = null;
      if (!resend) _phoneE164 = e164;
    });
    try {
      await AuthService.sendVerification(
        phoneE164: _phoneE164!,
        resendToken: resend ? _resendToken : null,
        onAutoVerified: (cred) async {
          // Instant on-device verification — sign in silently; the router
          // reacts to the auth change and moves us forward.
          try {
            await AuthService.signInWithCredential(cred);
          } catch (_) {}
        },
        onFailed: (e) {
          if (mounted) {
            setState(() {
              _busy = false;
              _error = AuthService.errorMessage(e);
            });
          }
        },
        onCodeSent: (verificationId, token) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = token;
            _busy = false;
            _step = 2;
          });
          _startCooldown();
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AuthService.errorMessage(e);
        });
      }
    }
  }

  Future<void> _verifyOtp(String code) async {
    if (_verificationId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.signInWithSmsCode(
        verificationId: _verificationId!,
        smsCode: code,
      );
      // Success: RootRouter swaps this screen out. Leave _busy true.
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AuthService.errorMessage(e);
        });
      }
    }
  }

  void _back() {
    if (_step == 0) return;
    setState(() {
      _error = null;
      _step -= 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget child;
    switch (_step) {
      case 0:
        child = _PhoneStep(
          key: const ValueKey('phone'),
          busy: _busy,
          error: _error,
          onSend: _sendCode,
        );
        break;
      default:
        child = _OtpStep(
          key: const ValueKey('otp'),
          phoneLabel: _phoneE164 ?? '',
          busy: _busy,
          error: _error,
          resendSeconds: _resendSeconds,
          onBack: _back,
          onVerify: _verifyOtp,
          onResend: _resendSeconds == 0 && !_busy
              ? () => _sendCode(_phoneE164!, resend: true)
              : null,
        );
    }

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        transitionBuilder: (c, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.06, 0), end: Offset.zero)
                .animate(anim),
            child: c,
          ),
        ),
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 — Phone number
// ---------------------------------------------------------------------------
class _Country {
  final String name, dial, flag;
  const _Country(this.name, this.dial, this.flag);
}

const List<_Country> _countries = [
  _Country('India', '+91', '🇮🇳'),
  _Country('United States', '+1', '🇺🇸'),
  _Country('United Kingdom', '+44', '🇬🇧'),
  _Country('Canada', '+1', '🇨🇦'),
  _Country('Australia', '+61', '🇦🇺'),
  _Country('UAE', '+971', '🇦🇪'),
  _Country('Singapore', '+65', '🇸🇬'),
  _Country('Germany', '+49', '🇩🇪'),
];

class _PhoneStep extends StatefulWidget {
  final bool busy;
  final String? error;
  final void Function(String e164) onSend;
  const _PhoneStep({
    super.key,
    required this.busy,
    required this.error,
    required this.onSend,
  });

  @override
  State<_PhoneStep> createState() => _PhoneStepState();
}

class _PhoneStepState extends State<_PhoneStep> {
  _Country _country = _countries.first;
  final _controller = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.busy) return;
    // Strip non-digits and any leading zeros from the national number.
    final national =
        _controller.text.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
    if (national.length < 6 || national.length > 14) {
      setState(() => _localError = "That number doesn't look right.");
      return;
    }
    setState(() => _localError = null);
    FocusScope.of(context).unfocus();
    widget.onSend('${_country.dial}$national');
  }

  void _pickCountry() async {
    final picked = await showModalBottomSheet<_Country>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            for (final c in _countries)
              ListTile(
                leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                title: Text(c.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark)),
                trailing: Text(c.dial,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted)),
                onTap: () => Navigator.of(context).pop(c),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _country = picked);
  }

  @override
  Widget build(BuildContext context) {
    final error = _localError ?? widget.error;
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
                  padding: const EdgeInsets.fromLTRB(28, 4, 28, 24),
                  child: Column(
                    children: [
                      const HaloMascot('assets/mascot_pin.png', size: 130),
                      const SizedBox(height: 18),
                      const Text('Sign in to continue', style: AppText.title),
                      const SizedBox(height: 8),
                      const Text(
                        "We'll text a 6-digit code to your phone to make sure it's really you.",
                        textAlign: TextAlign.center,
                        style: AppText.body,
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          // Country code chip
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: widget.busy ? null : _pickCountry,
                              child: Container(
                                height: 58,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: Row(
                                  children: [
                                    Text(_country.flag,
                                        style: const TextStyle(fontSize: 20)),
                                    const SizedBox(width: 6),
                                    Text(_country.dial,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: AppColors.textDark,
                                        )),
                                    const Icon(Icons.expand_more_rounded,
                                        color: AppColors.textMuted, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              enabled: !widget.busy,
                              keyboardType: TextInputType.phone,
                              autofocus: true,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Phone number',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 18),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide:
                                      const BorderSide(color: AppColors.line),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                      color: AppColors.primary, width: 2),
                                ),
                              ),
                              onSubmitted: (_) => _submit(),
                              onChanged: (_) {
                                if (_localError != null) {
                                  setState(() => _localError = null);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 34,
                        child: Center(
                          child: error == null
                              ? null
                              : Text(error,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: AppColors.wrong,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const InfoPill(
                        icon: Icons.info_outline_rounded,
                        text: "This is the parent's number. Message rates may apply.",
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 4, 28, 18),
                child: widget.busy
                    ? const _BusyButton()
                    : PrimaryButton(label: 'Send code', onPressed: _submit),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 — OTP
// ---------------------------------------------------------------------------
class _OtpStep extends StatefulWidget {
  final String phoneLabel;
  final bool busy;
  final String? error;
  final int resendSeconds;
  final VoidCallback onBack;
  final void Function(String code) onVerify;
  final VoidCallback? onResend;
  const _OtpStep({
    super.key,
    required this.phoneLabel,
    required this.busy,
    required this.error,
    required this.resendSeconds,
    required this.onBack,
    required this.onVerify,
    required this.onResend,
  });

  @override
  State<_OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends State<_OtpStep> {
  String _code = '';

  @override
  void didUpdateWidget(_OtpStep old) {
    super.didUpdateWidget(old);
    // A new error means the entered code was wrong — clear it to retry.
    if (widget.error != null && old.error != widget.error) {
      _code = '';
    }
  }

  void _onDigit(String d) {
    if (widget.busy || _code.length >= 6) return;
    setState(() => _code += d);
    if (_code.length == 6) {
      widget.onVerify(_code);
    }
  }

  void _onDelete() {
    if (_code.isEmpty) return;
    setState(() => _code = _code.substring(0, _code.length - 1));
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
              NupoTopBar(showBack: true, onBack: widget.onBack),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text('Enter the code', style: AppText.title),
                      const SizedBox(height: 8),
                      Text(
                        'Sent to ${widget.phoneLabel}',
                        textAlign: TextAlign.center,
                        style: AppText.body,
                      ),
                      const SizedBox(height: 26),
                      PinBoxes(filled: _code.length, count: 6),
                      SizedBox(
                        height: 34,
                        child: Center(
                          child: widget.busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : widget.error == null
                                  ? null
                                  : Text(widget.error!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          color: AppColors.wrong,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800)),
                        ),
                      ),
                      PinPad(onDigit: _onDigit, onDelete: _onDelete),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: widget.onResend,
                        child: Text(
                          widget.resendSeconds > 0
                              ? 'Resend code in ${widget.resendSeconds}s'
                              : 'Resend code',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: widget.onResend == null
                                ? AppColors.textMuted
                                : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
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

/// Primary-button-shaped busy indicator, so the CTA row keeps its height.
class _BusyButton extends StatelessWidget {
  const _BusyButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFE3E0F0),
        borderRadius: BorderRadius.circular(29),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }
}
