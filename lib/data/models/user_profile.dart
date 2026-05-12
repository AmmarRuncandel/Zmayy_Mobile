class UserProfile {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarInitials;
  final String email;
  final bool isGhostMode;
  final bool isPublic;
  final bool notifyGlobal;
  final bool notifyRequests;
  final bool notifyMessages;
  final bool notifySound;
  final bool notificationsEnabled;

  const UserProfile({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarInitials,
    required this.email,
    this.isGhostMode = false,
    this.isPublic = true,
    this.notifyGlobal = true,
    this.notifyRequests = true,
    this.notifyMessages = true,
    this.notifySound = true,
    this.notificationsEnabled = true,
  });

  /// Returns display name if available, otherwise username
  String get effectiveName => displayName ?? username;

  /// Returns 2-letter initials from avatar_initials (backend) or computed from username.
  String get initials {
    // Prioritas: gunakan avatar_initials dari backend jika tersedia
    if (avatarInitials != null && avatarInitials!.isNotEmpty) {
      return avatarInitials!.toUpperCase();
    }
    
    // Fallback: compute dari username
    final t = username.trim();
    if (t.isEmpty) return 'ZM';
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return t.length >= 2 ? t.substring(0, 2).toUpperCase() : t[0].toUpperCase();
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final raw = json['username']?.toString() ??
        json['email']?.toString().split('@').first ??
        'Pengguna';
    return UserProfile(
      id: json['id']?.toString() ?? '',
      username: raw,
      displayName: json['display_name']?.toString(),
      avatarInitials: json['avatar_initials']?.toString(),
      email: json['email']?.toString() ?? '',
      isGhostMode: json['is_ghost_mode'] == true,
      isPublic: json['is_public'] != false,
      notifyGlobal: json['notify_global'] != false,
      notifyRequests: json['notify_requests'] != false,
      notifyMessages: json['notify_messages'] != false,
      notifySound: json['notify_sound'] != false,
      notificationsEnabled: json['notifications_enabled'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'display_name': displayName,
        'avatar_initials': avatarInitials,
        'email': email,
        'is_ghost_mode': isGhostMode,
        'is_public': isPublic,
        'notify_global': notifyGlobal,
        'notify_requests': notifyRequests,
        'notify_messages': notifyMessages,
        'notify_sound': notifySound,
        'notifications_enabled': notificationsEnabled,
      };

  UserProfile copyWith({
    String? username,
    String? displayName,
    String? avatarInitials,
    String? email,
    bool? isGhostMode,
    bool? isPublic,
    bool? notifyGlobal,
    bool? notifyRequests,
    bool? notifyMessages,
    bool? notifySound,
    bool? notificationsEnabled,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarInitials: avatarInitials ?? this.avatarInitials,
      email: email ?? this.email,
      isGhostMode: isGhostMode ?? this.isGhostMode,
      isPublic: isPublic ?? this.isPublic,
      notifyGlobal: notifyGlobal ?? this.notifyGlobal,
      notifyRequests: notifyRequests ?? this.notifyRequests,
      notifyMessages: notifyMessages ?? this.notifyMessages,
      notifySound: notifySound ?? this.notifySound,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
