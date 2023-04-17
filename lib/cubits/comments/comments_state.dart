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
    required this.fetchParentStatus,
    required this.fetchRootStatus,
    required this.order,
    required this.fetchMode,
    required this.onlyShowTargetComment,
    required this.isOfflineReading,
    required this.currentPage,
  });

  CommentsState.init({
    required this.isOfflineReading,
    required this.item,
    required this.fetchMode,
    required this.order,
  })  : comments = <Comment>[],
        status = CommentsStatus.init,
        fetchParentStatus = CommentsStatus.init,
        fetchRootStatus = CommentsStatus.init,
        onlyShowTargetComment = false,
        currentPage = 0;

  final Item item;
  final List<Comment> comments;
  final CommentsStatus status;
  final CommentsStatus fetchParentStatus;
  final CommentsStatus fetchRootStatus;
  final CommentsOrder order;
  final FetchMode fetchMode;
  final bool onlyShowTargetComment;
  final bool isOfflineReading;
  final int currentPage;

  CommentsState copyWith({
    Item? item,
    List<Comment>? comments,
    CommentsStatus? status,
    CommentsStatus? fetchParentStatus,
    CommentsStatus? fetchRootStatus,
    CommentsOrder? order,
    FetchMode? fetchMode,
    bool? onlyShowTargetComment,
    bool? isOfflineReading,
    int? currentPage,
  }) {
    return CommentsState(
      item: item ?? this.item,
      comments: comments ?? this.comments,
      fetchParentStatus: fetchParentStatus ?? this.fetchParentStatus,
      fetchRootStatus: fetchRootStatus ?? this.fetchRootStatus,
      status: status ?? this.status,
      order: order ?? this.order,
      fetchMode: fetchMode ?? this.fetchMode,
      onlyShowTargetComment:
          onlyShowTargetComment ?? this.onlyShowTargetComment,
      isOfflineReading: isOfflineReading ?? this.isOfflineReading,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  Set<int> get commentIds => comments.map((Comment e) => e.id).toSet();

  @override
  List<Object?> get props => <Object?>[
        item,
        status,
        fetchParentStatus,
        fetchRootStatus,
        order,
        fetchMode,
        onlyShowTargetComment,
        isOfflineReading,
        currentPage,
        comments,
      ];
}
