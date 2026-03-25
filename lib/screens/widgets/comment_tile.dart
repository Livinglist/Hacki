import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/widgets/lazy_fetch_load_button.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/haptic_feedback_util.dart';
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
    this.isDev = false,
    this.isActionable = true,
    this.isCollapsable = true,
    this.isSelectable = true,
    this.isResponse = false,
    this.isNew = false,
    this.isEyeCandyEnabled = false,
    this.isCompactCollapsedTileEnabled = false,
    this.shouldShowDivider = true,
    this.level = 0,
    this.index,
    this.onTap,
  });

  final String? opUsername;
  final Comment comment;
  final int level;
  final int? index;
  final bool isDev;
  final bool isActionable;
  final bool isCollapsable;
  final bool isSelectable;
  final bool isResponse;
  final bool isNew;
  final bool isEyeCandyEnabled;
  final bool isCompactCollapsedTileEnabled;
  final bool shouldShowDivider;
  final FetchMode fetchMode;

  final void Function(Comment)? onReplyTapped;
  final void Function(Comment, Rect?)? onMoreTapped;
  final void Function(Comment)? onEditTapped;
  final void Function(Comment)? onRightMoreTapped;

  /// Override for search screen.
  final VoidCallback? onTap;

  static final Map<int, Color> levelToBorderColors = <int, Color>{};
  static final Map<int, (Color, Color)> levelToRainbowBorderColors =
      <int, (Color, Color)>{};

  @override
  Widget build(BuildContext context) {
    return BlocBuilder2<PreferenceCubit, PreferenceState, BlocklistCubit,
        BlocklistState>(
      builder: (
        BuildContext context,
        PreferenceState prefState,
        BlocklistState blocklistState,
      ) {
        final Color primaryColor = Theme.of(context).colorScheme.primary;
        final Brightness brightness = Theme.of(context).brightness;
        final (Color, Color) slidableBackgroundColor =
            isEyeCandyEnabled && level > 0
                ? _getRainbowColor(
                    level,
                    Theme.of(context).colorScheme.surface,
                  )
                : (
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.onPrimaryContainer,
                  );

        int newCommentsCount = 0;
        int hiddenCommentsCount = 0;
        bool hasNewReplies = false;

        if (isActionable) {
          final (int, int)? hiddenAndNewCommentsCount =
              context.tryRead<CommentsCubit>()?.collapsedCount(comment);
          newCommentsCount = hiddenAndNewCommentsCount?.$2 ?? 0;
          hiddenCommentsCount =
              (hiddenAndNewCommentsCount?.$1 ?? 0) - newCommentsCount;
          hasNewReplies = newCommentsCount > 0;
        }

        final Widget child = DeviceGestureWrapper(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Slidable(
                startActionPane: isActionable
                    ? ActionPane(
                        motion: const StretchMotion(),
                        children: <Widget>[
                          CustomSlidableAction(
                            onPressed: (_) => onReplyTapped?.call(comment),
                            backgroundColor: slidableBackgroundColor.$1,
                            foregroundColor: slidableBackgroundColor.$2,
                            child: const Icon(
                              Icons.message,
                              size: Dimens.pt24,
                            ),
                          ),
                          if (context.read<AuthBloc>().state.user.id ==
                              comment.by)
                            CustomSlidableAction(
                              onPressed: (_) => onEditTapped?.call(comment),
                              backgroundColor: slidableBackgroundColor.$1,
                              foregroundColor: slidableBackgroundColor.$2,
                              child: const Icon(
                                Icons.edit,
                                size: Dimens.pt24,
                              ),
                            ),
                          CustomSlidableAction(
                            onPressed: (BuildContext context) =>
                                onMoreTapped?.call(
                              comment,
                              context.rect,
                            ),
                            backgroundColor: slidableBackgroundColor.$1,
                            foregroundColor: slidableBackgroundColor.$2,
                            child: const Icon(
                              Icons.more_horiz,
                              size: Dimens.pt24,
                            ),
                          ),
                        ],
                      )
                    : null,
                endActionPane: isActionable
                    ? ActionPane(
                        motion: const StretchMotion(),
                        children: <Widget>[
                          CustomSlidableAction(
                            onPressed: (_) => onRightMoreTapped?.call(comment),
                            backgroundColor: slidableBackgroundColor.$1,
                            foregroundColor: slidableBackgroundColor.$2,
                            child: const Icon(
                              Icons.av_timer,
                              size: Dimens.pt24,
                            ),
                          ),
                        ],
                      )
                    : null,
                child: InkWell(
                  splashFactory: NoSplash.splashFactory,
                  onTap: () {
                    if (isCollapsable) {
                      HapticFeedbackUtil.selection();
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
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              textScaler: MediaQuery.of(context).textScaler,
                            ),
                            if (comment.by == opUsername) ...<Widget>[
                              SizedBoxes.pt6,
                              const Icon(
                                Icons.arrow_back_sharp,
                                size: TextDimens.pt12,
                              ),
                              SizedBoxes.pt6,
                              Text(
                                'OP',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            if (index != null)
                              Text(
                                ' #${index! + 1}',
                                style: const TextStyle(
                                  color: Palette.grey,
                                ),
                                textScaler: MediaQuery.of(context).textScaler,
                              ),
                            if (kDebugMode || isDev)
                              Text(
                                ' ${comment.id}',
                                style: const TextStyle(
                                  color: Palette.grey,
                                ),
                                textScaler: MediaQuery.of(context).textScaler,
                              ),
                            if (isResponse)
                              const Padding(
                                padding: EdgeInsets.only(left: Dimens.pt4),
                                child: Icon(
                                  Icons.reply,
                                  size: Dimens.pt16,
                                  color: Palette.grey,
                                ),
                              ),
                            if (comment.isNew)
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: Dimens.pt4),
                                child: Icon(
                                  Icons.fiber_new,
                                  size: Dimens.pt16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                ),
                              )
                            else if (hasNewReplies)
                              const Padding(
                                padding: EdgeInsets.only(left: Dimens.pt4),
                                child: Icon(
                                  Icons.mark_unread_chat_alt,
                                  size: Dimens.pt16,
                                  color: Palette.grey,
                                ),
                              ),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          AnimatedCrossFade(
                            duration: AppDurations.ms300,
                            crossFadeState:
                                isActionable && comment.isCollapsedByUser
                                    ? CrossFadeState.showFirst
                                    : CrossFadeState.showSecond,
                            firstChild: Padding(
                              padding: const EdgeInsets.only(
                                left: Dimens.pt8,
                                right: Dimens.pt2,
                                top: Dimens.pt6,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      if (isCompactCollapsedTileEnabled)
                                        const SizedBox.shrink()
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
                                        Expanded(
                                          child: Text(
                                            comment.text,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .disabledColor,
                                              fontSize:
                                                  prefState.fontSize.fontSize,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            maxLines: 1,
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBoxes.pt6,
                                  CenteredText(
                                    text:
                                        '''collapsed ($hiddenCommentsCount${newCommentsCount == 0 ? '' : ' + $newCommentsCount new'})''',
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.8),
                                  ),
                                ],
                              ),
                            ),
                            secondChild: Padding(
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
                                  child: () {
                                    if (comment.hidden) {
                                      return const CenteredText.hidden();
                                    } else if (comment.deleted) {
                                      return const CenteredText.deleted();
                                    } else if (comment.dead) {
                                      return const CenteredText.dead();
                                    } else if (blocklistState.blocklist
                                        .contains(comment.by)) {
                                      return const CenteredText.blocked();
                                    } else {
                                      return ItemText(
                                        key: ValueKey<int>(comment.id),
                                        item: comment,
                                        selectable: isSelectable,
                                        textScaler:
                                            MediaQuery.of(context).textScaler,
                                        onTap: () {
                                          if (isCollapsable) {
                                            HapticFeedbackUtil.selection();
                                            _onTextTapped(context);
                                          } else {
                                            onTap?.call();
                                          }
                                        },
                                      );
                                    }
                                  }(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      AnimatedCrossFade(
                        firstChild: LazyFetchLoadButton(comment: comment),
                        secondChild: const SizedBox(
                          height: 0,
                          width: double.infinity,
                        ),
                        crossFadeState: _shouldShowLoadButton(context)
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: AppDurations.ms300,
                      ),
                      if (shouldShowDivider)
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

        const Color commentColor = Palette.transparent;
        final bool isMyComment = comment.deleted == false &&
            context.read<AuthBloc>().state.username == comment.by;

        Widget wrapper = child;

        if (level == 0) {
          return Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: () {
                if (isMyComment) {
                  return primaryColor.withValues(alpha: 0.2);
                } else if (comment.isNew) {
                  return Theme.of(context).colorScheme.surfaceContainerLow;
                }

                return commentColor;
              }(),
            ),
            child: wrapper,
          );
        }

        for (final int i in level.to(0, inclusive: false)) {
          final Color wrapperBorderColor = isEyeCandyEnabled
              ? _getRainbowColor(
                  i,
                  Theme.of(context).colorScheme.surface,
                ).$1
              : _getColor(
                  i,
                  primaryColor: primaryColor,
                  brightness: brightness,
                );
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
              color: () {
                if (i == level) {
                  if (isMyComment) {
                    return primaryColor.withValues(alpha: 0.2);
                  } else if (comment.isNew) {
                    return Theme.of(context).colorScheme.surfaceContainerLow;
                  }
                }

                return commentColor;
              }(),
            ),
            child: wrapper,
          );
        }

        /// This makes the left part of the thread that doesn't contain
        /// any text able to recognize for back gesture.
        if (<int>[0, 1, 2, 3].contains(level)) {
          wrapper = Stack(
            children: <Widget>[
              wrapper,
              Positioned(
                left: Dimens.zero,
                top: Dimens.zero,
                bottom: Dimens.zero,
                width: Dimens.pt24,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ],
          );
        }

        return wrapper;
      },
    );
  }

  void _onTextTapped(BuildContext context) {
    if (context.read<PreferenceCubit>().state.isTapAnywhereToCollapseEnabled) {
      _collapse(context);
    }
  }

  void _collapse(BuildContext context) {
    final CommentsCubit commentsCubit = context.read<CommentsCubit>();

    /// When text selection context menu is being displayed,
    /// ignore the collapse request.
    if (commentsCubit.isCommentLocked(comment)) {
      commentsCubit.unlock();
      return;
    }

    if (comment.isCollapsedByUser) {
      commentsCubit.uncollapse(comment);
    } else {
      commentsCubit.collapse(comment);
    }

    final List<Comment> comments = commentsCubit.state.comments;
    final int indexOfComment =
        comments.indexWhere((Comment c) => c.id == comment.id);
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

  static Color _getColor(
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

  static (Color, Color) _getRainbowColor(int level, Color background) {
    const int colorCount = 6;

    // If id is larger than 6, take modulo
    int index = level % colorCount;
    final int key = index + background.hashCode;

    final (Color, Color)? cachedColor = levelToRainbowBorderColors[key];

    if (cachedColor != null) return cachedColor;

    // Ensure positive index
    if (index < 0) {
      index += colorCount;
    }

    // Evenly distribute hue across 6 colors
    final double hue = (index / colorCount) * 360.0;

    // Adjust saturation & lightness based on background brightness
    final bool isDarkBg = background.computeLuminance() < 0.5;
    const double saturation = 0.85;
    final double lightness = isDarkBg ? 0.60 : 0.45;
    final Color color = HSLColor.fromAHSL(
      1, // Fully opaque
      hue,
      saturation,
      lightness,
    ).toColor();

    final bool isDarkColor = color.computeLuminance() < 0.5;
    final Color foregroundColor = isDarkColor ? Palette.white : Palette.black;
    levelToRainbowBorderColors[key] = (color, foregroundColor);
    return (color, foregroundColor);
  }

  bool _shouldShowLoadButton(BuildContext context) {
    final CommentsState? commentsState =
        context.tryRead<CommentsCubit>()?.state;
    return isActionable &&
        fetchMode == FetchMode.lazy &&
        comment.kids.isNotEmpty &&
        comment.isCollapsedByUser == false &&
        commentsState?.commentIds.contains(comment.kids.first) == false &&
        commentsState?.onlyShowTargetComment == false;
  }
}
