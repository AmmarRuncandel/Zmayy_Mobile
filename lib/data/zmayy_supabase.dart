import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_env.dart';

/// Thin wrapper around `supabase_flutter` initialization.
final class ZmayySupabase {
  ZmayySupabase._();

  static bool _initialized = false;

  /// Whether [initialize] completed successfully.
  static bool get isReady => _initialized;

  /// Throws if called before a successful [initialize].
  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'Supabase not initialized. Call ZmayySupabase.initialize() after '
        'WidgetsFlutterBinding.ensureInitialized(), and pass '
        '--dart-define=SUPABASE_URL / SUPABASE_ANON_KEY when running the app.',
      );
    }
    return Supabase.instance.client;
  }

  /// Initializes the global Supabase singleton. Safe to call once at app start.
  static Future<void> initialize() async {
    if (_initialized) return;
    if (!SupabaseEnv.isConfigured) {
      throw StateError(
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY. Provide them via --dart-define.',
      );
    }
    await Supabase.initialize(url: SupabaseEnv.url, anonKey: SupabaseEnv.anonKey);
    _initialized = true;
  }

  /// Allows running UI shell without credentials (e.g. design-time). Returns `false` when skipped.
  static Future<bool> initializeIfConfigured() async {
    if (_initialized) return true;
    if (!SupabaseEnv.isConfigured) return false;
    await Supabase.initialize(url: SupabaseEnv.url, anonKey: SupabaseEnv.anonKey);
    _initialized = true;
    return true;
  }
}
