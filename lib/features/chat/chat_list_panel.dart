import 'package:flutter/material.dart';

/// Placeholder Chat List panel — Phase 3 will replace body with real DM data.
class ChatListPanel extends StatelessWidget {
  final VoidCallback onClose;
  const ChatListPanel({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B0E11),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildEmptyState()),
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
            onTap: onClose,
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
}
