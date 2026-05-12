import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_state.dart';
import '../../core/secure_storage.dart';
import '../../core/biometric_helper.dart';
import '../../core/biometric_storage.dart';
import '../../core/elegant_dialog.dart';
import '../../data/models/user_profile.dart';
import '../auth/login_screen.dart';

class ProfilePanel extends StatefulWidget {
  final VoidCallback onClose;
  const ProfilePanel({super.key, required this.onClose});

  @override
  State<ProfilePanel> createState() => _ProfilePanelState();
}

class _ProfilePanelState extends State<ProfilePanel> {
  bool _showDeleteConfirm = false;

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
            onTap: widget.onClose,
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
    final displayName = profile?.effectiveName ?? '—';
    final handle = '@${profile?.username.toLowerCase().replaceAll(' ', '') ?? '—'}';
    final email = profile?.email ?? '—';

    return Column(
      children: [
        Text(
          displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: profile == null
              ? null
              : () async {
                  // Capture appState before awaiting dialog to avoid using BuildContext across async gaps
                  final appState = Provider.of<ZmayyAppState>(context, listen: false);

                  final result = await ElegantDialog.showInput(
                    context: context,
                    title: 'Ubah Nama',
                    hint: 'Nama tampil',
                    initialValue: profile.displayName ?? profile.username,
                    confirmText: 'Simpan',
                    cancelText: 'Batal',
                  );

                  if (result != null && result.isNotEmpty) {
                    // CELAH LOGIKA KRITIS #2: Defensif Payload Sinkronisasi Profil
                    // Kirim payload ganda untuk kompatibilitas dengan skema Supabase
                    final updated = profile.copyWith(
                      username: result,      // Update username (field bawaan Supabase)
                      displayName: result,   // Update display_name (field custom)
                    );
                    await appState.updateProfileField(updated);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama berhasil diperbarui'), behavior: SnackBarBehavior.floating));
                  }
                },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(handle,
                  style: const TextStyle(color: Color(0xFF848E9C), fontSize: 13)),
              const SizedBox(width: 6),
              const Icon(Icons.edit_outlined, color: Color(0xFF848E9C), size: 14),
            ],
          ),
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
                      await appState.setGhostMode(val);
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
            onTap: () {
              _showLocationSharingDialog(context, appState, profile);
            },
            showDivider: true,
          ),
          _buildSettingRow(
            icon: Icons.notifications_outlined,
            title: 'Notifikasi',
            subtitle: 'Semua aktif',
            trailing: const Icon(Icons.chevron_right,
                color: Color(0xFF848E9C), size: 20),
            onTap: () {
              _showNotificationsDialog(context, appState, profile);
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
              _showPrivacyDialog(context, appState, profile);
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
    final profileUrl = 'https://zmayy.vercel.app/profile/${profile?.username ?? ''}';

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
              // QR Code - Dynamic with qr_flutter
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(4),
                child: QrImageView(
                  data: profileUrl,
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0B0E11),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0B0E11),
                  ),
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
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
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tautan profil berhasil disalin.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
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
                            text: 'Zmayy',
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
                _showNfcDemoModal(profileUrl);
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

  Future<void> _showNotificationsDialog(
    BuildContext context,
    ZmayyAppState appState,
    UserProfile? profile,
  ) async {
    if (profile == null) return;
    bool enabled = profile.notifyGlobal;
    bool requests = profile.notifyRequests;
    bool messages = profile.notifyMessages;
    bool sound = profile.notifySound;

    final result = await showDialog<UserProfile>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: const Color(0xFF181A20),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF2B2F36), width: 1),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33FCD535),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 32,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Notifikasi',
                              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(dialogContext).pop(),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF12151B),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF2B2F36)),
                              ),
                              child: const Icon(Icons.close, color: Color(0xFF848E9C), size: 18),
                            ),
                          ),
                        ],
                      ),
                    const Divider(color: Color(0xFF2B2F36), height: 1),
                    const SizedBox(height: 12),
                    _dialogToggle(
                      title: 'Aktifkan Notifikasi',
                      subtitle: 'Aktifkan atau matikan semua notifikasi',
                      value: enabled,
                      onChanged: (value) async {
                        setModalState(() => enabled = value);
                        await appState.updateProfileField(profile.copyWith(notifyGlobal: value));
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('JENIS NOTIFIKASI', style: TextStyle(color: Color(0xFF848E9C), fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    _dialogToggle(
                      title: 'Permintaan Teman',
                      subtitle: 'Saat seseorang mengirim permintaan pertemanan',
                      value: requests,
                      enabled: enabled,
                      onChanged: (value) async {
                        if (!enabled) return;
                        setModalState(() => requests = value);
                        await appState.updateProfileField(profile.copyWith(notifyRequests: value));
                      },
                    ),
                    const SizedBox(height: 10),
                    _dialogToggle(
                      title: 'Pesan',
                      subtitle: 'Pesan chat baru dari teman',
                      value: messages,
                      enabled: enabled,
                      onChanged: (value) async {
                        if (!enabled) return;
                        setModalState(() => messages = value);
                        await appState.updateProfileField(profile.copyWith(notifyMessages: value));
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('SUARA', style: TextStyle(color: Color(0xFF848E9C), fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    _dialogToggle(
                      title: 'Suara Notifikasi',
                      subtitle: 'Putar suara saat ada notifikasi baru',
                      value: sound,
                      enabled: enabled,
                      onChanged: (value) async {
                        if (!enabled) return;
                        setModalState(() => sound = value);
                        await appState.updateProfileField(profile.copyWith(notifySound: value));
                      },
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(
                          profile.copyWith(
                            notifyGlobal: enabled,
                            notifyRequests: requests,
                            notifyMessages: messages,
                            notifySound: sound,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B2F36),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

    if (result != null && mounted) {
      setState(() {});
    }
  }

  Future<void> _showPrivacyDialog(
    BuildContext context,
    ZmayyAppState appState,
    UserProfile? profile,
  ) async {
    if (profile == null) return;
    bool isPublic = profile.isPublic;
    _showDeleteConfirm = false;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: const Color(0xFF181A20),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF2B2F36), width: 1),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33FCD535),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 32,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Privasi & Keamanan',
                              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(dialogContext).pop(),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFF12151B),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF2B2F36)),
                              ),
                              child: const Icon(Icons.close, color: Color(0xFF848E9C), size: 18),
                            ),
                          ),
                        ],
                      ),
                    const Divider(color: Color(0xFF2B2F36), height: 1),
                    const SizedBox(height: 12),
                    const Text('VISIBILITAS', style: TextStyle(color: Color(0xFF848E9C), fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    _dialogToggle(
                      title: 'Profil Publik',
                      subtitle: 'Izinkan pengguna di sekitar (+1 km) melihat kamu di peta',
                      value: isPublic,
                      onChanged: (value) async {
                        setModalState(() => isPublic = value);
                        await appState.updateProfileField(profile.copyWith(isPublic: value));
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('KEAMANAN', style: TextStyle(color: Color(0xFF848E9C), fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    FutureBuilder<bool>(
                      future: BiometricStorage.isBiometricChatEnabled(),
                      builder: (context, snapshot) {
                        final biometricEnabled = snapshot.data ?? false;
                        return _dialogToggle(
                          title: 'Proteksi Sidik Jari untuk Obrolan',
                          subtitle: 'Wajibkan autentikasi biometrik saat membuka obrolan',
                          value: biometricEnabled,
                          onChanged: (value) async {
                            if (value) {
                              // Check if device supports biometric
                              final isSupported = await BiometricHelper.isDeviceSupported();
                              if (!isSupported) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Perangkat tidak mendukung autentikasi biometrik')),
                                );
                                return;
                              }
                              // Test biometric authentication
                              final authenticated = await BiometricHelper.authenticate();
                              if (authenticated) {
                                await BiometricStorage.enableBiometricChat();
                                setModalState(() {});
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Proteksi sidik jari diaktifkan')),
                                );
                              } else {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Autentikasi gagal')),
                                );
                              }
                            } else {
                              await BiometricStorage.disableBiometricChat();
                              setModalState(() {});
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Proteksi sidik jari dinonaktifkan')),
                              );
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('AKUN', style: TextStyle(color: Color(0xFF848E9C), fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => setModalState(() => _showDeleteConfirm = !_showDeleteConfirm),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A1313),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF7F1D1D)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline, color: Color(0xFFF87171)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Hapus Akun', style: TextStyle(color: Color(0xFFF87171), fontSize: 15, fontWeight: FontWeight.w700)),
                                  SizedBox(height: 2),
                                  Text('Hapus akun dan semua data secara permanen', style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showDeleteConfirm) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3A1515),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFB91C1C)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hapus Akun Secara Permanen?',
                              style: TextStyle(color: Color(0xFFF87171), fontWeight: FontWeight.w800, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tindakan ini tidak dapat dibatalkan. Seluruh data profil, teman, pesan, dan lokasi akan dihapus selamanya.',
                              style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setModalState(() => _showDeleteConfirm = false),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFF7F1D1D)),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Batal'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Endpoint hapus akun belum tersedia di mobile API.'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFDC2626),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Lanjutkan'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2B2F36),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
  }

  Widget _dialogToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: enabled ? const Color(0xFF848E9C) : const Color(0xFF5B6170),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: const Color(0xFFFCD535),
            activeTrackColor: const Color(0xFFD4AC1A),
            inactiveThumbColor: Colors.white54,
            inactiveTrackColor: const Color(0xFF2B2F36),
          ),
        ],
      ),
    );
  }

  // ── NFC Demo Modal ─────────────────────────────────────────────────────────
  void _showNfcDemoModal(String profileUrl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF181A20),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: const Border(
            top: BorderSide(color: Color(0xFF2B2F36), width: 1),
            left: BorderSide(color: Color(0xFF2B2F36), width: 1),
            right: BorderSide(color: Color(0xFF2B2F36), width: 1),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33FCD535),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2B2F36),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFCD535).withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFCD535).withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(Icons.nfc, color: Color(0xFFFCD535), size: 40),
            ),
            const SizedBox(height: 20),
            // Title
            const Text(
              'Fitur NFC Aktif',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            // Description
            const Text(
              'Tempelkan bagian belakang ponsel ke perangkat Zmayy lain untuk mentransfer profil.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Animated pulse
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.2),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeInOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFCD535).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCD535).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.phone_android,
                          color: Color(0xFFFCD535),
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                );
              },
              onEnd: () {
                // Loop animation
                if (mounted) {
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  nav.pop();
                  Clipboard.setData(ClipboardData(text: profileUrl)).then((_) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Tautan profil disalin sebagai alternatif.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFCD535),
                  foregroundColor: const Color(0xFF0B0E11),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Salin Tautan Sebagai Alternatif',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Location Sharing Dialog ────────────────────────────────────────────────
  Future<void> _showLocationSharingDialog(
    BuildContext context,
    ZmayyAppState appState,
    UserProfile? profile,
  ) async {
    if (profile == null) return;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF181A20),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF2B2F36), width: 1),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33FCD535),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 32,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Berbagi Lokasi',
                        style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF12151B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF2B2F36)),
                        ),
                        child: const Icon(Icons.close, color: Color(0xFF848E9C), size: 18),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF2B2F36), height: 1),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF12151B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2B2F36)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFFFCD535), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Lokasi Anda dibagikan secara real-time ke teman dan pengguna dalam radius 1 km.',
                          style: TextStyle(color: Color(0xFF848E9C), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'PENGATURAN SAAT INI',
                  style: TextStyle(color: Color(0xFF848E9C), fontSize: 11, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _infoRow(Icons.people, 'Teman', 'Selalu terlihat'),
                const SizedBox(height: 10),
                _infoRow(Icons.public, 'Pengguna Sekitar', 'Dalam radius 1 km'),
                const SizedBox(height: 10),
                _infoRow(Icons.update, 'Pembaruan', 'Setiap 30 detik'),
                const SizedBox(height: 16),
                const Text(
                  'Gunakan Mode Hantu untuk menyembunyikan lokasi Anda dari semua pengguna.',
                  style: TextStyle(color: Color(0xFF848E9C), fontSize: 12, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2B2F36),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  }

  Widget _infoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF848E9C), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: const TextStyle(color: Color(0xFFFCD535), fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
