import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

part 'comments_state.dart';

class CommentsCubit extends Cubit<CommentsState> {
  CommentsCubit(
      {required List<int> commentIds, StoriesRepository? storiesRepository})
      : _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        super(CommentsState.init()) {
    init(commentIds);
  }

  final StoriesRepository _storiesRepository;

  void init(List<int> commentIds) {
    for (final id in commentIds) {
      _storiesRepository
          .fetchCommentBy(commentId: id.toString())
          .then((comment) {
        emit(state.copyWith(comments: List.from(state.comments)..add(comment)));
      });
    }
  }
}
