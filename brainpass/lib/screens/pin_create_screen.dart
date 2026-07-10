// screens/pin_create_screen.dart
//
// Create a 4-digit PIN, entered twice, stored as a salted hash (see pin.dart).
// This PIN protects all settings and is the emergency bypass on the gate.

import 'package:flutter/material.dart';

import '../pin.dart';
import '../theme.dart';
import '../widgets.dart';

class PinCreateScreen extends StatefulWidget {
  final VoidCallback onNext;
  final int? step;
  final int? total;
  const PinCreateScreen({
    super.key,
    required this.onNext,
    this.step,
    this.total,
  });

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
        if (_first.length == 4) {
          // Brief pause so the 4th dot is visible before switching.
          Future.delayed(const Duration(milliseconds: 250), () {
            if (mounted && _first.length == 4) {
              setState(() => _confirming = true);
            }
          });
        }
      } else {
        if (_second.length < 4) _second += d;
      }
    });
    if (_second.length == 4) {
      Future.delayed(const Duration(milliseconds: 200), _maybeSave);
    }
  }

  void _onDelete() {
    setState(() {
      _error = null;
      if (_confirming) {
        if (_second.isNotEmpty) {
          _second = _second.substring(0, _second.length - 1);
        } else {
          _confirming = false;
          _first = '';
        }
      } else if (_first.isNotEmpty) {
        _first = _first.substring(0, _first.length - 1);
      }
    });
  }

  Future<void> _maybeSave() async {
    if (!mounted || _second.length != 4) return;
    if (_first == _second) {
      await Pin.setPin(_first);
      widget.onNext();
    } else {
      setState(() {
        _error = "PINs didn't match — try again";
        _first = '';
        _second = '';
        _confirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _confirming ? _second : _first;
    return Scaffold(
      body: Container(
        decoration: AppColors.bgDecoration(),
        height: double.infinity,
        child: SafeArea(
          child: Column(
            children: [
              NupoTopBar(
                step: widget.step,
                total: widget.total,
                onBack: _confirming
                    ? () => setState(() {
                          _confirming = false;
                          _second = '';
                        })
                    : null,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const HaloMascot('assets/mascot_pin.png', size: 140),
                      const SizedBox(height: 12),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _confirming ? 'Confirm your PIN' : 'Create your PIN',
                          key: ValueKey(_confirming),
                          style: AppText.title,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _confirming
                            ? 'Enter the same 4 digits again.'
                            : 'Just for grown-ups — opens settings and skips a lesson.',
                        textAlign: TextAlign.center,
                        style: AppText.body,
                      ),
                      const SizedBox(height: 26),
                      PinBoxes(filled: active.length),
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
                      const SizedBox(height: 16),
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
