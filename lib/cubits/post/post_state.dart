part of 'post_cubit.dart';

enum PostStatus {
  init,
  loading,
  successful,
  failure,
}

class PostState extends Equatable {
  const PostState({required this.status});

  const PostState.init() : status = PostStatus.init;

  final PostStatus status;

  PostState copyWith({PostStatus? status}) {
    return PostState(
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        status,
      ];
}
