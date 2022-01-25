part of 'auth_bloc.dart';

enum AuthStatus {
  loading,
  loaded,
  failure,
}

class AuthState extends Equatable {
  const AuthState({
    required this.user,
    required this.isLoggedIn,
    required this.status,
    required this.agreedToEULA,
  });

  AuthState.init()
      : user = User.empty(),
        isLoggedIn = false,
        status = AuthStatus.loaded,
        agreedToEULA = false;

  final User user;
  final bool isLoggedIn;
  final bool agreedToEULA;
  final AuthStatus status;

  String get username => user.id;

  AuthState copyWith({
    User? user,
    bool? isLoggedIn,
    bool? agreedToEULA,
    AuthStatus? status,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      agreedToEULA: agreedToEULA ?? this.agreedToEULA,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        user,
        isLoggedIn,
        agreedToEULA,
        status,
      ];
}
