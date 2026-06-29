// screens/pin_entry_screen.dart
//
// Re-enter the PIN to reach the PIN-protected parent home (spec §9.7).
// Returns true via Navigator.pop when the PIN is correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pin.dart';
import '../theme.dart';

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
    if (_pin.length == 4) _verify();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _verify() {
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
      appBar: AppBar(title: const Text('Enter PIN')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.lock_rounded, size: 56, color: AppColors.primary),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 4; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _pin.length
                            ? AppColors.primary
                            : Colors.transparent,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!,
                    style: const TextStyle(color: AppColors.wrong, fontSize: 15)),
              ],
              const Spacer(),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.7,
                children: [
                  for (final k in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'])
                    if (k.isEmpty)
                      const SizedBox.shrink()
                    else
                      InkWell(
                        borderRadius: BorderRadius.circular(40),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          k == 'del' ? _onDelete() : _onDigit(k);
                        },
                        child: Center(
                          child: k == 'del'
                              ? const Icon(Icons.backspace_rounded, size: 26)
                              : Text(k,
                                  style: const TextStyle(
                                      fontSize: 30, fontWeight: FontWeight.w700)),
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _showForgot(context),
                child: const Text('Forgot PIN?'),
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
        title: const Text('Forgot your PIN?'),
        content: const Text(
          'Nupo keeps everything on your device with no account, so the PIN '
          'can\'t be recovered.\n\nTo reset it, open:\n'
          'Android Settings → Apps → Nupo → Storage → Clear data,\n'
          'then set Nupo up again.\n\n'
          'Note: this also clears your gated-app settings.',
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
