// screens/pin_create_screen.dart — spec §9.2
//
// Create a 4-digit PIN, entered twice, stored as a salted hash (see pin.dart).
// This PIN protects all settings and is the emergency bypass on the gate.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pin.dart';
import '../theme.dart';

class PinCreateScreen extends StatefulWidget {
  final VoidCallback onNext;
  const PinCreateScreen({super.key, required this.onNext});

  @override
  State<PinCreateScreen> createState() => _PinCreateScreenState();
}

class _PinCreateScreenState extends State<PinCreateScreen> {
  String _first = '';
  String _second = '';
  bool _confirming = false;
  String? _error;

  void _onDigit(String d) {
    setState(() {
      _error = null;
      if (!_confirming) {
        if (_first.length < 4) _first += d;
        if (_first.length == 4) _confirming = true;
      } else {
        if (_second.length < 4) _second += d;
      }
    });
  }

  void _onDelete() {
    setState(() {
      _error = null;
      if (_confirming) {
        if (_second.isNotEmpty) {
          _second = _second.substring(0, _second.length - 1);
        } else {
          _confirming = false;
          _first = _first.substring(0, _first.length - 1);
        }
      } else if (_first.isNotEmpty) {
        _first = _first.substring(0, _first.length - 1);
      }
    });
  }

  Future<void> _maybeSave() async {
    if (_second.length == 4) {
      if (_first == _second) {
        await Pin.setPin(_first);
        widget.onNext();
      } else {
        setState(() {
          _error = "PINs didn't match. Try again.";
          _first = '';
          _second = '';
          _confirming = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Trigger save once 4 confirm digits are entered.
    if (_second.length == 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeSave());
    }
    final active = _confirming ? _second : _first;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                _confirming ? 'Re-enter your PIN' : 'Create a parent PIN',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This protects all settings and unlocks apps in an emergency. '
                'Keep it secret from your child.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
              const SizedBox(height: 32),
              _Dots(filled: active.length),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!,
                    style: const TextStyle(color: AppColors.wrong, fontSize: 15)),
              ],
              const Spacer(),
              _PinPad(onDigit: _onDigit, onDelete: _onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

/// Four dots showing how many digits have been entered.
class _Dots extends StatelessWidget {
  final int filled;
  const _Dots({required this.filled});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 4; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? AppColors.primary : Colors.transparent,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
          ),
      ],
    );
  }
}

/// A reusable 0–9 + delete pad. Shared by PIN creation and PIN entry.
class _PinPad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  const _PinPad({required this.onDigit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.7,
      children: [
        for (final k in keys)
          if (k.isEmpty)
            const SizedBox.shrink()
          else
            InkWell(
              borderRadius: BorderRadius.circular(40),
              onTap: () {
                HapticFeedback.selectionClick();
                k == 'del' ? onDelete() : onDigit(k);
              },
              child: Center(
                child: k == 'del'
                    ? const Icon(Icons.backspace_rounded, size: 26)
                    : Text(
                        k,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
      ],
    );
  }
}
