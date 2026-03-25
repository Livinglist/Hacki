import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/custom_router.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/config/paths.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/item/widgets/in_thread_search_icon_button.dart'
    show InThreadSearchIconButton;
import 'package:hacki/screens/screens.dart' show ItemScreen, ItemScreenArgs;
import 'package:hacki/screens/widgets/custom_linkify/custom_linkify.dart';
import 'package:hacki/screens/widgets/shine_overlay.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/utils/utils.dart';
import 'package:rxdart/rxdart.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

part 'comments_state.dart';

final Map<int, Map<int, Comment>> _itemIdToPreviousStates =
    <int, Map<int, Comment>>{};

class CommentsCubit extends Cubit<CommentsState> with Loggable {
  CommentsCubit({
    required FilterCubit filterCubit,
    required PreferenceCubit preferenceCubit,
    required bool isOfflineReading,
    required Item item,
    required FetchMode defaultFetchMode,
    required CommentsOrder defaultCommentsOrder,
    CommentCache? commentCache,
    OfflineRepository? offlineRepository,
    SembastRepository? sembastRepository,
    HackerNewsRepository? hackerNewsRepository,
    HackerNewsWebRepository? hackerNewsWebRepository,
    CollapseStateCacheRepository? collapseStateCacheRepository,
    AppLifecycleService? appLifecycleService,
  })  : _filterCubit = filterCubit,
        _preferenceCubit = preferenceCubit,
        _commentCache = commentCache ?? locator.get<CommentCache>(),
        _offlineRepository =
            offlineRepository ?? locator.get<OfflineRepository>(),
        _sembastRepository =
            sembastRepository ?? locator.get<SembastRepository>(),
        _hackerNewsRepository =
            hackerNewsRepository ?? locator.get<HackerNewsRepository>(),
        _hackerNewsWebRepository =
            hackerNewsWebRepository ?? locator.get<HackerNewsWebRepository>(),
        _collapseStateCacheRepository = collapseStateCacheRepository ??
            locator.get<CollapseStateCacheRepository>(),
        _appLifecycleService =
            appLifecycleService ?? locator.get<AppLifecycleService>(),
        super(
          CommentsState.init(
            isOfflineReading: isOfflineReading,
            item: item,
            fetchMode: defaultFetchMode,
            order: defaultCommentsOrder,
          ),
        ) {
    _appStateSubscription = _appLifecycleService.stream
        .where((AppLifecycleState s) => s == AppLifecycleState.inactive)
        .listen(_onAppHidden);
  }

  /// Global keys mapped to comment ids, this is used primarily in
  /// [InThreadSearchIconButton] to uncollapse the search target
  /// that user tapped on on [ItemScreen].
  final Map<int, GlobalKey> globalKeys = <int, GlobalKey>{};

  final FilterCubit _filterCubit;
  final PreferenceCubit _preferenceCubit;
  final CommentCache _commentCache;
  final OfflineRepository _offlineRepository;
  final SembastRepository _sembastRepository;
  final HackerNewsRepository _hackerNewsRepository;
  final HackerNewsWebRepository _hackerNewsWebRepository;
  final CollapseStateCacheRepository _collapseStateCacheRepository;
  final AppLifecycleService _appLifecycleService;
  late final StreamSubscription<AppLifecycleState> _appStateSubscription;
  void Function()? openInThreadSearch;

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  /// The [StreamSubscription] for stream (both lazy or eager)
  /// fetching comments posted directly to the story.
  StreamSubscription<Comment>? _streamSubscription;
  StreamSubscription<Comment?>? _searchStreamSubscription;

  /// The map of [StreamSubscription] for streams
  /// fetching comments lazily. [int] is the id of parent comment.
  final Map<int, StreamSubscription<Comment>> _streamSubscriptions =
      <int, StreamSubscription<Comment>>{};

  static const int _webFetchingCmtCountLowerLimit = 5;
  static DateTime? _hackerNewsWebRetryAfterDateTime;

  /// The id of the comment of which the text selection menu is active.
  static int _lockedCommentId = 0;
  Map<int, Comment>? _previousCommentStates;
  double inThreadSearchOffset = 0;

  bool get hasNewComment => state.comments.any((Comment c) => c.isNew);

  Future<bool> get _shouldFetchFromWeb async {
    final bool isOnWifi = await _isOnWifi;
    final bool isPastRetryAfterDateTime =
        _hackerNewsWebRetryAfterDateTime == null ||
            DateTime.now().isAfter(_hackerNewsWebRetryAfterDateTime!);
    if (isOnWifi && isPastRetryAfterDateTime) {
      return switch (state.item) {
        Story(descendants: final int descendants)
            when descendants > _webFetchingCmtCountLowerLimit =>
          true,
        Comment(kids: final List<int> kids)
            when kids.length > _webFetchingCmtCountLowerLimit =>
          true,
        _ => false,
      };
    } else {
      return isPastRetryAfterDateTime;
    }
  }

  static Future<bool> get _isOnWifi async {
    final List<ConnectivityResult> status =
        await Connectivity().checkConnectivity();
    return status.contains(ConnectivityResult.wifi);
  }

  @override
  void emit(CommentsState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> _initializeCollapseStateCache() async {
    if (_preferenceCubit.state.shouldPersistCollapseStateAcrossSessions &&
        _itemIdToPreviousStates.isEmpty) {
      _itemIdToPreviousStates.addAll(
        _collapseStateCacheRepository.cachedItemIdToPreviousStates,
      );
    }

    if (_preferenceCubit.state.shouldPreserveCollapseStateAfterScreenExit) {
      _previousCommentStates = _itemIdToPreviousStates[state.item.id];
    } else {
      _itemIdToPreviousStates.clear();
    }
  }

  Future<void> init({
    bool shouldOnlyShowTargetComment = false,
    bool shouldUseCommentCacheInMemory = false,
    List<Comment>? targetAncestors,
    AppExceptionHandler? onError,
    bool isFetchingFromWebAllowed = true,
  }) async {
    await _initializeCollapseStateCache();

    final Item item = state.item;

    if (_preferenceCubit.state.shouldPreserveCollapseStateAfterScreenExit &&
        item is Story) {
      _previousCommentStates = _itemIdToPreviousStates[item.id];
    }

    if (shouldOnlyShowTargetComment && (targetAncestors?.isNotEmpty ?? false)) {
      emit(
        state.copyWith(
          comments: targetAncestors,
          onlyShowTargetComment: true,
          status: CommentsStatus.allLoaded,
        ),
      );

      _streamSubscription = _hackerNewsRepository
          .fetchAllCommentsRecursivelyStream(
            ids: targetAncestors!.last.kids,
            level: targetAncestors.last.level + 1,
          )
          .asyncMap(_toBuildableComment)
          .whereNotNull()
          .listen(_onCommentFetched)
        ..onDone(_onDone);

      return;
    }

    emit(
      state.copyWith(
        status: CommentsStatus.inProgress,
        comments: <Comment>[],
        matchedComments: <Comment>[],
        inThreadSearchQuery: '',
        currentPage: 0,
      ),
    );

    final Item updatedItem = state.isOfflineReading
        ? item
        : await _hackerNewsRepository
                .fetchItem(id: item.id)
                .then(_toBuildable)
                .onError((_, __) => item) ??
            item;
    final List<int> kids = _sortKids(updatedItem.kids);

    emit(state.copyWith(item: updatedItem));

    late final Stream<Comment> commentStream;
    final bool shouldShowCompletionSnackBar = !state.isOfflineReading;

    if (state.isOfflineReading) {
      commentStream = _offlineRepository.getCachedCommentsStream(
        ids: kids,
      );
    } else {
      switch (state.fetchMode) {
        case FetchMode.lazy:
          commentStream = _hackerNewsRepository.fetchCommentsStream(
            ids: kids,
            getFromCache:
                shouldUseCommentCacheInMemory ? _commentCache.getComment : null,
          );
        case FetchMode.eager:
          switch (state.order) {
            case CommentsOrder.natural:
              final bool shouldFetchFromWeb = await _shouldFetchFromWeb;
              if (isFetchingFromWebAllowed && shouldFetchFromWeb) {
                logInfo('fetching comments of ${item.id} from web.');
                commentStream = _hackerNewsWebRepository
                    .fetchCommentsStream(
                  state.item,
                )
                    .handleError((dynamic e) {
                  _streamSubscription?.cancel();

                  logError(e);

                  switch (e.runtimeType) {
                    case RateLimitedException:
                    case RateLimitedWithFallbackException:
                    case ParsingException:
                      if (_preferenceCubit.state.isDevModeEnabled) {
                        onError?.call(e as AppException);
                      }
                    case TooManyRequestsException:
                      final DateTime retryAfter =
                          (e as TooManyRequestsException).retryAfter;
                      _hackerNewsWebRetryAfterDateTime = retryAfter;
                      logInfo('retry after $retryAfter');
                      if (_preferenceCubit.state.isDevModeEnabled) {
                        onError?.call(e);
                      }
                    default:
                      onError?.call(GenericException(error: e));
                  }

                  /// If fetching from web failed, fetch using API instead.
                  init(onError: onError, isFetchingFromWebAllowed: false);
                });
              } else {
                logInfo('fetching comments of ${item.id} from API.');
                commentStream =
                    _hackerNewsRepository.fetchAllCommentsRecursivelyStream(
                  ids: kids,
                  getFromCache: shouldUseCommentCacheInMemory
                      ? _commentCache.getComment
                      : null,
                );
              }
            case CommentsOrder.oldestFirst:
            case CommentsOrder.newestFirst:
              logInfo('fetching comments of ${item.id} from API.');
              commentStream =
                  _hackerNewsRepository.fetchAllCommentsRecursivelyStream(
                ids: kids,
                getFromCache: shouldUseCommentCacheInMemory
                    ? _commentCache.getComment
                    : null,
              );
          }
      }
    }

    _streamSubscription = commentStream
        .asyncMap(_toBuildableComment)
        .whereNotNull()
        .listen(_onCommentFetched)
      ..onDone(
        () => _onDone(
          isCompletionSnackBarEnabled: shouldShowCompletionSnackBar,
        ),
      );
  }

  Future<void> refresh({
    required AppExceptionHandler? onError,
    bool fetchFromWeb = true,
  }) async {
    if (state.isOfflineReading) {
      emit(
        state.copyWith(
          status: CommentsStatus.allLoaded,
        ),
      );
      return;
    } else if (state.status == CommentsStatus.inProgress) {
      return;
    }

    emit(
      state.copyWith(
        status: CommentsStatus.inProgress,
      ),
    );

    /// Preserve collapse state.
    _preserveCollapseState();

    final Item item = state.item;
    final Item updatedItem =
        await _hackerNewsRepository.fetchItem(id: item.id) ?? item;

    /// Compare the kids to decide if we should fetch from remote source.
    if (item.kids.length == updatedItem.kids.length &&
        item.kids.toSet() == updatedItem.kids.toSet()) {
      emit(
        state.copyWith(
          status: CommentsStatus.allLoaded,
        ),
      );
      return;
    } else {
      await _streamSubscription?.cancel();
      for (final int id in _streamSubscriptions.keys) {
        await _streamSubscriptions[id]?.cancel();
      }
      _streamSubscriptions.clear();

      emit(
        state.copyWith(
          comments: <Comment>[],
          currentPage: 0,
        ),
      );
    }

    final List<int> kids = _sortKids(updatedItem.kids);

    late final Stream<Comment> commentStream;

    switch (state.fetchMode) {
      case FetchMode.lazy:
        commentStream = _hackerNewsRepository.fetchCommentsStream(ids: kids);
      case FetchMode.eager:
        switch (state.order) {
          case CommentsOrder.natural:
            final bool shouldFetchFromWeb = await _shouldFetchFromWeb;
            if (fetchFromWeb && shouldFetchFromWeb) {
              logInfo(
                'fetching comments of ${item.id} from web.',
              );
              commentStream = _hackerNewsWebRepository
                  .fetchCommentsStream(state.item)
                  .handleError((dynamic e) {
                logError(e);

                switch (e.runtimeType) {
                  case RateLimitedException:
                  case RateLimitedWithFallbackException:
                  case ParsingException:
                    if (_preferenceCubit.state.isDevModeEnabled) {
                      onError?.call(e as AppException);
                    }
                  case TooManyRequestsException:
                    final DateTime retryAfter =
                        (e as TooManyRequestsException).retryAfter;
                    _hackerNewsWebRetryAfterDateTime = retryAfter;
                    logInfo('retry after $retryAfter');
                    if (_preferenceCubit.state.isDevModeEnabled) {
                      onError?.call(e);
                    }
                  default:
                    onError?.call(GenericException(error: e));
                }

                /// If fetching from web failed, fetch using API instead.
                refresh(onError: onError, fetchFromWeb: false);
              });
            } else {
              logInfo('fetching comments of ${item.id} from API.');
              commentStream = _hackerNewsRepository
                  .fetchAllCommentsRecursivelyStream(ids: kids);
            }
          case CommentsOrder.oldestFirst:
          case CommentsOrder.newestFirst:
            logInfo('fetching comments of ${item.id} from API.');
            commentStream =
                _hackerNewsRepository.fetchAllCommentsRecursivelyStream(
              ids: kids,
            );
        }
    }

    _streamSubscription = commentStream
        .asyncMap(_toBuildableComment)
        .whereNotNull()
        .listen(_onCommentFetched)
      ..onDone(() => _onDone(isCompletionSnackBarEnabled: true));

    emit(
      state.copyWith(
        item: updatedItem,
      ),
    );
  }

  void loadAll(Story story) {
    HapticFeedbackUtil.light();
    emit(
      state.copyWith(
        onlyShowTargetComment: false,
        item: story,
        matchedComments: <Comment>[],
      ),
    );
    init();
  }

  /// [comment] is only used for lazy fetching.
  void loadMore({
    Comment? comment,
    VoidCallback? onDone,
  }) {
    if (comment == null && state.status == CommentsStatus.inProgress) return;

    switch (state.fetchMode) {
      case FetchMode.lazy:
        if (comment == null) return;
        if (_streamSubscriptions.containsKey(comment.id)) return;

        final int level = comment.level + 1;
        int offset = 0;

        /// Ignoring because the subscription will be cancelled in close()
        // ignore: cancel_subscriptions
        final StreamSubscription<Comment> streamSubscription =
            _hackerNewsRepository
                .fetchCommentsStream(ids: comment.kids)
                .asyncMap(_toBuildableComment)
                .whereNotNull()
                .listen((Comment cmt) {
          globalKeys[cmt.id] = GlobalKey();
          _commentCache.cacheComment(cmt);

          final Map<int, Comment> updatedIdToCommentMap =
              Map<int, Comment>.from(state.idToCommentMap);
          updatedIdToCommentMap[comment.id] = comment;

          emit(
            state.copyWith(
              comments: <Comment>[...state.comments]..insert(
                  state.comments.indexOf(comment) + offset + 1,
                  cmt.copyWith(level: level),
                ),
              idToCommentMap: updatedIdToCommentMap,
            ),
          );
          offset++;
        })
              ..onDone(() {
                _streamSubscriptions[comment.id]?.cancel();
                _streamSubscriptions.remove(comment.id);
              })
              ..onError((dynamic e) {
                logError(e);
                _streamSubscriptions[comment.id]?.cancel();
                _streamSubscriptions.remove(comment.id);
              });

        _streamSubscriptions[comment.id] = streamSubscription;
      case FetchMode.eager:
        return;
    }
  }

  void lock(Comment comment) {
    _lockedCommentId = comment.id;
  }

  void unlock() {
    _lockedCommentId = 0;
  }

  bool isCommentLocked(Comment comment) => _lockedCommentId == comment.id;

  void collapse(Comment comment) {
    final List<Comment> comments = <Comment>[...state.comments];
    final int commentIndex =
        state.comments.indexWhere((Comment c) => c.id == comment.id);
    final int commentLevel = comment.level;
    final Comment updatedComment = comment.copyWith(isCollapsedByUser: true);
    final List<Comment> updatedComments = <Comment>[updatedComment];
    int endIndex = commentIndex + 1;

    if (endIndex >= comments.length) {
      comments.replaceRange(commentIndex, comments.length, updatedComments);
      emit(state.copyWith(comments: comments));
      return;
    }

    for (int i = commentIndex + 1; i < comments.length; i++) {
      Comment cmt = comments.elementAt(i);
      endIndex = i;
      if (cmt.level > commentLevel) {
        cmt = cmt.copyWith(isHiddenByUser: true);
        updatedComments.add(cmt);
        if (i == comments.length - 1) {
          endIndex = comments.length;
        }
      } else {
        break;
      }
    }

    comments.replaceRange(commentIndex, endIndex, updatedComments);
    emit(state.copyWith(comments: comments));
  }

  void uncollapse(Comment comment) {
    final List<Comment> comments = <Comment>[...state.comments];
    final int commentIndex =
        state.comments.indexWhere((Comment c) => c.id == comment.id);
    final int commentLevel = comment.level;
    final Comment updatedComment = comment.copyWith(isCollapsedByUser: false);
    final List<Comment> updatedComments = <Comment>[updatedComment];
    int endIndex = commentIndex + 1;

    if (endIndex >= comments.length) {
      comments.replaceRange(commentIndex, comments.length, updatedComments);
      emit(state.copyWith(comments: comments));
      return;
    }

    for (int i = commentIndex + 1; i < comments.length; i++) {
      Comment cmt = comments.elementAt(i);
      endIndex = i;
      if (cmt.level > commentLevel) {
        cmt = cmt.copyWith(isHiddenByUser: false);
        updatedComments.add(cmt);
        if (i == comments.length - 1) {
          endIndex = comments.length;
        }
      } else {
        break;
      }
    }

    comments.replaceRange(commentIndex, endIndex, updatedComments);
    emit(state.copyWith(comments: comments));
  }

  /// Hidden and new comments count.
  (int, int) collapsedCount(
    Comment comment, {
    bool countNewComments = false,
  }) {
    final List<Comment> comments = state.comments;
    final int commentIndex =
        state.comments.indexWhere((Comment c) => c.id == comment.id);
    final int commentLevel = comment.level;
    int count = 0;
    int newCommentsCount = 0;
    for (int i = commentIndex + 1; i < comments.length; i++) {
      final Comment cmt = comments.elementAt(i);
      if (cmt.level > commentLevel) {
        if (countNewComments && cmt.isNew) newCommentsCount++;
        count++;
      } else {
        break;
      }
    }
    return (count, newCommentsCount);
  }

  Future<void> loadParentThread() async {
    HapticFeedbackUtil.light();
    emit(state.copyWith(fetchParentStatus: CommentsStatus.inProgress));
    final Item? parent =
        await _hackerNewsRepository.fetchItem(id: state.item.parent);

    if (parent == null) {
      return;
    } else {
      await router.push(
        Paths.item.landing,
        extra: ItemScreenArgs(item: parent),
      );

      emit(
        state.copyWith(
          fetchParentStatus: CommentsStatus.loaded,
        ),
      );
    }
  }

  Future<void> loadRootThread() async {
    HapticFeedbackUtil.light();
    emit(state.copyWith(fetchRootStatus: CommentsStatus.inProgress));
    final Story? parent = await _hackerNewsRepository
        .fetchParentStory(id: state.item.id)
        .then(_toBuildableStory);

    if (parent == null) {
      return;
    } else {
      await router.push(
        Paths.item.landing,
        extra: ItemScreenArgs(item: parent),
      );

      emit(
        state.copyWith(
          fetchRootStatus: CommentsStatus.loaded,
        ),
      );
    }
  }

  void updateOrder(CommentsOrder? order) {
    if (order == null) return;
    if (state.order == order) return;
    if (state.status == CommentsStatus.inProgress) return;
    HapticFeedbackUtil.selection();
    _streamSubscription?.cancel();
    for (final StreamSubscription<Comment> s in _streamSubscriptions.values) {
      s.cancel();
    }
    _streamSubscriptions.clear();

    emit(
      state.copyWith(
        order: order,
        comments: <Comment>[],
        status: CommentsStatus.inProgress,
      ),
    );

    final Item item = state.item;
    final List<int> kids = _sortKids(item.kids);
    final Stream<Comment> commentStream =
        _commentCache.getCommentsStream(ids: kids);
    _streamSubscription = commentStream
        .asyncMap(_toBuildableComment)
        .whereNotNull()
        .listen(_onCommentFetched)
      ..onDone(_onDone);
  }

  void updateFetchMode(FetchMode? fetchMode) {
    /// Preserve collapse state.
    _preserveCollapseState();

    if (fetchMode == null) return;
    if (state.fetchMode == fetchMode) return;
    HapticFeedbackUtil.selection();
    _streamSubscription?.cancel();
    for (final StreamSubscription<Comment> s in _streamSubscriptions.values) {
      s.cancel();
    }
    _streamSubscriptions.clear();
    emit(state.copyWith(fetchMode: fetchMode));
    init();
  }

  bool _isCommentOnScreen(Comment comment) {
    final Iterable<Comment> onScreenComments =
        itemPositionsListener.itemPositions.value
            // The header is also a part of the list view,
            // thus ignoring it here.
            .where(
              (ItemPosition e) =>
                  e.index >= 1 &&
                      (e.itemLeadingEdge > 0.12 && e.itemLeadingEdge < 0.48) ||
                  (e.itemLeadingEdge >= 0.48 && e.itemTrailingEdge < 1),
            )
            .map(
              (ItemPosition e) => e.index <= state.comments.length
                  ? state.comments.elementAt(e.index - 1)
                  : null,
            )
            .nonNulls;
    if (kDebugMode) {
      debugPrint(
        '''on screen comments are ${onScreenComments.map((Comment e) => e.id)}''',
      );
    }
    final bool isTargetCommentInRange =
        onScreenComments.any((Comment c) => c.id == comment.id);
    return isTargetCommentInRange;
  }

  Future<void> scrollToComment(
    Comment comment, {
    bool isRetrying = false,
  }) async {
    /// Find out the index of the comment in the thread.
    final Comment? matchedComment = state.comments.singleWhereOrNull(
      (Comment c) => c.id == comment.id,
    );
    if (matchedComment == null) return;
    final int index = state.comments.indexOf(matchedComment);

    /// If index if found, scroll to the comment.
    if (index != -1) {
      await scrollTo(
        index: index,
        duration: AppDurations.ms300,
      );
    }

    /// Find out all of its ancestors, uncollapse them if they
    /// are collapsed.
    Comment? curComment = matchedComment;
    while (curComment != null) {
      if (curComment.isCollapsedByUser) {
        uncollapse(curComment);
      }
      curComment = state.comments.singleWhereOrNull(
        (Comment c) => c.id == curComment?.parent,
      );

      if (curComment == null) break;
    }

    final GlobalKey<State<StatefulWidget>>? targetCommentGlobalKey =
        globalKeys[matchedComment.id];
    final BuildContext? targetCommentContext =
        targetCommentGlobalKey?.currentContext;

    /// After uncollapsing all the ancestors,
    /// once again, ensure the target comment is visible.
    /// Then create a shine effect on the widget to
    /// briefly highlight the target comment tile.
    if (targetCommentContext != null) {
      /// Delay here so `itemPositionsListener` can be up to date.
      await Future<void>.delayed(AppDurations.ms300, () async {
        /// Make sure the comment tile's leading edge is within an
        /// acceptable view point.
        final bool isCommentOnScreen = _isCommentOnScreen(comment);

        if (kDebugMode) {
          debugPrint(
            '''
target comment is ${comment.id}
target comment is in range? $isCommentOnScreen
index is $index
comments length is ${state.comments.length}            
            ''',
          );
        }

        if (!isCommentOnScreen) {
          if (index != -1) {
            if (kDebugMode) {
              debugPrint('scrolling another time to ${index + 1}');
            }
            await itemScrollController.scrollTo(
              index: index + 1,
              alignment: 0.2,
              duration: AppDurations.ms300,
            );

            final bool isCommentOnScreen = _isCommentOnScreen(comment);
            if (!isCommentOnScreen && !isRetrying) {
              await scrollToComment(comment, isRetrying: true);
              return;
            }
          } else {
            if (kDebugMode) {
              debugPrint('attempting to ensure visible');
            }
            final BuildContext? newTargetCommentContext =
                targetCommentGlobalKey?.currentContext;
            if (newTargetCommentContext != null &&
                newTargetCommentContext.mounted) {
              if (kDebugMode) {
                debugPrint('ensure visible');
              }
              await Scrollable.ensureVisible(
                newTargetCommentContext,
                alignment: 0.15,
                duration: AppDurations.ms300,
                alignmentPolicy:
                    ScrollPositionAlignmentPolicy.keepVisibleAtStart,
              );
            }
          }
        }

        await Future<void>.delayed(AppDurations.ms400, () {
          final BuildContext? newTargetCommentContext =
              targetCommentGlobalKey?.currentContext;
          if (targetCommentGlobalKey != null &&
              newTargetCommentContext != null &&
              newTargetCommentContext.mounted) {
            _startShine(
              newTargetCommentContext,
              targetCommentGlobalKey,
            );
          }
        });
      });
    }
  }

  Future<void> scrollTo({
    required int index,
    double alignment = 0.0,
    Duration? duration,
    Curve curve = Curves.linear,
    List<double> opacityAnimationWeights = const <double>[40, 20, 40],
  }) async {
    debugPrint('scrolling to: $index, alignment: $alignment');
    await itemScrollController.scrollTo(
      index: index,
      alignment: alignment,
      duration: duration ?? AppDurations.ms400,
      curve: curve,
      opacityAnimationWeights: opacityAnimationWeights,
    );
  }

  /// Scroll to next root level comment.
  void scrollToNextRoot({VoidCallback? onError}) {
    final int totalComments = state.comments.length;
    final List<Comment> onScreenComments = itemPositionsListener
        .itemPositions.value
        // The header is also a part of the list view,
        // thus ignoring it here.
        .where((ItemPosition e) => e.index >= 1 && e.itemLeadingEdge > 0.1)
        .sorted((ItemPosition a, ItemPosition b) => a.index.compareTo(b.index))
        .map(
          (ItemPosition e) => e.index <= state.comments.length
              ? state.comments.elementAt(e.index - 1)
              : null,
        )
        .nonNulls
        .toList();

    if (onScreenComments.isEmpty && state.comments.isNotEmpty) {
      itemScrollController.scrollTo(
        index: 1,
        alignment: 0.15,
        duration: AppDurations.ms400,
      );
      return;
    }

    final Comment? firstVisibleRootComment =
        onScreenComments.firstWhereOrNull((Comment e) => e.isRoot);
    late int startIndex;

    if (firstVisibleRootComment != null) {
      /// The index of first root level comment visible on screen.
      final int firstVisibleRootCommentIndex =
          state.comments.indexOf(firstVisibleRootComment);
      startIndex = min(firstVisibleRootCommentIndex + 1, totalComments);
    } else if (onScreenComments.isNotEmpty) {
      final int lastVisibleCommentIndex =
          state.comments.indexOf(onScreenComments.last);
      startIndex = min(lastVisibleCommentIndex + 1, totalComments);
    }

    for (int i = startIndex; i < totalComments; i++) {
      final Comment cmt = state.comments.elementAt(i);

      if (cmt.isRoot && (cmt.deleted || cmt.dead) == false) {
        itemScrollController.scrollTo(
          index: i + 1,
          alignment: 0.15,
          duration: AppDurations.ms400,
        );
        return;
      }
    }

    if (state.status == CommentsStatus.allLoaded) {
      onError?.call();
    }
  }

  /// Scroll to previous root level comment.
  void scrollToPreviousRoot() {
    final List<Comment> onScreenComments = itemPositionsListener
        .itemPositions.value
        // The header is also a part of the list view,
        // thus ignoring it here.
        .where((ItemPosition e) => e.index >= 1 && e.itemLeadingEdge > 0)
        .sorted((ItemPosition a, ItemPosition b) => a.index.compareTo(b.index))
        .map(
          (ItemPosition e) => e.index <= state.comments.length
              ? state.comments.elementAt(e.index - 1)
              : null,
        )
        .nonNulls
        .toList();

    /// The index of first comment visible on screen.
    final int firstVisibleIndex = state.comments.indexOf(
      onScreenComments.firstOrNull ?? state.comments.last,
    );
    final int startIndex = max(0, firstVisibleIndex - 1);

    for (int i = startIndex; i >= 0; i--) {
      final Comment cmt = state.comments.elementAt(i);

      if (cmt.isRoot && (cmt.deleted || cmt.dead) == false) {
        itemScrollController.scrollTo(
          index: i + 1,
          alignment: 0.15,
          duration: AppDurations.ms400,
        );
        return;
      }
    }
  }

  Future<void> search(
    String query, {
    String author = '',
    bool isNewSelected = false,
  }) async {
    await _searchStreamSubscription?.cancel();
    resetSearch();
    emit(
      state.copyWith(
        inThreadSearchQuery: query,
        inThreadSearchAuthor: author,
        inThreadSearchStatus: Status.inProgress,
        isNewInSearchSelected: isNewSelected,
      ),
    );
    _searchStreamSubscription = _searchStream(
      query,
      author: author,
      isNewSelected: isNewSelected,
    ).listen((Comment? comment) {
      emit(
        state.copyWith(
          matchedComments: <Comment>[
            ...state.matchedComments,
            if (comment != null) comment,
          ],
        ),
      );
    })
      ..onDone(() {
        emit(
          state.copyWith(
            inThreadSearchStatus: Status.success,
          ),
        );
      });
  }

  Stream<Comment?> _searchStream(
    String query, {
    String author = '',
    bool isNewSelected = false,
  }) async* {
    late bool Function(Comment cmt) conditionSatisfied;
    final String lowercaseQuery = query.toLowerCase();
    bool newCommentsSelector(Comment cmt) => !isNewSelected || cmt.isNew;
    if (query.isEmpty && author.isEmpty) {
      if (isNewSelected) {
        conditionSatisfied = newCommentsSelector;
      } else {
        return;
      }
    } else if (author.isEmpty) {
      conditionSatisfied = (Comment cmt) =>
          newCommentsSelector(cmt) &&
          (cmt.by.toLowerCase().contains(lowercaseQuery) ||
              cmt.text.toLowerCase().contains(lowercaseQuery));
    } else if (query.isEmpty) {
      conditionSatisfied =
          (Comment cmt) => newCommentsSelector(cmt) && cmt.by == author;
    } else {
      conditionSatisfied = (Comment cmt) =>
          newCommentsSelector(cmt) &&
          cmt.text.toLowerCase().contains(lowercaseQuery) &&
          cmt.by == author;
    }

    for (final int i in 0.to(state.comments.length, inclusive: false)) {
      final Comment cmt = state.comments.elementAt(i);
      if (conditionSatisfied(cmt)) {
        final Comment comment = state.comments.elementAt(i);
        final BuildableComment? buildableComment =
            await _toBuildableComment(comment, withHighlightedText: query);
        yield buildableComment;
      }
    }
  }

  void resetSearch() => emit(
        state.copyWith(
          matchedComments: <Comment>[],
          inThreadSearchQuery: '',
          inThreadSearchAuthor: '',
          inThreadSearchStatus: Status.idle,
        ),
      );

  void _preserveCollapseState() {
    _previousCommentStates ??= <int, Comment>{};

    for (final Comment e in state.comments) {
      _previousCommentStates?[e.id] = e.copyWithOnlyCollapseState();
    }

    if (_previousCommentStates != null && state.item is Story) {
      _itemIdToPreviousStates
          .putIfAbsent(state.item.id, () => <int, Comment>{})
          .addAll(_previousCommentStates ?? <int, Comment>{});

      if (_preferenceCubit.state.shouldPersistCollapseStateAcrossSessions) {
        _collapseStateCacheRepository.saveStoryStates(
          state.item.id,
          _previousCommentStates!,
        );
      }

      if (!_preferenceCubit.state.shouldPreserveCollapseStateAfterScreenExit) {
        _itemIdToPreviousStates.clear();
      }
    }
  }

  List<int> _sortKids(List<int> kids) {
    switch (state.order) {
      case CommentsOrder.natural:
        return kids;
      case CommentsOrder.newestFirst:
        return kids.sorted((int a, int b) => b.compareTo(a));
      case CommentsOrder.oldestFirst:
        return kids.sorted((int a, int b) => a.compareTo(b));
    }
  }

  void _onDone({bool isCompletionSnackBarEnabled = false}) {
    _streamSubscription?.cancel();
    _streamSubscription = null;

    logInfo('loading of ${state.item.id} is complete.');
    emit(
      state.copyWith(
        status: CommentsStatus.allLoaded,
      ),
    );

    final bool isFirstTimeReading =
        !_itemIdToPreviousStates.containsKey(state.item.id);
    if (isCompletionSnackBarEnabled && !isFirstTimeReading) {
      final int newCommentsCount =
          state.comments.where((Comment c) => c.isNew).length;
      if (newCommentsCount > 0) {
        HapticFeedbackUtil.success();
        navigatorKey.currentContext?.showSnackBar(
          persist: false,
          duration: AppDurations.fiveSeconds,
          content:
              '''$newCommentsCount new comment${newCommentsCount > 1 ? 's' : ''} fetched.''',
          label: openInThreadSearch == null ? null : 'Search',
          action: openInThreadSearch == null
              ? null
              : () {
                  resetSearch();
                  search('', isNewSelected: true);
                  openInThreadSearch?.call();
                },
        );
      }
    }
  }

  void _onCommentFetched(BuildableComment? comment) {
    if (comment != null) {
      final Comment? prevState = _previousCommentStates?[comment.id];
      final int parentIndex =
          state.comments.indexWhere((Comment c) => c.id == comment?.parent);
      if (parentIndex > -1) {
        final Comment parent = state.comments.elementAt(parentIndex);
        comment = comment.copyWith(
          isHiddenByUser: parent.isHiddenByUser || parent.isCollapsedByUser,
          isNew: _previousCommentStates != null && prevState == null,
        );
      } else if ((_previousCommentStates?.isNotEmpty ?? false) &&
          prevState == null) {
        final Comment? parent = _previousCommentStates?[comment.parent];
        if (parent == null) {
          comment = comment.copyWith(
            isNew: true,
          );
        } else {
          comment = comment.copyWith(
            isHiddenByUser: parent.isCollapsedByUser || parent.isHiddenByUser,
            isNew: true,
          );
        }
        _previousCommentStates?[comment.id] = comment;
      } else {
        comment = comment.copyWith(
          isCollapsedByUser: prevState?.isCollapsedByUser,
          isHiddenByUser: prevState?.isHiddenByUser,
          isNew: false,
        );
      }

      globalKeys[comment.id] = GlobalKey(
        debugLabel: 'comment_tile_key_${comment.id}_under_${state.item.id}',
      );
      _commentCache.cacheComment(comment);

      if (state.isOfflineReading) {
        _sembastRepository.cacheComment(comment);
      }

      // Hide comment that matches any of the filter keywords.
      final bool hidden = _filterCubit.state.keywords.any(
        (String keyword) => comment!.text.toLowerCase().contains(keyword),
      );
      final List<Comment> updatedComments = <Comment>[
        ...state.comments,
        comment.copyWith(hidden: hidden),
      ];

      final Map<int, Comment> updatedIdToCommentMap =
          Map<int, Comment>.from(state.idToCommentMap);
      updatedIdToCommentMap[comment.id] = comment;

      emit(
        state.copyWith(
          comments: updatedComments,
          idToCommentMap: updatedIdToCommentMap,
        ),
      );
    }
  }

  static Future<Item?> _toBuildable(Item? item) async {
    if (item == null) return null;

    switch (item.runtimeType) {
      case Comment:
        return _toBuildableComment(item as Comment);
      case Story:
        return _toBuildableStory(item as Story);
    }

    return null;
  }

  static Future<BuildableComment?> _toBuildableComment(
    Comment? comment, {
    String? withHighlightedText,
  }) async {
    if (comment == null) return null;

    final List<LinkifyElement> elements = await Isolate.run(
      () => LinkifierUtil.linkify(
        comment.text,
        extraLinkifiers: <Linkifier>[
          if (withHighlightedText != null && withHighlightedText.isNotEmpty)
            HighlightLinkifier(highlightedText: withHighlightedText),
        ],
      ),
    );

    final BuildableComment buildableComment =
        BuildableComment.fromComment(comment, elements: elements);

    return buildableComment;
  }

  static Future<BuildableStory?> _toBuildableStory(Story? story) async {
    if (story == null) {
      return null;
    } else if (story.text.isEmpty) {
      return BuildableStory.fromTitleOnlyStory(story);
    }

    final List<LinkifyElement> elements =
        await compute<String, List<LinkifyElement>>(
      LinkifierUtil.linkify,
      story.text,
    );

    final BuildableStory buildableStory =
        BuildableStory.fromStory(story, elements: elements);

    return buildableStory;
  }

  void _onAppHidden(AppLifecycleState _) => _preserveCollapseState();

  @override
  Future<void> close() async {
    await _streamSubscription?.cancel();
    for (final StreamSubscription<Comment> s in _streamSubscriptions.values) {
      await s.cancel();
    }
    await _searchStreamSubscription?.cancel();
    await _appStateSubscription.cancel();
    _preserveCollapseState();
    await super.close();
  }

  static Rect? _getWidgetRect(GlobalKey targetGlobalKey) {
    final RenderBox? renderBox =
        targetGlobalKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    return offset & size;
  }

  static void _startShine(
    BuildContext targetContext,
    GlobalKey targetGlobalKey,
  ) {
    final Rect? rect = _getWidgetRect(targetGlobalKey);
    if (rect == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ShineOverlay(
        rect: rect,
        onDone: () => entry.remove(),
      ),
    );

    Overlay.of(targetContext).insert(entry);
  }

  @override
  String get logIdentifier => 'CommentsCubit';
}
