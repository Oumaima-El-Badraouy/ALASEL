/// Point to your deployed API or local dev server.
/// Android emulator: use `10.0.2.2` instead of `localhost`.
///
/// **Important:** routes are under `/api/v1`. If you pass only the origin
/// (e.g. `http://127.0.0.1:4000`), `/api/v1` is appended automatically so
/// login does not 404.
class ApiConfig {
  static const String _apiBaseFromEnv = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://127.0.0.1:4000/api/v1',
  );

  /// Resolved API root, always including `/api/v1` when the env is origin-only.
  static String get baseUrl => _normalizeApiBase(_apiBaseFromEnv);

  static String _normalizeApiBase(String raw) {
    var u = raw.trim().replaceAll(RegExp(r'/+$'), '');
    if (u.isEmpty) {
      return 'http://127.0.0.1:4000/api/v1';
    }
    if (u.contains('/api/')) {
      return u;
    }
    return '$u/api/v1';
  }

  /// Demo mode: backend with MEMORY_STORE=1 accepts X-Demo-Uid without Firebase.
  static const String demoUid = String.fromEnvironment('DEMO_UID', defaultValue: 'demo_client');

  /// Separate demo identity so you can bootstrap an artisan profile without overwriting the client.
  static const String demoArtisanUid =
      String.fromEnvironment('DEMO_ARTISAN_UID', defaultValue: 'demo_artisan');
}
