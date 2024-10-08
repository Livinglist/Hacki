import 'package:flutter/material.dart';
import 'package:hacki/styles/styles.dart';

class CenteredText extends StatelessWidget {
  const CenteredText({
    required this.text,
    super.key,
    this.color = Palette.grey,
  });

  const CenteredText.hidden({Key? key})
      : this(
          key: key,
          text: 'hidden',
        );

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

  const CenteredText.empty({Key? key})
      : this(
          key: key,
          text: 'empty',
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
