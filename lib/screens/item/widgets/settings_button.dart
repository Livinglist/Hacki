import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/config/paths.dart';
import 'package:hacki/models/discoverable_feature.dart';
import 'package:hacki/screens/widgets/widgets.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Go to settings',
      icon: CustomDescribedFeatureOverlay(
        tapTarget: Icon(
          Icons.settings,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        feature: DiscoverableFeature.settingsShortcutOnItemScreen,
        contentLocation: ContentLocation.below,
        child: Icon(
          Icons.settings,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onPressed: () => context.push(Paths.item.settings),
    );
  }
}
