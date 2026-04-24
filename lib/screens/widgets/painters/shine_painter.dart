import 'package:flutter/material.dart';
import 'package:hacki/screens/widgets/shine_overlay.dart';
import 'package:hacki/styles/palette.dart';

/// Used with [ShineOverlay] to highlight a widget on the screen.
class ShinePainter extends CustomPainter {
  ShinePainter(this.progress, {this.color});

  final double progress;
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    /// Sweep a bright streak across the widget
    final double sweepX = size.width * progress;
    final Color highlightColor = color == null
        ? Palette.white
        : Color.alphaBlend(
            color!.withValues(alpha: 0.3),
            Palette.white.withValues(alpha: 0.4),
          );
    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          highlightColor.withValues(alpha: 0),
          highlightColor.withValues(alpha: 0.6),
          highlightColor.withValues(alpha: 0),
        ],
        stops: const <double>[0, 0.5, 1],
      ).createShader(Rect.fromLTWH(sweepX - 60, 0, 120, size.height));

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(ShinePainter old) => old.progress != progress;
}
