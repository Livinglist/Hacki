import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart' show Comment;
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/services/services.dart';

part 'time_machine_state.dart';

class TimeMachineCubit extends Cubit<TimeMachineState> {
  TimeMachineCubit({
    SembastRepository? sembastRepository,
    StoriesRepository? storiesRepository,
    CommentCache? commentCache,
  })  : _sembastRepository =
            sembastRepository ?? locator.get<SembastRepository>(),
        _storiesRepository =
            storiesRepository ?? locator.get<StoriesRepository>(),
        _commentCache = commentCache ?? locator.get<CommentCache>(),
        super(TimeMachineState.init());

  final SembastRepository _sembastRepository;
  final StoriesRepository _storiesRepository;
  final CommentCache _commentCache;

  Future<void> activateTimeMachine(Comment comment) async {
    emit(state.copyWith(parents: <Comment>[]));

    final int level = comment.level;
    final List<Comment> parents = <Comment>[];
    Comment? parent = _commentCache.getComment(comment.parent);
    parent ??= await _sembastRepository.getCachedComment(id: comment.parent);
    parent ??= await _storiesRepository.fetchCommentBy(id: comment.parent);

    while (parent != null) {
      parents.insert(0, parent);

      if (parents.length == level) break;

      final int parentId = parent.parent;
      parent = _commentCache.getComment(parentId);
      parent ??= await _sembastRepository.getCachedComment(id: parentId);
      parent ??= await _storiesRepository.fetchCommentBy(id: parentId);
    }

    emit(state.copyWith(parents: parents));
  }
}
