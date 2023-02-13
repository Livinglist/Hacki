import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';

class CustomAppBar extends AppBar {
  CustomAppBar({
    super.key,
    required ScrollController scrollController,
    required Item item,
    required Color super.backgroundColor,
    required Future<bool> Function() onDismiss,
    required VoidCallback onFontSizeTap,
    required GlobalKey fontSizeIconButtonKey,
    bool splitViewEnabled = false,
    VoidCallback? onZoomTap,
    bool? expanded,
  }) : super(
          elevation: Dimens.zero,
          actions: <Widget>[
            if (splitViewEnabled) ...<Widget>[
              IconButton(
                icon: Icon(
                  expanded ?? false
                      ? FeatherIcons.minimize2
                      : FeatherIcons.maximize2,
                  size: TextDimens.pt20,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onZoomTap?.call();
                },
              ),
              const Spacer(),
            ],
            ScrollUpIconButton(
              scrollController: scrollController,
            ),
            IconButton(
              key: fontSizeIconButtonKey,
              icon: const Icon(
                Icons.format_size,
              ),
              onPressed: onFontSizeTap,
            ),
            if (item is Story)
              PinIconButton(
                story: item,
                onDismiss: onDismiss,
              ),
            FavIconButton(
              storyId: item.id,
              onDismiss: onDismiss,
            ),
            LinkIconButton(
              storyId: item.id,
              onDismiss: onDismiss,
            ),
          ],
        );
}
