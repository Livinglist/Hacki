import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/services/services.dart';

part 'collapse_state.dart';

class CollapseCubit extends Cubit<CollapseState> {
  CollapseCubit({
    required int commentId,
    CollapseCache? collapseCache,
  })  : _commentId = commentId,
        _collapseCache = collapseCache ?? locator.get<CollapseCache>(),
        super(const CollapseState.init());

  final int _commentId;
  final CollapseCache _collapseCache;
  late final StreamSubscription<Map<int, Set<int>>> _streamSubscription;

  void init() {
    _streamSubscription =
        _collapseCache.hiddenComments.listen(hiddenCommentsStreamListener);

    emit(
      state.copyWith(
        collapsedCount: _collapseCache.totalHidden(_commentId),
        collapsed: _collapseCache.isCollapsed(_commentId),
        hidden: _collapseCache.isHidden(_commentId),
        locked: _collapseCache.lockedId == _commentId,
      ),
    );
  }

  void collapse({required VoidCallback onDone}) {
    if (state.collapsed) {
      _collapseCache.uncollapse(_commentId);

      emit(
        state.copyWith(
          collapsed: false,
          collapsedCount: 0,
        ),
      );

      onDone();
    } else {
      if (state.locked) {
        emit(state.copyWith(locked: false));
        return;
      }

      final Set<int> collapsedCommentIds = _collapseCache.collapse(_commentId);

      emit(
        state.copyWith(
          collapsed: true,
          collapsedCount: state.collapsed ? 0 : collapsedCommentIds.length,
        ),
      );

      onDone();
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

  /// Prevent the item to be able to collapse, used when the comment
  /// text is selected.
  void lock() {
    _collapseCache.lockedId = _commentId;
    emit(state.copyWith(locked: true));
  }

  @override
  Future<void> close() async {
    await _streamSubscription.cancel();
    await super.close();
  }
}
