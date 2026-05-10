import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_constants.dart';
import '../../core/app_state.dart';
import '../../core/zmayy_colors.dart';
import '../../data/models/message.dart';
import '../../data/models/profile.dart';
import '../../services/friends_service.dart';

/// Header metadata surfaced in **`ConversationThreadScreen`** toolbar.
final class ConversationPeerBrief {
  const ConversationPeerBrief({
    required this.name,
    required this.avatarLetters,
    required this.distanceLabel,
  });

  final String name;
  final String avatarLetters;
  final String distanceLabel;
}

Future<Map<String, dynamic>?> _peekLatestEnvelope(String viewerId, String peerId) async {
  final SupabaseClient client = Supabase.instance.client;
  try {
    final dynamic envelope = await client
        .from(SupabaseTables.messages)
        .select('content, created_at')
        .or(
          'and(sender_id.eq.$viewerId,receiver_id.eq.$peerId),'
          'and(sender_id.eq.$peerId,receiver_id.eq.$viewerId)',
        )
        .order('created_at', ascending: false)
        .limit(1);
    if (envelope is! List || envelope.isEmpty) return null;
    return Map<String, dynamic>.from(envelope.first as Map);
  } catch (_) {
    return null;
  }
}

String initialsForProfile(Profile profile) {
  final init = profile.avatarInitials?.trim();
  if (init != null && init.isNotEmpty) {
    final up = init.toUpperCase();
    return up.length >= 2 ? up.substring(0, 2) : up.padRight(2, '?');
  }
  final handle = profile.username?.trim();
  if (handle != null && handle.isNotEmpty) {
    final up = handle.toUpperCase();
    return up.length >= 2 ? up.substring(0, 2) : up.padRight(2, '?');
  }
  return '?';
}

String previewLabel(String raw) {
  final t = raw.trim();
  if (t.startsWith('[IMAGE]:')) return '?? Gambar';
  if (t.isEmpty) return 'Belum ada pesan';
  return t;
}

String clockHm(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return '';
  return DateFormat('HH:mm').format(dt.toLocal());
}

/// Recent chat carousel (`RecentChatsView` parity).
final class ConversationLobbyScreen extends StatefulWidget {
  const ConversationLobbyScreen({super.key, required this.sessionUserId});

  final String sessionUserId;

  @override
  State<ConversationLobbyScreen> createState() => _ConversationLobbyScreenState();
}

class LobbyRecord {
  LobbyRecord({
    required this.peerId,
    required this.title,
    required this.avatar,
    required this.rawPreview,
    required this.relativeClock,
    required this.distance,
    required this.sortKeyMillis,
  });

  final String peerId;
  final String title;
  final String avatar;
  final String rawPreview;
  final String relativeClock;
  final String distance;
  final int sortKeyMillis;
}

class _ConversationLobbyScreenState extends State<ConversationLobbyScreen> {
  late Future<List<LobbyRecord>> _future = _materialize();

  Future<void> _refresh() async {
    setState(() => _future = _materialize());
    await _future;
  }

  Future<List<LobbyRecord>> _materialize() async {
    final FriendsService repo = context.read<FriendsService>();
    final FriendsSnapshot snapshot = await repo.loadFriendsSnapshot(currentUserId: widget.sessionUserId);
    final List<LobbyRecord> rows = [];

    for (final FriendRow bond in snapshot.acceptedFriends) {
      final Profile profile = bond.profile;
      final Map<String, dynamic>? envelope =
          await _peekLatestEnvelope(widget.sessionUserId, profile.id);
      final String raw = envelope?['content'] as String? ?? '';
      final String created = envelope?['created_at'] as String? ?? '';
      rows.add(
        LobbyRecord(
          peerId: profile.id,
          title: profile.displayName ?? profile.username ?? 'Teman',
          avatar: initialsForProfile(profile),
          rawPreview: raw,
          relativeClock: created.isEmpty ? '' : clockHm(created),
          distance: profile.lastLat != null && profile.lastLng != null ? '< 1 km' : 'Offline',
          sortKeyMillis: DateTime.tryParse(created)?.millisecondsSinceEpoch ?? 0,
        ),
      );
    }

    rows.sort((LobbyRecord a, LobbyRecord b) => b.sortKeyMillis.compareTo(a.sortKeyMillis));
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LobbyRecord>>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<List<LobbyRecord>> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: ZmayyColors.gold));
        }
        final List<LobbyRecord> rows = snap.data ?? const <LobbyRecord>[];
        if (rows.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 44, color: ZmayyColors.gold.withAlpha(100)),
                const SizedBox(height: 14),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Belum ada teman untuk diajak chat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ZmayyColors.muted),
                  ),
                ),
              ],
            ),
          );
        }

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ZmayyColors.base, ZmayyColors.slate950],
            ),
          ),
          child: RefreshIndicator(
            color: ZmayyColors.gold,
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                14,
                14,
                14,
                MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 26,
              ),
              itemBuilder: (_, int index) {
                final LobbyRecord entry = rows[index];
                final ConversationPeerBrief brief = ConversationPeerBrief(
                  name: entry.title,
                  avatarLetters: entry.avatar,
                  distanceLabel: entry.distance,
                );

                return Container(
                  decoration: BoxDecoration(
                    color: ZmayyColors.surface.withAlpha(220),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: ZmayyColors.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor: ZmayyColors.gold,
                      foregroundColor: ZmayyColors.base,
                      child: Text(entry.avatar),
                    ),
                    title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(previewLabel(entry.rawPreview), maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Text(entry.relativeClock, style: const TextStyle(fontSize: 11, color: ZmayyColors.muted)),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ConversationThreadScreen(peerId: entry.peerId, peer: brief),
                        ),
                      );
                    },
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 8),
              itemCount: rows.length,
            ),
          ),
        );
      },
    );
  }
}

/// Stateful conversation bound to [`ZmayyAppState.openConversation`].
final class ConversationThreadScreen extends StatefulWidget {
  const ConversationThreadScreen({super.key, required this.peerId, required this.peer});

  final String peerId;
  final ConversationPeerBrief peer;

  @override
  State<ConversationThreadScreen> createState() => _ConversationThreadScreenState();
}

class _ConversationThreadScreenState extends State<ConversationThreadScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _list = ScrollController();
  late final ZmayyAppState _host = context.read<ZmayyAppState>();

  bool _loading = true;
  Object? _failure;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _host.registerChatDrawerVisibility(true);
      try {
        await _host.openConversation(peerId: widget.peerId);
        if (mounted) setState(() => _loading = false);
      } catch (error) {
        if (mounted) {
          setState(() {
            _failure = error;
            _loading = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    Future<void>.microtask(() async => _host.closeConversation());
    _host.registerChatDrawerVisibility(false);
    _input.dispose();
    _list.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final String body = _input.text.trim();
    if (body.isEmpty) return;
    try {
      await _host.sendChatText(body);
      _input.clear();
      _scrollLast();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengirim: $error')));
    }
  }

  Future<void> _sendImage() async {
    try {
      final XFile? shot = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88);
      if (shot == null) return;
      await _host.sendChatImageFromFile(File(shot.path));
      _scrollLast();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mengunggah: $error')));
    }
  }

  void _scrollLast() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_list.hasClients) return;
      _list.animateTo(
        _list.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;

    Widget body;
    if (_failure != null) {
      body = Center(child: Text('$_failure'));
    } else if (_loading) {
      body = const Center(child: CircularProgressIndicator(color: ZmayyColors.gold));
    } else {
      body = Consumer<ZmayyAppState>(
        builder: (BuildContext context, ZmayyAppState app, _) {
          final List<Message> timeline = app.visibleChatTimeline;
          final int reserved = app.ephemeralRingSlotsUsed.clamp(0, chatRetentionMessageCap);
          final String? uid = app.authenticatedUserId;

          _scrollLast();

          return AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.only(bottom: keyboard),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ZmayyColors.gold.withAlpha(18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ZmayyColors.gold.withAlpha(64)),
                  ),
                  child: const Text(
                    'Mode Efemeral: Pesan dihapus otomatis setelah 10 percakapan atau 3 jam.',
                    style: TextStyle(fontSize: 12, height: 1.35),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: LinearProgressIndicator(
                    value: reserved / chatRetentionMessageCap,
                    color: reserved < chatRetentionMessageCap ~/ 2
                        ? ZmayyColors.gold
                        : reserved < (chatRetentionMessageCap * 3 ~/ 4)
                            ? ZmayyColors.warningAmber
                            : ZmayyColors.danger,
                    backgroundColor: Colors.white12,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: timeline.isEmpty
                      ? const Center(
                          child: Text('Belum ada pesan baru.', style: TextStyle(color: ZmayyColors.muted)),
                        )
                      : ListView.builder(
                          controller: _list,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          itemCount: timeline.length,
                          itemBuilder: (_, int index) {
                            final Message bubble = timeline[index];
                            final bool outgoing = uid != null && bubble.senderId == uid;
                            return ChatBubbleTile(message: bubble, outgoing: outgoing);
                          },
                        ),
                ),
                const Divider(height: 1, color: ZmayyColors.border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: ZmayyColors.border),
                        ),
                        child: IconButton(onPressed: _sendImage, icon: const Icon(Icons.image_outlined, size: 20)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: ZmayyColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: ZmayyColors.border),
                          ),
                          child: TextField(
                            controller: _input,
                            minLines: 1,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Tulis pesan...',
                              filled: false,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendText(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: ZmayyColors.gold,
                          foregroundColor: ZmayyColors.base,
                          minimumSize: const Size(54, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          elevation: 0,
                        ),
                        onPressed: _sendText,
                        child: const Icon(Icons.send_rounded, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    final int consumed = context.select<ZmayyAppState, int>(
      (ZmayyAppState value) =>
          chatRetentionMessageCap - value.ephemeralRingSlotsUsed.clamp(0, chatRetentionMessageCap),
    );
    final int ringUsage = context.select<ZmayyAppState, int>(
      (ZmayyAppState value) => value.ephemeralRingSlotsUsed,
    );

    return Scaffold(
      backgroundColor: ZmayyColors.base,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.peer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.peer.distanceLabel, style: const TextStyle(fontSize: 12, color: ZmayyColors.gold)),
            Text(
              '$consumed pesan sebelum hapus otomatis',
              style: TextStyle(
                fontSize: 11,
                color: ringUsage >= 8 ? ZmayyColors.danger : ZmayyColors.gold.withAlpha(140),
              ),
            ),
          ],
        ),
        backgroundColor: ZmayyColors.base,
      ),
      body: body,
    );
  }
}

final class ChatBubbleTile extends StatelessWidget {
  const ChatBubbleTile({super.key, required this.message, required this.outgoing});

  final Message message;
  final bool outgoing;

  @override
  Widget build(BuildContext context) {
    final Widget core;
    if (message.content.startsWith('[IMAGE]:')) {
      final String url = message.content.substring('[IMAGE]:'.length);
      core = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => const SizedBox(
            height: 120,
            child: Center(child: Icon(Icons.broken_image_outlined)),
          ),
        ),
      );
    } else {
      core = Text(message.content, style: const TextStyle(height: 1.35));
    }

    final BorderRadius radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(outgoing ? 20 : 6),
      bottomRight: Radius.circular(outgoing ? 6 : 20),
    );

    final Color fill = outgoing ? ZmayyColors.gold : ZmayyColors.surface;
    final Color fg = outgoing ? ZmayyColors.base : ZmayyColors.primaryText;
    final Color stamp = outgoing ? ZmayyColors.base.withAlpha(140) : ZmayyColors.muted;

    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.86,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: radius,
            border: Border.all(color: outgoing ? Colors.transparent : ZmayyColors.border),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: fg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                core,
                const SizedBox(height: 6),
                Text(clockHm(message.createdAt), style: TextStyle(fontSize: 10, color: stamp)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
