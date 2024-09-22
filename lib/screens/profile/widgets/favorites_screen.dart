import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hacki/blocs/auth/auth_bloc.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/profile/widgets/centered_message_view.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    required this.refreshController,
    required this.authState,
    required this.onItemTap,
    super.key,
  });

  final RefreshController refreshController;
  final AuthState authState;
  final void Function(Item) onItemTap;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FavCubit, FavState>(
      listener: (BuildContext context, FavState favState) {
        if (favState.status == Status.success) {
          refreshController
            ..refreshCompleted()
            ..loadComplete();
        }
      },
      buildWhen: (FavState previous, FavState current) =>
          previous.favItems.length != current.favItems.length ||
          previous.isDisplayingStories != current.isDisplayingStories,
      builder: (BuildContext context, FavState favState) {
        Widget? header() => authState.isLoggedIn
            ? Column(
                children: <Widget>[
                  BlocSelector<FavCubit, FavState, Status>(
                    selector: (FavState state) => state.mergeStatus,
                    builder: (
                      BuildContext context,
                      Status status,
                    ) {
                      return TextButton(
                        onPressed: () => context.read<FavCubit>().merge(
                              onError: (AppException e) =>
                                  context.showErrorSnackBar(e.message),
                              onSuccess: () => context.showSnackBar(
                                content: '''Sync completed.''',
                              ),
                            ),
                        child: status == Status.inProgress
                            ? const SizedBox(
                                height: Dimens.pt12,
                                width: Dimens.pt12,
                                child: CustomCircularProgressIndicator(
                                  strokeWidth: Dimens.pt2,
                                ),
                              )
                            : const Text(
                                'Sync from Hacker News',
                              ),
                      );
                    },
                  ),
                  Row(
                    children: <Widget>[
                      const SizedBox(
                        width: Dimens.pt12,
                      ),
                      CustomChip(
                        selected: favState.isDisplayingStories,
                        label: 'Story',
                        onSelected: (_) => context.read<FavCubit>().switchTab(),
                      ),
                      const SizedBox(
                        width: Dimens.pt12,
                      ),
                      CustomChip(
                        selected: !favState.isDisplayingStories,
                        label: 'Comment',
                        onSelected: (_) => context.read<FavCubit>().switchTab(),
                      ),
                    ],
                  ),
                ],
              )
            : null;

        if (favState.favItems.isEmpty && favState.status != Status.inProgress) {
          return Column(
            children: <Widget>[
              header() ?? const SizedBox.shrink(),
              const CenteredMessageView(
                content: 'Your favorite stories will show up here.'
                    '\nThey will be synced to your Hacker '
                    'News account if you are logged in.',
              ),
            ],
          );
        }

        return BlocBuilder<PreferenceCubit, PreferenceState>(
          buildWhen: (
            PreferenceState previous,
            PreferenceState current,
          ) =>
              previous.isComplexStoryTileEnabled !=
                  current.isComplexStoryTileEnabled ||
              previous.isMetadataEnabled != current.isMetadataEnabled ||
              previous.isUrlEnabled != current.isUrlEnabled,
          builder: (
            BuildContext context,
            PreferenceState prefState,
          ) {
            return ItemsListView<Item>(
              showWebPreviewOnStoryTile: prefState.isComplexStoryTileEnabled,
              showMetadataOnStoryTile: prefState.isMetadataEnabled,
              showFavicon: prefState.isFaviconEnabled,
              showUrl: prefState.isUrlEnabled,
              useSimpleTileForStory: true,
              refreshController: refreshController,
              items: favState.isDisplayingStories
                  ? favState.favItems.whereType<Story>().toList(growable: false)
                  : favState.favItems
                      .whereType<Comment>()
                      .toList(growable: false),
              onRefresh: () {
                HapticFeedbackUtil.light();
                context.read<FavCubit>().refresh();
              },
              onLoadMore: () {
                context.read<FavCubit>().loadMore();
              },
              onTap: onItemTap,
              header: header(),
              itemBuilder: (Widget child, Item item) {
                return Slidable(
                  dragStartBehavior: DragStartBehavior.start,
                  startActionPane: ActionPane(
                    motion: const BehindMotion(),
                    children: <Widget>[
                      SlidableAction(
                        onPressed: (_) {
                          HapticFeedbackUtil.light();
                          context.read<FavCubit>().removeFav(item.id);
                        },
                        backgroundColor: Palette.red,
                        foregroundColor: Palette.white,
                        icon: Icons.close,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
            );
          },
        );
      },
    );
  }
}
