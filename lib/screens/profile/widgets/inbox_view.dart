import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:hacki/cubits/notification/notification_cubit.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/link_util.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class InboxView extends StatelessWidget {
  const InboxView({
    required this.refreshController,
    required this.comments,
    required this.unreadCommentsIds,
    required this.onCommentTapped,
    required this.onMarkAllAsReadTapped,
    required this.onLoadMore,
    required this.onRefresh,
    super.key,
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
    return Column(
      children: <Widget>[
        if (unreadCommentsIds.isNotEmpty)
          TextButton(
            onPressed: onMarkAllAsReadTapped,
            child: const Text('Mark all as read'),
          ),
        if (context.read<NotificationCubit>().state.commentFetchingStatus ==
            Status.inProgress)
          const LinearProgressIndicator(),
        Expanded(
          child: SmartRefresher(
            enablePullUp: true,
            header: WaterDropMaterialHeader(
              backgroundColor: Theme.of(context).colorScheme.primary,
              color: Theme.of(context).colorScheme.onPrimary,
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
                            padding: const EdgeInsets.symmetric(
                              vertical: Dimens.pt8,
                              horizontal: Dimens.pt6,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Text(
                                      '''${e.timeAgo} from ${e.by}:''',
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
                                  style: TextStyle(
                                    color: unreadCommentsIds.contains(e.id)
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                        : Theme.of(context).readGrey,
                                    fontSize: TextDimens.pt16,
                                  ),
                                  linkStyle: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(
                                          unreadCommentsIds.contains(e.id)
                                              ? 1
                                              : 0.6,
                                        ),
                                  ),
                                  maxLines: 4,
                                  onOpen: (LinkableElement link) =>
                                      LinkUtil.launch(link.url, context),
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
