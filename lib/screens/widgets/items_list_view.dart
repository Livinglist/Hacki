import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ItemsListView<T extends Item> extends StatelessWidget {
  const ItemsListView({
    super.key,
    required this.showWebPreview,
    required this.showMetadata,
    required this.showUrl,
    required this.items,
    required this.onTap,
    required this.refreshController,
    this.useCommentTile = false,
    this.showCommentBy = false,
    this.enablePullDown = true,
    this.pinnable = false,
    this.markReadStories = false,
    this.useConsistentFontSize = false,
    this.showOfflineBanner = false,
    this.onRefresh,
    this.onLoadMore,
    this.onPinned,
    this.header,
  }) : assert(
          !pinnable || (pinnable && onPinned != null),
          'onPinned cannot be null when pinnable is true',
        );

  final bool useCommentTile;
  final bool showCommentBy;
  final bool showWebPreview;
  final bool showMetadata;
  final bool showUrl;
  final bool enablePullDown;
  final bool markReadStories;
  final bool showOfflineBanner;

  /// Whether story tiles can be pinned to the top.
  final bool pinnable;

  /// Whether to use same font size for comment and story tiles.
  final bool useConsistentFontSize;

  final List<T> items;
  final Widget? header;
  final RefreshController refreshController;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoadMore;
  final ValueChanged<Story>? onPinned;
  final Function(T) onTap;

  @override
  Widget build(BuildContext context) {
    final ListView child = ListView(
      children: <Widget>[
        if (showOfflineBanner)
          const OfflineBanner(
            showExitButton: true,
          ),
        if (header != null) header!,
        ...items.map((T e) {
          if (e is Story) {
            final bool hasRead = context.read<StoriesBloc>().hasRead(e);
            return <Widget>[
              FadeIn(
                child: Slidable(
                  startActionPane: pinnable
                      ? ActionPane(
                          motion: const BehindMotion(),
                          children: <Widget>[
                            SlidableAction(
                              onPressed: (_) {
                                HapticFeedback.lightImpact();
                                onPinned?.call(e);
                              },
                              backgroundColor: Palette.orange,
                              foregroundColor: Palette.white,
                              icon: showWebPreview
                                  ? Icons.push_pin_outlined
                                  : null,
                              label: 'Pin to top',
                            ),
                          ],
                        )
                      : null,
                  child: StoryTile(
                    key: ValueKey<int>(e.id),
                    story: e,
                    onTap: () => onTap(e),
                    showWebPreview: showWebPreview,
                    showMetadata: showMetadata,
                    showUrl: showUrl,
                    hasRead: markReadStories && hasRead,
                    simpleTileFontSize: useConsistentFontSize
                        ? TextDimens.pt14
                        : TextDimens.pt16,
                  ),
                ),
              ),
              if (!showWebPreview)
                const Divider(
                  height: Dimens.zero,
                ),
            ];
          } else if (e is Comment) {
            if (useCommentTile) {
              return <Widget>[
                if (showWebPreview)
                  const Divider(
                    height: Dimens.zero,
                  ),
                _CommentTile(
                  comment: e,
                  onTap: () => onTap(e),
                  fontSize: showWebPreview ? TextDimens.pt14 : TextDimens.pt16,
                ),
                const Divider(
                  height: Dimens.zero,
                ),
              ];
            }
            return <Widget>[
              FadeIn(
                child: Padding(
                  padding: const EdgeInsets.only(left: Dimens.pt6),
                  child: InkWell(
                    onTap: () => onTap(e),
                    child: Padding(
                      padding: EdgeInsets.zero,
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
                          Flex(
                            direction: Axis.horizontal,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: Dimens.pt8,
                                    horizontal: Dimens.pt6,
                                  ),
                                  child: Linkify(
                                    text:
                                        '''${showCommentBy ? '${e.by}: ' : ''}${e.text}''',
                                    maxLines: 4,
                                    linkStyle: const TextStyle(
                                      color: Palette.orange,
                                    ),
                                    onOpen: (LinkableElement link) =>
                                        LinkUtil.launch(link.url),
                                  ),
                                ),
                              ),
                              Row(
                                children: <Widget>[
                                  Text(
                                    e.postedDate,
                                    style: const TextStyle(
                                      color: Palette.grey,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: Dimens.pt12,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(
                            height: Dimens.zero,
                          ),
                        ],
                      ),
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
        }).expand((List<Widget> element) => element),
        const SizedBox(
          height: Dimens.pt40,
        ),
      ],
    );

    return SmartRefresher(
      enablePullUp: true,
      enablePullDown: enablePullDown,
      header: const WaterDropMaterialHeader(
        backgroundColor: Palette.orange,
      ),
      footer: CustomFooter(
        loadStyle: LoadStyle.ShowWhenLoading,
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

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    Key? key,
    required this.comment,
    required this.onTap,
    this.fontSize = 16,
  }) : super(key: key);

  final Comment comment;
  final VoidCallback onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(
          left: Dimens.pt12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(
              height: Dimens.pt8,
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    comment.text,
                    style: TextStyle(
                      fontSize: fontSize,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    comment.metadata,
                    style: TextStyle(
                      color: Palette.grey,
                      fontSize: fontSize - 2,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: Dimens.pt8,
            ),
          ],
        ),
      ),
    );
  }
}
