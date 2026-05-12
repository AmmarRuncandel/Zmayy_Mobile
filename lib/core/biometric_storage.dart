import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _keyBiometricEnabled = 'biometric_chat_enabled';

  /// Check if biometric protection for chat is enabled
  static Future<bool> isBiometricChatEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  /// Enable biometric protection for chat
  static Future<void> enableBiometricChat() async {
    await _storage.write(key: _keyBiometricEnabled, value: 'true');
  }

  /// Disable biometric protection for chat
  static Future<void> disableBiometricChat() async {
    await _storage.delete(key: _keyBiometricEnabled);
  }
}
