import 'package:hacki/models/search/filters/numeric_filter.dart';

final class DateTimeRangeFilter implements NumericFilter {
  const DateTimeRangeFilter({
    this.startTime,
    this.endTime,
  });

  final DateTime? startTime;
  final DateTime? endTime;

  @override
  String get query {
    if (startTime == null || endTime == null) return '';

    final int? startTimestamp = startTime == null
        ? null
        : startTime!.toUtc().millisecondsSinceEpoch ~/ 1000;
    int? endTimestamp = endTime == null
        ? null
        : endTime!.toUtc().millisecondsSinceEpoch ~/ 1000;

    if (startTimestamp == endTimestamp) {
      endTimestamp = startTime!
              .add(const Duration(hours: 24))
              .toUtc()
              .millisecondsSinceEpoch ~/
          1000;
    }

    if (startTimestamp == null || endTimestamp == null) return '';

    final String query =
        '''created_at_i>=$startTimestamp, created_at_i<=$endTimestamp''';

    if (query.endsWith(',')) {
      return query.replaceFirst(',', '');
    }

    return query;
  }
}
