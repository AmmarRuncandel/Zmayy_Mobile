import 'profile.dart';

/// Mirrors `utils/supabase/types.ts` → `FriendshipStatus`.
typedef FriendshipStatusWire = String;

abstract final class FriendshipStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
}

/// Mirrors `utils/supabase/types.ts` → `Friendship`.
class Friendship {
  const Friendship({
    required this.id,
    required this.requesterId,
    required this.addresseeId,
    required this.status,
    required this.createdAt,
    this.friendProfile,
  });

  final String id;
  final String requesterId;
  final String addresseeId;
  final FriendshipStatusWire status;
  final String createdAt;
  final Profile? friendProfile;

  Friendship copyWith({
    String? id,
    String? requesterId,
    String? addresseeId,
    FriendshipStatusWire? status,
    String? createdAt,
    Profile? friendProfile,
  }) {
    return Friendship(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      addresseeId: addresseeId ?? this.addresseeId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      friendProfile: friendProfile ?? this.friendProfile,
    );
  }

  factory Friendship.fromJson(
    Map<String, dynamic> json, {
    Profile? resolvedFriendProfile,
  }) {
    return Friendship(
      id: json['id'] as String,
      requesterId: json['requester_id'] as String,
      addresseeId: json['addressee_id'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      friendProfile:
          resolvedFriendProfile ??
          (json['friend_profile'] is Map<String, dynamic>
              ? Profile.fromJson(json['friend_profile'] as Map<String, dynamic>)
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    final friend = friendProfile;
    return <String, dynamic>{
      'id': id,
      'requester_id': requesterId,
      'addressee_id': addresseeId,
      'status': status,
      'created_at': createdAt,
      if (friend != null) 'friend_profile': friend.toJson(),
    };
  }
}
