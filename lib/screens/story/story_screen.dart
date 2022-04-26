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
  List<Object?> get props => [
        story,
        onlyShowTargetComment,
        targetComments,
      ];
}

class StoryScreen extends StatefulWidget {
  const StoryScreen({
    Key? key,
    this.splitViewEnabled = false,
    required this.story,
    required this.parentComments,
  }) : super(key: key);

  static const String routeName = '/story';

  static Route route(StoryScreenArgs args) {
    return MaterialPageRoute<StoryScreen>(
      settings: const RouteSettings(name: routeName),
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider<CommentsCubit>(
            create: (_) => CommentsCubit<Story>(
              offlineReading: context.read<StoriesBloc>().state.offlineReading,
              item: args.story,
            )..init(
                onlyShowTargetComment: args.onlyShowTargetComment,
                targetParents: args.targetComments,
              ),
          ),
        ],
        child: StoryScreen(
          story: args.story,
          parentComments: args.targetComments ?? [],
        ),
      ),
    );
  }

  static Widget build(StoryScreenArgs args) {
    return MultiBlocProvider(
      key: ValueKey(args),
      providers: [
        BlocProvider<CommentsCubit>(
          create: (context) => CommentsCubit<Story>(
            offlineReading: context.read<StoriesBloc>().state.offlineReading,
            item: args.story,
          )..init(
              onlyShowTargetComment: args.onlyShowTargetComment,
              targetParents: args.targetComments,
            ),
        ),
      ],
      child: StoryScreen(
        story: args.story,
        parentComments: args.targetComments ?? [],
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
  final commentEditingController = TextEditingController();
  final scrollController = ScrollController();
  final refreshController = RefreshController(
    initialLoadStatus: LoadStatus.idle,
    initialRefreshStatus: RefreshStatus.refreshing,
  );
  final focusNode = FocusNode();
  final throttle = Throttle(delay: const Duration(seconds: 2));
  final happyFace = Constants.happyFaces.pickRandomly()!;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_) {
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
    final topPadding =
        MediaQuery.of(context).padding.top.toDouble() + kToolbarHeight;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return MultiBlocListener(
          listeners: [
            BlocListener<TimeMachineCubit, TimeMachineState>(
              listenWhen: (previous, current) => current.parents.isNotEmpty,
              listener: (context, postState) => showTimeMachine(),
            ),
            BlocListener<PostCubit, PostState>(
              listener: (context, postState) {
                if (postState.status == PostStatus.successful) {
                  final verb =
                      context.read<EditCubit>().state.replyingTo == null
                          ? 'updated'
                          : 'submitted';
                  final msg =
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
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == CommentsStatus.loaded) {
                refreshController
                  ..refreshCompleted()
                  ..loadComplete();
              }
            },
            builder: (context, state) {
              final mainView = SmartRefresher(
                scrollController: scrollController,
                enablePullUp: !state.onlyShowTargetComment,
                enablePullDown: !state.onlyShowTargetComment,
                header: WaterDropMaterialHeader(
                  backgroundColor: Colors.orange,
                  offset: topPadding,
                ),
                footer: CustomFooter(
                  loadStyle: LoadStyle.ShowWhenLoading,
                  builder: (context, mode) {
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
                  children: [
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
                        children: [
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
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 6,
                              right: 6,
                            ),
                            child: Row(
                              children: [
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
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                                onOpen: (link) {
                                  if (link.url
                                      .contains('news.ycombinator.com/item')) {
                                    onStoryLinkTapped(link.url);
                                  } else {
                                    LinkUtil.launchUrl(link.url);
                                  }
                                },
                              ),
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
                    if (state.onlyShowTargetComment) ...[
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
                        state.status == CommentsStatus.allLoaded) ...[
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
                    for (final e in state.comments)
                      FadeIn(
                        child: CommentTile(
                          comment: e,
                          level: e.level,
                          myUsername:
                              authState.isLoggedIn ? authState.username : null,
                          opUsername: widget.story.by,
                          onReplyTapped: (cmt) {
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
                          onEditTapped: (cmt) {
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
                listenWhen: (previous, current) {
                  return previous.replyingTo != current.replyingTo ||
                      previous.itemBeingEdited != current.itemBeingEdited;
                },
                listener: (context, editState) {
                  if (editState.replyingTo != null ||
                      editState.itemBeingEdited != null) {
                    if (editState.text == null) {
                      commentEditingController.clear();
                    } else {
                      final text = editState.text!;
                      commentEditingController
                        ..text = text
                        ..selection = TextSelection.fromPosition(
                            TextPosition(offset: text.length));
                    }
                  } else {
                    commentEditingController.clear();
                  }
                },
                child: widget.splitViewEnabled
                    ? Material(
                        child: Stack(
                          children: [
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

  void onTimeMachineActivated(Comment comment) {
    HapticFeedback.lightImpact();
    context.read<TimeMachineCubit>().activateTimeMachine(comment);
  }

  void showTimeMachine() {
    final size = MediaQuery.of(context).size;
    final deviceType = getDeviceType(size);
    final widthFactor = deviceType != DeviceScreenType.mobile ? 0.6 : 0.9;
    showDialog<void>(
      context: context,
      builder: (context) {
        return BlocBuilder<TimeMachineCubit, TimeMachineState>(
          builder: (context, state) {
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
                      children: [
                        Row(
                          children: [
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
                            children: [
                              for (final c in state.parents) ...[
                                CommentTile(
                                  comment: c,
                                  loadKids: false,
                                  myUsername:
                                      context.read<AuthBloc>().state.username,
                                  onStoryLinkTapped: onStoryLinkTapped,
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
        );
      },
    );
  }

  Future<void> onStoryLinkTapped(String link) async {
    final regex = RegExp(r'\d+$');
    final match = regex.stringMatch(link) ?? '';
    final id = int.tryParse(match);
    if (id != null) {
      throttle.run(() {
        locator.get<StoriesRepository>().fetchParentStory(id: id).then((story) {
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

    final isBlocked =
        context.read<BlocklistCubit>().state.blocklist.contains(item.by);
    showModalBottomSheet<_MenuAction>(
        context: context,
        builder: (context) {
          return BlocProvider(
            create: (context) => VoteCubit(
              item: item,
              authBloc: context.read<AuthBloc>(),
            ),
            child: BlocConsumer<VoteCubit, VoteState>(
              listenWhen: (previous, current) {
                return previous.status != current.status;
              },
              listener: (context, voteState) {
                if (voteState.status == VoteStatus.submitted) {
                  showSnackBar(content: 'Vote submitted successfully.');
                } else if (voteState.status == VoteStatus.canceled) {
                  showSnackBar(content: 'Vote canceled.');
                } else if (voteState.status == VoteStatus.failure) {
                  showSnackBar(content: 'Something went wrong...');
                } else if (voteState.status ==
                    VoteStatus.failureKarmaBelowThreshold) {
                  showSnackBar(
                      content:
                          "You can't downvote because you are karmaly broke.");
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
              builder: (context, voteState) {
                final upvoted = voteState.vote == Vote.up;
                final downvoted = voteState.vote == Vote.down;
                return Container(
                  height: 300,
                  color: Theme.of(context).canvasColor,
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
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
                          subtitle: item is Story
                              ? Text(item.score.toString())
                              : null,
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
                          leading: Icon(isBlocked
                              ? Icons.visibility
                              : Icons.visibility_off),
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
        }).then((action) {
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
            onBlockTapped(item, isBlocked);
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
        builder: (context) {
          return SimpleDialog(
            title: const Text('Flag this comment?'),
            children: [
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
                  children: [
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
        }).then((yesTapped) {
      if (yesTapped ?? false) {
        context.read<AuthBloc>().add(AuthFlag(item: item));
        showSnackBar(content: 'Comment flagged!');
      }
    });
  }

  void onBlockTapped(Item item, bool isBlocked) {
    showDialog<bool>(
        context: context,
        builder: (context) {
          return SimpleDialog(
            title: Text('${isBlocked ? 'Unblock' : 'Block'} this user?'),
            children: [
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
                  children: [
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
        }).then((yesTapped) {
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
    final authBloc = context.read<AuthBloc>();
    final postCubit = context.read<PostCubit>();
    final editState = context.read<EditCubit>().state;
    final replyingTo = editState.replyingTo;
    final itemEdited = editState.itemBeingEdited;

    if (authBloc.state.isLoggedIn) {
      final text = commentEditingController.text;
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
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final sadFace = Constants.sadFaces.pickRandomly();
    final happyFace = Constants.happyFaces.pickRandomly();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.isLoggedIn) {
              Navigator.pop(context);
              showSnackBar(content: 'Logged in successfully! $happyFace');
            }
          },
          builder: (context, state) {
            return SimpleDialog(
              children: [
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
                else if (!state.isLoggedIn) ...[
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
                    children: [
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
                          children: [
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
                                      Constants.endUserAgreementLink),
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
                      children: [
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
                              final username = usernameController.text;
                              final password = passwordController.text;
                              if (username.isNotEmpty && password.isNotEmpty) {
                                context.read<AuthBloc>().add(AuthLogin(
                                      username: username,
                                      password: password,
                                    ));
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
