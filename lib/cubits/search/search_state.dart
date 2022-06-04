part of 'search_cubit.dart';

enum SearchStatus {
  initial,
  loading,
  loadingMore,
  loaded,
}

class SearchState extends Equatable {
  const SearchState({
    required this.status,
    required this.results,
    required this.searchFilters,
  });

  SearchState.init()
      : status = SearchStatus.initial,
        results = <Story>[],
        searchFilters = SearchFilters.init();

  final List<Story> results;
  final SearchStatus status;
  final SearchFilters searchFilters;

  SearchState copyWith({
    List<Story>? results,
    SearchStatus? status,
    SearchFilters? searchFilters,
  }) {
    return SearchState(
      results: results ?? this.results,
      status: status ?? this.status,
      searchFilters: searchFilters ?? this.searchFilters,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        results,
        searchFilters,
      ];
}
