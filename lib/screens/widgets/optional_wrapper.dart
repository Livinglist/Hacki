import 'package:flutter/material.dart';

class OptionalWrapper extends StatelessWidget {
  const OptionalWrapper({
    required this.enabled,
    required this.wrapper,
    required this.child,
    super.key,
  });

  final bool enabled;
  final Widget Function(Widget) wrapper;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (enabled) {
      return wrapper(child);
    } else {
      return child;
    }
  }
}
