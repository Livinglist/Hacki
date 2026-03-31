import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart' show TextEditingController;
import 'package:hacki/config/locator.dart';
import 'package:hacki/extensions/buildable_mixin.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/utils/haptic_feedback_util.dart';
import 'package:rxdart/rxdart.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> with BuildableMixin {
  SearchCubit({
    SearchRepository? searchRepository,
    TextEditingController? textEditingController,
  })  : _searchRepository = searchRepository ?? locator.get<SearchRepository>(),
        textEditingController =
            textEditingController ?? TextEditingController(),
        super(SearchState.init());

  final SearchRepository _searchRepository;
  final TextEditingController textEditingController;

  StreamSubscription<Item>? streamSubscription;

  void search(String query) {
    streamSubscription?.cancel();
    textEditingController.text = query;
    emit(
      state.copyWith(
        results: <Item>[],
        status: SearchStatus.loading,
        params: state.params.copyWith(query: query, page: 0),
      ),
    );
    streamSubscription = _searchRepository
        .search(params: state.params)
        .asyncMap((Item item) => toBuildable(item, withHighlightedText: query))
        .whereNotNull()
        .listen(_onItemFetched)
      ..onDone(() {
        emit(state.copyWith(status: SearchStatus.loaded));
      });
  }

  void loadMore() {
    if (state.status != SearchStatus.loading) {
      final int updatedPage = state.params.page + 1;
      emit(
        state.copyWith(
          status: SearchStatus.loadingMore,
          params: state.params.copyWith(page: updatedPage),
        ),
      );
      streamSubscription = _searchRepository
          .search(params: state.params)
          .asyncMap(
            (Item item) => toBuildable(
              item,
              withHighlightedText: state.params.query,
            ),
          )
          .whereNotNull()
          .listen(_onItemFetched)
        ..onDone(() {
          emit(state.copyWith(status: SearchStatus.loaded));
        });
    }
  }

  void addFilter<T extends SearchFilter>(T filter) {
    HapticFeedbackUtil.selection();
    if (state.params.contains<T>()) {
      emit(
        state.copyWith(
          params: state.params.copyWithFilterRemoved<T>(),
        ),
      );
    }

    emit(
      state.copyWith(
        params: state.params.copyWithFilterAdded(filter),
      ),
    );

    search(state.params.query);
  }

  void removeFilter<T extends SearchFilter>() {
    HapticFeedbackUtil.selection();
    if (state.params.contains<T>() == false) return;

    emit(
      state.copyWith(
        params: state.params.copyWithFilterRemoved<T>(),
      ),
    );

    search(state.params.query);
  }

  void onToggled(TypeTagFilter filter) {
    HapticFeedbackUtil.selection();
    if (state.params.contains<TypeTagFilter>() &&
        state.params.get<TypeTagFilter>() == filter) {
      removeFilter<TypeTagFilter>();
    } else {
      removeFilter<TypeTagFilter>();
      addFilter<TypeTagFilter>(filter);
    }
  }

  void onSortToggled() {
    HapticFeedbackUtil.selection();
    emit(
      state.copyWith(
        params: state.params.copyWith(
          sorted: !state.params.sorted,
        ),
      ),
    );

    search(state.params.query);
  }

  void onExactMatchToggled() {
    HapticFeedbackUtil.selection();
    emit(
      state.copyWith(
        params: state.params.copyWith(
          exactMatch: !state.params.exactMatch,
        ),
      ),
    );

    search(state.params.query);
  }

  void onDateTimeRangeUpdated(DateTime start, DateTime end) {
    HapticFeedbackUtil.selection();
    final DateTime updatedStart = start.copyWith(
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    final DateTime updatedEnd = end.copyWith(
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );
    final DateTime? existingStart =
        state.params.get<DateTimeRangeFilter>()?.startTime;
    final DateTime? existingEnd =
        state.params.get<DateTimeRangeFilter>()?.endTime;

    if (existingStart == updatedStart && existingEnd == updatedEnd) return;

    addFilter(
      DateTimeRangeFilter(
        startTime: updatedStart,
        endTime: updatedEnd,
      ),
    );
  }

  void onPostedByChanged(String? username) {
    HapticFeedbackUtil.selection();
    if (username == null) {
      removeFilter<PostedByFilter>();
    } else {
      addFilter(PostedByFilter(author: username));
    }
  }

  void onPointsFilterChanged(PointsFilter? pointsFilter) {
    HapticFeedbackUtil.selection();
    if (pointsFilter == null) {
      removeFilter<PointsFilter>();
    } else {
      addFilter(pointsFilter);
    }
  }

  void onNumberOfCommentsFilterChanged(CommentsNumberFilter? filter) {
    HapticFeedbackUtil.selection();
    if (filter == null) {
      removeFilter<CommentsNumberFilter>();
    } else {
      addFilter(filter);
    }
  }

  void _onItemFetched(Item item) {
    emit(
      state.copyWith(
        results: List<Item>.from(state.results)..add(item),
      ),
    );
  }

  @override
  Future<void> close() async {
    await streamSubscription?.cancel();
    textEditingController.dispose();
    await super.close();
  }
}
