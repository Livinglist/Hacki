import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/config/paths.dart';
import 'package:hacki/config/router.dart';
import 'package:hacki/models/discoverable_feature.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/services/services.dart';
import 'package:responsive_builder/responsive_builder.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({
    super.key,
  });

  static DeviceScreenType? _cachedDeviceType;

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
      onPressed: () {
        _cachedDeviceType ??= () {
          final BuildContext? context = navigatorKey.currentContext;
          if (context != null) {
            final Size size = MediaQuery.of(context).size;
            final DeviceScreenType type = getDeviceType(size);
            return type;
          }
          return DeviceScreenType.mobile;
        }();
        final DeviceScreenType deviceType = _cachedDeviceType!;

        if (deviceType == DeviceScreenType.mobile) {
          context.push(Paths.item.settings);
          return;
        } else {
          DialogProxy.showSettingsBottomSheet(context);
        }
      },
    );
  }
}
