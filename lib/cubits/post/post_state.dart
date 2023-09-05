part of 'post_cubit.dart';

class PostState extends Equatable {
  const PostState({required this.status});

  const PostState.init() : status = Status.idle;

  final Status status;

  PostState copyWith({Status? status}) {
    return PostState(
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
      ];
}
