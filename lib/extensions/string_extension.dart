extension StringExtension on String {
  int? get itemId {
    final RegExp regex = RegExp(r'\d+$');
    final RegExp exception = RegExp(r'\)|].*$');
    final String match = regex.stringMatch(replaceAll(exception, '')) ?? '';
    return int.tryParse(match);
  }

  bool get isStoryLink => contains('news.ycombinator.com/item');

  String removeAllEmojis() {
    final RegExp regex = RegExp(
      r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
    );
    return replaceAllMapped(regex, (_) => '');
  }
}

extension OptionalStringExtension on String? {
  bool get isNullOrEmpty {
    if (this == null) return true;
    return this!.trim().isEmpty;
  }

  bool get isNotNullOrEmpty => !isNullOrEmpty;
}
