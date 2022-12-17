mixin SettingsDisplayable {
  String get title;

  String get subtitle => '';

  /// Whether or not this should be displayed
  /// in settings.
  bool get isDisplayable => true;
}
