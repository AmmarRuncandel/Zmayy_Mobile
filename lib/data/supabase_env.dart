/// Reads Supabase credentials from `--dart-define` flags (no `.env` dependency).
///
/// Example:
/// ```sh
/// flutter run \
///   --dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
/// ```
abstract final class SupabaseEnv {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
