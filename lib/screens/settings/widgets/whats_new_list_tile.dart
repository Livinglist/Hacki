import 'package:hacki/config/constants.dart';
import 'package:hacki/config/updatify.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/haptic_feedback_utils.dart';
import 'package:material_ui/material_ui.dart';
import 'package:updatify_flutter/updatify_flutter.dart';

class WhatsNewListTile extends StatelessWidget {
  const WhatsNewListTile({super.key});

  static const Duration _checkInterval = Duration(hours: 1);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return UpdatifyTrigger(
      projectId: Constants.updatifyProjectId,
      popupType: UpdatifyPopupType.bottomSheet,
      checkInterval: _checkInterval,
      titleStyle: theme.textTheme.titleMedium,
      backgroundColor: theme.canvasColor,
      closeButtonColor: theme.colorScheme.onSurface,
      itemDecoration: updatifyPostDecoration(context),
      builder:
          (
            BuildContext context,
            bool hasNewUpdates,
            VoidCallback openUpdates,
          ) => ListTile(
            title: const Text("What's New"),
            subtitle: const Text('Latest changes in Hacki.'),
            trailing: hasNewUpdates
                ? Icon(
                    Icons.circle,
                    size: Dimens.pt10,
                    color: theme.colorScheme.primary,
                  )
                : null,
            onTap: () {
              HapticFeedbackUtils.light();
              openUpdates();
            },
          ),
    );
  }
}
