import 'package:flutter/material.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/link_util.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class InboxView extends StatelessWidget {
  const InboxView({
    super.key,
    required this.refreshController,
    required this.comments,
    required this.unreadCommentsIds,
    required this.onCommentTapped,
    required this.onMarkAllAsReadTapped,
    required this.onLoadMore,
    required this.onRefresh,
  });

  final RefreshController refreshController;
  final List<Comment> comments;
  final List<int> unreadCommentsIds;
  final void Function(Comment) onCommentTapped;
  final VoidCallback onMarkAllAsReadTapped;
  final VoidCallback onLoadMore;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final Color textColor = Theme.of(context).brightness == Brightness.dark
        ? Palette.white
        : Palette.black;
    return Column(
      children: <Widget>[
        if (unreadCommentsIds.isNotEmpty)
          TextButton(
            onPressed: onMarkAllAsReadTapped,
            child: const Text('Mark all as read'),
          ),
        Expanded(
          child: SmartRefresher(
            enablePullUp: true,
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
            onLoading: onLoadMore,
            onRefresh: onRefresh,
            child: ListView(
              children: <Widget>[
                ...comments.map((Comment e) {
                  return <Widget>[
                    FadeIn(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: Dimens.pt6,
                        ),
                        child: InkWell(
                          onTap: () => onCommentTapped(e),
                          child: Padding(
                            padding: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
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
                                          text: '${e.by} : ${e.text}',
                                          style: TextStyle(
                                            color:
                                                unreadCommentsIds.contains(e.id)
                                                    ? textColor
                                                    : Palette.grey,
                                          ),
                                          linkStyle: TextStyle(
                                            color:
                                                unreadCommentsIds.contains(e.id)
                                                    ? Palette.orange
                                                    : Palette.orange
                                                        .withOpacity(0.6),
                                          ),
                                          maxLines: 4,
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
                }).expand((List<Widget> element) => element),
                const SizedBox(
                  height: Dimens.pt40,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
