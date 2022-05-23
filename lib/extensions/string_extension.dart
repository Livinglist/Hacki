extension StringExtension on String {
  int? getItemId() {
    final RegExp regex = RegExp(r'\d+$');
    final String match = regex.stringMatch(this) ?? '';
    return int.tryParse(match);
  }
}
