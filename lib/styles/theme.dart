import 'package:flutter/material.dart';

extension ThemeDataExtension on ThemeData {
  Color get readGrey => colorScheme.onSurface.withValues(alpha: 0.6);

  Color get metadataColor => colorScheme.onSurface.withValues(alpha: 0.8);
}
