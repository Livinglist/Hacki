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
    required this.story,
    required this.comments,
    required this.status,
    required this.collapsed,
    required this.onlyShowTargetComment,
    required this.offlineReading,
    required this.currentPage,
  });

  CommentsState.init({
    required this.offlineReading,
    required this.story,
  })  : comments = <Comment>[],
        status = CommentsStatus.init,
        collapsed = false,
        onlyShowTargetComment = false,
        currentPage = 0;

  final Story story;
  final List<Comment> comments;
  final CommentsStatus status;
  final bool collapsed;
  final bool onlyShowTargetComment;
  final bool offlineReading;
  final int currentPage;

  CommentsState copyWith({
    Story? story,
    List<Comment>? comments,
    CommentsStatus? status,
    bool? collapsed,
    bool? onlyShowTargetComment,
    bool? offlineReading,
    int? currentPage,
  }) {
    return CommentsState(
      story: story ?? this.story,
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
  List<Object?> get props => <Object?>[
        story,
        comments,
        status,
        collapsed,
        onlyShowTargetComment,
        offlineReading,
        currentPage,
      ];
}
