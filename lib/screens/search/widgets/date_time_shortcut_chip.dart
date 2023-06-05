import 'package:flutter/material.dart';
import 'package:hacki/screens/search/widgets/date_time_range_filter_chip.dart';
import 'package:hacki/screens/widgets/widgets.dart' show CustomChip;

typedef Calculator = DateTime Function(DateTime);

/// A set of chips that perform addition or subtraction on the date selected
/// by [DateTimeRangeFilterChip]
class DateTimeShortcutChip extends StatelessWidget {
  const DateTimeShortcutChip({
    required this.onDateTimeRangeUpdated,
    required this.startDate,
    required this.endDate,
    required this.label,
    required Calculator calculator,
    super.key,
  }) : _calculator = calculator;

  DateTimeShortcutChip.dayBefore({
    required this.onDateTimeRangeUpdated,
    required this.startDate,
    required this.endDate,
    super.key,
  })  : label = '- day',
        _calculator =
            ((DateTime date) => date.subtract(const Duration(hours: 24)));

  DateTimeShortcutChip.dayAfter({
    required this.onDateTimeRangeUpdated,
    required this.startDate,
    required this.endDate,
    super.key,
  })  : label = '+ day',
        _calculator = ((DateTime date) => date.add(const Duration(hours: 24)));

  DateTimeShortcutChip.weekBefore({
    required this.onDateTimeRangeUpdated,
    required this.startDate,
    required this.endDate,
    super.key,
  })  : label = '- week',
        _calculator =
            ((DateTime date) => date.subtract(const Duration(days: 7)));

  DateTimeShortcutChip.weekAfter({
    required this.onDateTimeRangeUpdated,
    required this.startDate,
    required this.endDate,
    super.key,
  })  : label = '+ week',
        _calculator = ((DateTime date) => date.add(const Duration(days: 7)));

  DateTimeShortcutChip.monthBefore({
    required this.onDateTimeRangeUpdated,
    required this.startDate,
    required this.endDate,
    super.key,
  })  : label = '- 30 days',
        _calculator =
            ((DateTime date) => date.subtract(const Duration(days: 30)));

  DateTimeShortcutChip.monthAfter({
    required this.onDateTimeRangeUpdated,
    required this.startDate,
    required this.endDate,
    super.key,
  })  : label = '+ 30 days',
        _calculator = ((DateTime date) => date.add(const Duration(days: 30)));

  final void Function(DateTime, DateTime) onDateTimeRangeUpdated;
  final DateTime? startDate;
  final DateTime? endDate;
  final String label;
  final Calculator _calculator;

  @override
  Widget build(BuildContext context) {
    return CustomChip(
      onSelected: (bool value) {
        if (startDate == null || endDate == null) return;
        final DateTime updatedStartDate = _calculator(startDate!);
        final DateTime updatedEndDate = _calculator(endDate!);
        onDateTimeRangeUpdated(updatedStartDate, updatedEndDate);
      },
      selected: false,
      label: label,
    );
  }
}
