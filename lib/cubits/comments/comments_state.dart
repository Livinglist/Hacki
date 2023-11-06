part of 'comments_cubit.dart';

enum CommentsStatus {
  idle,
  inProgress,
  loaded,
  allLoaded,
  error,
}

class CommentsState extends Equatable {
  const CommentsState({
    required this.item,
    required this.comments,
    required this.matchedComments,
    required this.idToCommentMap,
    required this.status,
    required this.fetchParentStatus,
    required this.fetchRootStatus,
    required this.order,
    required this.fetchMode,
    required this.onlyShowTargetComment,
    required this.isOfflineReading,
    required this.currentPage,
    required this.inThreadSearchQuery,
    required this.inThreadSearchAuthor,
  });

  CommentsState.init({
    required this.isOfflineReading,
    required this.item,
    required this.fetchMode,
    required this.order,
  })  : comments = <Comment>[],
        matchedComments = <int>[],
        idToCommentMap = <int, Comment>{},
        status = CommentsStatus.idle,
        fetchParentStatus = CommentsStatus.idle,
        fetchRootStatus = CommentsStatus.idle,
        onlyShowTargetComment = false,
        currentPage = 0,
        inThreadSearchQuery = '',
        inThreadSearchAuthor = '';

  final Item item;
  final List<Comment> comments;
  final Map<int, Comment> idToCommentMap;
  final CommentsStatus status;
  final CommentsStatus fetchParentStatus;
  final CommentsStatus fetchRootStatus;
  final CommentsOrder order;
  final FetchMode fetchMode;
  final bool onlyShowTargetComment;
  final bool isOfflineReading;
  final int currentPage;
  final String inThreadSearchQuery;
  final String inThreadSearchAuthor;

  /// Indexes of comments that matches the query for in-thread search.
  final List<int> matchedComments;

  CommentsState copyWith({
    Item? item,
    List<Comment>? comments,
    List<int>? matchedComments,
    Map<int, Comment>? idToCommentMap,
    CommentsStatus? status,
    CommentsStatus? fetchParentStatus,
    CommentsStatus? fetchRootStatus,
    CommentsOrder? order,
    FetchMode? fetchMode,
    bool? onlyShowTargetComment,
    bool? isOfflineReading,
    int? currentPage,
    String? inThreadSearchQuery,
    String? inThreadSearchAuthor,
  }) {
    return CommentsState(
      item: item ?? this.item,
      comments: comments ?? this.comments,
      matchedComments: matchedComments ?? this.matchedComments,
      fetchParentStatus: fetchParentStatus ?? this.fetchParentStatus,
      fetchRootStatus: fetchRootStatus ?? this.fetchRootStatus,
      status: status ?? this.status,
      order: order ?? this.order,
      fetchMode: fetchMode ?? this.fetchMode,
      onlyShowTargetComment:
          onlyShowTargetComment ?? this.onlyShowTargetComment,
      isOfflineReading: isOfflineReading ?? this.isOfflineReading,
      currentPage: currentPage ?? this.currentPage,
      inThreadSearchQuery: inThreadSearchQuery ?? this.inThreadSearchQuery,
      inThreadSearchAuthor: inThreadSearchAuthor ?? this.inThreadSearchAuthor,
      idToCommentMap: idToCommentMap ?? this.idToCommentMap,
    );
  }

  Set<int> get commentIds => comments.map((Comment e) => e.id).toSet();

  bool isResponse(Comment comment) {
    if (comment.isRoot) return false;
    final Comment? precedingComment = idToCommentMap[comment.parent];
    if (precedingComment == null) {
      return false;
    } else if (item.id == precedingComment.parent && item.by == comment.by) {
      return true;
    }
    return idToCommentMap[precedingComment.parent]?.by == comment.by;
  }

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
        matchedComments,
        inThreadSearchQuery,
        inThreadSearchAuthor,
        idToCommentMap,
      ];
}
