import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/app_state.dart';
import '../../core/secure_storage.dart';
import '../../data/models/user_profile.dart';
import '../auth/login_screen.dart';

class ProfilePanel extends StatelessWidget {
  final VoidCallback onClose;
  const ProfilePanel({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<ZmayyAppState>(context);
    final profile = appState.currentProfile;

    return Container(
      color: const Color(0xFF0B0E11),
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, profile),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildAvatar(profile),
                    const SizedBox(height: 14),
                    _buildUserInfo(profile),
                    const SizedBox(height: 28),
                    _buildSettingsCard(context, appState, profile),
                    const SizedBox(height: 20),
                    _buildQrSection(profile),
                    const SizedBox(height: 24),
                    _buildLogoutButton(context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, UserProfile? profile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 8),
      child: Row(
        children: [
          // Zmayy mini logo
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF12151B),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Color(0x33FCD535), blurRadius: 12),
              ],
            ),
            padding: const EdgeInsets.all(5),
            child: Image.asset('assets/images/zmay_logo.png', fit: BoxFit.contain),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1F27),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close, color: Colors.white70, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Avatar ─────────────────────────────────────────────────────────────────
  Widget _buildAvatar(UserProfile? profile) {
    final initials = profile?.initials ?? 'ZM';
    return Container(
      width: 80,
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFFFCD535),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF0B0E11),
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ── User info ──────────────────────────────────────────────────────────────
  Widget _buildUserInfo(UserProfile? profile) {
    final username = profile?.username ?? '—';
    final handle = '@${profile?.username.toLowerCase().replaceAll(' ', '') ?? '—'}';
    final email = profile?.email ?? '—';

    return Column(
      children: [
        Text(
          username,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(handle,
                style: const TextStyle(color: Color(0xFF848E9C), fontSize: 13)),
            const SizedBox(width: 6),
            const Icon(Icons.edit_outlined, color: Color(0xFF848E9C), size: 14),
          ],
        ),
        const SizedBox(height: 4),
        Text(email,
            style: const TextStyle(color: Color(0xFF848E9C), fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: Color(0xFF22C55E), shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            const Text('Online',
                style: TextStyle(color: Color(0xFF22C55E), fontSize: 13)),
          ],
        ),
      ],
    );
  }

  // ── Settings card ──────────────────────────────────────────────────────────
  Widget _buildSettingsCard(
      BuildContext context, ZmayyAppState appState, UserProfile? profile) {
    final isGhost = profile?.isGhostMode ?? false;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181A20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B2F36)),
      ),
      child: Column(
        children: [
          _buildSettingRow(
            icon: Icons.remove_red_eye_outlined,
            title: 'Mode Hantu',
            subtitle: 'Sembunyikan lokasi dari teman',
            trailing: Switch(
              value: isGhost,
              onChanged: profile == null
                  ? null
                  : (val) async {
                      final updated = profile.copyWith(isGhostMode: val);
                      await appState.updateProfileField(updated);
                    },
              activeThumbColor: const Color(0xFFFCD535),
              activeTrackColor: const Color(0xFFD4AC1A),
              inactiveThumbColor: Colors.white54,
              inactiveTrackColor: const Color(0xFF2B2F36),
            ),
            showDivider: true,
          ),
          _buildSettingRow(
            icon: Icons.location_on_outlined,
            title: 'Berbagi Lokasi',
            subtitle: 'Teman & Sekitar (1km)',
            trailing: const Icon(Icons.chevron_right,
                color: Color(0xFF848E9C), size: 20),
            showDivider: true,
          ),
          _buildSettingRow(
            icon: Icons.notifications_outlined,
            title: 'Notifikasi',
            subtitle: 'Semua aktif',
            trailing: const Icon(Icons.chevron_right,
                color: Color(0xFF848E9C), size: 20),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pengaturan notifikasi — segera hadir'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            showDivider: true,
          ),
          _buildSettingRow(
            icon: Icons.shield_outlined,
            title: 'Privasi & Keamanan',
            subtitle: 'Kelola data & pemblokiran',
            trailing: const Icon(Icons.chevron_right,
                color: Color(0xFF848E9C), size: 20),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pengaturan privasi — segera hadir'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    bool showDivider = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF848E9C), size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              color: Color(0xFF848E9C), fontSize: 12)),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
          if (showDivider)
            const Divider(
                height: 1, thickness: 1, color: Color(0xFF2B2F36),
                indent: 50, endIndent: 0),
        ],
      ),
    );
  }

  // ── QR Section ─────────────────────────────────────────────────────────────
  Widget _buildQrSection(UserProfile? profile) {
    final handle = '@${profile?.username.toLowerCase().replaceAll(' ', '') ?? '—'}';
    final profileUrl =
        'https://zmayy.vercel.app/u/${profile?.id ?? ''}';
    final qrUrl =
        'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=${Uri.encodeComponent(profileUrl)}&bgcolor=FFFFFF&color=0B0E11&margin=4';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181A20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2B2F36)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_scanner,
                  color: Color(0xFF848E9C), size: 16),
              const SizedBox(width: 8),
              const Text(
                'PINDAI UNTUK TERHUBUNG',
                style: TextStyle(
                    color: Color(0xFF848E9C),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // QR Code
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    qrUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => const Center(
                      child: Icon(Icons.qr_code_2,
                          color: Color(0xFF0B0E11), size: 48),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(handle,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        await Clipboard.setData(
                            ClipboardData(text: profileUrl));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12151B),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: const Color(0xFF2B2F36)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link,
                                color: Color(0xFF848E9C), size: 14),
                            SizedBox(width: 6),
                            Text('Salin Tautan Profil',
                                style: TextStyle(
                                    color: Color(0xFF848E9C),
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                            color: Color(0xFF848E9C), fontSize: 11),
                        children: [
                          TextSpan(text: 'Pindai dengan '),
                          TextSpan(
                            text: 'Zmayy Mobile',
                            style:
                                TextStyle(color: Color(0xFFFCD535)),
                          ),
                          TextSpan(
                              text: ' atau ketuk ponsel melalui '),
                          TextSpan(
                            text: 'NFC.',
                            style:
                                TextStyle(color: Color(0xFFFCD535)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // NFC / share — Phase 4
              },
              icon: const Icon(Icons.nfc,
                  color: Color(0xFFFCD535), size: 16),
              label: const Text('Bagikan via NFC',
                  style: TextStyle(
                      color: Color(0xFFFCD535),
                      fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFCD535)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await SecureStorage.clearAll();
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (r) => false,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF181A20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2B2F36)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Color(0xFFEF4444), size: 18),
            SizedBox(width: 10),
            Text(
              'Keluar',
              style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                  fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
