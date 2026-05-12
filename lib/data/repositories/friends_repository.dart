import 'dart:developer' as developer;

import '../../core/api_client.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';

class FriendsRepository {
  final ApiClient _client = ApiClient();

  /// ENDPOINT MUTLAK: GET /api/friends
  Future<List<Friend>> getFriends() async {
    final resp = await _client.get('/api/friends');
    final list = _extractList(resp, const ['data', 'friends', 'items']);
    
    developer.log('[Friends Sync] Ditemukan ${list.length} teman', level: 800);
    
    return list.map<Friend>((e) {
      final map = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map);
      return Friend.fromJson(map);
    }).toList(growable: false);
  }

  /// ENDPOINT MUTLAK: GET /api/friends/requests
  Future<List<FriendRequest>> getFriendRequests() async {
    final resp = await _client.get('/api/friends/requests');
    final list = _extractList(resp, const ['data', 'requests', 'items']);
    
    developer.log('[Friend Requests Sync] Ditemukan ${list.length} permintaan', level: 800);
    
    return list.map<FriendRequest>((e) {
      final map = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map);
      return FriendRequest.fromJson(map);
    }).toList(growable: false);
  }

  /// ENDPOINT MUTLAK: POST /api/friends/accept
  Future<void> acceptFriendRequest(String requesterId) async {
    developer.log('[Friend Request] Accepting request from: $requesterId', level: 800);
    await _client.post('/api/friends/accept', {'requester_id': requesterId});
  }

  /// Defensif JSON extractor - handles various response formats
  List<dynamic> _extractList(dynamic resp, List<String> preferredKeys) {
    if (resp == null) return <dynamic>[];
    if (resp is List) return resp;
    if (resp is Map) {
      final map = Map<String, dynamic>.from(resp);
      for (final key in preferredKeys) {
        final value = map[key];
        if (value is List) return value;
      }
      // Fallback: return empty list instead of throwing
      return <dynamic>[];
    }
    return <dynamic>[];
  }
}