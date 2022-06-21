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
    required this.item,
    required this.comments,
    required this.status,
    required this.fetchParentStatus,
    required this.order,
    required this.onlyShowTargetComment,
    required this.offlineReading,
    required this.currentPage,
  });

  CommentsState.init({
    required this.offlineReading,
    required this.item,
  })  : comments = <Comment>[],
        status = CommentsStatus.init,
        fetchParentStatus = CommentsStatus.init,
        order = CommentsOrder.natural,
        onlyShowTargetComment = false,
        currentPage = 0;

  final Item item;
  final List<Comment> comments;
  final CommentsStatus status;
  final CommentsStatus fetchParentStatus;
  final CommentsOrder order;
  final bool onlyShowTargetComment;
  final bool offlineReading;
  final int currentPage;

  CommentsState copyWith({
    Item? item,
    List<Comment>? comments,
    CommentsStatus? status,
    CommentsStatus? fetchParentStatus,
    CommentsOrder? order,
    bool? onlyShowTargetComment,
    bool? offlineReading,
    int? currentPage,
  }) {
    return CommentsState(
      item: item ?? this.item,
      comments: comments ?? this.comments,
      fetchParentStatus: fetchParentStatus ?? this.fetchParentStatus,
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
        item,
        comments,
        status,
        fetchParentStatus,
        order,
        onlyShowTargetComment,
        offlineReading,
        currentPage,
      ];
}
