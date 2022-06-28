// ignore_for_file: comment_references

import 'package:equatable/equatable.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/main.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/item/widgets/widgets.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:share_plus/share_plus.dart';

enum _MenuAction {
  upvote,
  downvote,
  share,
  block,
  flag,
  cancel,
}

class ItemScreenArgs extends Equatable {
  const ItemScreenArgs({
    required this.item,
    this.onlyShowTargetComment = false,
    this.useCommentCache = false,
    this.targetComments,
  });

  final Item item;
  final bool onlyShowTargetComment;
  final List<Comment>? targetComments;

  /// when a user is trying to view a sub-thread from a main thread, we don't
  /// need to fetch comments from [StoryRepository] since we have some, if not
  /// all, comments cached in [CommentCache].
  final bool useCommentCache;

  @override
  List<Object?> get props => <Object?>[
        item,
        onlyShowTargetComment,
        targetComments,
        useCommentCache,
      ];
}

class ItemScreen extends StatefulWidget {
  const ItemScreen({
    super.key,
    this.splitViewEnabled = false,
    required this.item,
    required this.parentComments,
  });

  static const String routeName = '/item';

  static Route<dynamic> route(ItemScreenArgs args) {
    return MaterialPageRoute<ItemScreen>(
      settings: const RouteSettings(name: routeName),
      builder: (BuildContext context) => RepositoryProvider<CollapseCache>(
        create: (BuildContext context) => CollapseCache(),
        lazy: false,
        child: MultiBlocProvider(
          providers: <BlocProvider<dynamic>>[
            BlocProvider<CommentsCubit>(
              create: (BuildContext context) => CommentsCubit(
                offlineReading:
                    context.read<StoriesBloc>().state.offlineReading,
                item: args.item,
                collapseCache: context.read<CollapseCache>(),
              )..init(
                  onlyShowTargetComment: args.onlyShowTargetComment,
                  targetParents: args.targetComments,
                ),
            ),
            BlocProvider<EditCubit>(
              lazy: false,
              create: (BuildContext context) => EditCubit(),
            ),
          ],
          child: ItemScreen(
            item: args.item,
            parentComments: args.targetComments ?? <Comment>[],
          ),
        ),
      ),
    );
  }

  static Widget build(BuildContext context, ItemScreenArgs args) {
    return WillPopScope(
      onWillPop: () async {
        if (context.read<SplitViewCubit>().state.expanded) {
          context.read<SplitViewCubit>().zoom();
          return false;
        } else {
          return true;
        }
      },
      child: RepositoryProvider<CollapseCache>(
        create: (BuildContext context) => CollapseCache(),
        lazy: false,
        child: MultiBlocProvider(
          key: ValueKey<ItemScreenArgs>(args),
          providers: <BlocProvider<dynamic>>[
            BlocProvider<CommentsCubit>(
              create: (BuildContext context) => CommentsCubit(
                offlineReading:
                    context.read<StoriesBloc>().state.offlineReading,
                item: args.item,
                collapseCache: context.read<CollapseCache>(),
              )..init(
                  onlyShowTargetComment: args.onlyShowTargetComment,
                  targetParents: args.targetComments,
                ),
            ),
            BlocProvider<EditCubit>(
              lazy: false,
              create: (BuildContext context) => EditCubit(),
            ),
          ],
          child: ItemScreen(
            item: args.item,
            parentComments: args.targetComments ?? <Comment>[],
            splitViewEnabled: true,
          ),
        ),
      ),
    );
  }

  final bool splitViewEnabled;
  final Item item;
  final List<Comment> parentComments;

  @override
  _ItemScreenState createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  final TextEditingController commentEditingController =
      TextEditingController();
  final ScrollController scrollController = ScrollController();
  final RefreshController refreshController = RefreshController(
    initialLoadStatus: LoadStatus.idle,
    initialRefreshStatus: RefreshStatus.refreshing,
  );
  final FocusNode focusNode = FocusNode();
  final String happyFace = Constants.happyFaces.pickRandomly()!;
  final Throttle storyLinkTapThrottle = Throttle(
    delay: _storyLinkTapThrottleDelay,
  );
  final Throttle featureDiscoveryDismissThrottle = Throttle(
    delay: _featureDiscoveryDismissThrottleDelay,
  );

  static const Duration _storyLinkTapThrottleDelay = Duration(seconds: 2);
  static const Duration _featureDiscoveryDismissThrottleDelay =
      Duration(seconds: 1);

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      FeatureDiscovery.discoverFeatures(
        context,
        const <String>{
          Constants.featurePinToTop,
          Constants.featureAddStoryToFavList,
          Constants.featureOpenStoryInWebView,
        },
      );
    });

    scrollController.addListener(() {
      FocusScope.of(context).requestFocus(FocusNode());
      if (commentEditingController.text.isEmpty) {
        context.read<EditCubit>().onScrolled();
      }
    });
  }

  @override
  void dispose() {
    refreshController.dispose();
    commentEditingController.dispose();
    scrollController.dispose();
    storyLinkTapThrottle.dispose();
    featureDiscoveryDismissThrottle.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding =
        MediaQuery.of(context).padding.top + kToolbarHeight;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return MultiBlocListener(
          listeners: <BlocListener<dynamic, dynamic>>[
            BlocListener<PostCubit, PostState>(
              listener: (BuildContext context, PostState postState) {
                if (postState.status == PostStatus.successful) {
                  final String verb =
                      context.read<EditCubit>().state.replyingTo == null
                          ? 'updated'
                          : 'submitted';
                  final String msg =
                      'Comment $verb! ${Constants.happyFaces.pickRandomly()}';
                  focusNode.unfocus();
                  HapticFeedback.lightImpact();
                  showSnackBar(content: msg);
                  context.read<EditCubit>().onReplySubmittedSuccessfully();
                  context.read<PostCubit>().reset();
                } else if (postState.status == PostStatus.failure) {
                  showSnackBar(
                    content: 'Something went wrong...'
                        '${Constants.sadFaces.pickRandomly()}',
                    label: 'Okay',
                    action: ScaffoldMessenger.of(context).hideCurrentSnackBar,
                  );
                  context.read<PostCubit>().reset();
                }
              },
            ),
          ],
          child: BlocConsumer<CommentsCubit, CommentsState>(
            listenWhen: (CommentsState previous, CommentsState current) =>
                previous.status != current.status,
            listener: (BuildContext context, CommentsState state) {
              if (state.status == CommentsStatus.loaded) {
                refreshController
                  ..refreshCompleted()
                  ..loadComplete();
              }
            },
            builder: (BuildContext context, CommentsState state) {
              final SmartRefresher mainView = SmartRefresher(
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
                onLoading: context.read<CommentsCubit>().loadMore,
                child: ListView(
                  primary: false,
                  children: <Widget>[
                    SizedBox(
                      height: topPadding,
                    ),
                    if (!widget.splitViewEnabled)
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
                                  context
                                      .read<EditCubit>()
                                      .state
                                      .replyingTo
                                      ?.id) {
                                commentEditingController.clear();
                              }
                              context
                                  .read<EditCubit>()
                                  .onReplyTapped(state.item);
                              focusNode.requestFocus();
                            },
                            backgroundColor: Palette.orange,
                            foregroundColor: Palette.white,
                            icon: Icons.message,
                          ),
                          SlidableAction(
                            onPressed: (_) => onMoreTapped(state.item),
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
                          if (state.item is Story)
                            InkWell(
                              onTap: () => LinkUtil.launch(
                                state.item.url,
                                useReader: context
                                    .read<PreferenceCubit>()
                                    .state
                                    .useReader,
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
                                child: Text(
                                  state.item.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: state.item.url.isNotEmpty
                                        ? Palette.orange
                                        : null,
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
                                  fontSize:
                                      MediaQuery.of(context).textScaleFactor *
                                          TextDimens.pt15,
                                ),
                                linkStyle: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).textScaleFactor *
                                          TextDimens.pt15,
                                  color: Palette.orange,
                                ),
                                onOpen: (LinkableElement link) {
                                  if (link.url.contains(
                                    'news.ycombinator.com/item',
                                  )) {
                                    onStoryLinkTapped(link.url);
                                  } else {
                                    LinkUtil.launch(link.url);
                                  }
                                },
                              ),
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
                          onPressed: () => context
                              .read<CommentsCubit>()
                              .loadAll(state.item as Story),
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
                            ),
                          ] else ...<Widget>[
                            const SizedBox(
                              width: Dimens.pt4,
                            ),
                            TextButton(
                              onPressed: context
                                  .read<CommentsCubit>()
                                  .loadParentThread,
                              child: state.fetchParentStatus ==
                                      CommentsStatus.loading
                                  ? const SizedBox(
                                      height: Dimens.pt12,
                                      width: Dimens.pt12,
                                      child: CustomCircularProgressIndicator(
                                        strokeWidth: Dimens.pt2,
                                      ),
                                    )
                                  : const Text('View parent thread'),
                            ),
                          ],
                          const Spacer(),
                          DropdownButton<CommentsOrder>(
                            value: state.order,
                            underline: const SizedBox.shrink(),
                            items: const <DropdownMenuItem<CommentsOrder>>[
                              DropdownMenuItem<CommentsOrder>(
                                value: CommentsOrder.natural,
                                child: Text(
                                  'Natural',
                                  style: TextStyle(
                                    fontSize: TextDimens.pt14,
                                  ),
                                ),
                              ),
                              DropdownMenuItem<CommentsOrder>(
                                value: CommentsOrder.newestFirst,
                                child: Text(
                                  'Newest first',
                                  style: TextStyle(
                                    fontSize: TextDimens.pt14,
                                  ),
                                ),
                              ),
                              DropdownMenuItem<CommentsOrder>(
                                value: CommentsOrder.oldestFirst,
                                child: Text(
                                  'Oldest first',
                                  style: TextStyle(
                                    fontSize: TextDimens.pt14,
                                  ),
                                ),
                              ),
                            ],
                            onChanged:
                                context.read<CommentsCubit>().onOrderChanged,
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
                    for (final Comment comment in state.comments)
                      FadeIn(
                        key: ValueKey<String>('${comment.id}-FadeIn'),
                        child: CommentTile(
                          comment: comment,
                          level: comment.level,
                          myUsername:
                              authState.isLoggedIn ? authState.username : null,
                          opUsername: state.item.by,
                          onReplyTapped: (Comment cmt) {
                            HapticFeedback.lightImpact();
                            if (cmt.deleted || cmt.dead) {
                              return;
                            }

                            if (cmt.id !=
                                context
                                    .read<EditCubit>()
                                    .state
                                    .replyingTo
                                    ?.id) {
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
                      ),
                    if ((state.status == CommentsStatus.allLoaded &&
                            state.comments.isNotEmpty) ||
                        state.onlyShowTargetComment)
                      SizedBox(
                        height: 240,
                        child: Center(
                          child: Text(happyFace),
                        ),
                      )
                  ],
                ),
              );

              return BlocListener<EditCubit, EditState>(
                listenWhen: (EditState previous, EditState current) {
                  return previous.replyingTo != current.replyingTo ||
                      previous.itemBeingEdited != current.itemBeingEdited;
                },
                listener: (BuildContext context, EditState editState) {
                  if (editState.replyingTo != null ||
                      editState.itemBeingEdited != null) {
                    if (editState.text == null) {
                      commentEditingController.clear();
                    } else {
                      final String text = editState.text!;
                      commentEditingController
                        ..text = text
                        ..selection = TextSelection.fromPosition(
                          TextPosition(offset: text.length),
                        );
                    }
                  } else {
                    commentEditingController.clear();
                  }
                },
                child: widget.splitViewEnabled
                    ? Material(
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                              child: mainView,
                            ),
                            BlocBuilder<SplitViewCubit, SplitViewState>(
                              buildWhen: (
                                SplitViewState previous,
                                SplitViewState current,
                              ) =>
                                  previous.expanded != current.expanded,
                              builder: (
                                BuildContext context,
                                SplitViewState state,
                              ) {
                                return Positioned(
                                  top: Dimens.zero,
                                  left: Dimens.zero,
                                  right: Dimens.zero,
                                  child: CustomAppBar(
                                    backgroundColor: Theme.of(context)
                                        .canvasColor
                                        .withOpacity(0.6),
                                    item: widget.item,
                                    scrollController: scrollController,
                                    onBackgroundTap:
                                        onFeatureDiscoveryDismissed,
                                    onDismiss: onFeatureDiscoveryDismissed,
                                    splitViewEnabled: state.enabled,
                                    expanded: state.expanded,
                                    onZoomTap:
                                        context.read<SplitViewCubit>().zoom,
                                  ),
                                );
                              },
                            ),
                            Positioned(
                              bottom: Dimens.zero,
                              left: Dimens.zero,
                              right: Dimens.zero,
                              child: ReplyBox(
                                splitViewEnabled: true,
                                focusNode: focusNode,
                                textEditingController: commentEditingController,
                                onSendTapped: onSendTapped,
                                onCloseTapped: () {
                                  context.read<EditCubit>().onReplyBoxClosed();
                                  commentEditingController.clear();
                                  focusNode.unfocus();
                                },
                                onChanged:
                                    context.read<EditCubit>().onTextChanged,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Scaffold(
                        extendBodyBehindAppBar: true,
                        resizeToAvoidBottomInset: true,
                        appBar: CustomAppBar(
                          backgroundColor:
                              Theme.of(context).canvasColor.withOpacity(0.6),
                          item: widget.item,
                          scrollController: scrollController,
                          onBackgroundTap: onFeatureDiscoveryDismissed,
                          onDismiss: onFeatureDiscoveryDismissed,
                        ),
                        body: mainView,
                        bottomSheet: ReplyBox(
                          focusNode: focusNode,
                          textEditingController: commentEditingController,
                          onSendTapped: onSendTapped,
                          onCloseTapped: () {
                            context.read<EditCubit>().onReplyBoxClosed();
                            commentEditingController.clear();
                            focusNode.unfocus();
                          },
                          onChanged: context.read<EditCubit>().onTextChanged,
                        ),
                      ),
              );
            },
          ),
        );
      },
    );
  }

  Future<bool> onFeatureDiscoveryDismissed() {
    featureDiscoveryDismissThrottle.run(() {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).clearSnackBars();
      showSnackBar(content: 'Tap on icon to continue');
    });
    return Future<bool>.value(false);
  }

  void onRightMoreTapped(Comment comment) {
    const double bottomSheetHeight = 140;

    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: bottomSheetHeight,
          color: Theme.of(context).canvasColor,
          child: Material(
            color: Palette.transparent,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.av_timer),
                  title: const Text('View parents'),
                  onTap: () {
                    Navigator.pop(context);
                    onTimeMachineActivated(comment);
                  },
                  enabled:
                      comment.level > 0 && !(comment.dead || comment.deleted),
                ),
                ListTile(
                  leading: const Icon(Icons.list),
                  title: const Text('View in separate thread'),
                  onTap: () {
                    Navigator.pop(context);
                    goToItemScreen(
                      args: ItemScreenArgs(
                        item: comment,
                        useCommentCache: true,
                      ),
                      forceNewScreen: true,
                    );
                  },
                  enabled: !(comment.dead || comment.deleted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void onTimeMachineActivated(Comment comment) {
    final Size size = MediaQuery.of(context).size;
    final DeviceScreenType deviceType = getDeviceType(size);
    final double widthFactor =
        deviceType != DeviceScreenType.mobile ? 0.6 : 0.9;
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return BlocProvider<TimeMachineCubit>.value(
          value: TimeMachineCubit()..activateTimeMachine(comment),
          child: BlocBuilder<TimeMachineCubit, TimeMachineState>(
            builder: (BuildContext context, TimeMachineState state) {
              return Center(
                child: Material(
                  color: Theme.of(context).canvasColor,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(
                      Dimens.pt4,
                    ),
                  ),
                  child: SizedBox(
                    height: size.height * 0.8,
                    width: size.width * widthFactor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimens.pt8,
                        vertical: Dimens.pt12,
                      ),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const SizedBox(
                                width: Dimens.pt8,
                              ),
                              const Text('Parents:'),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: Dimens.pt16,
                                ),
                                onPressed: () => Navigator.pop(context),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          Expanded(
                            child: ListView(
                              children: <Widget>[
                                for (final Comment c
                                    in state.parents) ...<Widget>[
                                  CommentTile(
                                    comment: c,
                                    myUsername:
                                        context.read<AuthBloc>().state.username,
                                    onStoryLinkTapped: onStoryLinkTapped,
                                    actionable: false,
                                  ),
                                  const Divider(
                                    height: Dimens.zero,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> onStoryLinkTapped(String link) async {
    final int? id = link.getItemId();
    if (id != null) {
      storyLinkTapThrottle.run(() {
        locator.get<StoriesRepository>().fetchItemBy(id: id).then((Item? item) {
          if (mounted) {
            if (item != null) {
              HackiApp.navigatorKey.currentState!.pushNamed(
                ItemScreen.routeName,
                arguments: ItemScreenArgs(item: item),
              );
            }
          }
        });
      });
    } else {
      LinkUtil.launch(link);
    }
  }

  void onMoreTapped(Item item) {
    HapticFeedback.lightImpact();

    if (item.dead || item.deleted) {
      return;
    }

    final bool isBlocked =
        context.read<BlocklistCubit>().state.blocklist.contains(item.by);
    showModalBottomSheet<_MenuAction>(
      context: context,
      builder: (BuildContext context) {
        return BlocProvider<VoteCubit>(
          create: (BuildContext context) => VoteCubit(
            item: item,
            authBloc: context.read<AuthBloc>(),
          ),
          child: BlocConsumer<VoteCubit, VoteState>(
            listenWhen: (VoteState previous, VoteState current) {
              return previous.status != current.status;
            },
            listener: (BuildContext context, VoteState voteState) {
              if (voteState.status == VoteStatus.submitted) {
                showSnackBar(content: 'Vote submitted successfully.');
              } else if (voteState.status == VoteStatus.canceled) {
                showSnackBar(content: 'Vote canceled.');
              } else if (voteState.status == VoteStatus.failure) {
                showSnackBar(content: 'Something went wrong...');
              } else if (voteState.status ==
                  VoteStatus.failureKarmaBelowThreshold) {
                showSnackBar(
                  content: "You can't downvote because you are karmaly broke.",
                );
              } else if (voteState.status == VoteStatus.failureNotLoggedIn) {
                showSnackBar(
                  content: 'Not logged in, no voting! (;｀O´)o',
                  action: onLoginTapped,
                  label: 'Log in',
                );
              } else if (voteState.status == VoteStatus.failureBeHumble) {
                showSnackBar(content: 'No voting on your own post! (;｀O´)o');
              }

              Navigator.pop(
                context,
                _MenuAction.upvote,
              );
            },
            builder: (BuildContext context, VoteState voteState) {
              final bool upvoted = voteState.vote == Vote.up;
              final bool downvoted = voteState.vote == Vote.down;
              return Container(
                height: item is Comment ? 430 : 450,
                color: Theme.of(context).canvasColor,
                child: Material(
                  color: Palette.transparent,
                  child: Column(
                    children: <Widget>[
                      BlocProvider<UserCubit>(
                        create: (BuildContext context) =>
                            UserCubit()..init(userId: item.by),
                        child: BlocBuilder<UserCubit, UserState>(
                          builder: (BuildContext context, UserState state) {
                            return ListTile(
                              leading: const Icon(
                                Icons.account_circle,
                              ),
                              title: Text(item.by),
                              subtitle: Text(
                                state.user.description,
                              ),
                              onTap: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      AlertDialog(
                                    title: Text('About ${state.user.id}'),
                                    content: state.user.about.isEmpty
                                        ? Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const <Widget>[
                                              Text(
                                                'empty',
                                                style: TextStyle(
                                                  color: Palette.grey,
                                                ),
                                              ),
                                            ],
                                          )
                                        : SelectableLinkify(
                                            text: HtmlUtil.parseHtml(
                                              state.user.about,
                                            ),
                                            linkStyle: const TextStyle(
                                              color: Palette.orange,
                                            ),
                                            onOpen: (LinkableElement link) {
                                              if (link.url.contains(
                                                'news.ycombinator.com/item',
                                              )) {
                                                onStoryLinkTapped
                                                    .call(link.url);
                                              } else {
                                                LinkUtil.launch(link.url);
                                              }
                                            },
                                          ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text(
                                          'Okay',
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      ListTile(
                        leading: Icon(
                          FeatherIcons.chevronUp,
                          color: upvoted ? Palette.orange : null,
                        ),
                        title: Text(
                          upvoted ? 'Upvoted' : 'Upvote',
                          style: upvoted
                              ? const TextStyle(color: Palette.orange)
                              : null,
                        ),
                        subtitle:
                            item is Story ? Text(item.score.toString()) : null,
                        onTap: context.read<VoteCubit>().upvote,
                      ),
                      ListTile(
                        leading: Icon(
                          FeatherIcons.chevronDown,
                          color: downvoted ? Palette.orange : null,
                        ),
                        title: Text(
                          downvoted ? 'Downvoted' : 'Downvote',
                          style: downvoted
                              ? const TextStyle(color: Palette.orange)
                              : null,
                        ),
                        onTap: context.read<VoteCubit>().downvote,
                      ),
                      ListTile(
                        leading: const Icon(FeatherIcons.share),
                        title: const Text(
                          'Share',
                        ),
                        onTap: () => Navigator.pop(
                          context,
                          _MenuAction.share,
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.local_police),
                        title: const Text(
                          'Flag',
                        ),
                        onTap: () => Navigator.pop(
                          context,
                          _MenuAction.flag,
                        ),
                      ),
                      ListTile(
                        leading: Icon(
                          isBlocked ? Icons.visibility : Icons.visibility_off,
                        ),
                        title: Text(
                          isBlocked ? 'Unblock' : 'Block',
                        ),
                        onTap: () => Navigator.pop(
                          context,
                          _MenuAction.block,
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.close),
                        title: const Text(
                          'Cancel',
                        ),
                        onTap: () => Navigator.pop(
                          context,
                          _MenuAction.cancel,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    ).then((_MenuAction? action) {
      if (action != null) {
        switch (action) {
          case _MenuAction.upvote:
            break;
          case _MenuAction.downvote:
            break;
          case _MenuAction.share:
            onShareTapped(item);
            break;
          case _MenuAction.flag:
            onFlagTapped(item);
            break;
          case _MenuAction.block:
            onBlockTapped(item, isBlocked: isBlocked);
            break;
          case _MenuAction.cancel:
            break;
        }
      }
    });
  }

  void onShareTapped(Item item) =>
      Share.share('https://news.ycombinator.com/item?id=${item.id}');

  void onFlagTapped(Item item) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Flag this comment?'),
          content: Text(
            'Flag this comment posted by ${item.by}?',
            style: const TextStyle(
              color: Palette.grey,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Yes',
              ),
            ),
          ],
        );
      },
    ).then((bool? yesTapped) {
      if (yesTapped ?? false) {
        context.read<AuthBloc>().add(AuthFlag(item: item));
        showSnackBar(content: 'Comment flagged!');
      }
    });
  }

  void onBlockTapped(Item item, {required bool isBlocked}) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${isBlocked ? 'Unblock' : 'Block'} this user?'),
          content: Text(
            'Do you want to ${isBlocked ? 'unblock' : 'block'} ${item.by}'
            ' and ${isBlocked ? 'display' : 'hide'} '
            'comments posted by this user?',
            style: const TextStyle(
              color: Palette.grey,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Yes',
              ),
            ),
          ],
        );
      },
    ).then((bool? yesTapped) {
      if (yesTapped ?? false) {
        if (isBlocked) {
          context.read<BlocklistCubit>().removeFromBlocklist(item.by);
        } else {
          context.read<BlocklistCubit>().addToBlocklist(item.by);
        }
        showSnackBar(content: 'User ${isBlocked ? 'unblocked' : 'blocked'}!');
      }
    });
  }

  void onSendTapped() {
    final AuthBloc authBloc = context.read<AuthBloc>();
    final PostCubit postCubit = context.read<PostCubit>();
    final EditState editState = context.read<EditCubit>().state;
    final Item? replyingTo = editState.replyingTo;
    final Item? itemEdited = editState.itemBeingEdited;

    if (authBloc.state.isLoggedIn) {
      final String text = commentEditingController.text;
      if (text.isEmpty) {
        return;
      }

      if (itemEdited != null) {
        postCubit.edit(text: text, id: itemEdited.id);
      } else if (replyingTo != null) {
        postCubit.post(text: text, to: replyingTo.id);
      }
    } else {
      onLoginTapped();
    }
  }

  void onLoginTapped() {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();
    final String? sadFace = Constants.sadFaces.pickRandomly();
    final String? happyFace = Constants.happyFaces.pickRandomly();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BlocConsumer<AuthBloc, AuthState>(
          listener: (BuildContext context, AuthState state) {
            if (state.isLoggedIn) {
              Navigator.pop(context);
              showSnackBar(content: 'Logged in successfully! $happyFace');
            }
          },
          builder: (BuildContext context, AuthState state) {
            return SimpleDialog(
              children: <Widget>[
                if (state.status == AuthStatus.loading)
                  const SizedBox(
                    height: Dimens.pt36,
                    width: Dimens.pt36,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Palette.orange,
                      ),
                    ),
                  )
                else if (!state.isLoggedIn) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimens.pt18,
                    ),
                    child: TextField(
                      controller: usernameController,
                      cursorColor: Palette.orange,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: 'Username',
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Palette.orange),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: Dimens.pt16,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimens.pt18,
                    ),
                    child: TextField(
                      controller: passwordController,
                      cursorColor: Palette.orange,
                      obscureText: true,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: 'Password',
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Palette.orange),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: Dimens.pt16,
                  ),
                  if (state.status == AuthStatus.failure)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: Dimens.pt18,
                      ),
                      child: Text(
                        'Something went wrong... $sadFace',
                        style: const TextStyle(
                          color: Palette.grey,
                          fontSize: TextDimens.pt12,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                          state.agreedToEULA
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: state.agreedToEULA
                              ? Palette.deepOrange
                              : Palette.grey,
                        ),
                        onPressed: () => context
                            .read<AuthBloc>()
                            .add(AuthToggleAgreeToEULA()),
                      ),
                      Text.rich(
                        TextSpan(
                          children: <InlineSpan>[
                            const TextSpan(
                              text: 'I agree to ',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            WidgetSpan(
                              child: Transform.translate(
                                offset: const Offset(0, 1),
                                child: TapDownWrapper(
                                  onTap: () => LinkUtil.launch(
                                    Constants.endUserAgreementLink,
                                  ),
                                  child: const Text(
                                    'End User Agreement',
                                    style: TextStyle(
                                      color: Palette.deepOrange,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      right: Dimens.pt12,
                    ),
                    child: ButtonBar(
                      children: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.read<AuthBloc>().add(AuthInitialize());
                          },
                          child: const Text(
                            'Cancel',
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (state.agreedToEULA) {
                              final String username = usernameController.text;
                              final String password = passwordController.text;
                              if (username.isNotEmpty && password.isNotEmpty) {
                                context.read<AuthBloc>().add(
                                      AuthLogin(
                                        username: username,
                                        password: password,
                                      ),
                                    );
                              }
                            }
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all(
                              state.agreedToEULA
                                  ? Palette.deepOrange
                                  : Palette.grey,
                            ),
                          ),
                          child: const Text(
                            'Log in',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Palette.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
