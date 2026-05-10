import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_constants.dart';
import '../data/models/profile.dart';

/// Profile CRUD helpers matching `ProfileModal.tsx`, `PrivacySettingsModal.tsx`,
/// and deep-link lookups (`profiles` narrow select by `.eq('id', uuid)`).
final class UserService {
  UserService(this._client);

  final SupabaseClient _client;

  /// Generic row fetch (`ProfileModal.tsx` hydrate path).
  Future<Profile?> fetchProfileByUuid(String profileId) async {
    final row = await _client
        .from(SupabaseTables.profiles)
        .select()
        .eq('id', profileId)
        .maybeSingle();

    if (row == null) return null;
    return Profile.fromJson(Map<String, dynamic>.from(row));
  }

  /// Deep-link optimisation — logically identical [`fetchProfileByUuid`] but labelled for QR flows.
  Future<Profile?> fetchProfileViaDeepLinkUuid(String uuid) =>
      fetchProfileByUuid(uuid);

  /// Mirrors instant toggles synced to granular notification columns (`notify_sound`, `notify_messages`).
  ///
  /// Web toggles originate from modal controls — null fields are **skipped** avoiding accidental resets.
  Future<void> patchNotificationGranularity({
    required String profileId,
    bool? notifyMessages,
    bool? notifySound,
  }) async {
    final payload = <String, dynamic>{};
    final messages = notifyMessages;
    final sound = notifySound;
    if (messages != null) payload['notify_messages'] = messages;
    if (sound != null) payload['notify_sound'] = sound;

    if (payload.isEmpty) return;

    await _client.from(SupabaseTables.profiles).update(payload).eq('id', profileId);
  }

  /// Full notification matrix — `NotificationsSettingsModal.tsx`.
  Future<void> patchNotificationMatrix({
    required String profileId,
    bool? notifyGlobal,
    bool? notifyRequests,
    bool? notifyMessages,
    bool? notifySound,
  }) async {
    final payload = <String, dynamic>{};
    if (notifyGlobal != null) payload['notify_global'] = notifyGlobal;
    if (notifyRequests != null) payload['notify_requests'] = notifyRequests;
    if (notifyMessages != null) payload['notify_messages'] = notifyMessages;
    if (notifySound != null) payload['notify_sound'] = notifySound;
    if (payload.isEmpty) return;
    await _client.from(SupabaseTables.profiles).update(payload).eq('id', profileId);
  }

  /// `PrivacySettingsModal.tsx` “Profil Publik” instant toggle.
  Future<void> updatePublicProfile({
    required String profileId,
    required bool isPublic,
  }) async {
    await _client.from(SupabaseTables.profiles).update(<String, dynamic>{
      'is_public': isPublic,
    }).eq('id', profileId);
  }

  /// `ProfileModal.tsx` ghost activation — DB footprint wipe when enabling.
  Future<void> setGhostProfileState({
    required String profileId,
    required bool ghostEnabled,
  }) async {
    final payload = <String, dynamic>{'is_ghost_mode': ghostEnabled};
    if (ghostEnabled) {
      payload['last_lat'] = null;
      payload['last_lng'] = null;
    }
    await _client.from(SupabaseTables.profiles).update(payload).eq('id', profileId);
  }

  /// Mirrors `navigator` heartbeat upserts updating `profiles.last_lat/lng/updated_at` (`MapViewInner.tsx`).
  Future<void> updateLastKnownLocation({
    required String profileId,
    required double latitude,
    required double longitude,
  }) async {
    await _client.from(SupabaseTables.profiles).update(<String, dynamic>{
      'last_lat': latitude,
      'last_lng': longitude,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq(
      'id',
      profileId,
    );
  }

  /// Executes `PrivacySettingsModal.tsx` guarded RPC — caller must enforce **HAPUS** confirmation UI.
  Future<void> deleteUserAccountViaRpc() async {
    await _client.rpc<void>(SupabaseRpc.deleteUserAccount);
  }

  Future<void> signOutEverywhere() async {
    await _client.auth.signOut();
  }
}
