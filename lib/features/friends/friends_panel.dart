import 'package:flutter/material.dart';

import '../../data/repositories/friends_repository.dart';
import '../../data/models/friend.dart';
import '../../data/models/friend_request.dart';
import '../chat/chat_detail_screen.dart';

/// Phase 2.1 — Friends panel UI parity (data still placeholder).
class FriendsPanel extends StatefulWidget {
  final VoidCallback onClose;
  final void Function(double lat, double lng)? onGoToLocation;
  
  const FriendsPanel({
    super.key, 
    required this.onClose,
    this.onGoToLocation,
  });

  @override
  State<FriendsPanel> createState() => _FriendsPanelState();
}

class _FriendsPanelState extends State<FriendsPanel> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final FriendsRepository _repo = FriendsRepository();

  // 0 = Teman, 1 = Permintaan
  int _tab = 0;

  bool _loading = true;
  bool _accepting = false;
  String? _error;

  List<Friend> _friends = const <Friend>[];
  List<FriendRequest> _requests = const <FriendRequest>[];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _repo.getFriends(),
        _repo.getFriendRequests(),
      ]);

      final friends = results[0] as List<Friend>;
      final requests = results[1] as List<FriendRequest>;

      if (!mounted) return;
      setState(() {
        _friends = friends;
        _requests = requests;
      });
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

  Future<void> _acceptRequest(FriendRequest req) async {
    if (_accepting) return;
    setState(() => _accepting = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    try {
      await _repo.acceptFriendRequest(req.requesterId);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permintaan diterima.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();
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
            _buildSearch(),
            _buildSegmentedTabs(),
            const SizedBox(height: 10),
            Expanded(
              child: _buildBody(query),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String query) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFFFCD535)),
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
                'Gagal memuat data teman',
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
                onTap: _refresh,
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

    return _tab == 0 ? _buildFriendsList(query) : _buildRequestsList(query);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 12, 8),
      child: Row(
        children: [
          const Text(
            'Teman',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1F27),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.close, color: Colors.white70, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF181A20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2B2F36)),
        ),
        child: TextField(
          controller: _searchCtrl,
          focusNode: _searchFocus,
          style: const TextStyle(color: Colors.white, fontSize: 13.5),
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Cari username...',
            hintStyle: TextStyle(color: Color(0xFF848E9C), fontSize: 13.5),
            prefixIcon: Icon(Icons.search, color: Color(0xFF848E9C), size: 18),
            prefixIconConstraints: BoxConstraints(minWidth: 44, minHeight: 42),
            border: OutlineInputBorder(borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
            contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF181A20),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2B2F36)),
        ),
        child: Row(
          children: [
            Expanded(child: _segButton(index: 0, label: 'Teman', badge: 0)),
            Expanded(child: _segButton(index: 1, label: 'Permintaan', badge: _requests.length)),
          ],
        ),
      ),
    );
  }

  Widget _segButton({required int index, required String label, required int badge}) {
    final active = _tab == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _tab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFCD535) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? const Color(0xFF0B0E11) : const Color(0xFF848E9C),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: active ? const Color(0xFF0B0E11) : const Color(0xFFFCD535),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$badge',
                  style: TextStyle(
                    color: active ? const Color(0xFFFCD535) : const Color(0xFF0B0E11),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList(String query) {
    final items = query.isEmpty
        ? _friends
        : _friends.where((f) => f.username.toLowerCase().contains(query)).toList(growable: false);

    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: query.isEmpty ? 'Belum ada teman' : 'Tidak ada hasil',
        subtitle: query.isEmpty ? 'Dekati seseorang di peta untuk memulai' : 'Coba kata kunci lain',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _friendTile(items[i]),
    );
  }

  Widget _buildRequestsList(String query) {
    final items = query.isEmpty
        ? _requests
        : _requests.where((r) => r.username.toLowerCase().contains(query)).toList(growable: false);

    if (items.isNotEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final r = items[i];
          return _requestTile(
            initials: _initials(r.username),
            username: r.username,
            subtitle: r.subtitle,
            onAccept: _accepting ? null : () => _acceptRequest(r),
          );
        },
      );
    }

    return _buildEmptyState(
      icon: Icons.person_add_outlined,
      title: query.isEmpty ? 'Tidak ada permintaan' : 'Tidak ada hasil',
      subtitle: query.isEmpty ? 'Permintaan pertemanan akan muncul di sini' : 'Coba kata kunci lain',
    );
  }

  Widget _friendTile(Friend friend) {
    final initials = _initials(friend.username);
    final hasLocation = friend.lastLat != null && friend.lastLng != null;
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (friend.id.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Teman ini tidak memiliki id (response backend belum lengkap).'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChatDetailScreen(friend: friend)),
        );
      },
      child: Row(
        children: [
          _friendAvatar(initials: initials, isOnline: friend.isOnline),
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
                  friend.subtitle,
                  style: const TextStyle(color: Color(0xFF848E9C), fontSize: 12.5),
                ),
              ],
            ),
          ),
          // "Go to Location" button - feature parity dengan web
          if (hasLocation)
            GestureDetector(
              onTap: () {
                widget.onGoToLocation?.call(friend.lastLat!, friend.lastLng!);
                widget.onClose();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCD535).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFCD535).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFFFCD535),
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _friendAvatar({required String initials, required bool isOnline}) {
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

  Widget _requestTile({
    required String initials,
    required String username,
    required String subtitle,
    required VoidCallback? onAccept,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _avatar(initials),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Color(0xFF848E9C), fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _acceptButton(onAccept),
        ],
      ),
    );
  }

  Widget _avatar(String initials) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E11),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFCD535), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x33FCD535), blurRadius: 16, spreadRadius: 2),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(color: Color(0xFFFCD535), fontSize: 13, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _acceptButton(VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: onTap == null ? const Color(0xFFFCD535).withAlpha(160) : const Color(0xFFFCD535),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onTap == null) ...[
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0B0E11)),
              ),
            ] else ...[
              const Icon(Icons.person_add_alt_1_outlined, color: Color(0xFF0B0E11), size: 16),
            ],
            const SizedBox(width: 6),
            const Text(
              'Terima',
              style: TextStyle(color: Color(0xFF0B0E11), fontSize: 12.5, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
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
                border: Border.all(color: const Color(0xFF2B2F36), style: BorderStyle.solid),
              ),
              child: Icon(icon, color: const Color(0xFF848E9C), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF848E9C), fontSize: 13),
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
}

