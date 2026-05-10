import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'core/zmayy_colors.dart';
import 'features/chat/chat_panel.dart';
import 'features/friends/friends_screen.dart';
import 'features/map/map_screen.dart';
import 'features/settings/settings_screen.dart';

/// Bottom navigation scaffold — **`MapViewInner`**, chat lobby, **`FriendsPanel`**, settings parity.
final class ZmayyAppShell extends StatefulWidget {
  const ZmayyAppShell({super.key, required this.sessionUserId});

  final String sessionUserId;

  @override
  State<ZmayyAppShell> createState() => _ZmayyAppShellState();
}

class _ZmayyAppShellState extends State<ZmayyAppShell> {
  int _index = 0;

  Future<void> _openThread(String peerId, ConversationPeerBrief brief) async {
    setState(() => _index = 1);
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ConversationThreadScreen(peerId: peerId, peer: brief),
      ),
    );
  }

  void _jumpMapAndFly(String uuid) {
    setState(() => _index = 0);
    context.read<ZmayyAppState>().requestFlyToProfileId(uuid);
  }

  @override
  Widget build(BuildContext context) {
    final List<NavigationDestination> docks = [
      NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map_rounded), label: 'Map'),
      NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_rounded), label: 'Chat'),
      NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups_rounded), label: 'Teman'),
      NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Akun'),
    ];

    return Scaffold(
      backgroundColor: ZmayyColors.base,
      body: IndexedStack(
        index: _index,
        children: [
          const MapScreen(),
          ConversationLobbyScreen(sessionUserId: widget.sessionUserId),
          FriendsHomeScreen(
            sessionUserId: widget.sessionUserId,
            locatePeer: _jumpMapAndFly,
            beginChat: _openThread,
          ),
          SettingsHomeScreen(sessionUserId: widget.sessionUserId),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: ZmayyColors.gold.withAlpha(45),
          backgroundColor: ZmayyColors.surface,
          elevation: 0,
          iconTheme:
              WidgetStateProperty.resolveWith<IconThemeData?>((Set<WidgetState> s) =>
                  IconThemeData(color: s.contains(WidgetState.selected) ? ZmayyColors.gold : ZmayyColors.muted)),
          labelTextStyle:
              WidgetStateProperty.resolveWith<TextStyle?>((Set<WidgetState> s) =>
                  TextStyle(
                    fontSize: 12,
                    fontWeight:
                        s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w400,
                  )),
        ),
        child: NavigationBar(
          surfaceTintColor: Colors.transparent,
          selectedIndex: _index,
          onDestinationSelected: (int next) => setState(() => _index = next),
          destinations: docks,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        ),
      ),
    );
  }
}
