import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_shell.dart';
import 'core/app_state.dart';
import 'core/app_theme.dart';
import 'data/zmayy_supabase.dart';
import 'features/auth/login_screen.dart';
import 'services/chat_service.dart';
import 'services/friends_service.dart';
import 'services/location_service.dart';
import 'services/map_service.dart';
import 'services/user_service.dart';
import 'session_bridge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ZmayySupabase.initializeIfConfigured();
  runApp(const ZmayyBootstrap());
}

/// Roots the tree with `MultiProvider` (services + [ZmayyAppState]), then binds auth.
final class ZmayyBootstrap extends StatelessWidget {
  const ZmayyBootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    if (!ZmayySupabase.isReady) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Zmayy',
        themeMode: ThemeMode.dark,
        theme: buildZmayyDarkTheme(),
        home: const _CredentialHintGate(),
      );
    }

    return MultiProvider(
      providers: [
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<MapService>(create: (_) => MapService(ZmayySupabase.client)),
        Provider<ChatService>(create: (_) => ChatService(ZmayySupabase.client)),
        Provider<UserService>(create: (_) => UserService(ZmayySupabase.client)),
        Provider<FriendsService>(create: (_) => FriendsService(ZmayySupabase.client)),
        ChangeNotifierProvider<ZmayyAppState>(
          create: (BuildContext ctx) {
            return ZmayyAppState(
              locationService: ctx.read<LocationService>(),
              mapService: ctx.read<MapService>(),
              chatService: ctx.read<ChatService>(),
              userService: ctx.read<UserService>(),
            );
          },
        ),
      ],
      child: SessionBridge(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Zmayy',
          themeMode: ThemeMode.dark,
          theme: buildZmayyDarkTheme(),
          home: const AuthRouter(),
        ),
      ),
    );
  }
}

final class AuthRouter extends StatelessWidget {
  const AuthRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (BuildContext context, AsyncSnapshot<AuthState> snapshot) {
        final Session? session =
            snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
        final String? uid = session?.user.id;

        if (uid != null && uid.isNotEmpty) {
          return ZmayyAppShell(sessionUserId: uid);
        }
        return const LoginScreen();
      },
    );
  }
}

final class _CredentialHintGate extends StatelessWidget {
  const _CredentialHintGate();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Zmayy',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Add --dart-define=SUPABASE_URL and SUPABASE_ANON_KEY to connect.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
