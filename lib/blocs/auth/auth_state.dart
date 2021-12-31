part of 'auth_bloc.dart';

enum AuthStatus {
  loading,
  loaded,
  failure,
}

class AuthState extends Equatable {
  const AuthState({
    required this.username,
    required this.isLoggedIn,
    required this.status,
  });

  const AuthState.init()
      : username = '',
        isLoggedIn = false,
        status = AuthStatus.loaded;

  final String username;
  final bool isLoggedIn;
  final AuthStatus status;

  AuthState copyWith({
    String? username,
    bool? isLoggedIn,
    AuthStatus? status,
  }) {
    return AuthState(
      username: username ?? this.username,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        username,
        isLoggedIn,
        status,
      ];
}
