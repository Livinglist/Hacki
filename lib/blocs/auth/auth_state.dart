part of 'auth_bloc.dart';

class AuthState extends Equatable {
  const AuthState({
    required this.user,
    required this.isLoggedIn,
    required this.status,
    required this.agreedToEULA,
  });

  const AuthState.init()
      : user = const User.empty(),
        isLoggedIn = false,
        status = Status.success,
        agreedToEULA = false;

  final User user;
  final bool isLoggedIn;
  final bool agreedToEULA;
  final Status status;

  String get username => user.id;

  AuthState copyWith({
    User? user,
    bool? isLoggedIn,
    bool? agreedToEULA,
    Status? status,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      agreedToEULA: agreedToEULA ?? this.agreedToEULA,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        user,
        isLoggedIn,
        agreedToEULA,
        status,
      ];
}
