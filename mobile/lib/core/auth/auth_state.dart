import '../../data/models/user_model.dart';

class AuthState {
  const AuthState({this.token, this.user, this.ready = false});

  final String? token;
  final UserModel? user;
  final bool ready;

  bool get isAuthenticated => token != null && user != null;

  AuthState copyWith({String? token, UserModel? user, bool? ready}) {
    return AuthState(
      token: token ?? this.token,
      user: user ?? this.user,
      ready: ready ?? this.ready,
    );
  }
}
