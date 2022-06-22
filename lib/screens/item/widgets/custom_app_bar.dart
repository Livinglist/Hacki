import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/widgets/widgets.dart';

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
          elevation: 0,
          actions: <Widget>[
            if (splitViewEnabled) ...<Widget>[
              IconButton(
                icon: Icon(
                  expanded ?? false
                      ? FeatherIcons.minimize2
                      : FeatherIcons.maximize2,
                  size: 20,
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
