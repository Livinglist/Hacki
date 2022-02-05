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

enum PageType {
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

  PageType pageType = PageType.notification;

  final magicWords = <String>[
    'to be a lord.',
    'to conquer the world.',
    'to be over the rainbow!',
    'to bless humanity with long-lasting peace.',
    'to save the world',
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
                    if (!authState.isLoggedIn && pageType == PageType.history)
                      Positioned.fill(
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 120,
                            ),
                            ElevatedButton(
                              onPressed: onLoginTapped,
                              style: ElevatedButton.styleFrom(
                                  primary: Colors.deepOrange),
                              child: const Text(
                                'Log in',
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          ],
                        ),
                      ),
                    Positioned.fill(
                      top: 50,
                      child: Offstage(
                        offstage: !authState.isLoggedIn ||
                            pageType != PageType.history,
                        child: BlocConsumer<HistoryCubit, HistoryState>(
                          listener: (context, historyState) {
                            if (historyState.status == HistoryStatus.loaded) {
                              refreshControllerHistory
                                ..refreshCompleted()
                                ..loadComplete();
                            }
                          },
                          builder: (context, historyState) {
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
                        offstage: pageType != PageType.fav,
                        child: BlocConsumer<FavCubit, FavState>(
                          listener: (context, favState) {
                            if (favState.status == FavStatus.loaded) {
                              refreshControllerFav
                                ..refreshCompleted()
                                ..loadComplete();
                            }
                          },
                          builder: (context, favState) {
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
                        offstage: pageType != PageType.search,
                        child: const SearchScreen(),
                      ),
                    ),
                    Positioned.fill(
                      top: 50,
                      child: Offstage(
                        offstage: pageType != PageType.notification,
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
                        offstage: pageType != PageType.settings,
                        child: Column(
                          children: [
                            ListTile(
                              title: Text(
                                  authState.isLoggedIn ? 'Log Out' : 'Log In'),
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
                              subtitle:
                                  const Text('show web preview in story tile.'),
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
                              subtitle:
                                  const Text('show web page first after tapping'
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
                            SwitchListTile(
                              title: const Text('Show Comment Outlines'),
                              subtitle: const Text('be nice to your eyes.'),
                              value: preferenceState.showCommentBorder,
                              onChanged: (val) {
                                HapticFeedback.lightImpact();
                                context
                                    .read<PreferenceCubit>()
                                    .toggleCommentBorderMode();
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
                            ListTile(
                              title: const Text('Theme'),
                              onTap: showThemeSettingDialog,
                            ),
                            ListTile(
                              title: const Text('About'),
                              subtitle: const Text('nothing interesting here.'),
                              onTap: () {
                                showAboutDialog(
                                  context: context,
                                  applicationName: 'Hacki',
                                  applicationVersion: 'v0.1.1',
                                  applicationIcon: Image.asset(
                                    'images/hacki_icon.png',
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
                          ],
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
                              label: 'Inbox : '
                                  '${notificationState.unreadCommentsIds.length}',
                              selected: pageType == PageType.notification,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    pageType = PageType.notification;
                                  });
                                }
                              },
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            CustomChip(
                              label: 'Favorite',
                              selected: pageType == PageType.fav,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    pageType = PageType.fav;
                                  });
                                }
                              },
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            CustomChip(
                              label: 'Submitted',
                              selected: pageType == PageType.history,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    pageType = PageType.history;
                                  });
                                }
                              },
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            CustomChip(
                              label: 'Search',
                              selected: pageType == PageType.search,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    pageType = PageType.search;
                                  });
                                }
                              },
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            CustomChip(
                              label: 'Settings',
                              selected: pageType == PageType.settings,
                              onSelected: (val) {
                                if (val) {
                                  setState(() {
                                    pageType = PageType.settings;
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

  void showThemeSettingDialog() {
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
