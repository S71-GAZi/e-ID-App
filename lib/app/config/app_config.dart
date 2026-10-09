/// Central app configuration.
///
/// Values are injected at build time via `--dart-define` so no secrets live in
/// the repository. Example:
///
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xyzcompany.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi... \
///   --dart-define=PUBLIC_BASE_URL=https://cards.yourdomain.com
/// ```
class AppConfig {
  const AppConfig._();

  /// Supabase project URL (required).
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  /// Supabase anonymous/public key (required). Safe to ship in the client —
  /// all real protection comes from Row Level Security policies.
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// Base URL used in online QR short links: <base>/c/<shortCode>.
  static const String publicBaseUrl = String.fromEnvironment(
    'PUBLIC_BASE_URL',
    defaultValue: 'https://cards.example.com',
  );

  /// Link that opens the app when installed (Universal Links / App Links host).
  static const String appLinkHost =
      String.fromEnvironment('APP_LINK_HOST', defaultValue: 'cards.example.com');

  /// Store URLs shown on the web card page and inside the app.
  static const String iosAppStoreUrl =
      String.fromEnvironment('IOS_APP_STORE_URL', defaultValue: '');
  static const String androidPlayStoreUrl =
      String.fromEnvironment('ANDROID_PLAY_STORE_URL', defaultValue: '');

  /// Max bytes we allow for an offline (embedded vCard) QR payload.
  /// QR version 40, binary mode, low ECC tops out around 2953 bytes;
  /// we stay conservative so phones can scan dense codes reliably.
  static const int maxOfflineQrBytes = 2400;

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}
