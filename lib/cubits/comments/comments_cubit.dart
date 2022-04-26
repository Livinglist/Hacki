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
    required bool offlineReading,
    required T item,
  })  : _cacheService = cacheService ?? locator.get<CacheService>(),
        _cacheRepository = cacheRepository ?? locator.get<CacheRepository>(),
        _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        super(CommentsState.init(offlineReading: offlineReading, item: item));

  final CacheService _cacheService;
  final CacheRepository _cacheRepository;
  final StoriesRepository _storiesRepository;
  StreamSubscription? _streamSubscription;

  static const _pageSize = 20;

  @override
  void emit(CommentsState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> init({
    bool onlyShowTargetComment = false,
    Comment? targetComment,
    List<Comment>? targetParents,
  }) async {
    if (onlyShowTargetComment) {
      emit(state.copyWith(
        comments: targetParents != null ? [...targetParents] : [],
        onlyShowTargetComment: true,
      ));
      return;
    }

    emit(state.copyWith(status: CommentsStatus.loading));

    if (state.item is Story) {
      final story = state.item;
      final updatedStory = state.offlineReading
          ? story
          : await _storiesRepository.fetchStoryBy(story.id) ?? story;

      emit(state.copyWith(item: updatedStory));

      if (state.offlineReading) {
        _cacheRepository
            .getCachedCommentsStream(ids: updatedStory.kids)
            .listen(_onCommentFetched)
            .onDone(() {
          emit(state.copyWith(
            status: CommentsStatus.loaded,
          ));
        });
      } else {
        _streamSubscription = _storiesRepository
            .fetchCommentsStream(ids: updatedStory.kids)
            .listen(_onCommentFetched);
        // ..onDone(() {
        //   emit(state.copyWith(
        //     status: CommentsStatus.loaded,
        //   ));
        // });
      }
    } else {
      emit(state.copyWith(
        collapsed: _cacheService.isCollapsed(state.item.id),
        status: CommentsStatus.loaded,
      ));
    }
  }

  Future<void> refresh() async {
    final offlineReading = await _cacheRepository.hasCachedStories;

    if (offlineReading) {
      emit(state.copyWith(
        status: CommentsStatus.loaded,
      ));
      return;
    }

    emit(state.copyWith(
      status: CommentsStatus.loading,
      comments: [],
    ));

    final story = (state.item as Story?)!;
    final updatedStory =
        await _storiesRepository.fetchStoryBy(story.id) ?? story;

    if (state.offlineReading) {
      _cacheRepository
          .getCachedCommentsStream(ids: updatedStory.kids)
          .listen(_onCommentFetched)
          .onDone(() {
        emit(state.copyWith(
          status: CommentsStatus.loaded,
        ));
      });
    } else {
      _streamSubscription = _storiesRepository
          .fetchCommentsStream(ids: updatedStory.kids)
          .listen(_onCommentFetched);
    }

    emit(state.copyWith(
      item: updatedStory,
      status: CommentsStatus.loaded,
    ));
  }

  void collapse() {
    _cacheService.updateCollapsedComments(state.item.id);
    emit(state.copyWith(collapsed: !state.collapsed));
  }

  void loadAll(T item) {
    emit(state.copyWith(
      onlyShowTargetComment: false,
      comments: [],
      item: item,
    ));
    init();
  }

  void loadMore() {
    emit(state.copyWith(status: CommentsStatus.loading));
    _streamSubscription?.resume();
  }

  void _onCommentFetched(Comment? comment) {
    if (comment != null) {
      _cacheService.cacheComment(comment);
      final updatedComments = [...state.comments, comment];
      emit(state.copyWith(comments: updatedComments));

      if (updatedComments.length >= _pageSize + _pageSize * state.currentPage &&
          updatedComments.length <=
              _pageSize * 2 + _pageSize * state.currentPage) {
        _streamSubscription?.pause();

        emit(state.copyWith(
          currentPage: state.currentPage + 1,
          status: CommentsStatus.loaded,
        ));
      }
    }
  }

  @override
  Future<void> close() async {
    await _streamSubscription?.cancel();
    await super.close();
  }
}
