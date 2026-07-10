// screens/login/reauth_delete_screen.dart
//
// Deleting a Firebase account is a sensitive op: it needs a RECENT login. So we
// send a fresh OTP to the signed-in number, re-authenticate, then delete.
// Pops `true` once the account is gone (RootRouter then drops to login).

import 'dart:async';

import 'package:flutter/material.dart';

import '../../auth_service.dart';
import '../../theme.dart';
import '../../widgets.dart';

class ReauthDeleteScreen extends StatefulWidget {
  const ReauthDeleteScreen({super.key});

  @override
  State<ReauthDeleteScreen> createState() => _ReauthDeleteScreenState();
}

class _ReauthDeleteScreenState extends State<ReauthDeleteScreen> {
  final String _phone = AuthService.phoneNumber ?? '';
  String? _verificationId;
  int? _resendToken;
  bool _busy = true; // start by sending the code
  String? _error;
  String _code = '';
  int _resendSeconds = 0;
  Timer? _cooldown;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

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

  Future<void> _sendCode({bool resend = false}) async {
    setState(() {
      _busy = true;
      _error = null;
      _code = '';
    });
    try {
      await AuthService.sendVerification(
        phoneE164: _phone,
        resendToken: resend ? _resendToken : null,
        onAutoVerified: (cred) async {
          try {
            await AuthService.reauthWithCredential(cred);
            await _finishDelete();
          } catch (e) {
            if (mounted) {
              setState(() {
                _busy = false;
                _error = AuthService.errorMessage(e);
              });
            }
          }
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

  Future<void> _verify(String code) async {
    if (_verificationId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.reauthWithSmsCode(
        verificationId: _verificationId!,
        smsCode: code,
      );
      await _finishDelete();
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AuthService.errorMessage(e);
          _code = '';
        });
      }
    }
  }

  Future<void> _finishDelete() async {
    try {
      await AuthService.deleteAccount();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AuthService.errorMessage(e);
        });
      }
    }
  }

  void _onDigit(String d) {
    if (_busy || _code.length >= 6) return;
    setState(() => _code += d);
    if (_code.length == 6) _verify(_code);
  }

  void _onDelete() {
    if (_code.isEmpty) return;
    setState(() => _code = _code.substring(0, _code.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _resendSeconds == 0 && !_busy;
    return Scaffold(
      body: Container(
        decoration: AppColors.bgDecoration(),
        height: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              const NupoTopBar(title: 'Delete account'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const Text("Confirm it's you", style: AppText.title),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the code sent to $_phone to permanently delete your account.',
                        textAlign: TextAlign.center,
                        style: AppText.body,
                      ),
                      const SizedBox(height: 26),
                      PinBoxes(filled: _code.length, count: 6),
                      SizedBox(
                        height: 34,
                        child: Center(
                          child: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : _error == null
                                  ? null
                                  : Text(_error!,
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
                        onPressed:
                            canResend ? () => _sendCode(resend: true) : null,
                        child: Text(
                          _resendSeconds > 0
                              ? 'Resend code in ${_resendSeconds}s'
                              : 'Resend code',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: canResend
                                ? AppColors.primary
                                : AppColors.textMuted,
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
