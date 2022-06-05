import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/story/widgets/fav_icon_button.dart';
import 'package:hacki/screens/story/widgets/link_icon_button.dart';
import 'package:hacki/screens/story/widgets/pin_icon_button.dart';
import 'package:hacki/screens/story/widgets/scroll_up_icon_button.dart';

class CustomAppBar extends AppBar {
  CustomAppBar({
    Key? key,
    required ScrollController scrollController,
    required Story story,
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
            PinIconButton(
              story: story,
              onBackgroundTap: onBackgroundTap,
              onDismiss: onDismiss,
            ),
            FavIconButton(
              storyId: story.id,
              onBackgroundTap: onBackgroundTap,
              onDismiss: onDismiss,
            ),
            LinkIconButton(
              storyId: story.id,
              onBackgroundTap: onBackgroundTap,
              onDismiss: onDismiss,
            ),
          ],
        );
}
