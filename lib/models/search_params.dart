import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';

part 'search_filter.dart';

class SearchParams extends Equatable {
  const SearchParams({
    required this.filters,
    required this.query,
    required this.page,
    this.sorted = false,
  });

  SearchParams.init()
      : filters = <SearchFilter>{},
        query = '',
        page = 0,
        sorted = false;

  final Set<SearchFilter> filters;
  final String query;
  final int page;
  final bool sorted;

  SearchParams copyWith({
    Set<SearchFilter>? filters,
    String? query,
    int? page,
    bool? sorted,
  }) {
    return SearchParams(
      filters: filters ?? this.filters,
      query: query ?? this.query,
      page: page ?? this.page,
      sorted: sorted ?? this.sorted,
    );
  }

  SearchParams copyWithFilterRemoved<T extends SearchFilter>() {
    return SearchParams(
      filters: <SearchFilter>{...filters}
        ..removeWhere((SearchFilter e) => e is T),
      query: query,
      page: page,
      sorted: sorted,
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
    );
  }

  String get filteredQuery {
    final StringBuffer buffer = StringBuffer();

    if (sorted) {
      buffer.write('search_by_date?query=${Uri.encodeComponent(query)}');
    } else {
      buffer.write('search?query=${Uri.encodeComponent(query)}');
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
      ];
}
