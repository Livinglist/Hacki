import 'dart:async';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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
    required this.topPadding,
    required this.splitViewEnabled,
    required this.onMoreTapped,
    required this.onRightMoreTapped,
    required this.shouldMarkNewComment,
    super.key,
  });

  final ScrollOffsetListener scrollOffsetListener;
  final TextEditingController commentEditingController;
  final AuthState authState;
  final double topPadding;
  final bool splitViewEnabled;
  final bool shouldMarkNewComment;
  final void Function(Item item, Rect? rect) onMoreTapped;
  final ValueChanged<Comment> onRightMoreTapped;

  static const int _loadingIndicatorOpacityAnimationDuration = 300;
  static const double _trailingBoxHeight = 240;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: BlocBuilder<CommentsCubit, CommentsState>(
            buildWhen: (CommentsState previous, CommentsState current) =>
                previous.comments.length != current.comments.length ||
                previous.status != current.status,
            builder: (BuildContext context, CommentsState state) {
              return RefreshIndicator(
                displacement: 100,
                onRefresh: () async {
                  HapticFeedbackUtil.light();

                  if (context.read<StoriesBloc>().state.isOfflineReading ==
                          false &&
                      state.onlyShowTargetComment == false) {
                    unawaited(context.read<CommentsCubit>().refresh());

                    if (state.item.isPoll) {
                      context.read<PollCubit>().refresh();
                    }
                  }
                },
                child: ScrollablePositionedList.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemScrollController:
                      context.read<CommentsCubit>().itemScrollController,
                  itemPositionsListener:
                      context.read<CommentsCubit>().itemPositionsListener,
                  itemCount: state.comments.length + 2,
                  padding: EdgeInsets.only(top: topPadding),
                  scrollOffsetListener: scrollOffsetListener,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      return _ParentItemSection(
                        commentEditingController: commentEditingController,
                        state: state,
                        authState: authState,
                        topPadding: topPadding,
                        splitViewEnabled: splitViewEnabled,
                        onMoreTapped: onMoreTapped,
                        onRightMoreTapped: onRightMoreTapped,
                      );
                    } else if (index == state.comments.length + 1) {
                      if ((state.status == CommentsStatus.allLoaded &&
                              state.comments.isNotEmpty) ||
                          state.onlyShowTargetComment) {
                        return SizedBox(
                          height: _trailingBoxHeight,
                          child: Center(
                            child: Text(Constants.happyFace),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    }

                    index = index - 1;
                    final Comment comment = state.comments.elementAt(index);

                    return FadeIn(
                      key: ValueKey<String>('${comment.id}-FadeIn'),
                      child: CommentTile(
                        comment: comment,
                        index: index,
                        level: comment.level,
                        opUsername: state.item.by,
                        fetchMode: state.fetchMode,
                        isResponse: state.isResponse(comment),
                        isNew: shouldMarkNewComment && !comment.isFromCache,
                        onReplyTapped: (Comment cmt) {
                          HapticFeedbackUtil.light();
                          if (cmt.deleted || cmt.dead) {
                            return;
                          }

                          if (cmt.id !=
                              context.read<EditCubit>().state.replyingTo?.id) {
                            commentEditingController.clear();
                          }

                          context.read<EditCubit>().onReplyTapped(cmt);
                        },
                        onEditTapped: (Comment cmt) {
                          HapticFeedbackUtil.light();
                          if (cmt.deleted || cmt.dead) {
                            return;
                          }
                          commentEditingController.clear();
                          context.read<EditCubit>().onEditTapped(cmt);
                        },
                        onMoreTapped: onMoreTapped,
                        onRightMoreTapped: onRightMoreTapped,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
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
}

class _ParentItemSection extends StatelessWidget {
  const _ParentItemSection({
    required this.commentEditingController,
    required this.state,
    required this.authState,
    required this.topPadding,
    required this.splitViewEnabled,
    required this.onMoreTapped,
    required this.onRightMoreTapped,
  });

  final TextEditingController commentEditingController;
  final CommentsState state;
  final AuthState authState;
  final double topPadding;
  final bool splitViewEnabled;
  final void Function(Item item, Rect? rect) onMoreTapped;
  final ValueChanged<Comment> onRightMoreTapped;

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
                  SlidableAction(
                    onPressed: (_) {
                      HapticFeedbackUtil.light();

                      if (item.id !=
                          context.read<EditCubit>().state.replyingTo?.id) {
                        commentEditingController.clear();
                      }
                      context.read<EditCubit>().onReplyTapped(item);
                    },
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    icon: Icons.message,
                  ),
                  SlidableAction(
                    onPressed: (BuildContext context) =>
                        onMoreTapped(item, context.rect),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    icon: Icons.more_horiz,
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
                          item.timeAgo,
                          style: const TextStyle(
                            color: Palette.grey,
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
                              onTap: () => LinkUtil.launch(
                                item.url,
                                context,
                                useReader: context
                                    .read<PreferenceCubit>()
                                    .state
                                    .readerEnabled,
                                offlineReading: context
                                    .read<StoriesBloc>()
                                    .state
                                    .isOfflineReading,
                              ),
                              onLongPress: () {
                                if (item.url.isNotEmpty) {
                                  FlutterClipboard.copy(item.url)
                                      .whenComplete(() {
                                    HapticFeedbackUtil.selection();
                                    context.showSnackBar(
                                      content: 'Link copied.',
                                    );
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
                  if (item is Story && item.isPoll)
                    BlocProvider<PollCubit>(
                      create: (BuildContext context) =>
                          PollCubit(story: item)..init(),
                      child: const PollView(),
                    ),
                ],
              ),
            ),
          ),
          if (item.text.isNotEmpty)
            const SizedBox(
              height: Dimens.pt8,
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
          ],
        ],
      ),
    );
  }
}
