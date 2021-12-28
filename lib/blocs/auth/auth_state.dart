part of 'auth_bloc.dart';

enum AuthStatus {
  loading,
  loaded,
  failure,
}

class AuthState extends Equatable {
  const AuthState({
    required this.isLoggedIn,
    required this.status,
  });

  const AuthState.init()
      : isLoggedIn = false,
        status = AuthStatus.loaded;

  final bool isLoggedIn;
  final AuthStatus status;

  AuthState copyWith({
    bool? isLoggedIn,
    AuthStatus? status,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        isLoggedIn,
        status,
      ];
}
