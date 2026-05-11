import '../../core/api_client.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';

class FriendsRepository {
  final ApiClient _client = ApiClient();

  Future<List<Friend>> getFriends() async {
    final resp = await _client.get('/api/friends');
    if (resp == null) return <Friend>[];

    final list = resp is List ? resp : (resp is Map && resp['data'] is List ? resp['data'] as List : <dynamic>[]);
    return list.map<Friend>((e) {
      final map = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map);
      return Friend.fromJson(map);
    }).toList(growable: false);
  }

  Future<List<FriendRequest>> getFriendRequests() async {
    final resp = await _client.get('/api/friends/requests');
    if (resp == null) return <FriendRequest>[];

    final list = resp is List ? resp : (resp is Map && resp['data'] is List ? resp['data'] as List : <dynamic>[]);
    return list.map<FriendRequest>((e) {
      final map = e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map);
      return FriendRequest.fromJson(map);
    }).toList(growable: false);
  }

  Future<void> acceptFriendRequest(String requesterId) async {
    await _client.post('/api/friends/accept', {'requester_id': requesterId});
  }
}

