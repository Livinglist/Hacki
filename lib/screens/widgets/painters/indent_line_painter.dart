import 'dart:math';

import 'package:flutter/material.dart';

class IndentLinePainter extends CustomPainter {
  IndentLinePainter({
    required this.color,
    required this.lineWidth,
    required this.shimmerPos,
    required this.glowOpacity,
    required this.isShining,
    required this.brightness,
  });

  final Color color;
  final double lineWidth;
  final double shimmerPos;
  final double glowOpacity;
  final bool isShining;
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;

    final Paint basePaint = Paint()
      ..color = color.withValues(
        alpha: brightness == Brightness.light ? 0.6 : 0.4,
      )
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), basePaint);

    if (!isShining || glowOpacity == 0) return;

    final Paint glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25 * glowOpacity)
      ..strokeWidth = lineWidth + 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawLine(Offset(cx, 0), Offset(cx, size.height), glowPaint);

    final double streakHeight = size.height * 0.22;
    final double cy = size.height * shimmerPos.clamp(0.0, 1.0);
    final double top = max(0, cy - streakHeight / 2);
    final double bottom = min(size.height, cy + streakHeight / 2);
    final Color streakColor =
        brightness == Brightness.dark ? color : Colors.black26;
    final double streakAlpha =
        brightness == Brightness.dark ? 0.95 * glowOpacity : 0.2;

    final Paint streakPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          streakColor.withValues(alpha: 0),
          streakColor.withValues(alpha: streakAlpha),
          streakColor.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, top, size.width, bottom - top))
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(cx, top), Offset(cx, bottom), streakPaint);

    final Color dotColor =
        brightness == Brightness.dark ? Colors.white : Colors.black26;
    final Paint dotPaint = Paint()
      ..color = Color.lerp(color, dotColor, 0.6)!.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawCircle(Offset(cx, cy), lineWidth * 1.8, dotPaint);
  }

  @override
  bool shouldRepaint(IndentLinePainter old) =>
      old.shimmerPos != shimmerPos ||
      old.glowOpacity != glowOpacity ||
      old.isShining != isShining ||
      old.color != color;
}
