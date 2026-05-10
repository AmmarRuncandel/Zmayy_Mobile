import "dart:async";

import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../../core/app_constants.dart";
import "../../core/zmayy_colors.dart";
import "../../data/models/profile.dart";
import "../../services/friends_service.dart";
import "../chat/chat_panel.dart";

typedef PeerLocator = void Function(String uuid);
typedef ChatStarter = void Function(String peerId, ConversationPeerBrief brief);

class FriendsHomeScreen extends StatefulWidget {
  const FriendsHomeScreen({super.key, required this.sessionUserId, this.locatePeer, this.beginChat});

  final String sessionUserId;
  final PeerLocator? locatePeer;
  final ChatStarter? beginChat;

  @override
  State<FriendsHomeScreen> createState() => _FriendsHomeScreenState();
}

class _FriendsHomeScreenState extends State<FriendsHomeScreen> {
  final TextEditingController needle = TextEditingController();
  Timer? debouncer;
  FriendsSnapshot? stash;
  bool booting = true;
  List<Profile> hits = [];
  bool scouting = false;
  int segment = 0;

  @override
  void initState() {
    super.initState();
    needle.addListener(onNeedleChanged);
    hydrate();
  }

  @override
  void dispose() {
    needle.removeListener(onNeedleChanged);
    needle.dispose();
    debouncer?.cancel();
    super.dispose();
  }

  Future<void> hydrate() async {
    final FriendsService svc = context.read<FriendsService>();
    final FriendsSnapshot parcel = await svc.loadFriendsSnapshot(currentUserId: widget.sessionUserId);
    if (!mounted) return;
    setState(() {
      stash = parcel;
      booting = false;
    });
  }

  void onNeedleChanged() {
    debouncer?.cancel();
    final String trimmed = needle.text.trim();
    if (trimmed.isEmpty) {
      setState(() => hits = []);
      return;
    }
    if (friendsPanelUuidCandidate.hasMatch(trimmed)) {
      debouncer = Timer(const Duration(milliseconds: 40), () async {
        setState(() => scouting = true);
        final svc = context.read<FriendsService>();
        final Profile? exact = await svc.fetchProfileStrictId(
          profileId: trimmed,
          excludingUserId: widget.sessionUserId,
        );
        if (!mounted) return;
        setState(() {
          hits = exact == null ? [] : [exact];
          scouting = false;
        });
      });
      return;
    }
    debouncer = Timer(const Duration(milliseconds: 330), () async {
      setState(() => scouting = true);
      final rows = await context.read<FriendsService>().searchProfilesByUsername(
            query: trimmed,
            excludingUserId: widget.sessionUserId,
          );
      if (!mounted) return;
      setState(() {
        hits = rows;
        scouting = false;
      });
    });
  }

  ConversationPeerBrief synopsis(Profile peer) {
    final letters = initialsForProfile(peer);
    final distanceLabel = peer.lastLat != null && peer.lastLng != null ? "< 1 km" : "Offline";
    return ConversationPeerBrief(
      name: peer.displayName ?? peer.username ?? "Teman",
      avatarLetters: letters,
      distanceLabel: distanceLabel,
    );
  }

  Future<void> sendHandshake(Profile guest) async {
    try {
      await Supabase.instance.client.from(SupabaseTables.friendships).insert({
        "requester_id": widget.sessionUserId,
        "addressee_id": guest.id,
        "status": "pending",
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Permintaan terkirim untuk ${guest.displayName ?? guest.username}")),
      );
      await hydrate();
    } on PostgrestException catch (err) {
      final message = err.code == "23505" ? "Permintaan pertemanan sudah terkirim sebelumnya." : err.message;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> acceptHandshake(String fid, String name) async {
    await context.read<FriendsService>().acceptFriendRequest(fid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name ditambahkan!")));
    await hydrate();
  }

  Widget chip(String caption, int index, {int badge = 0}) {
    final bool active = segment == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => segment = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? ZmayyColors.gold : Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? ZmayyColors.gold : ZmayyColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                caption,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: active ? ZmayyColors.base : ZmayyColors.primaryText,
                ),
              ),
              if (badge > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: active ? ZmayyColors.base : ZmayyColors.gold,
                    foregroundColor: active ? ZmayyColors.gold : ZmayyColors.base,
                    child: Text("$badge", style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget friendList(List<FriendRow> rows, {bool inbound = false}) {
    if (rows.isEmpty) {
      return const Center(child: Text("Kosong", style: TextStyle(color: ZmayyColors.muted)));
    }
    final inset = MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 16;

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(left: 16, right: 16, bottom: inset),
      itemCount: rows.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 8),
      itemBuilder: (_, idx) {
        final bond = rows[idx];
        final peer = bond.profile;
        final glyph = initialsForProfile(peer);

        Widget? trailingWidget;
        if (inbound) {
          trailingWidget = FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: ZmayyColors.gold,
              foregroundColor: ZmayyColors.base,
            ),
            onPressed: () =>
                acceptHandshake(bond.friendshipId, peer.displayName ?? peer.username ?? ""),
            child: const Text("Terima"),
          );
        } else {
          trailingWidget = Wrap(
            children: [
              IconButton(
                icon: const Icon(Icons.map_outlined, color: ZmayyColors.gold),
                onPressed: () {
                  if (peer.isGhostMode == true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Tidak dapat melacak — pengguna dalam Mode Hantu.")),
                    );
                    return;
                  }
                  widget.locatePeer?.call(peer.id);
                },
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: ZmayyColors.gold),
                onPressed: () => widget.beginChat?.call(peer.id, synopsis(peer)),
              ),
            ],
          );
        }

        final caption = inbound ? "Permintaan masuk" : (peer.lastLat != null ? "Dekat" : "Aktif");

        return Container(
          decoration: BoxDecoration(
            color: ZmayyColors.surface.withAlpha(218),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ZmayyColors.border),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: ZmayyColors.gold,
              foregroundColor: ZmayyColors.base,
              child: Text(glyph),
            ),
            title: Text(peer.displayName ?? peer.username ?? "Teman"),
            subtitle: Text(caption, style: const TextStyle(color: ZmayyColors.muted)),
            trailing: trailingWidget,
            onTap: inbound ? null : () => widget.beginChat?.call(peer.id, synopsis(peer)),
          ),
        );
      },
    );
  }

  Widget discoveryViewport() {
    if (scouting) {
      return const Center(child: CircularProgressIndicator(color: ZmayyColors.gold));
    }
    if (hits.isEmpty) {
      return const Center(child: Text("Pengguna tidak ditemukan", style: TextStyle(color: ZmayyColors.muted)));
    }
    final inset = MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 16;

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 6, 16, inset),
      itemCount: hits.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 8),
      itemBuilder: (_, idx) {
        final profile = hits[idx];
        final glyph = initialsForProfile(profile);

        return Card(
          color: ZmayyColors.surface.withAlpha(220),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: ZmayyColors.gold, foregroundColor: ZmayyColors.base, child: Text(glyph)),
            title: Text(profile.displayName ?? profile.username ?? "Profil"),
            subtitle: Text("@${profile.username ?? "—"}", style: const TextStyle(color: ZmayyColors.muted)),
            trailing: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ZmayyColors.gold,
                foregroundColor: ZmayyColors.base,
              ),
              onPressed: () => sendHandshake(profile),
              child: const Text("Tambah"),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (booting) {
      return const Center(child: CircularProgressIndicator(color: ZmayyColors.gold));
    }

    final parcel = stash;
    if (parcel == null) {
      return const Center(
        child: Text("Memuat daftar teman...", style: TextStyle(color: ZmayyColors.muted)),
      );
    }
    final querying = needle.text.trim().isNotEmpty;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ZmayyColors.base, ZmayyColors.slate950],
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            decoration: BoxDecoration(
              color: ZmayyColors.glassFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ZmayyColors.border),
            ),
            child: TextField(
              controller: needle,
              decoration: const InputDecoration(
                hintText: "Cari username...",
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: ZmayyColors.muted),
                filled: false,
              ),
            ),
          ),
          if (!querying)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  chip("Teman", 0),
                  const SizedBox(width: 12),
                  chip("Permintaan", 1, badge: parcel.inboundPending.length),
                ],
              ),
            ),
          Expanded(
            child: querying
                ? discoveryViewport()
                : segment == 0
                    ? friendList(parcel.acceptedFriends, inbound: false)
                    : friendList(parcel.inboundPending, inbound: true),
          ),
        ],
      ),
    );
  }
}
