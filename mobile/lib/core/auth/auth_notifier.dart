import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user_model.dart';
import '../config/api_config.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    hydrate();
  }

  static const _key = 'al_asel_jwt';
  static const _keyRemember = 'al_asel_remember_login';
  static const _keySavedEmail = 'al_asel_saved_email';
  static const _keySavedPassword = 'al_asel_saved_password';

  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final t = prefs.getString(_key);
    if (t != null && t.isNotEmpty) {
      state = AuthState(token: t, ready: false);
      try {
        final dio = _dio(t);
        final res = await dio.get('/users/me');
        final u = UserModel.fromJson(res.data as Map<String, dynamic>);
        state = AuthState(token: t, user: u, ready: true);
        return;
      } catch (_) {
        await prefs.remove(_key);
      }
    }
    if (prefs.getBool(_keyRemember) == true) {
      final email = prefs.getString(_keySavedEmail);
      final password = prefs.getString(_keySavedPassword);
      if (email != null &&
          email.isNotEmpty &&
          password != null &&
          password.isNotEmpty) {
        try {
          await login(email, password, rememberMe: true);
          return;
        } catch (_) {
          /* garder les champs sauvegardés pour saisie manuelle */
        }
      }
    }
    state = const AuthState(ready: true);
  }

  Dio _dio(String token) {
    return Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Future<void> login(
    String email,
    String password, {
    bool? rememberMe,
  }) async {
    final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl, headers: {'Content-Type': 'application/json'}));
    final res = await dio.post('/auth/login', data: {'email': email.trim(), 'password': password});
    final data = res.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
    if (rememberMe == true) {
      await prefs.setBool(_keyRemember, true);
      await prefs.setString(_keySavedEmail, email.trim());
      await prefs.setString(_keySavedPassword, password);
    } else if (rememberMe == false) {
      await prefs.remove(_keyRemember);
      await prefs.remove(_keySavedEmail);
      await prefs.remove(_keySavedPassword);
    }
    state = AuthState(token: token, user: user, ready: true);
  }

  Future<void> registerClient({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    required bool isMediounaVerified,
    String? photoUrl,
  }) async {
    final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl, headers: {'Content-Type': 'application/json'}));
    final res = await dio.post('/auth/register', data: {
      'role': 'client',
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'phone': phone.trim(),
      'email': email.trim(),
      'password': password,
      'isMediounaVerified': isMediounaVerified,
      if (photoUrl != null && photoUrl.trim().isNotEmpty) 'photoUrl': photoUrl.trim(),
    });
    final data = res.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
    state = AuthState(token: token, user: user, ready: true);
  }

  Future<void> registerArtisan({
    required String fullName,
    required String domain,
    required String description,
    required String phone,
    required String email,
    required String password,
    required bool isMediounaVerified,
    String? photoUrl,
    required String cinRectoUrl,
    required String cinVersoUrl,
  }) async {
    final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl, headers: {'Content-Type': 'application/json'}));
    final res = await dio.post('/auth/register', data: {
      'role': 'artisan',
      'fullName': fullName,
      'domain': domain,
      'description': description,
      'phone': phone,
      'email': email.trim(),
      'password': password,
      'isMediounaVerified': isMediounaVerified,
      if (photoUrl != null && photoUrl.trim().isNotEmpty) 'photoUrl': photoUrl.trim(),
      'cinRectoUrl': cinRectoUrl.trim(),
      'cinVersoUrl': cinVersoUrl.trim(),
    });
    final data = res.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
    state = AuthState(token: token, user: user, ready: true);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_keyRemember);
    await prefs.remove(_keySavedEmail);
    await prefs.remove(_keySavedPassword);
    state = const AuthState(ready: true);
  }

  Future<void> refreshMe() async {
    final t = state.token;
    if (t == null) return;
    final dio = _dio(t);
    final res = await dio.get('/users/me');
    final u = UserModel.fromJson(res.data as Map<String, dynamic>);
    state = state.copyWith(user: u);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
