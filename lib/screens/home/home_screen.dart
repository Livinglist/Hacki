import 'dart:async';
import 'dart:convert';

import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/config/paths.dart';
import 'package:hacki/config/router.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/main.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/screens/home/widgets/widgets.dart';
import 'package:hacki/screens/screens.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/styles/styles.dart';
import 'package:material_ui/material_ui.dart' hide Badge;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:responsive_builder/responsive_builder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/';

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, RouteAware, ItemActionMixin, Loggable {
  late final TabController tabController;
  late final StreamSubscription<List<SharedMediaFile>>
  intentDataStreamSubscription;
  late final StreamSubscription<String?> notificationStreamSubscription;
  late final StreamSubscription<String?> siriSuggestionStreamSubscription;
  late final StreamSubscription<StoriesDownloadStatus>
  downloadStreamSubscription;

  static final int tabLength = StoryType.values.length + 1;

  @override
  void initState() {
    super.initState();

    downloadStreamSubscription = context
        .read<StoriesBloc>()
        .stream
        .map((StoriesState state) => state.downloadStatus)
        .distinct()
        .listen((StoriesDownloadStatus status) {
          if (status == StoriesDownloadStatus.finished) {
            DialogProxy.showDownloadCompletedDialog();
          }
        });

    ReceiveSharingIntent.instance.getInitialMedia().then(
      onShareExtensionTapped,
    );

    intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(onShareExtensionTapped);

    if (!selectNotificationSubject.hasListener) {
      notificationStreamSubscription = selectNotificationSubject.stream.listen(
        onNotificationTapped,
      );
    }

    if (!siriSuggestionSubject.hasListener) {
      siriSuggestionStreamSubscription = siriSuggestionSubject.stream.listen(
        onSiriSuggestionTapped,
      );
    }

    SchedulerBinding.instance
      ..addPostFrameCallback((_) => unawaited(applyIosLaunchDeepLink()))
      ..addPostFrameCallback((_) => showFeatureDiscoveryDialog())
      ..addPostFrameCallback((_) {
        final ModalRoute<dynamic>? route = ModalRoute.of(context);

        if (route == null) return;

        locator.get<RouteObserver<ModalRoute<dynamic>>>().subscribe(
          this,
          route,
        );
      });

    tabController = TabController(length: tabLength, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ReviewRequestCubit reviewRequestCubit = context
          .read<ReviewRequestCubit>();
      if (!reviewRequestCubit.state.hasShown &&
          reviewRequestCubit.feelingLucky) {
        reviewRequestCubit.markAsShown();
        showModalBottomSheet<bool>(
          context: context,
          isDismissible: false,
          builder: (BuildContext context) {
            return const ReviewRequestBottomSheet();
          },
        );
      }
    });
  }

  @override
  void dispose() {
    tabController.dispose();
    intentDataStreamSubscription.cancel();
    notificationStreamSubscription.cancel();
    siriSuggestionStreamSubscription.cancel();
    downloadStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BlocBuilder<PreferenceCubit, PreferenceState>
    homeScreen = BlocBuilder<PreferenceCubit, PreferenceState>(
      buildWhen: (PreferenceState previous, PreferenceState current) =>
          previous.isRichStoryTileEnabled != current.isRichStoryTileEnabled ||
          previous.isMetadataEnabled != current.isMetadataEnabled ||
          previous.isSwipeGestureEnabled != current.isSwipeGestureEnabled ||
          previous.isDividerEnabled != current.isDividerEnabled ||
          previous.isStoryTilePreviewImageEnabled !=
              current.isStoryTilePreviewImageEnabled ||
          previous.isHackerNewsThemeEnabled != current.isHackerNewsThemeEnabled,
      builder: (BuildContext context, PreferenceState preferenceState) {
        final PinState pinState = context.watch<PinCubit>().state;
        final bool hasPins = pinState.pinnedStories.isNotEmpty;
        return DefaultTabController(
          length: tabLength,
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: PreferredSize(
              preferredSize: const Size(Dimens.zero, Dimens.pt40),
              child: OptionalWrapper(
                enabled: preferenceState.isHackerNewsThemeEnabled,
                wrapper: (Widget c) =>
                    ColoredBox(color: HackerNewsTheme.hnOrange, child: c),
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      height: MediaQuery.of(context).padding.top - Dimens.pt8,
                    ),
                    CustomTabBar(tabController: tabController),
                  ],
                ),
              ),
            ),
            body: BlocBuilder<TabCubit, TabState>(
              builder: (BuildContext context, TabState state) {
                return TabBarView(
                  physics: preferenceState.isSwipeGestureEnabled
                      ? const PageScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  controller: tabController,
                  children: <Widget>[
                    for (final StoryType type in state.tabs)
                      StoriesListView(
                        key: ValueKey<StoryType>(type),
                        storyType: type,
                        header: AnimatedSize(
                          duration: AppDurations.ms300,
                          child: hasPins
                              ? ListTile(
                                  leading: const Icon(Icons.push_pin),
                                  title: Text(
                                    '''${pinState.pinnedStories.length} Pin${pinState.pinnedStories.length > 1 ? 's' : ''}''',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    context.go(Paths.pins.landing);
                                  },
                                )
                              : const SizedBox.shrink(),
                        ),
                        onStoryTapped: context.onStoryTapped,
                      ),
                    const ProfileScreen(),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    if (context.watch<SplitViewCubit>().state.enabled) {
      return ScreenTypeLayout.builder(
        mobile: (BuildContext context) {
          context.read<SplitViewCubit>().disableSplitView();
          return MobileHomeScreen(homeScreen: homeScreen);
        },
        tablet: (BuildContext context) {
          context.read<SplitViewCubit>().enableSplitView();
          return TabletHomeScreen(homeScreen: homeScreen);
        },
      );
    } else {
      context.read<SplitViewCubit>().disableSplitView();
      return MobileHomeScreen(homeScreen: homeScreen);
    }
  }

  Future<void> showFeatureDiscoveryDialog() async {
    final PreferenceRepository repo = locator.get<PreferenceRepository>();
    final bool hasSeen = await repo.hasSeenTour ?? false;
    if (!hasSeen) {
      repo.markTourAsCompleted();
      await FeatureDiscovery.clearPreferences(
        // ignore: use_build_context_synchronously
        context,
        DiscoverableFeature.values.map((DiscoverableFeature e) => e.featureId),
      );
      await showDialog<void>(
        // ignore: use_build_context_synchronously
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Welcome to Hacki!'),
          content: const Text('Take a quick tour to see what Hacki can do?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                context.pop();
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                context.pop();
                FeatureDiscovery.discoverFeatures(context, <String>{
                  DiscoverableFeature.login.featureId,
                  DiscoverableFeature.searchInThread.featureId,
                  DiscoverableFeature.pinToTop.featureId,
                  DiscoverableFeature.addStoryToFavList.featureId,
                  DiscoverableFeature.settingsShortcutOnItemScreen.featureId,
                  DiscoverableFeature.jumpUpButton.featureId,
                  DiscoverableFeature.jumpDownButton.featureId,
                });
              },
              child: const Text('Yes'),
            ),
          ],
        ),
      );
    }
  }

  void onShareExtensionTapped(List<SharedMediaFile>? event) {
    logInfo('share intent received: $event');

    if (event == null) return;

    final int? id = event.firstOrNull?.path.itemId;

    if (id != null) {
      locator.get<HackerNewsRepository>().fetchItem(id: id).then((Item? item) {
        logInfo('item fetched successfully: $item');
        if (item != null) {
          goToItemScreen(
            args: ItemScreenArgs(item: item),
            forceNewScreen: true,
          );
        }
      });
    }
  }

  Future<void> onSiriSuggestionTapped(String? id) async {
    if (id == null) return;
    final int? storyId = int.tryParse(id);
    if (storyId == null) return;

    await locator.get<HackerNewsRepository>().fetchStory(id: storyId).then((
      Story? story,
    ) {
      if (story == null) {
        showErrorSnackBar();
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

      await locator.get<HackerNewsRepository>().fetchStory(id: storyId).then((
        Story? story,
      ) {
        if (story == null) {
          showErrorSnackBar();
          return;
        }
        final ItemScreenArgs args = ItemScreenArgs(item: story);
        goToItemScreen(args: args);
      });
    }
  }

  @Deprecated('For debugging only')
  void clearFeatureDiscoveryPreferences(BuildContext context) {
    FeatureDiscovery.clearPreferences(context, <String>[
      DiscoverableFeature.login.featureId,
      DiscoverableFeature.addStoryToFavList.featureId,
      DiscoverableFeature.settingsShortcutOnItemScreen.featureId,
      DiscoverableFeature.pinToTop.featureId,
    ]);
  }

  @override
  String get logIdentifier => 'HomeScreen';
}
