import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/account_deletion.dart';
import '../../core/app_state.dart';
import '../../core/micro_sound.dart';
import '../../core/zmayy_colors.dart';
import '../../data/models/profile.dart';
import '../../services/user_service.dart';
import '../../widgets/danger_banner.dart';
import '../../widgets/premium_buttons.dart';

class SettingsHomeScreen extends StatefulWidget {
  const SettingsHomeScreen({super.key, required this.sessionUserId});

  final String sessionUserId;

  @override
  State<SettingsHomeScreen> createState() => _SettingsHomeScreenState();
}

class _SettingsHomeScreenState extends State<SettingsHomeScreen> {
  Profile? profile;
  bool loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final UserService users = context.read<UserService>();
    final ZmayyAppState app = context.read<ZmayyAppState>();
    final Profile? row = await users.fetchProfileByUuid(widget.sessionUserId);
    await app.refreshCurrentProfile();
    if (!mounted) return;
    setState(() {
      profile = row ?? app.currentProfile;
      loadingProfile = false;
    });
  }

  Future<void> _toggleGhost(bool next) async {
    final ZmayyAppState app = context.read<ZmayyAppState>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await app.commitGhostPreference(nextGhostEnabled: next);
    await MicroSounds.playToggleDoublePop();
    if (!mounted) return;
    final message = next
        ? 'Mode Hantu Aktif — lokasimu tersembunyi.'
        : 'Mode Hantu Nonaktif — lokasimu terlihat oleh teman.';
    messenger.showSnackBar(SnackBar(content: Text(message)));
    await _load();
  }

  Future<void> _persistPublic(bool flag) async {
    if (profile == null || !mounted) return;
    final profileId = profile?.id;
    if (profileId == null) return;
    final UserService svc = context.read<UserService>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    await svc.updatePublicProfile(profileId: profileId, isPublic: flag);
    final String copy = flag
        ? 'Profil sekarang publik — sekitar ±1 km dapat melihatmu.'
        : 'Profil sekarang privat — hanya teman melihat lokasi.';
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(copy)));
    await _load();
  }

  Future<void> _patchNotification(String key, bool value) async {
    if (profile == null || !mounted) return;
    final profileId = profile?.id;
    if (profileId == null) return;
    final UserService svc = context.read<UserService>();
    final ZmayyAppState appState = context.read<ZmayyAppState>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (key == 'global') {
      await svc.patchNotificationMatrix(profileId: profileId, notifyGlobal: value);
    } else if (key == 'requests') {
      await svc.patchNotificationMatrix(profileId: profileId, notifyRequests: value);
    } else if (key == 'messages') {
      await svc.patchNotificationMatrix(profileId: profileId, notifyMessages: value);
    } else if (key == 'sound') {
      await svc.patchNotificationMatrix(profileId: profileId, notifySound: value);
    }
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Pengaturan disimpan.')));
    await _load();
    if (!mounted) return;
    await appState.refreshCurrentProfile();
  }

  Future<void> _signOut() async {
    await context.read<ZmayyAppState>().signOutCascade();
  }

  Future<void> _openDeleteFlow() async {
    final bool? deleted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ZmayyColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (BuildContext ctx) => const AccountDeletionSheet(),
    );

    if (deleted == true && mounted) {
      await context.read<ZmayyAppState>().signOutCascade();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akun dihapus. Sesi Anda telah diakhiri.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loadingProfile) {
      return const Center(child: CircularProgressIndicator(color: ZmayyColors.gold));
    }

    final bool ghost = context.watch<ZmayyAppState>().badgesMaskedForGhostMode;
    final bool isPublic = profile?.isPublic ?? true;
    final String display = profile?.displayName ?? profile?.username ?? 'Akun';
    final String handle = profile?.username ?? '—';
    final String link = 'https://zmayy.com/u/${widget.sessionUserId}';

    return ListView(
      padding: EdgeInsets.fromLTRB(
        18,
        22,
        18,
        MediaQuery.paddingOf(context).bottom + kBottomNavigationBarHeight + 18,
      ),
      children: [
        Text(display, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text('@$handle', style: const TextStyle(color: ZmayyColors.muted)),
        const SizedBox(height: 16),
        SizedBox(
          width: 164,
          height: 164,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: QrImageView(
              data: link,
              version: QrVersions.auto,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: ZmayyColors.base,
              ),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square),
            ),
          ),
        ),
        const SizedBox(height: 16),
        OutlineMutedButton(
          label: 'Salin tautan profil',
          onPressed: () async {
            final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
            await Clipboard.setData(ClipboardData(text: link));
            if (!mounted) return;
            messenger.showSnackBar(const SnackBar(content: Text('Tautan disalin')));
          },
        ),
        const SizedBox(height: 18),
        SwitchListTile.adaptive(
          value: ghost,
          activeTrackColor: ZmayyColors.gold.withAlpha(120),
          inactiveThumbColor: ZmayyColors.muted,
          inactiveTrackColor: ZmayyColors.border,
          thumbColor:
              WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> s) =>
                  ZmayyColors.gold),
          title: const Text('Mode Hantu'),
          subtitle: Text(ghost ? 'Lokasimu disembunyikan' : 'Lokasimu terlihat oleh teman.'),
          onChanged: _toggleGhost,
        ),
        SwitchListTile.adaptive(
          value: isPublic,
          activeTrackColor: ZmayyColors.gold.withAlpha(120),
          inactiveThumbColor: ZmayyColors.muted,
          inactiveTrackColor: ZmayyColors.border,
          thumbColor:
              WidgetStateProperty.resolveWith<Color?>((_) => ZmayyColors.gold),
          title: const Text('Profil Publik'),
          subtitle: Text(isPublic ? 'Sekitar ±1 km dapat melihatmu.' : 'Hanya teman melihat lokasimu.'),
          onChanged: _persistPublic,
        ),
        const Divider(color: ZmayyColors.border, height: 32),
        const Text('Notifikasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        _notifyTile(
          'Utama',
          'Izinkan notifikasi inti.',
          profile?.notifyGlobal ?? profile?.notificationsEnabled ?? true,
          (bool v) => _patchNotification('global', v),
        ),
        _notifyTile(
          'Permintaan',
          'Notifikasi permintaan teman.',
          profile?.notifyRequests ?? true,
          (bool v) => _patchNotification('requests', v),
        ),
        _notifyTile(
          'Pesan Chat',
          'Notifikasi pesan masuk.',
          profile?.notifyMessages ?? true,
          (bool v) => _patchNotification('messages', v),
        ),
        _notifyTile(
          'Suara',
          'Putar suara ringan saat ada notifikasi.',
          profile?.notifySound ?? true,
          (bool v) => _patchNotification('sound', v),
        ),
        const Divider(color: ZmayyColors.border, height: 32),
        ListTile(
          leading: const Icon(Icons.delete_outline, color: ZmayyColors.danger),
          title: const Text(
            'Hapus akun secara permanen',
            style: TextStyle(color: ZmayyColors.danger),
          ),
          subtitle: const Text(
            'Tindakan tidak dapat dibatalkan.',
            style: TextStyle(fontSize: 12),
          ),
          onTap: _openDeleteFlow,
        ),
        const SizedBox(height: 24),
        OutlineMutedButton(label: 'Keluar', onPressed: _signOut),
      ],
    );
  }

  Widget _notifyTile(String title, String subtitle, bool value, ValueChanged<bool> push) {
    return SwitchListTile.adaptive(
      value: value,
      activeTrackColor: ZmayyColors.gold.withAlpha(120),
      inactiveThumbColor: ZmayyColors.muted,
      inactiveTrackColor: ZmayyColors.border,
      thumbColor:
          WidgetStateProperty.resolveWith<Color?>((_) => ZmayyColors.gold),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: ZmayyColors.muted)),
      onChanged: push,
    );
  }
}

class AccountDeletionSheet extends StatefulWidget {
  const AccountDeletionSheet({super.key});

  @override
  State<AccountDeletionSheet> createState() => _AccountDeletionSheetState();
}

class _AccountDeletionSheetState extends State<AccountDeletionSheet> {
  int step = 0;
  String phrase = '';
  bool working = false;

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (step == 0) {
      body = DangerAttentionBanner(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Konfirmasi diperlukan',
              style: TextStyle(fontWeight: FontWeight.bold, color: ZmayyColors.danger),
            ),
            SizedBox(height: 8),
            Text('Ini akan menghapus profil, teman, lokasi, dan pesan Anda selamanya.'),
          ],
        ),
      );
    } else if (step == 1) {
      body = DangerAttentionBanner(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Konfirmasi akhir kedua:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Kalian menghapus data permanen.'),
          ],
        ),
      );
    } else {
      body = DangerAttentionBanner(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ketik "HAPUS" untuk menghapus permanen.'),
            const SizedBox(height: 12),
            TextField(
              onChanged: (String v) => setState(() => phrase = v),
              decoration: const InputDecoration(labelText: 'HAPUS', filled: true),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
        left: 18,
        right: 18,
        top: 16,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Privasi & Keamanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              body,
              const SizedBox(height: 18),
              if (step < 2) ...[
                Row(
                  children: [
                    Expanded(
                      child:
                          OutlineMutedButton(label: 'Batal', onPressed: () => Navigator.maybePop(context)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DangerElevatedChip(
                        label: step == 0 ? 'Lanjutkan' : 'Konfirmasi',
                        onPressed: () => setState(() => step += 1),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child:
                          OutlineMutedButton(label: 'Batal', onPressed: () => Navigator.maybePop(context)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DangerElevatedChip(
                        label: 'Hapus Sekarang',
                        busy: working,
                        onPressed: phrase.trim() == accountDeletionConfirmWord && !working
                            ? () async {
                                setState(() => working = true);
                                try {
                                  await context.read<UserService>().deleteUserAccountViaRpc();
                                  if (!context.mounted) return;
                                  Navigator.of(context).pop(true);
                                } catch (error) {
                                  if (!context.mounted) return;
                                  setState(() => working = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Gagal menghapus: $error')),
                                  );
                                }
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
