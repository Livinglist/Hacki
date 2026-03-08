extension DateTimeExtension on DateTime {
  String toTimeAgoString({bool shouldUseAbbreviations = false}) {
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(this);
    final String hourStr = shouldUseAbbreviations ? 'hr' : 'hour';
    final String dayStr = shouldUseAbbreviations ? 'day' : 'day';
    final String minuteStr = shouldUseAbbreviations ? 'min' : 'minute';
    final String secondStr = shouldUseAbbreviations ? 'sec' : 'second';
    if (diff.inDays > 365) {
      final int gap = now.year - year;
      return '$gap year${gap == 1 ? '' : 's'} ago';
    } else if (diff.inDays > 30) {
      int gap = now.month - month;
      if (gap <= 0) {
        gap = now.month + 12 - month;
      }
      return '$gap month${gap == 1 ? '' : 's'} ago';
    } else if (diff.inDays >= 1) {
      if (diff.inHours <= 24) {
        return '${diff.inHours} $hourStr${diff.inHours == 1 ? '' : 's'} ago';
      }
      return '${diff.inDays} $dayStr${diff.inDays == 1 ? '' : 's'} ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} $hourStr${diff.inHours == 1 ? '' : 's'} ago';
    } else if (diff.inMinutes >= 1) {
      return '''${diff.inMinutes} $minuteStr${diff.inMinutes == 1 ? '' : 's'} ago''';
    } else if (diff.inSeconds >= 1) {
      return '''${diff.inSeconds} $secondStr${diff.inSeconds == 1 ? '' : 's'} ago''';
    }
    return 'just now';
  }
}
