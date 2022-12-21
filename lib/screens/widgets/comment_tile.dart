import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/bloc_builder_3.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.myUsername,
    required this.comment,
    required this.onStoryLinkTapped,
    required this.fetchMode,
    this.onReplyTapped,
    this.onMoreTapped,
    this.onEditTapped,
    this.onRightMoreTapped,
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
  final Function(Comment, Rect?)? onMoreTapped;
  final Function(Comment)? onEditTapped;
  final Function(Comment)? onRightMoreTapped;
  final Function(String) onStoryLinkTapped;
  final FetchMode fetchMode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CollapseCubit>(
      key: ValueKey<String>('${comment.id}-BlocProvider'),
      lazy: false,
      create: (_) => CollapseCubit(
        commentId: comment.id,
        collapseCache: context.tryRead<CollapseCache>() ?? CollapseCache(),
      )..init(),
      child: BlocBuilder3<CollapseCubit, CollapseState, PreferenceCubit,
          PreferenceState, BlocklistCubit, BlocklistState>(
        builder: (
          BuildContext context,
          CollapseState state,
          PreferenceState prefState,
          BlocklistState blocklistState,
        ) {
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
                              onPressed: (_) => onReplyTapped?.call(comment),
                              backgroundColor: Palette.orange,
                              foregroundColor: Palette.white,
                              icon: Icons.message,
                            ),
                            if (context.read<AuthBloc>().state.user.id ==
                                comment.by)
                              SlidableAction(
                                onPressed: (_) => onEditTapped?.call(comment),
                                backgroundColor: Palette.orange,
                                foregroundColor: Palette.white,
                                icon: Icons.edit,
                              ),
                            SlidableAction(
                              onPressed: (BuildContext context) =>
                                  onMoreTapped?.call(
                                comment,
                                context.rect,
                              ),
                              backgroundColor: Palette.orange,
                              foregroundColor: Palette.white,
                              icon: Icons.more_horiz,
                            ),
                          ],
                        )
                      : null,
                  endActionPane: actionable
                      ? ActionPane(
                          motion: const StretchMotion(),
                          children: <Widget>[
                            SlidableAction(
                              onPressed: (_) =>
                                  onRightMoreTapped?.call(comment),
                              backgroundColor: Palette.orange,
                              foregroundColor: Palette.white,
                              icon: Icons.av_timer,
                            ),
                          ],
                        )
                      : null,
                  child: InkWell(
                    onTap: () {
                      if (actionable) {
                        HapticFeedback.selectionClick();
                        context.read<CollapseCubit>().collapse();
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                            left: Dimens.pt6,
                            right: Dimens.pt6,
                            top: Dimens.pt6,
                          ),
                          child: Row(
                            children: <Widget>[
                              Text(
                                comment.by,
                                style: TextStyle(
                                  color:
                                      prefState.showEyeCandy ? orange : color,
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
                                  color: Palette.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (actionable && state.collapsed)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: Dimens.pt12,
                              ),
                              child: Text(
                                'collapsed '
                                '(${state.collapsedCount + 1})',
                                style: const TextStyle(
                                  color: Palette.orangeAccent,
                                ),
                              ),
                            ),
                          )
                        else if (comment.deleted)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: Dimens.pt12,
                              ),
                              child: Text(
                                'deleted',
                                style: TextStyle(
                                  color: Palette.grey,
                                ),
                              ),
                            ),
                          )
                        else if (comment.dead)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: Dimens.pt12,
                              ),
                              child: Text(
                                'dead',
                                style: TextStyle(
                                  color: Palette.grey,
                                ),
                              ),
                            ),
                          )
                        else if (blocklistState.blocklist.contains(comment.by))
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.only(
                                bottom: Dimens.pt12,
                              ),
                              child: Text(
                                'blocked',
                                style: TextStyle(
                                  color: Palette.grey,
                                ),
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(
                              left: Dimens.pt8,
                              right: Dimens.pt8,
                              top: Dimens.pt6,
                              bottom: Dimens.pt12,
                            ),
                            child: comment is BuildableComment
                                ? SelectableText.rich(
                                    key: ValueKey<int>(comment.id),
                                    buildTextSpan(
                                      (comment as BuildableComment).elements,
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(
                                              context,
                                            ).textScaleFactor *
                                            prefState.fontSize.fontSize,
                                      ),
                                      linkStyle: TextStyle(
                                        fontSize: MediaQuery.of(
                                              context,
                                            ).textScaleFactor *
                                            prefState.fontSize.fontSize,
                                        decoration: TextDecoration.underline,
                                        color: Palette.orange,
                                      ),
                                      onOpen: (LinkableElement link) {
                                        if (link.url.isStoryLink) {
                                          onStoryLinkTapped.call(link.url);
                                        } else {
                                          LinkUtil.launch(link.url);
                                        }
                                      },
                                    ),
                                    onTap: () => onTextTapped(context),
                                  )
                                : SelectableLinkify(
                                    key: ValueKey<int>(comment.id),
                                    text: comment.text,
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context)
                                              .textScaleFactor *
                                          prefState.fontSize.fontSize,
                                    ),
                                    linkStyle: TextStyle(
                                      fontSize: MediaQuery.of(context)
                                              .textScaleFactor *
                                          prefState.fontSize.fontSize,
                                      color: Palette.orange,
                                    ),
                                    onOpen: (LinkableElement link) {
                                      if (link.url.isStoryLink) {
                                        onStoryLinkTapped.call(link.url);
                                      } else {
                                        LinkUtil.launch(link.url);
                                      }
                                    },
                                    onTap: () => onTextTapped(context),
                                  ),
                          ),
                        if (!state.collapsed &&
                            fetchMode == FetchMode.lazy &&
                            comment.kids.isNotEmpty &&
                            !context
                                .read<CommentsCubit>()
                                .state
                                .commentIds
                                .contains(comment.kids.first) &&
                            !context
                                .read<CommentsCubit>()
                                .state
                                .onlyShowTargetComment)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimens.pt12,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () {
                                        HapticFeedback.selectionClick();
                                        context.read<CommentsCubit>().loadMore(
                                              comment: comment,
                                            );
                                      },
                                      child: Text(
                                        '''Load ${comment.kids.length} ${comment.kids.length > 1 ? 'replies' : 'reply'}''',
                                        style: const TextStyle(
                                          fontSize: TextDimens.pt12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const Divider(
                          height: Dimens.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );

          final double commentBackgroundColorOpacity =
              Theme.of(context).brightness == Brightness.dark ? 0.03 : 0.15;

          final Color commentColor = prefState.showEyeCandy
              ? color.withOpacity(commentBackgroundColorOpacity)
              : Palette.transparent;
          final bool isMyComment = myUsername == comment.by;

          Widget wrapper = child;

          if (isMyComment && level == 0) {
            return Container(
              color: Palette.orange.withOpacity(0.2),
              child: wrapper,
            );
          }

          for (final int i in level.to(0, inclusive: false)) {
            final Color wrapperBorderColor = _getColor(i);
            final bool shouldHighlight = isMyComment && i == level;
            wrapper = Container(
              clipBehavior: Clip.hardEdge,
              margin: const EdgeInsets.only(
                left: Dimens.pt12,
              ),
              decoration: BoxDecoration(
                border: i != 0
                    ? Border(
                        left: BorderSide(
                          color: wrapperBorderColor,
                        ),
                      )
                    : null,
                color: shouldHighlight
                    ? Palette.orange.withOpacity(0.2)
                    : commentColor,
              ),
              child: wrapper,
            );
          }

          return wrapper;
        },
      ),
    );
  }

  static final Map<int, Color> _colors = <int, Color>{};

  Color _getColor(int level) {
    final int initialLevel = level;
    if (_colors[initialLevel] != null) return _colors[initialLevel]!;

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

    _colors[initialLevel] = color;
    return color;
  }

  void onTextTapped(BuildContext context) {
    if (context.read<PreferenceCubit>().state.tapAnywhereToCollapse) {
      HapticFeedback.selectionClick();
      context.read<CollapseCubit>().collapse();
    }
  }
}
