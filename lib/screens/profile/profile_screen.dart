import 'dart:io';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/main.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/profile/widgets/widgets.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/utils/utils.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:tuple/tuple.dart';

enum _PageType {
  fav,
  history,
  settings,
  search,
  notification,
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

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

  _PageType pageType = _PageType.notification;

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
    return BlocBuilder<PreferenceCubit, PreferenceState>(
      builder: (BuildContext context, PreferenceState preferenceState) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (BuildContext context, AuthState authState) {
            return BlocConsumer<NotificationCubit, NotificationState>(
              listenWhen:
                  (NotificationState previous, NotificationState current) =>
                      previous.status != current.status,
              listener:
                  (BuildContext context, NotificationState notificationState) {
                if (notificationState.status == NotificationStatus.loaded) {
                  refreshControllerNotification
                    ..refreshCompleted()
                    ..loadComplete();
                }
              },
              builder:
                  (BuildContext context, NotificationState notificationState) {
                return Stack(
                  children: <Widget>[
                    Positioned.fill(
                      top: 50,
                      child: Visibility(
                        visible: pageType == _PageType.history,
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
                                  goToStoryScreen(
                                    args: StoryScreenArgs(story: item),
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
                      top: 50,
                      child: Visibility(
                        visible: pageType == _PageType.fav,
                        child: BlocConsumer<FavCubit, FavState>(
                          listener: (BuildContext context, FavState favState) {
                            if (favState.status == FavStatus.loaded) {
                              refreshControllerFav
                                ..refreshCompleted()
                                ..loadComplete();
                            }
                          },
                          builder: (BuildContext context, FavState favState) {
                            if (favState.favStories.isEmpty &&
                                favState.status != FavStatus.loading) {
                              return const CenteredMessageView(
                                content:
                                    'Your favorite stories will show up here.'
                                    '\nThey will be synced to your Hacker '
                                    'News account if you are logged in.',
                              );
                            }
                            return ItemsListView<Story>(
                              showWebPreview:
                                  preferenceState.showComplexStoryTile,
                              refreshController: refreshControllerFav,
                              items: favState.favStories,
                              onRefresh: () {
                                HapticFeedback.lightImpact();
                                context.read<FavCubit>().refresh();
                              },
                              onLoadMore: () {
                                context.read<FavCubit>().loadMore();
                              },
                              onTap: (Story story) => goToStoryScreen(
                                args: StoryScreenArgs(story: story),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned.fill(
                      top: 50,
                      child: Visibility(
                        visible: pageType == _PageType.search,
                        maintainState: true,
                        child: const SearchScreen(),
                      ),
                    ),
                    Positioned.fill(
                      top: 50,
                      child: Visibility(
                        visible: pageType == _PageType.notification,
                        child: notificationState.comments.isEmpty
                            ? const CenteredMessageView(
                                content:
                                    'New replies to your comments or stories '
                                    'will show up here.',
                              )
                            : InboxView(
                                refreshController:
                                    refreshControllerNotification,
                                unreadCommentsIds:
                                    notificationState.unreadCommentsIds,
                                comments: notificationState.comments,
                                onCommentTapped: (Comment cmt) {
                                  onCommentTapped(
                                    cmt,
                                    then: () {
                                      context
                                          .read<NotificationCubit>()
                                          .markAsRead(cmt);
                                    },
                                  );
                                },
                                onMarkAllAsReadTapped: () {
                                  context
                                      .read<NotificationCubit>()
                                      .markAllAsRead();
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
                    Positioned.fill(
                      top: 50,
                      child: Visibility(
                        visible: pageType == _PageType.settings,
                        child: SingleChildScrollView(
                          child: Column(
                            children: <Widget>[
                              ListTile(
                                title: Text(
                                  authState.isLoggedIn ? 'Log Out' : 'Log In',
                                ),
                                subtitle: Text(
                                  authState.isLoggedIn
                                      ? authState.username
                                      : magicWord,
                                ),
                                onTap: () {
                                  if (authState.isLoggedIn) {
                                    onLogoutTapped();
                                  } else {
                                    onLoginTapped();
                                  }
                                },
                              ),
                              const OfflineListTile(),
                              SwitchListTile(
                                title: const Text('Notification on New Reply'),
                                subtitle: const Text(
                                  'Hacki scans for new replies to your 15 '
                                  'most recent comments or stories '
                                  'every 1 minute while the app is '
                                  'running in the foreground.',
                                ),
                                value: preferenceState.showNotification,
                                onChanged: (bool val) {
                                  HapticFeedback.lightImpact();
                                  context
                                      .read<PreferenceCubit>()
                                      .toggleNotificationMode();
                                },
                                activeColor: Colors.orange,
                              ),
                              SwitchListTile(
                                title: const Text('Complex Story Tile'),
                                subtitle: const Text(
                                  'show web preview in story tile.',
                                ),
                                value: preferenceState.showComplexStoryTile,
                                onChanged: (bool val) {
                                  HapticFeedback.lightImpact();
                                  context
                                      .read<PreferenceCubit>()
                                      .toggleDisplayMode();
                                },
                                activeColor: Colors.orange,
                              ),
                              SwitchListTile(
                                title: const Text('Show Web Page First'),
                                subtitle: const Text(
                                  'show web page first after tapping'
                                  ' on story.',
                                ),
                                value: preferenceState.showWebFirst,
                                onChanged: (bool val) {
                                  HapticFeedback.lightImpact();
                                  context
                                      .read<PreferenceCubit>()
                                      .toggleNavigationMode();
                                },
                                activeColor: Colors.orange,
                              ),
                              if (Platform.isIOS)
                                SwitchListTile(
                                  title: const Text('Use Reader'),
                                  subtitle: const Text(
                                    'enter reader mode in Safari directly'
                                    ' when it is available.',
                                  ),
                                  value: preferenceState.useReader,
                                  onChanged: (bool val) {
                                    HapticFeedback.lightImpact();
                                    context
                                        .read<PreferenceCubit>()
                                        .toggleReaderMode();
                                  },
                                  activeColor: Colors.orange,
                                ),
                              SwitchListTile(
                                title: const Text('Mark Read Stories'),
                                subtitle: const Text(
                                  'grey out stories you have read.',
                                ),
                                value: preferenceState.markReadStories,
                                onChanged: (bool val) {
                                  HapticFeedback.lightImpact();

                                  if (!val) {
                                    context
                                        .read<CacheCubit>()
                                        .deleteAllReadStoryIds();
                                  }

                                  context
                                      .read<PreferenceCubit>()
                                      .toggleMarkReadStoriesMode();
                                },
                                activeColor: Colors.orange,
                              ),
                              SwitchListTile(
                                title: const Text('Eye Candy'),
                                subtitle: const Text('some sort of magic.'),
                                value: preferenceState.showEyeCandy,
                                onChanged: (bool val) {
                                  HapticFeedback.lightImpact();
                                  context
                                      .read<PreferenceCubit>()
                                      .toggleEyeCandyMode();
                                },
                                activeColor: Colors.orange,
                              ),
                              SwitchListTile(
                                title: const Text('True Dark Mode'),
                                subtitle: const Text('real dark.'),
                                value: preferenceState.useTrueDark,
                                onChanged: (bool val) {
                                  HapticFeedback.lightImpact();
                                  context
                                      .read<PreferenceCubit>()
                                      .toggleTrueDarkMode();
                                },
                                activeColor: Colors.orange,
                              ),
                              ListTile(
                                title: Text(
                                  'Theme',
                                  style: TextStyle(
                                    decoration: preferenceState.useTrueDark
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                onTap: () => showThemeSettingDialog(
                                  useTrueDarkMode: preferenceState.useTrueDark,
                                ),
                              ),
                              ListTile(
                                title: const Text('About'),
                                subtitle:
                                    const Text('nothing interesting here.'),
                                onTap: () {
                                  showAboutDialog(
                                    context: context,
                                    applicationName: 'Hacki',
                                    applicationVersion: 'v0.2.3',
                                    applicationIcon: Image.asset(
                                      Constants.hackiIconPath,
                                      height: 50,
                                      width: 50,
                                    ),
                                    children: <Widget>[
                                      ElevatedButton(
                                        onPressed: () => LinkUtil.launchUrl(
                                          Constants.portfolioLink,
                                        ),
                                        child: Row(
                                          children: const <Widget>[
                                            Icon(
                                              FontAwesomeIcons.addressCard,
                                            ),
                                            SizedBox(
                                              width: 12,
                                            ),
                                            Text('Developer'),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => LinkUtil.launchUrl(
                                          Constants.githubLink,
                                        ),
                                        child: Row(
                                          children: const <Widget>[
                                            Icon(
                                              FontAwesomeIcons.github,
                                            ),
                                            SizedBox(
                                              width: 12,
                                            ),
                                            Text('Source Code'),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => LinkUtil.launchUrl(
                                          Platform.isIOS
                                              ? Constants.appStoreLink
                                              : Constants.googlePlayLink,
                                        ),
                                        child: Row(
                                          children: const <Widget>[
                                            Icon(
                                              Icons.thumb_up,
                                            ),
                                            SizedBox(
                                              width: 12,
                                            ),
                                            Text('Like the App?'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(
                                height: 48,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: scrollController,
                        child: Row(
                          children: <Widget>[
                            const SizedBox(
                              width: 12,
                            ),
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
                              width: 12,
                            ),
                            CustomChip(
                              label: 'Inbox : '
                                  // ignore: lines_longer_than_80_chars
                                  '${notificationState.unreadCommentsIds.length}',
                              selected: pageType == _PageType.notification,
                              onSelected: (bool val) {
                                if (val) {
                                  setState(() {
                                    pageType = _PageType.notification;
                                  });
                                }
                              },
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            CustomChip(
                              label: 'Favorite',
                              selected: pageType == _PageType.fav,
                              onSelected: (bool val) {
                                if (val) {
                                  setState(() {
                                    pageType = _PageType.fav;
                                  });
                                }
                              },
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            CustomChip(
                              label: 'Submitted',
                              selected: pageType == _PageType.history,
                              onSelected: (bool val) {
                                if (val) {
                                  setState(() {
                                    pageType = _PageType.history;
                                  });
                                }
                              },
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            CustomChip(
                              label: 'Search',
                              selected: pageType == _PageType.search,
                              onSelected: (bool val) {
                                if (val) {
                                  setState(() {
                                    pageType = _PageType.search;
                                  });
                                }
                              },
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            CustomChip(
                              label: 'Settings',
                              selected: pageType == _PageType.settings,
                              onSelected: (bool val) {
                                if (val) {
                                  setState(() {
                                    pageType = _PageType.settings;
                                  });
                                }
                              },
                            ),
                            const SizedBox(
                              width: 12,
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
      },
    );
  }

  void showThemeSettingDialog({bool useTrueDarkMode = false}) {
    if (useTrueDarkMode) {
      showSnackBar(
        content: "Can't choose theme when using true dark mode.",
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) {
        final AdaptiveThemeMode themeMode = AdaptiveTheme.of(context).mode;
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RadioListTile<AdaptiveThemeMode>(
                value: AdaptiveThemeMode.light,
                groupValue: themeMode,
                onChanged: (AdaptiveThemeMode? val) =>
                    AdaptiveTheme.of(context).setLight(),
                title: const Text('Light'),
              ),
              RadioListTile<AdaptiveThemeMode>(
                value: AdaptiveThemeMode.dark,
                groupValue: themeMode,
                onChanged: (AdaptiveThemeMode? val) =>
                    AdaptiveTheme.of(context).setDark(),
                title: const Text('Dark'),
              ),
              RadioListTile<AdaptiveThemeMode>(
                value: AdaptiveThemeMode.system,
                groupValue: themeMode,
                onChanged: (AdaptiveThemeMode? val) =>
                    AdaptiveTheme.of(context).setSystem(),
                title: const Text('System'),
              ),
            ],
          ),
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
          goToStoryScreen(
            args: StoryScreenArgs(
              story: tuple.item1,
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
                    const Padding(
                      padding: EdgeInsets.only(
                        left: 18,
                      ),
                      child: Text(
                        'Something went wrong...',
                        style: TextStyle(
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

  void onLogoutTapped() {
    final AuthBloc authBloc = context.read<AuthBloc>();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleDialog(
          children: <Widget>[
            ...<Widget>[
              const SizedBox(
                height: 16,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                child: Text(
                  'Log out as ${authBloc.state.username}?',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Padding(
                padding: const EdgeInsets.only(
                  right: 12,
                ),
                child: ButtonBar(
                  children: <Widget>[
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
                        Navigator.pop(context);
                        context.read<AuthBloc>().add(AuthLogout());
                        context.read<HistoryCubit>().reset();
                      },
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.deepOrange),
                      ),
                      child: const Text(
                        'Log out',
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
  }

  @override
  bool get wantKeepAlive => true;
}
