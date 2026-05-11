class VisibleUser {
  final String id;
  final String? username;
  final String? relationType;
  final bool isOnline;
  final double distanceKm;
  final double? lastLat;
  final double? lastLng;
  final String? updatedAt;

  VisibleUser({
    required this.id,
    this.username,
    this.relationType,
    required this.isOnline,
    required this.distanceKm,
    this.lastLat,
    this.lastLng,
    this.updatedAt,
  });

  factory VisibleUser.fromJson(Map<String, dynamic> json) {
    double? parseNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return VisibleUser(
      id: json['id']?.toString() ?? '',
      username: json['username'] as String?,
      relationType: json['relation_type'] as String?,
      isOnline: json['is_online'] == true,
      distanceKm: (json['distance_km'] is num) ? (json['distance_km'] as num).toDouble() : double.tryParse(json['distance_km']?.toString() ?? '') ?? 0.0,
      lastLat: parseNum(json['last_lat']),
      lastLng: parseNum(json['last_lng']),
      updatedAt: json['updated_at'] as String?,
    );
  }
}
