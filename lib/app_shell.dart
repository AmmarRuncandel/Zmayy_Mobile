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

  /// Slide controller untuk Teman (slide from left)
  late final AnimationController _friendsCtrl;
  late final Animation<Offset> _friendsSlide;
  late final Animation<double> _friendsFade;

  /// Slide controller untuk Obrolan (slide from RIGHT - seperti web)
  late final AnimationController _chatCtrl;
  late final Animation<Offset> _chatSlide;
  late final Animation<double> _chatFade;

  /// Slide controller untuk Profil (slide from bottom)
  late final AnimationController _profileCtrl;
  late final Animation<Offset> _profileSlide;
  late final Animation<double> _profileFade;

  @override
  void initState() {
    super.initState();

    // Friends panel - slide from left with fade
    _friendsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _friendsSlide = Tween<Offset>(
      begin: const Offset(-1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _friendsCtrl,
      curve: Curves.easeOutCubic,
    ));
    _friendsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _friendsCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Chat panel - slide from RIGHT with fade (seperti web)
    _chatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _chatSlide = Tween<Offset>(
      begin: const Offset(1.0, 0), // Dari KANAN
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _chatCtrl,
      curve: Curves.easeOutCubic,
    ));
    _chatFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _chatCtrl,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Profile panel - slide from bottom with fade
    _profileCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _profileSlide = Tween<Offset>(
      begin: const Offset(0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _profileCtrl,
      curve: Curves.easeOutCubic,
    ));
    _profileFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _profileCtrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Load profile and bootstrap chat on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = Provider.of<ZmayyAppState>(context, listen: false);
      state.loadProfileFromStorage();
      state.loadChatHistory();
    });
  }

  @override
  void dispose() {
    _friendsCtrl.dispose();
    _chatCtrl.dispose();
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

    // Close current panel first
    if (_activePanel != _kNoPanel) {
      await _closeActive();
    }

    // Open new panel
    setState(() => _activePanel = index);
    if (index == _kFriends) {
      _friendsCtrl.forward();
    } else if (index == _kChat) {
      _chatCtrl.forward();
    } else if (index == _kProfile) {
      _profileCtrl.forward();
    }
  }

  Future<void> _closeActive() async {
    if (_activePanel == _kFriends) {
      await _friendsCtrl.reverse();
    } else if (_activePanel == _kChat) {
      await _chatCtrl.reverse();
    } else if (_activePanel == _kProfile) {
      await _profileCtrl.reverse();
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
                duration: const Duration(milliseconds: 250),
                child: Container(color: Colors.black.withValues(alpha: 0.6)),
              ),
            ),

          // Layer 2 — Friends panel (slide from LEFT with fade)
          if (_activePanel == _kFriends)
            FadeTransition(
              opacity: _friendsFade,
              child: SlideTransition(
                position: _friendsSlide,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.85,
                    child: FriendsPanel(
                      onClose: _closePanel,
                      onGoToLocation: (lat, lng) {
                        _mapKey.currentState?.panToLocation(lat, lng);
                      },
                    ),
                  ),
                ),
              ),
            ),

          // Layer 3 — Chat panel (slide from RIGHT with fade - seperti web)
          if (_activePanel == _kChat)
            FadeTransition(
              opacity: _chatFade,
              child: SlideTransition(
                position: _chatSlide,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.85,
                    child: ChatListPanel(onClose: _closePanel),
                  ),
                ),
              ),
            ),

          // Layer 4 — Profile panel (slide from bottom with fade, full screen)
          if (_activePanel == _kProfile)
            FadeTransition(
              opacity: _profileFade,
              child: SlideTransition(
                position: _profileSlide,
                child: ProfilePanel(onClose: _closePanel),
              ),
            ),

          // Layer 5 — Recenter button (hidden when profile panel is open)
          if (_activePanel != _kProfile)
            Positioned(
              right: 16,
              bottom: 128,
              child: _RecenterFab(
                onTap: () => _mapKey.currentState?.recenter(),
              ),
            ),

          // Layer 6 — Floating bottom navigation
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
            color: const Color(0xFF181A20).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: const Color(0xFFFCD535).withValues(alpha: 0.15),
                blurRadius: 32,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Row(
            children: [
              _navItem(
                index: _kFriends,
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: 'Teman',
              ),
              _navItem(
                index: _kChat,
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: 'Obrolan',
              ),
              _navItem(
                index: _kProfile,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profil',
              ),
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
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: active ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: Icon(
                  active ? activeIcon : icon,
                  color: active
                      ? const Color(0xFFFCD535)
                      : const Color(0xFF848E9C),
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: active
                      ? const Color(0xFFFCD535)
                      : const Color(0xFF848E9C),
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: active ? 20 : 0,
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
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFFFCD535),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFCD535).withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.my_location,
          color: Color(0xFF0B0E11),
          size: 24,
        ),
      ),
    );
  }
}
