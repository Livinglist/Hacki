import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/object_extension.dart';
import 'package:hacki/main.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/utils/linkifier_util.dart';
import 'package:linkify/linkify.dart';
import 'package:logger/logger.dart';
import 'package:rxdart/rxdart.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:visibility_detector/visibility_detector.dart';

part 'comments_state.dart';

class CommentsCubit extends Cubit<CommentsState> {
  CommentsCubit({
    required FilterCubit filterCubit,
    required CollapseCache collapseCache,
    CommentCache? commentCache,
    OfflineRepository? offlineRepository,
    StoriesRepository? storiesRepository,
    SembastRepository? sembastRepository,
    Logger? logger,
    required bool isOfflineReading,
    required Item item,
    required FetchMode defaultFetchMode,
    required CommentsOrder defaultCommentsOrder,
  })  : _filterCubit = filterCubit,
        _collapseCache = collapseCache,
        _commentCache = commentCache ?? locator.get<CommentCache>(),
        _offlineRepository =
            offlineRepository ?? locator.get<OfflineRepository>(),
        _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        _sembastRepository =
            sembastRepository ?? locator.get<SembastRepository>(),
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
  final CollapseCache _collapseCache;
  final CommentCache _commentCache;
  final OfflineRepository _offlineRepository;
  final StoriesRepository _storiesRepository;
  final SembastRepository _sembastRepository;
  final Logger _logger;
  final Map<int, double> _cmtIdToVisibilityMap = <int, double>{};

  /// The [StreamSubscription] for stream (both lazy or eager)
  /// fetching comments posted directly to the story.
  StreamSubscription<Comment>? _streamSubscription;

  /// The map of [StreamSubscription] for streams
  /// fetching comments lazily. [int] is the id of parent comment.
  final Map<int, StreamSubscription<Comment>> _streamSubscriptions =
      <int, StreamSubscription<Comment>>{};

  static const int _pageSize = 500;

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
  }) async {
    if (onlyShowTargetComment && (targetAncestors?.isNotEmpty ?? false)) {
      emit(
        state.copyWith(
          comments: targetAncestors,
          onlyShowTargetComment: true,
          status: CommentsStatus.allLoaded,
        ),
      );

      _streamSubscription = _storiesRepository
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
        status: CommentsStatus.loading,
        comments: <Comment>[],
        currentPage: 0,
      ),
    );

    final Item item = state.item;
    final Item updatedItem = state.isOfflineReading
        ? item
        : await _storiesRepository.fetchItem(id: item.id).then(_toBuildable) ??
            item;
    final List<int> kids = sortKids(updatedItem.kids);

    emit(state.copyWith(item: updatedItem));

    late final Stream<Comment> commentStream;

    if (state.isOfflineReading) {
      commentStream = _offlineRepository.getCachedCommentsStream(ids: kids);
    } else {
      switch (state.fetchMode) {
        case FetchMode.lazy:
          commentStream = _storiesRepository.fetchCommentsStream(
            ids: kids,
            getFromCache: useCommentCache ? _commentCache.getComment : null,
          );
          break;
        case FetchMode.eager:
          commentStream = _storiesRepository.fetchAllCommentsRecursivelyStream(
            ids: kids,
            getFromCache: useCommentCache ? _commentCache.getComment : null,
          );
          break;
      }
    }

    _streamSubscription = commentStream
        .asyncMap(_toBuildableComment)
        .whereNotNull()
        .listen(_onCommentFetched)
      ..onDone(_onDone);
  }

  Future<void> refresh() async {
    emit(
      state.copyWith(
        status: CommentsStatus.loading,
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
        await _storiesRepository.fetchItem(id: item.id) ?? item;
    final List<int> kids = sortKids(updatedItem.kids);

    late final Stream<Comment> commentStream;
    if (state.fetchMode == FetchMode.lazy) {
      commentStream = _storiesRepository.fetchCommentsStream(
        ids: kids,
      );
    } else {
      commentStream = _storiesRepository.fetchAllCommentsRecursivelyStream(
        ids: kids,
      );
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
    HapticFeedback.lightImpact();
    emit(
      state.copyWith(
        onlyShowTargetComment: false,
        item: story,
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
    if (comment == null && state.status == CommentsStatus.loading) return;

    switch (state.fetchMode) {
      case FetchMode.lazy:
        if (comment == null) return;
        if (_streamSubscriptions.containsKey(comment.id)) return;

        final int level = comment.level + 1;
        int offset = 0;

        /// Ignoring because the subscription will be cancelled in close()
        // ignore: cancel_subscriptions
        final StreamSubscription<Comment> streamSubscription =
            _storiesRepository
                .fetchCommentsStream(ids: comment.kids)
                .asyncMap(_toBuildableComment)
                .whereNotNull()
                .listen((Comment cmt) {
          _collapseCache.addKid(cmt.id, to: cmt.parent);
          _commentCache.cacheComment(cmt);
          _sembastRepository.cacheComment(cmt);

          emit(
            state.copyWith(
              comments: <Comment>[...state.comments]..insert(
                  state.comments.indexOf(comment) + offset + 1,
                  cmt.copyWith(level: level),
                ),
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
        break;
      case FetchMode.eager:
        if (_streamSubscription != null) {
          emit(state.copyWith(status: CommentsStatus.loading));
          _streamSubscription
            ?..resume()
            ..onData(onCommentFetched);
        }
        break;
    }
  }

  Future<void> loadParentThread() async {
    unawaited(HapticFeedback.lightImpact());
    emit(state.copyWith(fetchParentStatus: CommentsStatus.loading));
    final Story? parent = await _storiesRepository
        .fetchParentStory(id: state.item.id)
        .then(_toBuildableStory);

    if (parent == null) {
      return;
    } else {
      await HackiApp.navigatorKey.currentState?.pushNamed(
        ItemScreen.routeName,
        arguments: ItemScreenArgs(item: parent),
      );

      emit(
        state.copyWith(
          fetchParentStatus: CommentsStatus.loaded,
        ),
      );
    }
  }

  void onOrderChanged(CommentsOrder? order) {
    if (order == null) return;
    if (state.order == order) return;
    HapticFeedback.selectionClick();
    _streamSubscription?.cancel();
    for (final StreamSubscription<Comment> s in _streamSubscriptions.values) {
      s.cancel();
    }
    _streamSubscriptions.clear();
    emit(state.copyWith(order: order));
    init(useCommentCache: true);
  }

  void onFetchModeChanged(FetchMode? fetchMode) {
    if (fetchMode == null) return;
    if (state.fetchMode == fetchMode) return;
    _collapseCache.resetCollapsedComments();
    HapticFeedback.selectionClick();
    _streamSubscription?.cancel();
    for (final StreamSubscription<Comment> s in _streamSubscriptions.values) {
      s.cancel();
    }
    _streamSubscriptions.clear();
    emit(state.copyWith(fetchMode: fetchMode));
    init(useCommentCache: true);
  }

  void onVisibilityChanged(Comment cmt, VisibilityInfo info) {
    _cmtIdToVisibilityMap.update(
      cmt.id,
      (_) => info.visibleFraction,
      ifAbsent: () => info.visibleFraction,
    );
  }

  void jump(
    ItemScrollController itemScrollController,
    ItemPositionsListener itemPositionsListener,
    double alignment,
  ) {
    final length = state.comments.length;
    final lastIndex =
        state.comments.lastIndexWhere((e) => _cmtIdToVisibilityMap[e.id] == 1);
    for (int i = min(
      lastIndex,
      state.item is Story ? state.item.descendants : state.item.kids.length,
    );
        i < length;
        i++) {
      final Comment cmt = state.comments.elementAt(i);
      i.log();
      if (i != length - 1 &&
          state.comments.elementAt(i).isRoot &&
          _cmtIdToVisibilityMap[state.comments.elementAt(i).id] == 1 &&
          state.comments.elementAt(i + 1).isRoot &&
          _cmtIdToVisibilityMap[state.comments.elementAt(i + 1).id] == 1) {
        print('break!');
        continue;
      }

      print('${cmt.metadata}');
      print('the fraction for $i ${_cmtIdToVisibilityMap[cmt.id]}');

      if (_cmtIdToVisibilityMap[cmt.id] == 1) {
        final int curIndex = i;
        final int nextIndex = state.comments.indexWhere(
          (Comment element) => element.isRoot,
          min(curIndex + 1, state.comments.length - 1),
        );
        print('curIndex is $curIndex');
        print('scrolling to ${nextIndex}');
        if (nextIndex == -1) {
          loadMore(
            onCommentFetched: (Comment cmtFetched) {
              if (cmtFetched.isRoot) {
                itemScrollController.scrollTo(
                  index: state.comments.lastIndexWhere(
                    (Comment e) => e.id == cmtFetched.id,
                  ),
                  alignment: 0.2,
                  duration: const Duration(milliseconds: 400),
                );
              } else {
                if (state.status != CommentsStatus.loading &&
                    state.comments.length >=
                        _pageSize + _pageSize * state.currentPage &&
                    state.comments.length <=
                        _pageSize * 2 + _pageSize * state.currentPage) {
                  jump(
                    itemScrollController,
                    itemPositionsListener,
                    alignment,
                  );
                }
              }
            },
          );
        } else {
          itemScrollController.scrollTo(
            index: nextIndex,
            alignment: 0.2,
            duration: const Duration(milliseconds: 400),
          );
        }

        return;
      }
    }
  }

  void jumpUp(
    ItemScrollController itemScrollController,
    ItemPositionsListener itemPositionsListener,
  ) {
    Comment? prevRootCmt;
    for (final Comment cmt in state.comments) {
      print(state.comments.indexOf(cmt));
      print(cmt.isRoot);
      print(_cmtIdToVisibilityMap[cmt.id]);
      if (cmt.isRoot && (_cmtIdToVisibilityMap[cmt.id] ?? 0) == 1) {
        final int curIndex = state.comments.indexOf(cmt);
        final int nextIndex =
            state.comments.sublist(0, curIndex).lastIndexWhere(
                  (Comment element) => element.isRoot,
                );

        print('curIndex is $curIndex');
        print('scrolling to ${nextIndex}');

        if (nextIndex == -1) {
          // TODO
        } else {
          itemScrollController.scrollTo(
            index: nextIndex,
            alignment: 0.2,
            duration: const Duration(milliseconds: 400),
          );
        }

        return;
      } else if (state.comments.last.id == cmt.id && prevRootCmt != null) {
        final index = state.comments.indexOf(prevRootCmt);
        print('curIndex is last');
        print('scrolling to ${index}');
        itemScrollController.scrollTo(
          index: index,
          alignment: 0.2,
          duration: const Duration(milliseconds: 400),
        );
      }

      if (cmt.isRoot) {
        prevRootCmt = cmt;
      }
    }
  }

  List<int> sortKids(List<int> kids) {
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
      _sembastRepository.cacheComment(comment);

      final bool hidden = _filterCubit.state.keywords.any(
        (String keyword) => comment.text.toLowerCase().contains(keyword),
      );
      final List<Comment> updatedComments = <Comment>[
        ...state.comments,
        comment.copyWith(hidden: hidden),
      ];

      emit(state.copyWith(comments: updatedComments));

      if (state.fetchMode == FetchMode.eager) {
        if (updatedComments.length >=
                _pageSize + _pageSize * state.currentPage &&
            updatedComments.length <=
                _pageSize * 2 + _pageSize * state.currentPage) {
          final bool isHidden = _collapseCache.isHidden(comment.id);

          if (!isHidden) {
            _streamSubscription?.pause();

            emit(
              state.copyWith(
                status: CommentsStatus.loaded,
              ),
            );
          }

          emit(
            state.copyWith(
              currentPage: state.currentPage + 1,
            ),
          );
        }
      }
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
