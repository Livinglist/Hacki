/// Compile-time configuration supplied with Flutter's `--dart-define` option.
abstract final class AppEnvironment {
  /// Public HTTPS base URL of the optional Hacker News fallback backend.
  static const String backendUrl = String.fromEnvironment('HACKI_BACKEND_URL');

  /// Shared backend API key. Empty values leave fallback disabled.
  static const String backendApiKey = String.fromEnvironment(
    'HACKI_BACKEND_API_KEY',
  );
}
