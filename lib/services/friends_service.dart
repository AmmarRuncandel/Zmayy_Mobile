import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_constants.dart';
import '../data/models/profile.dart';

/// Friend list + search queries mirroring `FriendsPanel.tsx`.
final class FriendsService {
  FriendsService(this._client);

  final SupabaseClient _client;

  static const _profileSelect =
      'id, username, display_name, avatar_initials, last_lat, last_lng, is_ghost_mode';

  Future<FriendsSnapshot> loadFriendsSnapshot({required String currentUserId}) async {
    final accepted = await _client
        .from(SupabaseTables.friendships)
        .select('''
          id, requester_id, addressee_id, status,
          requester:profiles!friendships_requester_id_fkey($_profileSelect),
          addressee:profiles!friendships_addressee_id_fkey($_profileSelect)
        ''')
        .eq('status', 'accepted')
        .or('requester_id.eq.$currentUserId,addressee_id.eq.$currentUserId');

    final pending = await _client
        .from(SupabaseTables.friendships)
        .select('''
          id, requester_id, status,
          requester:profiles!friendships_requester_id_fkey($_profileSelect)
        ''')
        .eq('status', 'pending')
        .eq('addressee_id', currentUserId);

    final friends = <FriendRow>[];
    final seen = <String>{};

    for (final row in (accepted as List<dynamic>? ?? [])) {
      final map = Map<String, dynamic>.from(row as Map);
      final isRequester = map['requester_id'] as String == currentUserId;
      final profileMap = isRequester
          ? map['addressee'] as Map<String, dynamic>?
          : map['requester'] as Map<String, dynamic>?;
      if (profileMap == null) continue;
      final profile = Profile.fromJson(profileMap);
      if (seen.add(profile.id)) {
        friends.add(
          FriendRow(
            friendshipId: map['id'] as String,
            profile: profile,
            isPendingRequest: false,
          ),
        );
      }
    }

    final inboundPending = <FriendRow>[];

    for (final row in (pending as List<dynamic>? ?? [])) {
      final map = Map<String, dynamic>.from(row as Map);
      final req = map['requester'];
      if (req is! Map) continue;
      final profile = Profile.fromJson(Map<String, dynamic>.from(req));
      inboundPending.add(
        FriendRow(
          friendshipId: map['id'] as String,
          profile: profile,
          isPendingRequest: true,
        ),
      );
    }

    return FriendsSnapshot(acceptedFriends: friends, inboundPending: inboundPending);
  }

  /// `.eq('id', uuid)` path — skips username `ilike` (`FriendsPanel.tsx` deep link).
  Future<Profile?> fetchProfileStrictId({
    required String profileId,
    required String excludingUserId,
  }) async {
    final row = await _client
        .from(SupabaseTables.profiles)
        .select(_profileSelect)
        .eq('id', profileId)
        .neq('id', excludingUserId)
        .maybeSingle();
    if (row == null) return null;
    return Profile.fromJson(Map<String, dynamic>.from(row));
  }

  /// Debounced caller supplies trimmed non-uuid query (`ilike`).
  Future<List<Profile>> searchProfilesByUsername({
    required String query,
    required String excludingUserId,
    int limit = 8,
  }) async {
    final rows = await _client
        .from(SupabaseTables.profiles)
        .select(_profileSelect)
        .ilike('username', '%$query%')
        .neq('id', excludingUserId)
        .limit(limit);

    return (rows as List<dynamic>)
        .map((dynamic row) => Profile.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }

  Future<void> sendFriendRequest({
    required String requesterId,
    required String addresseeId,
  }) async {
    await _client.from(SupabaseTables.friendships).insert(<String, dynamic>{
      'requester_id': requesterId,
      'addressee_id': addresseeId,
      'status': 'pending',
    });
  }

  Future<void> acceptFriendRequest(String friendshipId) async {
    await _client.from(SupabaseTables.friendships).update(<String, dynamic>{
      'status': 'accepted',
    }).eq('id', friendshipId);
  }
}

final class FriendRow {
  FriendRow({
    required this.friendshipId,
    required this.profile,
    required this.isPendingRequest,
  });

  final String friendshipId;
  final Profile profile;
  final bool isPendingRequest;
}

final class FriendsSnapshot {
  FriendsSnapshot({
    required this.acceptedFriends,
    required this.inboundPending,
  });

  final List<FriendRow> acceptedFriends;
  final List<FriendRow> inboundPending;
}
