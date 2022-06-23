import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';

class CustomAppBar extends AppBar {
  CustomAppBar({
    Key? key,
    required ScrollController scrollController,
    required Item item,
    required Color backgroundColor,
    required Future<bool> Function() onBackgroundTap,
    required Future<bool> Function() onDismiss,
    bool splitViewEnabled = false,
    VoidCallback? onZoomTap,
    bool? expanded,
  }) : super(
          key: key,
          backgroundColor: backgroundColor,
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
            if (item is Story)
              PinIconButton(
                story: item,
                onBackgroundTap: onBackgroundTap,
                onDismiss: onDismiss,
              ),
            FavIconButton(
              storyId: item.id,
              onBackgroundTap: onBackgroundTap,
              onDismiss: onDismiss,
            ),
            LinkIconButton(
              storyId: item.id,
              onBackgroundTap: onBackgroundTap,
              onDismiss: onDismiss,
            ),
          ],
        );
}
