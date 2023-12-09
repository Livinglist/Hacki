import 'package:flutter/services.dart';

abstract class HapticFeedbackUtil {
  static bool enabled = true;

  static void selection() {
    if (enabled) {
      HapticFeedback.selectionClick();
    }
  }

  static void light() {
    if (enabled) {
      HapticFeedback.lightImpact();
    }
  }

  static void heavy() {
    if (enabled) {
      HapticFeedback.heavyImpact();
    }
  }
}
