import 'dart:async';

import 'package:flutter/material.dart' hide DateUtils;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/item/widgets/widgets.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class MainView extends StatelessWidget {
  const MainView({
    required this.scrollOffsetListener,
    required this.commentEditingController,
    required this.authState,
    required this.preferenceState,
    required this.splitViewEnabled,
    required this.onMoreTapped,
    required this.onRightMoreTapped,
    required this.shouldMarkNewComment,
    required this.indentPadding,
    required this.indentLineWidth,
    required this.topPadding,
    super.key,
  });

  final ScrollOffsetListener scrollOffsetListener;
  final TextEditingController commentEditingController;
  final AuthState authState;
  final PreferenceState preferenceState;
  final bool splitViewEnabled;
  final bool shouldMarkNewComment;
  final void Function(Item item, Rect? rect) onMoreTapped;
  final ValueChanged<Comment> onRightMoreTapped;
  final double indentPadding;
  final double indentLineWidth;
  final double topPadding;

  static const int _loadingIndicatorOpacityAnimationDuration = 300;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: BlocBuilder<CommentsCubit, CommentsState>(
            buildWhen: (CommentsState previous, CommentsState current) =>
                previous.comments != current.comments ||
                previous.status != current.status,
            builder: (BuildContext context, CommentsState state) {
              return RefreshIndicator(
                displacement: 200,
                color: Theme.of(context).colorScheme.primaryContainer,
                onRefresh: () async {
                  HapticFeedbackUtils.light();

                  if (context.read<StoriesBloc>().state.isOfflineReading ==
                          false &&
                      state.onlyShowTargetComment == false) {
                    unawaited(
                      context.read<CommentsCubit>().refresh(
                            onError: (AppException e) =>
                                context.showErrorSnackBar(
                              e.message,
                              e.error,
                            ),
                          ),
                    );

                    if (state.item.isPoll) {
                      context.read<PollCubit>().refresh();
                    }
                  }
                },
                child: ScrollablePositionedList.builder(
                  physics: const ClampingScrollPhysics(),
                  itemScrollController:
                      context.read<CommentsCubit>().itemScrollController,
                  itemPositionsListener:
                      context.read<CommentsCubit>().itemPositionsListener,
                  itemCount: state.comments.length + 2,
                  scrollOffsetListener: scrollOffsetListener,
                  minCacheExtent: WidgetUtils.calculateCacheExtent(context),
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      return Material(
                        color: Theme.of(context).canvasColor,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: topPadding,
                          ),
                          child: _ParentItemSection(
                            commentEditingController: commentEditingController,
                            state: state,
                            authState: authState,
                            preferenceState: preferenceState,
                            splitViewEnabled: splitViewEnabled,
                            onMoreTapped: onMoreTapped,
                            onUpvoteTapped: (Item item) => onUpvoteTapped(
                              context,
                              item,
                            ),
                          ),
                        ),
                      );
                    } else if (index == state.comments.length + 1) {
                      if ((state.status == CommentsStatus.allLoaded &&
                              state.comments.isNotEmpty) ||
                          state.onlyShowTargetComment) {
                        return Container(
                          color: Theme.of(context).canvasColor,
                          height: MediaQuery.of(context).size.height -
                              MediaQuery.of(context).padding.top,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimens.pt48,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              SizedBoxes.pt100,
                              if (preferenceState.isEyeCandyEnabled)
                                GestureDetector(
                                  onTap: () => unawaited(
                                    HapticFeedbackUtils.loadAndPlay(),
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.all(Dimens.pt24),
                                      child: FaIcon(
                                        FontAwesomeIcons.heartPulse,
                                        applyTextScaling: false,
                                        color: Theme.of(context).hintColor,
                                        size: Dimens.pt36,
                                      ),
                                    ),
                                  ),
                                )
                              else if (DateUtils.isMidnight)
                                Text(
                                  'Time for bed',
                                  style: TextStyle(
                                    color: Theme.of(context).hintColor,
                                    fontSize: TextDimens.pt10,
                                  ),
                                  textScaler: TextScaler.noScaling,
                                  textAlign: TextAlign.center,
                                )
                              else if (DateUtils.isTodayAnniversary)
                                Text(
                                  '''Hacki turns ${DateUtils.yearsSinceFirstCommit} today!''',
                                  style: TextStyle(
                                    color: Theme.of(context).hintColor,
                                    fontSize: TextDimens.pt10,
                                  ),
                                  textScaler: TextScaler.noScaling,
                                  textAlign: TextAlign.center,
                                )
                              else
                                Text(
                                  Constants.happyFace,
                                  style: TextStyle(
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              SizedBoxes.pt36,
                              Text(
                                context.read<CommentsCubit>().currentTips,
                                style: TextStyle(
                                  fontSize: TextDimens.pt10,
                                  color: Theme.of(context).hintColor,
                                ),
                                textScaler: TextScaler.noScaling,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    }

                    index = index - 1;
                    final Comment comment = state.comments.elementAt(index);

                    return FadeIn(
                      key: context.read<CommentsCubit>().globalKeys[comment.id],
                      child: comment.isHiddenByUser
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: EdgeInsets.only(
                                left: splitViewEnabled
                                    ? comment.level * indentPadding
                                    : comment.level * indentPadding +
                                        indentLineWidth,
                              ),
                              child: CommentTile(
                                comment: comment,
                                commentBackgroundColor:
                                    Theme.of(context).canvasColor,
                                index: index,
                                level: comment.level,
                                opUsername: state.item.by,
                                fetchMode: state.fetchMode,
                                isResponse: state.isResponse(comment),
                                isCompactCollapsedTileEnabled: preferenceState
                                    .isCompactCollapsedTileEnabled,
                                shouldHighlightNewComments:
                                    preferenceState.shouldHighlightNewComments,
                                isDev: preferenceState.isDevModeEnabled,
                                isNew: shouldMarkNewComment &&
                                    !comment.isFromCache,
                                isEyeCandyEnabled:
                                    preferenceState.isEyeCandyEnabled,
                                onUpvoteTapped: (Comment cmt) =>
                                    onUpvoteTapped(context, cmt),
                                onReplyTapped: (Comment cmt) =>
                                    onReplyTapped(context, cmt),
                                onEditTapped: (Comment cmt) =>
                                    onEditTapped(context, cmt),
                                onMoreTapped: onMoreTapped,
                                onRightMoreTapped: onRightMoreTapped,
                              ),
                            ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        if (preferenceState.isDevModeEnabled)
          Positioned(
            height: Dimens.pt4,
            bottom: Dimens.zero,
            left: Dimens.zero,
            right: Dimens.zero,
            child: BlocBuilder<CommentsCubit, CommentsState>(
              buildWhen: (CommentsState prev, CommentsState current) =>
                  prev.status != current.status,
              builder: (BuildContext context, CommentsState state) {
                return AnimatedOpacity(
                  opacity: state.status == CommentsStatus.inProgress
                      ? NumSwitch.on
                      : NumSwitch.off,
                  duration: const Duration(
                    milliseconds: _loadingIndicatorOpacityAnimationDuration,
                  ),
                  child: const LinearProgressIndicator(),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> onUpvoteTapped(BuildContext context, Item item) async {
    final AuthBloc authBloc = context.read<AuthBloc>();
    if (authBloc.state.isLoggedIn) {
      final VoteCubit cubit = VoteCubit(
        item: item,
        authBloc: authBloc,
        shouldInitialize: false,
      );
      final bool res = await cubit.upvote();
      if (res && context.mounted) {
        context.showSnackBar(
          content: SnackBarMessages.voteSubmitted,
        );
      }
    } else {
      HapticFeedbackUtils.error();
      context.showSnackBar(
        content: SnackBarMessages.notLoggedInNoVoting,
        action: () {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return const LoginDialog();
            },
          );
        },
        label: 'Log in',
      );
    }
  }

  void onReplyTapped(BuildContext context, Comment cmt) {
    HapticFeedbackUtils.light();
    if (cmt.deleted || cmt.dead) {
      return;
    }

    if (cmt.id != context.read<EditCubit>().state.replyingTo?.id) {
      commentEditingController.clear();
    }

    context.read<EditCubit>().onReplyTapped(cmt);
  }

  void onEditTapped(BuildContext context, Comment cmt) {
    HapticFeedbackUtils.light();
    if (cmt.deleted || cmt.dead) {
      return;
    }
    commentEditingController.clear();
    context.read<EditCubit>().onEditTapped(cmt);
  }
}

class _ParentItemSection extends StatelessWidget {
  const _ParentItemSection({
    required this.commentEditingController,
    required this.state,
    required this.authState,
    required this.preferenceState,
    required this.splitViewEnabled,
    required this.onMoreTapped,
    required this.onUpvoteTapped,
  });

  final TextEditingController commentEditingController;
  final CommentsState state;
  final AuthState authState;
  final PreferenceState preferenceState;
  final bool splitViewEnabled;
  final void Function(Item item, Rect? rect) onMoreTapped;
  final void Function(Item) onUpvoteTapped;

  @override
  Widget build(BuildContext context) {
    final Item item = state.item;
    return Semantics(
      label:
          '''Posted by ${item.by} ${item.timeAgo}, ${item.title}. ${item.text}''',
      child: Column(
        children: <Widget>[
          if (!splitViewEnabled)
            const Padding(
              padding: EdgeInsets.only(bottom: Dimens.pt6),
              child: OfflineBanner(),
            ),
          DeviceGestureWrapper(
            child: Slidable(
              startActionPane: ActionPane(
                motion: const BehindMotion(),
                children: <Widget>[
                  if (context.read<AuthBloc>().state.user.id != item.by)
                    CustomSlidableAction(
                      onPressed: (_) => onUpvoteTapped.call(item),
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimaryContainer,
                      child: const Icon(
                        Icons.thumb_up,
                        size: Dimens.pt24,
                      ),
                    ),
                  CustomSlidableAction(
                    onPressed: (_) {
                      HapticFeedbackUtils.light();

                      if (item.id !=
                          context.read<EditCubit>().state.replyingTo?.id) {
                        commentEditingController.clear();
                      }
                      context.read<EditCubit>().onReplyTapped(item);
                    },
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    child: const Icon(
                      Icons.message,
                      size: Dimens.pt24,
                    ),
                  ),
                  CustomSlidableAction(
                    onPressed: (BuildContext context) =>
                        onMoreTapped(item, context.rect),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    child: const Icon(
                      Icons.more_horiz,
                      size: Dimens.pt24,
                    ),
                  ),
                ],
              ),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(
                      left: Dimens.pt6,
                      right: Dimens.pt6,
                    ),
                    child: Row(
                      children: <Widget>[
                        Text(
                          item.by,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          textScaler: MediaQuery.of(context).textScaler,
                        ),
                        const Spacer(),
                        Text(
                          preferenceState.displayDateFormat
                              .convertToString(item.time),
                          style: TextStyle(
                            color: Theme.of(context).metadataColor,
                          ),
                          textScaler: MediaQuery.of(context).textScaler,
                        ),
                      ],
                    ),
                  ),
                  BlocBuilder<PreferenceCubit, PreferenceState>(
                    buildWhen: (
                      PreferenceState previous,
                      PreferenceState current,
                    ) =>
                        previous.fontSize != current.fontSize,
                    builder: (
                      BuildContext context,
                      PreferenceState prefState,
                    ) {
                      final double fontSize = prefState.fontSize.fontSize;
                      return Column(
                        children: <Widget>[
                          if (item is Story)
                            InkWell(
                              onTap: () => LinkUtils.launch(
                                item.url,
                                context,
                                shouldUseReader: prefState.isReaderEnabled,
                                isOfflineReading: context
                                    .read<StoriesBloc>()
                                    .state
                                    .isOfflineReading,
                              ),
                              onLongPress: () {
                                if (item.url.isNotEmpty) {
                                  Clipboard.setData(
                                    ClipboardData(text: item.url),
                                  ).whenComplete(() {
                                    HapticFeedbackUtils.selection();
                                    if (context.mounted) {
                                      context.showSnackBar(
                                        content: 'Link copied.',
                                      );
                                    }
                                  });
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: Dimens.pt6,
                                  right: Dimens.pt6,
                                  bottom: Dimens.pt12,
                                  top: Dimens.pt6,
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    children: <TextSpan>[
                                      TextSpan(
                                        semanticsLabel: item.title,
                                        text: item.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: fontSize,
                                          color: item.url.isNotEmpty
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : null,
                                        ),
                                      ),
                                      if (item.url.isNotEmpty)
                                        TextSpan(
                                          text: ''' (${item.readableUrl})''',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: fontSize - 4,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                  textScaler: MediaQuery.of(context).textScaler,
                                ),
                              ),
                            )
                          else
                            const SizedBox(
                              height: Dimens.pt6,
                            ),
                          if (item.text.isNotEmpty)
                            FadeIn(
                              child: SizedBox(
                                width: double.infinity,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: Dimens.pt8,
                                    bottom: Dimens.pt8,
                                  ),
                                  child: ItemText(
                                    item: item,
                                    textScaler:
                                        MediaQuery.of(context).textScaler,
                                    selectable: true,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  if (item is Story && item.isPoll) ...<Widget>[
                    BlocProvider<PollCubit>(
                      create: (BuildContext context) =>
                          PollCubit(story: item)..init(),
                      child: const PollView(),
                    ),
                    SizedBoxes.pt6,
                  ],
                ],
              ),
            ),
          ),
          const Divider(
            height: Dimens.zero,
          ),
          if (state.onlyShowTargetComment && item is Story) ...<Widget>[
            Center(
              child: TextButton(
                onPressed: () => context.read<CommentsCubit>().loadAll(item),
                child: const Text('View all comments'),
              ),
            ),
            const Divider(
              height: Dimens.zero,
            ),
          ] else ...<Widget>[
            SizedBox(
              height: 48,
              child: Row(
                children: <Widget>[
                  if (item is Story) ...<Widget>[
                    const SizedBox(
                      width: Dimens.pt12,
                    ),
                    Text(
                      '''${item.score} karma, ${item.descendants} cmt${item.descendants > 1 ? 's' : ''}''',
                      style: Theme.of(context).textTheme.labelLarge,
                      textScaler: MediaQuery.of(context).clampedTextScaler,
                    ),
                  ] else ...<Widget>[
                    const SizedBox(
                      width: Dimens.pt4,
                    ),
                    BlocSelector<CommentsCubit, CommentsState, CommentsStatus>(
                      selector: (CommentsState state) =>
                          state.fetchParentStatus,
                      builder: (BuildContext context, CommentsStatus status) {
                        return TextButton(
                          onPressed:
                              context.read<CommentsCubit>().loadParentThread,
                          child: status == CommentsStatus.inProgress
                              ? const SizedBox(
                                  height: Dimens.pt12,
                                  width: Dimens.pt12,
                                  child: CustomCircularProgressIndicator(
                                    strokeWidth: Dimens.pt2,
                                  ),
                                )
                              : Text(
                                  'View Parent',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                  textScaler:
                                      MediaQuery.of(context).clampedTextScaler,
                                ),
                        );
                      },
                    ),
                    BlocSelector<CommentsCubit, CommentsState, CommentsStatus>(
                      selector: (CommentsState state) => state.fetchRootStatus,
                      builder: (BuildContext context, CommentsStatus status) {
                        return TextButton(
                          onPressed:
                              context.read<CommentsCubit>().loadRootThread,
                          child: status == CommentsStatus.inProgress
                              ? const SizedBox(
                                  height: Dimens.pt12,
                                  width: Dimens.pt12,
                                  child: CustomCircularProgressIndicator(
                                    strokeWidth: Dimens.pt2,
                                  ),
                                )
                              : Text(
                                  'View Root',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                  textScaler:
                                      MediaQuery.of(context).clampedTextScaler,
                                ),
                        );
                      },
                    ),
                  ],
                  const Spacer(),
                  if (!state.isOfflineReading)
                    CustomDropdownMenu<FetchMode>(
                      menuChildren: FetchMode.values,
                      onSelected: context.read<CommentsCubit>().updateFetchMode,
                      selected: state.fetchMode,
                    ),
                  const SizedBox(
                    width: Dimens.pt6,
                  ),
                  CustomDropdownMenu<CommentsOrder>(
                    menuChildren: CommentsOrder.values,
                    onSelected: context.read<CommentsCubit>().updateOrder,
                    selected: state.order,
                  ),
                  const SizedBox(
                    width: Dimens.pt4,
                  ),
                ],
              ),
            ),
            const Divider(
              height: Dimens.zero,
            ),
          ],
          if (state.comments.isEmpty &&
              state.status == CommentsStatus.allLoaded) ...<Widget>[
            const SizedBox(
              height: 240,
            ),
            const Center(
              child: Text(
                'Nothing yet',
                style: TextStyle(color: Palette.grey),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height - 240,
            ),
          ],
        ],
      ),
    );
  }
}
