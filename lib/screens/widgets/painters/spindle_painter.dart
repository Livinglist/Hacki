import 'package:flutter/material.dart';

class SpindlePainter extends CustomPainter {
  SpindlePainter({required this.color, super.repaint});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Paint strokePaint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final double w = size.width;
    final double h = size.height;

    final double center = w * 0.50;
    const double neckHalf = 0.5;

    final Path path = Path()
      ..moveTo(center - neckHalf, 0) // top-left neck
      // Left side going DOWN
      ..cubicTo(
        center - neckHalf, h * 0.20,
        w * 0.20, h * 0.30,
        w * 0.20, h * 0.50, // widest point left
      )
      ..cubicTo(
        w * 0.20, h * 0.70,
        center - neckHalf, h * 0.80,
        center - neckHalf, h * 1.0, // bottom-left neck
      )
      // Connect across bottom
      ..lineTo(center + neckHalf, h * 1.0)
      // Right side going UP
      ..cubicTo(
        center + neckHalf, h * 0.80,
        w * 0.80, h * 0.70,
        w * 0.80, h * 0.50, // widest point right
      )
      ..cubicTo(
        w * 0.80, h * 0.30,
        center + neckHalf, h * 0.20,
        center + neckHalf, 0, // top-right neck
      )
      ..close();

    canvas
      ..drawPath(path, fillPaint) // fill first
      ..drawPath(path, strokePaint); // outline on top
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
