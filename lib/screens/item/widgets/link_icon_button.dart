import 'package:flutter/material.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/models/discoverable_feature.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

class LinkIconButton extends StatelessWidget {
  const LinkIconButton({
    required this.storyId,
    super.key,
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
        feature: DiscoverableFeature.openStoryInWebView,
        child: Icon(
          Icons.stream,
        ),
      ),
      onPressed: () => LinkUtil.launch(
        '${Constants.hackerNewsItemLinkPrefix}$storyId',
        context,
        useHackiForHnLink: false,
      ),
    );
  }
}
