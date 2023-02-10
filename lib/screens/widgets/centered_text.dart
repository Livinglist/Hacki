import 'package:flutter/material.dart';
import 'package:hacki/styles/styles.dart';

class CenteredText extends StatelessWidget {
  const CenteredText({
    super.key,
    required this.text,
    this.color = Palette.grey,
  });

  const CenteredText.deleted({Key? key})
      : this(
          key: key,
          text: 'deleted',
        );

  const CenteredText.dead({Key? key})
      : this(
          key: key,
          text: 'dead',
        );

  const CenteredText.blocked({Key? key})
      : this(
          key: key,
          text: 'blocked',
        );

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: Dimens.pt12,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
          ),
        ),
      ),
    );
  }
}
