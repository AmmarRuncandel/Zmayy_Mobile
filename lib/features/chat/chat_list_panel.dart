import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../data/models/friend.dart';
import '../../data/models/chat_message.dart';
import '../../data/repositories/chat_repository.dart';
import 'chat_detail_screen.dart';

/// Chat List panel — Shows 1-on-1 conversations with friends.
class ChatListPanel extends StatefulWidget {
  final VoidCallback onClose;
  const ChatListPanel({super.key, required this.onClose});

  @override
  State<ChatListPanel> createState() => _ChatListPanelState();
}

class _ChatListPanelState extends State<ChatListPanel> {
  final ChatRepository _repo = ChatRepository();
  bool _loading = true;
  String? _error;
  Map<String, ChatMessage?> _lastMessages = {};

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _loading = true;
      _error = null;
      _lastMessages = {};
    });

    try {
      final appState = Provider.of<ZmayyAppState>(context, listen: false);
      final friends = appState.visibleUsers
          .where((u) => _isFriend(u))
          .map((u) => Friend(
            id: u.id,
            username: u.username ?? '—',
            isOnline: u.isOnline,
            distanceKm: u.distanceKm,
          ))
          .toList();

      // Fetch last message for each friend
      for (final friend in friends) {
        try {
          final history = await _repo.getDirectHistory(friend.id);
          if (history.isNotEmpty) {
            _lastMessages[friend.id] = history.last;
          }
        } catch (e) {
          // Silent fail for individual friend messages
        }
      }

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _isFriend(dynamic u) {
    if (u.relationType == 'friend') return true;
    if (u.relationType == 'stranger') return false;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181A20).withValues(alpha: 0.88),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(2, 0)),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        children: [
          const Text('Obrolan',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          const Spacer(),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: const Color(0xFF1C1F27),
                  borderRadius: BorderRadius.circular(8)),
              child:
                  const Icon(Icons.close, color: Colors.white70, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child:
              CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFFFCD535)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFFCD535), size: 28),
              const SizedBox(height: 10),
              const Text(
                'Gagal memuat obrolan',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF848E9C), fontSize: 12.5),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _loadConversations,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCD535),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Coba lagi',
                    style: TextStyle(color: Color(0xFF0B0E11), fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final appState = Provider.of<ZmayyAppState>(context);
    final friends = appState.visibleUsers
        .where((u) => _isFriend(u))
        .map((u) => Friend(
          id: u.id,
          username: u.username ?? '—',
          isOnline: u.isOnline,
          distanceKm: u.distanceKm,
        ))
        .toList();

    if (friends.isEmpty) {
      return _buildEmptyState();
    }

    // Sort by last message time (newest first)
    friends.sort((a, b) {
      final msgA = _lastMessages[a.id];
      final msgB = _lastMessages[b.id];
      if (msgA == null && msgB == null) return 0;
      if (msgA == null) return 1;
      if (msgB == null) return -1;
      return msgB.createdAt.compareTo(msgA.createdAt);
    });

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      itemCount: friends.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final friend = friends[i];
        final lastMsg = _lastMessages[friend.id];
        return _conversationTile(friend, lastMsg);
      },
    );
  }

  Widget _conversationTile(Friend friend, ChatMessage? lastMsg) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChatDetailScreen(friend: friend)),
        );
      },
      child: Row(
        children: [
          _friendAvatar(friend.username, friend.isOnline),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  lastMsg?.content ?? 'Mulai percakapan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF848E9C).withAlpha(200),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          if (lastMsg != null) ...[
            const SizedBox(width: 8),
            Text(
              _formatTime(lastMsg.createdAt),
              style: const TextStyle(
                color: Color(0xFF848E9C),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _friendAvatar(String username, bool isOnline) {
    final initials = _initials(username);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFFCD535),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Color(0x2BFCD535), blurRadius: 14, spreadRadius: 1),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: Color(0xFF0B0E11),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0B0E11), width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF181A20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2B2F36)),
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  color: Color(0xFF848E9C), size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Belum ada obrolan',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text(
              'Mulai chat dengan temanmu dari daftar Teman',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF848E9C), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String username) {
    final t = username.trim();
    if (t.isEmpty) return 'ZM';
    final parts = t.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return t.length >= 2 ? t.substring(0, 2).toUpperCase() : t[0].toUpperCase();
  }

  String _formatTime(String createdAt) {
    try {
      final dt = DateTime.parse(createdAt);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Baru';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays == 1) return 'Kemarin';
      if (diff.inDays < 7) return '${diff.inDays}d';

      return '${dt.day}/${dt.month}';
    } catch (_) {
      return '';
    }
  }
}
