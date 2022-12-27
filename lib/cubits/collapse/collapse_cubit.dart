import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/services/services.dart';

part 'collapse_state.dart';

class CollapseCubit extends Cubit<CollapseState> {
  CollapseCubit({
    required int commentId,
    required CommentsCubit commentsCubit,
    CollapseCache? collapseCache,
  })  : _commentId = commentId,
        _collapseCache = collapseCache ?? locator.get<CollapseCache>(),
        _commentsCubit = commentsCubit,
        super(const CollapseState.init());

  final int _commentId;
  final CollapseCache _collapseCache;
  final CommentsCubit _commentsCubit;
  late final StreamSubscription<Map<int, Set<int>>> _streamSubscription;

  void init() {
    _streamSubscription =
        _collapseCache.hiddenComments.listen(hiddenCommentsStreamListener);

    emit(
      state.copyWith(
        collapsedCount: _collapseCache.totalHidden(_commentId),
        collapsed: _collapseCache.isCollapsed(_commentId),
        hidden: _collapseCache.isHidden(_commentId),
      ),
    );
  }

  void collapse() {
    if (state.collapsed) {
      _collapseCache.uncollapse(_commentId);

      emit(
        state.copyWith(
          collapsed: false,
          collapsedCount: 0,
        ),
      );
    } else {
      final Set<int> collapsedCommentIds = _collapseCache.collapse(_commentId);
      final int lastCommentId = _commentsCubit.state.comments.last.id;
      final bool shouldLoadMore = _commentId == lastCommentId ||
          collapsedCommentIds.contains(lastCommentId);

      if (shouldLoadMore) {
        _commentsCubit.loadMore();
      }

      emit(
        state.copyWith(
          collapsed: true,
          collapsedCount: state.collapsed ? 0 : collapsedCommentIds.length,
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
