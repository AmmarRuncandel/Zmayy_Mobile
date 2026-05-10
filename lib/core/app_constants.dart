/// Operational constants mirrored from the Zmayy Next.js/PWA codebase.
library;

/// Same literal required by `PrivacySettingsModal.tsx` before `delete_user_account` RPC runs.
const String accountDeletionConfirmWord = 'HAPUS';

/// Ephemeral chat: `ChatPanel.tsx` uses `MAX_MSG = 10` and `.slice(-MAX_MSG)` on in-memory arrays.
const int chatRetentionMessageCap = 10;

/// Matches `ChatPanel.tsx`: `Date.now() - 3 * 60 * 60 * 1000` for hide/drop thresholds.
///
/// Visible rule (load + realtime + render paths on web): keep message iff
/// `Date.parse(created_at).getTime() > thresholdEpochMs(now)`.
///
/// Incoming realtime payloads use the complementary guard `<= threshold` → ignore.
/// (`ChatPanel.tsx` load filter and `visibleMessages` filter use strict `>` on age.)

/// Milliseconds equivalent of the 3-hour window (explicit integer math as on web).
int chatHideThresholdEpochMs(int nowEpochMs) =>
    nowEpochMs - 3 * 60 * 60 * 1000;

bool isChatMessageYoungerThanThreshold({
  required DateTime createdAt,
  required DateTime referenceNow,
}) {
  final thresholdMs = chatHideThresholdEpochMs(referenceNow.millisecondsSinceEpoch);
  return createdAt.millisecondsSinceEpoch > thresholdMs;
}

/// `MapViewInner.tsx`: `setInterval(fetchVisibleUsers, 30_000)`.
const Duration mapVisibleUsersPollingInterval = Duration(seconds: 30);

/// Maximum age / timeout mirrors `navigator.geolocation.watchPosition` options.
const Duration geolocationMaximumAge = Duration(seconds: 5);
const Duration geolocationTimeout = Duration(seconds: 10);

/// Canonical default map center (Tasikmalaya) — `MapViewInner.tsx`.
const double defaultMapLat = -7.3274;
const double defaultMapLng = 108.2142;

/// Default zoom levels from `MapViewInner.tsx`.
const double defaultMapZoom = 13;
const double flyToFriendZoom = 16;

/// Spatial radius for strangers is enforced server-side via `get_visible_users` RPC
/// (“public strangers within 1 km”) — keep the label here for parity with UI copy.

const int strangerDiscoveryRadiusKm = 1;

/// Supabase Postgres table names used across the web app.
abstract final class SupabaseTables {
  static const profiles = 'profiles';
  static const friendships = 'friendships';
  static const messages = 'messages';
}

/// Named RPC functions — `MapViewInner.tsx`, `PrivacySettingsModal.tsx`.
abstract final class SupabaseRpc {
  static const getVisibleUsers = 'get_visible_users';
  static const deleteUserAccount = 'delete_user_account';
}

/// Storage bucket for shared chat images (`ChatPanel.tsx`).
abstract final class SupabaseStorageBuckets {
  static const chatImages = 'chat_images';
}

/// FriendsPanel UUID guard — username `ilike` search must not run for deep-link IDs.
final RegExp friendsPanelUuidCandidate = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);
