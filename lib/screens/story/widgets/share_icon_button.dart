import 'dart:async';

import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/utils/utils.dart';
import 'package:share_plus/share_plus.dart';

class ShareIconButton extends StatelessWidget {
  const ShareIconButton({
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
        onComplete: () async {
          unawaited(HapticFeedback.lightImpact());
          return true;
        },
        overflowMode: OverflowMode.extendBackground,
        targetColor: Theme.of(context).primaryColor,
        tapTarget: const Icon(
          Icons.stream,
          color: Colors.white,
        ),
        featureId: Constants.featureShareStory,
        title: const Text('Share'),
        description: const Text(
          'Want more than just reading and replying? '
          'You can tap here to share this story to '
          'another app.',
          style: TextStyle(fontSize: 16),
        ),
        child: const Icon(
          Icons.stream,
        ),
      ),
      onPressed: () =>
          Share.share('https://news.ycombinator.com/item?id=$storyId'),
    );
  }
}
