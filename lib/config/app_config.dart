class AppConfig {
  static const String appName = 'Bright Future Classes';
  static const String packageName = 'com.brightfutureclasses';

  /// Base URL for the external administrative backend.
  /// Can be configured via --dart-define=BACKEND_BASE_URL=https://your-app.onrender.com
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );
}
