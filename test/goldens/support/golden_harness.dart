import 'dart:ui' as ui;

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:clock/clock.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/services/caches/comment_cache.dart';
import 'package:hacki/styles/styles.dart';
import 'package:logger/logger.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'fake_image_http.dart';
import 'fake_video_platform.dart';
import 'screen_fixtures.dart';

class GoldenScenario {
  const GoldenScenario(
    this.name,
    this.build, {
    this.covers = const <String>{},
    this.exercise,
    this.setup,
  });

  final String name;
  final Widget Function() build;
  final Set<String> covers;
  final Future<void> Function(WidgetTester)? exercise;
  final Future<void> Function()? setup;
}

class GoldenAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class GoldenStoriesBloc extends MockBloc<StoriesEvent, StoriesState>
    implements StoriesBloc {}

class GoldenBlocklistCubit extends MockCubit<BlocklistState>
    implements BlocklistCubit {}

class GoldenCommentsCubit extends MockCubit<CommentsState>
    implements CommentsCubit {}

class GoldenEditCubit extends MockCubit<EditState> implements EditCubit {}

class GoldenFavCubit extends MockCubit<FavState> implements FavCubit {}

class GoldenFilterCubit extends MockCubit<FilterState> implements FilterCubit {}

class GoldenHideCubit extends MockCubit<HideState> implements HideCubit {}

class GoldenHistoryCubit extends MockCubit<HistoryState>
    implements HistoryCubit {}

class GoldenNetworkProxyCubit extends MockCubit<NetworkProxyState>
    implements NetworkProxyCubit {}

class GoldenNotificationCubit extends MockCubit<NotificationState>
    implements NotificationCubit {}

class GoldenPinCubit extends MockCubit<PinState> implements PinCubit {}

class GoldenPollCubit extends MockCubit<PollState> implements PollCubit {}

class GoldenPostCubit extends MockCubit<PostState> implements PostCubit {}

class GoldenPreferenceCubit extends MockCubit<PreferenceState>
    implements PreferenceCubit {}

class GoldenReminderCubit extends MockCubit<ReminderState>
    implements ReminderCubit {}

class GoldenRemoteConfigCubit extends MockCubit<RemoteConfigState>
    implements RemoteConfigCubit {}

class GoldenReviewRequestCubit extends MockCubit<ReviewRequestState>
    implements ReviewRequestCubit {}

class GoldenSearchCubit extends MockCubit<SearchState> implements SearchCubit {}

class GoldenSplitViewCubit extends MockCubit<SplitViewState>
    implements SplitViewCubit {}

class GoldenSubmitCubit extends MockCubit<SubmitState> implements SubmitCubit {}

class GoldenTabCubit extends MockCubit<TabState> implements TabCubit {}

class GoldenThreadNavigationButtonCubit
    extends MockCubit<ThreadNavigationButtonState>
    implements ThreadNavigationButtonCubit {}

class GoldenTimeMachineCubit extends MockCubit<TimeMachineState>
    implements TimeMachineCubit {}

class GoldenTipsCubit extends MockCubit<TipsState> implements TipsCubit {}

class GoldenUserCubit extends MockCubit<UserState> implements UserCubit {}

class GoldenVoteCubit extends MockCubit<VoteState> implements VoteCubit {}

class GoldenPreferenceRepository extends Mock implements PreferenceRepository {}

class GoldenHackerNewsRepository extends Mock implements HackerNewsRepository {}

class GoldenHackerNewsWebRepository extends Mock
    implements HackerNewsWebRepository {}

class GoldenSembastRepository extends Mock implements SembastRepository {}

class GoldenPostRepository extends Mock implements PostRepository {}

class GoldenAuthRepository extends Mock implements AuthRepository {}

class GoldenOfflineRepository extends Mock implements OfflineRepository {}

const Key goldenKey = Key('matrix-golden');

/// Every scenario runs the complete Cartesian product. DPR affects both layout
/// and the rasterized PNG, rather than just being a label in the filename.
const Map<String, ui.Size> goldenSizes = <String, Size>{
  'compact': Size(320, 640),
  'phone': Size(390, 844),
  'tablet': Size(1024, 768),
};
const List<double> goldenPixelRatios = <double>[1, 2];
const Map<String, double> goldenTextScales = <String, double>{
  'small': 0.85,
  'regular': 1,
  'large': 1.5,
};

void testGoldens(String groupName, List<GoldenScenario> scenarios) {
  for (final GoldenScenario scenario in scenarios) {
    for (final TargetPlatform platform in <TargetPlatform>[
      TargetPlatform.android,
      TargetPlatform.iOS,
    ]) {
      for (final MapEntry<String, ui.Size> size in goldenSizes.entries) {
        for (final double ratio in goldenPixelRatios) {
          for (final MapEntry<String, double> scale
              in goldenTextScales.entries) {
            final String variant =
                '${platform.name}_${size.key}_dpr${ratio.toInt()}_${scale.key}';
            testWidgets(
              '$groupName / ${scenario.name} / $variant',
              (WidgetTester tester) => withClock(
                Clock.fixed(DateTime.utc(2026, 1, 15, 12)),
                () async {
                  debugDefaultTargetPlatformOverride = platform;
                  addTearDown(() => debugDefaultTargetPlatformOverride = null);
                  tester.view.devicePixelRatio = ratio;
                  tester.view.physicalSize = size.value * ratio;
                  tester.view.padding = FakeViewPadding(
                    top: 24 * ratio,
                    bottom: 16 * ratio,
                  );
                  addTearDown(tester.view.reset);
                  await _setUpDependencies();
                  await tester.runAsync(installGoldenImageHttp);
                  await scenario.setup?.call();
                  final FontSize fontSize = switch (scale.key) {
                    'small' => FontSize.small,
                    'large' => FontSize.xxlarge,
                    _ => FontSize.regular,
                  };
                  final GoldenPreferenceCubit preference =
                      GoldenPreferenceCubit();
                  when(() => preference.state).thenReturn(
                    PreferenceState.init()
                        .copyWithPreference(
                          FontSizePreference(val: fontSize.index),
                        )
                        .copyWithPreference(
                          TextScaleFactorPreference(val: scale.value),
                        ),
                  );
                  final ThemeData theme = AppTheme.theme(
                    ColorScheme.fromSeed(
                      seedColor: Palette.deepOrange,
                      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
                    ),
                    Font.robotoSlab,
                    isDarkModeEnabled: false,
                    isTrueDarkModeEnabled: false,
                  ).copyWith(platform: platform);
                  await tester.pumpWidget(
                    FeatureDiscovery.withProvider(
                      persistenceProvider: const NoPersistenceProvider(),
                      child: MultiBlocProvider(
                        providers: _providers(preference),
                        child: AdaptiveTheme(
                          light: theme,
                          dark: theme,
                          initial: AdaptiveThemeMode.light,
                          builder: (ThemeData light, ThemeData dark) =>
                              MaterialApp(
                                debugShowCheckedModeBanner: false,
                                theme: light,
                                darkTheme: dark,
                                locale: const Locale('en', 'US'),
                                navigatorObservers: <NavigatorObserver>[
                                  locator
                                      .get<
                                        RouteObserver<ModalRoute<dynamic>>
                                      >(),
                                ],
                                builder:
                                    (BuildContext context, Widget? child) =>
                                        MediaQuery(
                                          data: MediaQuery.of(context).copyWith(
                                            textScaler: TextScaler.linear(
                                              scale.value,
                                            ),
                                          ),
                                          child: RepaintBoundary(
                                            key: goldenKey,
                                            child: child,
                                          ),
                                        ),
                                home: Scaffold(
                                  body: Builder(
                                    builder: (_) => scenario.build(),
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                  );
                  // Fixed time supports perpetual spinners and shimmer.
                  await tester.pump();
                  await tester.pump(const Duration(milliseconds: 500));
                  await scenario.exercise?.call(tester);
                  await tester.runAsync(() async {
                    for (final Image asset in tester.widgetList<Image>(
                      find.byType(Image),
                    )) {
                      await precacheImage(
                        asset.image,
                        tester.element(find.byWidget(asset)),
                      );
                    }
                  });
                  await tester.pump();
                  await tester.pump(const Duration(milliseconds: 500));
                  final Set<String> mounted = tester.allWidgets
                      .map(
                        (Widget widget) =>
                            widget.runtimeType.toString().split('<').first,
                      )
                      .toSet();
                  for (final String covered in scenario.covers) {
                    expect(
                      mounted,
                      contains(covered.split('#').last),
                      reason:
                          '${scenario.name} claims $covered '
                          'but never mounted it',
                    );
                  }
                  final RenderRepaintBoundary boundary = tester
                      .renderObject<RenderRepaintBoundary>(
                        find.byKey(goldenKey),
                      );
                  final ui.Image image = await boundary.toImage(
                    pixelRatio: ratio,
                  );
                  try {
                    expect(image.width, (size.value.width * ratio).round());
                    expect(image.height, (size.value.height * ratio).round());
                    await expectLater(
                      image,
                      matchesGoldenFile(
                        'baselines/$groupName/${scenario.name}/$variant.png',
                      ),
                    );
                  } finally {
                    image.dispose();
                  }
                  await tester.pumpWidget(const SizedBox.shrink());
                  await tester.pump();
                },
              ),
              tags: <String>['golden'],
            );
          }
        }
      }
    }
  }
}

Future<void> _setUpDependencies() async {
  registerFallbackValue(ScreenComment());
  installGoldenPathProvider();
  await installGoldenVideoPlatform();
  await locator.reset();
  addTearDown(locator.reset);
  SharedPreferences.setMockInitialValues(<String, Object>{});
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  VisibilityDetectorController.instance.updateInterval = Duration.zero;
  locator
    ..registerSingleton<Logger>(Logger(level: Level.off))
    ..registerSingleton<RouteObserver<ModalRoute<dynamic>>>(
      RouteObserver<ModalRoute<dynamic>>(),
    );
  final GoldenPreferenceRepository preferences = GoldenPreferenceRepository();
  when(() => preferences.hasSeenTour).thenAnswer((_) async => true);
  when(() => preferences.username).thenAnswer((_) async => null);
  when(() => preferences.password).thenAnswer((_) async => null);
  when(() => preferences.loggedIn).thenAnswer((_) async => false);
  when(
    () => preferences.vote(
      submittedTo: any(named: 'submittedTo'),
      from: any(named: 'from'),
    ),
  ).thenAnswer((_) async => null);
  locator.registerSingleton<PreferenceRepository>(preferences);
  final GoldenHackerNewsRepository news = GoldenHackerNewsRepository();
  when(
    () => news.fetchUser(id: any(named: 'id')),
  ).thenAnswer((_) async => const User.empty());
  when(
    () => news.fetchItem(id: any(named: 'id')),
  ).thenAnswer((_) async => null);
  when(
    () => news.fetchPollOptionsStream(ids: any(named: 'ids')),
  ).thenAnswer((_) => const Stream<PollOption>.empty());
  locator
    ..registerSingleton<HackerNewsRepository>(news)
    ..registerSingleton<HackerNewsWebRepository>(
      GoldenHackerNewsWebRepository(),
    )
    ..registerSingleton<PostRepository>(GoldenPostRepository())
    ..registerSingleton<AuthRepository>(GoldenAuthRepository());
  final GoldenSembastRepository sembast = GoldenSembastRepository();
  when(
    () => sembast.getCachedMetadata(key: any(named: 'key')),
  ).thenAnswer((_) async => null);
  locator.registerSingleton<SembastRepository>(sembast);
  final GoldenOfflineRepository offline = GoldenOfflineRepository();
  when(
    () => offline.getHtml(url: any(named: 'url')),
  ).thenAnswer((_) async => null);
  locator
    ..registerSingleton<OfflineRepository>(offline)
    ..registerSingleton<CommentCache>(CommentCache());
  const MethodChannel sharing = MethodChannel(
    'receive_sharing_intent/messages',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('receive_sharing_intent/events-media'),
        (_) async => null,
      );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(sharing, (_) async => null);
}

List<BlocProvider<dynamic>> _providers(GoldenPreferenceCubit preference) {
  final GoldenAuthBloc auth = GoldenAuthBloc();
  when(() => auth.state).thenReturn(const AuthState.init());
  final GoldenStoriesBloc stories = GoldenStoriesBloc();
  when(() => stories.state).thenReturn(const StoriesState.init());
  registerFallbackValue(Story.placeholder());
  when(() => stories.hasRead(any())).thenReturn(false);
  final GoldenCommentsCubit comments = GoldenCommentsCubit();
  when(() => comments.state).thenReturn(
    CommentsState.init(
      isOfflineReading: false,
      item: Story.placeholder(),
      fetchMode: FetchMode.eager,
      order: CommentsOrder.natural,
    ),
  );
  when(() => comments.itemScrollController).thenReturn(ItemScrollController());
  when(
    () => comments.itemPositionsListener,
  ).thenReturn(ItemPositionsListener.create());
  when(() => comments.globalKeys).thenReturn(<int, GlobalKey>{});
  when(() => comments.currentTips).thenReturn('Tips for reading Hacker News');
  when(() => comments.hasNewComment).thenReturn(false);
  when(
    () => comments.collapsedCount(
      any(),
      countNewComments: any(named: 'countNewComments'),
    ),
  ).thenReturn((3, 1));
  when(() => comments.inThreadSearchOffset).thenReturn(0);
  final GoldenSearchCubit search = GoldenSearchCubit();
  when(() => search.state).thenReturn(SearchState.init());
  final TextEditingController searchController = TextEditingController();
  when(() => search.textEditingController).thenReturn(searchController);
  addTearDown(searchController.dispose);
  final GoldenBlocklistCubit blocklist = GoldenBlocklistCubit();
  when(() => blocklist.state).thenReturn(BlocklistState.init());
  final GoldenEditCubit edit = GoldenEditCubit();
  when(() => edit.state).thenReturn(const EditState.init());
  final GoldenFavCubit fav = GoldenFavCubit();
  when(() => fav.state).thenReturn(FavState.init());
  final GoldenFilterCubit filter = GoldenFilterCubit();
  when(() => filter.state).thenReturn(FilterState.init());
  final GoldenHideCubit hide = GoldenHideCubit();
  when(() => hide.state).thenReturn(HideState.init());
  final GoldenHistoryCubit history = GoldenHistoryCubit();
  when(() => history.state).thenReturn(HistoryState.init());
  final GoldenNetworkProxyCubit networkProxy = GoldenNetworkProxyCubit();
  when(() => networkProxy.state).thenReturn(
    const NetworkProxyState(
      proxy: NetworkProxy.none(),
      isAppliedToWebViews: true,
    ),
  );
  final GoldenNotificationCubit notification = GoldenNotificationCubit();
  when(() => notification.state).thenReturn(NotificationState.init());
  final GoldenPinCubit pin = GoldenPinCubit();
  when(() => pin.state).thenReturn(PinState.init());
  final GoldenPollCubit poll = GoldenPollCubit();
  when(() => poll.state).thenReturn(PollState.init());
  final GoldenPostCubit post = GoldenPostCubit();
  when(() => post.state).thenReturn(const PostState.init());
  final GoldenReminderCubit reminder = GoldenReminderCubit();
  when(() => reminder.state).thenReturn(const ReminderState.init());
  final GoldenRemoteConfigCubit remoteConfig = GoldenRemoteConfigCubit();
  when(() => remoteConfig.state).thenReturn(RemoteConfigState.init());
  final GoldenReviewRequestCubit reviewRequest = GoldenReviewRequestCubit();
  when(() => reviewRequest.state).thenReturn(
    ReviewRequestState(
      launchCounter: 1,
      firstRecordedLaunchDate: DateTime(2026),
      hasShown: true,
    ),
  );
  final GoldenSplitViewCubit splitView = GoldenSplitViewCubit();
  when(() => splitView.state).thenReturn(const SplitViewState.init());
  final GoldenSubmitCubit submit = GoldenSubmitCubit();
  when(() => submit.state).thenReturn(const SubmitState.init());
  final GoldenTabCubit tab = GoldenTabCubit();
  when(() => tab.state).thenReturn(const TabState(tabs: StoryType.values));
  final GoldenThreadNavigationButtonCubit threadNavigationButton =
      GoldenThreadNavigationButtonCubit();
  when(
    () => threadNavigationButton.state,
  ).thenReturn(ThreadNavigationButtonState.init());
  final GoldenTimeMachineCubit timeMachine = GoldenTimeMachineCubit();
  when(() => timeMachine.state).thenReturn(TimeMachineState.init());
  final GoldenTipsCubit tips = GoldenTipsCubit();
  when(() => tips.state).thenReturn(const TipsState.init());
  final GoldenUserCubit user = GoldenUserCubit();
  when(() => user.state).thenReturn(const UserState.init());
  final GoldenVoteCubit vote = GoldenVoteCubit();
  when(() => vote.state).thenReturn(VoteState.init(item: Story.placeholder()));
  when(() => reviewRequest.feelingLucky).thenReturn(false);
  return <BlocProvider<dynamic>>[
    BlocProvider<AuthBloc>.value(value: auth),
    BlocProvider<StoriesBloc>.value(value: stories),
    BlocProvider<BlocklistCubit>.value(value: blocklist),
    BlocProvider<CommentsCubit>.value(value: comments),
    BlocProvider<EditCubit>.value(value: edit),
    BlocProvider<FavCubit>.value(value: fav),
    BlocProvider<FilterCubit>.value(value: filter),
    BlocProvider<HideCubit>.value(value: hide),
    BlocProvider<HistoryCubit>.value(value: history),
    BlocProvider<NetworkProxyCubit>.value(value: networkProxy),
    BlocProvider<NotificationCubit>.value(value: notification),
    BlocProvider<PinCubit>.value(value: pin),
    BlocProvider<PollCubit>.value(value: poll),
    BlocProvider<PostCubit>.value(value: post),
    BlocProvider<PreferenceCubit>.value(value: preference),
    BlocProvider<ReminderCubit>.value(value: reminder),
    BlocProvider<RemoteConfigCubit>.value(value: remoteConfig),
    BlocProvider<ReviewRequestCubit>.value(value: reviewRequest),
    BlocProvider<SearchCubit>.value(value: search),
    BlocProvider<SplitViewCubit>.value(value: splitView),
    BlocProvider<SubmitCubit>.value(value: submit),
    BlocProvider<TabCubit>.value(value: tab),
    BlocProvider<ThreadNavigationButtonCubit>.value(
      value: threadNavigationButton,
    ),
    BlocProvider<TimeMachineCubit>.value(value: timeMachine),
    BlocProvider<TipsCubit>.value(value: tips),
    BlocProvider<UserCubit>.value(value: user),
    BlocProvider<VoteCubit>.value(value: vote),
  ];
}
