part of 'comments_cubit.dart';

enum CommentsStatus {
  init,
  loading,
  loaded,
  allLoaded,
  failure,
}

enum CommentsOrder {
  natural,
  newestFirst,
  oldestFirst,
}

class CommentsState extends Equatable {
  const CommentsState({
    required this.story,
    required this.comments,
    required this.status,
    required this.order,
    required this.onlyShowTargetComment,
    required this.offlineReading,
    required this.currentPage,
  });

  CommentsState.init({
    required this.offlineReading,
    required this.story,
  })  : comments = <Comment>[],
        status = CommentsStatus.init,
        order = CommentsOrder.natural,
        onlyShowTargetComment = false,
        currentPage = 0;

  final Story story;
  final List<Comment> comments;
  final CommentsStatus status;
  final CommentsOrder order;
  final bool onlyShowTargetComment;
  final bool offlineReading;
  final int currentPage;

  CommentsState copyWith({
    Story? story,
    List<Comment>? comments,
    CommentsStatus? status,
    CommentsOrder? order,
    bool? onlyShowTargetComment,
    bool? offlineReading,
    int? currentPage,
  }) {
    return CommentsState(
      story: story ?? this.story,
      comments: comments ?? this.comments,
      status: status ?? this.status,
      order: order ?? this.order,
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
        order,
        onlyShowTargetComment,
        offlineReading,
        currentPage,
      ];
}
