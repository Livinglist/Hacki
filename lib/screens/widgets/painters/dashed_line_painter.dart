import 'package:flutter/material.dart';

class DashedLinePainter extends CustomPainter {
  const DashedLinePainter({
    required this.color,
    this.dashWidth = 4,
    this.dashGap = 4,
    this.strokeWidth = 1,
  });

  final Color color;
  final double dashWidth;
  final double dashGap;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;

    double startX = 0;
    final double y = size.height / 2;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset((startX + dashWidth).clamp(0, size.width), y),
        paint,
      );
      startX += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(DashedLinePainter old) =>
      old.color != color ||
      old.dashWidth != dashWidth ||
      old.dashGap != dashGap ||
      old.strokeWidth != strokeWidth;
}
