import 'package:flutter/material.dart';
import 'package:hacki/screens/widgets/tap_down_wrapper.dart';

class DraggableFloatingButton extends StatefulWidget {
  const DraggableFloatingButton({
    required this.child,
    required this.onTap,
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  State<DraggableFloatingButton> createState() =>
      _DraggableFloatingButtonState();
}

class _DraggableFloatingButtonState extends State<DraggableFloatingButton> {
  Offset _offset = const Offset(20, 100);
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Positioned(
      right: _offset.dx,
      bottom: _offset.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _isDragging = true),
        onPanUpdate: (DragUpdateDetails details) {
          setState(() {
            _offset = Offset(
              (_offset.dx - details.delta.dx).clamp(0, size.width - 60),
              (_offset.dy - details.delta.dy).clamp(0, size.height - 60),
            );
          });
        },
        onPanEnd: (_) => setState(() => _isDragging = false),
        child: TapDownWrapper(
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isDragging ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: FloatingActionButton(
              backgroundColor: Theme.of(context).colorScheme.primary,
              onPressed: null, // handled by GestureDetector
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
