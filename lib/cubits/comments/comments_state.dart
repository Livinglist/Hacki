part of 'comments_cubit.dart';

class CommentsState extends Equatable {
  const CommentsState({required this.comments});

  CommentsState.init() : comments = [];

  final List<Comment> comments;

  CommentsState copyWith({List<Comment>? comments}) {
    return CommentsState(comments: comments ?? this.comments);
  }

  @override
  List<Object?> get props => [comments];
}
