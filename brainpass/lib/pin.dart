// pin.dart
//
// The parent PIN protects every setting and is the emergency bypass on the gate
// (spec §9.2, §13). We never store the PIN itself — only a salted SHA-256 hash.

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

import 'storage.dart';

class Pin {
  /// Create a random salt as a hex string.
  static String _newSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  static String _hash(String pin, String salt) {
    final digest = sha256.convert(utf8.encode('$salt:$pin'));
    return digest.toString();
  }

  /// Set (or change) the parent PIN. Generates a fresh salt each time.
  static Future<void> setPin(String pin) async {
    final salt = _newSalt();
    await Storage.setPin(_hash(pin, salt), salt);
  }

  /// Returns true if [pin] matches the stored salted hash.
  static bool verify(String pin) {
    final hash = Storage.pinHash;
    final salt = Storage.pinSalt;
    if (hash == null || salt == null) return false;
    return _hash(pin, salt) == hash;
  }
}
