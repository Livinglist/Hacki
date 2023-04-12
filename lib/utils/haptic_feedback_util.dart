import 'package:flutter/services.dart';

abstract class HapticFeedbackUtil {
  static void selection() => HapticFeedback.selectionClick();

  static void light() => HapticFeedback.lightImpact();
}
