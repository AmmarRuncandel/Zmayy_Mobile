import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/zmayy_colors.dart';

/// Parity auth screen dengan Next.js login page
/// • Mode switching dengan slide animation
/// • Auto-fill & auto-switch setelah signup
/// • Comprehensive error translation ke Bahasa Indonesia
/// • Session validation sebelum navigate
final class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  
  late AnimationController _slideController;
  bool _busy = false;
  bool _register = false;
  Object? _error;
  String? _successMsg;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _slideController.dispose();
    super.dispose();
  }

  /// Comprehensive error translation (sesuai Next.js translateError)
  String _translateError(Object raw) {
    String msg = '';
    if (raw is AuthException) {
      msg = raw.message.toLowerCase();
    } else if (raw is Exception) {
      msg = raw.toString().toLowerCase();
    } else {
      msg = raw.toString().toLowerCase();
    }

    if (msg.contains('invalid login credentials') || msg.contains('invalid password')) {
      return 'Email atau kata sandi salah. Periksa kembali dan coba lagi.';
    }
    if (msg.contains('user already registered') || msg.contains('already been registered')) {
      return 'Email ini sudah terdaftar. Silakan masuk.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Email belum diverifikasi. Periksa kotak masuk kamu.';
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.';
    }
    if (msg.contains('password should be at least') || msg.contains('at least 6')) {
      return 'Kata sandi minimal 6 karakter.';
    }
    if (msg.contains('unable to validate email') || msg.contains('invalid email')) {
      return 'Format email tidak valid.';
    }
    if (msg.contains('network') || msg.contains('fetch') || msg.contains('connection')) {
      return 'Koneksi gagal. Periksa jaringan internet kamu.';
    }
    
    return msg.isNotEmpty ? msg : 'Autentikasi gagal. Silakan coba lagi.';
  }

  /// Switch mode dengan animation
  void _switchMode() {
    setState(() {
      _error = null;
      _successMsg = null;
      _register = !_register;
    });
    // Trigger animation
    if (_slideController.isCompleted) {
      _slideController.reverse();
    } else {
      _slideController.forward();
    }
  }

  Future<void> _submit() async {
    final SupabaseClient client = Supabase.instance.client;
    final String email = _email.text.trim();
    final String password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email dan kata sandi wajib diisi.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _successMsg = null;
    });

    try {
      if (_register) {
        // SIGNUP flow
        await client.auth.signUp(
          email: email,
          password: password,
        );
        
        if (!mounted) return;

        // Success: auto-fill email & switch ke login
        setState(() {
          _successMsg = 'Akun berhasil dibuat. Silakan masuk.';
          _email.text = email; // Keep email
          _password.clear();
          _register = false;
          _busy = false;
        });

        // Small delay untuk show success message, then switch mode animation
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          _slideController.reverse();
        }
      } else {
        // LOGIN flow
        final AuthResponse response = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (!mounted) return;

        // Validate session established
        if (response.session == null) {
          throw Exception('Sesi tidak dapat divalidasi.');
        }

        // Small delay untuk ensure cookies set dan session valid
        await Future.delayed(const Duration(milliseconds: 100));

        if (!mounted) return;
        // Session valid - AuthRouter stream listener akan handle navigation ke app
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _busy = false;
      });
    }
  }

  String _readableError(Object raw) {
    return _translateError(raw);
  }

  InputDecoration _fieldDecoration({
    required String label,
    IconData? leading,
    bool hasError = false,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: leading == null ? null : Icon(leading, size: 18, color: ZmayyColors.muted),
      filled: true,
      fillColor: ZmayyColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFEF4444) : ZmayyColors.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: hasError ? const Color(0xFFEF4444) : ZmayyColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ZmayyColors.gold, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Animation<Offset> slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0), // From right
      end: Offset.zero, // To center
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    return Scaffold(
      backgroundColor: ZmayyColors.base,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [ZmayyColors.base, ZmayyColors.slate950],
                ),
              ),
            ),
          ),
          Positioned(
            top: -180,
            left: -20,
            right: -20,
            child: IgnorePointer(
              child: Container(
                height: 320,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.7),
                    radius: 1,
                    colors: [
                      ZmayyColors.gold.withAlpha(36),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -120,
            bottom: -140,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.72,
                    colors: [Color(0x4D1E3250), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: SlideTransition(
                  position: slideAnimation,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 410),
                    padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
                    decoration: BoxDecoration(
                      color: ZmayyColors.glassFill,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ZmayyColors.border, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFCD535).withAlpha(38),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Zmayy',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 31),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _register ? 'Buat akun baru' : 'Masuk ke petamu',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: ZmayyColors.muted, fontSize: 13),
                        ),
                        const SizedBox(height: 24),
                        // Success message banner
                        if (_successMsg != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0x2210B981),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x6610B981)),
                            ),
                            child: Text(
                              _successMsg!,
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const <String>[AutofillHints.email],
                          enabled: !_busy,
                          decoration: _fieldDecoration(
                            label: 'Email',
                            leading: Icons.alternate_email_rounded,
                            hasError: _error != null,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          autofillHints: const <String>[AutofillHints.password],
                          enabled: !_busy,
                          decoration: _fieldDecoration(
                            label: 'Kata sandi',
                            leading: Icons.lock_outline_rounded,
                            hasError: _error != null,
                          ),
                          onSubmitted: (_) => _busy ? null : _submit(),
                        ),
                        // Error message banner
                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0x22EF4444),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x66EF4444)),
                            ),
                            child: Text(
                              _readableError(_error ?? 'Terjadi kesalahan.'),
                              style: const TextStyle(
                                color: ZmayyColors.danger,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            backgroundColor: ZmayyColors.gold,
                            foregroundColor: ZmayyColors.base,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _busy ? null : _submit,
                          icon: _busy
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: ZmayyColors.base,
                                  ),
                                )
                              : const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: Text(_register ? 'Buat Akun' : 'Masuk'),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _busy ? null : _switchMode,
                          child: Text(
                            _register ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar',
                            style: const TextStyle(color: ZmayyColors.gold),
                          ),
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
    );
  }
}
