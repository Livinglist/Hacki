import 'dart:async';

import 'package:hacki/config/constants.dart';
import 'package:hacki/styles/styles.dart';
import 'package:material_ui/material_ui.dart';
import 'package:updatify_flutter/updatify_flutter.dart';

// Just a styles config to match overall app UI
UpdatifyPostDecoration updatifyPostDecoration(BuildContext context) {
  final ThemeData theme = Theme.of(context);
  final ColorScheme colors = theme.colorScheme;

  return UpdatifyPostDecoration(
    titleStyle: theme.textTheme.titleLarge,
    headerStyle: theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    ),
    bodyStyle: theme.textTheme.bodyMedium,
    codeStyle: const TextStyle(fontFamily: 'UbuntuMono'),
    chipColors: <PostType, Color>{
      for (final PostType type in PostType.values) type: colors.primary,
    },
    blockquoteDecoration: BoxDecoration(
      border: Border(
        left: BorderSide(color: colors.primary, width: Dimens.pt3),
      ),
    ),
    horizontalRuleColor: theme.dividerColor,
  );
}

void showWhatsNewIfNeeded(BuildContext context) {
  final ThemeData theme = Theme.of(context);

  unawaited(
    maybeShowUpdatifyPopup(
      context,
      projectId: Constants.updatifyProjectId,
      popupType: UpdatifyPopupType.bottomSheet,
      titleStyle: theme.textTheme.titleMedium,
      backgroundColor: theme.canvasColor,
      closeButtonColor: theme.colorScheme.onSurface,
      itemDecoration: updatifyPostDecoration(context),
    ),
  );
}
