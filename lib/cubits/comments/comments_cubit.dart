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
    CacheService? cacheService,
    CacheRepository? cacheRepository,
    StoriesRepository? storiesRepository,
    SembastRepository? sembastRepository,
    required bool offlineReading,
    required Item item,
  })  : _cacheService = cacheService ?? locator.get<CacheService>(),
        _cacheRepository = cacheRepository ?? locator.get<CacheRepository>(),
        _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        _sembastRepository =
            sembastRepository ?? locator.get<SembastRepository>(),
        super(CommentsState.init(offlineReading: offlineReading, item: item));

  final CacheService _cacheService;
  final CacheRepository _cacheRepository;
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
          .fetchCommentsStream(
            ids: targetParents!.last.kids,
            level: targetParents.last.level + 1,
          )
          .listen(_onCommentFetched)
        ..onDone(_onDone);

      return;
    }

    emit(state.copyWith(status: CommentsStatus.loading));

    final Item item = state.item;
    final Item updatedItem = state.offlineReading
        ? item
        : await _storiesRepository.fetchItemBy(id: item.id) ?? item;
    final List<int> kids = () {
      switch (state.order) {
        case CommentsOrder.natural:
          return updatedItem.kids;
        case CommentsOrder.newestFirst:
          return updatedItem.kids.sorted((int a, int b) => b.compareTo(a));
        case CommentsOrder.oldestFirst:
          return updatedItem.kids.sorted((int a, int b) => a.compareTo(b));
      }
    }();

    emit(state.copyWith(item: updatedItem));

    if (state.offlineReading) {
      _streamSubscription = _cacheRepository
          .getCachedCommentsStream(ids: kids)
          .listen(_onCommentFetched)
        ..onDone(_onDone);
    } else {
      _streamSubscription = _storiesRepository
          .fetchCommentsStream(ids: kids)
          .listen(_onCommentFetched)
        ..onDone(_onDone);
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

    _cacheService
      ..resetComments()
      ..resetCollapsedComments();

    emit(
      state.copyWith(
        status: CommentsStatus.loading,
        comments: <Comment>[],
      ),
    );

    await _streamSubscription?.cancel();

    final Item item = state.item;
    final Item updatedItem =
        await _storiesRepository.fetchItemBy(id: item.id) ?? item;
    final List<int> kids = () {
      switch (state.order) {
        case CommentsOrder.natural:
          return updatedItem.kids;
        case CommentsOrder.newestFirst:
          return updatedItem.kids.sorted((int a, int b) => b.compareTo(a));
        case CommentsOrder.oldestFirst:
          return updatedItem.kids.sorted((int a, int b) => a.compareTo(b));
      }
    }();

    _streamSubscription = _storiesRepository
        .fetchCommentsStream(ids: kids)
        .listen(_onCommentFetched)
      ..onDone(_onDone);

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
        comments: <Comment>[],
        item: story,
      ),
    );
    init();
  }

  void loadMore() {
    if (_streamSubscription != null) {
      emit(state.copyWith(status: CommentsStatus.loading));
      _streamSubscription?.resume();
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
    HapticFeedback.selectionClick();
    if (order == null) return;
    _streamSubscription?.cancel();
    emit(state.copyWith(order: order, comments: <Comment>[]));
    init();
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
      _cacheService
        ..addKid(comment.id, to: comment.parent)
        ..cacheComment(comment);
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

      if (updatedComments.length >= _pageSize + _pageSize * state.currentPage &&
          updatedComments.length <=
              _pageSize * 2 + _pageSize * state.currentPage) {
        final bool isHidden = _cacheService.isHidden(comment.id);

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
