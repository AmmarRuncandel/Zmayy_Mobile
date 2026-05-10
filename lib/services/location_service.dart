import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../core/app_constants.dart';

/// Thrown when the user denies location permission permanently.
final class LocationPermissionDeniedException implements Exception {
  LocationPermissionDeniedException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when the device location provider is unavailable or disabled.
final class LocationUnavailableException implements Exception {
  LocationUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Foreground GPS abstraction matching `navigator.geolocation.watchPosition`
/// semantics from `MapViewInner.tsx` (`enableHighAccuracy`, `maximumAge: 5000`,
/// `timeout: 10000`).
///
/// **Platform setup:** callers must declare iOS/Android location permission
/// descriptions in Info.plist / `AndroidManifest.xml` — not handled here.
final class LocationService {
  /// Streaming configuration — mirrored `maximumAge`/continuous intent (no rigid timeout).
  static const LocationSettings _streamSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 5,
  );

  /// Snapshot configuration — embeds **`timeLimit`** to honour the 10 s JSX timeout analogue.
  static final LocationSettings _snapshotSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 5,
    timeLimit: geolocationTimeout,
  );

  Future<bool> isLocationServicesEnabledWithPrompt() =>
      Geolocator.isLocationServiceEnabled();

  /// Returns whether we can legally request fixes (foreground "While In Use").
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  /// Requests foreground access as needed.
  ///
  /// On web the app behaves when permission is permanently denied — we expose
  /// that outcome so [ZmayyAppState] can fall back to the Tasik defaults.
  Future<LocationPermission> requestForegroundPermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm;
  }

  Future<void> ensureServiceEnabledOrThrow() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw LocationUnavailableException(
        'Perangkat mematikan GPS. Aktifkan layanan lokasi untuk memuat peta.',
      );
    }
  }

  /// Single fix with parity timeout — matches `maximumAge` + `timeout` intent.
  Future<Position> getCurrentPosition() async {
    await ensureServiceEnabledOrThrow();

    final perm = await requestForegroundPermission();
    if (perm != LocationPermission.whileInUse &&
        perm != LocationPermission.always) {
      throw LocationPermissionDeniedException(
        perm == LocationPermission.deniedForever
            ? 'Izin lokasi ditolak permanen — buka Pengaturan untuk mengaktifkan.'
            : 'Izin lokasi diperlukan untuk menampilkan posisi Anda di peta.',
      );
    }

    return Geolocator.getCurrentPosition(locationSettings: _snapshotSettings);
  }

  /// Continuous updates for map + Supabase heartbeat.
  ///
  /// Emits typed errors wrapped as [AsyncError]; consumers should use
  /// `listen(..., onError: ...)` similar to silent web `watchPosition`
  /// error callback.
  Stream<Position> watchPositionForeground({
    LocationSettings settings = _streamSettings,
  }) async* {
    await ensureServiceEnabledOrThrow();

    final perm = await requestForegroundPermission();
    if (perm != LocationPermission.whileInUse && perm != LocationPermission.always) {
      yield* Stream.error(
        LocationPermissionDeniedException(
          perm == LocationPermission.deniedForever
              ? 'Izin lokasi ditolak permanen.'
              : 'Izin lokasi diperlukan.',
        ),
      );
      return;
    }

    yield* Geolocator.getPositionStream(locationSettings: settings);
  }
}
