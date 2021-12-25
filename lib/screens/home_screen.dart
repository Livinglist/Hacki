import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/main.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/services/services.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:url_launcher/url_launcher.dart';

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
    tabController = TabController(vsync: this, length: 5)
      ..addListener(() {
        setState(() {
          currentIndex = tabController.index;
        });
      });
  }

  @override
  Widget build(BuildContext context) {
    final cacheService = locator.get<CacheService>();

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
        return DefaultTabController(
          length: 5,
          child: Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size(0, 60),
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).padding.top,
                  ),
                  TabBar(
                    controller: tabController,
                    indicatorColor: Colors.orange,
                    tabs: [
                      Tab(
                        child: Text(
                          'TOP',
                          style: TextStyle(
                            color:
                                currentIndex == 0 ? Colors.orange : Colors.grey,
                          ),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'NEW',
                          style: TextStyle(
                            color:
                                currentIndex == 1 ? Colors.orange : Colors.grey,
                          ),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'ASK',
                          style: TextStyle(
                            color:
                                currentIndex == 2 ? Colors.orange : Colors.grey,
                          ),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'SHOW',
                          style: TextStyle(
                            color:
                                currentIndex == 3 ? Colors.orange : Colors.grey,
                          ),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'JOBS',
                          style: TextStyle(
                            color:
                                currentIndex == 4 ? Colors.orange : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            body: TabBarView(
              controller: tabController,
              children: [
                ItemsListView<Story>(
                  key: const PageStorageKey('test'),
                  refreshController: refreshControllerTop,
                  items: state.storiesByType[StoryType.top]!,
                  onRefresh: () {
                    context
                        .read<StoriesBloc>()
                        .add(StoriesRefresh(type: StoryType.top));
                  },
                  onLoadMore: () {
                    context
                        .read<StoriesBloc>()
                        .add(StoriesLoadMore(type: StoryType.top));
                  },
                  onTap: (story) {
                    HackiApp.navigatorKey.currentState!.pushNamed(
                        StoryScreen.routeName,
                        arguments: StoryScreenArgs(story: story));

                    if (cacheService.isFirstTimeReading(story.id)) {
                      final url = Uri.encodeFull(story.url);
                      canLaunch(url).then((val) {
                        if (val) {
                          launch(url);
                        }
                      });
                      cacheService.store(story.id);
                    }
                  },
                ),
                ItemsListView<Story>(
                  refreshController: refreshControllerNew,
                  items: state.storiesByType[StoryType.latest]!,
                  onRefresh: () {
                    context
                        .read<StoriesBloc>()
                        .add(StoriesRefresh(type: StoryType.latest));
                  },
                  onLoadMore: () {
                    context
                        .read<StoriesBloc>()
                        .add(StoriesLoadMore(type: StoryType.latest));
                  },
                  onTap: (story) {
                    HackiApp.navigatorKey.currentState!.pushNamed(
                        StoryScreen.routeName,
                        arguments: StoryScreenArgs(story: story));

                    if (cacheService.isFirstTimeReading(story.id)) {
                      final url = Uri.encodeFull(story.url);
                      canLaunch(url).then((val) {
                        if (val) {
                          launch(url);
                        }
                      });
                      cacheService.store(story.id);
                    }
                  },
                ),
                ItemsListView<Story>(
                  refreshController: refreshControllerAsk,
                  items: state.storiesByType[StoryType.ask]!,
                  onRefresh: () {
                    context
                        .read<StoriesBloc>()
                        .add(StoriesRefresh(type: StoryType.ask));
                  },
                  onLoadMore: () {
                    context
                        .read<StoriesBloc>()
                        .add(StoriesLoadMore(type: StoryType.ask));
                  },
                  onTap: (story) {
                    HackiApp.navigatorKey.currentState!.pushNamed(
                        StoryScreen.routeName,
                        arguments: StoryScreenArgs(story: story));

                    if (cacheService.isFirstTimeReading(story.id)) {
                      final url = Uri.encodeFull(story.url);
                      canLaunch(url).then((val) {
                        if (val) {
                          launch(url);
                        }
                      });
                      cacheService.store(story.id);
                    }
                  },
                ),
                ItemsListView<Story>(
                  refreshController: refreshControllerShow,
                  items: state.storiesByType[StoryType.show]!,
                  onRefresh: () {
                    context
                        .read<StoriesBloc>()
                        .add(StoriesRefresh(type: StoryType.show));
                  },
                  onLoadMore: () {
                    context
                        .read<StoriesBloc>()
                        .add(StoriesLoadMore(type: StoryType.show));
                  },
                  onTap: (story) {
                    HackiApp.navigatorKey.currentState!.pushNamed(
                        StoryScreen.routeName,
                        arguments: StoryScreenArgs(story: story));

                    if (cacheService.isFirstTimeReading(story.id)) {
                      final url = Uri.encodeFull(story.url);
                      canLaunch(url).then((val) {
                        if (val) {
                          launch(url);
                        }
                      });
                      cacheService.store(story.id);
                    }
                  },
                ),
                ItemsListView<Story>(
                  refreshController: refreshControllerJobs,
                  items: state.storiesByType[StoryType.jobs]!,
                  onRefresh: () {
                    context
                        .read<StoriesBloc>()
                        .add(StoriesRefresh(type: StoryType.jobs));
                  },
                  onLoadMore: () {
                    context
                        .read<StoriesBloc>()
                        .add(StoriesLoadMore(type: StoryType.jobs));
                  },
                  onTap: (story) {
                    final url = Uri.encodeFull(story.url);
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
        );
      },
    );
  }
}
