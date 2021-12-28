part of 'comments_cubit.dart';

enum CommentsStatus {
  init,
  loading,
  loaded,
  failure,
}

class CommentsState extends Equatable {
  const CommentsState({
    required this.story,
    required this.comments,
    required this.status,
  });

  CommentsState.init()
      : story = Story.empty(),
        comments = [],
        status = CommentsStatus.init;

  final Story story;
  final List<Comment> comments;
  final CommentsStatus status;

  CommentsState copyWith({
    Story? story,
    List<Comment>? comments,
    CommentsStatus? status,
  }) {
    return CommentsState(
      story: story ?? this.story,
      comments: comments ?? this.comments,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        story,
        comments,
        status,
      ];
}
