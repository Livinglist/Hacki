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
    required this.agreedToEULA,
  });

  const AuthState.init()
      : username = '',
        isLoggedIn = false,
        status = AuthStatus.loaded,
        agreedToEULA = false;

  final String username;
  final bool isLoggedIn;
  final bool agreedToEULA;
  final AuthStatus status;

  AuthState copyWith({
    String? username,
    bool? isLoggedIn,
    bool? agreedToEULA,
    AuthStatus? status,
  }) {
    return AuthState(
      username: username ?? this.username,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      agreedToEULA: agreedToEULA ?? this.agreedToEULA,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        username,
        isLoggedIn,
        agreedToEULA,
        status,
      ];
}
