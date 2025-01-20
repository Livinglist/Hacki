import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({
    required this.comment,
    required this.fetchMode,
    super.key,
    this.onReplyTapped,
    this.onMoreTapped,
    this.onEditTapped,
    this.onRightMoreTapped,
    this.opUsername,
    this.actionable = true,
    this.collapsable = true,
    this.selectable = true,
    this.isResponse = false,
    this.isNew = false,
    this.level = 0,
    this.index,
    this.onTap,
  });

  final String? opUsername;
  final Comment comment;
  final int level;
  final int? index;
  final bool actionable;
  final bool collapsable;
  final bool selectable;
  final bool isResponse;
  final bool isNew;
  final FetchMode fetchMode;

  final void Function(Comment)? onReplyTapped;
  final void Function(Comment, Rect?)? onMoreTapped;
  final void Function(Comment)? onEditTapped;
  final void Function(Comment)? onRightMoreTapped;

  /// Override for search screen.
  final VoidCallback? onTap;

  static final Map<int, Color> levelToBorderColors = <int, Color>{};

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
          if (actionable && state.hidden) return const SizedBox.shrink();

          final Color primaryColor = Theme.of(context).colorScheme.primary;
          final Brightness brightness = Theme.of(context).brightness;
          final Color color = _getColor(
            level,
            primaryColor: primaryColor,
            brightness: brightness,
          );

          final Widget child = DeviceGestureWrapper(
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
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              icon: Icons.message,
                            ),
                            if (context.read<AuthBloc>().state.user.id ==
                                comment.by)
                              SlidableAction(
                                onPressed: (_) => onEditTapped?.call(comment),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                icon: Icons.edit,
                              ),
                            SlidableAction(
                              onPressed: (BuildContext context) =>
                                  onMoreTapped?.call(
                                comment,
                                context.rect,
                              ),
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
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
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              icon: Icons.av_timer,
                            ),
                          ],
                        )
                      : null,
                  child: InkWell(
                    splashFactory: NoSplash.splashFactory,
                    onTap: () {
                      if (collapsable) {
                        _collapse(context);
                      } else {
                        onTap?.call();
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
                                  color: primaryColor,
                                ),
                                textScaler: MediaQuery.of(context).textScaler,
                              ),
                              if (comment.by == opUsername)
                                Text(
                                  ' - OP',
                                  style: TextStyle(
                                    color: primaryColor,
                                  ),
                                ),
                              if (index != null)
                                Text(
                                  ' #${index! + 1}',
                                  style: const TextStyle(
                                    color: Palette.grey,
                                  ),
                                  textScaler: MediaQuery.of(context).textScaler,
                                ),
                              if (isResponse)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.reply,
                                    size: 16,
                                    color: Palette.grey,
                                  ),
                                ),
                              // Commented out for now, maybe review later.
                              // if (!comment.dead && isNew)
                              //   const Padding(
                              //     padding: EdgeInsets.only(left: 4),
                              //     child: Icon(
                              //       Icons.sunny_snowing,
                              //       size: 16,
                              //       color: Palette.grey,
                              //     ),
                              //   ),
                              const Spacer(),
                              Text(
                                prefState.displayDateFormat
                                    .convertToString(comment.time),
                                style: TextStyle(
                                  color: Theme.of(context).metadataColor,
                                ),
                                textScaler: MediaQuery.of(context).textScaler,
                              ),
                            ],
                          ),
                        ),
                        AnimatedSize(
                          duration: AppDurations.ms200,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (actionable && state.collapsed)
                                CenteredText(
                                  text:
                                      '''collapsed (${state.collapsedCount + 1})''',
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.8),
                                )
                              else if (comment.hidden)
                                const CenteredText.hidden()
                              else if (comment.deleted)
                                const CenteredText.deleted()
                              else if (comment.dead)
                                const CenteredText.dead()
                              else if (blocklistState.blocklist
                                  .contains(comment.by))
                                const CenteredText.blocked()
                              else
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: Dimens.pt8,
                                    right: Dimens.pt2,
                                    top: Dimens.pt6,
                                    bottom: Dimens.pt12,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Semantics(
                                      label: '''At level ${comment.level}.''',
                                      child: ItemText(
                                        key: ValueKey<int>(comment.id),
                                        item: comment,
                                        selectable: selectable,
                                        textScaler:
                                            MediaQuery.of(context).textScaler,
                                        onTap: () {
                                          if (onTap == null) {
                                            _onTextTapped(context);
                                          } else {
                                            onTap!.call();
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_shouldShowLoadButton(context))
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
                                        HapticFeedbackUtil.selection();
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
              Theme.of(context).canvasColor != Palette.white ? 0.03 : 0.15;

          final Color commentColor = prefState.isEyeCandyEnabled
              ? color.withValues(alpha: commentBackgroundColorOpacity)
              : Palette.transparent;
          final bool isMyComment = comment.deleted == false &&
              context.read<AuthBloc>().state.username == comment.by;

          Widget wrapper = child;

          if (isMyComment && level == 0) {
            return Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: 0.2,
                    ),
              ),
              child: wrapper,
            );
          }

          for (final int i in level.to(0, inclusive: false)) {
            final Color wrapperBorderColor = _getColor(
              i,
              primaryColor: primaryColor,
              brightness: brightness,
            );
            final bool shouldHighlight = isMyComment && i == level;
            wrapper = Container(
              clipBehavior: Clip.hardEdge,
              margin: const EdgeInsets.only(
                left: Dimens.pt8,
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
                    ? primaryColor.withValues(alpha: 0.2)
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

  Color _getColor(
    int level, {
    required Color primaryColor,
    required Brightness brightness,
  }) {
    final int initialLevel = level;

    int convertKeyBasedOnBrightness(int original) {
      return brightness == Brightness.light ? original : original * 100;
    }

    final int cacheKey = convertKeyBasedOnBrightness(initialLevel);

    if (levelToBorderColors[cacheKey] != null) {
      return levelToBorderColors[cacheKey]!;
    } else if (level == 0) {
      levelToBorderColors[cacheKey] = primaryColor;
      return primaryColor;
    }

    while (level >= 10) {
      level = level - 10;
    }

    final double opacity = ((10 - level) / 10).clamp(0.3, 1);
    final Color color = primaryColor.withValues(alpha: opacity);

    levelToBorderColors[cacheKey] = color;
    return color;
  }

  bool _shouldShowLoadButton(BuildContext context) {
    final CollapseState collapseState = context.read<CollapseCubit>().state;
    final CommentsState? commentsState =
        context.tryRead<CommentsCubit>()?.state;
    return actionable &&
        fetchMode == FetchMode.lazy &&
        comment.kids.isNotEmpty &&
        collapseState.collapsed == false &&
        commentsState?.commentIds.contains(comment.kids.first) == false &&
        commentsState?.onlyShowTargetComment == false;
  }

  void _onTextTapped(BuildContext context) {
    if (context.read<PreferenceCubit>().state.isTapAnywhereToCollapseEnabled) {
      _collapse(context);
    }
  }

  void _collapse(BuildContext context) {
    final PreferenceCubit preferenceCubit = context.read<PreferenceCubit>();
    final CollapseCubit collapseCubit = context.read<CollapseCubit>()
      ..collapse(onStateChanged: HapticFeedbackUtil.selection);
    if (collapseCubit.state.collapsed &&
        preferenceCubit.state.isAutoScrollEnabled) {
      final CommentsCubit commentsCubit = context.read<CommentsCubit>();
      final List<Comment> comments = commentsCubit.state.comments;
      final int indexOfComment = comments.indexOf(comment);
      if (indexOfComment < comments.length) {
        final double? leadingEdge =
            commentsCubit.itemPositionsListener.itemPositions.value
                .singleWhereOrNull(
                  (ItemPosition e) => e.index - 1 == indexOfComment,
                )
                ?.itemLeadingEdge;
        final bool willBeOutsideOfScreen =
            leadingEdge != null && leadingEdge < 0.1;
        if (willBeOutsideOfScreen) {
          Future<void>.delayed(
            AppDurations.ms200,
            () {
              commentsCubit.itemScrollController.scrollTo(
                index: indexOfComment + 1,
                alignment: 0.15,
                duration: AppDurations.ms300,
              );
            },
          );
        }
      }
    }
  }
}
