import 'package:flutter/material.dart';
import 'package:hacki/models/search_params.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:intl/intl.dart';

class DateTimeRangeFilterChip extends StatelessWidget {
  const DateTimeRangeFilterChip({
    required this.filter,
    required this.onDateTimeRangeUpdated,
    required this.onDateTimeRangeRemoved,
    super.key,
  });

  final DateTimeRangeFilter? filter;
  final void Function(DateTime, DateTime) onDateTimeRangeUpdated;
  final VoidCallback onDateTimeRangeRemoved;

  static final DateFormat _dateTimeFormatter = DateFormat.yMMMd();

  @override
  Widget build(BuildContext context) {
    return CustomChip(
      onSelected: (bool value) {
        showDateRangePicker(
          context: context,
          firstDate: DateTime.now().subtract(const Duration(days: 20 * 365)),
          lastDate: DateTime.now(),
        ).then((DateTimeRange? range) {
          if (range != null) {
            onDateTimeRangeUpdated(range.start, range.end);
          } else {
            onDateTimeRangeRemoved();
          }
        });
      },
      selected: filter != null,
      label: _label,
    );
  }

  String get _label {
    final DateTime? start = filter?.startTime;
    final DateTime? end = filter?.endTime;
    if (start == null && end == null) {
      return '''from X to Y''';
    } else if (start == end) {
      return '''from ${_formatDateTime(start)}''';
    } else {
      return '''from ${_formatDateTime(start)} to ${_formatDateTime(end)}''';
    }
  }

  static String? _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return null;

    return _dateTimeFormatter.format(dateTime);
  }
}
