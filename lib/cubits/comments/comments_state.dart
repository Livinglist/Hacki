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

enum FetchMode {
  lazy,
  eager,
}

class CommentsState extends Equatable {
  const CommentsState({
    required this.item,
    required this.comments,
    required this.status,
    required this.fetchParentStatus,
    required this.order,
    required this.fetchMode,
    required this.onlyShowTargetComment,
    required this.offlineReading,
    required this.currentPage,
  });

  CommentsState.init({
    required this.offlineReading,
    required this.item,
    required this.fetchMode,
    required this.order,
  })  : comments = <Comment>[],
        status = CommentsStatus.init,
        fetchParentStatus = CommentsStatus.init,
        onlyShowTargetComment = false,
        currentPage = 0;

  final Item item;
  final List<Comment> comments;
  final CommentsStatus status;
  final CommentsStatus fetchParentStatus;
  final CommentsOrder order;
  final FetchMode fetchMode;
  final bool onlyShowTargetComment;
  final bool offlineReading;
  final int currentPage;

  CommentsState copyWith({
    Item? item,
    List<Comment>? comments,
    CommentsStatus? status,
    CommentsStatus? fetchParentStatus,
    CommentsOrder? order,
    FetchMode? fetchMode,
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
      fetchMode: fetchMode ?? this.fetchMode,
      onlyShowTargetComment:
          onlyShowTargetComment ?? this.onlyShowTargetComment,
      offlineReading: offlineReading ?? this.offlineReading,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  Set<int> get commentIds => comments.map((Comment e) => e.id).toSet();

  @override
  List<Object?> get props => <Object?>[
        item,
        comments,
        status,
        fetchParentStatus,
        order,
        fetchMode,
        onlyShowTargetComment,
        offlineReading,
        currentPage,
      ];
}
