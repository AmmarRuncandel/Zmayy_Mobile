import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../data/models/visible_user.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _center;
  String? _error;
  bool _requesting = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() { _error = 'Izin lokasi tidak diberikan'; _requesting = false; });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      if (!mounted) return;

      setState(() {
        _center = LatLng(pos.latitude, pos.longitude);
        _requesting = false;
      });

      final appState = Provider.of<ZmayyAppState>(context, listen: false);
      await appState.fetchNearbyUsers(pos.latitude, pos.longitude);
    } catch (err) {
      if (mounted) {
        setState(() {
          _error = 'Gagal mengambil lokasi';
          _requesting = false;
        });
      }
    }
  }

  void recenter() {
    final c = _center;
    if (c != null) {
      _mapController.move(c, 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ZmayyAppState>(context);
    final isGhost = appState.currentProfile?.isGhostMode ?? false;

    return Stack(
      children: [
        // ── Map ──────────────────────────────────────────────────────────────
        if (_center != null)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _center,
              zoom: 15,
              interactiveFlags: InteractiveFlag.all,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                tileProvider: NetworkTileProvider(),
                userAgentPackageName: 'dev.zmayy.app',
              ),
              MarkerLayer(
                markers: appState.visibleUsers
                    .map((u) => _buildMarker(u))
                    .toList(),
              ),
            ],
          )
        else
          Container(
            color: const Color(0xFF0B0E11),
            child: Center(
              child: _requesting
                  ? const CircularProgressIndicator(
                      color: Color(0xFFFCD535), strokeWidth: 2.4)
                  : Text(
                      _error ?? 'Mengambil lokasi...',
                      style: const TextStyle(color: Colors.white70),
                    ),
            ),
          ),

        // ── Bottom-left overlay badges ────────────────────────────────────
        Positioned(
          left: 14,
          bottom: 14,
          child: _buildBadgeColumn(appState, isGhost),
        ),
      ],
    );
  }

  // ── Marker builder ─────────────────────────────────────────────────────────
  Marker _buildMarker(VisibleUser user) {
    final isFriend = user.relationType == 'friend';
    final initials = _initials(user.username ?? '?');

    return Marker(
      width: 48,
      height: 56,
      point: LatLng(user.lastLat ?? 0.0, user.lastLng ?? 0.0),
      builder: (ctx) => GestureDetector(
        onTap: () {
          final dist = (user.distanceKm * 1000).round();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${user.username ?? 'Pengguna'} · ${dist}m'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF181A20),
            duration: const Duration(seconds: 2),
          ));
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isFriend
                    ? const Color(0xFF181A20)
                    : const Color(0xFF111318),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isFriend
                      ? const Color(0xFFFCD535)
                      : const Color(0xFF4B5563),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isFriend
                        ? const Color(0x72FCD535)
                        : const Color(0x4C4B5563),
                    blurRadius: 12,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  color: isFriend
                      ? const Color(0xFFFCD535)
                      : const Color(0xFF9CA3AF),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // Online indicator dot
            if (user.isOnline)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Badge column ───────────────────────────────────────────────────────────
  Widget _buildBadgeColumn(ZmayyAppState appState, bool isGhost) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E11).withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: nearby strangers
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people_outline,
                  color: Color(0xFFD1D5DB), size: 14),
              const SizedBox(width: 6),
              Text(
                isGhost ? '—' : '${appState.nearbyStrangersCount} pengguna di sekitar',
                style: const TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 2: online friends (gold)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.people,
                  color: Color(0xFFFCD535), size: 14),
              const SizedBox(width: 6),
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 5),
                decoration: const BoxDecoration(
                    color: Color(0xFF22C55E), shape: BoxShape.circle),
              ),
              Text(
                isGhost ? '—' : '${appState.onlineFriendsCount} teman online',
                style: const TextStyle(
                    color: Color(0xFFFCD535),
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return t.length >= 2 ? t.substring(0, 2).toUpperCase() : t[0].toUpperCase();
  }
}
