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
    this.isActionable = true,
    this.isCollapsable = true,
    this.isSelectable = true,
    this.isResponse = false,
    this.isNew = false,
    this.isEyeCandyEnabled = false,
    this.shouldShowDivider = true,
    this.level = 0,
    this.index,
    this.onTap,
  });

  final String? opUsername;
  final Comment comment;
  final int level;
  final int? index;
  final bool isActionable;
  final bool isCollapsable;
  final bool isSelectable;
  final bool isResponse;
  final bool isNew;
  final bool isEyeCandyEnabled;
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
          if (isActionable && state.hidden) return const SizedBox.shrink();

          final Color primaryColor = Theme.of(context).colorScheme.primary;
          final Brightness brightness = Theme.of(context).brightness;
          final (Color, Color) slidableBackgroundColor =
              isEyeCandyEnabled && level > 0
                  ? _getRainbowColor(
                      level,
                      Theme.of(context).colorScheme.surface,
                    )
                  : (
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.onPrimary,
                    );

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
                              onPressed: (_) =>
                                  onRightMoreTapped?.call(comment),
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
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
                              if (isActionable && state.collapsed)
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
                                        selectable: isSelectable,
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
      ),
    );
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
    final CollapseState collapseState = context.read<CollapseCubit>().state;
    final CommentsState? commentsState =
        context.tryRead<CommentsCubit>()?.state;
    return isActionable &&
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
