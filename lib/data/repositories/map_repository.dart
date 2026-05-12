import 'dart:developer' as developer;

import '../../core/api_client.dart';
import '../models/visible_user.dart';

class MapRepository {
  final ApiClient _client = ApiClient();

  Future<List<VisibleUser>> getVisibleUsers(double lat, double lng) async {
    final path = '/api/map/visible?lat=${lat.toString()}&lng=${lng.toString()}';
    final resp = await _client.get(path);

    if (resp == null) {
      // LOGGING KRUSIAL: Empty response
      developer.log('[Map Sync] Ditemukan 0 entitas di sekitar koordinat saat ini', level: 800);
      return <VisibleUser>[];
    }

    // Expecting a JSON array
    final list = resp is List ? resp : (resp is Map && resp['data'] is List ? resp['data'] as List : <dynamic>[]);

    final users = list.map<VisibleUser>((e) {
      if (e is Map<String, dynamic>) return VisibleUser.fromJson(e);
      return VisibleUser.fromJson(Map<String, dynamic>.from(e as Map));
    }).toList();

    // LOGGING KRUSIAL: Log jumlah entitas yang ditemukan
    developer.log('[Map Sync] Ditemukan ${users.length} entitas di sekitar koordinat saat ini', level: 800);

    return users;
  }

  /// Notify backend of current location and enable mapping for this session.
  Future<void> enableMap(double lat, double lng) async {
    await _client.post('/api/map/visible', {
      'lat': lat,
      'lng': lng,
    });
  }
}
