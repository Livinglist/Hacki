import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class ItemsListView<T extends Item> extends StatelessWidget {
  const ItemsListView({
    super.key,
    required this.showWebPreview,
    required this.showMetadata,
    required this.items,
    required this.onTap,
    required this.refreshController,
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

  final bool showWebPreview;
  final bool showMetadata;
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
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
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
                    hasRead: markReadStories && hasRead,
                    simpleTileFontSize: useConsistentFontSize ? 14 : 16,
                  ),
                ),
              ),
              if (!showWebPreview)
                const Divider(
                  height: 0,
                ),
            ];
          } else if (e is Comment) {
            return <Widget>[
              FadeIn(
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
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
                                padding: EdgeInsets.only(top: 6),
                                child: Text(
                                  'deleted',
                                  style: TextStyle(color: Colors.grey),
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
                                    vertical: 8,
                                    horizontal: 6,
                                  ),
                                  child: Linkify(
                                    text: e.text,
                                    maxLines: 4,
                                    linkStyle: const TextStyle(
                                      color: Colors.orange,
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
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(
                            height: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(
                height: 0,
              ),
            ];
          }

          return <Widget>[Container()];
        }).expand((List<Widget> element) => element),
        const SizedBox(
          height: 40,
        ),
      ],
    );

    return SmartRefresher(
      enablePullUp: true,
      enablePullDown: enablePullDown,
      header: const WaterDropMaterialHeader(
        backgroundColor: Colors.orange,
      ),
      footer: CustomFooter(
        loadStyle: LoadStyle.ShowWhenLoading,
        builder: (BuildContext context, LoadStatus? mode) {
          Widget body;
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
            height: 55,
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
