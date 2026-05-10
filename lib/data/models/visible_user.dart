/// Discriminator literals returned inside `relation_type`
/// (`utils/supabase/types.ts` VisibleUser typedef).
abstract final class VisibleUserRelationType {
  static const String friend = 'friend';
  static const String stranger = 'stranger';
}

/// Mirrors `utils/supabase/types.ts` → `VisibleUser`
/// (“Row returned by the get_visible_users RPC”).
class VisibleUser {
  const VisibleUser({
    required this.id,
    this.username,
    this.displayName,
    this.avatarInitials,
    required this.lastLat,
    required this.lastLng,
    this.updatedAt,
    required this.relationType,
    this.isFriend,
  });

  final String id;
  final String? username;
  final String? displayName;
  final String? avatarInitials;
  final double lastLat;
  final double lastLng;
  final String? updatedAt;

  /// Raw RPC outputs are exactly `'friend'` or `'stranger'` per TS.
  final String relationType;

  /// Optional explicit flag echoed by older RPC payloads.
  final bool? isFriend;

  factory VisibleUser.fromJson(Map<String, dynamic> json) {
    return VisibleUser(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarInitials: json['avatar_initials'] as String?,
      lastLat: (json['last_lat'] as num).toDouble(),
      lastLng: (json['last_lng'] as num).toDouble(),
      updatedAt: json['updated_at'] as String?,
      relationType: json['relation_type'] as String,
      isFriend: json['is_friend'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'username': username,
    'display_name': displayName,
    'avatar_initials': avatarInitials,
    'last_lat': lastLat,
    'last_lng': lastLng,
    'updated_at': updatedAt,
    'relation_type': relationType,
    if (isFriend != null) 'is_friend': isFriend,
  };
}

/// Canonical helper — lifted verbatim from `MapViewInner.tsx` (`resolveIsFriend`).
bool resolveIsFriend(VisibleUser u) {
  if (u.relationType == VisibleUserRelationType.friend) return true;
  if (u.relationType == VisibleUserRelationType.stranger) return false;
  return u.isFriend == true;
}
