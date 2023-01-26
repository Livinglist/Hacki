import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:badges/badges.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_fadein/flutter_fadein.dart';
import 'package:flutter_siri_suggestions/flutter_siri_suggestions.dart';
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
import 'package:hacki/styles/styles.dart';
import 'package:hacki/utils/utils.dart';
import 'package:logger/logger.dart';
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
  final Throttle featureDiscoveryDismissThrottle = Throttle(
    delay: _throttleDelay,
  );

  late final TabController tabController;
  late final StreamSubscription<String> intentDataStreamSubscription;
  late final StreamSubscription<String?> notificationStreamSubscription;
  late final StreamSubscription<String?> siriSuggestionStreamSubscription;

  int currentIndex = 0;

  static const Duration _throttleDelay = Duration(seconds: 1);

  @override
  void didPopNext() {
    super.didPopNext();
    if (context.read<StoriesBloc>().deviceScreenType ==
        DeviceScreenType.mobile) {
      locator.get<Logger>().i('resetting comments in CommentCache');
      Future<void>.delayed(
        const Duration(milliseconds: 500),
        locator.get<CommentCache>().resetComments,
      );
    }
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

    if (!siriSuggestionSubject.hasListener) {
      siriSuggestionStreamSubscription =
          siriSuggestionSubject.stream.listen(onSiriSuggestionTapped);
    }

    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        if (!isTesting) {
          FeatureDiscovery.discoverFeatures(
            context,
            const <String>{
              Constants.featureLogIn,
            },
          );
        }
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
    siriSuggestionStreamSubscription.cancel();
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
                            backgroundColor: Palette.red,
                            foregroundColor: Palette.white,
                            icon: preferenceState.showComplexStoryTile
                                ? Icons.close
                                : null,
                            label: 'Unpin',
                          ),
                        ],
                      ),
                      child: ColoredBox(
                        color: Palette.orangeAccent.withOpacity(0.2),
                        child: StoryTile(
                          key: ValueKey<String>('${story.id}-PinnedStoryTile'),
                          story: story,
                          onTap: () => onStoryTapped(story, isPin: true),
                          showWebPreview: preferenceState.showComplexStoryTile,
                          showMetadata: preferenceState.showMetadata,
                          showUrl: preferenceState.showUrl,
                        ),
                      ),
                    ),
                  ),
                if (state.pinnedStories.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: Dimens.pt12),
                    child: Divider(
                      color: Palette.orangeAccent,
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
              preferredSize: const Size(
                Dimens.zero,
                Dimens.pt40,
              ),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    height: MediaQuery.of(context).padding.top - Dimens.pt8,
                  ),
                  Theme(
                    data: ThemeData(
                      highlightColor: Palette.transparent,
                      splashColor: Palette.transparent,
                      primaryColor: Theme.of(context).primaryColor,
                    ),
                    child: TabBar(
                      isScrollable: true,
                      controller: tabController,
                      indicatorColor: Palette.orange,
                      indicator: CircleTabIndicator(
                        color: Palette.orange,
                        radius: Dimens.pt2,
                      ),
                      indicatorPadding: const EdgeInsets.only(
                        bottom: Dimens.pt8,
                      ),
                      onTap: (_) {
                        HapticFeedback.selectionClick();
                      },
                      tabs: <Widget>[
                        for (int i = 0; i < StoriesBloc.types.length; i++)
                          Tab(
                            key: ValueKey<StoryType>(
                              StoriesBloc.types.elementAt(i),
                            ),
                            child: Text(
                              StoriesBloc.types.elementAt(i).label,
                              style: TextStyle(
                                fontSize: currentIndex == i
                                    ? TextDimens.pt14
                                    : TextDimens.pt10,
                                color: currentIndex == i
                                    ? Palette.orange
                                    : Palette.grey,
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
                              size: TextDimens.pt16,
                              color: Palette.white,
                            ),
                            featureId: Constants.featureLogIn,
                            title: const Text('Log in for more'),
                            description: const Text(
                              'Log in using your Hacker News account '
                              'to check out stories and comments you have '
                              'posted in the past, and get in-app '
                              'notification when there is new reply to '
                              'your comments or stories.',
                              style: TextStyle(fontSize: TextDimens.pt16),
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
                                    height: Dimens.pt3,
                                    width: Dimens.pt3,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Palette.white,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: currentIndex == 5
                                        ? TextDimens.pt16
                                        : TextDimens.pt12,
                                    color: currentIndex == 5
                                        ? Palette.orange
                                        : Palette.grey,
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
                for (final StoryType type in StoriesBloc.types)
                  StoriesListView(
                    key: ValueKey<StoryType>(type),
                    storyType: type,
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
        return _MobileHomeScreen(
          homeScreen: homeScreen,
        );
      },
      tablet: (BuildContext context) => _TabletHomeScreen(
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
      final ItemScreenArgs args = ItemScreenArgs(item: story);

      context.read<ReminderCubit>().updateLastReadStoryId(story.id);

      if (splitViewEnabled) {
        context.read<SplitViewCubit>().updateItemScreenArgs(args);
      } else {
        HackiApp.navigatorKey.currentState
            ?.pushNamed(
          ItemScreen.routeName,
          arguments: args,
        )
            .whenComplete(() {
          context.read<ReminderCubit>().removeLastReadStoryId();
        });
      }
    }

    if (story.url.isNotEmpty && (isJobWithLink || (showWebFirst && !hasRead))) {
      LinkUtil.launch(
        story.url,
        useReader: useReader,
        offlineReading: offlineReading,
      );
    }

    context.read<StoriesBloc>().add(
          StoryRead(
            story: story,
          ),
        );

    if (Platform.isIOS) {
      FlutterSiriSuggestions.instance.registerActivity(
        FlutterSiriActivity(
          story.title,
          story.id.toString(),
          suggestedInvocationPhrase: '',
          contentDescription: story.text,
          persistentIdentifier: story.id.toString(),
        ),
      );
    }
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

    final int? id = event.itemId;

    if (id != null) {
      locator.get<StoriesRepository>().fetchItemBy(id: id).then((Item? item) {
        if (mounted) {
          if (item != null) {
            goToItemScreen(
              args: ItemScreenArgs(item: item),
              forceNewScreen: true,
            );
          }
        }
      });
    }
  }

  Future<void> onSiriSuggestionTapped(String? id) async {
    if (id == null) return;
    final int? storyId = int.tryParse(id);
    if (storyId == null) return;

    await locator
        .get<StoriesRepository>()
        .fetchStoryBy(storyId)
        .then((Story? story) {
      if (story == null) {
        showSnackBar(content: 'Something went wrong...');
        return;
      }
      final ItemScreenArgs args = ItemScreenArgs(item: story);
      goToItemScreen(args: args);
    });
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
        final ItemScreenArgs args = ItemScreenArgs(item: story);
        goToItemScreen(args: args);
      });
    }
  }
}

class _MobileHomeScreen extends StatelessWidget {
  const _MobileHomeScreen({
    required this.homeScreen,
  });

  final Widget homeScreen;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(child: homeScreen),
        if (!context.read<ReminderCubit>().state.hasShown)
          const Positioned(
            left: Dimens.pt24,
            right: Dimens.pt24,
            bottom: Dimens.pt36,
            height: Dimens.pt40,
            child: CountdownReminder(),
          ),
      ],
    );
  }
}

class _TabletHomeScreen extends StatelessWidget {
  const _TabletHomeScreen({
    required this.homeScreen,
  });

  final Widget homeScreen;

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (BuildContext context, SizingInformation sizeInfo) {
        context.read<SplitViewCubit>().enableSplitView();
        double homeScreenWidth = 428;

        if (sizeInfo.screenSize.width < homeScreenWidth * 2) {
          homeScreenWidth = 345;
        }

        return BlocBuilder<SplitViewCubit, SplitViewState>(
          buildWhen: (SplitViewState previous, SplitViewState current) =>
              previous.expanded != current.expanded,
          builder: (BuildContext context, SplitViewState state) {
            return Stack(
              children: <Widget>[
                AnimatedPositioned(
                  left: Dimens.zero,
                  top: Dimens.zero,
                  bottom: Dimens.zero,
                  width: homeScreenWidth,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  child: homeScreen,
                ),
                Positioned(
                  left: Dimens.pt24,
                  bottom: Dimens.pt36,
                  height: Dimens.pt40,
                  width: homeScreenWidth - Dimens.pt24,
                  child: const CountdownReminder(),
                ),
                AnimatedPositioned(
                  right: Dimens.zero,
                  top: Dimens.zero,
                  bottom: Dimens.zero,
                  left: state.expanded ? Dimens.zero : homeScreenWidth,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  child: const _TabletStoryView(),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TabletStoryView extends StatelessWidget {
  const _TabletStoryView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SplitViewCubit, SplitViewState>(
      buildWhen: (SplitViewState previous, SplitViewState current) =>
          previous.itemScreenArgs != current.itemScreenArgs,
      builder: (BuildContext context, SplitViewState state) {
        if (state.itemScreenArgs != null) {
          return ItemScreen.build(context, state.itemScreenArgs!);
        }

        return Material(
          child: ColoredBox(
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
