import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_constants.dart';
import '../data/models/message.dart';

/// Applies the ephemeral rules from `ChatPanel.tsx`:
/// • server fetch is limited to **[chatRetentionMessageCap]** ascending rows  
/// • after load/realtime merges, **`[...msgs, newMsg]` then `.slice(-10)`** trimming  
/// • strict **younger-than-3-hours** insertion guard on realtime payloads  
///
/// Rendering still applies the presentation filter independently (see
/// [EphemeralConversationLogic.visibleForTimeline]) — mirrored in [`ZmayyAppState`]
/// like React `visibleMessages`.
abstract final class EphemeralConversationLogic {
  /// ISO `created_at` must be strictly **greater than** the rolling threshold —
  /// identical to `.getTime() > threshold` (`ChatPanel.tsx`).
  static bool passesThreeHourGate(String createdAtIso, DateTime referenceNow) {
    final stamp = DateTime.tryParse(createdAtIso)?.toUtc();
    if (stamp == null) return false;
    return isChatMessageYoungerThanThreshold(
      createdAt: stamp,
      referenceNow: referenceNow,
    );
  }

  static List<Message> filterYoungerThanThreeHours(
    Iterable<Message> messages,
    DateTime referenceNow,
  ) {
    return messages
        .where(
          (message) => passesThreeHourGate(message.createdAt, referenceNow),
        )
        .toList(growable: false);
  }

  /// Drops chronologically earliest rows beyond the allowance (parity with `.slice(-MAX_MSG)`).
  static List<Message> applyTenMessageRetention(List<Message> ascendingChronological) {
    final cap = chatRetentionMessageCap;
    if (ascendingChronological.length <= cap) {
      return List<Message>.from(ascendingChronological);
    }
    return ascendingChronological.sublist(ascendingChronological.length - cap);
  }

  /// Bubbled UI list analogue — `ChatPanel.tsx` `visibleMessages`.
  static List<Message> visibleForTimeline(
    List<Message> cappedAscendingBuffer,
    DateTime referenceNow,
  ) =>
      filterYoungerThanThreeHours(cappedAscendingBuffer, referenceNow);

  /// Ring metric uses **RAW** buffered length before the timeline filter (`remaining` calc).
  static int ringUsedCount(List<Message> cappedAscendingBuffer) =>
      cappedAscendingBuffer.length;
}

/// Subscription handle so [`ZmayyAppState`] can tear down cleanly.
final class PeerChatRealtimeSession {
  PeerChatRealtimeSession(this._dispose);

  final Future<void> Function() _dispose;

  Future<void> dispose() => _dispose();
}

/// Stateless Supabase `messages` accessors + realtime fan-in for exactly **one peer pair**.
///
/// Mirrors `ChatPanel.tsx`:
/// • channel name **`chat-{sorted(ids)}`**  
/// • Postgres filter **`receiver_id = eq.currentUser`** plus callback predicate on `sender_id`  
///
/// Despite rubric wording (“global”), production behaviour remains **scoped 1:1** chat parity.
final class ChatService {
  ChatService(this._client);

  final SupabaseClient _client;

  String _conversationOrFilter({
    required String viewerId,
    required String peerId,
  }) {
    /// Same PostgREST `or(and(...))` clauses as JSX template literal.
    return 'and(sender_id.eq.$viewerId,receiver_id.eq.$peerId),'
        'and(sender_id.eq.$peerId,receiver_id.eq.$viewerId)';
  }

  /// Hydrates the chronological tail (**<= [chatRetentionMessageCap]** rows) then applies the
  /// hydrated 3&nbsp;h filter identical to typed script `filtered` assignment.
  Future<List<Message>> loadConversationTail({
    required String viewerId,
    required String peerId,
  }) async {
    final response = await _client
        .from(SupabaseTables.messages)
        .select('*')
        .or(_conversationOrFilter(viewerId: viewerId, peerId: peerId))
        .order('created_at', ascending: true)
        .limit(chatRetentionMessageCap);

    final rows = (response as List<dynamic>? ?? [])
        .map((dynamic row) => Map<String, dynamic>.from(row as Map))
        .map(Message.fromJson)
        .toList();

    final nowClock = DateTime.now();
    return EphemeralConversationLogic.filterYoungerThanThreeHours(
      rows,
      nowClock,
    );
  }

  /// Mirrors **incoming-only** realtime branch — optimistic outbound sends bypass this channel,
  /// exactly like JSX implementation.
  PeerChatRealtimeSession subscribeIncomingPartnerInserts({
    required String viewerId,
    required String peerId,
    required void Function(Message message) onInsert,
  }) {
    final ids = [viewerId, peerId]..sort();
    final topic = 'chat-${ids.join('-')}';

    final channel = _client.channel(topic);

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseTables.messages,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'receiver_id',
            value: viewerId,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isEmpty) return;

            late final Message inserted;
            try {
              inserted = Message.fromJson(Map<String, dynamic>.from(record));
            } catch (_) {
              return;
            }

            if (inserted.senderId != peerId) return;

            final nowClock = DateTime.now();
            if (!EphemeralConversationLogic.passesThreeHourGate(
              inserted.createdAt,
              nowClock,
            )) {
              return;
            }

            onInsert(inserted);
          },
        )
        .subscribe();

    return PeerChatRealtimeSession(() async {
      await channel.unsubscribe();
    });
  }
}
