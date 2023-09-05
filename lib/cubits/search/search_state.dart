part of 'search_cubit.dart';

enum SearchStatus {
  idle,
  loading,
  loadingMore,
  loaded,
}

class SearchState extends Equatable {
  const SearchState({
    required this.status,
    required this.results,
    required this.params,
  });

  SearchState.init()
      : status = SearchStatus.idle,
        results = <Item>[],
        params = SearchParams.init();

  final List<Item> results;
  final SearchStatus status;
  final SearchParams params;

  bool get hasDateFilter =>
      params.filters.whereType<DateTimeRangeFilter>().isNotEmpty;

  DateTimeRangeFilter? get dateFilter =>
      params.filters.whereType<DateTimeRangeFilter>().singleOrNull;

  SearchState copyWith({
    List<Item>? results,
    SearchStatus? status,
    SearchParams? params,
  }) {
    return SearchState(
      results: results ?? this.results,
      status: status ?? this.status,
      params: params ?? this.params,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        results,
        params,
      ];
}

extension SearchStateExtension on SearchState {
  bool get showDateRangeShortcutChips {
    return hasDateFilter &&
        dateFilter?.startTime != null &&
        dateFilter?.endTime != null;
  }
}
