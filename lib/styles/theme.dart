import 'package:flutter/material.dart';

extension ThemeDataExtension on ThemeData {
  Color get readGrey => colorScheme.onSurface.withOpacity(0.4);

  Color get metadataColor => colorScheme.onSurface.withOpacity(0.6);
}
