import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_state.dart';
import 'features/map/map_screen.dart';
import 'features/friends/friends_panel.dart';
import 'features/chat/chat_list_panel.dart';
import 'features/profile/profile_panel.dart';

/// Panel indices
const int _kNoPanel = -1;
const int _kFriends = 0;
const int _kChat = 1;
const int _kProfile = 2;

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with TickerProviderStateMixin {
  int _activePanel = _kNoPanel;
  final GlobalKey<MapScreenState> _mapKey = GlobalKey<MapScreenState>();

  /// Slide controller — used for Teman & Obrolan (slide from left)
  late final AnimationController _sideCtrl;
  late final Animation<Offset> _sideSlide;

  /// Slide controller — used for Profil (slide from bottom)
  late final AnimationController _profileCtrl;
  late final Animation<Offset> _profileSlide;

  @override
  void initState() {
    super.initState();

    _sideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _sideSlide = Tween<Offset>(
      begin: const Offset(-1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _sideCtrl, curve: Curves.easeOutCubic));

    _profileCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _profileSlide = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _profileCtrl, curve: Curves.easeOutCubic));

    // Load profile and bootstrap chat on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<ZmayyAppState>(context, listen: false);
      state.loadProfileFromStorage();
      state.loadChatHistory();
    });
  }

  @override
  void dispose() {
    _sideCtrl.dispose();
    _profileCtrl.dispose();
    super.dispose();
  }

  // ── Navigation logic ───────────────────────────────────────────────────────

  Future<void> _onNavTap(int index) async {
    // Same tab tapped → close
    if (_activePanel == index) {
      await _closeActive();
      return;
    }

    // Currently a side panel open, switching to profile
    if (_activePanel != _kNoPanel &&
        _activePanel != _kProfile &&
        index == _kProfile) {
      await _sideCtrl.reverse();
      setState(() => _activePanel = _kProfile);
      _profileCtrl.forward();
      return;
    }

    // Currently profile open, switching to a side panel
    if (_activePanel == _kProfile && index != _kProfile) {
      await _profileCtrl.reverse();
      setState(() => _activePanel = index);
      _sideCtrl.forward();
      return;
    }

    // Both side panels — just swap content, no re-animation
    if (_activePanel != _kNoPanel &&
        _activePanel != _kProfile &&
        index != _kProfile) {
      setState(() => _activePanel = index);
      return;
    }

    // Nothing open → open new panel
    setState(() => _activePanel = index);
    if (index == _kProfile) {
      _profileCtrl.forward();
    } else {
      _sideCtrl.forward();
    }
  }

  Future<void> _closeActive() async {
    if (_activePanel == _kProfile) {
      await _profileCtrl.reverse();
    } else {
      await _sideCtrl.reverse();
    }
    if (mounted) setState(() => _activePanel = _kNoPanel);
  }

  void _closePanel() {
    _closeActive();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      body: Stack(
        children: [
          // Layer 0 — Map always visible as background
          MapScreen(key: _mapKey),

          // Layer 1 — Dim backdrop when any panel is open
          if (_activePanel != _kNoPanel)
            GestureDetector(
              onTap: _closePanel,
              child: AnimatedOpacity(
                opacity: _activePanel != _kNoPanel ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(color: Colors.black54),
              ),
            ),

          // Layer 2 — Side panel (Teman or Obrolan), slides from left
          if (_activePanel == _kFriends || _activePanel == _kChat)
            SlideTransition(
              position: _sideSlide,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.85,
                  child: _activePanel == _kFriends
                      ? FriendsPanel(onClose: _closePanel)
                      : ChatListPanel(onClose: _closePanel),
                ),
              ),
            ),

          // Layer 3 — Profile panel, slides from bottom, full screen
          if (_activePanel == _kProfile)
            SlideTransition(
              position: _profileSlide,
              child: ProfilePanel(onClose: _closePanel),
            ),

          // Layer 4 — Recenter button (hidden when profile panel is open)
          if (_activePanel != _kProfile)
            Positioned(
              right: 16,
              bottom: 128,
              child: _RecenterFab(
                onTap: () => _mapKey.currentState?.recenter(),
              ),
            ),

          // Layer 5 — Floating bottom navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: _buildBottomNav(),
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation Bar ──────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return SafeArea(
      top: false,
      child: Center(
        child: Container(
          width: 252,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF181A20).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 6)),
              BoxShadow(color: Color(0x18FCD535), blurRadius: 20),
            ],
          ),
          child: Row(
            children: [
              _navItem(index: _kFriends, icon: Icons.people_outline, activeIcon: Icons.people, label: 'Teman'),
              _navItem(index: _kChat, icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Obrolan'),
              _navItem(index: _kProfile, icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final active = _activePanel == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onNavTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                active ? activeIcon : icon,
                color: active
                    ? const Color(0xFFFCD535)
                    : const Color(0xFF848E9C),
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: active
                      ? const Color(0xFFFCD535)
                      : const Color(0xFF848E9C),
                  fontSize: 11,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: active ? 18 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFFCD535)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecenterFab extends StatelessWidget {
  final VoidCallback onTap;
  const _RecenterFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Color(0xFFFCD535),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x47FCD535),
              blurRadius: 22,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.navigation, color: Color(0xFF0B0E11), size: 22),
      ),
    );
  }
}
