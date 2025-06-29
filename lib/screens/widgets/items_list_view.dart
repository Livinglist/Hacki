import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/context_extension.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ItemsListView<T extends Item> extends StatelessWidget {
  const ItemsListView({
    this.showDivider = false,
    required this.showWebPreviewOnStoryTile,
    required this.showMetadataOnStoryTile,
    required this.showFavicon,
    required this.showUrl,
    required this.items,
    required this.onTap,
    required this.refreshController,
    super.key,
    this.showAuthor = true,
    this.useSimpleTileForStory = false,
    this.enablePullDown = true,
    this.markReadStories = false,
    this.showOfflineBanner = false,
    this.loadStyle = LoadStyle.ShowWhenLoading,
    this.onRefresh,
    this.onLoadMore,
    this.onPinned,
    this.header,
    this.footer,
    this.onMoreTapped,
    this.scrollController,
    this.itemBuilder,
  });

  final bool showAuthor;
  final bool showDivider;
  final bool useSimpleTileForStory;
  final bool showWebPreviewOnStoryTile;
  final bool showMetadataOnStoryTile;
  final bool showFavicon;
  final bool showUrl;
  final bool enablePullDown;
  final bool markReadStories;
  final bool showOfflineBanner;

  final LoadStyle loadStyle;
  final List<T> items;
  final Widget? header;
  final Widget? footer;
  final RefreshController refreshController;
  final ScrollController? scrollController;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoadMore;
  final ValueChanged<Story>? onPinned;
  final void Function(T) onTap;
  final Widget Function(Widget child, T item)? itemBuilder;

  /// Used for home screen.
  final void Function(Story, Rect?)? onMoreTapped;

  @override
  Widget build(BuildContext context) {
    final ListView child = ListView(
      controller: scrollController,
      children: <Widget>[
        if (showOfflineBanner)
          const OfflineBanner(
            showExitButton: true,
          ),
        if (header != null) header!,
        ...items.map((T e) {
          if (e is Story) {
            final bool hasRead = context.read<StoriesBloc>().hasRead(e);
            final bool swipeGestureEnabled =
                context.read<PreferenceCubit>().state.isSwipeGestureEnabled;
            return <Widget>[
              if (showDivider)
                Padding(
                  padding: EdgeInsetsGeometry.only(
                    bottom:
                        showWebPreviewOnStoryTile ? Dimens.pt8 : Dimens.zero,
                  ),
                  child: const Divider(
                    height: Dimens.zero,
                  ),
                )
              else if (context.read<SplitViewCubit>().state.enabled)
                const Divider(
                  height: Dimens.pt6,
                  color: Palette.transparent,
                ),
              if (useSimpleTileForStory)
                FadeIn(
                  child: InkWell(
                    onTap: () => onTap(e),

                    /// If swipe gesture is enabled on home screen, use
                    /// long press instead of slide action to trigger
                    /// the action menu.
                    onLongPress: swipeGestureEnabled
                        ? () => onMoreTapped?.call(e, context.rect)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: Dimens.pt8,
                        bottom: Dimens.pt8,
                        left: Dimens.pt12,
                        right: Dimens.pt6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                showAuthor
                                    ? '''${e.timeAgo} by ${e.by}'''
                                    : e.timeAgo,
                                style: TextStyle(
                                  color: Theme.of(context).metadataColor,
                                ),
                              ),
                              const SizedBox(
                                width: Dimens.pt12,
                              ),
                            ],
                          ),
                          Linkify(
                            text: e.title,
                            maxLines: 4,
                            style: const TextStyle(
                              fontSize: TextDimens.pt16,
                            ),
                            linkStyle: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            onOpen: (LinkableElement link) => LinkUtil.launch(
                              link.url,
                              context,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...<Widget>[
                GestureDetector(
                  /// If swipe gesture is enabled on home screen, use long press
                  /// instead of slide action to trigger the action menu.
                  onLongPress: swipeGestureEnabled
                      ? () => onMoreTapped?.call(e, context.rect)
                      : null,
                  child: FadeIn(
                    child: StoryTile(
                      key: ValueKey<int>(e.id),
                      story: e,
                      onTap: () => onTap(e),
                      showWebPreview: showWebPreviewOnStoryTile,
                      showMetadata: showMetadataOnStoryTile,
                      showUrl: showUrl,
                      showFavicon: showFavicon,
                      hasRead: markReadStories && hasRead,
                    ),
                  ),
                ),
                if (showDivider && showWebPreviewOnStoryTile)
                  const SizedBox(
                    height: Dimens.pt8,
                  ),
              ],
            ];
          } else if (e is Comment) {
            return <Widget>[
              FadeIn(
                child: InkWell(
                  onTap: () => onTap(e),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: Dimens.pt8,
                      bottom: Dimens.pt8,
                      left: Dimens.pt12,
                      right: Dimens.pt6,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (e.deleted)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: Dimens.pt6,
                              ),
                              child: Text(
                                'deleted',
                                style: TextStyle(color: Palette.grey),
                              ),
                            ),
                          ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Text(
                                  showAuthor
                                      ? '''${e.timeAgo} by ${e.by}'''
                                      : e.timeAgo,
                                  style: TextStyle(
                                    color: Theme.of(context).metadataColor,
                                  ),
                                ),
                                const SizedBox(
                                  width: Dimens.pt12,
                                ),
                              ],
                            ),
                            Linkify(
                              text: e.text,
                              maxLines: 4,
                              style: const TextStyle(
                                fontSize: TextDimens.pt16,
                              ),
                              linkStyle: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onOpen: (LinkableElement link) => LinkUtil.launch(
                                link.url,
                                context,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(
                height: Dimens.zero,
              ),
            ];
          }

          return <Widget>[Container()];
        }).mapIndexed(
          (int index, List<Widget> e) => itemBuilder == null
              ? Column(children: e)
              : itemBuilder!(Column(children: e), items.elementAt(index)),
        ),
        if (footer != null) footer!,
        const SizedBox(
          height: Dimens.pt40,
        ),
      ],
    );

    return SmartRefresher(
      enablePullUp: true,
      enablePullDown: enablePullDown,
      header: WaterDropMaterialHeader(
        backgroundColor: Theme.of(context).colorScheme.primary,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      footer: CustomFooter(
        loadStyle: loadStyle,
        builder: (BuildContext context, LoadStatus? mode) {
          const double height = 55;
          late final Widget body;

          if (mode == LoadStatus.loading) {
            body = const CustomCircularProgressIndicator();
          } else if (mode == LoadStatus.failed) {
            body = const Text(
              'loading failed.',
            );
          } else {
            body = const SizedBox.shrink();
          }
          return SizedBox(
            height: height,
            child: Center(child: body),
          );
        },
      ),
      controller: refreshController,
      onRefresh: onRefresh,
      onLoading: onLoadMore,
      child: child,
    );
  }
}
