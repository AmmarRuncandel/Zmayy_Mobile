import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/friend.dart';
import '../../data/repositories/chat_repository.dart';

class ChatDetailScreen extends StatefulWidget {
  final Friend friend;
  const ChatDetailScreen({super.key, required this.friend});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatRepository _repo = ChatRepository();
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Load DM history (if backend endpoint isn't ready yet, the error will be shown clearly).
      final msgs = await _repo.getDirectHistory(widget.friend.id);
      if (!mounted) return;
      final appState = Provider.of<ZmayyAppState>(context, listen: false);
      // Reuse appState chat list temporarily; Phase 3 will isolate DM state.
      appState.replaceChatMessages(msgs);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    try {
      final msg = await _repo.sendDirectMessage(widget.friend.id, text);
      if (!mounted) return;
      final appState = Provider.of<ZmayyAppState>(context, listen: false);
      appState.appendChatMessage(msg);
      _ctrl.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ZmayyAppState>(context);
    final messages = appState.chatMessages;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildEphemeralBanner(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFFFCD535)),
                      ),
                    )
                  : (_error != null
                      ? _buildError()
                      : (messages.isEmpty ? _buildEmptyState() : _buildMessages(messages))),
            ),
            _buildUploadHint(),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final initials = widget.friend.username.trim().isEmpty
        ? 'ZM'
        : (widget.friend.username.trim().length >= 2 ? widget.friend.username.trim().substring(0, 2).toUpperCase() : widget.friend.username.trim()[0].toUpperCase());

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left, color: Colors.white70),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(color: Color(0xFFFCD535), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(color: Color(0xFF0B0E11), fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.friend.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  '${widget.friend.subtitle} • 10 pesan sebelum hapus otomatis',
                  style: const TextStyle(color: Color(0xFFFCD535), fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildEphemeralBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF181A20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2B2F36)),
        ),
        child: const Text(
          'Mode Efemeral: Pesan dihapus otomatis setelah 10 percakapan atau 3 jam.',
          style: TextStyle(color: Color(0xFFFCD535), fontSize: 12.2, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFCD535), size: 30),
            const SizedBox(height: 10),
            const Text('Gagal memuat obrolan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF848E9C), fontSize: 12.5)),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _load,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFFCD535), borderRadius: BorderRadius.circular(10)),
                child: const Text('Coba lagi', style: TextStyle(color: Color(0xFF0B0E11), fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF181A20),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF2B2F36)),
              ),
              child: const Icon(Icons.crop_square_rounded, color: Color(0xFFFCD535), size: 28),
            ),
            const SizedBox(height: 16),
            const Text('Belum ada pesan.', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Kirim pesan pertama. Pesan akan terhapus otomatis setelah 10 percakapan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF848E9C), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessages(List<ChatMessage> messages) {
    final myUserId = Provider.of<ZmayyAppState>(context, listen: false).currentUserId;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final m = messages[i];
        final mine = myUserId != null && m.senderId == myUserId;
        return Align(
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
            decoration: BoxDecoration(
              color: mine ? const Color(0xFFFCD535) : const Color(0xFF181A20),
              borderRadius: BorderRadius.circular(14),
              border: mine ? null : Border.all(color: const Color(0xFF2B2F36)),
            ),
            child: Text(
              m.content,
              style: TextStyle(color: mine ? const Color(0xFF0B0E11) : Colors.white70, fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUploadHint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF12151B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2B2F36), style: BorderStyle.solid),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            const Icon(Icons.image_outlined, color: Color(0xFF848E9C), size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Seret & lepas gambar untuk berbagi lokasi',
                style: TextStyle(color: Color(0xFF848E9C), fontSize: 12.2, fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1F27),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, color: Colors.white70, size: 16),
                  SizedBox(width: 6),
                  Text('Upload', style: TextStyle(color: Colors.white70, fontSize: 12.2, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF181A20),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF2B2F36)),
              ),
              child: TextField(
                controller: _ctrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Tulis pesan...',
                  hintStyle: TextStyle(color: Color(0xFF848E9C)),
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sending ? null : _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFCD535).withAlpha(_sending ? 170 : 255),
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF0B0E11)),
                    )
                  : const Icon(Icons.send_rounded, color: Color(0xFF0B0E11), size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

