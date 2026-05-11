import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../data/models/visible_user.dart';
import '../data/models/chat_message.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/map_repository.dart';
import '../data/repositories/chat_repository.dart';
import 'secure_storage.dart';

class ZmayyAppState extends ChangeNotifier {
  final MapRepository mapRepository;
  final ChatRepository chatRepository;

  ZmayyAppState({required this.mapRepository, required this.chatRepository}) {
    _startHeartbeat();
  }

  Timer? _heartbeat;
  double? lastLat;
  double? lastLng;

  // ── Profile state ──────────────────────────────────────────────────────────
  UserProfile? _currentProfile;
  String? _currentUserId;
  bool isLoadingProfile = false;

  UserProfile? get currentProfile => _currentProfile;
  String? get currentUserId => _currentUserId ?? _currentProfile?.id;

  /// Load profile from SecureStorage (called on AppShell init).
  Future<void> loadProfileFromStorage() async {
    isLoadingProfile = true;
    notifyListeners();
    try {
      final raw = await SecureStorage.readProfile();
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _currentProfile = UserProfile.fromJson(map);
        _currentUserId = _currentProfile?.id.isEmpty == true ? null : _currentProfile?.id;
      }
      _currentUserId ??= await _loadUserIdFromStoredUser();
    } catch (_) {
      // Silent — profile simply stays null
    } finally {
      isLoadingProfile = false;
      notifyListeners();
    }
  }

  void setProfile(UserProfile profile) {
    _currentProfile = profile;
    _currentUserId = profile.id.isEmpty ? null : profile.id;
    notifyListeners();
  }

  /// Update a single field on the profile and persist to storage.
  Future<void> updateProfileField(UserProfile updated) async {
    _currentProfile = updated;
    _currentUserId = updated.id.isEmpty ? _currentUserId : updated.id;
    notifyListeners();
    try {
      await SecureStorage.saveProfile(jsonEncode(updated.toJson()));
    } catch (_) {}
  }

  Future<void> setGhostMode(bool enabled) async {
    final current = _currentProfile;
    if (current == null) return;

    final updated = current.copyWith(isGhostMode: enabled);
    await updateProfileField(updated);

    if (enabled) {
      _visibleUsers.clear();
      notifyListeners();
      return;
    }

    if (lastLat != null && lastLng != null) {
      await fetchNearbyUsers(lastLat!, lastLng!);
    }
  }

  void clearProfile() {
    _currentProfile = null;
    _currentUserId = null;
    notifyListeners();
  }

  Future<String?> _loadUserIdFromStoredUser() async {
    try {
      final raw = await SecureStorage.readUser();
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final id = map['id']?.toString();
      if (id == null || id.isEmpty) return null;
      return id;
    } catch (_) {
      return null;
    }
  }

  // ── Map state ──────────────────────────────────────────────────────────────
  final List<VisibleUser> _visibleUsers = [];
  bool isLoadingMap = false;
  String? mapError;

  List<VisibleUser> get visibleUsers => List.unmodifiable(_visibleUsers);

  int get onlineFriendsCount =>
      _visibleUsers.where((u) => _resolveIsFriend(u)).length;

  int get nearbyStrangersCount =>
      _visibleUsers.where((u) => !_resolveIsFriend(u)).length;

  /// Priority: relation_type='friend' → true | 'stranger' → false | fallback is_friend flag.
  bool _resolveIsFriend(VisibleUser u) {
    if (u.relationType == 'friend') return true;
    if (u.relationType == 'stranger') return false;
    return u.isOnline; // fallback
  }

  Future<void> fetchNearbyUsers(double lat, double lng) async {
    // Skip GPS updates when ghost mode is active
    if (_currentProfile?.isGhostMode == true) return;

    isLoadingMap = true;
    mapError = null;
    notifyListeners();

    lastLat = lat;
    lastLng = lng;

    try {
      final users = await mapRepository.getVisibleUsers(lat, lng);
      _visibleUsers
        ..clear()
        ..addAll(users);
    } catch (err) {
      mapError = err is Exception ? err.toString() : 'Gagal memuat pengguna terdekat';
    } finally {
      isLoadingMap = false;
      notifyListeners();
    }
  }

  // ── Chat state ─────────────────────────────────────────────────────────────
  final List<ChatMessage> _chatMessages = [];
  bool isLoadingChat = false;
  String? chatError;

  List<ChatMessage> get chatMessages => List.unmodifiable(_chatMessages);

  void replaceChatMessages(List<ChatMessage> next) {
    _chatMessages
      ..clear()
      ..addAll(next);
    notifyListeners();
  }

  void appendChatMessage(ChatMessage msg) {
    _chatMessages.add(msg);
    while (_chatMessages.length > 10) {
      _chatMessages.removeAt(0);
    }
    notifyListeners();
  }

  Future<void> loadChatHistory() async {
    isLoadingChat = true;
    chatError = null;
    notifyListeners();

    try {
      final msgs = await chatRepository.getChatHistory();
      _chatMessages
        ..clear()
        ..addAll(msgs);
    } catch (err) {
      chatError = err is Exception ? err.toString() : 'Gagal memuat riwayat chat';
    } finally {
      isLoadingChat = false;
      notifyListeners();
    }
  }

  Future<void> sendNewMessage(String text, {String? imgUrl}) async {
    chatError = null;
    notifyListeners();
    try {
      final msg = await chatRepository.sendMessage(text, imageUrl: imgUrl);
      _chatMessages.add(msg);
      // Enforce 10-message retention cap
      while (_chatMessages.length > 10) {
        _chatMessages.removeAt(0);
      }
      notifyListeners();
    } catch (err) {
      chatError = err is Exception ? err.toString() : 'Gagal mengirim pesan';
      notifyListeners();
      rethrow;
    }
  }

  // ── Heartbeat ──────────────────────────────────────────────────────────────
  void _startHeartbeat() {
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        if (lastLat != null && lastLng != null) {
          await fetchNearbyUsers(lastLat!, lastLng!);
        }
        await loadChatHistory();
      } catch (_) {}
    });
  }

  void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  @override
  void dispose() {
    _stopHeartbeat();
    super.dispose();
  }
}
