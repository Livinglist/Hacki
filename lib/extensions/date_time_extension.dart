extension DateTimeExtension on DateTime {
  String toReadableString() {
    final now = DateTime.now();
    final diff = now.difference(this);
    if (diff.inDays > 365) {
      final gap = now.year - year;
      return '$gap year${gap == 1 ? '' : 's'} ago';
    } else if (diff.inDays > 30) {
      var gap = now.month - month;
      if (gap <= 0) {
        gap = now.month + (12 - month);
      }
      return '$gap month${gap == 1 ? '' : 's'} ago';
    } else if (diff.inDays >= 1) {
      if (diff.inHours <= 24) {
        return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
      }
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    } else if (diff.inSeconds >= 1) {
      return '${diff.inSeconds} second${diff.inSeconds == 1 ? '' : 's'} ago';
    }
    return 'just now';
  }
}
