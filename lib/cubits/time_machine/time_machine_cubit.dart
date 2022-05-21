import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart' show Comment;
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/services/cache_service.dart';

part 'time_machine_state.dart';

class TimeMachineCubit extends Cubit<TimeMachineState> {
  TimeMachineCubit({
    SembastRepository? sembastRepository,
    CacheService? cacheService,
  })  : _sembastRepository =
            sembastRepository ?? locator.get<SembastRepository>(),
        _cacheService = cacheService ?? locator.get<CacheService>(),
        super(TimeMachineState.init());

  final SembastRepository _sembastRepository;
  final CacheService _cacheService;

  Future<void> activateTimeMachine(Comment comment) async {
    emit(state.copyWith(parents: <Comment>[]));

    final List<Comment> parents = <Comment>[];
    Comment? parent = _cacheService.getComment(comment.parent);
    parent ??= await _sembastRepository.getCachedComment(id: comment.parent);

    while (parent != null) {
      parents.insert(0, parent);

      final int parentId = parent.parent;
      parent = _cacheService.getComment(parentId);
      parent ??= await _sembastRepository.getCachedComment(id: parentId);
    }

    emit(state.copyWith(parents: parents));
  }
}
