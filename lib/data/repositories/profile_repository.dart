import 'dart:developer' as developer;

import '../../core/api_client.dart';

class ProfileRepository {
  final ApiClient _client = ApiClient();

  ProfileRepository();

  /// Updates profile fields on the server. Returns the updated profile map.
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> payload) async {
    final sanitizedPayload = _sanitizePayload(payload);
    
    // LOGGING KRUSIAL: Log payload yang akan dikirim
    developer.log('[Profile Update] Payload terkirim: $sanitizedPayload', level: 800);
    
    // ENDPOINT MUTLAK: /api/profile/update (PATCH atau POST)
    final resp = await _client.patch('/api/profile/update', sanitizedPayload);
    if (resp == null) return <String, dynamic>{};

    final map = _unwrapStandardJson(resp);
    return _sanitizeProfileMap(map);
  }

  Map<String, dynamic> _sanitizePayload(Map<String, dynamic> payload) {
    final result = Map<String, dynamic>.from(payload);
    if (result.containsKey('notifications_enabled') && result['notifications_enabled'] == null) {
      result['notifications_enabled'] = true;
    }
    return result;
  }

  Map<String, dynamic> _unwrapStandardJson(dynamic resp) {
    if (resp is Map<String, dynamic>) {
      if (resp['data'] is Map) {
        return Map<String, dynamic>.from(resp['data'] as Map);
      }
      if (resp['profile'] is Map) {
        return Map<String, dynamic>.from(resp['profile'] as Map);
      }
      return resp;
    }
    if (resp is Map) {
      final map = Map<String, dynamic>.from(resp);
      if (map['data'] is Map) {
        return Map<String, dynamic>.from(map['data'] as Map);
      }
      if (map['profile'] is Map) {
        return Map<String, dynamic>.from(map['profile'] as Map);
      }
      return map;
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> _sanitizeProfileMap(Map<String, dynamic> profile) {
    final result = Map<String, dynamic>.from(profile);
    if (result['notifications_enabled'] == null) {
      result['notifications_enabled'] = true;
    }
    return result;
  }
}
