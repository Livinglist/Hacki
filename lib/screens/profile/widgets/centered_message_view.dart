import 'package:flutter/material.dart';

class CenteredMessageView extends StatelessWidget {
  const CenteredMessageView({
    Key? key,
    required this.content,
  }) : super(key: key);

  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 120,
        left: 40,
        right: 40,
      ),
      child: Text(
        content,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
