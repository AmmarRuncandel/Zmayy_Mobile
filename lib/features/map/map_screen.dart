import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/app_constants.dart';
import '../../core/app_state.dart';
import '../../core/map_style_constants.dart';
import '../../core/zmayy_colors.dart';
import '../../data/models/visible_user.dart';
import '../../widgets/custom_badges.dart';

/// Flutter parity for **`MapViewInner.tsx`** (Carto tiles, leaflet-like markers, controls).
final class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final MapController _controller = MapController();
  late final AnimationController _recenterPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final Animation<double> _recenterScale = CurvedAnimation(
    parent: _recenterPulse,
    curve: Curves.elasticOut,
  );

  int _appliedFlightGeneration = -(1 << 30);
  VoidCallback? _detachFlightListener;
  int _tileErrors = 0;
  String? _lastTileIssue;

  @override
  void initState() {
    super.initState();
    final app = context.read<ZmayyAppState>();
    void pulseListener() => _considerFlightCue(app.flightEpoch, app.flightLatitude, app.flightLongitude);
    app.addListener(pulseListener);
    _detachFlightListener = () => app.removeListener(pulseListener);

    WidgetsBinding.instance.addPostFrameCallback((_) => pulseListener());
  }

  @override
  void dispose() {
    _detachFlightListener?.call();
    _recenterPulse.dispose();
    super.dispose();
  }

  Future<void> _considerFlightCue(int epoch, double? lat, double? lng) async {
    if (!mounted || lat == null || lng == null || epoch <= _appliedFlightGeneration) return;
    _appliedFlightGeneration = epoch;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    _controller.move(LatLng(lat, lng), flyToFriendZoom);
  }

  Future<void> _recenterToDevice(BuildContext scaffoldContext) async {
    final app = scaffoldContext.read<ZmayyAppState>();
    if (app.badgesMaskedForGhostMode) return;

    await _recenterPulse.forward(from: 0);
    await _recenterPulse.reverse(from: _recenterPulse.value);
    if (!mounted || !scaffoldContext.mounted) return;
    final next = LatLng(app.deviceLatitude ?? defaultMapLat, app.deviceLongitude ?? defaultMapLng);
    _controller.move(next, defaultMapZoom);
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 24;

    return Consumer<ZmayyAppState>(
      builder: (BuildContext scaffoldContext, ZmayyAppState app, _) {
        final ghost = app.badgesMaskedForGhostMode;
        final anchor = LatLng(app.deviceLatitude ?? defaultMapLat, app.deviceLongitude ?? defaultMapLng);
        final urlTemplate =
            MapTiles.cartoDarkMatterTemplate.replaceAll('{r}', '');
        const fallbackTemplate = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';

        final layerMarkers = <Marker>[
          if (!ghost)
            Marker(
              point: anchor,
              alignment: Alignment.center,
              rotate: false,
              width: 42,
              height: 54,
              child: const CurrentUserGoldenMarker(),
            ),
          ...app.visibleUsers.map(
            (VisibleUser peer) => Marker(
              point: LatLng(peer.lastLat, peer.lastLng),
              alignment: Alignment.center,
              rotate: false,
              width: 48,
              height: 56,
              child: PeerBubbleMarker(
                initials: AvatarInitialFormatter.forVisibleUser(peer.avatarInitials, peer.username),
                friend: resolveIsFriend(peer),
              ),
            ),
          ),
        ];

        return Stack(
          children: <Widget>[
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [ZmayyColors.base, ZmayyColors.slate950],
                  ),
                ),
              ),
            ),
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: anchor,
                initialZoom: defaultMapZoom,
                minZoom: 3,
                maxZoom: 19,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: <Widget>[
                TileLayer(
                  urlTemplate: urlTemplate,
                  fallbackUrl: fallbackTemplate,
                  subdomains: const <String>['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'dev.zmayy.mobile',
                  errorTileCallback: (TileImage tile, Object error, StackTrace? stackTrace) {
                    if (!mounted) return;
                    final msg = error.toString();
                    if (msg.contains('SocketException') || msg.contains('Connection reset by peer')) {
                      setState(() {
                        _tileErrors += 1;
                        _lastTileIssue = 'Jaringan peta tidak stabil. Menampilkan fallback tile.';
                      });
                      return;
                    }
                    setState(() {
                      _tileErrors += 1;
                      _lastTileIssue = 'Tile gagal dimuat, mencoba sumber alternatif.';
                    });
                  },
                  evictErrorTileStrategy: EvictErrorTileStrategy.notVisibleRespectMargin,
                ),
                SimpleAttributionWidget(
                  alignment: Alignment.bottomRight,
                  backgroundColor: ZmayyColors.attributionPill.withAlpha(217),
                  source: Text(
                    '© OpenStreetMap · CARTO',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: ZmayyColors.gold),
                  ),
                ),
                MarkerLayer(markers: layerMarkers),
              ],
            ),

            SpatialBadgeTray(bottomInset: inset),

            if (_tileErrors > 0)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 10,
                left: 16,
                right: 80,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: _tileErrors > 0 ? 1 : 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ZmayyColors.glassFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ZmayyColors.border),
                    ),
                    child: Text(
                      _lastTileIssue ?? 'Sumber peta alternatif aktif.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: ZmayyColors.muted),
                    ),
                  ),
                ),
              ),

            Positioned(
              top: MediaQuery.paddingOf(context).top + 10,
              right: 22,
              child: Column(
                children: <Widget>[
                  FrostedGlassIconButton(
                    icon: Icons.add_rounded,
                    press:
                        () => _controller.move(_controller.camera.center, _controller.camera.zoom + 1),
                  ),
                  const SizedBox(height: 10),
                  FrostedGlassIconButton(
                    icon: Icons.remove_rounded,
                    press:
                        () => _controller.move(_controller.camera.center, _controller.camera.zoom - 1),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: inset,
              right: 26,
              child: ScaleTransition(
                scale: _recenterScale,
                child: FloatingActionButton(
                  elevation: ghost ? 0 : 6,
                  heroTag: 'fab_map_reanchor',
                  backgroundColor: ghost ? ZmayyColors.surface : ZmayyColors.gold,
                  foregroundColor: ghost ? ZmayyColors.muted : ZmayyColors.base,
                  onPressed: ghost ? null : () => _recenterToDevice(scaffoldContext),
                  child: const Icon(Icons.navigation_rounded),
                ),
              ),
            ),

            IgnorePointer(
              ignoring: !ghost,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: ghost ? 1 : 0,
                child: Container(color: const Color.fromRGBO(11, 14, 17, .35)),
              ),
            ),
          ],
        );
      },
    );
  }
}

final class AvatarInitialFormatter {
  static String forVisibleUser(String? avatarInitials, String? username) {
    final a = avatarInitials?.trim();
    if (a != null && a.isNotEmpty) {
      final u = a.toUpperCase();
      return u.length >= 2 ? u.substring(0, 2) : u.padRight(2, '?');
    }
    final n = username?.trim();
    if (n != null && n.isNotEmpty) {
      final u = n.toUpperCase();
      return u.length >= 2 ? u.substring(0, 2) : u.padRight(2, '?');
    }
    return '??';
  }
}

class FrostedGlassIconButton extends StatelessWidget {
  const FrostedGlassIconButton({super.key, required this.icon, required this.press});

  final IconData icon;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: press,
        child: Ink(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: ZmayyColors.glassFill.withAlpha(215),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: ZmayyColors.border),
            boxShadow: [
              BoxShadow(color: const Color(0xFFFCD535).withAlpha(20), blurRadius: 16, spreadRadius: 1),
            ],
          ),
          child: Icon(icon, size: 19.5, color: ZmayyColors.primaryText.withAlpha(222)),
        ),
      ),
    );
  }
}

class PeerBubbleMarker extends StatelessWidget {
  const PeerBubbleMarker({super.key, required this.initials, required this.friend});

  final String initials;
  final bool friend;

  @override
  Widget build(BuildContext context) {
    final Color ring = friend ? ZmayyColors.gold : ZmayyColors.strangerStroke;
    final Color fill = friend ? ZmayyColors.surface : ZmayyColors.strangerFill;
    final Color text = friend ? ZmayyColors.gold : ZmayyColors.strangerInitials;

    return SizedBox(
      width: 44,
      height: friend ? 54 : 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: Border.all(color: ring, width: 2),
                boxShadow: [
                  BoxShadow(color: ring.withAlpha(110), blurRadius: 13, spreadRadius: 2),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: text),
              ),
            ),
          ),
          if (friend)
            Align(
              alignment: const Alignment(0.92, -0.18),
              child: DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(width: 1.8, color: ZmayyColors.surface)),
                child: const CircleAvatar(backgroundColor: ZmayyColors.statusOnlineMap, radius: 6),
              ),
            ),
        ],
      ),
    );
  }
}

class CurrentUserGoldenMarker extends StatelessWidget {
  const CurrentUserGoldenMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 56,
      child: Stack(
        alignment: Alignment.topCenter,
        children: const <Widget>[
          Positioned(
            top: 0,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: ZmayyColors.base,
              child: Padding(
                padding: EdgeInsets.all(2),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: ZmayyColors.gold,
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: CircleAvatar(backgroundColor: ZmayyColors.base, radius: 10),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            child: SizedBox.square(dimension: 8, child: CircleAvatar(backgroundColor: ZmayyColors.gold)),
          ),
          Positioned(
            bottom: 2,
            child: SizedBox(
              height: 6,
              width: 22,
              child: DecoratedBox(
                decoration: BoxDecoration(boxShadow: [
                  BoxShadow(color: Colors.black54, blurRadius: 14, spreadRadius: 8),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
