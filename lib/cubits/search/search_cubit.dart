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

  void search(String query) {
    emit(
      state.copyWith(
        results: <Story>[],
        currentPage: 0,
        status: SearchStatus.loading,
        query: query,
      ),
    );
    _searchRepository.search(query).listen(_onStoryFetched).onDone(() {
      emit(state.copyWith(status: SearchStatus.loaded));
    });
  }

  void loadMore() {
    final int updatedPage = state.currentPage + 1;
    emit(
      state.copyWith(
        status: SearchStatus.loadingMore,
        currentPage: updatedPage,
      ),
    );
    _searchRepository
        .search(state.query, page: updatedPage)
        .listen(_onStoryFetched)
        .onDone(() {
      emit(state.copyWith(status: SearchStatus.loaded));
    });
  }

  void _onStoryFetched(Story story) {
    emit(
      state.copyWith(
        results: List<Story>.from(state.results)..add(story),
        status: SearchStatus.loaded,
      ),
    );
  }
}
