part of 'filter_cubit.dart';

class FilterState extends Equatable {
  const FilterState({
    required this.keywords,
  });

  FilterState.init() : keywords = <String>{};

  final Set<String> keywords;

  FilterState copyWith({Set<String>? keywords}) {
    return FilterState(
      keywords: keywords ?? this.keywords,
    );
  }

  @override
  List<Object?> get props => <Object?>[keywords];
}
