import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_constants.dart';
import '../data/models/visible_user.dart';

/// Stateless wrapper around [`SupabaseRpc.getVisibleUsers`] as used by
/// `MapViewInner.tsx`.
final class MapService {
  MapService(this._client);

  final SupabaseClient _client;

  /// Calls `get_visible_users` mirroring `{ caller_id, user_lat, user_lng }`.
  ///
  /// Invalid rows lacking coordinates are discarded — same `.filter(...)` guard
  /// as the React map.
  Future<List<VisibleUser>> fetchVisibleUsers({
    required String callerId,
    double? latitude,
    double? longitude,
  }) async {
    final lat = latitude ?? defaultMapLat;
    final lng = longitude ?? defaultMapLng;

    final dynamic boxed = await _client.rpc(
      SupabaseRpc.getVisibleUsers,
      params: <String, dynamic>{
        'caller_id': callerId,
        'user_lat': lat,
        'user_lng': lng,
      },
    );

    final List<dynamic> rows = boxed is List ? List<dynamic>.from(boxed) : <dynamic>[];

    final result = <VisibleUser>[];

    for (final row in rows) {
      if (row is! Map) continue;
      final map = Map<String, dynamic>.from(row);
      try {
        if (map['last_lat'] == null || map['last_lng'] == null) continue;
        result.add(VisibleUser.fromJson(map));
      } catch (_) {
        continue;
      }
    }

    return result;
  }
}
