import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/custom_router.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/utils/utils.dart';
import 'package:linkify/linkify.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

part 'comments_state.dart';

class CommentsCubit extends Cubit<CommentsState> {
  CommentsCubit({
    required FilterCubit filterCubit,
    required PreferenceCubit preferenceCubit,
    required CollapseCache collapseCache,
    required bool isOfflineReading,
    required Item item,
    required FetchMode defaultFetchMode,
    required CommentsOrder defaultCommentsOrder,
    CommentCache? commentCache,
    OfflineRepository? offlineRepository,
    SembastRepository? sembastRepository,
    HackerNewsRepository? hackerNewsRepository,
    HackerNewsWebRepository? hackerNewsWebRepository,
    Logger? logger,
  })  : _filterCubit = filterCubit,
        _preferenceCubit = preferenceCubit,
        _collapseCache = collapseCache,
        _commentCache = commentCache ?? locator.get<CommentCache>(),
        _offlineRepository =
            offlineRepository ?? locator.get<OfflineRepository>(),
        _sembastRepository =
            sembastRepository ?? locator.get<SembastRepository>(),
        _hackerNewsRepository =
            hackerNewsRepository ?? locator.get<HackerNewsRepository>(),
        _hackerNewsWebRepository =
            hackerNewsWebRepository ?? locator.get<HackerNewsWebRepository>(),
        _logger = logger ?? locator.get<Logger>(),
        super(
          CommentsState.init(
            isOfflineReading: isOfflineReading,
            item: item,
            fetchMode: defaultFetchMode,
            order: defaultCommentsOrder,
          ),
        );

  final FilterCubit _filterCubit;
  final PreferenceCubit _preferenceCubit;
  final CollapseCache _collapseCache;
  final CommentCache _commentCache;
  final OfflineRepository _offlineRepository;
  final SembastRepository _sembastRepository;
  final HackerNewsRepository _hackerNewsRepository;
  final HackerNewsWebRepository _hackerNewsWebRepository;
  final Logger _logger;

  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  /// The [StreamSubscription] for stream (both lazy or eager)
  /// fetching comments posted directly to the story.
  StreamSubscription<Comment>? _streamSubscription;

  /// The map of [StreamSubscription] for streams
  /// fetching comments lazily. [int] is the id of parent comment.
  final Map<int, StreamSubscription<Comment>> _streamSubscriptions =
      <int, StreamSubscription<Comment>>{};

  static const int _webFetchingCmtCountLowerLimit = 100;

  Future<bool> get _shouldFetchFromWeb async {
    final bool isOnWifi = await _isOnWifi;
    if (isOnWifi) {
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
      return true;
    }
  }

  static Future<bool> get _isOnWifi async {
    final ConnectivityResult status = await Connectivity().checkConnectivity();
    return status == ConnectivityResult.wifi;
  }

  @override
  void emit(CommentsState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> init({
    bool onlyShowTargetComment = false,
    bool useCommentCache = false,
    List<Comment>? targetAncestors,
    AppExceptionHandler? onError,
    bool fetchFromWeb = true,
  }) async {
    if (onlyShowTargetComment && (targetAncestors?.isNotEmpty ?? false)) {
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
        matchedComments: <int>[],
        inThreadSearchQuery: '',
        currentPage: 0,
      ),
    );

    final Item item = state.item;
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

    if (state.isOfflineReading) {
      commentStream = _offlineRepository.getCachedCommentsStream(ids: kids);
    } else {
      switch (state.fetchMode) {
        case FetchMode.lazy:
          commentStream = _hackerNewsRepository.fetchCommentsStream(
            ids: kids,
            getFromCache: useCommentCache ? _commentCache.getComment : null,
          );
        case FetchMode.eager:
          switch (state.order) {
            case CommentsOrder.natural:
              final bool shouldFetchFromWeb = await _shouldFetchFromWeb;
              if (fetchFromWeb && shouldFetchFromWeb) {
                _logger.d('fetching from web.');
                commentStream = _hackerNewsWebRepository
                    .fetchCommentsStream(state.item)
                    .handleError((dynamic e) {
                  _streamSubscription?.cancel();

                  _logger.e(e);

                  switch (e.runtimeType) {
                    case RateLimitedWithFallbackException:
                    case PossibleParsingException:
                    case BrowserNotRunningException:
                    case DelayNotFinishedException:
                      if (_preferenceCubit.state.devModeEnabled) {
                        onError?.call(e as AppException);
                      }

                      /// If fetching from web failed, fetch using API instead.
                      refresh(onError: onError, fetchFromWeb: false);
                    default:
                      onError?.call(GenericException());
                  }
                });
              } else {
                _logger.d('fetching from API.');
                commentStream =
                    _hackerNewsRepository.fetchAllCommentsRecursivelyStream(
                  ids: kids,
                  getFromCache:
                      useCommentCache ? _commentCache.getComment : null,
                );
              }
            case CommentsOrder.oldestFirst:
            case CommentsOrder.newestFirst:
              commentStream =
                  _hackerNewsRepository.fetchAllCommentsRecursivelyStream(
                ids: kids,
                getFromCache: useCommentCache ? _commentCache.getComment : null,
              );
          }
      }
    }

    _streamSubscription = commentStream
        .asyncMap(_toBuildableComment)
        .whereNotNull()
        .listen(_onCommentFetched)
      ..onDone(_onDone);
  }

  Future<void> refresh({
    required AppExceptionHandler? onError,
    bool fetchFromWeb = true,
  }) async {
    emit(
      state.copyWith(
        status: CommentsStatus.inProgress,
      ),
    );

    if (state.isOfflineReading) {
      emit(
        state.copyWith(
          status: CommentsStatus.allLoaded,
        ),
      );
      return;
    }

    _collapseCache.resetCollapsedComments();

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

    final Item item = state.item;
    final Item updatedItem =
        await _hackerNewsRepository.fetchItem(id: item.id) ?? item;
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
              _logger.d('fetching from web.');
              commentStream = _hackerNewsWebRepository
                  .fetchCommentsStream(state.item)
                  .handleError((dynamic e) {
                _logger.e(e);

                switch (e.runtimeType) {
                  case RateLimitedException:
                  case PossibleParsingException:
                  case BrowserNotRunningException:
                  case DelayNotFinishedException:
                    if (_preferenceCubit.state.devModeEnabled) {
                      onError?.call(e as AppException);
                    }

                    /// If fetching from web failed, fetch using API instead.
                    refresh(onError: onError, fetchFromWeb: false);
                  default:
                    onError?.call(GenericException());
                }
              });
            } else {
              _logger.d('fetching from API.');
              commentStream = _hackerNewsRepository
                  .fetchAllCommentsRecursivelyStream(ids: kids);
            }
          case CommentsOrder.oldestFirst:
          case CommentsOrder.newestFirst:
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
      ..onDone(_onDone);

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
        matchedComments: <int>[],
      ),
    );
    init();
  }

  /// [comment] is only used for lazy fetching.
  void loadMore({
    Comment? comment,
    void Function(Comment)? onCommentFetched,
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
          _collapseCache.addKid(cmt.id, to: cmt.parent);
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
              ..onError((dynamic error) {
                _logger.e(error);
                _streamSubscriptions[comment.id]?.cancel();
                _streamSubscriptions.remove(comment.id);
              });

        _streamSubscriptions[comment.id] = streamSubscription;
      case FetchMode.eager:
        if (_streamSubscription != null) {
          emit(state.copyWith(status: CommentsStatus.inProgress));
          _streamSubscription
            ?..resume()
            ..onData(onCommentFetched);
        }
    }
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
        '/${ItemScreen.routeName}',
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
        '/${ItemScreen.routeName}',
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
    HapticFeedbackUtil.selection();
    _streamSubscription?.cancel();
    for (final StreamSubscription<Comment> s in _streamSubscriptions.values) {
      s.cancel();
    }
    _streamSubscriptions.clear();
    emit(state.copyWith(order: order));
    init(useCommentCache: true);
  }

  void updateFetchMode(FetchMode? fetchMode) {
    if (fetchMode == null) return;
    if (state.fetchMode == fetchMode) return;
    _collapseCache.resetCollapsedComments();
    HapticFeedbackUtil.selection();
    _streamSubscription?.cancel();
    for (final StreamSubscription<Comment> s in _streamSubscriptions.values) {
      s.cancel();
    }
    _streamSubscriptions.clear();
    emit(state.copyWith(fetchMode: fetchMode));
    init(useCommentCache: true);
  }

  void scrollTo({
    required int index,
    double alignment = 0.0,
  }) {
    debugPrint('Scrolling to: $index, alignment: $alignment');
    itemScrollController.scrollTo(
      index: index,
      alignment: alignment,
      duration: AppDurations.ms400,
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
        .whereNotNull()
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
    } else {
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
        .whereNotNull()
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

  void search(String query, {String author = ''}) {
    resetSearch();

    late final bool Function(Comment cmt) conditionSatisfied;
    final String lowercaseQuery = query.toLowerCase();
    if (query.isEmpty && author.isEmpty) {
      return;
    } else if (author.isEmpty) {
      conditionSatisfied =
          (Comment cmt) => cmt.text.toLowerCase().contains(lowercaseQuery);
    } else if (query.isEmpty) {
      conditionSatisfied = (Comment cmt) => cmt.by == author;
    } else {
      conditionSatisfied = (Comment cmt) =>
          cmt.text.toLowerCase().contains(lowercaseQuery) && cmt.by == author;
    }

    emit(
      state.copyWith(
        inThreadSearchQuery: query,
        inThreadSearchAuthor: author,
      ),
    );

    for (final int i in 0.to(state.comments.length, inclusive: false)) {
      final Comment cmt = state.comments.elementAt(i);
      if (conditionSatisfied(cmt)) {
        emit(
          state.copyWith(
            matchedComments: <int>[...state.matchedComments, i],
          ),
        );
      }
    }
  }

  void resetSearch() => emit(
        state.copyWith(
          matchedComments: <int>[],
          inThreadSearchQuery: '',
          inThreadSearchAuthor: '',
        ),
      );

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

  void _onDone() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    emit(
      state.copyWith(
        status: CommentsStatus.allLoaded,
      ),
    );
  }

  void _onCommentFetched(BuildableComment? comment) {
    if (comment != null) {
      _collapseCache.addKid(comment.id, to: comment.parent);
      _commentCache.cacheComment(comment);

      if (state.isOfflineReading) {
        _sembastRepository.cacheComment(comment);
      }

      // Hide comment that matches any of the filter keywords.
      final bool hidden = _filterCubit.state.keywords.any(
        (String keyword) => comment.text.toLowerCase().contains(keyword),
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

  static Future<BuildableComment?> _toBuildableComment(Comment? comment) async {
    if (comment == null) return null;

    final List<LinkifyElement> elements =
        await compute<String, List<LinkifyElement>>(
      LinkifierUtil.linkify,
      comment.text,
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

  @override
  Future<void> close() async {
    await _streamSubscription?.cancel();
    for (final StreamSubscription<Comment> s in _streamSubscriptions.values) {
      await s.cancel();
    }
    await super.close();
  }
}
