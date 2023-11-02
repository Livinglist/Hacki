import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

class CustomAppBar extends AppBar {
  CustomAppBar({
    required Item item,
    required super.backgroundColor,
    required super.foregroundColor,
    required VoidCallback onFontSizeTap,
    required GlobalKey fontSizeIconButtonKey,
    super.key,
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
                  HapticFeedbackUtil.light();
                  onZoomTap?.call();
                },
              ),
              const Spacer(),
            ],
            const InThreadSearchIconButton(),
            IconButton(
              key: fontSizeIconButtonKey,
              icon: Text(
                String.fromCharCode(FeatherIcons.type.codePoint),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: TextDimens.pt18,
                  fontFamily: FeatherIcons.type.fontFamily,
                  package: FeatherIcons.type.fontPackage,
                ),
                textScaleFactor: 1,
              ),
              onPressed: onFontSizeTap,
            ),
            if (item is Story)
              PinIconButton(
                story: item,
              ),
            FavIconButton(
              storyId: item.id,
            ),
            LinkIconButton(
              storyId: item.id,
            ),
          ],
        );
}
