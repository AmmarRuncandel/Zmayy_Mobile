import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/message.dart';
import '../data/models/profile.dart';
import '../data/models/visible_user.dart';
import '../services/chat_service.dart';
import '../services/location_service.dart';
import '../services/map_service.dart';
import '../services/user_service.dart';
import 'app_constants.dart';
import 'micro_sound.dart';

/// Central reactive coordinator — wired through `ChangeNotifierProvider<ZmayyAppState>` in [`main.dart`].
final class ZmayyAppState extends ChangeNotifier {
  ZmayyAppState({
    required LocationService locationService,
    required MapService mapService,
    required ChatService chatService,
    required UserService userService,
    SupabaseClient? supabaseOverride,
  }) : _locationService = locationService,
       _mapService = mapService,
       _chatService = chatService,
       _userService = userService,
       _supabase = supabaseOverride;

  factory ZmayyAppState.standard() {
    final client = Supabase.instance.client;
    return ZmayyAppState(
      locationService: LocationService(),
      mapService: MapService(client),
      chatService: ChatService(client),
      userService: UserService(client),
      supabaseOverride: client,
    );
  }

  final LocationService _locationService;
  final MapService _mapService;
  final ChatService _chatService;
  final UserService _userService;
  final SupabaseClient? _supabase;

  SupabaseClient get _client => _supabase ?? Supabase.instance.client;

  StreamSubscription<Position>? _positionSub;
  Timer? _mapPollTimer;
  Timer? _ephemeralUiTicker;

  String? _sessionUserId;

  List<VisibleUser> _visibleUsers = <VisibleUser>[];
  bool _ghostMode = false;
  double? _latestLatitude;
  double? _latestLongitude;

  List<Message> _chatRetentionAscending = const <Message>[];
  String? _activePeerId;

  PeerChatRealtimeSession? _chatRealtime;

  Profile? _profile;
  bool _chatDrawerVisible = false;

  int _flightEpoch = -1;
  double? _flightLat;
  double? _flightLng;

  Profile? get currentProfile => _profile;

  /// Mirrors authenticated Supabase **`auth`** subject id for ephemeral UI branching.
  String? get authenticatedUserId => _sessionUserId;

  /// Live flight command — incremented whenever [`requestFlyToProfileId`] succeeds.
  int get flightEpoch => _flightEpoch;

  double? get flightLatitude => _flightLat;

  double? get flightLongitude => _flightLng;

  List<VisibleUser> get visibleUsers =>
      List<VisibleUser>.unmodifiable(_visibleUsers);

  /// [`MapViewInner.tsx`] bottom-left gauges derived via [`resolveIsFriend`].
  int get nearbyStrangersCount =>
      _visibleUsers.where((VisibleUser candidate) => !resolveIsFriend(candidate)).length;

  int get onlineFriendsCount =>
      _visibleUsers.where((VisibleUser candidate) => resolveIsFriend(candidate)).length;

  bool get badgesMaskedForGhostMode => _ghostMode;

  double? get deviceLatitude => _latestLatitude;

  double? get deviceLongitude => _latestLongitude;

  /// Raw ascending buffer respecting **≤10** payloads (`ChatPanel.tsx`).
  List<Message> get ephemeralRingBufferAscending =>
      List<Message>.unmodifiable(_chatRetentionAscending);

  List<Message> get visibleChatTimeline => EphemeralConversationLogic.visibleForTimeline(
        _chatRetentionAscending,
        DateTime.now(),
      );

  int get ephemeralRingSlotsUsed =>
      EphemeralConversationLogic.ringUsedCount(_chatRetentionAscending);

  String? get activeConversationPeerId => _activePeerId;

  Future<void> refreshCurrentProfile() async {
    final userId = _sessionUserId;
    if (userId == null) return;
    try {
      _profile = await _userService.fetchProfileByUuid(userId);
      final remoteGhost = _profile?.isGhostMode ?? false;
      if (remoteGhost != _ghostMode) {
        _syncGhostLocally(remoteGhost);
      } else {
        notifyListeners();
      }
    } catch (error, stack) {
      if (kDebugMode) debugPrint('$error\n$stack');
    }
  }

  Future<void> commitGhostPreference({required bool nextGhostEnabled}) async {
    final uid = _sessionUserId;
    if (uid == null) return;
    await _userService.setGhostProfileState(profileId: uid, ghostEnabled: nextGhostEnabled);
    _syncGhostLocally(nextGhostEnabled);
    await refreshCurrentProfile();
  }

  void _syncGhostLocally(bool enabled) {
    final wasGhost = _ghostMode;
    _ghostMode = enabled;

    if (enabled && !wasGhost) {
      _pauseGeolocationPump();
      notifyListeners();
    } else if (!enabled && wasGhost) {
      unawaited(_resumeSpatialStack());
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  void registerChatDrawerVisibility(bool open) {
    if (_chatDrawerVisible == open) return;
    _chatDrawerVisible = open;
    notifyListeners();
  }

  /// Centres on a visible [`VisibleUser`] if present (`MapViewInner.tsx` `focusProfileId` parity).
  void requestFlyToProfileId(String profileId) {
    VisibleUser? match;
    for (final VisibleUser candidate in _visibleUsers) {
      if (candidate.id == profileId) match = candidate;
    }
    if (match == null) return;

    _flightLat = match.lastLat;
    _flightLng = match.lastLng;
    _flightEpoch++;
    notifyListeners();
  }

  Future<void> openConversation({required String peerId}) async {
    final viewer = _sessionUserId;
    if (viewer == null) {
      throw StateError('Session user unattached.');
    }

    await _disposeChatRealtimeQuietly();

    _activePeerId = peerId;

    try {
      _chatRetentionAscending = await _chatService.loadConversationTail(
        viewerId: viewer,
        peerId: peerId,
      );
    } catch (error, stack) {
      if (kDebugMode) debugPrint('$error\n$stack');
      _chatRetentionAscending = const <Message>[];
      rethrow;
    }

    _chatRealtime = _chatService.subscribeIncomingPartnerInserts(
      viewerId: viewer,
      peerId: peerId,
      onInsert: _capturePartnerInsertStrict,
    );

    _startEphemeralTicker();
    notifyListeners();
  }

  Future<void> closeConversation() async {
    await _disposeChatRealtimeQuietly();
    _chatRetentionAscending = const <Message>[];
    _activePeerId = null;
    _disposeEphemeralTicker();
    notifyListeners();
  }

  void _capturePartnerInsertStrict(Message inbound) {
    if (_chatRetentionAscending.any((Message row) => row.id == inbound.id)) return;

    final merged = [..._chatRetentionAscending, inbound];
    _chatRetentionAscending = EphemeralConversationLogic.applyTenMessageRetention(merged);

    final allowSound = _profile?.notifySound ?? true;
    if (_chatDrawerVisible && allowSound) {
      unawaited(MicroSounds.playIncomingMessage());
    }
    notifyListeners();
  }

  Future<void> sendChatText(String raw) async {
    final text = raw.trim();
    final viewer = _sessionUserId;
    final peer = _activePeerId;
    if (text.isEmpty || viewer == null || peer == null) return;

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final tempId = 'opt-${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = Message(
      id: tempId,
      senderId: viewer,
      receiverId: peer,
      content: text,
      createdAt: nowIso,
    );

    _chatRetentionAscending = EphemeralConversationLogic.applyTenMessageRetention(
      [..._chatRetentionAscending, optimistic],
    );
    notifyListeners();

    final allowSendSound = _profile?.notifySound ?? true;
    if (allowSendSound) {
      unawaited(MicroSounds.playSendTap());
    }

    try {
      await _client.from(SupabaseTables.messages).insert(<String, dynamic>{
        'sender_id': viewer,
        'receiver_id': peer,
        'content': text,
      });
    } catch (error, stack) {
      if (kDebugMode) debugPrint('$error\n$stack');
      _chatRetentionAscending =
          _chatRetentionAscending.where((Message row) => row.id != tempId).toList();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendChatImageFromFile(File file) async {
    final viewer = _sessionUserId;
    final peer = _activePeerId;
    if (viewer == null || peer == null) return;

    final safeName =
        '${DateTime.now().millisecondsSinceEpoch}-${file.uri.pathSegments.isNotEmpty ? file.uri.pathSegments.last : 'image.jpg'}'.replaceAll(
          RegExp(r'[^a-zA-Z0-9.\-_]'),
          '_',
        );
    final remotePath = 'chat_uploads/$viewer/$safeName';

    await _client.storage.from(SupabaseStorageBuckets.chatImages).upload(
          remotePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600'),
        );

    final publicUrl = _client.storage.from(SupabaseStorageBuckets.chatImages).getPublicUrl(remotePath);

    await sendPreparedContent('[IMAGE]:$publicUrl');
  }

  Future<void> sendPreparedContent(String content) async {
    final viewer = _sessionUserId;
    final peer = _activePeerId;
    if (viewer == null || peer == null) return;

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final tempId = 'opt-${DateTime.now().millisecondsSinceEpoch}';

    final optimistic = Message(
      id: tempId,
      senderId: viewer,
      receiverId: peer,
      content: content,
      createdAt: nowIso,
    );

    _chatRetentionAscending = EphemeralConversationLogic.applyTenMessageRetention(
      [..._chatRetentionAscending, optimistic],
    );
    notifyListeners();

    if (_profile?.notifySound ?? true) {
      unawaited(MicroSounds.playSendTap());
    }

    try {
      await _client.from(SupabaseTables.messages).insert(<String, dynamic>{
        'sender_id': viewer,
        'receiver_id': peer,
        'content': content,
      });
    } catch (error, stack) {
      if (kDebugMode) debugPrint('$error\n$stack');
      _chatRetentionAscending =
          _chatRetentionAscending.where((Message row) => row.id != tempId).toList();
      notifyListeners();
      rethrow;
    }
  }

  void attachAuthenticatedUser(String userId) {
    assert(userId.isNotEmpty, 'userId required');
    _sessionUserId = userId;
  }

  Future<void> startSpatialTracking() async {
    if (_sessionUserId == null) {
      throw StateError('Call attachAuthenticatedUser before startSpatialTracking().');
    }

    if (_ghostMode) {
      _latestLatitude ??= defaultMapLat;
      _latestLongitude ??= defaultMapLng;
      notifyListeners();
    } else {
      await _hydrateBaselineFix();
    }

    unawaited(refreshVisibleUsersQuietly());
    _startMapTicker();
    if (!_ghostMode) _resumeGeolocationPump();
  }

  Future<void> stopSpatialTracking() async {
    _pauseGeolocationPump();
    _disposeMapTicker();
  }

  Future<void> refreshVisibleUsersQuietly() async {
    final userId = _sessionUserId;
    if (userId == null) return;

    final lat = (_latestLatitude ?? defaultMapLat);
    final lng = (_latestLongitude ?? defaultMapLng);

    try {
      final snapshot = await _mapService.fetchVisibleUsers(
        callerId: userId,
        latitude: lat,
        longitude: lng,
      );
      _visibleUsers = snapshot;
      notifyListeners();
    } catch (error, stack) {
      if (kDebugMode) debugPrint('$error\n$stack');
    }
  }

  Future<void> _hydrateBaselineFix() async {
    try {
      final Position fix = await _locationService.getCurrentPosition();
      _latestLatitude = fix.latitude;
      _latestLongitude = fix.longitude;

      await _maybePublishDeviceFix(fix.latitude, fix.longitude);
    } on LocationPermissionDeniedException catch (error, stack) {
      if (kDebugMode) debugPrint('$error\n$stack');
      _latestLatitude ??= defaultMapLat;
      _latestLongitude ??= defaultMapLng;
      notifyListeners();
    } catch (error, stack) {
      if (kDebugMode) debugPrint('$error\n$stack');
      _latestLatitude ??= defaultMapLat;
      _latestLongitude ??= defaultMapLng;
      notifyListeners();
    }
  }

  Future<void> _resumeSpatialStack() async {
    await _hydrateBaselineFix();
    unawaited(refreshVisibleUsersQuietly());
    _startMapTicker();
    _resumeGeolocationPump();
  }

  void _resumeGeolocationPump() {
    if (_ghostMode) return;
    if (_sessionUserId == null) return;

    _positionSub?.cancel();
    _positionSub = _locationService.watchPositionForeground().listen(
      _handleIncomingPosition,
      onError: (Object error, StackTrace stack) {
        if (kDebugMode) debugPrint('[location stream] $error\n$stack');
      },
    );
  }

  void _pauseGeolocationPump() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  Future<void> _handleIncomingPosition(Position snapshot) async {
    if (_ghostMode || _sessionUserId == null) return;

    _latestLatitude = snapshot.latitude;
    _latestLongitude = snapshot.longitude;
    notifyListeners();

    await _maybePublishDeviceFix(snapshot.latitude, snapshot.longitude);
  }

  Future<void> _maybePublishDeviceFix(double lat, double lng) async {
    final userId = _sessionUserId;
    if (userId == null) return;

    try {
      await _userService.updateLastKnownLocation(
        profileId: userId,
        latitude: lat,
        longitude: lng,
      );
    } catch (error, stack) {
      if (kDebugMode) debugPrint('$error\n$stack');
    }
  }

  void _startMapTicker() {
    _mapPollTimer?.cancel();
    _mapPollTimer = Timer.periodic(
      mapVisibleUsersPollingInterval,
      (_) => unawaited(refreshVisibleUsersQuietly()),
    );
  }

  void _disposeMapTicker() {
    _mapPollTimer?.cancel();
    _mapPollTimer = null;
  }

  void _startEphemeralTicker() {
    _disposeEphemeralTicker();
    _ephemeralUiTicker = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (_activePeerId != null && _chatRetentionAscending.isNotEmpty) {
          notifyListeners();
        }
      },
    );
  }

  void _disposeEphemeralTicker() {
    _ephemeralUiTicker?.cancel();
    _ephemeralUiTicker = null;
  }

  Future<void> _disposeChatRealtimeQuietly() async {
    final session = _chatRealtime;
    _chatRealtime = null;
    if (session != null) {
      await session.dispose();
    }
  }

  /// Proper logout cascade dengan session invalidation delay (sesuai Next.js pattern)
  /// 1. Stop tracking & close conversations
  /// 2. Sign out dari Supabase (invalidate JWT)
  /// 3. Clear local state
  /// 4. Add delay untuk browser process session invalidation
  /// 5. Notify listeners (trigger AuthRouter to show LoginScreen)
  Future<void> signOutCascade() async {
    await stopSpatialTracking();
    await closeConversation();
    
    try {
      // Invalidate JWT dan session di Supabase
      await _userService.signOutEverywhere();
    } catch (error, stack) {
      if (kDebugMode) debugPrint('signOut error: $error\n$stack');
    }

    // Clear local state SEBELUM delay
    _sessionUserId = null;
    _profile = null;
    _ghostMode = false;
    _visibleUsers = <VisibleUser>[];
    _latestLatitude = null;
    _latestLongitude = null;
    _flightEpoch = -1;
    _flightLat = null;
    _flightLng = null;

    // Small delay untuk ensure session invalidation processed
    // (equiv ke Next.js logout delay pattern)
    await Future.delayed(const Duration(milliseconds: 150));

    // Notify listeners - ini akan trigger AuthRouter untuk show LoginScreen
    notifyListeners();
  }

  @override
  void dispose() {
    _disposeMapTicker();
    _disposeEphemeralTicker();
    _pauseGeolocationPump();
    unawaited(_disposeChatRealtimeQuietly());
    super.dispose();
  }
}
