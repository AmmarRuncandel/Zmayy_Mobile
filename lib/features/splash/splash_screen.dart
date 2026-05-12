import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_shell.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/secure_storage.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final AuthRepository _authRepository = AuthRepository();
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Hold splash for exactly 2 seconds
    Timer(const Duration(seconds: 2), _routeFromSession);
  }

  Future<void> _routeFromSession() async {
    final token = await SecureStorage.readToken();

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      _goToLogin();
      return;
    }

    try {
      await _authRepository.validateSession();
      if (!mounted) return;
      _goToAppShell();
    } catch (_) {
      await SecureStorage.deleteToken();
      await SecureStorage.deleteUser();
      await SecureStorage.deleteProfile();
      if (!mounted) return;
      _goToLogin();
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _goToAppShell() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) => const AppShell(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Golden Aura + Rounded Logo
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Breathing golden glow
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.0),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Container(
                          width: 200 * value,
                          height: 200 * value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFFCD535).withValues(alpha: 0.25 * value),
                                const Color(0xFFFCD535).withValues(alpha: 0.12 * value),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        );
                      },
                      onEnd: () {
                        if (mounted) setState(() {});
                      },
                    ),
                    // Rounded logo container
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF181A20),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: const Color(0xFFFCD535).withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFCD535).withValues(alpha: 0.4),
                              blurRadius: 32,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Image.asset(
                          'assets/images/zmay_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // App name
                const Text(
                  'Zmayy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                // Tagline
                const Text(
                  'Connecting Spatially.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF848E9C),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}