import 'package:flutter/material.dart';

import '../../auth_service.dart';
import '../../theme.dart';
import '../../widgets.dart';
import '../onboarding/onb_widgets.dart';

class ReauthDeleteScreen extends StatefulWidget {
  const ReauthDeleteScreen({super.key});

  @override
  State<ReauthDeleteScreen> createState() => _ReauthDeleteScreenState();
}

class _ReauthDeleteScreenState extends State<ReauthDeleteScreen> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  /// An email/password account cannot be re-verified silently — Firebase needs
  /// the password again, so this screen has to collect it.
  bool get _needsPassword => AuthService.providerId == 'password';

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _confirmWithPassword() => _confirm(() async {
        final email = AuthService.email;
        if (email == null) throw const AuthFailure('Not signed in.');
        // Re-signing in refreshes the login age, which is what delete() wants.
        await AuthService.signInWithEmail(email, _password.text);
      });

  Future<void> _confirm(Future<void> Function() reauthenticate) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await reauthenticate();
      await AuthService.deleteAccount();
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = AuthService.errorMessage(error);
      });
    }
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
              const NupoTopBar(title: 'Delete account'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      const HaloMascot('assets/mascot_pin.png', size: 130),
                      const SizedBox(height: 20),
                      const Text('Confirm it is you', style: AppText.title),
                      const SizedBox(height: 8),
                      const Text(
                        'Sign in again to permanently delete your account.',
                        textAlign: TextAlign.center,
                        style: AppText.body,
                      ),
                      const SizedBox(height: 24),
                      if (_needsPassword) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.cardBorder, width: 1.5),
                          ),
                          child: TextField(
                            controller: _password,
                            obscureText: true,
                            autocorrect: false,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Your password',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 17),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        NupoButton(
                          label: 'Delete my account',
                          buttonTone: ButtonTone.brand,
                          onPressed: _busy || _password.text.length < 6
                              ? null
                              : _confirmWithPassword,
                        ),
                      ] else
                      // One button: re-authentication has to use whichever
                      // provider the account was made with, so offering a
                      // choice only invites picking the wrong one.
                      _DeleteProviderButton(
                        label: 'Continue with ${AuthService.providerLabel}',
                        icon: AuthService.providerId == 'apple.com'
                            ? Icons.apple_rounded
                            : Icons.g_mobiledata_rounded,
                        filled: true,
                        busy: _busy,
                        onPressed: () =>
                            _confirm(AuthService.reauthenticate),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 18),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.wrong,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
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

class _DeleteProviderButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool busy;
  final VoidCallback onPressed;

  const _DeleteProviderButton({
    required this.label,
    required this.icon,
    required this.busy,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 58,
        child: OutlinedButton.icon(
          onPressed: busy ? null : onPressed,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, size: 25),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            backgroundColor: filled ? AppColors.textDark : Colors.white,
            foregroundColor: filled ? Colors.white : AppColors.textDark,
            side: BorderSide(
              color: filled ? AppColors.textDark : AppColors.line,
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(29),
            ),
            textStyle: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
}
