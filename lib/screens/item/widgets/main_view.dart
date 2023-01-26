import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
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
import 'package:pull_to_refresh/pull_to_refresh.dart';

class MainView extends StatelessWidget {
  const MainView({
    super.key,
    required this.scrollController,
    required this.refreshController,
    required this.commentEditingController,
    required this.authState,
    required this.focusNode,
    required this.topPadding,
    required this.splitViewEnabled,
    required this.onMoreTapped,
    required this.onStoryLinkTapped,
    required this.onLoginTapped,
    required this.onRightMoreTapped,
  });

  final ScrollController scrollController;
  final RefreshController refreshController;
  final TextEditingController commentEditingController;
  final AuthState authState;
  final FocusNode focusNode;
  final double topPadding;
  final bool splitViewEnabled;
  final void Function(Item item, Rect? rect) onMoreTapped;
  final ValueChanged<String> onStoryLinkTapped;
  final VoidCallback onLoginTapped;
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
              return SmartRefresher(
                scrollController: scrollController,
                enablePullUp: !state.onlyShowTargetComment,
                enablePullDown: !state.onlyShowTargetComment,
                header: WaterDropMaterialHeader(
                  backgroundColor: Palette.orange,
                  offset: topPadding,
                ),
                footer: CustomFooter(
                  loadStyle: LoadStyle.ShowWhenLoading,
                  builder: (BuildContext context, LoadStatus? mode) {
                    const double height = 55;
                    late final Widget body;

                    if (mode == LoadStatus.idle) {
                      body = const Text('');
                    } else if (mode == LoadStatus.loading) {
                      body = const Text('');
                    } else if (mode == LoadStatus.failed) {
                      body = const Text(
                        '',
                      );
                    } else if (mode == LoadStatus.canLoading) {
                      body = const Text(
                        '',
                      );
                    } else {
                      body = const Text('');
                    }
                    return SizedBox(
                      height: height,
                      child: Center(child: body),
                    );
                  },
                ),
                controller: refreshController,
                onRefresh: () {
                  HapticFeedback.lightImpact();

                  if (context.read<StoriesBloc>().state.offlineReading) {
                    refreshController.refreshCompleted();
                  } else {
                    context.read<CommentsCubit>().refresh();

                    if (state.item.isPoll) {
                      context.read<PollCubit>().refresh();
                    }
                  }
                },
                onLoading: () {
                  if (state.fetchMode == FetchMode.eager) {
                    context.read<CommentsCubit>().loadMore();
                  } else {
                    refreshController.loadComplete();
                  }
                },
                child: ListView.builder(
                  primary: false,
                  itemCount: state.comments.length + 2,
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 0) {
                      return _ParentItemSection(
                        scrollController: scrollController,
                        refreshController: refreshController,
                        commentEditingController: commentEditingController,
                        state: state,
                        authState: authState,
                        focusNode: focusNode,
                        topPadding: topPadding,
                        splitViewEnabled: splitViewEnabled,
                        onMoreTapped: onMoreTapped,
                        onStoryLinkTapped: onStoryLinkTapped,
                        onLoginTapped: onLoginTapped,
                        onRightMoreTapped: onRightMoreTapped,
                      );
                    } else if (index == state.comments.length + 1) {
                      if ((state.status == CommentsStatus.allLoaded &&
                              state.comments.isNotEmpty) ||
                          state.onlyShowTargetComment) {
                        return SizedBox(
                          height: _trailingBoxHeight,
                          child: Center(
                            child: Text(Constants.happyFaces.pickRandomly()!),
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
                        myUsername:
                            authState.isLoggedIn ? authState.username : null,
                        opUsername: state.item.by,
                        fetchMode: state.fetchMode,
                        onReplyTapped: (Comment cmt) {
                          HapticFeedback.lightImpact();
                          if (cmt.deleted || cmt.dead) {
                            return;
                          }

                          if (cmt.id !=
                              context.read<EditCubit>().state.replyingTo?.id) {
                            commentEditingController.clear();
                          }

                          context.read<EditCubit>().onReplyTapped(cmt);
                          focusNode.requestFocus();
                        },
                        onEditTapped: (Comment cmt) {
                          HapticFeedback.lightImpact();
                          if (cmt.deleted || cmt.dead) {
                            return;
                          }
                          commentEditingController.clear();
                          context.read<EditCubit>().onEditTapped(cmt);
                          focusNode.requestFocus();
                        },
                        onMoreTapped: onMoreTapped,
                        onStoryLinkTapped: onStoryLinkTapped,
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
                opacity: state.status == CommentsStatus.loading
                    ? NumSwitch.on
                    : NumSwitch.off,
                duration: const Duration(
                  milliseconds: _loadingIndicatorOpacityAnimationDuration,
                ),
                child: const LinearProgressIndicator(),
              );
            },
          ),
        )
      ],
    );
  }
}

class _ParentItemSection extends StatelessWidget {
  const _ParentItemSection({
    required this.scrollController,
    required this.refreshController,
    required this.commentEditingController,
    required this.state,
    required this.authState,
    required this.focusNode,
    required this.topPadding,
    required this.splitViewEnabled,
    required this.onMoreTapped,
    required this.onStoryLinkTapped,
    required this.onLoginTapped,
    required this.onRightMoreTapped,
  });

  final ScrollController scrollController;
  final RefreshController refreshController;
  final TextEditingController commentEditingController;
  final CommentsState state;
  final AuthState authState;
  final FocusNode focusNode;
  final double topPadding;
  final bool splitViewEnabled;
  final void Function(Item item, Rect? rect) onMoreTapped;
  final ValueChanged<String> onStoryLinkTapped;
  final VoidCallback onLoginTapped;
  final ValueChanged<Comment> onRightMoreTapped;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: topPadding,
        ),
        if (!splitViewEnabled)
          const Padding(
            padding: EdgeInsets.only(bottom: Dimens.pt6),
            child: OfflineBanner(),
          ),
        Slidable(
          startActionPane: ActionPane(
            motion: const BehindMotion(),
            children: <Widget>[
              SlidableAction(
                onPressed: (_) {
                  HapticFeedback.lightImpact();

                  if (state.item.id !=
                      context.read<EditCubit>().state.replyingTo?.id) {
                    commentEditingController.clear();
                  }
                  context.read<EditCubit>().onReplyTapped(state.item);
                  focusNode.requestFocus();
                },
                backgroundColor: Palette.orange,
                foregroundColor: Palette.white,
                icon: Icons.message,
              ),
              SlidableAction(
                onPressed: (BuildContext context) =>
                    onMoreTapped(state.item, context.rect),
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
                      state.item.by,
                      style: const TextStyle(
                        color: Palette.orange,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      state.item.postedDate,
                      style: const TextStyle(
                        color: Palette.grey,
                      ),
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
                  return Column(
                    children: <Widget>[
                      if (state.item is Story)
                        InkWell(
                          onTap: () => LinkUtil.launch(
                            state.item.url,
                            useReader:
                                context.read<PreferenceCubit>().state.useReader,
                            offlineReading: context
                                .read<StoriesBloc>()
                                .state
                                .offlineReading,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: Dimens.pt6,
                              right: Dimens.pt6,
                              bottom: Dimens.pt12,
                              top: Dimens.pt12,
                            ),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: MediaQuery.of(
                                        context,
                                      ).textScaleFactor *
                                      prefState.fontSize.fontSize,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: state.item.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: MediaQuery.of(
                                            context,
                                          ).textScaleFactor *
                                          prefState.fontSize.fontSize,
                                      color: state.item.url.isNotEmpty
                                          ? Palette.orange
                                          : null,
                                    ),
                                  ),
                                  if (state.item.url.isNotEmpty)
                                    TextSpan(
                                      text:
                                          ''' (${(state.item as Story).readableUrl})''',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: MediaQuery.of(
                                              context,
                                            ).textScaleFactor *
                                            (prefState.fontSize.fontSize - 4),
                                        color: Palette.orange,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(
                          height: Dimens.pt6,
                        ),
                      if (state.item.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimens.pt10,
                          ),
                          child: SelectableLinkify(
                            text: state.item.text,
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).textScaleFactor *
                                  context
                                      .read<PreferenceCubit>()
                                      .state
                                      .fontSize
                                      .fontSize,
                            ),
                            linkStyle: TextStyle(
                              fontSize: MediaQuery.of(context).textScaleFactor *
                                  context
                                      .read<PreferenceCubit>()
                                      .state
                                      .fontSize
                                      .fontSize,
                              color: Palette.orange,
                            ),
                            onOpen: (LinkableElement link) {
                              if (link.url.isStoryLink) {
                                onStoryLinkTapped(link.url);
                              } else {
                                LinkUtil.launch(link.url);
                              }
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (state.item.isPoll)
                BlocProvider<PollCubit>(
                  create: (BuildContext context) =>
                      PollCubit(story: state.item as Story)..init(),
                  child: PollView(
                    onLoginTapped: onLoginTapped,
                  ),
                ),
            ],
          ),
        ),
        if (state.item.text.isNotEmpty)
          const SizedBox(
            height: Dimens.pt8,
          ),
        const Divider(
          height: Dimens.zero,
        ),
        if (state.onlyShowTargetComment) ...<Widget>[
          Center(
            child: TextButton(
              onPressed: () =>
                  context.read<CommentsCubit>().loadAll(state.item as Story),
              child: const Text('View all comments'),
            ),
          ),
          const Divider(
            height: Dimens.zero,
          ),
        ] else ...<Widget>[
          Row(
            children: <Widget>[
              if (state.item is Story) ...<Widget>[
                const SizedBox(
                  width: Dimens.pt12,
                ),
                Text(
                  '''${state.item.score} karma, ${state.item.descendants} comment${state.item.descendants > 1 ? 's' : ''}''',
                  style: const TextStyle(
                    fontSize: TextDimens.pt13,
                  ),
                ),
              ] else ...<Widget>[
                const SizedBox(
                  width: Dimens.pt4,
                ),
                TextButton(
                  onPressed: context.read<CommentsCubit>().loadParentThread,
                  child: state.fetchParentStatus == CommentsStatus.loading
                      ? const SizedBox(
                          height: Dimens.pt12,
                          width: Dimens.pt12,
                          child: CustomCircularProgressIndicator(
                            strokeWidth: Dimens.pt2,
                          ),
                        )
                      : const Text(
                          'View parent thread',
                          style: TextStyle(
                            fontSize: TextDimens.pt13,
                          ),
                        ),
                ),
              ],
              const Spacer(),
              if (!state.offlineReading)
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
    );
  }
}
