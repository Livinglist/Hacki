part of 'comments_cubit.dart';

enum CommentsStatus {
  init,
  loading,
  loaded,
  failure,
}

class CommentsState<T extends Item> extends Equatable {
  const CommentsState({
    required this.item,
    required this.comments,
    required this.status,
    required this.collapsed,
  });

  CommentsState.init()
      : item = null,
        comments = [],
        status = CommentsStatus.init,
        collapsed = false;

  final Item? item;
  final List<Comment> comments;
  final CommentsStatus status;
  final bool collapsed;

  CommentsState copyWith({
    Item? item,
    List<Comment>? comments,
    CommentsStatus? status,
    bool? collapsed,
  }) {
    return CommentsState(
      item: item ?? this.item,
      comments: comments ?? this.comments,
      status: status ?? this.status,
      collapsed: collapsed ?? this.collapsed,
    );
  }

  @override
  List<Object?> get props => [
        item,
        comments,
        status,
        collapsed,
      ];
}
