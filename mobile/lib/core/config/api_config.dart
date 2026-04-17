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

  /// Origine HTTP pour Socket.IO (sans `/api/v1`).
  static String get socketOrigin {
    final u = baseUrl;
    final idx = u.indexOf('/api/v1');
    if (idx >= 0) return u.substring(0, idx);
    final idx2 = u.indexOf('/api/');
    if (idx2 >= 0) return u.substring(0, idx2);
    return u.replaceAll(RegExp(r'/+$'), '');
  }

  /// Lecture des vidéos servies sous `/uploads/...` : même hôte/port que l’API
  /// (évite `localhost` vs `127.0.0.1` vs `10.0.2.2` selon ce que le serveur a renvoyé).
  static Uri resolvedMediaUri(String media) {
    final m = media.trim();
    if (m.isEmpty) {
      return Uri.parse(media);
    }
    final origin = Uri.parse(socketOrigin);
    if (m.startsWith('/')) {
      return origin.resolve(m);
    }
    final u = Uri.tryParse(m);
    if (u == null || !(u.scheme == 'http' || u.scheme == 'https')) {
      return Uri.parse(m);
    }
    // Uniquement nos fichiers API : ne pas réécrire une URL CDN / autre domaine.
    if (u.path.startsWith('/uploads/')) {
      return Uri(
        scheme: origin.scheme,
        host: origin.host,
        port: origin.hasPort ? origin.port : null,
        path: u.path,
        query: u.hasQuery ? u.query : null,
      );
    }
    return u;
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
