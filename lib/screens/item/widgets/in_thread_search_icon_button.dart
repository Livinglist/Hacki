import 'package:animations/animations.dart';
import 'package:collection/collection.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:hacki/blocs/auth/auth_bloc.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/cubits/comments/comments_cubit.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/shine_overlay.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/debouncer.dart';
import 'package:hacki/utils/haptic_feedback_util.dart';

class InThreadSearchIconButton extends StatelessWidget {
  const InThreadSearchIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      closedColor: Palette.transparent,
      openColor: Theme.of(context).canvasColor,
      closedShape: const CircleBorder(),
      closedElevation: Dimens.zero,
      openElevation: Dimens.zero,
      transitionType: ContainerTransitionType.fadeThrough,
      closedBuilder: (BuildContext context, void Function() action) {
        return CustomDescribedFeatureOverlay(
          tapTarget: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          feature: DiscoverableFeature.searchInThread,
          contentLocation: ContentLocation.below,
          child: IconButton(
            tooltip: 'Search in thread',
            icon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: action,
          ),
        );
      },
      openBuilder: (_, void Function({Object? returnValue}) action) =>
          _InThreadSearchView(
        commentsCubit: context.read<CommentsCubit>(),
        action: action,
      ),
    );
  }
}

class _InThreadSearchView extends StatefulWidget {
  const _InThreadSearchView({
    required this.commentsCubit,
    required this.action,
  });

  final CommentsCubit commentsCubit;
  final void Function({Object? returnValue}) action;

  @override
  State<_InThreadSearchView> createState() => _InThreadSearchViewState();
}

class _InThreadSearchViewState extends State<_InThreadSearchView> {
  final ScrollController scrollController = ScrollController();
  final FocusNode focusNode = FocusNode();
  final TextEditingController textEditingController = TextEditingController();
  final Debouncer debouncer = Debouncer(
    delay: AppDurations.oneSecond,
  );

  @override
  void initState() {
    super.initState();
    scrollController.addListener(onScroll);
    textEditingController.text = widget.commentsCubit.state.inThreadSearchQuery;
    Future<void>.delayed(AppDurations.ms300, () {
      if (textEditingController.text.isEmpty) {
        focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    scrollController
      ..removeListener(onScroll)
      ..dispose();
    focusNode.dispose();
    textEditingController.dispose();
    super.dispose();
  }

  void onScroll() => focusNode.unfocus();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CommentsCubit>.value(
      value: widget.commentsCubit,
      child: BlocBuilder<CommentsCubit, CommentsState>(
        buildWhen: (CommentsState previous, CommentsState current) =>
            previous.matchedComments != current.matchedComments ||
            previous.inThreadSearchAuthor != current.inThreadSearchAuthor ||
            previous.inThreadSearchStatus != current.inThreadSearchStatus,
        builder: (BuildContext context, CommentsState state) {
          final AuthState authState = context.read<AuthBloc>().state;
          return Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              backgroundColor: Theme.of(context).canvasColor,
              elevation: Dimens.zero,
              leadingWidth: Dimens.zero,
              leading: const SizedBox.shrink(),
              title: Padding(
                padding: const EdgeInsets.only(bottom: Dimens.pt8),
                child: Flex(
                  direction: Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        cursorColor: Theme.of(context).colorScheme.primary,
                        autocorrect: false,
                        decoration: InputDecoration(
                          hintText: 'Search in this thread',
                          suffixText: '${state.matchedComments.length} results',
                        ),
                        onChanged: (String text) => debouncer.run(
                          () => widget.commentsCubit.search(
                            text,
                            author: state.inThreadSearchAuthor,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      onPressed: widget.action,
                    ),
                  ],
                ),
              ),
            ),
            body: ListView(
              controller: scrollController,
              shrinkWrap: true,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const SizedBox(
                      width: Dimens.pt12,
                    ),
                    CustomChip(
                      selected: state.inThreadSearchAuthor == state.item.by,
                      label: 'by OP',
                      onSelected: (bool value) {
                        if (value) {
                          widget.commentsCubit.search(
                            state.inThreadSearchQuery,
                            author: state.item.by,
                          );
                        } else {
                          widget.commentsCubit.search(
                            state.inThreadSearchQuery,
                          );
                        }
                      },
                    ),
                    if (authState.isLoggedIn) ...<Widget>[
                      const SizedBox(
                        width: Dimens.pt12,
                      ),
                      CustomChip(
                        selected:
                            state.inThreadSearchAuthor == authState.username,
                        label: 'by me',
                        onSelected: (bool value) {
                          if (value) {
                            widget.commentsCubit.search(
                              state.inThreadSearchQuery,
                              author: authState.username,
                            );
                          } else {
                            widget.commentsCubit.search(
                              state.inThreadSearchQuery,
                            );
                          }
                        },
                      ),
                    ],
                    const SizedBox(
                      width: Dimens.pt12,
                    ),
                    CustomChip(
                      selected: false,
                      label: 'clear',
                      onSelected: (_) {
                        HapticFeedbackUtil.selection();
                        if (textEditingController.text.isNotEmpty) {
                          textEditingController.clear();
                          widget.commentsCubit.search(
                            '',
                            author: state.inThreadSearchAuthor,
                          );
                        }
                      },
                    ),
                  ],
                ),
                if (state.matchedComments.isEmpty &&
                    state.inThreadSearchStatus.isSuccessful)
                  FadeIn(
                    child: Center(
                      child: SizedBox(
                        height: Dimens.pt200,
                        child: Center(
                          child: Text(
                            'Nothing found...',
                            style: TextStyle(
                              color: Theme.of(context).disabledColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  for (final Comment comment in state.matchedComments)
                    CommentTile(
                      comment: comment,
                      fetchMode: FetchMode.lazy,
                      isActionable: false,
                      isCollapsable: false,
                      onTap: () async {
                        widget.action();

                        /// Find out the index of the comment in the thread.
                        final Comment? matchedComment =
                            state.comments.singleWhereOrNull(
                          (Comment c) => c.id == comment.id,
                        );
                        if (matchedComment == null) return;
                        final int index =
                            state.comments.indexOf(matchedComment);

                        /// If index if found, scroll to the comment.
                        if (index != -1) {
                          await widget.commentsCubit.scrollTo(
                            index: index + 1,
                            alignment: 0.2,
                          );
                        }

                        /// Then find out the context of the target comment and
                        /// also all of its ancestors, uncollapse them if they
                        /// are collapsed.
                        final GlobalKey<State<StatefulWidget>>?
                            targetCommentGlobalKey =
                            widget.commentsCubit.globalKeys[matchedComment.id];
                        Comment? curComment = matchedComment;
                        while (curComment != null) {
                          if (curComment.isCollapsedByUser) {
                            widget.commentsCubit.uncollapse(curComment);
                          }
                          curComment = state.comments.singleWhereOrNull(
                            (Comment c) => c.id == curComment?.parent,
                          );

                          if (curComment == null) break;
                        }

                        final BuildContext? targetCommentContext =
                            targetCommentGlobalKey?.currentContext;

                        /// After uncollapsing all the ancestors,
                        /// once again, ensure the target comment is visible.
                        /// Then create a shine effect on the widget to
                        /// briefly highlight the target comment tile.
                        if (targetCommentContext != null) {
                          /// If there is a comment context, then use the
                          /// `ensureVisible` to bring it into view.
                          if (targetCommentContext.mounted) {
                            await Scrollable.ensureVisible(
                              targetCommentContext,
                              alignment: 0.3,
                              duration: AppDurations.ms300,
                            );

                            Future<void>.delayed(AppDurations.ms400, () {
                              if (targetCommentGlobalKey != null &&
                                  targetCommentContext.mounted) {
                                _startShine(
                                  targetCommentContext,
                                  targetCommentGlobalKey,
                                );
                              }
                            });
                          }
                        }
                      },
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Rect? _getWidgetRect(GlobalKey targetGlobalKey) {
    final RenderBox? renderBox =
        targetGlobalKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    return offset & size;
  }

  static void _startShine(
    BuildContext targetContext,
    GlobalKey targetGlobalKey,
  ) {
    final Rect? rect = _getWidgetRect(targetGlobalKey);
    if (rect == null) return;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => ShineOverlay(
        rect: rect,
        onDone: () => entry.remove(),
      ),
    );

    Overlay.of(targetContext).insert(entry);
  }
}
