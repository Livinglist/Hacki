import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_siri_suggestions/flutter_siri_suggestions.dart';
import 'package:go_router/go_router.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/config/locator.dart';
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
import 'package:hacki/utils/utils.dart';
import 'package:logger/logger.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:responsive_builder/responsive_builder.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static const String routeName = '/';

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, RouteAware, ItemActionMixin {
  late final TabController tabController;
  late final StreamSubscription<List<SharedMediaFile>>
      intentDataStreamSubscription;
  late final StreamSubscription<String?> notificationStreamSubscription;
  late final StreamSubscription<String?> siriSuggestionStreamSubscription;

  static final int tabLength = StoryType.values.length + 1;

  @override
  void didPopNext() {
    super.didPopNext();
    if (context.read<StoriesBloc>().deviceScreenType ==
        DeviceScreenType.mobile) {
      locator.get<Logger>().i('resetting comments in CommentCache');
      Future<void>.delayed(
        AppDurations.ms500,
        locator.get<CommentCache>().resetComments,
      );
    }
  }

  @override
  void initState() {
    super.initState();

    ReceiveSharingIntent.getInitialMedia().then(onShareExtensionTapped);

    intentDataStreamSubscription =
        ReceiveSharingIntent.getMediaStream().listen(onShareExtensionTapped);

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
        FeatureDiscovery.discoverFeatures(
          context,
          <String>{
            DiscoverableFeature.login.featureId,
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

    tabController = TabController(length: tabLength, vsync: this);
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
          previous.complexStoryTileEnabled != current.complexStoryTileEnabled ||
          previous.metadataEnabled != current.metadataEnabled ||
          previous.swipeGestureEnabled != current.swipeGestureEnabled,
      builder: (BuildContext context, PreferenceState preferenceState) {
        return DefaultTabController(
          length: tabLength,
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
                  CustomTabBar(
                    tabController: tabController,
                  ),
                ],
              ),
            ),
            body: BlocBuilder<TabCubit, TabState>(
              builder: (BuildContext context, TabState state) {
                return TabBarView(
                  physics: preferenceState.swipeGestureEnabled
                      ? const PageScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  controller: tabController,
                  children: <Widget>[
                    for (final StoryType type in state.tabs)
                      StoriesListView(
                        key: ValueKey<StoryType>(type),
                        storyType: type,
                        header: PinnedStories(
                          preferenceState: preferenceState,
                          onStoryTapped: onStoryTapped,
                        ),
                        onStoryTapped: onStoryTapped,
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

    return ScreenTypeLayout.builder(
      mobile: (BuildContext context) {
        context.read<SplitViewCubit>().disableSplitView();
        return MobileHomeScreen(
          homeScreen: homeScreen,
        );
      },
      tablet: (BuildContext context) => TabletHomeScreen(
        homeScreen: homeScreen,
      ),
    );
  }

  void onStoryTapped(Story story) {
    final PreferenceState prefState = context.read<PreferenceCubit>().state;
    final bool useReader = prefState.readerEnabled;
    final StoryMarkingMode storyMarkingMode = prefState.storyMarkingMode;
    final bool offlineReading =
        context.read<StoriesBloc>().state.isOfflineReading;
    final bool splitViewEnabled = context.read<SplitViewCubit>().state.enabled;
    final bool markReadStoriesEnabled = prefState.markReadStoriesEnabled;

    // If a story is a job story and it has a link to the job posting,
    // it would be better to just navigate to the web page.
    final bool isJobWithLink = story.isJob && story.url.isNotEmpty;

    if (isJobWithLink) {
      context.read<ReminderCubit>().removeLastReadStoryId();
    } else {
      final bool shouldMarkNewComment = markReadStoriesEnabled &&
          context.read<StoriesBloc>().state.readStoriesIds.contains(story.id);
      final ItemScreenArgs args = ItemScreenArgs(
        item: story,
        shouldMarkNewComment: shouldMarkNewComment,
      );

      context.read<ReminderCubit>().updateLastReadStoryId(story.id);

      if (splitViewEnabled) {
        context.read<SplitViewCubit>().updateItemScreenArgs(args);
      } else {
        context.push('/${ItemScreen.routeName}', extra: args);
      }
    }

    if (story.url.isNotEmpty && isJobWithLink) {
      LinkUtil.launch(
        story.url,
        context,
        useReader: useReader,
        offlineReading: offlineReading,
      );
    }

    if (markReadStoriesEnabled && storyMarkingMode.shouldDetectTapping) {
      context.read<StoriesBloc>().add(StoryRead(story: story));
    }

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

  void onShareExtensionTapped(List<SharedMediaFile> files) {
    final SharedMediaFile? file = files.firstOrNull;

    if (file?.type != SharedMediaType.text || file?.message == null) return;

    final String message = file!.message!;
    final int? id = message.itemId;

    if (id != null) {
      locator.get<HackerNewsRepository>().fetchItem(id: id).then((Item? item) {
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
        .get<HackerNewsRepository>()
        .fetchStory(id: storyId)
        .then((Story? story) {
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

      await locator
          .get<HackerNewsRepository>()
          .fetchStory(id: storyId)
          .then((Story? story) {
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
      DiscoverableFeature.openStoryInWebView.featureId,
      DiscoverableFeature.pinToTop.featureId,
    ]);
  }
}
