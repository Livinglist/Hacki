import 'package:clock/clock.dart';
import 'package:material_ui/material_ui.dart' as date_utils;

abstract final class DateUtils {
  static final DateTime _hackiAnniversary = DateTime(
    2021,
    DateTime.december,
    24,
  );

  static final int yearsSinceFirstCommit = () {
    final DateTime now = clock.now();
    final int year = now.year;
    return year - _hackiAnniversary.year;
  }();

  static final bool isTodayAnniversary = () {
    return date_utils.DateUtils.isSameDay(clock.now(), _hackiAnniversary);
  }();

  static final bool isMidnight = () {
    final DateTime now = clock.now();
    final int hour = now.hour;
    return hour >= 0 && hour < 4;
  }();
}
