import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/main.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/profile/models/models.dart';
import 'package:hacki/screens/profile/widgets/widgets.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tuple/tuple.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  final RefreshController refreshControllerHistory = RefreshController();
  final RefreshController refreshControllerFav = RefreshController();
  final RefreshController refreshControllerNotification = RefreshController();
  final ScrollController scrollController = ScrollController();
  final Throttle throttle = Throttle(delay: const Duration(seconds: 2));

  PageType pageType = PageType.notification;

  final List<String> magicWords = <String>[
    'to be a lord.',
    'to conquer the world.',
    'to be over the rainbow!',
    'to bless humanity with long-lasting peace.',
    'to save the world',
    'to infinity and beyond!',
  ];

  @override
  void dispose() {
    super.dispose();
    refreshControllerHistory.dispose();
    refreshControllerFav.dispose();
    refreshControllerNotification.dispose();
    scrollController.dispose();
    throttle.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final String magicWord = (magicWords..shuffle()).first;
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (BuildContext context, AuthState authState) {
        return BlocConsumer<NotificationCubit, NotificationState>(
          listenWhen: (NotificationState previous, NotificationState current) =>
              previous.status != current.status,
          listener:
              (BuildContext context, NotificationState notificationState) {
            if (notificationState.status == NotificationStatus.loaded) {
              refreshControllerNotification
                ..refreshCompleted()
                ..loadComplete();
            }
          },
          builder: (BuildContext context, NotificationState notificationState) {
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  top: Dimens.pt50,
                  child: Visibility(
                    visible: pageType == PageType.history,
                    child: BlocConsumer<HistoryCubit, HistoryState>(
                      listener: (
                        BuildContext context,
                        HistoryState historyState,
                      ) {
                        if (historyState.status == HistoryStatus.loaded) {
                          refreshControllerHistory
                            ..refreshCompleted()
                            ..loadComplete();
                        }
                      },
                      builder: (
                        BuildContext context,
                        HistoryState historyState,
                      ) {
                        if ((!authState.isLoggedIn ||
                                historyState.submittedItems.isEmpty) &&
                            historyState.status != HistoryStatus.loading) {
                          return const CenteredMessageView(
                            content: 'Your past comments and stories will '
                                'show up here.',
                          );
                        }

                        return ItemsListView<Item>(
                          showWebPreview: false,
                          showMetadata: false,
                          showUrl: false,
                          useConsistentFontSize: true,
                          refreshController: refreshControllerHistory,
                          items: historyState.submittedItems
                              .where((Item e) => !e.dead && !e.deleted)
                              .toList(),
                          onRefresh: () {
                            HapticFeedback.lightImpact();
                            context.read<HistoryCubit>().refresh();
                          },
                          onLoadMore: () {
                            context.read<HistoryCubit>().loadMore();
                          },
                          onTap: (Item item) {
                            if (item is Story) {
                              goToItemScreen(
                                args: ItemScreenArgs(item: item),
                              );
                            } else if (item is Comment) {
                              onCommentTapped(item);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
                Positioned.fill(
                  top: Dimens.pt50,
                  child: Visibility(
                    visible: pageType == PageType.fav,
                    child: BlocConsumer<FavCubit, FavState>(
                      listener: (BuildContext context, FavState favState) {
                        if (favState.status == FavStatus.loaded) {
                          refreshControllerFav
                            ..refreshCompleted()
                            ..loadComplete();
                        }
                      },
                      builder: (BuildContext context, FavState favState) {
                        if (favState.favItems.isEmpty &&
                            favState.status != FavStatus.loading) {
                          return const CenteredMessageView(
                            content: 'Your favorite stories will show up here.'
                                '\nThey will be synced to your Hacker '
                                'News account if you are logged in.',
                          );
                        }

                        return BlocBuilder<PreferenceCubit, PreferenceState>(
                          buildWhen: (
                            PreferenceState previous,
                            PreferenceState current,
                          ) =>
                              previous.complexStoryTileEnabled !=
                                  current.complexStoryTileEnabled ||
                              previous.metadataEnabled !=
                                  current.metadataEnabled ||
                              previous.urlEnabled != current.urlEnabled,
                          builder: (
                            BuildContext context,
                            PreferenceState prefState,
                          ) {
                            return ItemsListView<Item>(
                              showWebPreview: prefState.complexStoryTileEnabled,
                              showMetadata: prefState.metadataEnabled,
                              showUrl: prefState.urlEnabled,
                              useCommentTile: true,
                              refreshController: refreshControllerFav,
                              items: favState.favItems,
                              onRefresh: () {
                                HapticFeedback.lightImpact();
                                context.read<FavCubit>().refresh();
                              },
                              onLoadMore: () {
                                context.read<FavCubit>().loadMore();
                              },
                              onTap: (Item item) => goToItemScreen(
                                args: ItemScreenArgs(item: item),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                Positioned.fill(
                  top: Dimens.pt50,
                  child: Visibility(
                    visible: pageType == PageType.search,
                    maintainState: true,
                    child: const SearchScreen(),
                  ),
                ),
                Positioned.fill(
                  top: Dimens.pt50,
                  child: Visibility(
                    visible: pageType == PageType.notification,
                    child: notificationState.comments.isEmpty
                        ? const CenteredMessageView(
                            content: 'New replies to your comments or stories '
                                'will show up here.',
                          )
                        : InboxView(
                            refreshController: refreshControllerNotification,
                            unreadCommentsIds:
                                notificationState.unreadCommentsIds,
                            comments: notificationState.comments,
                            onCommentTapped: (Comment cmt) {
                              onCommentTapped(
                                cmt,
                                then: () {
                                  context
                                      .read<NotificationCubit>()
                                      .markAsRead(cmt.id);
                                },
                              );
                            },
                            onMarkAllAsReadTapped: () {
                              context.read<NotificationCubit>().markAllAsRead();
                            },
                            onLoadMore: () {
                              context.read<NotificationCubit>().loadMore();
                            },
                            onRefresh: () {
                              HapticFeedback.lightImpact();
                              context.read<NotificationCubit>().refresh();
                            },
                          ),
                  ),
                ),
                Settings(
                  authState: authState,
                  magicWord: magicWord,
                  pageType: pageType,
                  onLoginTapped: onLoginTapped,
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: scrollController,
                    child: Row(
                      children: <Widget>[
                        const SizedBox(
                          width: Dimens.pt12,
                        ),
                        if (authState.isLoggedIn) ...<Widget>[
                          CustomChip(
                            label: 'Submit',
                            selected: false,
                            onSelected: (bool val) {
                              if (authState.isLoggedIn) {
                                HackiApp.navigatorKey.currentState
                                    ?.pushNamed(SubmitScreen.routeName);
                              } else {
                                showSnackBar(
                                  content: 'You need to log in first.',
                                  label: 'Log in',
                                  action: onLoginTapped,
                                );
                              }
                            },
                          ),
                          const SizedBox(
                            width: Dimens.pt12,
                          ),
                          CustomChip(
                            label: 'Inbox : '
                                // ignore: lines_longer_than_80_chars
                                '${notificationState.unreadCommentsIds.length}',
                            selected: pageType == PageType.notification,
                            onSelected: (bool val) {
                              if (val) {
                                setState(() {
                                  pageType = PageType.notification;
                                });
                              }
                            },
                          ),
                          const SizedBox(
                            width: Dimens.pt12,
                          ),
                        ],
                        CustomChip(
                          label: 'Favorite',
                          selected: pageType == PageType.fav,
                          onSelected: (bool val) {
                            if (val) {
                              setState(() {
                                pageType = PageType.fav;
                              });
                            }
                          },
                        ),
                        const SizedBox(
                          width: Dimens.pt12,
                        ),
                        if (authState.isLoggedIn) ...<Widget>[
                          CustomChip(
                            label: 'Submitted',
                            selected: pageType == PageType.history,
                            onSelected: (bool val) {
                              if (val) {
                                setState(() {
                                  pageType = PageType.history;
                                });
                              }
                            },
                          ),
                          const SizedBox(
                            width: Dimens.pt12,
                          ),
                        ],
                        CustomChip(
                          label: 'Search',
                          selected: pageType == PageType.search,
                          onSelected: (bool val) {
                            if (val) {
                              setState(() {
                                pageType = PageType.search;
                              });
                            }
                          },
                        ),
                        const SizedBox(
                          width: Dimens.pt12,
                        ),
                        CustomChip(
                          label: 'Settings',
                          selected: pageType == PageType.settings,
                          onSelected: (bool val) {
                            if (val) {
                              setState(() {
                                pageType = PageType.settings;
                              });
                            }
                          },
                        ),
                        const SizedBox(
                          width: Dimens.pt12,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void onCommentTapped(Comment comment, {VoidCallback? then}) {
    throttle.run(() {
      locator
          .get<StoriesRepository>()
          .fetchParentStoryWithComments(id: comment.parent)
          .then((Tuple2<Story, List<Comment>>? tuple) {
        if (tuple != null && mounted) {
          goToItemScreen(
            args: ItemScreenArgs(
              item: tuple.item1,
              targetComments: tuple.item2.isEmpty
                  ? <Comment>[comment]
                  : <Comment>[
                      ...tuple.item2,
                      comment.copyWith(level: tuple.item2.length)
                    ],
              onlyShowTargetComment: true,
            ),
          )?.then((_) => then?.call());
        }
      });
    });
  }

  void onLoginTapped() {
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BlocConsumer<AuthBloc, AuthState>(
          listener: (BuildContext context, AuthState state) {
            if (state.isLoggedIn) {
              Navigator.pop(context);
              showSnackBar(content: 'Logged in successfully!');
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
                        Constants.errorMessage,
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

  @override
  bool get wantKeepAlive => true;
}
