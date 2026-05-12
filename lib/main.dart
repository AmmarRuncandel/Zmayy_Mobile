                                            import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'core/app_navigator.dart';
import 'features/splash/splash_screen.dart';
import 'core/app_state.dart';
import 'data/repositories/map_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/profile_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ZmayyApp());
}

class ZmayyApp extends StatelessWidget {
  const ZmayyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mapRepo = MapRepository();
    final chatRepo = ChatRepository();
    final profileRepo = ProfileRepository();

    return MultiProvider(
      providers: [
        Provider<MapRepository>.value(value: mapRepo),
        Provider<ChatRepository>.value(value: chatRepo),
        Provider<ProfileRepository>.value(value: profileRepo),
        ChangeNotifierProvider<ZmayyAppState>(create: (_) => ZmayyAppState(mapRepository: mapRepo, chatRepository: chatRepo, profileRepository: profileRepo)),
      ],
      child: MaterialApp(
        navigatorKey: AppNavigator.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Zmayy',
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
