import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

enum _MenuAction { block, flag, cancel }

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
      builder: (context) => BlocProvider<PostCubit>(
        create: (context) => PostCubit(),
        child: BlocProvider<CommentsCubit>(
          create: (_) => CommentsCubit(
            story: args.story,
          ),
          child: StoryScreen(
            story: args.story,
          ),
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
  Item? _replyingTo;
  bool _showReplyBox = false;

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
        setState(() {
          _showReplyBox = false;
          _replyingTo = null;
        });
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
    return BlocConsumer<PostCubit, PostState>(
      listener: (context, postState) {
        if (postState.status == PostStatus.successful) {
          setState(() {
            _replyingTo = null;
            _showReplyBox = false;
          });
          focusNode.unfocus();
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Comment submitted! ${(happyFaces..shuffle()).first}'),
            backgroundColor: Colors.orange,
          ));
          context.read<PostCubit>().reset();
        } else if (postState.status == PostStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Something went wrong...${(sadFaces..shuffle()).first}'),
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
            return BlocBuilder<FavCubit, FavState>(
              builder: (context, favState) {
                final isFav = favState.favIds.contains(widget.story.id);
                return Scaffold(
                  resizeToAvoidBottomInset: true,
                  appBar: AppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    actions: [
                      IconButton(
                        icon: DescribedFeatureOverlay(
                          targetColor: Theme.of(context).primaryColor,
                          tapTarget: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: Colors.white,
                          ),
                          featureId: Constants.featureAddStoryToFavList,
                          title: const Text('Fav a Story'),
                          description: const Text(
                            'Save this article for later.',
                            style: TextStyle(fontSize: 16),
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav
                                ? Colors.orange
                                : Theme.of(context).iconTheme.color,
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          if (isFav) {
                            context.read<FavCubit>().removeFav(widget.story.id);
                          } else {
                            context.read<FavCubit>().addFav(widget.story.id);
                          }
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
                            'You can tap here to open this story in a browser.',
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
                  body: Stack(
                    children: [
                      Positioned.fill(
                        child: SmartRefresher(
                          scrollController: scrollController,
                          enablePullUp: true,
                          header: const WaterDropMaterialHeader(
                            backgroundColor: Colors.orange,
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
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    if (widget.story != _replyingTo) {
                                      commentEditingController.clear();
                                    }
                                    setState(() {
                                      _showReplyBox = true;
                                      _replyingTo = widget.story;
                                    });
                                    focusNode.requestFocus();
                                  });
                                },
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
                                      onTap: () =>
                                          LinkUtil.launchUrl(widget.story.url),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 6,
                                          right: 6,
                                          bottom: 12,
                                          top: 12,
                                        ),
                                        child: Text(
                                          widget.story.title,
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
                                    onTap: (cmt) {
                                      if (cmt != _replyingTo) {
                                        commentEditingController.clear();
                                      }

                                      setState(() {
                                        _showReplyBox = true;
                                        _replyingTo = cmt;
                                      });
                                      focusNode.requestFocus();
                                    },
                                    onLongPress: onLongPressed,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 120,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 70,
                        child: Offstage(
                          offstage: !_showReplyBox,
                          child: Container(
                            decoration: const BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black54,
                                  offset: Offset(0, 20), //(x,y)
                                  blurRadius: 40,
                                ),
                              ],
                            ),
                            child: Material(
                              child: Flex(
                                direction: Axis.horizontal,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                  ),
                                  Flexible(
                                    flex: 9,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: TextField(
                                        focusNode: focusNode,
                                        controller: commentEditingController,
                                        maxLines: 10,
                                        decoration: InputDecoration(
                                          alignLabelWithHint: true,
                                          contentPadding: EdgeInsets.zero,
                                          hintText: _replyingTo == null
                                              ? ''
                                              : 'Replying ${_replyingTo!.by}',
                                          hintStyle: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                          focusedBorder: InputBorder.none,
                                          border: InputBorder.none,
                                        ),
                                        keyboardType: TextInputType.multiline,
                                        textInputAction:
                                            TextInputAction.newline,
                                      ),
                                    ),
                                  ),
                                  if (_replyingTo != null &&
                                      postState.status != PostStatus.loading)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () {
                                        commentEditingController.clear();
                                        setState(() {
                                          _showReplyBox = false;
                                          _replyingTo = null;
                                        });
                                        focusNode.unfocus();
                                      },
                                    ),
                                  if (postState.status == PostStatus.loading)
                                    const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.orange,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    Flexible(
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.send,
                                          color: Colors.orange,
                                        ),
                                        onPressed: onSendTapped,
                                      ),
                                    ),
                                  const SizedBox(
                                    width: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void onLongPressed(Item item) {
    final isBlocked =
        context.read<BlocklistCubit>().state.blocklist.contains(item.by);
    showModalBottomSheet<_MenuAction>(
        context: context,
        builder: (context) {
          return Container(
            height: 180,
            color: Theme.of(context).canvasColor,
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.local_police),
                    title: const Text(
                      'Flag',
                    ),
                    onTap: () => Navigator.pop(context, _MenuAction.flag),
                  ),
                  ListTile(
                    leading: Icon(
                        isBlocked ? Icons.visibility : Icons.visibility_off),
                    title: Text(
                      isBlocked ? 'Unblock' : 'Block',
                    ),
                    onTap: () => Navigator.pop(context, _MenuAction.block),
                  ),
                  ListTile(
                    leading: const Icon(Icons.close),
                    title: const Text(
                      'Cancel',
                    ),
                    onTap: () => Navigator.pop(context, _MenuAction.cancel),
                  ),
                ],
              ),
            ),
          );
        }).then((action) {
      if (action != null) {
        switch (action) {
          case _MenuAction.flag:
            showFlagPopup(item);
            break;
          case _MenuAction.block:
            showBlockPopup(item, isBlocked);
            break;
          case _MenuAction.cancel:
        }
      }
    });
  }

  void showFlagPopup(Item item) {
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

  void showBlockPopup(Item item, bool isBlocked) {
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

    if (authBloc.state.isLoggedIn) {
      final text = commentEditingController.text;
      if (text.isEmpty) {
        return;
      }

      if (_replyingTo != null) {
        postCubit.post(text: text, to: _replyingTo!.id);
      }
    } else {
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
                                if (username.isNotEmpty &&
                                    password.isNotEmpty) {
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
}
