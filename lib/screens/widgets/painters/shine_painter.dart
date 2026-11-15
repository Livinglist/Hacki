import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:hacki/screens/widgets/shine_overlay.dart';
import 'package:hacki/styles/palette.dart';
import 'package:material_ui/material_ui.dart';

/// Used with [ShineOverlay] to highlight a widget on the screen.
class ShinePainter extends CustomPainter {
  ShinePainter(
    this.progress, {
    required this.targetKey,
    required this.overlayKey,
    this.color,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final GlobalKey targetKey;
  final GlobalKey overlayKey;
  final Color? color;

  @override
  void paint(Canvas canvas, Size size) {
    // A removed target can still have an inactive element until this frame
    // ends. Read its render object so the attachment check can skip it.
    final RenderObject? target =
        (targetKey.currentContext as Element?)?.renderObject;
    final RenderObject? overlay = overlayKey.currentContext?.findRenderObject();
    if (target is! RenderBox ||
        !target.attached ||
        !target.hasSize ||
        target.size.isEmpty ||
        overlay is! RenderBox ||
        !overlay.attached ||
        !overlay.hasSize) {
      return;
    }

    // Scroll layout runs after build. Resolve the target here so the shine
    // follows the comment's position and size in the frame being painted.
    final Rect rect = MatrixUtils.transformRect(
      target.getTransformTo(overlay),
      Offset.zero & target.size,
    );
    Rect clip = Offset.zero & size;
    final RenderAbstractViewport? viewport = RenderAbstractViewport.maybeOf(
      target,
    );
    if (viewport != null) {
      clip = clip.intersect(
        MatrixUtils.transformRect(
          viewport.getTransformTo(overlay),
          viewport.paintBounds,
        ),
      );
    }
    if (!rect.isFinite || rect.intersect(clip).isEmpty) return;

    /// Sweep a bright streak across the widget
    final double sweepX = rect.width * progress.value;
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
      ).createShader(Rect.fromLTWH(sweepX - 60, 0, 120, rect.height));

    canvas
      ..save()
      ..clipRect(clip)
      ..translate(rect.left, rect.top)
      ..drawRect(Offset.zero & rect.size, paint)
      ..restore();
  }

  @override
  bool shouldRepaint(ShinePainter old) =>
      old.progress != progress ||
      old.targetKey != targetKey ||
      old.overlayKey != overlayKey ||
      old.color != color;
}
