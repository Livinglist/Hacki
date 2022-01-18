import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/services/cache_service.dart';

part 'comments_state.dart';

class CommentsCubit<T extends Item> extends Cubit<CommentsState> {
  CommentsCubit(
      {T? item,
      CacheService? cacheService,
      StoriesRepository? storiesRepository})
      : _cacheService = cacheService ?? locator.get<CacheService>(),
        _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        super(CommentsState<T>.init()) {
    init(item!);
  }

  final CacheService _cacheService;
  final StoriesRepository _storiesRepository;

  Future<void> init(T item) async {
    if (item is Story) {
      final story = item;
      final updatedStory = await _storiesRepository.fetchStoryById(story.id);

      emit(state.copyWith(item: updatedStory));

      for (final id in updatedStory.kids) {
        final cachedComment = _cacheService.getComment(id);
        if (cachedComment != null) {
          emit(state.copyWith(
              comments: List.from(state.comments)..add(cachedComment)));
        } else {
          await _storiesRepository
              .fetchCommentBy(commentId: id.toString())
              .then(_onCommentFetched);
        }
      }

      emit(state.copyWith(
        status: CommentsStatus.loaded,
      ));
    } else {
      final comment = item;

      emit(state.copyWith(
        item: item,
        collapsed: _cacheService.isCollapsed(item.id),
      ));

      for (final id in comment.kids) {
        final cachedComment = _cacheService.getComment(id);
        if (cachedComment != null) {
          emit(state.copyWith(
              comments: List.from(state.comments)..add(cachedComment)));
        } else {
          await _storiesRepository
              .fetchCommentBy(commentId: id.toString())
              .then(_onCommentFetched);
        }
      }

      emit(state.copyWith(
        status: CommentsStatus.loaded,
      ));
    }
  }

  Future<void> refresh() async {
    emit(state.copyWith(status: CommentsStatus.loading, comments: []));

    final story = (state.item as Story?)!;
    final updatedStory = await _storiesRepository.fetchStoryById(story.id);

    for (final id in updatedStory.kids) {
      final cachedComment = _cacheService.getComment(id);
      if (cachedComment != null) {
        emit(state.copyWith(
            comments: List.from(state.comments)..add(cachedComment)));
      } else {
        await _storiesRepository
            .fetchCommentBy(commentId: id.toString())
            .then(_onCommentFetched);
      }
    }

    emit(state.copyWith(
      item: updatedStory,
      status: CommentsStatus.loaded,
    ));
  }

  void collapse() {
    _cacheService.updateCollapsedComments(state.item!.id);
    emit(state.copyWith(collapsed: !state.collapsed));
  }

  void _onCommentFetched(Comment? comment) {
    if (comment != null) {
      _cacheService.cacheComment(comment);
      emit(state.copyWith(comments: List.from(state.comments)..add(comment)));
    }
  }
}
