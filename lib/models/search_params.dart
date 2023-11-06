import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

part 'search_filter.dart';

class SearchParams extends Equatable {
  const SearchParams({
    required this.filters,
    required this.query,
    required this.page,
    required this.sorted,
    required this.exactMatch,
  });

  SearchParams.init()
      : filters = <SearchFilter>{},
        query = '',
        page = 0,
        sorted = false,
        exactMatch = false;

  final Set<SearchFilter> filters;
  final String query;
  final int page;
  final bool sorted;
  final bool exactMatch;

  SearchParams copyWith({
    Set<SearchFilter>? filters,
    String? query,
    int? page,
    bool? sorted,
    bool? exactMatch,
  }) {
    return SearchParams(
      filters: filters ?? this.filters,
      query: query ?? this.query,
      page: page ?? this.page,
      sorted: sorted ?? this.sorted,
      exactMatch: exactMatch ?? this.exactMatch,
    );
  }

  SearchParams copyWithFilterRemoved<T extends SearchFilter>() {
    return SearchParams(
      filters: <SearchFilter>{...filters}
        ..removeWhere((SearchFilter e) => e is T),
      query: query,
      page: page,
      sorted: sorted,
      exactMatch: exactMatch,
    );
  }

  SearchParams copyWithFilterAdded(
    SearchFilter filter,
  ) {
    return SearchParams(
      filters: <SearchFilter>{...filters, filter},
      query: query,
      page: page,
      sorted: sorted,
      exactMatch: exactMatch,
    );
  }

  String get filteredQuery {
    final StringBuffer buffer = StringBuffer();
    final String encodedQuery =
        Uri.encodeComponent(exactMatch ? '"$query"' : query);

    if (sorted) {
      buffer.write('search_by_date?query=$encodedQuery');
    } else {
      buffer.write('search?query=$encodedQuery');
    }

    final Iterable<NumericFilter> numericFilters =
        filters.whereType<NumericFilter>();
    final List<TagFilter> tagFilters = <TagFilter>[
      ...filters.whereType<TagFilter>(),
    ];

    if (numericFilters.isNotEmpty) {
      buffer
        ..write('&numericFilters=')
        ..writeAll(
          numericFilters.map<String>((NumericFilter e) => e.query),
          ',',
        );
    }

    if (tagFilters.isNotEmpty) {
      buffer
        ..write('&tags=')
        ..writeAll(
          tagFilters.map<String>((TagFilter e) => e.query),
          ',',
        );
    }

    buffer.write('&page=$page');

    return buffer.toString();
  }

  bool contains<T extends SearchFilter>() {
    return filters.whereType<T>().isNotEmpty;
  }

  T? get<T extends SearchFilter>() {
    return filters.singleWhereOrNull(
      (SearchFilter e) => e is T,
    ) as T?;
  }

  @override
  List<Object?> get props => <Object?>[
        filters,
        query,
        page,
        sorted,
        exactMatch,
      ];
}
