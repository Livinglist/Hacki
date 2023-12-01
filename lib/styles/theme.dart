import 'package:flutter/material.dart';

extension ThemeDataExtension on ThemeData {
  Color get responsivePrimaryColor =>
      brightness == Brightness.light ? primaryColor : colorScheme.onSurface;
}
