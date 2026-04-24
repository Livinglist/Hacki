import 'package:equatable/equatable.dart';
import 'package:hacki/models/search/filters/numeric_condition.dart';
import 'package:hacki/models/search/filters/numeric_filter.dart';

final class PointsFilter extends Equatable implements NumericFilter {
  const PointsFilter({required this.points, required this.condition});

  final int points;
  final NumericCondition condition;

  @override
  String get query {
    return 'points${condition.operator}$points';
  }

  @override
  List<Object?> get props => <Object?>[points, condition];
}
