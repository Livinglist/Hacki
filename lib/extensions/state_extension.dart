import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/blocs/auth/auth_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
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
    context.showSnackBar(
      content: content,
      action: action,
      label: label,
    );
  }

  void showErrorSnackBar() => context.showErrorSnackBar();

  Future<void>? goToItemScreen({
    required ItemScreenArgs args,
    bool forceNewScreen = false,
  }) {
    final bool splitViewEnabled = context.read<SplitViewCubit>().state.enabled;

    if (splitViewEnabled && !forceNewScreen) {
      context.read<SplitViewCubit>().updateItemScreenArgs(args);
    } else {
      context.push(
        '/${ItemScreen.routeName}',
        extra: args,
      );
    }

    return Future<void>.value();
  }

  void onMoreTapped(Item item, Rect? rect) {
    HapticFeedbackUtil.light();

    if (item.dead || item.deleted) {
      return;
    }

    final bool isBlocked =
        context.read<BlocklistCubit>().state.blocklist.contains(item.by);
    showModalBottomSheet<MenuAction>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: MorePopupMenu(
            item: item,
            isBlocked: isBlocked,
            onLoginTapped: onLoginTapped,
          ),
        );
      },
    ).then((MenuAction? action) {
      if (action != null) {
        switch (action) {
          case MenuAction.upvote:
            break;
          case MenuAction.downvote:
            break;
          case MenuAction.fav:
            onFavTapped(item);
          case MenuAction.share:
            onShareTapped(item, rect);
          case MenuAction.flag:
            onFlagTapped(item);
          case MenuAction.block:
            onBlockTapped(item, isBlocked: isBlocked);
          case MenuAction.cancel:
            break;
        }
      }
    });
  }

  void onFavTapped(Item item) {
    final FavCubit favCubit = context.read<FavCubit>();
    final bool isFav = favCubit.state.favIds.contains(item.id);
    if (isFav) {
      favCubit.removeFav(item.id);
    } else {
      favCubit.addFav(item.id);
    }
  }

  Future<void> onShareTapped(Item item, Rect? rect) async {
    late final String? linkToShare;
    if (item.url.isNotEmpty) {
      linkToShare = await showModalBottomSheet<String>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: ColoredBox(
              color: Theme.of(context).canvasColor,
              child: Material(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      onTap: () => context.pop(item.url),
                      title: const Text('Link to article'),
                    ),
                    ListTile(
                      onTap: () => context.pop(
                        'https://news.ycombinator.com/item?id=${item.id}',
                      ),
                      title: const Text('Link to HN'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } else {
      linkToShare = 'https://news.ycombinator.com/item?id=${item.id}';
    }

    if (linkToShare != null) {
      await Share.share(
        linkToShare,
        sharePositionOrigin: rect,
      );
    }
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
              onPressed: () => context.pop(false),
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () => context.pop(true),
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
              onPressed: () => context.pop(false),
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () => context.pop(true),
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
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const LoginDialog();
      },
    );
  }
}
