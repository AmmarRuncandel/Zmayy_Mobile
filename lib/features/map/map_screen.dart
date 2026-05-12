import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../data/models/visible_user.dart';
import '../../data/models/friend.dart';
import '../../data/repositories/map_repository.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _center;
  LatLng? _currentPosition;
  String? _error;
  bool _requesting = true;
  VisibleUser? _selectedUser;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      // STEP 1: Pengamanan Izin Lokasi (Permissions)
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() { _error = 'Izin lokasi tidak diberikan'; _requesting = false; });
        return;
      }

      // Get initial position
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      if (!mounted) return;

      setState(() {
        _center = LatLng(pos.latitude, pos.longitude);
        _currentPosition = LatLng(pos.latitude, pos.longitude);
        _requesting = false;
      });

      // Capture repositories / state before awaiting to avoid using BuildContext across async gaps
      final appState = Provider.of<ZmayyAppState>(context, listen: false);
      final mapRepo = Provider.of<MapRepository>(context, listen: false);

      await appState.fetchNearbyUsers(pos.latitude, pos.longitude);

      // Tell backend we're enabling map sharing for this session
      // ENDPOINT MUTLAK: POST /api/map/update-location
      try {
        await mapRepo.updateLocation(pos.latitude, pos.longitude);
      } catch (_) {}

      // STEP 2: Aliran Lokasi Real-Time (Position Stream)
      // Start listening to GPS position stream with high accuracy
      _startPositionStream(appState, mapRepo);
    } catch (err) {
      if (mounted) {
        setState(() {
          _error = 'Gagal mengambil lokasi';
          _requesting = false;
        });
      }
    }
  }

  void _startPositionStream(ZmayyAppState appState, MapRepository mapRepo) {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        // STEP 3: Pembaruan Reaktif (State & UI Parity)
        if (!mounted) return;

        final newPosition = LatLng(position.latitude, position.longitude);
        
        setState(() {
          _currentPosition = newPosition;
        });

        // Update nearby users based on new coordinates
        // Use Future.microtask to avoid async gaps
        Future.microtask(() async {
          try {
            await appState.fetchNearbyUsers(position.latitude, position.longitude);
            await mapRepo.updateLocation(position.latitude, position.longitude);
          } catch (_) {
            // Silent fail - don't interrupt user experience
          }
        });
      },
      onError: (error) {
        // Handle stream errors silently
        if (mounted) {
          setState(() {
            _error = 'GPS stream error';
          });
        }
      },
    );
  }

  void recenter() {
    final c = _center;
    if (c != null) {
      _mapController.move(c, 15);
    }
  }

  void panToLocation(double lat, double lng) {
    _mapController.move(LatLng(lat, lng), 16);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ZmayyAppState>(context);
    final isGhost = appState.currentProfile?.isGhostMode ?? false;

    // BUG FIX #2: Merge friends with visible users to show distant friend markers
    final allMarkers = _buildMergedMarkers(appState);

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
              MarkerLayer(markers: allMarkers),
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
          bottom: 92,
          child: _buildBadgeColumn(appState, isGhost),
        ),

        if (_selectedUser != null)
          Positioned(
            top: 16,
            left: 18,
            right: 18,
            child: _buildMarkerPopup(_selectedUser!),
          ),
      ],
    );
  }

  // BUG FIX #2: Merge visible users with friends list to show distant friend markers
  List<Marker> _buildMergedMarkers(ZmayyAppState appState) {
    final markers = <String, Marker>{};
    final currentUserId = appState.currentUserId;

    // Add current user marker (blue dot) if position is available
    if (_currentPosition != null) {
      markers['__current_user__'] = _buildCurrentUserMarker(_currentPosition!);
    }

    // Add visible users (within 1KM from backend)
    for (final user in appState.visibleUsers) {
      if (user.lastLat == null || user.lastLng == null) continue;
      if (user.id == currentUserId) continue; // Filter self-marker
      
      markers[user.id] = _buildMarkerFromVisibleUser(user, currentUserId);
    }

    // Add friends (bypass 1KM limit) - always show golden markers for friends
    for (final friend in appState.friends) {
      if (friend.lastLat == null || friend.lastLng == null) continue;
      if (friend.id == currentUserId) continue; // Filter self-marker
      
      // Only add if not already in visible users (avoid duplicates)
      if (!markers.containsKey(friend.id)) {
        markers[friend.id] = _buildMarkerFromFriend(friend, currentUserId);
      }
    }

    return markers.values.toList();
  }

  Marker _buildCurrentUserMarker(LatLng position) {
    return Marker(
      width: 48,
      height: 48,
      point: position,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF3B82F6),
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x663B82F6),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          Icons.navigation,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  Marker _buildMarkerFromVisibleUser(VisibleUser user, String? currentUserId) {
    final isFriend = user.relationType == 'friend';
    final initials = _initials(user.username ?? '?');

    return Marker(
      width: 48,
      height: 56,
      point: LatLng(user.lastLat ?? 0.0, user.lastLng ?? 0.0),
      builder: (ctx) => GestureDetector(
        onTap: () {
          setState(() {
            _selectedUser = user;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            if (_selectedUser?.id == user.id) {
              setState(() => _selectedUser = null);
            }
          });
        },
        child: _buildMarkerWidget(initials, isFriend, user.isOnline),
      ),
    );
  }

  Marker _buildMarkerFromFriend(Friend friend, String? currentUserId) {
    final initials = _initials(friend.username);
    
    // Convert Friend to VisibleUser for popup display
    final visibleUser = VisibleUser(
      id: friend.id,
      username: friend.username,
      isOnline: friend.isOnline,
      distanceKm: friend.distanceKm ?? 0.0,
      lastLat: friend.lastLat,
      lastLng: friend.lastLng,
      relationType: 'friend',
    );

    return Marker(
      width: 48,
      height: 56,
      point: LatLng(friend.lastLat ?? 0.0, friend.lastLng ?? 0.0),
      builder: (ctx) => GestureDetector(
        onTap: () {
          setState(() {
            _selectedUser = visibleUser;
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (!mounted) return;
            if (_selectedUser?.id == friend.id) {
              setState(() => _selectedUser = null);
            }
          });
        },
        child: _buildMarkerWidget(initials, true, friend.isOnline),
      ),
    );
  }

  Widget _buildMarkerWidget(String initials, bool isFriend, bool isOnline) {
    return Column(
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
                  ? const Color(0xFFFCD535) // Golden marker for friends
                  : const Color(0xFF4B5563), // Gray marker for strangers
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
                  ? const Color(0xFFFCD535) // Golden text for friends
                  : const Color(0xFF9CA3AF), // Gray text for strangers
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        // Online indicator dot
        if (isOnline)
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
    );
  }

  // ── Badge column ───────────────────────────────────────────────────────────
  Widget _buildBadgeColumn(ZmayyAppState appState, bool isGhost) {
    final nearbyUsers = appState.visibleUsers.length;
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
                isGhost ? '— pengguna di sekitar' : '$nearbyUsers pengguna di sekitar',
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

  Widget _buildMarkerPopup(VisibleUser user) {
    final distanceText = user.distanceKm < 1
        ? '${(user.distanceKm * 1000).round()} m'
        : '${user.distanceKm.toStringAsFixed(1)} km';
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF181A20).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2B2F36)),
          boxShadow: const [
            BoxShadow(color: Color(0x22000000), blurRadius: 14),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place_outlined, color: Color(0xFFFCD535), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${user.username ?? 'Pengguna'} · $distanceText',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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
