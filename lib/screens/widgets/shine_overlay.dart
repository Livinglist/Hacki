import 'package:hacki/config/constants.dart';
import 'package:hacki/screens/widgets/painters/shine_painter.dart';
import 'package:material_ui/material_ui.dart';

class ShineOverlay extends StatefulWidget {
  const ShineOverlay({
    required this.targetKey,
    required this.onDone,
    super.key,
  });

  final GlobalKey targetKey;
  final VoidCallback onDone;

  @override
  State<ShineOverlay> createState() => _ShineOverlayState();
}

class _ShineOverlayState extends State<ShineOverlay>
    with SingleTickerProviderStateMixin {
  final GlobalKey _paintKey = GlobalKey();

  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: AppDurations.ms800,
  )..forward().whenComplete(widget.onDone);

  late final Animation<double> _anim =
      TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 0,
            end: 1,
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 1,
            end: 0,
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 1,
        ),
      ]).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CustomPaint(
            key: _paintKey,
            painter: ShinePainter(
              _anim,
              targetKey: widget.targetKey,
              overlayKey: _paintKey,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
