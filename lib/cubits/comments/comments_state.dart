part of 'comments_cubit.dart';

enum CommentsStatus {
  init,
  loading,
  loaded,
  allLoaded,
  failure,
}

class CommentsState extends Equatable {
  const CommentsState({
    required this.item,
    required this.comments,
    required this.status,
    required this.collapsed,
    required this.onlyShowTargetComment,
    required this.offlineReading,
    required this.currentPage,
  });

  CommentsState.init({
    required this.offlineReading,
    required this.item,
  })  : comments = [],
        status = CommentsStatus.init,
        collapsed = false,
        onlyShowTargetComment = false,
        currentPage = 0;

  final Item item;
  final List<Comment> comments;
  final CommentsStatus status;
  final bool collapsed;
  final bool onlyShowTargetComment;
  final bool offlineReading;
  final int currentPage;

  CommentsState copyWith({
    Item? item,
    List<Comment>? comments,
    CommentsStatus? status,
    bool? collapsed,
    bool? onlyShowTargetComment,
    bool? offlineReading,
    int? currentPage,
  }) {
    return CommentsState(
      item: item ?? this.item,
      comments: comments ?? this.comments,
      status: status ?? this.status,
      collapsed: collapsed ?? this.collapsed,
      onlyShowTargetComment:
          onlyShowTargetComment ?? this.onlyShowTargetComment,
      offlineReading: offlineReading ?? this.offlineReading,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
        item,
        comments,
        status,
        collapsed,
        onlyShowTargetComment,
        offlineReading,
        currentPage,
      ];
}
