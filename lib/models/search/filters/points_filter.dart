import 'package:hacki/models/search/filters/numeric_condition.dart';
import 'package:hacki/models/search/filters/numeric_filter.dart';

final class PointsFilter implements NumericFilter {
  const PointsFilter({
    required this.points,
    required this.condition,
  });

  final int points;
  final NumericCondition condition;

  @override
  String get query {
    return 'points${condition.operator}$points';
  }
}
