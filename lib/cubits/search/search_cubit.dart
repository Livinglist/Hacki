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
        searchFilters: state.searchFilters.copyWith(query: query, page: 0),
      ),
    );
    streamSubscription = _searchRepository
        .search(filters: state.searchFilters)
        .listen(_onStoryFetched)
      ..onDone(() {
        emit(state.copyWith(status: SearchStatus.loaded));
      });
  }

  void loadMore() {
    if (state.status != SearchStatus.loading) {
      final int updatedPage = state.searchFilters.page + 1;
      emit(
        state.copyWith(
          status: SearchStatus.loadingMore,
          searchFilters: state.searchFilters.copyWith(page: updatedPage),
        ),
      );
      streamSubscription = _searchRepository
          .search(filters: state.searchFilters)
          .listen(_onStoryFetched)
        ..onDone(() {
          emit(state.copyWith(status: SearchStatus.loaded));
        });
    }
  }

  void addFilter<T extends SearchFilter>(T filter) {
    if (state.searchFilters.contains<T>()) {
      emit(
        state.copyWith(
          searchFilters: state.searchFilters.copyWithFilterRemoved<T>(),
        ),
      );
    }

    emit(
      state.copyWith(
        searchFilters: state.searchFilters.copyWithFilterAdded(filter),
      ),
    );

    search(state.searchFilters.query);
  }

  void removeFilter<T extends SearchFilter>() {
    emit(
      state.copyWith(
        searchFilters: state.searchFilters.copyWithFilterRemoved<T>(),
      ),
    );

    search(state.searchFilters.query);
  }

  void onSortToggled() {
    emit(
      state.copyWith(
        searchFilters: state.searchFilters.copyWith(
          sorted: !state.searchFilters.sorted,
        ),
      ),
    );

    search(state.searchFilters.query);
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
