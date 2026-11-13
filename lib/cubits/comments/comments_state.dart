part of 'comments_cubit.dart';

enum CommentsStatus { idle, inProgress, loaded, allLoaded, error }

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
    required this.inThreadSearchStatus,
    required this.isNewInSearchSelected,
    required this.maxLevel,
    required this.navigationStack,
    required this.navigationIndex,
  });

  CommentsState.init({
    required this.isOfflineReading,
    required this.item,
    required this.fetchMode,
    required this.order,
  }) : comments = <Comment>[],
       matchedComments = <Comment>[],
       idToCommentMap = <int, Comment>{},
       status = CommentsStatus.idle,
       fetchParentStatus = CommentsStatus.idle,
       fetchRootStatus = CommentsStatus.idle,
       onlyShowTargetComment = false,
       currentPage = 0,
       inThreadSearchQuery = '',
       inThreadSearchAuthor = '',
       inThreadSearchStatus = Status.idle,
       isNewInSearchSelected = false,
       maxLevel = 0,
       navigationStack = <NavigationAnchor>[],
       navigationIndex = -1;

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
  final Status inThreadSearchStatus;
  final bool isNewInSearchSelected;
  final int maxLevel;

  /// The positions the user has jumped from and to in this thread, oldest
  /// first.
  final List<NavigationAnchor> navigationStack;

  /// The index in [navigationStack] of the position the user is currently
  /// at, or -1 when nothing has been recorded.
  final int navigationIndex;

  static const int maxNavigationStackSize = 50;

  bool get canNavigateBack => navigationIndex > 0;

  bool get canNavigateForward =>
      navigationIndex >= 0 && navigationIndex < navigationStack.length - 1;

  /// Indexes of comments that matches the query for in-thread search.
  final List<Comment> matchedComments;

  CommentsState copyWith({
    Item? item,
    List<Comment>? comments,
    List<Comment>? matchedComments,
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
    Status? inThreadSearchStatus,
    bool? isNewInSearchSelected,
    int? maxLevel,
    List<NavigationAnchor>? navigationStack,
    int? navigationIndex,
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
      inThreadSearchStatus: inThreadSearchStatus ?? this.inThreadSearchStatus,
      idToCommentMap: idToCommentMap ?? this.idToCommentMap,
      isNewInSearchSelected:
          isNewInSearchSelected ?? this.isNewInSearchSelected,
      maxLevel: maxLevel ?? this.maxLevel,
      navigationStack: navigationStack ?? this.navigationStack,
      navigationIndex: navigationIndex ?? this.navigationIndex,
    );
  }

  /// Records a jump from [from], where the user currently is, to [to].
  ///
  /// Any positions ahead of the current one are dropped, the same way a
  /// browser drops forward history when a new page is visited.
  CommentsState copyWithNavigation({
    required NavigationAnchor to,
    NavigationAnchor? from,
  }) {
    if (from?.itemId == to.itemId) {
      return this;
    }

    final List<NavigationAnchor> stack = navigationStack
        .take(navigationIndex + 1)
        .toList();

    if (from != null) {
      if (stack.isNotEmpty && stack.last.itemId == from.itemId) {
        stack.last = from;
      } else {
        stack.add(from);
      }
    }

    if (stack.isEmpty || stack.last.itemId != to.itemId) {
      stack.add(to);
    }

    if (stack.length > maxNavigationStackSize) {
      stack.removeRange(0, stack.length - maxNavigationStackSize);
    }

    return copyWith(navigationStack: stack, navigationIndex: stack.length - 1);
  }

  Set<int> get commentIds => comments.map((Comment e) => e.id).toSet();

  static final Map<int, bool> _isResponseCache = <int, bool>{};

  bool isResponse(Comment comment) {
    if (_isResponseCache.containsKey(comment.id)) {
      return _isResponseCache[comment.id]!;
    }

    if (comment.isRoot) {
      _isResponseCache[comment.id] = false;
      return false;
    }
    final Comment? precedingComment = idToCommentMap[comment.parent];
    if (precedingComment == null) {
      _isResponseCache[comment.id] = false;
      return false;
    } else if (item.id == precedingComment.parent && item.by == comment.by) {
      _isResponseCache[comment.id] = true;
      return true;
    } else if (idToCommentMap[precedingComment.parent]?.by == comment.by) {
      _isResponseCache[comment.id] = true;
      return true;
    } else {
      _isResponseCache[comment.id] = false;
      return false;
    }
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
    inThreadSearchStatus,
    idToCommentMap,
    isNewInSearchSelected,
    maxLevel,
    navigationStack,
    navigationIndex,
  ];
}
