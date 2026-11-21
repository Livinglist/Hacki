import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/config/paths.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/discoverable_feature.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/services/services.dart';
import 'package:material_ui/material_ui.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Go to settings',
      icon: CustomDescribedFeatureOverlay(
        tapTarget: Icon(
          Icons.stream,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        feature: DiscoverableFeature.settingsShortcutOnItemScreen,
        contentLocation: ContentLocation.below,
        child: Icon(
          Icons.stream,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onPressed: () {
        if (context.read<SplitViewCubit>().state.enabled) {
          DialogProxy.showSettingsBottomSheet(context);
        } else {
          context.push(Paths.item.settings);
        }
      },
    );
  }
}
