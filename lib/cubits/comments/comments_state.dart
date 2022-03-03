part of 'comments_cubit.dart';

enum CommentsStatus {
  init,
  loading,
  loaded,
  failure,
}

class CommentsState extends Equatable {
  const CommentsState({
    required this.item,
    required this.comments,
    required this.status,
    required this.collapsed,
    required this.onlyShowTargetComment,
  });

  CommentsState.init()
      : item = null,
        comments = [],
        status = CommentsStatus.init,
        collapsed = false,
        onlyShowTargetComment = false;

  final Item? item;
  final List<Comment> comments;
  final CommentsStatus status;
  final bool collapsed;
  final bool onlyShowTargetComment;

  CommentsState copyWith({
    Item? item,
    List<Comment>? comments,
    CommentsStatus? status,
    bool? collapsed,
    bool? onlyShowTargetComment,
  }) {
    return CommentsState(
      item: item ?? this.item,
      comments: comments ?? this.comments,
      status: status ?? this.status,
      collapsed: collapsed ?? this.collapsed,
      onlyShowTargetComment:
          onlyShowTargetComment ?? this.onlyShowTargetComment,
    );
  }

  @override
  List<Object?> get props => [
        item,
        comments,
        status,
        collapsed,
        onlyShowTargetComment,
      ];
}
