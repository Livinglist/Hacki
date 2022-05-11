import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/utils/utils.dart';

class LinkIconButton extends StatelessWidget {
  const LinkIconButton({
    super.key,
    required this.storyId,
    required this.onBackgroundTap,
    required this.onDismiss,
  });

  final int storyId;
  final Future<bool> Function() onBackgroundTap;
  final Future<bool> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: DescribedFeatureOverlay(
        onBackgroundTap: onBackgroundTap,
        onDismiss: onDismiss,
        overflowMode: OverflowMode.extendBackground,
        targetColor: Theme.of(context).primaryColor,
        tapTarget: const Icon(
          Icons.stream,
          color: Colors.white,
        ),
        featureId: Constants.featureOpenStoryInWebView,
        title: const Text('Open in Browser'),
        description: const Text(
          'Want more than just reading and replying? '
          'You can tap here to open this story in a '
          'browser.',
          style: TextStyle(fontSize: 16),
        ),
        child: const Icon(
          Icons.stream,
        ),
      ),
      onPressed: () =>
          LinkUtil.launchUrl('https://news.ycombinator.com/item?id=$storyId'),
    );
  }
}
