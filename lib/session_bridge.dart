import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_state.dart';

/// Keeps [ZmayyAppState] aligned with Supabase **`auth`** (attach on sign-in / purge on sign-out).
final class SessionBridge extends StatefulWidget {
  const SessionBridge({super.key, required this.child});

  final Widget child;

  @override
  State<SessionBridge> createState() => _SessionBridgeState();
}

class _SessionBridgeState extends State<SessionBridge> {
  StreamSubscription<AuthState>? _stream;

  @override
  void initState() {
    super.initState();
    _stream =
        Supabase.instance.client.auth.onAuthStateChange.listen((AuthState data) async {
      await _mirrorSession(data.session);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _mirrorSession(Supabase.instance.client.auth.currentSession);
    });
  }

  Future<void> _mirrorSession(Session? session) async {
    final String? id = session?.user.id;
    if (!mounted) return;
    final ZmayyAppState appState = context.read<ZmayyAppState>();

    if (id != null) {
      if (appState.authenticatedUserId != id) {
        appState.attachAuthenticatedUser(id);
        
        // Delay untuk ensure session established (equiv Next.js login delay)
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (!mounted) return;
        await appState.refreshCurrentProfile();
        try {
          await appState.startSpatialTracking();
        } catch (error, stack) {
          debugPrint('$error\n$stack');
        }
      }
    } else if (appState.authenticatedUserId != null) {
      // Session was cleared (logout)
      await appState.signOutCascade();
    }
  }

  @override
  void dispose() {
    _stream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
