part of 'search_cubit.dart';

enum SearchStatus {
  initial,
  loading,
  loadingMore,
  loaded,
}

class SearchState extends Equatable {
  const SearchState({
    required this.query,
    required this.status,
    required this.results,
    required this.currentPage,
  });

  SearchState.init()
      : query = '',
        status = SearchStatus.initial,
        results = <Story>[],
        currentPage = 0;

  final String query;
  final List<Story> results;
  final SearchStatus status;
  final int currentPage;

  SearchState copyWith({
    String? query,
    List<Story>? results,
    SearchStatus? status,
    int? currentPage,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      status: status ?? this.status,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        query,
        status,
        results,
        currentPage,
      ];
}
