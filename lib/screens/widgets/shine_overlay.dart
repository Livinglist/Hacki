import 'package:flutter/material.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/screens/widgets/painters/shine_painter.dart';

class ShineOverlay extends StatefulWidget {
  const ShineOverlay({
    required this.rect,
    required this.onDone,
    super.key,
  });

  final Rect rect;
  final VoidCallback onDone;

  @override
  State<ShineOverlay> createState() => _ShineOverlayState();
}

class _ShineOverlayState extends State<ShineOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppDurations.ms800,
  )..forward().whenComplete(widget.onDone);

  late final Animation<double> _anim = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRect(
      rect: widget.rect,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => CustomPaint(
            painter: ShinePainter(
              _anim.value,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
