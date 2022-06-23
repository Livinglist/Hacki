import 'package:flutter/material.dart';
import 'package:hacki/styles/styles.dart';

class CenteredMessageView extends StatelessWidget {
  const CenteredMessageView({
    super.key,
    required this.content,
  });

  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: Dimens.pt120,
        left: Dimens.pt40,
        right: Dimens.pt40,
      ),
      child: Text(
        content,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Palette.grey),
      ),
    );
  }
}
