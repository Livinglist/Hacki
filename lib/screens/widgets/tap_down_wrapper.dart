import 'package:flutter/material.dart';
import 'package:hacki/config/constants.dart';

class TapDownWrapper extends StatefulWidget {
  const TapDownWrapper({
    required this.child,
    super.key,
    this.onTap,
    this.onLongPress,
  });

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;

  @override
  _TapDownWrapperState createState() => _TapDownWrapperState();
}

class _TapDownWrapperState extends State<TapDownWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  Tween<double> tween = Tween<double>(begin: 1, end: 0.95);

  @override
  void initState() {
    controller = AnimationController(
      duration: AppDurations.ms100,
      vsync: this,
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: onTapCancel,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation:
            CurvedAnimation(parent: controller, curve: Curves.decelerate),
        builder: (BuildContext context, Widget? child) {
          return Transform.scale(
            scale: tween.evaluate(controller),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void onTapDown(TapDownDetails details) {
    controller.forward();
  }

  void onTapUp(TapUpDetails details) {
    controller.reverse();
  }

  void onTapCancel() {
    controller.reverse();
  }

  void onTap() {
    widget.onTap?.call();
  }
}
