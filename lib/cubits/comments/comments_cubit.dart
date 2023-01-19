import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/main.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/services/services.dart';
import 'package:logger/logger.dart';

part 'comments_state.dart';

class CommentsCubit extends Cubit<CommentsState> {
  CommentsCubit({
    required CollapseCache collapseCache,
    CommentCache? commentCache,
    OfflineRepository? offlineRepository,
    StoriesRepository? storiesRepository,
    SembastRepository? sembastRepository,
    Logger? logger,
    required bool offlineReading,
    required Item item,
    required FetchMode defaultFetchMode,
    required CommentsOrder defaultCommentsOrder,
  })  : _collapseCache = collapseCache,
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
            offlineReading: offlineReading,
            item: item,
            fetchMode: defaultFetchMode,
            order: defaultCommentsOrder,
          ),
        );

  final CollapseCache _collapseCache;
  final CommentCache _commentCache;
  final OfflineRepository _offlineRepository;
  final StoriesRepository _storiesRepository;
  final SembastRepository _sembastRepository;
  final Logger _logger;

  /// The [StreamSubscription] for stream (both lazy or eager)
  /// fetching comments posted directly to the story.
  StreamSubscription<Comment>? _streamSubscription;

  /// The map of [StreamSubscription] for streams
  /// fetching comments lazily. [int] is the id of parent comment.
  final Map<int, StreamSubscription<Comment>> _streamSubscriptions =
      <int, StreamSubscription<Comment>>{};

  static const int _pageSize = 20;

  @override
  void emit(CommentsState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> init({
    bool onlyShowTargetComment = false,
    bool useCommentCache = false,
    List<Comment>? targetParents,
  }) async {
    if (onlyShowTargetComment && (targetParents?.isNotEmpty ?? false)) {
      emit(
        state.copyWith(
          comments: targetParents,
          onlyShowTargetComment: true,
          status: CommentsStatus.allLoaded,
        ),
      );

      _streamSubscription = _storiesRepository
          .fetchAllCommentsRecursivelyStream(
            ids: targetParents!.last.kids,
            level: targetParents.last.level + 1,
          )
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
    final Item updatedItem = state.offlineReading
        ? item
        : await _storiesRepository.fetchItemBy(id: item.id) ?? item;
    final List<int> kids = sortKids(updatedItem.kids);

    emit(state.copyWith(item: updatedItem));

    if (state.offlineReading) {
      _streamSubscription = _offlineRepository
          .getCachedCommentsStream(ids: kids)
          .listen(_onCommentFetched)
        ..onDone(_onDone);
    } else {
      switch (state.fetchMode) {
        case FetchMode.lazy:
          _streamSubscription = _storiesRepository
              .fetchCommentsStream(
                ids: kids,
                getFromCache: useCommentCache ? _commentCache.getComment : null,
              )
              .listen(_onCommentFetched)
            ..onDone(_onDone);
          break;
        case FetchMode.eager:
          _streamSubscription = _storiesRepository
              .fetchAllCommentsRecursivelyStream(
                ids: kids,
                getFromCache: useCommentCache ? _commentCache.getComment : null,
              )
              .listen(_onCommentFetched)
            ..onDone(_onDone);
          break;
      }
    }
  }

  Future<void> refresh() async {
    if (state.offlineReading) {
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
        await _storiesRepository.fetchItemBy(id: item.id) ?? item;
    final List<int> kids = sortKids(updatedItem.kids);

    if (state.fetchMode == FetchMode.lazy) {
      _streamSubscription = _storiesRepository
          .fetchCommentsStream(
            ids: kids,
          )
          .listen(_onCommentFetched)
        ..onDone(_onDone);
    } else {
      _streamSubscription = _storiesRepository
          .fetchAllCommentsRecursivelyStream(
            ids: kids,
          )
          .listen(_onCommentFetched)
        ..onDone(_onDone);
    }

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
  void loadMore({Comment? comment}) {
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
                .listen((Comment cmt) {
          _collapseCache.addKid(cmt.id, to: cmt.parent);
          _commentCache.cacheComment(cmt);
          _sembastRepository.cacheComment(cmt);

          final List<LinkifyElement> elements = _linkify(
            cmt.text,
          );

          final BuildableComment buildableComment =
              BuildableComment.fromComment(cmt, elements: elements);

          emit(
            state.copyWith(
              comments: <Comment>[...state.comments]..insert(
                  state.comments.indexOf(comment) + offset + 1,
                  buildableComment.copyWith(level: level),
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
          _streamSubscription?.resume();
        }
        break;
    }
  }

  Future<void> loadParentThread() async {
    unawaited(HapticFeedback.lightImpact());
    emit(state.copyWith(fetchParentStatus: CommentsStatus.loading));
    final Story? parent =
        await _storiesRepository.fetchParentStory(id: state.item.id);

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

  void _onCommentFetched(Comment? comment) {
    if (comment != null) {
      _collapseCache.addKid(comment.id, to: comment.parent);
      _commentCache.cacheComment(comment);
      _sembastRepository.cacheComment(comment);

      final List<LinkifyElement> elements = _linkify(
        comment.text,
      );

      final BuildableComment buildableComment =
          BuildableComment.fromComment(comment, elements: elements);

      final List<Comment> updatedComments = <Comment>[
        ...state.comments,
        buildableComment
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
          }

          emit(
            state.copyWith(
              currentPage: state.currentPage + 1,
              status: CommentsStatus.loaded,
            ),
          );
        }
      }
    }
  }

  static List<LinkifyElement> _linkify(
    String text, {
    LinkifyOptions options = const LinkifyOptions(),
    List<Linkifier> linkifiers = const <Linkifier>[
      UrlLinkifier(),
      EmailLinkifier(),
    ],
  }) {
    List<LinkifyElement> list = <LinkifyElement>[TextElement(text)];

    if (text.isEmpty) {
      return <LinkifyElement>[];
    }

    if (linkifiers.isEmpty) {
      return list;
    }

    for (final Linkifier linkifier in linkifiers) {
      list = linkifier.parse(list, options);
    }

    return list;
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
