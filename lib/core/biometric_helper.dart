import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricHelper {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Check if device supports biometric authentication
  static Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  /// Check if device has enrolled biometrics
  static Future<bool> isDeviceSupported() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;

      final availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Authenticate with biometric (fingerprint/face)
  static Future<bool> authenticate() async {
    try {
      final isSupported = await isDeviceSupported();
      if (!isSupported) return false;

      return await _auth.authenticate(
        localizedReason: 'Pindai sidik jari untuk memuat sesi Zmayy Anda.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
