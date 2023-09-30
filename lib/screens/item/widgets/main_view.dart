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
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.scrollOffsetListener,
    required this.commentEditingController,
    required this.authState,
    required this.topPadding,
    required this.splitViewEnabled,
    required this.onMoreTapped,
    required this.onRightMoreTapped,
    super.key,
  });

  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final ScrollOffsetListener scrollOffsetListener;
  final TextEditingController commentEditingController;
  final AuthState authState;
  final double topPadding;
  final bool splitViewEnabled;
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
                  itemScrollController: itemScrollController,
                  itemPositionsListener: itemPositionsListener,
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
                        level: comment.level,
                        opUsername: state.item.by,
                        fetchMode: state.fetchMode,
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
                        itemScrollController: itemScrollController,
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

  static const double _viewParentButtonWidth = 100;
  static const double _viewRootButtonWidth = 80;

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
                    backgroundColor: Palette.orange,
                    foregroundColor: Palette.white,
                    icon: Icons.message,
                  ),
                  SlidableAction(
                    onPressed: (BuildContext context) =>
                        onMoreTapped(item, context.rect),
                    backgroundColor: Palette.orange,
                    foregroundColor: Palette.white,
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
                          style: const TextStyle(
                            color: Palette.orange,
                          ),
                          textScaleFactor:
                              MediaQuery.of(context).textScaleFactor,
                        ),
                        const Spacer(),
                        Text(
                          item.timeAgo,
                          style: const TextStyle(
                            color: Palette.grey,
                          ),
                          textScaleFactor:
                              MediaQuery.of(context).textScaleFactor,
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
                                useReader: context
                                    .read<PreferenceCubit>()
                                    .state
                                    .readerEnabled,
                                offlineReading: context
                                    .read<StoriesBloc>()
                                    .state
                                    .isOfflineReading,
                              ),
                              onLongPress: () => FlutterClipboard.copy(item.url)
                                  .whenComplete(() {
                                HapticFeedbackUtil.selection();
                                context.showSnackBar(
                                  content: 'Link copied.',
                                );
                              }),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: Dimens.pt6,
                                  right: Dimens.pt6,
                                  bottom: Dimens.pt12,
                                  top: Dimens.pt12,
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: fontSize,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                                    ),
                                    children: <TextSpan>[
                                      TextSpan(
                                        semanticsLabel: item.title,
                                        text: item.title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: fontSize,
                                          color: item.url.isNotEmpty
                                              ? Palette.orange
                                              : null,
                                        ),
                                      ),
                                      if (item.url.isNotEmpty)
                                        TextSpan(
                                          text: ''' (${item.readableUrl})''',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: fontSize - 4,
                                            color: Palette.orange,
                                          ),
                                        ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                  textScaleFactor:
                                      MediaQuery.of(context).textScaleFactor,
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
                                    textScaleFactor:
                                        MediaQuery.of(context).textScaleFactor,
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
            Row(
              children: <Widget>[
                if (item is Story) ...<Widget>[
                  const SizedBox(
                    width: Dimens.pt12,
                  ),
                  Text(
                    '''${item.score} karma, ${item.descendants} comment${item.descendants > 1 ? 's' : ''}''',
                    style: const TextStyle(
                      fontSize: TextDimens.pt13,
                    ),
                    textScaleFactor: 1,
                  ),
                ] else ...<Widget>[
                  const SizedBox(
                    width: Dimens.pt4,
                  ),
                  SizedBox(
                    width: _viewParentButtonWidth,
                    child: TextButton(
                      onPressed: context.read<CommentsCubit>().loadParentThread,
                      child:
                          state.fetchParentStatus == CommentsStatus.inProgress
                              ? const SizedBox(
                                  height: Dimens.pt12,
                                  width: Dimens.pt12,
                                  child: CustomCircularProgressIndicator(
                                    strokeWidth: Dimens.pt2,
                                  ),
                                )
                              : const Text(
                                  'View parent',
                                  style: TextStyle(
                                    fontSize: TextDimens.pt13,
                                  ),
                                  textScaleFactor: 1,
                                ),
                    ),
                  ),
                  SizedBox(
                    width: _viewRootButtonWidth,
                    child: TextButton(
                      onPressed: context.read<CommentsCubit>().loadRootThread,
                      child: state.fetchRootStatus == CommentsStatus.inProgress
                          ? const SizedBox(
                              height: Dimens.pt12,
                              width: Dimens.pt12,
                              child: CustomCircularProgressIndicator(
                                strokeWidth: Dimens.pt2,
                              ),
                            )
                          : const Text(
                              'View root',
                              style: TextStyle(
                                fontSize: TextDimens.pt13,
                              ),
                              textScaleFactor: 1,
                            ),
                    ),
                  ),
                ],
                const Spacer(),
                if (!state.isOfflineReading)
                  DropdownButton<FetchMode>(
                    value: state.fetchMode,
                    underline: const SizedBox.shrink(),
                    items: FetchMode.values
                        .map(
                          (FetchMode val) => DropdownMenuItem<FetchMode>(
                            value: val,
                            child: Text(
                              val.description,
                              style: const TextStyle(
                                fontSize: TextDimens.pt13,
                              ),
                              textScaleFactor: 1,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: context.read<CommentsCubit>().onFetchModeChanged,
                  ),
                const SizedBox(
                  width: Dimens.pt6,
                ),
                DropdownButton<CommentsOrder>(
                  value: state.order,
                  underline: const SizedBox.shrink(),
                  items: CommentsOrder.values
                      .map(
                        (CommentsOrder val) => DropdownMenuItem<CommentsOrder>(
                          value: val,
                          child: Text(
                            val.description,
                            style: const TextStyle(
                              fontSize: TextDimens.pt13,
                            ),
                            textScaleFactor: 1,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: context.read<CommentsCubit>().onOrderChanged,
                ),
                const SizedBox(
                  width: Dimens.pt4,
                ),
              ],
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
