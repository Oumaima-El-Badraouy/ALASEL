import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// API locale — port **4000**, routes sous `/api/v1`.
///
/// Android : IP du PC sur le réseau (développement). Changez [_lanDevHost] si votre IP change.
/// Autre plateforme : `127.0.0.1`.
/// Surcharge build : `--dart-define=API_BASE=http://.../api/v1`
class ApiConfig {
  static const String _apiBaseFromEnv = String.fromEnvironment('API_BASE', defaultValue: '');

  /// IP du PC (cmd → `ipconfig` → IPv4). Téléphone et PC sur le même Wi‑Fi.
  static const String _lanDevHost = '192.168.1.198';
  static const int _apiPort = 4000;

  static String get baseUrl {
    final fromEnv = _apiBaseFromEnv.trim();
    if (fromEnv.isNotEmpty) {
      return _normalizeApiBase(fromEnv);
    }
    return _normalizeApiBase(_defaultBaseForPlatform());
  }

  static String _defaultBaseForPlatform() {
    if (kIsWeb) return 'http://127.0.0.1:$_apiPort/api/v1';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://$_lanDevHost:$_apiPort/api/v1';
    }
    return 'http://127.0.0.1:$_apiPort/api/v1';
  }

  static String get socketOrigin {
    final u = baseUrl;
    final idx = u.indexOf('/api/v1');
    if (idx >= 0) return u.substring(0, idx);
    final idx2 = u.indexOf('/api/');
    if (idx2 >= 0) return u.substring(0, idx2);
    return u.replaceAll(RegExp(r'/+$'), '');
  }

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
      return _normalizeApiBase(_defaultBaseForPlatform());
    }
    if (!u.contains('://')) {
      u = 'http://$u';
    }
    if (u.contains('/api/')) {
      return u;
    }
    return '$u/api/v1';
  }

  static const String demoUid = String.fromEnvironment('DEMO_UID', defaultValue: 'demo_client');

  static const String demoArtisanUid =
      String.fromEnvironment('DEMO_ARTISAN_UID', defaultValue: 'demo_artisan');
}
