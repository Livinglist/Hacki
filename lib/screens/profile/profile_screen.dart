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
import 'package:hacki/main.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/profile/widgets/widgets.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/utils/utils.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

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
  final refreshControllerHistory = RefreshController();
  final refreshControllerFav = RefreshController();
  final refreshControllerNotification = RefreshController();
  final scrollController = ScrollController();

  _PageType pageType = _PageType.notification;

  final magicWords = <String>[
    'to be a lord.',
    'to conquer the world.',
    'to be over the rainbow!',
    'to bless humanity with long-lasting peace.',
    'to save the world',
    'to infinity and beyond!',
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final magicWord = (magicWords..shuffle()).first;
    return BlocBuilder<PreferenceCubit, PreferenceState>(
      builder: (context, preferenceState) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            return BlocConsumer<NotificationCubit, NotificationState>(
              listenWhen: (previous, current) =>
                  previous.status != current.status,
              listener: (context, notificationState) {
                if (notificationState.status == NotificationStatus.loaded) {
                  refreshControllerNotification
                    ..refreshCompleted()
                    ..loadComplete();
                }
              },
              builder: (context, notificationState) {
                return Stack(
                  children: [
                    Positioned.fill(
                      top: 50,
                      child: Offstage(
                        offstage: pageType != _PageType.history,
                        child: BlocConsumer<HistoryCubit, HistoryState>(
                          listener: (context, historyState) {
                            if (historyState.status == HistoryStatus.loaded) {
                              refreshControllerHistory
                                ..refreshCompleted()
                                ..loadComplete();
                            }
                          },
                          builder: (context, historyState) {
                            if (!authState.isLoggedIn ||
                                historyState.submittedItems.isEmpty) {
                              return const _CenteredMessageView(
                                content: 'Your past comments and stories will '
                                    'show up here.',
                              );
                            }

                            return ItemsListView<Item>(
                              showWebPreview: false,
                              refreshController: refreshControllerHistory,
                              items: historyState.submittedItems
                                  .where((e) => !e.dead && !e.deleted)
                                  .toList(),
                              onRefresh: () {
                                HapticFeedback.lightImpact();
                                context.read<HistoryCubit>().refresh();
                              },
                              onLoadMore: () {
                                context.read<HistoryCubit>().loadMore();
                              },
                              onTap: (item) {
                                if (item is Story) {
                                  HackiApp.navigatorKey.currentState!.pushNamed(
                                      StoryScreen.routeName,
                                      arguments: StoryScreenArgs(story: item));
                                } else if (item is Comment) {
                                  locator
                                      .get<StoriesRepository>()
                                      .fetchParentStory(id: item.parent)
                                      .then((story) {
                                    if (story != null && mounted) {
                                      HackiApp.navigatorKey.currentState!
                                          .pushNamed(StoryScreen.routeName,
                                              arguments: StoryScreenArgs(
                                                  story: story));
                                    }
                                  });
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned.fill(
                      top: 50,
                      child: Offstage(
                        offstage: pageType != _PageType.fav,
                        child: BlocConsumer<FavCubit, FavState>(
                          listener: (context, favState) {
                            if (favState.status == FavStatus.loaded) {
                              refreshControllerFav
                                ..refreshCompleted()
                                ..loadComplete();
                            }
                          },
                          builder: (context, favState) {
                            if (favState.favStories.isEmpty) {
                              return const _CenteredMessageView(
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
                              onTap: (story) {
                                HackiApp.navigatorKey.currentState!.pushNamed(
                                    StoryScreen.routeName,
                                    arguments: StoryScreenArgs(story: story));
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned.fill(
                      top: 50,
                      child: Offstage(
                        offstage: pageType != _PageType.search,
                        child: const SearchScreen(),
                      ),
                    ),
                    Positioned.fill(
                      top: 50,
                      child: Offstage(
                        offstage: pageType != _PageType.notification,
                        child: InboxView(
                          refreshController: refreshControllerNotification,
                          unreadCommentsIds:
                              notificationState.unreadCommentsIds,
                          comments: notificationState.comments,
                          onCommentTapped: (comment) {
                            locator
                                .get<StoriesRepository>()
                                .fetchParentStory(id: comment.parent)
                                .then((story) {
                              if (story != null && mounted) {
                                context
                                    .read<NotificationCubit>()
                                    .markAsRead(comment);
                                HackiApp.navigatorKey.currentState!.pushNamed(
                                  StoryScreen.routeName,
                                  arguments: StoryScreenArgs(
                                    story: story,
                                  ),
                                );
                              }
                            });
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
                    Positioned.fill(
                      top: 50,
                      child: Offstage(
                        offstage: pageType != _PageType.settings,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(authState.isLoggedIn
                                    ? 'Log Out'
                                    : 'Log In'),
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
                              SwitchListTile(
                                title: const Text('Notification on New Reply'),
                                subtitle: const Text(
                                  'Hacki scans for new replies to your 15 '
                                  'most recent comments or stories '
                                  'every 1 minute while the app is '
                                  'running in the foreground.',
                                ),
                                value: preferenceState.showNotification,
                                onChanged: (val) {
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
                                    'show web preview in story tile.'),
                                value: preferenceState.showComplexStoryTile,
                                onChanged: (val) {
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
                                    ' on story.'),
                                value: preferenceState.showWebFirst,
                                onChanged: (val) {
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
                                      ' when it is available.'),
                                  value: preferenceState.useReader,
                                  onChanged: (val) {
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
                                    'grey out stories you have read.'),
                                value: preferenceState.markReadStories,
                                onChanged: (val) {
                                  HapticFeedback.lightImpact();
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
                                onChanged: (val) {
                                  HapticFeedback.lightImpact();
                                  context
                                      .read<PreferenceCubit>()
                                      .toggleEyeCandyMode();

                                  final inAppReview = InAppReview.instance;
                                  inAppReview.isAvailable().then((available) {
                                    if (available) {
                                      inAppReview.requestReview();
                                    }
                                  });
                                },
                                activeColor: Colors.orange,
                              ),
                              SwitchListTile(
                                title: const Text('True Dark Mode'),
                                subtitle: const Text('real dark.'),
                                value: preferenceState.useTrueDark,
                                onChanged: (val) {
                                  HapticFeedback.lightImpact();
                                  context
                                      .read<PreferenceCubit>()
                                      .toggleTrueDarkMode();

                                  final inAppReview = InAppReview.instance;
                                  inAppReview.isAvailable().then((available) {
                                    if (available) {
                                      inAppReview.requestReview();
                                    }
                                  });
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
                                    useTrueDarkMode:
                                        preferenceState.useTrueDark),
                              ),
                              ListTile(
                                title: const Text('About'),
                                subtitle:
                                    const Text('nothing interesting here.'),
                                onTap: () {
                                  showAboutDialog(
                                    context: context,
                                    applicationName: 'Hacki',
                                    applicationVersion: 'v0.1.8',
                                    applicationIcon: Image.asset(
                                      Constants.hackiIconPath,
                                      height: 50,
                                      width: 50,
                                    ),
                                    children: [
                                      ElevatedButton(
                                        onPressed: () => LinkUtil.launchUrl(
                                            'https://livinglist.github.io'),
                                        child: Row(
                                          children: const [
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
                                            'https://github.com/Livinglist/Hacki'),
                                        child: Row(
                                          children: const [
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
                          children: [
                            const SizedBox(
                              width: 12,
                            ),
                            CustomChip(
                              label: 'Submit',
                              selected: false,
                              onSelected: (val) {
                                if (authState.isLoggedIn) {
                                  HackiApp.navigatorKey.currentState
                                      ?.pushNamed(SubmitScreen.routeName);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                        'You need to log in first.',
                                      ),
                                      backgroundColor: Colors.orange,
                                      action: SnackBarAction(
                                        label: 'Log in',
                                        textColor: Colors.black,
                                        onPressed: onLoginTapped,
                                      ),
                                    ),
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
                              onSelected: (val) {
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
                              onSelected: (val) {
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
                              onSelected: (val) {
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
                              onSelected: (val) {
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
                              onSelected: (val) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Can't choose theme when using true dark mode."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    showDialog<void>(
        context: context,
        builder: (_) {
          final themeMode = AdaptiveTheme.of(context).mode;
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile(
                  value: AdaptiveThemeMode.light,
                  groupValue: themeMode,
                  onChanged: (val) => AdaptiveTheme.of(context).setLight(),
                  title: const Text('Light'),
                ),
                RadioListTile(
                  value: AdaptiveThemeMode.dark,
                  groupValue: themeMode,
                  onChanged: (val) => AdaptiveTheme.of(context).setDark(),
                  title: const Text('Dark'),
                ),
                RadioListTile(
                  value: AdaptiveThemeMode.system,
                  groupValue: themeMode,
                  onChanged: (val) => AdaptiveTheme.of(context).setSystem(),
                  title: const Text('System'),
                ),
              ],
            ),
          );
        });
  }

  void onLoginTapped() {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state.isLoggedIn) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged in successfully!'),
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

  void onLogoutTapped() {
    final authBloc = context.read<AuthBloc>();

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return SimpleDialog(
          children: [
            ...[
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

class _CenteredMessageView extends StatelessWidget {
  const _CenteredMessageView({
    Key? key,
    required this.content,
  }) : super(key: key);

  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 120,
        left: 40,
        right: 40,
      ),
      child: Text(
        content,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
