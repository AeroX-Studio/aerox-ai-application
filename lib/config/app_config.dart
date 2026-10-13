/// Centralized, production-ready application configuration for AeroX AI.
///
/// Houses official production backend endpoints, OAuth identifiers,
/// and environment-aware build properties.
library;

/// Central application configuration singleton and environment provider.
class AppConfig {
  AppConfig._();

  /// Official cloud production backend endpoint for AeroX AI.
  static const String defaultProductionUrl = 'https://aerox-ai.onrender.com';

  /// Active backend API base URL.
  ///
  /// In production releases, this is strictly [defaultProductionUrl].
  /// For internal staging/dev builds, developers may configure it at build
  /// time via `--dart-define=AEROX_API_URL=https://...` without modifying code
  /// or exposing development UI selectors in the production application.
  static const String apiBaseUrl = String.fromEnvironment(
    'AEROX_API_URL',
    defaultValue: defaultProductionUrl,
  );

  /// Google OAuth Web Client ID used for Google Sign-In and token verification.
  ///
  /// Configurable at build time via `--dart-define=GOOGLE_CLIENT_ID=...`.
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '37419829113-d7epdlc8qmbuhev1vum68plslhm75ss0.apps.googleusercontent.com',
  );

  /// Official Android application package identity.
  static const String androidPackageName = 'com.aeroxstudio.aeroxai';

  /// Returns the effective base URL with any protocol or trailing slash normalized.
  static String get normalizedApiUrl {
    var url = apiBaseUrl.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    // Safeguard to bridge any legacy aliases directly to the live production host
    if (url.contains('aerox-ai.onrender.io')) {
      url = url.replaceAll('aerox-ai.onrender.io', 'aerox-ai.onrender.com');
    }
    return url;
  }
}
