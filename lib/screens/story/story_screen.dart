import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:url_launcher/url_launcher.dart';

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

    scrollController.addListener(() {
      //focusNode.unfocus();
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
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav
                              ? Colors.orange
                              : Theme.of(context).iconTheme.color,
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
                        icon: const Icon(
                          Icons.stream,
                        ),
                        onPressed: () {
                          final url = Uri.encodeFull(
                              'https://news.ycombinator.com/item?id=${widget.story.id}');
                          canLaunch(url).then((val) {
                            if (val) {
                              launch(url);
                            }
                          });
                        },
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
                                      onTap: () {
                                        final url =
                                            Uri.encodeFull(widget.story.url);
                                        canLaunch(url).then((val) {
                                          if (val) {
                                            launch(url);
                                          }
                                        });
                                      },
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
                                        onLinkTap: (link, _, __, ___) {
                                          final url =
                                              Uri.encodeFull(link ?? '');
                                          canLaunch(url).then((val) {
                                            if (val) {
                                              launch(url);
                                            }
                                          });
                                        },
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
                                (e) => CommentTile(
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
                                        maxLines: 5,
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
                          'Something went wrong...$sadFace',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
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
                              final username = usernameController.text;
                              final password = passwordController.text;
                              if (username.isNotEmpty && password.isNotEmpty) {
                                context.read<AuthBloc>().add(AuthLogin(
                                      username: username,
                                      password: password,
                                    ));
                              }
                            },
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(Colors.orange),
                            ),
                            child: const Text(
                              'Log in',
                              style: TextStyle(fontWeight: FontWeight.bold),
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
