import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart' show Comment;
import 'package:hacki/services/cache_service.dart';

part 'time_machine_state.dart';

class TimeMachineCubit extends Cubit<TimeMachineState> {
  TimeMachineCubit({CacheService? cacheService})
      : _cacheService = cacheService ?? locator.get<CacheService>(),
        super(TimeMachineState.init());

  final CacheService _cacheService;

  void activateTimeMachine(Comment comment) {
    emit(state.copyWith(parents: <Comment>[]));

    final List<Comment> parents = <Comment>[];
    Comment? parent = _cacheService.getComment(comment.parent);

    while (parent != null) {
      parents.insert(0, parent);

      parent = _cacheService.getComment(parent.parent);
    }

    emit(state.copyWith(parents: parents));
  }
}
