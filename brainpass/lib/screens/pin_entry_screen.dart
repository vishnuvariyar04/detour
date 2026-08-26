// screens/pin_entry_screen.dart
//
// Re-enter the PIN to reach the PIN-protected parent home.
// Returns true via Navigator.pop when the PIN is correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../pin.dart';
import '../theme.dart';
import '../widgets.dart';

class PinEntryScreen extends StatefulWidget {
  const PinEntryScreen({super.key});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String _pin = '';
  String? _error;

  void _onDigit(String d) {
    if (_pin.length >= 4) return;
    setState(() {
      _error = null;
      _pin += d;
    });
    if (_pin.length == 4) {
      // Small delay to let the last dot render before verifying.
      Future.delayed(const Duration(milliseconds: 150), _verify);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _verify() {
    if (!mounted) return;
    if (Pin.verify(_pin)) {
      Navigator.of(context).pop(true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = 'Wrong PIN. Try again.';
        _pin = '';
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
              const NupoTopBar(title: 'Parent settings'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.line, width: 1.5),
                          boxShadow: AppColors.softShadow,
                        ),
                        child: Icon(
                          Symbols.lock_rounded,
                          color: AppColors.primary,
                          size: 38,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Enter your parent PIN', style: AppText.title),
                      const SizedBox(height: 6),
                      const Text(
                        'The four digits you chose during setup.',
                        style: AppText.body,
                      ),
                      const SizedBox(height: 24),
                      PinBoxes(filled: _pin.length),
                      SizedBox(
                        height: 34,
                        child: Center(
                          child: _error == null
                              ? null
                              : Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: AppColors.wrong,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                      PinPad(onDigit: _onDigit, onDelete: _onDelete),
                      TextButton(
                        onPressed: () => _showForgot(context),
                        child: const Text('Forgot PIN?'),
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

  void _showForgot(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Forgot your PIN?',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        content: const Text(
          'For safety, your PIN cannot be recovered.\n\n'
          'To reset: Android Settings, then Apps, then Nupo, then Storage, '
          'then Clear data. You will set Nupo up again.',
          style: AppText.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
