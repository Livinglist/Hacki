import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart' show Comment;
import 'package:hacki/repositories/repositories.dart';

part 'time_machine_state.dart';

class TimeMachineCubit extends Cubit<TimeMachineState> {
  TimeMachineCubit({
    SembastRepository? sembastRepository,
  })  : _sembastRepository =
            sembastRepository ?? locator.get<SembastRepository>(),
        super(TimeMachineState.init());

  final SembastRepository _sembastRepository;

  Future<void> activateTimeMachine(Comment comment) async {
    emit(state.copyWith(ancestors: <Comment>[]));

    final List<Comment> ancestors = <Comment>[];
    Comment? parent =
        await _sembastRepository.getCachedComment(id: comment.parent);

    while (parent != null) {
      ancestors.insert(0, parent);

      final int parentId = parent.parent;
      parent = await _sembastRepository.getCachedComment(id: parentId);
    }

    emit(state.copyWith(ancestors: ancestors));
  }
}
