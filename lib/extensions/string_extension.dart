extension StringExtension on String {
  int? getItemId() {
    final RegExp regex = RegExp(r'\d+$');
    final String match = regex.stringMatch(this) ?? '';
    return int.tryParse(match.replaceAll(')', ''));
  }

  String removeAllEmojis() {
    final RegExp regex = RegExp(
      r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])',
    );
    return replaceAllMapped(regex, (_) => '');
  }
}
