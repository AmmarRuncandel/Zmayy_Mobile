import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'access_token';
  static const String _userKey = 'auth_user';
  static const String _profileKey = 'user_profile';

  SecureStorage._();

  static Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  static Future<String?> readToken() => _storage.read(key: _tokenKey);
  static Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  static Future<void> saveUser(String json) => _storage.write(key: _userKey, value: json);
  static Future<String?> readUser() => _storage.read(key: _userKey);
  static Future<void> deleteUser() => _storage.delete(key: _userKey);

  static Future<void> saveProfile(String json) => _storage.write(key: _profileKey, value: json);
  static Future<String?> readProfile() => _storage.read(key: _profileKey);
  static Future<void> deleteProfile() => _storage.delete(key: _profileKey);

  static Future<void> clearAll() => _storage.deleteAll();
}
