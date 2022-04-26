import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/utils/utils.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({
    Key? key,
    required this.myUsername,
    required this.comment,
    required this.onStoryLinkTapped,
    this.onReplyTapped,
    this.onMoreTapped,
    this.onEditTapped,
    this.onTimeMachineActivated,
    this.opUsername,
    this.loadKids = true,
    this.level = 0,
  }) : super(key: key);

  final String? myUsername;
  final String? opUsername;
  final Comment comment;
  final int level;
  final bool loadKids;
  final Function(Comment)? onReplyTapped;
  final Function(Comment)? onMoreTapped;
  final Function(Comment)? onEditTapped;
  final Function(Comment)? onTimeMachineActivated;
  final Function(String) onStoryLinkTapped;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommentsCubit>(
      lazy: false,
      create: (_) => CommentsCubit<Comment>(
        offlineReading: context.read<StoriesBloc>().state.offlineReading,
        item: comment,
      )..init(),
      child: BlocBuilder<CommentsCubit, CommentsState>(
        builder: (context, state) {
          return BlocBuilder<PreferenceCubit, PreferenceState>(
            builder: (context, prefState) {
              return BlocBuilder<BlocklistCubit, BlocklistState>(
                builder: (context, blocklistState) {
                  const orange = Color.fromRGBO(255, 152, 0, 1);
                  final color = _getColor(level);

                  final child = Padding(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Slidable(
                          startActionPane: loadKids
                              ? ActionPane(
                                  motion: const StretchMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (_) =>
                                          onReplyTapped?.call(comment),
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      icon: Icons.message,
                                    ),
                                    if (context
                                            .read<AuthBloc>()
                                            .state
                                            .user
                                            .id ==
                                        comment.by)
                                      SlidableAction(
                                        onPressed: (_) =>
                                            onEditTapped?.call(comment),
                                        backgroundColor: Colors.orange,
                                        foregroundColor: Colors.white,
                                        icon: Icons.edit,
                                      ),
                                    SlidableAction(
                                      onPressed: (_) =>
                                          onMoreTapped?.call(comment),
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      icon: Icons.more_horiz,
                                    ),
                                  ],
                                )
                              : null,
                          endActionPane: loadKids
                              ? ActionPane(
                                  motion: const StretchMotion(),
                                  children: [
                                    SlidableAction(
                                      onPressed: (_) =>
                                          onTimeMachineActivated?.call(comment),
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      icon: Icons.av_timer,
                                    ),
                                  ],
                                )
                              : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context.read<CommentsCubit>().collapse();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 6, right: 6, top: 6),
                                  child: Row(
                                    children: [
                                      Text(
                                        comment.by,
                                        style: TextStyle(
                                          color: prefState.showEyeCandy
                                              ? orange
                                              : color,
                                        ),
                                      ),
                                      if (comment.by == opUsername)
                                        const Text(
                                          ' - OP',
                                          style: TextStyle(
                                            color: orange,
                                          ),
                                        ),
                                      const Spacer(),
                                      Text(
                                        comment.postedDate,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (comment.deleted)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      'deleted',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              else if (comment.dead)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      'dead',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              else if (blocklistState.blocklist
                                  .contains(comment.by))
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      'blocked',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              else if (state.collapsed)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Text(
                                      'collapsed',
                                      style:
                                          TextStyle(color: Colors.orangeAccent),
                                    ),
                                  ),
                                )
                              else
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    right: 8,
                                    top: 6,
                                    bottom: 12,
                                  ),
                                  child: SelectableLinkify(
                                    key: ObjectKey(comment),
                                    text: comment.text,
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context)
                                              .textScaleFactor *
                                          15,
                                    ),
                                    linkStyle: TextStyle(
                                      fontSize: MediaQuery.of(context)
                                              .textScaleFactor *
                                          15,
                                      color: Colors.orange,
                                    ),
                                    onOpen: (link) {
                                      if (link.url.contains(
                                          'news.ycombinator.com/item')) {
                                        onStoryLinkTapped.call(link.url);
                                      } else {
                                        LinkUtil.launchUrl(link.url);
                                      }
                                    },
                                  ),
                                ),
                              const Divider(
                                height: 0,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );

                  final commentBackgroundColorOpacity =
                      Theme.of(context).brightness == Brightness.dark
                          ? 0.03
                          : 0.15;

                  final commentColor = prefState.showEyeCandy
                      ? color.withOpacity(commentBackgroundColorOpacity)
                      : Colors.transparent;
                  final isMyComment = myUsername == comment.by;

                  Widget? wrapper = child;

                  if (isMyComment && level == 0) {
                    return Container(
                      color: Colors.orange.withOpacity(0.2),
                      child: wrapper,
                    );
                  }

                  for (final i
                      in List.generate(level, (index) => level - index)) {
                    final wrapperBorderColor = _getColor(i);
                    final shouldHighlight = isMyComment && i == level;
                    wrapper = Container(
                      margin: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                        border: i != 0
                            ? Border(
                                left: BorderSide(
                                  color: wrapperBorderColor,
                                ),
                              )
                            : null,
                        color: shouldHighlight
                            ? Colors.orange.withOpacity(0.2)
                            : commentColor,
                      ),
                      child: wrapper,
                    );
                  }

                  return wrapper!;
                },
              );
            },
          );
        },
      ),
    );
  }

  Color _getColor(int level) {
    while (level >= 10) {
      level = level - 10;
    }

    const r = 255;
    var g = level * 40 < 255 ? 152 : (level * 20).clamp(0, 255);
    var b = (level * 40).clamp(0, 255);

    if (g == 255 && b == 255) {
      g = (level * 30 - 255).clamp(0, 255);
      b = (level * 40 - 255).clamp(0, 255);
    }

    final color = Color.fromRGBO(
      r,
      g,
      b,
      1,
    );

    return color;
  }
}
