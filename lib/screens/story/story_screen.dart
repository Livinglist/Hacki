import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/main.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/story/widgets/widgets.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

enum _MenuAction {
  upvote,
  downvote,
  block,
  flag,
  cancel,
}

class StoryScreenArgs {
  StoryScreenArgs({required this.story});

  final Story story;
}

class StoryScreen extends StatefulWidget {
  const StoryScreen({Key? key, required this.story}) : super(key: key);

  static const String routeName = '/story';

  static Route route(StoryScreenArgs args) {
    return MaterialPageRoute<StoryScreen>(
      settings: const RouteSettings(name: routeName),
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider<PostCubit>(
            create: (context) => PostCubit(),
          ),
          BlocProvider<CommentsCubit>(
            create: (_) => CommentsCubit<Story>(
              item: args.story,
            ),
          ),
          BlocProvider<EditCubit>(
            create: (context) => EditCubit(),
          ),
        ],
        child: StoryScreen(
          story: args.story,
        ),
      ),
    );
  }

  final Story story;

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
  final sadFaces = <String>[
    'ಥ_ಥ',
    '(╯°□°）╯︵ ┻━┻',
    r'¯\_(ツ)_/¯',
    '( ͡° ͜ʖ ͡°)',
    '(Θ︹Θ)',
    '( ˘︹˘ )',
    '(ㆆ_ㆆ)',
    'ʕ•́ᴥ•̀ʔっ',
    '(ㆆ_ㆆ)',
  ];
  final happyFaces = <String>[
    '(๑•̀ㅂ•́)و✧',
    '( ͡• ͜ʖ ͡•)',
    '( ͡~ ͜ʖ ͡°)',
    '٩(˘◡˘)۶',
    '(─‿‿─)',
    '(¬‿¬)',
  ];

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((_) {
      FeatureDiscovery.discoverFeatures(
        context,
        const <String>{
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding =
        MediaQuery.of(context).padding.top.toDouble() + kToolbarHeight;
    final editCubit = context.read<EditCubit>();
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return BlocConsumer<PostCubit, PostState>(
          listener: (context, postState) {
            if (postState.status == PostStatus.successful) {
              editCubit.onReplySubmittedSuccessfully();
              focusNode.unfocus();
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  'Comment submitted! ${(happyFaces..shuffle()).first}',
                ),
                backgroundColor: Colors.orange,
              ));
              context.read<PostCubit>().reset();
            } else if (postState.status == PostStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  'Something went wrong...${(sadFaces..shuffle()).first}',
                ),
                backgroundColor: Colors.orange,
                action: SnackBarAction(
                    label: 'Okay',
                    onPressed: () =>
                        ScaffoldMessenger.of(context).hideCurrentSnackBar()),
              ));
              context.read<PostCubit>().reset();
            }
          },
          builder: (context, postState) {
            return BlocConsumer<CommentsCubit, CommentsState>(
              listener: (context, state) {
                if (state.status == CommentsStatus.loaded) {
                  refreshController
                    ..refreshCompleted()
                    ..loadComplete();
                }
              },
              builder: (context, state) {
                return BlocConsumer<EditCubit, EditState>(
                  listenWhen: (previous, current) {
                    return previous.replyingTo != current.replyingTo;
                  },
                  listener: (context, editState) {
                    if (editState.replyingTo != null) {
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
                  builder: (context, editState) {
                    final replyingTo = editCubit.state.replyingTo;
                    return Scaffold(
                      extendBodyBehindAppBar: true,
                      resizeToAvoidBottomInset: true,
                      appBar: AppBar(
                        backgroundColor:
                            Theme.of(context).canvasColor.withOpacity(0.6),
                        elevation: 0,
                        actions: [
                          ScrollUpIconButton(
                            scrollController: scrollController,
                          ),
                          BlocBuilder<FavCubit, FavState>(
                            builder: (context, favState) {
                              final isFav =
                                  favState.favIds.contains(widget.story.id);
                              return IconButton(
                                icon: DescribedFeatureOverlay(
                                  targetColor: Theme.of(context).primaryColor,
                                  tapTarget: Icon(
                                    isFav
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: Colors.white,
                                  ),
                                  featureId: Constants.featureAddStoryToFavList,
                                  title: const Text('Fav a Story'),
                                  description: const Text(
                                    'Save this article for later.',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  child: Icon(
                                    isFav
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFav
                                        ? Colors.orange
                                        : Theme.of(context).iconTheme.color,
                                  ),
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  if (isFav) {
                                    context
                                        .read<FavCubit>()
                                        .removeFav(widget.story.id);
                                  } else {
                                    context
                                        .read<FavCubit>()
                                        .addFav(widget.story.id);
                                  }
                                },
                              );
                            },
                          ),
                          IconButton(
                            icon: DescribedFeatureOverlay(
                              targetColor: Theme.of(context).primaryColor,
                              tapTarget: const Icon(
                                Icons.stream,
                                color: Colors.white,
                              ),
                              featureId: Constants.featureOpenStoryInWebView,
                              title: const Text('Open in Browser'),
                              description: const Text(
                                'Want more than just reading and replying? '
                                'You can tap here to open this story in a '
                                'browser.',
                                style: TextStyle(fontSize: 16),
                              ),
                              child: const Icon(
                                Icons.stream,
                              ),
                            ),
                            onPressed: () => LinkUtil.launchUrl(
                                'https://news.ycombinator.com/item?id=${widget.story.id}'),
                          ),
                        ],
                      ),
                      body: SmartRefresher(
                        scrollController: scrollController,
                        enablePullUp: true,
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
                        onLoading: () {},
                        child: ListView(
                          primary: false,
                          children: [
                            SizedBox(
                              height: topPadding,
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (widget.story != replyingTo) {
                                    commentEditingController.clear();
                                  }
                                  editCubit.onItemTapped(widget.story);
                                  focusNode.requestFocus();
                                });
                              },
                              onLongPress: () => onLongPressed(widget.story),
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
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  if (widget.story.text.isNotEmpty)
                                    Html(
                                      data: widget.story.text,
                                      onLinkTap: (link, _, __, ___) =>
                                          LinkUtil.launchUrl(link ?? ''),
                                    ),
                                ],
                              ),
                            ),
                            const Divider(
                              height: 0,
                            ),
                            if (state.comments.isEmpty &&
                                state.status == CommentsStatus.loaded) ...[
                              const SizedBox(
                                height: 240,
                              ),
                              const Center(
                                child: Text(
                                  'Nothing yet',
                                  style: TextStyle(color: Colors.white30),
                                ),
                              ),
                            ],
                            ...state.comments.map(
                              (e) => FadeIn(
                                child: CommentTile(
                                  comment: e,
                                  myUsername: authState.isLoggedIn
                                      ? authState.username
                                      : null,
                                  onTap: (cmt) {
                                    if (cmt.deleted || cmt.dead) {
                                      return;
                                    }

                                    if (cmt != replyingTo) {
                                      commentEditingController.clear();
                                    }

                                    editCubit.onItemTapped(cmt);
                                    focusNode.requestFocus();
                                  },
                                  onLongPress: onLongPressed,
                                  onStoryLinkTapped: (link) {
                                    final regex = RegExp(r'\d+$');
                                    final match = regex.stringMatch(link) ?? '';
                                    final id = int.tryParse(match);
                                    if (id != null) {
                                      locator
                                          .get<StoriesRepository>()
                                          .fetchParentStory(id: id)
                                          .then((story) {
                                        if (mounted) {
                                          if (story != null) {
                                            HackiApp.navigatorKey.currentState!
                                                .pushNamed(
                                              StoryScreen.routeName,
                                              arguments:
                                                  StoryScreenArgs(story: story),
                                            );
                                          } else {}
                                        }
                                      });
                                    } else {
                                      LinkUtil.launchUrl(link);
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 240,
                            ),
                          ],
                        ),
                      ),
                      bottomSheet: Offstage(
                        offstage: !editCubit.state.showReplyBox,
                        child: ReplyBox(
                          focusNode: focusNode,
                          textEditingController: commentEditingController,
                          replyingTo: replyingTo,
                          isLoading: postState.status == PostStatus.loading,
                          onSendTapped: onSendTapped,
                          onCloseTapped: () {
                            editCubit.onReplyBoxClosed();
                            commentEditingController.clear();
                            focusNode.unfocus();
                          },
                          onChanged: editCubit.onTextChanged,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void onLongPressed(Item item) {
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
                    withLoginAction: true,
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Comment flagged!'),
          backgroundColor: Colors.orange,
        ));
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('User ${isBlocked ? 'unblocked' : 'blocked'}!'),
          backgroundColor: Colors.orange,
        ));
      }
    });
  }

  void onSendTapped() {
    final authBloc = context.read<AuthBloc>();
    final postCubit = context.read<PostCubit>();
    final replyingTo = context.read<EditCubit>().state.replyingTo;

    if (authBloc.state.isLoggedIn) {
      final text = commentEditingController.text;
      if (text.isEmpty) {
        return;
      }

      if (replyingTo != null) {
        postCubit.post(text: text, to: replyingTo.id);
      }
    } else {
      onLoginTapped();
    }
  }

  void onLoginTapped() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final sadFace = (sadFaces..shuffle()).first;
    final happyFace = (happyFaces..shuffle()).first;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.isLoggedIn) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Logged in successfully! $happyFace'),
                  backgroundColor: Colors.orange,
                ),
              );
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
                          onPressed: () => Navigator.pop(context),
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

  void showSnackBar({required String content, bool withLoginAction = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          content,
        ),
        backgroundColor: Colors.orange,
        action: withLoginAction
            ? SnackBarAction(
                label: 'Log in',
                textColor: Colors.black,
                onPressed: onLoginTapped,
              )
            : null,
      ),
    );
  }
}
