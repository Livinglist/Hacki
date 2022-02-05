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
import 'package:pull_to_refresh/pull_to_refresh.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static const String routeName = '/home';

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
  final refreshControllerTop = RefreshController();
  final refreshControllerNew = RefreshController();
  final refreshControllerAsk = RefreshController();
  final refreshControllerShow = RefreshController();
  final refreshControllerJobs = RefreshController();
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
    return BlocBuilder<PreferenceCubit, PreferenceState>(
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
                            onPressed: (_) =>
                                context.read<PinCubit>().unpinStory(story),
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

        return BlocConsumer<StoriesBloc, StoriesState>(
          listener: (context, state) {
            if (state.statusByType[StoryType.top] == StoriesStatus.loaded) {
              refreshControllerTop
                ..refreshCompleted(resetFooterState: true)
                ..loadComplete();
            }
            if (state.statusByType[StoryType.latest] == StoriesStatus.loaded) {
              refreshControllerNew
                ..refreshCompleted(resetFooterState: true)
                ..loadComplete();
            }
            if (state.statusByType[StoryType.ask] == StoriesStatus.loaded) {
              refreshControllerAsk
                ..refreshCompleted(resetFooterState: true)
                ..loadComplete();
            }
            if (state.statusByType[StoryType.show] == StoriesStatus.loaded) {
              refreshControllerShow
                ..refreshCompleted(resetFooterState: true)
                ..loadComplete();
            }
            if (state.statusByType[StoryType.jobs] == StoriesStatus.loaded) {
              refreshControllerJobs
                ..refreshCompleted(resetFooterState: true)
                ..loadComplete();
            }
          },
          builder: (context, state) {
            return WillPopScope(
              onWillPop: () => Future.value(false),
              child: DefaultTabController(
                length: 6,
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  appBar: PreferredSize(
                    preferredSize: const Size(0, 48),
                    child: Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).padding.top,
                        ),
                        TabBar(
                          isScrollable: true,
                          controller: tabController,
                          indicatorColor: Colors.orange,
                          tabs: [
                            Tab(
                              child: Text(
                                'TOP',
                                style: TextStyle(
                                  fontSize: 14,
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
                                  fontSize: 14,
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
                                  fontSize: 14,
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
                                  fontSize: 13,
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
                                  fontSize: 14,
                                  color: currentIndex == 4
                                      ? Colors.orange
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            Tab(
                              icon: DescribedFeatureOverlay(
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
                                  'your comments or stories',
                                  style: TextStyle(fontSize: 16),
                                ),
                                child: BlocBuilder<NotificationCubit,
                                    NotificationState>(
                                  builder: (context, state) {
                                    if (state.unreadCommentsIds.isEmpty) {
                                      return Icon(
                                        Icons.person,
                                        size: 16,
                                        color: currentIndex == 5
                                            ? Colors.orange
                                            : Colors.grey,
                                      );
                                    } else {
                                      return Badge(
                                        borderRadius:
                                            BorderRadius.circular(100),
                                        badgeContent: Container(
                                          height: 3,
                                          width: 3,
                                          decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white),
                                        ),
                                        child: Icon(
                                          Icons.person,
                                          size: 16,
                                          color: currentIndex == 5
                                              ? Colors.orange
                                              : Colors.grey,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  body: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: tabController,
                    children: [
                      ItemsListView<Story>(
                        pinnable: true,
                        showWebPreview: preferenceState.showComplexStoryTile,
                        refreshController: refreshControllerTop,
                        items: state.storiesByType[StoryType.top]!,
                        onRefresh: () {
                          HapticFeedback.lightImpact();
                          context
                              .read<StoriesBloc>()
                              .add(StoriesRefresh(type: StoryType.top));
                        },
                        onLoadMore: () {
                          context
                              .read<StoriesBloc>()
                              .add(StoriesLoadMore(type: StoryType.top));
                        },
                        onTap: onStoryTapped,
                        onPinned: context.read<PinCubit>().pinStory,
                        header: pinnedStories,
                      ),
                      ItemsListView<Story>(
                        pinnable: true,
                        showWebPreview: preferenceState.showComplexStoryTile,
                        refreshController: refreshControllerNew,
                        items: state.storiesByType[StoryType.latest]!,
                        onRefresh: () {
                          HapticFeedback.lightImpact();
                          context
                              .read<StoriesBloc>()
                              .add(StoriesRefresh(type: StoryType.latest));
                        },
                        onLoadMore: () {
                          context
                              .read<StoriesBloc>()
                              .add(StoriesLoadMore(type: StoryType.latest));
                        },
                        onTap: onStoryTapped,
                        onPinned: context.read<PinCubit>().pinStory,
                        header: pinnedStories,
                      ),
                      ItemsListView<Story>(
                        pinnable: true,
                        showWebPreview: preferenceState.showComplexStoryTile,
                        refreshController: refreshControllerAsk,
                        items: state.storiesByType[StoryType.ask]!,
                        onRefresh: () {
                          HapticFeedback.lightImpact();
                          context
                              .read<StoriesBloc>()
                              .add(StoriesRefresh(type: StoryType.ask));
                        },
                        onLoadMore: () {
                          context
                              .read<StoriesBloc>()
                              .add(StoriesLoadMore(type: StoryType.ask));
                        },
                        onTap: onStoryTapped,
                        onPinned: context.read<PinCubit>().pinStory,
                        header: pinnedStories,
                      ),
                      ItemsListView<Story>(
                        pinnable: true,
                        showWebPreview: preferenceState.showComplexStoryTile,
                        refreshController: refreshControllerShow,
                        items: state.storiesByType[StoryType.show]!,
                        onRefresh: () {
                          HapticFeedback.lightImpact();
                          context
                              .read<StoriesBloc>()
                              .add(StoriesRefresh(type: StoryType.show));
                        },
                        onLoadMore: () {
                          context
                              .read<StoriesBloc>()
                              .add(StoriesLoadMore(type: StoryType.show));
                        },
                        onTap: onStoryTapped,
                        onPinned: context.read<PinCubit>().pinStory,
                        header: pinnedStories,
                      ),
                      ItemsListView<Story>(
                        pinnable: true,
                        showWebPreview: preferenceState.showComplexStoryTile,
                        refreshController: refreshControllerJobs,
                        items: state.storiesByType[StoryType.jobs]!,
                        onRefresh: () {
                          HapticFeedback.lightImpact();
                          context
                              .read<StoriesBloc>()
                              .add(StoriesRefresh(type: StoryType.jobs));
                        },
                        onLoadMore: () {
                          context
                              .read<StoriesBloc>()
                              .add(StoriesLoadMore(type: StoryType.jobs));
                        },
                        onTap: onStoryTapped,
                        onPinned: context.read<PinCubit>().pinStory,
                        header: pinnedStories,
                      ),
                      const ProfileScreen(),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void onStoryTapped(Story story) {
    final showWebFirst = context.read<PreferenceCubit>().state.showWebFirst;

    // If a story is a job story and it has a link to the job posting,
    // it would be better to just navigate to the web page.
    final isJobWithLink = story.type == 'job' && story.url.isNotEmpty;

    if (!isJobWithLink) {
      HackiApp.navigatorKey.currentState!.pushNamed(StoryScreen.routeName,
          arguments: StoryScreenArgs(story: story));
    }

    if (isJobWithLink ||
        (showWebFirst && cacheService.isFirstTimeReading(story.id))) {
      LinkUtil.launchUrl(story.url);
      cacheService.store(story.id);
    }
  }
}
