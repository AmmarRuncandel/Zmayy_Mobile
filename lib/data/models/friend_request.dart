class FriendRequest {
  final String requesterId;
  final String username;
  final double? distanceKm;

  const FriendRequest({
    required this.requesterId,
    required this.username,
    this.distanceKm,
  });

  String get subtitle {
    final km = distanceKm;
    if (km == null) return 'Dekat';
    if (km < 0.1) return 'Dekat';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
  }

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    // Accept multiple shapes:
    // - { requester_id, username, distance_km }
    // - { requester: { id, username }, distance_km }
    // - { requester_id, requester_username, distance_km }
    String requesterId = json['requester_id']?.toString() ?? '';
    String? username = json['username']?.toString() ?? json['requester_username']?.toString();

    final requester = json['requester'];
    if (requester is Map) {
      final req = requester is Map<String, dynamic> ? requester : Map<String, dynamic>.from(requester);
      requesterId = requesterId.isNotEmpty ? requesterId : (req['id']?.toString() ?? '');
      username ??= req['username']?.toString() ?? req['display_name']?.toString();
    }

    username ??= '—';
    final distanceKm = _parseDouble(json['distance_km']);

    return FriendRequest(
      requesterId: requesterId,
      username: username,
      distanceKm: distanceKm,
    );
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

