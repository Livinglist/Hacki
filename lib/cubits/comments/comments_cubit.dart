import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/services/services.dart';

part 'comments_state.dart';

class CommentsCubit<T extends Item> extends Cubit<CommentsState> {
  CommentsCubit({
    CacheService? cacheService,
    CacheRepository? cacheRepository,
    StoriesRepository? storiesRepository,
    SembastRepository? sembastRepository,
    required bool offlineReading,
    required T item,
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

    if (state.item is Story) {
      final Item story = state.item;
      final Item updatedStory = state.offlineReading
          ? story
          : await _storiesRepository.fetchStoryBy(story.id) ?? story;

      emit(state.copyWith(item: updatedStory));

      if (state.offlineReading) {
        _streamSubscription = _cacheRepository
            .getCachedCommentsStream(ids: updatedStory.kids)
            .listen(_onCommentFetched)
          ..onDone(_onDone);
      } else {
        _streamSubscription = _storiesRepository
            .fetchCommentsStream(ids: updatedStory.kids)
            .listen(_onCommentFetched)
          ..onDone(_onDone);
      }
    } else {
      emit(
        state.copyWith(
          collapsed: _cacheService.isCollapsed(state.item.id),
          status: CommentsStatus.loaded,
        ),
      );
    }
  }

  Future<void> refresh() async {
    final bool offlineReading = await _cacheRepository.hasCachedStories;

    if (offlineReading) {
      emit(
        state.copyWith(
          status: CommentsStatus.loaded,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: CommentsStatus.loading,
        comments: <Comment>[],
      ),
    );

    await _streamSubscription?.cancel();

    final Story story = (state.item as Story?)!;
    final Story updatedStory =
        await _storiesRepository.fetchStoryBy(story.id) ?? story;
    _streamSubscription = _storiesRepository
        .fetchCommentsStream(ids: updatedStory.kids)
        .listen(_onCommentFetched)
      ..onDone(_onDone);

    emit(
      state.copyWith(
        item: updatedStory,
        status: CommentsStatus.loaded,
      ),
    );
  }

  void collapse() {
    _cacheService.updateCollapsedComments(state.item.id);
    emit(state.copyWith(collapsed: !state.collapsed));
  }

  void loadAll(T item) {
    emit(
      state.copyWith(
        onlyShowTargetComment: false,
        comments: <Comment>[],
        item: item,
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
      _cacheService.cacheComment(comment);
      _sembastRepository.saveComment(comment);
      final List<Comment> updatedComments = <Comment>[
        ...state.comments,
        comment
      ];
      emit(state.copyWith(comments: updatedComments));

      if (updatedComments.length >= _pageSize + _pageSize * state.currentPage &&
          updatedComments.length <=
              _pageSize * 2 + _pageSize * state.currentPage) {
        _streamSubscription?.pause();

        emit(
          state.copyWith(
            currentPage: state.currentPage + 1,
            status: CommentsStatus.loaded,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    await _streamSubscription?.cancel();
    await super.close();
  }
}
