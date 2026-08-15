import 'package:material_ui/material_ui.dart';

extension MediaQueryDataExtension on MediaQueryData {
  TextScaler get clampedTextScaler => textScaler.clamp(maxScaleFactor: 1.2);
}
