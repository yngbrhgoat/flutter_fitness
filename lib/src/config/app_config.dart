/// Runtime app configuration provided through --dart-define values.
class AppConfig {
  /// Uses in-memory backend by default to allow local runs without a server.
  static const bool useMockBackend = bool.fromEnvironment(
    'USE_MOCK_BACKEND',
    defaultValue: true,
  );

  /// REST backend URL when USE_MOCK_BACKEND=false.
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
