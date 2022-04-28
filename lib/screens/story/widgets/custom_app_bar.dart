import 'package:flutter/material.dart';
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
  }) : super(
          key: key,
          backgroundColor: backgroundColor,
          elevation: 0,
          actions: <Widget>[
            ScrollUpIconButton(
              scrollController: scrollController,
            ),
            PinIconButton(story: story),
            FavIconButton(storyId: story.id),
            LinkIconButton(storyId: story.id),
          ],
        );
}
