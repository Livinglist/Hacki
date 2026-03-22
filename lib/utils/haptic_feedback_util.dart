import 'package:flutter/services.dart';

abstract class HapticFeedbackUtil {
  static bool enabled = true;

  static void success() {
    if (enabled) {
      HapticFeedback.successNotification();
    }
  }

  static void error() {
    if (enabled) {
      HapticFeedback.errorNotification();
    }
  }

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
