/// Mirrors `utils/supabase/types.ts` → `Profile`.
class Profile {
  const Profile({
    required this.id,
    this.username,
    this.displayName,
    this.avatarInitials,
    this.lastLat,
    this.lastLng,
    this.updatedAt,
    this.isGhostMode,
    this.notificationsEnabled,
    this.isPublic,
    this.notifyGlobal,
    this.notifyRequests,
    this.notifyMessages,
    this.notifySound,
  });

  final String id;
  final String? username;
  final String? displayName;
  final String? avatarInitials;
  final double? lastLat;
  final double? lastLng;
  final String? updatedAt;
  final bool? isGhostMode;
  final bool? notificationsEnabled;
  final bool? isPublic;
  final bool? notifyGlobal;
  final bool? notifyRequests;
  final bool? notifyMessages;
  final bool? notifySound;

  Profile copyWith({
    String? id,
    String? username,
    String? displayName,
    String? avatarInitials,
    double? lastLat,
    double? lastLng,
    String? updatedAt,
    bool? isGhostMode,
    bool? notificationsEnabled,
    bool? isPublic,
    bool? notifyGlobal,
    bool? notifyRequests,
    bool? notifyMessages,
    bool? notifySound,
  }) {
    return Profile(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      lastLat: lastLat ?? this.lastLat,
      lastLng: lastLng ?? this.lastLng,
      updatedAt: updatedAt ?? this.updatedAt,
      isGhostMode: isGhostMode ?? this.isGhostMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isPublic: isPublic ?? this.isPublic,
      notifyGlobal: notifyGlobal ?? this.notifyGlobal,
      notifyRequests: notifyRequests ?? this.notifyRequests,
      notifyMessages: notifyMessages ?? this.notifyMessages,
      notifySound: notifySound ?? this.notifySound,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String?,
      displayName: json['display_name'] as String?,
      avatarInitials: json['avatar_initials'] as String?,
      lastLat: (json['last_lat'] as num?)?.toDouble(),
      lastLng: (json['last_lng'] as num?)?.toDouble(),
      updatedAt: json['updated_at'] as String?,
      isGhostMode: json['is_ghost_mode'] as bool?,
      notificationsEnabled: json['notifications_enabled'] as bool?,
      isPublic: json['is_public'] as bool?,
      notifyGlobal: json['notify_global'] as bool?,
      notifyRequests: json['notify_requests'] as bool?,
      notifyMessages: json['notify_messages'] as bool?,
      notifySound: json['notify_sound'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_initials': avatarInitials,
      'last_lat': lastLat,
      'last_lng': lastLng,
      'updated_at': updatedAt,
      'is_ghost_mode': isGhostMode,
      'notifications_enabled': notificationsEnabled,
      'is_public': isPublic,
      'notify_global': notifyGlobal,
      'notify_requests': notifyRequests,
      'notify_messages': notifyMessages,
      'notify_sound': notifySound,
    };
  }
}
