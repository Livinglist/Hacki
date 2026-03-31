import 'package:hacki/models/search/filters/numeric_condition.dart';
import 'package:hacki/models/search/filters/numeric_filter.dart';

final class CommentsNumberFilter implements NumericFilter {
  const CommentsNumberFilter({
    required this.commentsNumber,
    required this.condition,
  });

  final int commentsNumber;
  final NumericCondition condition;

  @override
  String get query {
    return 'num_comments${condition.operator}$commentsNumber';
  }
}
