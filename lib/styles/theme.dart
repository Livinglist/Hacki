import 'package:flutter/material.dart';

extension ThemeDataExtension on ThemeData {
  Color get readGrey => colorScheme.onSurface.withOpacity(0.4);
}
