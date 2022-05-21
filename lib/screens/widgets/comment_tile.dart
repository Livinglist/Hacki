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
    super.key,
    required this.myUsername,
    required this.comment,
    required this.onStoryLinkTapped,
    this.onReplyTapped,
    this.onMoreTapped,
    this.onEditTapped,
    this.onTimeMachineActivated,
    this.opUsername,
    this.actionable = true,
    this.level = 0,
  });

  final String? myUsername;
  final String? opUsername;
  final Comment comment;
  final int level;
  final bool actionable;
  final Function(Comment)? onReplyTapped;
  final Function(Comment)? onMoreTapped;
  final Function(Comment)? onEditTapped;
  final Function(Comment)? onTimeMachineActivated;
  final Function(String) onStoryLinkTapped;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CollapseCubit>(
      lazy: false,
      create: (_) => CollapseCubit(
        commentId: comment.id,
      )..init(),
      child: BlocBuilder<CollapseCubit, CollapseState>(
        builder: (BuildContext context, CollapseState state) {
          if (actionable && state.hidden) return const SizedBox.shrink();

          return BlocBuilder<PreferenceCubit, PreferenceState>(
            builder: (BuildContext context, PreferenceState prefState) {
              return BlocBuilder<BlocklistCubit, BlocklistState>(
                builder: (BuildContext context, BlocklistState blocklistState) {
                  const Color orange = Color.fromRGBO(255, 152, 0, 1);
                  final Color color = _getColor(level);

                  final Padding child = Padding(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Slidable(
                          startActionPane: actionable
                              ? ActionPane(
                                  motion: const StretchMotion(),
                                  children: <Widget>[
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
                          endActionPane: actionable && level != 0
                              ? ActionPane(
                                  motion: const StretchMotion(),
                                  children: <Widget>[
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
                          child: InkWell(
                            onTap: () {
                              if (actionable) {
                                HapticFeedback.lightImpact();
                                context.read<CollapseCubit>().collapse();
                              }
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 6,
                                    right: 6,
                                    top: 6,
                                  ),
                                  child: Row(
                                    children: <Widget>[
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
                                if (comment.deleted)
                                  const Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      child: Text(
                                        'deleted',
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                else if (comment.dead)
                                  const Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      child: Text(
                                        'dead',
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                else if (blocklistState.blocklist
                                    .contains(comment.by))
                                  const Center(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      child: Text(
                                        'blocked',
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                else if (actionable && state.collapsed)
                                  Center(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Text(
                                        'collapsed '
                                        '(${state.collapsedCount + 1})',
                                        style: const TextStyle(
                                          color: Colors.orangeAccent,
                                        ),
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
                                      onOpen: (LinkableElement link) {
                                        if (link.url.contains(
                                          'news.ycombinator.com/item',
                                        )) {
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
                        ),
                      ],
                    ),
                  );

                  final double commentBackgroundColorOpacity =
                      Theme.of(context).brightness == Brightness.dark
                          ? 0.03
                          : 0.15;

                  final Color commentColor = prefState.showEyeCandy
                      ? color.withOpacity(commentBackgroundColorOpacity)
                      : Colors.transparent;
                  final bool isMyComment = myUsername == comment.by;

                  Widget? wrapper = child;

                  if (isMyComment && level == 0) {
                    return Container(
                      color: Colors.orange.withOpacity(0.2),
                      child: wrapper,
                    );
                  }

                  for (final int i in List<int>.generate(
                    level,
                    (int index) => level - index,
                  )) {
                    final Color wrapperBorderColor = _getColor(i);
                    final bool shouldHighlight = isMyComment && i == level;
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

    const int r = 255;
    int g = level * 40 < 255 ? 152 : (level * 20).clamp(0, 255);
    int b = (level * 40).clamp(0, 255);

    if (g == 255 && b == 255) {
      g = (level * 30 - 255).clamp(0, 255);
      b = (level * 40 - 255).clamp(0, 255);
    }

    final Color color = Color.fromRGBO(
      r,
      g,
      b,
      1,
    );

    return color;
  }
}
