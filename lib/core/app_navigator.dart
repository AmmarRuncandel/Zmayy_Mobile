import 'package:flutter/material.dart';
import '../features/auth/login_screen.dart';
import 'secure_storage.dart';

class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void goToLogin() {
    try {
      final nav = navigatorKey.currentState;
      if (nav == null) return;
      // Clear stored credentials before navigating
      SecureStorage.deleteToken();
      SecureStorage.deleteUser();
      SecureStorage.deleteProfile();

      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (r) => false,
      );
    } catch (_) {}
  }
}
