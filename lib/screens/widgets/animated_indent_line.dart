import 'package:flutter/material.dart';
import 'package:hacki/screens/widgets/painters/indent_line_painter.dart';

class AnimatedIndentLine extends StatefulWidget {
  const AnimatedIndentLine({
    required this.color,
    required this.width,
    required this.isShining,
    super.key,
  });

  final Color color;
  final double width;
  final bool isShining;

  @override
  State<AnimatedIndentLine> createState() => _AnimatedIndentLineState();
}

class _AnimatedIndentLineState extends State<AnimatedIndentLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmerPos;
  late Animation<double> _glowOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _shimmerPos = Tween<double>(begin: -0.2, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowOpacity = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0, end: 1),
        weight: 30,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 1),
        weight: 40,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 1, end: 0),
        weight: 30,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(AnimatedIndentLine old) {
    super.didUpdateWidget(old);
    if (widget.isShining && !old.isShining) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return CustomPaint(
          painter: IndentLinePainter(
            color: widget.color,
            lineWidth: widget.width,
            shimmerPos: _shimmerPos.value,
            glowOpacity: _glowOpacity.value,
            isShining: widget.isShining || _controller.isAnimating,
            brightness: Theme.of(context).brightness,
          ),
        );
      },
    );
  }
}
