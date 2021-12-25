import 'package:flutter/material.dart';
import 'package:hacki/models/models.dart';

class StoryTile extends StatelessWidget {
  const StoryTile({
    Key? key,
    required this.story,
    required this.onTap,
  }) : super(key: key);

  final Story story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
        child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 8,
            ),
            Text(
              story.title,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(
              height: 8,
            ),
          ],
        ),
      ),
    ));
  }
}
