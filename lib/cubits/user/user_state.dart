part of 'user_cubit.dart';

enum UserStatus {
  initial,
  loading,
  loaded,
  failure,
}

class UserState extends Equatable {
  const UserState({
    required this.user,
    required this.status,
  });

  UserState.init()
      : user = User.empty(),
        status = UserStatus.initial;

  final User user;
  final UserStatus status;

  UserState copyWith({
    User? user,
    UserStatus? status,
  }) {
    return UserState(
      user: user ?? this.user,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        user,
        status,
      ];
}
