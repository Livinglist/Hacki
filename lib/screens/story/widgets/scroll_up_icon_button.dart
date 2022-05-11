import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

class ScrollUpIconButton extends StatefulWidget {
  const ScrollUpIconButton({
    super.key,
    required this.scrollController,
  });

  final ScrollController scrollController;

  @override
  _ScrollUpIconButtonState createState() => _ScrollUpIconButtonState();
}

class _ScrollUpIconButtonState extends State<ScrollUpIconButton> {
  @override
  void initState() {
    super.initState();

    widget.scrollController.addListener(() {
      if (widget.scrollController.offset <= 1000) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scrollController.hasClients) {
      final double curPos = widget.scrollController.offset;
      final double opacity = curPos / 1000;
      return Opacity(
        opacity: opacity.clamp(0, 1),
        child: IconButton(
          icon: const Icon(
            FeatherIcons.chevronsUp,
            color: Colors.orange,
            size: 26,
          ),
          onPressed: () {
            final double curPos = widget.scrollController.offset;
            widget.scrollController.animateTo(
              0,
              curve: Curves.bounceOut,
              duration: Duration(
                milliseconds: curPos ~/ 15,
              ),
            );
          },
        ),
      );
    }

    return Container();
  }
}
