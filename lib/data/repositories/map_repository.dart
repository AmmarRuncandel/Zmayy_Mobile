import 'dart:developer' as developer;

import '../../core/api_client.dart';
import '../models/visible_user.dart';

class MapRepository {
  final ApiClient _client = ApiClient();

  /// ENDPOINT MUTLAK: GET /api/map/visible
  Future<List<VisibleUser>> getVisibleUsers(double lat, double lng) async {
    final path = '/api/map/visible?lat=${lat.toString()}&lng=${lng.toString()}';
    final resp = await _client.get(path);

    if (resp == null) {
      // LOGGING KRUSIAL: Empty response
      developer.log('[Map Sync] Ditemukan 0 entitas di sekitar koordinat saat ini', level: 800);
      return <VisibleUser>[];
    }

    // Defensif JSON extraction - handles various response formats
    final list = _extractList(resp);

    final users = list.map<VisibleUser>((e) {
      if (e is Map<String, dynamic>) return VisibleUser.fromJson(e);
      return VisibleUser.fromJson(Map<String, dynamic>.from(e as Map));
    }).toList();

    // LOGGING KRUSIAL: Log jumlah entitas yang ditemukan
    developer.log('[Map Sync] Ditemukan ${users.length} entitas di sekitar koordinat saat ini', level: 800);

    return users;
  }

  /// ENDPOINT MUTLAK: POST /api/map/update-location
  /// Notify backend of current location and enable mapping for this session.
  Future<void> updateLocation(double lat, double lng) async {
    developer.log('[Map Update] Updating location: lat=$lat, lng=$lng', level: 800);
    await _client.post('/api/map/update-location', {
      'lat': lat,
      'lng': lng,
    });
  }
  
  /// Legacy method name for backward compatibility
  @Deprecated('Use updateLocation instead')
  Future<void> enableMap(double lat, double lng) async {
    await updateLocation(lat, lng);
  }

  /// Defensif JSON extractor - handles various response formats
  List<dynamic> _extractList(dynamic resp) {
    if (resp == null) return <dynamic>[];
    if (resp is List) return resp;
    if (resp is Map) {
      final map = Map<String, dynamic>.from(resp);
      // Try common wrapper keys
      if (map['data'] is List) return map['data'] as List;
      if (map['users'] is List) return map['users'] as List;
      if (map['visible_users'] is List) return map['visible_users'] as List;
      if (map['items'] is List) return map['items'] as List;
    }
    return <dynamic>[];
  }
}
