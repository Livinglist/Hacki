// ignore_for_file: lines_longer_than_80_chars

import 'dart:async';
import 'dart:convert';

import 'package:badges/badges.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/main.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/utils/utils.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:responsive_builder/responsive_builder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/';

  static Route<dynamic> route() {
    return MaterialPageRoute<HomeScreen>(
      settings: const RouteSettings(name: routeName),
      builder: (BuildContext context) => const HomeScreen(),
    );
  }

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  final CacheService cacheService = locator.get<CacheService>();
  final Throttle featureDiscoveryDismissThrottle = Throttle(
    delay: _throttleDelay,
  );

  late final TabController tabController;
  late final StreamSubscription<String> intentDataStreamSubscription;
  late final StreamSubscription<String?> notificationStreamSubscription;

  int currentIndex = 0;

  static const Duration _throttleDelay = Duration(seconds: 1);

  @override
  void didPopNext() {
    if (context.read<StoriesBloc>().deviceScreenType ==
        DeviceScreenType.mobile) {
      cacheService.resetCollapsedComments();
    }
    super.didPopNext();
  }

  @override
  void initState() {
    super.initState();

    // This is for testing only.
    // FeatureDiscovery.clearPreferences(context, <String>[
    //   Constants.featureLogIn,
    //   Constants.featureAddStoryToFavList,
    //   Constants.featureOpenStoryInWebView,
    //   Constants.featurePinToTop,
    // ]);

    ReceiveSharingIntent.getInitialText().then(onShareExtensionTapped);

    intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen(onShareExtensionTapped);

    if (!selectNotificationSubject.hasListener) {
      notificationStreamSubscription =
          selectNotificationSubject.stream.listen(onNotificationTapped);
    }

    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        FeatureDiscovery.discoverFeatures(
          context,
          const <String>{
            Constants.featureLogIn,
          },
        );
      })
      ..addPostFrameCallback((_) {
        final ModalRoute<dynamic>? route = ModalRoute.of(context);

        if (route == null) return;

        locator
            .get<RouteObserver<ModalRoute<dynamic>>>()
            .subscribe(this, route);
      });

    tabController = TabController(vsync: this, length: 6)
      ..addListener(() {
        setState(() {
          currentIndex = tabController.index;
        });
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final DeviceScreenType deviceType =
        getDeviceType(MediaQuery.of(context).size);
    if (context.read<StoriesBloc>().deviceScreenType != deviceType) {
      context.read<StoriesBloc>().deviceScreenType = deviceType;
      context.read<StoriesBloc>().add(StoriesInitialize());
    }
  }

  @override
  void dispose() {
    featureDiscoveryDismissThrottle.dispose();
    tabController.dispose();
    intentDataStreamSubscription.cancel();
    notificationStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BlocBuilder<PreferenceCubit, PreferenceState> homeScreen =
        BlocBuilder<PreferenceCubit, PreferenceState>(
      buildWhen: (PreferenceState previous, PreferenceState current) =>
          previous.showComplexStoryTile != current.showComplexStoryTile ||
          previous.showMetadata != current.showMetadata,
      builder: (BuildContext context, PreferenceState preferenceState) {
        final BlocBuilder<PinCubit, PinState> pinnedStories =
            BlocBuilder<PinCubit, PinState>(
          builder: (BuildContext context, PinState state) {
            return Column(
              children: <Widget>[
                for (final Story story in state.pinnedStories)
                  FadeIn(
                    child: Slidable(
                      startActionPane: ActionPane(
                        motion: const BehindMotion(),
                        children: <Widget>[
                          SlidableAction(
                            onPressed: (_) {
                              HapticFeedback.lightImpact();
                              context.read<PinCubit>().unpinStory(story);
                            },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: preferenceState.showComplexStoryTile
                                ? Icons.close
                                : null,
                            label: 'Unpin',
                          ),
                        ],
                      ),
                      child: Container(
                        color: Colors.orangeAccent.withOpacity(0.2),
                        child: StoryTile(
                          key: ObjectKey(story),
                          story: story,
                          onTap: () => onStoryTapped(story, isPin: true),
                          showWebPreview: preferenceState.showComplexStoryTile,
                          showMetadata: preferenceState.showMetadata,
                        ),
                      ),
                    ),
                  ),
                if (state.pinnedStories.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Divider(
                      color: Colors.orangeAccent,
                    ),
                  ),
              ],
            );
          },
        );

        return DefaultTabController(
          length: 6,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: PreferredSize(
              preferredSize: const Size(0, 40),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: MediaQuery.of(context).padding.top - 8,
                  ),
                  Theme(
                    data: ThemeData(
                      highlightColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      primaryColor: Theme.of(context).primaryColor,
                    ),
                    child: TabBar(
                      isScrollable: true,
                      controller: tabController,
                      indicatorColor: Colors.orange,
                      indicator: CircleTabIndicator(
                        color: Colors.orange,
                        radius: 2,
                      ),
                      indicatorPadding: const EdgeInsets.only(bottom: 8),
                      onTap: (_) {
                        HapticFeedback.selectionClick();
                      },
                      tabs: <Widget>[
                        Tab(
                          child: Text(
                            'TOP',
                            style: TextStyle(
                              fontSize: currentIndex == 0 ? 14 : 10,
                              color: currentIndex == 0
                                  ? Colors.orange
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        Tab(
                          child: Text(
                            'NEW',
                            style: TextStyle(
                              fontSize: currentIndex == 1 ? 14 : 10,
                              color: currentIndex == 1
                                  ? Colors.orange
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        Tab(
                          child: Text(
                            'ASK',
                            style: TextStyle(
                              fontSize: currentIndex == 2 ? 14 : 10,
                              color: currentIndex == 2
                                  ? Colors.orange
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        Tab(
                          child: Text(
                            'SHOW',
                            style: TextStyle(
                              fontSize: currentIndex == 3 ? 14 : 10,
                              color: currentIndex == 3
                                  ? Colors.orange
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        Tab(
                          child: Text(
                            'JOBS',
                            style: TextStyle(
                              fontSize: currentIndex == 4 ? 14 : 10,
                              color: currentIndex == 4
                                  ? Colors.orange
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        Tab(
                          child: DescribedFeatureOverlay(
                            onBackgroundTap: onFeatureDiscoveryDismissed,
                            onDismiss: onFeatureDiscoveryDismissed,
                            onComplete: () async {
                              ScaffoldMessenger.of(context).clearSnackBars();
                              unawaited(HapticFeedback.lightImpact());
                              showOnboarding();
                              return true;
                            },
                            overflowMode: OverflowMode.extendBackground,
                            targetColor: Theme.of(context).primaryColor,
                            tapTarget: const Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.white,
                            ),
                            featureId: Constants.featureLogIn,
                            title: const Text('Log in for more'),
                            description: const Text(
                              'Log in using your Hacker News account '
                              'to check out stories and comments you have '
                              'posted in the past, and get in-app '
                              'notification when there is new reply to '
                              'your comments or stories.',
                              style: TextStyle(fontSize: 16),
                            ),
                            child: BlocBuilder<NotificationCubit,
                                NotificationState>(
                              buildWhen: (
                                NotificationState previous,
                                NotificationState current,
                              ) =>
                                  previous.unreadCommentsIds.length !=
                                  current.unreadCommentsIds.length,
                              builder: (
                                BuildContext context,
                                NotificationState state,
                              ) {
                                return Badge(
                                  showBadge: state.unreadCommentsIds.isNotEmpty,
                                  borderRadius: BorderRadius.circular(100),
                                  badgeContent: Container(
                                    height: 3,
                                    width: 3,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: currentIndex == 5 ? 16 : 12,
                                    color: currentIndex == 5
                                        ? Colors.orange
                                        : Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              physics: const NeverScrollableScrollPhysics(),
              controller: tabController,
              children: <Widget>[
                StoriesListView(
                  key: const ValueKey<StoryType>(StoryType.top),
                  storyType: StoryType.top,
                  header: pinnedStories,
                  onStoryTapped: onStoryTapped,
                ),
                StoriesListView(
                  key: const ValueKey<StoryType>(StoryType.latest),
                  storyType: StoryType.latest,
                  header: pinnedStories,
                  onStoryTapped: onStoryTapped,
                ),
                StoriesListView(
                  key: const ValueKey<StoryType>(StoryType.ask),
                  storyType: StoryType.ask,
                  header: pinnedStories,
                  onStoryTapped: onStoryTapped,
                ),
                StoriesListView(
                  key: const ValueKey<StoryType>(StoryType.show),
                  storyType: StoryType.show,
                  header: pinnedStories,
                  onStoryTapped: onStoryTapped,
                ),
                StoriesListView(
                  key: const ValueKey<StoryType>(StoryType.jobs),
                  storyType: StoryType.jobs,
                  header: pinnedStories,
                  onStoryTapped: onStoryTapped,
                ),
                const ProfileScreen(),
              ],
            ),
          ),
        );
      },
    );

    return ScreenTypeLayout.builder(
      mobile: (BuildContext context) {
        context.read<SplitViewCubit>().disableSplitView();
        return _MobileHomeScreenBuilder(
          homeScreen: homeScreen,
        );
      },
      tablet: (BuildContext context) => _TabletHomeScreenBuilder(
        homeScreen: homeScreen,
      ),
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

  void onStoryTapped(Story story, {bool isPin = false}) {
    final bool showWebFirst =
        context.read<PreferenceCubit>().state.showWebFirst;
    final bool useReader = context.read<PreferenceCubit>().state.useReader;
    final bool offlineReading =
        context.read<StoriesBloc>().state.offlineReading;
    final bool hasRead = isPin || context.read<StoriesBloc>().hasRead(story);
    final bool splitViewEnabled = context.read<SplitViewCubit>().state.enabled;

    // If a story is a job story and it has a link to the job posting,
    // it would be better to just navigate to the web page.
    final bool isJobWithLink = story.isJob && story.url.isNotEmpty;

    if (isJobWithLink) {
      context.read<ReminderCubit>().removeLastReadStoryId();
    } else {
      final StoryScreenArgs args = StoryScreenArgs(story: story);

      context.read<ReminderCubit>().updateLastReadStoryId(story.id);

      if (splitViewEnabled) {
        context.read<SplitViewCubit>().updateStoryScreenArgs(args);
      } else {
        HackiApp.navigatorKey.currentState
            ?.pushNamed(
          StoryScreen.routeName,
          arguments: args,
        )
            .whenComplete(() {
          context.read<ReminderCubit>().removeLastReadStoryId();
        });
      }
    }

    if (!offlineReading && (isJobWithLink || (showWebFirst && !hasRead))) {
      LinkUtil.launchUrl(story.url, useReader: useReader);
    }

    context.read<StoriesBloc>().add(
          StoryRead(
            story: story,
          ),
        );
  }

  void showOnboarding() {
    Navigator.push<dynamic>(
      context,
      MaterialPageRoute<dynamic>(
        builder: (BuildContext context) => const OnboardingView(),
        fullscreenDialog: true,
      ),
    );
  }

  void onShareExtensionTapped(String? event) {
    if (event == null) return;

    final int? id = event.getItemId();

    if (id != null) {
      locator
          .get<StoriesRepository>()
          .fetchParentStory(id: id)
          .then((Story? story) {
        if (mounted) {
          if (story != null) {
            goToStoryScreen(args: StoryScreenArgs(story: story));
          }
        }
      });
    }
  }

  Future<void> onNotificationTapped(String? payload) async {
    if (payload == null) return;

    final Map<String, dynamic> payloadJson =
        jsonDecode(payload) as Map<String, dynamic>;

    final int? storyId = payloadJson['storyId'] as int?;
    final int? commentId = payloadJson['commentId'] as int?;

    if (storyId != null && commentId != null) {
      context.read<NotificationCubit>().markAsRead(commentId);

      await locator
          .get<StoriesRepository>()
          .fetchStoryBy(storyId)
          .then((Story? story) {
        if (story == null) {
          showSnackBar(content: 'Something went wrong...');
          return;
        }
        final StoryScreenArgs args = StoryScreenArgs(story: story);
        goToStoryScreen(args: args);
      });
    }
  }
}

class _MobileHomeScreenBuilder extends StatelessWidget {
  const _MobileHomeScreenBuilder({
    Key? key,
    required this.homeScreen,
  }) : super(key: key);

  final Widget homeScreen;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(child: homeScreen),
        if (!context.read<ReminderCubit>().state.hasShown)
          const Positioned(
            left: 24,
            right: 24,
            bottom: 36,
            height: 40,
            child: CountdownReminder(),
          ),
      ],
    );
  }
}

class _TabletHomeScreenBuilder extends StatelessWidget {
  const _TabletHomeScreenBuilder({
    Key? key,
    required this.homeScreen,
  }) : super(key: key);

  final Widget homeScreen;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (BuildContext context, SizingInformation sizeInfo) {
        context.read<SplitViewCubit>().enableSplitView();
        double homeScreenWidth = 428;

        if (sizeInfo.screenSize.width < homeScreenWidth * 2) {
          homeScreenWidth = 345.0;
        }

        return Stack(
          children: <Widget>[
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: homeScreenWidth,
              child: homeScreen,
            ),
            Positioned(
              left: 24,
              bottom: 36,
              height: 40,
              width: homeScreenWidth - 24,
              child: const CountdownReminder(),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              left: homeScreenWidth,
              child: const _TabletStoryView(),
            ),
          ],
        );
      },
    );
  }
}

class _TabletStoryView extends StatelessWidget {
  const _TabletStoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SplitViewCubit, SplitViewState>(
      buildWhen: (SplitViewState previous, SplitViewState current) =>
          previous.storyScreenArgs != current.storyScreenArgs,
      builder: (BuildContext context, SplitViewState state) {
        if (state.storyScreenArgs != null) {
          return StoryScreen.build(state.storyScreenArgs!);
        }

        return Material(
          child: Container(
            color: Theme.of(context).canvasColor,
            child: const Center(
              child: Text('Tap on story tile to view comments.'),
            ),
          ),
        );
      },
    );
  }
}
