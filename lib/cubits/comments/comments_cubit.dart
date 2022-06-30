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

part 'comments_state.dart';

class CommentsCubit extends Cubit<CommentsState> {
  CommentsCubit({
    required CollapseCache collapseCache,
    CommentCache? commentCache,
    OfflineRepository? offlineRepository,
    StoriesRepository? storiesRepository,
    SembastRepository? sembastRepository,
    required bool offlineReading,
    required Item item,
  })  : _collapseCache = collapseCache,
        _commentCache = commentCache ?? locator.get<CommentCache>(),
        _offlineRepository =
            offlineRepository ?? locator.get<OfflineRepository>(),
        _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        _sembastRepository =
            sembastRepository ?? locator.get<SembastRepository>(),
        super(CommentsState.init(offlineReading: offlineReading, item: item));

  final CollapseCache _collapseCache;
  final CommentCache _commentCache;
  final OfflineRepository _offlineRepository;
  final StoriesRepository _storiesRepository;
  final SembastRepository _sembastRepository;
  StreamSubscription<Comment>? _streamSubscription;

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
          status: CommentsStatus.loaded,
        ),
      );

      _streamSubscription = _storiesRepository
          .fetchAllCommentsStream(
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
      if (state.fetchMode == FetchMode.lazy) {
        _streamSubscription = _storiesRepository
            .fetchCommentsStream(
              ids: kids,
              getFromCache: useCommentCache ? _commentCache.getComment : null,
            )
            .listen(_onCommentFetched)
          ..onDone(_onDone);
      } else {
        _streamSubscription = _storiesRepository
            .fetchAllCommentsStream(
              ids: kids,
              getFromCache: useCommentCache ? _commentCache.getComment : null,
            )
            .listen(_onCommentFetched)
          ..onDone(_onDone);
      }
    }
  }

  Future<void> refresh() async {
    if (state.offlineReading) {
      emit(
        state.copyWith(
          status: CommentsStatus.loaded,
        ),
      );
      return;
    }

    _collapseCache.resetCollapsedComments();

    emit(
      state.copyWith(
        status: CommentsStatus.loading,
        comments: <Comment>[],
        currentPage: 0,
      ),
    );

    await _streamSubscription?.cancel();

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
          .fetchAllCommentsStream(
            ids: kids,
          )
          .listen(_onCommentFetched)
        ..onDone(_onDone);
    }

    emit(
      state.copyWith(
        item: updatedItem,
        status: CommentsStatus.loaded,
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
    if (state.fetchMode == FetchMode.eager) {
      if (_streamSubscription != null) {
        emit(state.copyWith(status: CommentsStatus.loading));
        _streamSubscription?.resume();
      }
    } else {
      if (comment == null) return;

      final int level = comment.level + 1;
      int offset = 0;

      _streamSubscription = _streamSubscription =
          _storiesRepository.fetchCommentsStream(ids: comment.kids).listen(
        (Comment cmt) {
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
        },
      );
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
    emit(state.copyWith(order: order));
    init(useCommentCache: true);
  }

  void onFetchModeChanged(FetchMode? fetchMode) {
    if (fetchMode == null) return;
    if (state.fetchMode == fetchMode) return;
    _collapseCache.resetCollapsedComments();
    HapticFeedback.selectionClick();
    _streamSubscription?.cancel();
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
    await super.close();
  }
}
