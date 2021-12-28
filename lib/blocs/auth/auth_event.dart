part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {}

class AuthInitialize extends AuthEvent {
  @override
  List<Object?> get props => [];
}

class AuthLogin extends AuthEvent {
  AuthLogin({
    required this.username,
    required this.password,
  });

  final String username;
  final String password;

  @override
  List<Object?> get props => [
        username,
        password,
      ];
}

class AuthLogout extends AuthEvent {
  @override
  List<Object?> get props => [];
}
