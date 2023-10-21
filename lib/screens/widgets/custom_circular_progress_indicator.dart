import 'package:flutter/material.dart';

/// Circular progress indicator with color.
/// Changing `colorScheme`'s `primary` color doesn't work because it changes
/// the color of multiple widgets like
/// CircularProgressIndicators and TextFields.
/// We only want the CircularProgressIndicators to be `Palette.purple`.
class CustomCircularProgressIndicator extends StatelessWidget {
  const CustomCircularProgressIndicator({
    super.key,
    this.strokeWidth = 4,
  });

  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      strokeWidth: strokeWidth,
      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
    );
  }
}
