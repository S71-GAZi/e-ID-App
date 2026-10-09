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

  /// Application name shown in the UI and native app manifests.
  static const String appName =
      String.fromEnvironment('APP_NAME', defaultValue: 'E-ID');

  /// Supabase project URL (optional for now — the app is offline-first and
  /// works fully without a backend; sync activates once keys are provided).
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  /// Supabase anonymous/public key (required). Safe to ship in the client —
  /// all real protection comes from Row Level Security policies.
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  /// Placeholder domain used in online QR short links: <base>/c/<shortCode>.
  /// It does NOT need to resolve anywhere while you test: an installed E-ID
  /// app intercepts these links via deep linking, and any phone camera can
  /// still read the text. Replace with your real domain later via
  /// --dart-define=PUBLIC_BASE_URL=https://yourdomain.com (Phase 3 wires up
  /// Universal Links / App Links + the web card page on that domain).
  static const String publicBaseUrl = String.fromEnvironment(
    'PUBLIC_BASE_URL',
    defaultValue: 'https://eid.pages.dev',
  );

  /// Host of [publicBaseUrl] — used by the scanner/deep-link router to
  /// recognise our short links.
  static String get appLinkHost => Uri.parse(publicBaseUrl).host;

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
