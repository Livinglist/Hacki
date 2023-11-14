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
    CommentCache? commentCache,
  })  : _sembastRepository =
            sembastRepository ?? locator.get<SembastRepository>(),
        _commentCache = commentCache ?? locator.get<CommentCache>(),
        super(TimeMachineState.init());

  final SembastRepository _sembastRepository;
  final CommentCache _commentCache;

  Future<void> activateTimeMachine(Comment comment) async {
    emit(state.copyWith(ancestors: <Comment>[]));

    final List<Comment> ancestors = <Comment>[];
    Comment? parent = _commentCache.getComment(comment.parent);
    parent ??= await _sembastRepository.getCachedComment(id: comment.parent);

    while (parent != null) {
      ancestors.insert(0, parent);

      final int parentId = parent.parent;
      parent = _commentCache.getComment(parentId);
      parent ??= await _sembastRepository.getCachedComment(id: parentId);
    }

    emit(state.copyWith(ancestors: ancestors));
  }
}
