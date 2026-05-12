import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/biometric_helper.dart';
import '../../core/biometric_storage.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;
  bool _biometricChecked = false;
  bool _biometricPassed = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricProtection();
  }

  Future<void> _checkBiometricProtection() async {
    final isEnabled = await BiometricStorage.isBiometricChatEnabled();
    if (!isEnabled) {
      setState(() {
        _biometricChecked = true;
        _biometricPassed = true;
      });
      return;
    }

    // Biometric is enabled, require authentication
    final authenticated = await BiometricHelper.authenticate();
    if (!mounted) return;

    setState(() {
      _biometricChecked = true;
      _biometricPassed = authenticated;
    });

    if (!authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Autentikasi gagal. Akses obrolan ditolak.')),
      );
    }
  }

  Future<void> _send(ZmayyAppState appState) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await appState.sendNewMessage(text);
      _controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scroll.jumpTo(_scroll.position.maxScrollExtent));
    } catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ZmayyAppState>(context);
    final messages = appState.chatMessages;
    final myUserId = appState.currentUserId;

    // Show loading while checking biometric
    if (!_biometricChecked) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0E11),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFCD535)),
        ),
      );
    }

    // Show locked screen if biometric failed
    if (!_biometricPassed) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0E11),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, color: Color(0xFFFCD535), size: 64),
              const SizedBox(height: 16),
              const Text(
                'Obrolan Terkunci',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Autentikasi biometrik diperlukan',
                style: TextStyle(color: Color(0xFF848E9C), fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _checkBiometricProtection,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFCD535),
                  foregroundColor: const Color(0xFF0B0E11),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final m = messages[i];
                  final mine = myUserId != null && m.senderId == myUserId;
                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                      decoration: BoxDecoration(
                        color: mine ? const Color(0xFFD4AC1A) : const Color(0xFF181A20),
                        borderRadius: BorderRadius.circular(14),
                        border: mine ? null : Border.all(color: Colors.white12),
                        boxShadow: mine ? [BoxShadow(color: const Color(0x22000000), blurRadius: 8)] : null,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!mine) Text(m.senderUsername ?? m.senderId, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(m.content, style: TextStyle(color: mine ? const Color(0xFF0B0E11) : Colors.white70)),
                          const SizedBox(height: 6),
                          Text(m.createdAt, style: const TextStyle(color: Colors.white30, fontSize: 10)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0E11),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.02))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF121316),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(32), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sending ? null : () => _send(appState),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFFCD535), borderRadius: BorderRadius.circular(32)),
                      child: _sending ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send, color: Color(0xFF0B0E11)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
