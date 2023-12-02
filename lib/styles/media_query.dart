import 'package:flutter/material.dart';

extension MediaQueryDataExtension on MediaQueryData {
  TextScaler get clampedTextScaler => textScaler.clamp(maxScaleFactor: 1.2);
}
