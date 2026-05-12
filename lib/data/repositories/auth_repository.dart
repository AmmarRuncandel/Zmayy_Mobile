import 'dart:convert';

import '../../core/api_client.dart';
import '../../core/secure_storage.dart';

class AuthRepository {
  final ApiClient _client = ApiClient();

  AuthRepository();

  Future<Map<String, dynamic>> _persistSession(Map<String, dynamic> resp) async {
    final token = resp['access_token'] as String?;
    final user = resp['user'];
    final profile = resp['profile'];
    // mobile-session in Phase 2 may not return an access_token (it's used for validation
    // and profile snapshot). Only save token when present.
    if (token != null && token.isNotEmpty) {
      await SecureStorage.saveToken(token);
    }
    await SecureStorage.saveUser(jsonEncode(user ?? {}));
    await SecureStorage.saveProfile(jsonEncode(profile ?? {}));

    if (profile is Map<String, dynamic>) {
      return profile;
    }

    return Map<String, dynamic>.from(profile ?? {});
  }

  /// Attempts to login. On success saves access_token and profile JSON.
  Future<Map<String, dynamic>> login(String email, String password) async {
    final resp = await _client.post('/api/auth/mobile-login', {
      'email': email,
      'password': password,
    });

    return _persistSession(Map<String, dynamic>.from(resp as Map));
  }

  /// Validates the current token against the backend and refreshes the stored profile.
  Future<Map<String, dynamic>> validateSession() async {
    final resp = await _client.get('/api/auth/mobile-session');
    final data = Map<String, dynamic>.from(resp as Map);
    final valid = data['session_valid'];
    if (valid is bool && valid == false) {
      throw Exception('Session invalid');
    }
    return _persistSession(data);
  }

  /// Attempts to register a new user. On success saves access_token and profile JSON.
  Future<Map<String, dynamic>> register(String email, String password, String username) async {
    final resp = await _client.post('/api/auth/mobile-register', {
      'email': email,
      'password': password,
      'username': username,
    });

    final data = Map<String, dynamic>.from(resp as Map);
    final token = data['access_token'] as String?;

    if (token == null || token.isEmpty) {
      return data;
    }

    return _persistSession(data);
  }
}
