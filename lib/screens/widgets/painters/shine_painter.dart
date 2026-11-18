import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:hacki/screens/widgets/shine_overlay.dart';
import 'package:material_ui/material_ui.dart';

/// Used with [ShineOverlay] to highlight a widget on the screen.
class ShinePainter extends CustomPainter {
  ShinePainter(
    this.progress, {
    required this.targetKey,
    required this.overlayKey,
    required this.color,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final GlobalKey targetKey;
  final GlobalKey overlayKey;
  final Color color;

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

    // Scroll layout runs after build. Resolve the target here so the flash
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

    // Gently tint the entire tile, keeping its content readable at the peak.
    final Paint paint = Paint()
      ..color = color.withValues(alpha: 0.16 * progress.value);

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
