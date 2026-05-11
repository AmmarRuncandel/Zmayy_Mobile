class Friend {
  final String id;
  final String username;
  final bool isOnline;
  final double? distanceKm;

  const Friend({
    required this.id,
    required this.username,
    required this.isOnline,
    this.distanceKm,
  });

  String get subtitle {
    final km = distanceKm;
    if (km == null) return 'Dekat';
    if (km < 0.1) return 'Dekat';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
  }

  factory Friend.fromJson(Map<String, dynamic> json) {
    // Accept multiple shapes:
    // - { id, username, is_online, distance_km }
    // - { friend: { id, username, ... }, is_online, distance_km }
    // - { profile: { id, username, ... }, is_online, distance_km }
    final embedded = _firstMap(json['friend']) ?? _firstMap(json['profile']) ?? const <String, dynamic>{};

    final id = (json['id'] ?? embedded['id'])?.toString() ?? '';
    final username = (json['username'] ??
            embedded['username'] ??
            embedded['display_name'] ??
            embedded['email']?.toString().split('@').first)
        ?.toString() ??
        '—';

    final isOnline = (json['is_online'] ?? embedded['is_online']) == true;
    final distanceKm = _parseDouble(json['distance_km'] ?? embedded['distance_km']);

    return Friend(
      id: id,
      username: username,
      isOnline: isOnline,
      distanceKm: distanceKm,
    );
  }

  static Map<String, dynamic>? _firstMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

