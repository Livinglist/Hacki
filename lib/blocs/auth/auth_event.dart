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

class AuthToggleAgreeToEULA extends AuthEvent {
  @override
  List<Object?> get props => [];
}

class AuthFlag extends AuthEvent {
  AuthFlag({required this.item});

  final Item item;

  @override
  List<Object?> get props => [item];
}

class AuthLogout extends AuthEvent {
  @override
  List<Object?> get props => [];
}
