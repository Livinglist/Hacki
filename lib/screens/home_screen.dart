// ignore_for_file: lines_longer_than_80_chars

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
import 'package:hacki/main.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/utils/utils.dart';
import 'package:responsive_builder/responsive_builder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static const String routeName = '/';

  static Route route() {
    return MaterialPageRoute<HomeScreen>(
      settings: const RouteSettings(name: routeName),
      builder: (context) => const HomeScreen(),
    );
  }

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final cacheService = locator.get<CacheService>();
  late final TabController tabController;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();

    // This is for testing only.
    // FeatureDiscovery.clearPreferences(context, [
    //   Constants.featureLogIn,
    //   Constants.featureAddStoryToFavList,
    //   Constants.featureOpenStoryInWebView,
    //   Constants.featurePinToTop,
    // ]);

    SchedulerBinding.instance?.addPostFrameCallback((_) {
      FeatureDiscovery.discoverFeatures(
        context,
        const <String>{
          Constants.featureLogIn,
        },
      );
    });

    tabController = TabController(vsync: this, length: 6)
      ..addListener(() {
        setState(() {
          currentIndex = tabController.index;
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    final homeScreen = BlocBuilder<PreferenceCubit, PreferenceState>(
      buildWhen: (previous, current) =>
          previous.showComplexStoryTile != current.showComplexStoryTile,
      builder: (context, preferenceState) {
        final pinnedStories = BlocBuilder<PinCubit, PinState>(
          builder: (context, state) {
            return Column(
              children: [
                for (final story in state.pinnedStories)
                  FadeIn(
                    child: Slidable(
                      startActionPane: ActionPane(
                        motion: const BehindMotion(),
                        children: [
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
                          onTap: () => onStoryTapped(story),
                          showWebPreview: preferenceState.showComplexStoryTile,
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

        return BlocBuilder<CacheCubit, CacheState>(
          builder: (context, cacheState) {
            return DefaultTabController(
              length: 6,
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: PreferredSize(
                  preferredSize: const Size(0, 40),
                  child: Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).padding.top - 8,
                      ),
                      Theme(
                        data: ThemeData(
                          highlightColor: Colors.transparent,
                          splashColor: Colors.transparent,
                        ),
                        child: TabBar(
                          isScrollable: true,
                          controller: tabController,
                          indicatorColor: Colors.orange,
                          indicator: CircleTabIndicator(
                              color: Colors.orange, radius: 2),
                          indicatorPadding: const EdgeInsets.only(bottom: 8),
                          onTap: (_) {
                            HapticFeedback.selectionClick();
                          },
                          tabs: [
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
                                barrierDismissible: false,
                                overflowMode: OverflowMode.extendBackground,
                                targetColor: Theme.of(context).primaryColor,
                                tapTarget: const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                featureId: Constants.featureLogIn,
                                title: const Text(''),
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
                                  buildWhen: (previous, current) =>
                                      previous.unreadCommentsIds.length !=
                                      current.unreadCommentsIds.length,
                                  builder: (context, state) {
                                    return Badge(
                                      showBadge:
                                          state.unreadCommentsIds.isNotEmpty,
                                      borderRadius: BorderRadius.circular(100),
                                      badgeContent: Container(
                                        height: 3,
                                        width: 3,
                                        decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white),
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
                  children: [
                    StoriesListView(
                      key: const ValueKey(StoryType.top),
                      storyType: StoryType.top,
                      header: pinnedStories,
                      onStoryTapped: onStoryTapped,
                    ),
                    StoriesListView(
                      key: const ValueKey(StoryType.latest),
                      storyType: StoryType.latest,
                      header: pinnedStories,
                      onStoryTapped: onStoryTapped,
                    ),
                    StoriesListView(
                      key: const ValueKey(StoryType.ask),
                      storyType: StoryType.ask,
                      header: pinnedStories,
                      onStoryTapped: onStoryTapped,
                    ),
                    StoriesListView(
                      key: const ValueKey(StoryType.show),
                      storyType: StoryType.show,
                      header: pinnedStories,
                      onStoryTapped: onStoryTapped,
                    ),
                    StoriesListView(
                      key: const ValueKey(StoryType.jobs),
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
      },
    );

    return ScreenTypeLayout.builder(
      mobile: (context) {
        context.read<SplitViewCubit>().disableSplitView();
        return homeScreen;
      },
      tablet: (context) {
        return ResponsiveBuilder(
          builder: (context, sizeInfo) {
            context.read<SplitViewCubit>().enableSplitView();
            var homeScreenWidth = 428.0;

            if (sizeInfo.screenSize.width < homeScreenWidth * 2) {
              homeScreenWidth = 345.0;
            }

            return Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: homeScreenWidth,
                  child: homeScreen,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  left: homeScreenWidth,
                  child: BlocBuilder<SplitViewCubit, SplitViewState>(
                    buildWhen: (previous, current) =>
                        previous.storyScreenArgs != current.storyScreenArgs,
                    builder: (context, state) {
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
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void onStoryTapped(Story story) {
    final showWebFirst = context.read<PreferenceCubit>().state.showWebFirst;
    final useReader = context.read<PreferenceCubit>().state.useReader;
    final offlineReading = context.read<StoriesBloc>().state.offlineReading;
    final firstTimeReading = cacheService.isFirstTimeReading(story.id);
    final splitViewEnabled = context.read<SplitViewCubit>().state.enabled;

    // If a story is a job story and it has a link to the job posting,
    // it would be better to just navigate to the web page.
    final isJobWithLink = story.type == 'job' && story.url.isNotEmpty;

    if (!isJobWithLink) {
      final args = StoryScreenArgs(story: story);
      if (splitViewEnabled) {
        context.read<SplitViewCubit>().updateStoryScreenArgs(args);
      } else {
        HackiApp.navigatorKey.currentState?.pushNamed(
          StoryScreen.routeName,
          arguments: args,
        );
      }
    }

    if (!offlineReading &&
        (isJobWithLink || (showWebFirst && firstTimeReading))) {
      LinkUtil.launchUrl(story.url, useReader: useReader);
      cacheService.store(story.id);
    }

    context.read<CacheCubit>().markStoryAsRead(story.id);
  }
}
