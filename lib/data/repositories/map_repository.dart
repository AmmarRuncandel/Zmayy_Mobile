import '../../core/api_client.dart';
import '../models/visible_user.dart';

class MapRepository {
  final ApiClient _client = ApiClient();

  Future<List<VisibleUser>> getVisibleUsers(double lat, double lng) async {
    final path = '/api/map/visible?lat=${lat.toString()}&lng=${lng.toString()}';
    final resp = await _client.get(path);

    if (resp == null) return <VisibleUser>[];

    // Expecting a JSON array
    final list = resp is List ? resp : (resp is Map && resp['data'] is List ? resp['data'] as List : <dynamic>[]);

    return list.map<VisibleUser>((e) {
      if (e is Map<String, dynamic>) return VisibleUser.fromJson(e);
      return VisibleUser.fromJson(Map<String, dynamic>.from(e as Map));
    }).toList();
  }

  /// Notify backend of current location and enable mapping for this session.
  Future<void> enableMap(double lat, double lng) async {
    await _client.post('/api/map/enable', {
      'lat': lat,
      'lng': lng,
    });
  }
}
