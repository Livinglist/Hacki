import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

part 'comments_state.dart';

class CommentsCubit extends Cubit<CommentsState> {
  CommentsCubit(
      {Story? story,
      List<int>? commentIds,
      StoriesRepository? storiesRepository})
      : _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        assert(story != null || commentIds != null),
        super(CommentsState.init()) {
    init(story?.kids ?? commentIds!, story);
  }

  final StoriesRepository _storiesRepository;

  Future<void> init(List<int> commentIds, Story? story) async {
    if (story != null) {
      final updatedStory = await _storiesRepository.fetchStoryById(story.id);

      emit(state.copyWith(story: updatedStory));

      for (final id in updatedStory.kids) {
        await _storiesRepository
            .fetchCommentBy(commentId: id.toString())
            .then((comment) {
          emit(state.copyWith(
              comments: List.from(state.comments)..add(comment)));
        });
      }

      emit(state.copyWith(
        status: CommentsStatus.loaded,
      ));
    } else {
      for (final id in commentIds) {
        await _storiesRepository
            .fetchCommentBy(commentId: id.toString())
            .then((comment) {
          emit(state.copyWith(
              comments: List.from(state.comments)..add(comment)));
        });
      }

      emit(state.copyWith(
        status: CommentsStatus.loaded,
      ));
    }
  }

  Future<void> refresh() async {
    emit(state.copyWith(status: CommentsStatus.loading, comments: []));

    final updatedStory =
        await _storiesRepository.fetchStoryById(state.story.id);

    for (final id in updatedStory.kids) {
      await _storiesRepository
          .fetchCommentBy(commentId: id.toString())
          .then((comment) {
        emit(state.copyWith(comments: List.from(state.comments)..add(comment)));
      });
    }

    emit(state.copyWith(
      story: updatedStory,
      status: CommentsStatus.loaded,
    ));
  }
}
