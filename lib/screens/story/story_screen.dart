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
import 'package:hacki/screens/story/widgets/widgets.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:responsive_builder/responsive_builder.dart';

enum _MenuAction {
  upvote,
  downvote,
  block,
  flag,
  cancel,
}

class StoryScreenArgs extends Equatable {
  const StoryScreenArgs({
    required this.story,
    this.onlyShowTargetComment = false,
    this.targetComments,
  });

  final Story story;
  final bool onlyShowTargetComment;
  final List<Comment>? targetComments;

  @override
  List<Object?> get props => <Object?>[
        story,
        onlyShowTargetComment,
        targetComments,
      ];
}

class StoryScreen extends StatefulWidget {
  const StoryScreen({
    super.key,
    this.splitViewEnabled = false,
    required this.story,
    required this.parentComments,
  });

  static const String routeName = '/story';

  static Route<dynamic> route(StoryScreenArgs args) {
    return MaterialPageRoute<StoryScreen>(
      settings: const RouteSettings(name: routeName),
      builder: (BuildContext context) => MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<CommentsCubit>(
            create: (_) => CommentsCubit(
              offlineReading: context.read<StoriesBloc>().state.offlineReading,
              story: args.story,
            )..init(
                onlyShowTargetComment: args.onlyShowTargetComment,
                targetParents: args.targetComments,
              ),
          ),
          if (args.story.isPoll)
            BlocProvider<PollCubit>(
              create: (BuildContext context) =>
                  PollCubit()..init(story: args.story),
            ),
        ],
        child: StoryScreen(
          story: args.story,
          parentComments: args.targetComments ?? <Comment>[],
        ),
      ),
    );
  }

  static Widget build(StoryScreenArgs args) {
    return MultiBlocProvider(
      key: ValueKey<StoryScreenArgs>(args),
      providers: <BlocProvider<dynamic>>[
        BlocProvider<CommentsCubit>(
          create: (BuildContext context) => CommentsCubit(
            offlineReading: context.read<StoriesBloc>().state.offlineReading,
            story: args.story,
          )..init(
              onlyShowTargetComment: args.onlyShowTargetComment,
              targetParents: args.targetComments,
            ),
        ),
        if (args.story.isPoll)
          BlocProvider<PollCubit>(
            create: (BuildContext context) =>
                PollCubit()..init(story: args.story),
          ),
      ],
      child: StoryScreen(
        story: args.story,
        parentComments: args.targetComments ?? <Comment>[],
        splitViewEnabled: true,
      ),
    );
  }

  final bool splitViewEnabled;
  final Story story;
  final List<Comment> parentComments;

  @override
  _StoryScreenState createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final TextEditingController commentEditingController =
      TextEditingController();
  final ScrollController scrollController = ScrollController();
  final RefreshController refreshController = RefreshController(
    initialLoadStatus: LoadStatus.idle,
    initialRefreshStatus: RefreshStatus.refreshing,
  );
  final FocusNode focusNode = FocusNode();
  final Throttle throttle = Throttle(delay: const Duration(seconds: 2));
  final String happyFace = Constants.happyFaces.pickRandomly()!;

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
    locator.get<CacheService>().resetComments();
    refreshController.dispose();
    commentEditingController.dispose();
    scrollController.dispose();
    throttle.dispose();
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
                  backgroundColor: Colors.orange,
                  offset: topPadding,
                ),
                footer: CustomFooter(
                  loadStyle: LoadStyle.ShowWhenLoading,
                  builder: (BuildContext context, LoadStatus? mode) {
                    Widget body;
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
                      height: 55,
                      child: Center(child: body),
                    );
                  },
                ),
                controller: refreshController,
                onRefresh: () {
                  HapticFeedback.lightImpact();
                  locator.get<CacheService>().resetComments();
                  context.read<CommentsCubit>().refresh();
                },
                onLoading: () {
                  context.read<CommentsCubit>().loadMore();
                },
                child: ListView(
                  primary: false,
                  children: <Widget>[
                    SizedBox(
                      height: topPadding,
                    ),
                    if (!widget.splitViewEnabled)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: OfflineBanner(),
                      ),
                    Slidable(
                      startActionPane: ActionPane(
                        motion: const BehindMotion(),
                        children: <Widget>[
                          SlidableAction(
                            onPressed: (_) {
                              HapticFeedback.lightImpact();

                              if (widget.story !=
                                  context.read<EditCubit>().state.replyingTo) {
                                commentEditingController.clear();
                              }
                              context
                                  .read<EditCubit>()
                                  .onReplyTapped(widget.story);
                              focusNode.requestFocus();
                            },
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            icon: Icons.message,
                          ),
                          SlidableAction(
                            onPressed: (_) => onMorePressed(widget.story),
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            icon: Icons.more_horiz,
                          ),
                        ],
                      ),
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 6,
                              right: 6,
                            ),
                            child: Row(
                              children: <Widget>[
                                Text(
                                  widget.story.by,
                                  style: const TextStyle(
                                    color: Colors.orange,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  widget.story.postedDate,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => LinkUtil.launchUrl(
                              widget.story.url,
                              useReader: context
                                  .read<PreferenceCubit>()
                                  .state
                                  .useReader,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 6,
                                right: 6,
                                bottom: 12,
                                top: 12,
                              ),
                              child: Text(
                                widget.story.title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: widget.story.url.isNotEmpty
                                      ? Colors.orange
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          if (widget.story.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: SelectableLinkify(
                                text: widget.story.text,
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).textScaleFactor *
                                          15,
                                ),
                                linkStyle: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).textScaleFactor *
                                          15,
                                  color: Colors.orange,
                                ),
                                onOpen: (LinkableElement link) {
                                  if (link.url.contains(
                                    'news.ycombinator.com/item',
                                  )) {
                                    onStoryLinkTapped(link.url);
                                  } else {
                                    LinkUtil.launchUrl(link.url);
                                  }
                                },
                              ),
                            ),
                          if (widget.story.isPoll)
                            PollView(
                              story: widget.story,
                              onLoginTapped: onLoginTapped,
                            ),
                        ],
                      ),
                    ),
                    if (widget.story.text.isNotEmpty)
                      const SizedBox(
                        height: 8,
                      ),
                    const Divider(
                      height: 0,
                    ),
                    if (state.onlyShowTargetComment) ...<Widget>[
                      TextButton(
                        onPressed: () =>
                            context.read<CommentsCubit>().loadAll(widget.story),
                        child: const Text('View all comments'),
                      ),
                      const Divider(
                        height: 0,
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
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                    for (final Comment e in state.comments)
                      FadeIn(
                        child: CommentTile(
                          comment: e,
                          level: e.level,
                          myUsername:
                              authState.isLoggedIn ? authState.username : null,
                          opUsername: widget.story.by,
                          onReplyTapped: (Comment cmt) {
                            HapticFeedback.lightImpact();
                            if (cmt.deleted || cmt.dead) {
                              return;
                            }

                            if (cmt !=
                                context.read<EditCubit>().state.replyingTo) {
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
                          onMoreTapped: onMorePressed,
                          onStoryLinkTapped: onStoryLinkTapped,
                          onTimeMachineActivated: onTimeMachineActivated,
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
                      ),
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
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: CustomAppBar(
                                backgroundColor: Theme.of(context)
                                    .canvasColor
                                    .withOpacity(0.6),
                                story: widget.story,
                                scrollController: scrollController,
                                onBackgroundTap: onFeatureDiscoveryDismissed,
                                onDismiss: onFeatureDiscoveryDismissed,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
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
                          story: widget.story,
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
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    showSnackBar(content: 'Tap on icon to continue');
    return Future<bool>.value(false);
  }

  void onTimeMachineActivated(Comment comment) {
    final Size size = MediaQuery.of(context).size;
    final DeviceScreenType deviceType = getDeviceType(size);
    final double widthFactor =
        deviceType != DeviceScreenType.mobile ? 0.6 : 0.9;
    HapticFeedback.lightImpact();
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return BlocProvider<TimeMachineCubit>.value(
          value: TimeMachineCubit()..activateTimeMachine(comment),
          child: BlocBuilder<TimeMachineCubit, TimeMachineState>(
            builder: (BuildContext context, TimeMachineState state) {
              return Center(
                child: Material(
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  child: SizedBox(
                    height: size.height * 0.8,
                    width: size.width * widthFactor,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      child: Column(
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              const SizedBox(
                                width: 8,
                              ),
                              const Text('Parents:'),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 16,
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
                                    height: 0,
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
    final RegExp regex = RegExp(r'\d+$');
    final String match = regex.stringMatch(link) ?? '';
    final int? id = int.tryParse(match);
    if (id != null) {
      throttle.run(() {
        locator
            .get<StoriesRepository>()
            .fetchParentStory(id: id)
            .then((Story? story) {
          if (mounted) {
            if (story != null) {
              HackiApp.navigatorKey.currentState!.pushNamed(
                StoryScreen.routeName,
                arguments: StoryScreenArgs(story: story),
              );
            } else {}
          }
        });
      });
    } else {
      LinkUtil.launchUrl(link);
    }
  }

  void onMorePressed(Item item) {
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
                height: 300,
                color: Theme.of(context).canvasColor,
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        leading: Icon(
                          FeatherIcons.chevronUp,
                          color: upvoted ? Colors.orange : null,
                        ),
                        title: Text(
                          upvoted ? 'Upvoted' : 'Upvote',
                          style: upvoted
                              ? const TextStyle(color: Colors.orange)
                              : null,
                        ),
                        subtitle:
                            item is Story ? Text(item.score.toString()) : null,
                        onTap: context.read<VoteCubit>().upvote,
                      ),
                      ListTile(
                        leading: Icon(
                          FeatherIcons.chevronDown,
                          color: downvoted ? Colors.orange : null,
                        ),
                        title: Text(
                          downvoted ? 'Downvoted' : 'Downvote',
                          style: downvoted
                              ? const TextStyle(color: Colors.orange)
                              : null,
                        ),
                        onTap: context.read<VoteCubit>().downvote,
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

  void onFlagTapped(Item item) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Flag this comment?'),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                left: 24,
                right: 12,
              ),
              child: Text(
                'Flag this comment posted by ${item.by}?',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: 12,
              ),
              child: ButtonBar(
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colors.deepOrange),
                    ),
                    child: const Text(
                      'Yes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
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
        return SimpleDialog(
          title: Text('${isBlocked ? 'Unblock' : 'Block'} this user?'),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(
                left: 24,
                right: 12,
              ),
              child: Text(
                'Do you want to ${isBlocked ? 'unblock' : 'block'} ${item.by}'
                ' and ${isBlocked ? 'display' : 'hide'} '
                'comments posted by this user?',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: 12,
              ),
              child: ButtonBar(
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colors.deepOrange),
                    ),
                    child: const Text(
                      'Yes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
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
                    height: 36,
                    width: 36,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.orange,
                      ),
                    ),
                  )
                else if (!state.isLoggedIn) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),
                    child: TextField(
                      controller: usernameController,
                      cursorColor: Colors.orange,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: 'Username',
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),
                    child: TextField(
                      controller: passwordController,
                      cursorColor: Colors.orange,
                      obscureText: true,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        hintText: 'Password',
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  if (state.status == AuthStatus.failure)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 18,
                      ),
                      child: Text(
                        'Something went wrong... $sadFace',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
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
                              ? Colors.deepOrange
                              : Colors.grey,
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
                                  onTap: () => LinkUtil.launchUrl(
                                    Constants.endUserAgreementLink,
                                  ),
                                  child: const Text(
                                    'End User Agreement',
                                    style: TextStyle(
                                      color: Colors.deepOrange,
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
                      right: 12,
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
                            style: TextStyle(
                              color: Colors.red,
                            ),
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
                                  ? Colors.deepOrange
                                  : Colors.grey,
                            ),
                          ),
                          child: const Text(
                            'Log in',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
