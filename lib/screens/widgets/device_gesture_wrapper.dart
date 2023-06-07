import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A walk-around for [SelectableText] not responding to swipe gestures
/// while wrapped in a [Dismissible].
///
/// https://github.com/flutter/flutter/issues/124421#issuecomment-1500666795
class DeviceGestureWrapper extends StatelessWidget {
  const DeviceGestureWrapper({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: const MediaQueryData(
        gestureSettings: DeviceGestureSettings(touchSlop: 12),
      ),
      child: child,
    );
  }
}
