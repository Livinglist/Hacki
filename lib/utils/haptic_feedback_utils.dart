import 'dart:io';

import 'package:advanced_haptics/advanced_haptics.dart';
import 'package:flutter/services.dart';

abstract final class HapticFeedbackUtils {
  static bool enabled = true;
  static bool? hasCustomHapticsSupport;

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

  static Future<void> loadAndPlay() async {
    hasCustomHapticsSupport ??= await AdvancedHaptics.hasCustomHapticsSupport();
    if (hasCustomHapticsSupport ?? false) {
      await stop();
      if (Platform.isIOS) {
        await AdvancedHaptics.playAhap('assets/haptics/heartbeats.ahap');
      } else {
        final List<int> timings = <int>[0, 60, 50, 100, 50];
        final List<int> amplitudes = <int>[0, 255, 0, 150, 0];
        await AdvancedHaptics.playWaveform(timings, amplitudes);
      }
    }
  }

  static Future<void> stop() async {
    try {
      await AdvancedHaptics.stop();
    } catch (_) {}
  }
}
