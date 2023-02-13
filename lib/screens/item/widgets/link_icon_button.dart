import 'package:flutter/material.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

class LinkIconButton extends StatelessWidget {
  const LinkIconButton({
    super.key,
    required this.storyId,
  });

  final int storyId;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Open this story in browser',
      icon: const CustomDescribedFeatureOverlay(
        tapTarget: Icon(
          Icons.stream,
          color: Palette.white,
        ),
        featureId: Constants.featureOpenStoryInWebView,
        title: Text('Open in Browser'),
        description: Text(
          'Want more than just reading and replying? '
          'You can tap here to open this story in a '
          'browser.',
          style: TextStyle(fontSize: TextDimens.pt16),
        ),
        child: Icon(
          Icons.stream,
        ),
      ),
      onPressed: () =>
          LinkUtil.launch('https://news.ycombinator.com/item?id=$storyId'),
    );
  }
}
