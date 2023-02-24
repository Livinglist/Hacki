import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit({SearchRepository? searchRepository})
      : _searchRepository = searchRepository ?? locator.get<SearchRepository>(),
        super(SearchState.init());

  final SearchRepository _searchRepository;

  StreamSubscription<Story>? streamSubscription;

  void search(String query) {
    streamSubscription?.cancel();
    emit(
      state.copyWith(
        results: <Story>[],
        status: SearchStatus.loading,
        params: state.params.copyWith(query: query, page: 0),
      ),
    );
    streamSubscription =
        _searchRepository.search(params: state.params).listen(_onStoryFetched)
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
      streamSubscription =
          _searchRepository.search(params: state.params).listen(_onStoryFetched)
            ..onDone(() {
              emit(state.copyWith(status: SearchStatus.loaded));
            });
    }
  }

  void addFilter<T extends SearchFilter>(T filter) {
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
    if (state.params.contains<T>() == false) return;

    emit(
      state.copyWith(
        params: state.params.copyWithFilterRemoved<T>(),
      ),
    );

    search(state.params.query);
  }

  void onSortToggled() {
    emit(
      state.copyWith(
        params: state.params.copyWith(
          sorted: !state.params.sorted,
        ),
      ),
    );

    search(state.params.query);
  }

  void onDateTimeRangeUpdated(DateTime start, DateTime end) {
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
    if (username == null) {
      removeFilter<PostedByFilter>();
    } else {
      addFilter(PostedByFilter(author: username));
    }
  }

  void _onStoryFetched(Story story) {
    emit(
      state.copyWith(
        results: List<Story>.from(state.results)..add(story),
      ),
    );
  }

  @override
  Future<void> close() async {
    await streamSubscription?.cancel();
    await super.close();
  }
}
