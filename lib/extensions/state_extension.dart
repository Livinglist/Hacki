import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/auth/auth_bloc.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/main.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/item/models/models.dart';
import 'package:hacki/screens/item/widgets/widgets.dart';
import 'package:hacki/screens/screens.dart' show ItemScreen, ItemScreenArgs;
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:share_plus/share_plus.dart';

extension StateExtension on State {
  void showSnackBar({
    required String content,
    VoidCallback? action,
    String? label,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Palette.deepOrange,
        content: Text(content),
        action: action != null && label != null
            ? SnackBarAction(
                label: label,
                onPressed: action,
                textColor: Theme.of(context).textTheme.bodyLarge?.color,
              )
            : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void>? goToItemScreen({
    required ItemScreenArgs args,
    bool forceNewScreen = false,
  }) {
    final bool splitViewEnabled = context.read<SplitViewCubit>().state.enabled;

    if (splitViewEnabled && !forceNewScreen) {
      context.read<SplitViewCubit>().updateItemScreenArgs(args);
    } else {
      return HackiApp.navigatorKey.currentState?.pushNamed(
        ItemScreen.routeName,
        arguments: args,
      );
    }

    return Future<void>.value();
  }

  void onMoreTapped(Item item, Rect? rect) {
    HapticFeedback.lightImpact();

    if (item.dead || item.deleted) {
      return;
    }

    final bool isBlocked =
        context.read<BlocklistCubit>().state.blocklist.contains(item.by);
    showModalBottomSheet<MenuAction>(
      context: context,
      builder: (BuildContext context) {
        return MorePopupMenu(
          item: item,
          isBlocked: isBlocked,
          showSnackBar: showSnackBar,
          onStoryLinkTapped: onStoryLinkTapped,
          onLoginTapped: onLoginTapped,
        );
      },
    ).then((MenuAction? action) {
      if (action != null) {
        switch (action) {
          case MenuAction.upvote:
            break;
          case MenuAction.downvote:
            break;
          case MenuAction.share:
            onShareTapped(item, rect);
            break;
          case MenuAction.flag:
            onFlagTapped(item);
            break;
          case MenuAction.block:
            onBlockTapped(item, isBlocked: isBlocked);
            break;
          case MenuAction.cancel:
            break;
        }
      }
    });
  }

  Future<void> onStoryLinkTapped(String link) async {
    final int? id = link.itemId;
    if (id != null) {
      await locator
          .get<StoriesRepository>()
          .fetchItemBy(id: id)
          .then((Item? item) {
        if (mounted) {
          if (item != null) {
            HackiApp.navigatorKey.currentState!.pushNamed(
              ItemScreen.routeName,
              arguments: ItemScreenArgs(item: item),
            );
          }
        }
      });
    } else {
      LinkUtil.launch(link);
    }
  }

  void onShareTapped(Item item, Rect? rect) {
    Share.share(
      'https://news.ycombinator.com/item?id=${item.id}',
      sharePositionOrigin: rect,
    );
  }

  void onFlagTapped(Item item) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Flag this comment?'),
          content: Text(
            'Flag this comment posted by ${item.by}?',
            style: const TextStyle(
              color: Palette.grey,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Yes',
              ),
            ),
          ],
        );
      },
    ).then((bool? yesTapped) {
      if (yesTapped ?? false) {
        context.read<AuthBloc>().add(AuthFlag(item: item));
        showSnackBar(content: 'Comment flagged!');
      }
    });
  }

  void onBlockTapped(Item item, {required bool isBlocked}) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${isBlocked ? 'Unblock' : 'Block'} this user?'),
          content: Text(
            'Do you want to ${isBlocked ? 'unblock' : 'block'} ${item.by}'
            ' and ${isBlocked ? 'display' : 'hide'} '
            'comments posted by this user?',
            style: const TextStyle(
              color: Palette.grey,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Yes',
              ),
            ),
          ],
        );
      },
    ).then((bool? yesTapped) {
      if (yesTapped ?? false) {
        if (isBlocked) {
          context.read<BlocklistCubit>().removeFromBlocklist(item.by);
        } else {
          context.read<BlocklistCubit>().addToBlocklist(item.by);
        }
        showSnackBar(content: 'User ${isBlocked ? 'unblocked' : 'blocked'}!');
      }
    });
  }

  void onLoginTapped() {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LoginDialog(
          usernameController: usernameController,
          passwordController: passwordController,
          showSnackBar: showSnackBar,
        );
      },
    );
  }
}
