part of 'user_cubit.dart';

class UserState extends Equatable {
  const UserState({
    required this.user,
    required this.status,
  });

  const UserState.init()
      : user = const User.empty(),
        status = Status.idle;

  final User user;
  final Status status;

  UserState copyWith({
    User? user,
    Status? status,
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
