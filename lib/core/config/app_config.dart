/// Cấu hình truyền vào lúc build bằng `--dart-define` hoặc
/// `--dart-define-from-file=env/dev.json` (xem docs/setup-backend.md).
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Publishable (anon) key của Supabase. Được phép nằm trong app vì quyền
  /// truy cập do RLS quyết định.
  static const supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Web client ID (OAuth) của project Firebase, dùng cho Google Sign-In.
  static const googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  static List<String> get missingKeys => [
        if (supabaseUrl.isEmpty) 'SUPABASE_URL',
        if (supabasePublishableKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
      ];
}
