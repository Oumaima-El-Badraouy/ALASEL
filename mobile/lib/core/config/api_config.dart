import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Point to your deployed API or local dev server.
///
/// **Port 4000** — l’URL par défaut pointe vers l’API locale sur ce port.
///
/// - **Windows / macOS / Linux / iOS simulateur** : `127.0.0.1` = votre machine.
/// - **Émulateur Android** : `127.0.0.1` = l’émulateur lui-même, pas le PC. Sans
///   `API_BASE`, l’app utilise `http://10.0.2.2:4000` (alias de localhost sur l’hôte).
/// - **Téléphone Android réel** : définissez l’IP de votre PC, ex.
///   `--dart-define=API_BASE=http://192.168.1.x:4000/api/v1`
///
/// **Important:** les routes sont sous `/api/v1`. Si vous ne passez que l’origine
/// (ex. `http://127.0.0.1:4000`), `/api/v1` est ajouté automatiquement.
class ApiConfig {
  /// Vide = utiliser [_defaultBaseForPlatform] (émulateur Android → `10.0.2.2:4000`).
  static const String _apiBaseFromEnv = String.fromEnvironment('API_BASE', defaultValue: '');

  /// Resolved API root, always including `/api/v1` when the env is origin-only.
  static String get baseUrl {
    final raw = _apiBaseFromEnv.trim();
    final origin = raw.isNotEmpty ? raw : _defaultBaseForPlatform();
    return _normalizeApiBase(origin);
  }

  static String _defaultBaseForPlatform() {
    if (kIsWeb) return 'http://127.0.0.1:4000/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000/api/v1';
    }
    return 'http://127.0.0.1:4000/api/v1';
  }

  static String _normalizeApiBase(String raw) {
    var u = raw.trim().replaceAll(RegExp(r'/+$'), '');
    if (u.isEmpty) {
      return _defaultBaseForPlatform();
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
