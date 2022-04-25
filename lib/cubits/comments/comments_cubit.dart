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

  @override
  void emit(CommentsState state) {
    if (!isClosed) {
      super.emit(state);
    }
  }

  Future<void> init({
    bool onlyShowTargetComment = false,
    Comment? targetComment,
  }) async {
    if (onlyShowTargetComment) {
      emit(state.copyWith(
        comments: targetComment != null ? [targetComment] : [],
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

      for (final id in updatedStory.kids) {
        final cachedComment = _cacheService.getComment(id);
        if (cachedComment != null) {
          emit(state.copyWith(
              comments: List.from(state.comments)..add(cachedComment)));
        } else {
          if (state.offlineReading) {
            await _cacheRepository
                .getCachedComment(id: id)
                .then(_onCommentFetched);
          } else {
            await _storiesRepository
                .fetchCommentBy(id: id)
                .then(_onCommentFetched);
          }
        }
      }

      emit(state.copyWith(
        status: CommentsStatus.loaded,
      ));
    } else {
      final comment = state.item as Comment;

      emit(state.copyWith(
        collapsed: _cacheService.isCollapsed(state.item.id),
      ));

      for (final id in comment.kids) {
        final cachedComment = _cacheService.getComment(id);
        if (cachedComment != null) {
          emit(state.copyWith(
              comments: List.from(state.comments)..add(cachedComment)));
        } else {
          if (state.offlineReading) {
            await _cacheRepository
                .getCachedComment(id: id)
                .then(_onCommentFetched);
          } else {
            await _storiesRepository
                .fetchCommentBy(id: id)
                .then(_onCommentFetched);
          }
        }
      }

      emit(state.copyWith(
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

    for (final id in updatedStory.kids) {
      final cachedComment = _cacheService.getComment(id);
      if (cachedComment != null) {
        emit(state.copyWith(
            comments: List.from(state.comments)..add(cachedComment)));
      } else {
        final offlineReading = await _cacheRepository.hasCachedStories;

        if (offlineReading) {
          await _cacheRepository
              .getCachedComment(id: id)
              .then(_onCommentFetched);
        } else {
          await _storiesRepository
              .fetchCommentBy(id: id)
              .then(_onCommentFetched);
        }
      }
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

  void _onCommentFetched(Comment? comment) {
    if (comment != null) {
      _cacheService.cacheComment(comment);
      emit(state.copyWith(comments: List.from(state.comments)..add(comment)));
    }
  }
}
