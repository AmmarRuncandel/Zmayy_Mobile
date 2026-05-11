import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import '../../app_shell.dart';
import '../../data/repositories/auth_repository.dart';
import 'login_screen.dart';
import 'auth_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthRepository _repo = AuthRepository();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _buildUsernameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) {
      return 'pengguna-baru';
    }

    return localPart.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '-');
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email dan kata sandi wajib diisi.');
      }

      developer.log('Register attempt: $email', level: 800);
      final response = await _repo.register(email, password, _buildUsernameFromEmail(email));
      developer.log('Register response: $response', level: 800);

      if (response['requires_confirmation'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message']?.toString() ?? 'Akun dibuat. Silakan cek email kamu.')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell()),
        (route) => false,
      );
    } catch (err) {
      developer.log('Register error: $err', level: 1000);
      final message = err is Exception ? err.toString() : 'Register failed: $err';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.25),
                    radius: 1.1,
                    colors: [
                      const Color(0xFF102827).withValues(alpha: 0.62),
                      const Color(0xFF0B0E11),
                      const Color(0xFF081116),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: 24,
              bottom: 24,
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF12151B).withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFF232833)),
                        boxShadow: [
                          BoxShadow(color: const Color(0x26FCD535), blurRadius: 42, spreadRadius: 3),
                          BoxShadow(color: const Color(0x66000000), blurRadius: 24, offset: const Offset(0, 10)),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(22, 34, 22, 22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0E1116),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(color: const Color(0x33FCD535), blurRadius: 26, spreadRadius: 4),
                              ],
                            ),
                            padding: const EdgeInsets.all(11),
                            child: Image.asset('assets/images/zmay_logo.png', fit: BoxFit.contain),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Zmayy',
                            style: TextStyle(
                              color: Color(0xFFE5E7EB),
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Buat akun baru',
                            style: TextStyle(
                              color: Color(0xFF8A93A3),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildLabeledField(
                            label: 'EMAIL',
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 15),
                              decoration: _inputDecoration('Masukkan email'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildLabeledField(
                            label: 'KATA SANDI',
                            child: TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              enableSuggestions: false,
                              autocorrect: false,
                              style: const TextStyle(color: Color(0xFFF1F5F9), fontSize: 15),
                              decoration: _inputDecoration(
                                'Minimal 6 karakter',
                                suffix: IconButton(
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: const Color(0xFF93A0B3),
                                    size: 18,
                                  ),
                                  splashRadius: 18,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFCD535),
                                disabledBackgroundColor: const Color(0xFFFCD535).withValues(alpha: 0.7),
                                foregroundColor: const Color(0xFF0B0E11),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Color(0xFF0B0E11)),
                                    )
                                  : const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.arrow_forward, size: 18, color: Color(0xFF0B0E11)),
                                        SizedBox(width: 8),
                                        Text(
                                          'Buat Akun',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            color: Color(0xFF0B0E11),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'Sudah punya akun? ',
                                style: TextStyle(color: Color(0xFF8A93A3), fontSize: 12.5, fontWeight: FontWeight.w500),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushReplacement(AuthRoutes.cardRoute(const LoginScreen()));
                                },
                                child: const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    color: Color(0xFFFCD535),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7F8795),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF7E8794), fontSize: 14, fontWeight: FontWeight.w500),
      filled: true,
      fillColor: const Color(0xFF181A20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF232833)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFCD535), width: 1.25),
      ),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    );
  }
}