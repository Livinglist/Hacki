import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/services/services.dart';

part 'collapse_state.dart';

class CollapseCubit extends Cubit<CollapseState> {
  CollapseCubit({
    required int commentId,
    CacheService? cacheService,
  })  : _commentId = commentId,
        _cacheService = cacheService ?? locator.get<CacheService>(),
        super(const CollapseState.init());

  final int _commentId;
  final CacheService _cacheService;
  late final StreamSubscription<Map<int, Set<int>>> _streamSubscription;

  void init() {
    _streamSubscription =
        _cacheService.hiddenComments.listen(hiddenCommentsStreamListener);

    emit(
      state.copyWith(
        collapsedCount: _cacheService.totalHidden(_commentId),
        collapsed: _cacheService.isCollapsed(_commentId),
        hidden: _cacheService.isHidden(_commentId),
      ),
    );
  }

  void collapse() {
    if (state.collapsed) {
      _cacheService.uncollapse(_commentId);

      emit(
        state.copyWith(
          collapsed: false,
          collapsedCount: 0,
        ),
      );
    } else {
      final int count = _cacheService.collapse(_commentId);

      emit(
        state.copyWith(
          collapsed: true,
          collapsedCount: state.collapsed ? 0 : count,
        ),
      );
    }
  }

  void hiddenCommentsStreamListener(Map<int, Set<int>> event) {
    int collapsedCount = 0;
    for (final int key in event.keys) {
      if (key == _commentId && !isClosed) {
        collapsedCount = event[key]?.length ?? 0;
        break;
      }
    }

    for (final Set<int> val in event.values) {
      if (val.contains(_commentId) && !isClosed) {
        emit(
          state.copyWith(
            hidden: true,
            collapsedCount: collapsedCount,
          ),
        );
        return;
      }
    }

    if (!isClosed) {
      emit(
        state.copyWith(
          hidden: false,
          collapsedCount: collapsedCount,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _streamSubscription.cancel();
    await super.close();
  }
}
