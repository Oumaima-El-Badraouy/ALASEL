/// Point to your deployed API or local dev server.
/// Android emulator: use `10.0.2.2` instead of `localhost`.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://127.0.0.1:4000/api/v1',
  );

  /// Demo mode: backend with MEMORY_STORE=1 accepts X-Demo-Uid without Firebase.
  static const String demoUid = String.fromEnvironment('DEMO_UID', defaultValue: 'demo_client');

  /// Separate demo identity so you can bootstrap an artisan profile without overwriting the client.
  static const String demoArtisanUid =
      String.fromEnvironment('DEMO_ARTISAN_UID', defaultValue: 'demo_artisan');
}
