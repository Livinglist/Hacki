import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/home/home_screen.dart';
import 'package:hacki/screens/home/widgets/pinned_stories.dart';
import 'package:hacki/screens/home/widgets/review_request_bottom_sheet.dart';
import 'package:hacki/screens/home/widgets/tablet_home_screen.dart';
import 'package:hacki/screens/profile/profile_screen.dart';
import 'package:hacki/screens/profile/widgets/favorites_screen.dart';
import 'package:hacki/screens/profile/widgets/inbox_view.dart';
import 'package:hacki/screens/widgets/custom_tab_bar.dart';
import 'package:hacki/screens/widgets/stories_list_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import 'support/golden_harness.dart';

class _Stories extends MockBloc<StoriesEvent, StoriesState>
    implements StoriesBloc {}

class _Tabs extends MockCubit<TabState> implements TabCubit {}

class _Split extends MockCubit<SplitViewState> implements SplitViewCubit {}

class _Reminder extends MockCubit<ReminderState> implements ReminderCubit {}

class _Review extends MockCubit<ReviewRequestState>
    implements ReviewRequestCubit {}

class _Auth extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class _Notifications extends MockCubit<NotificationState>
    implements NotificationCubit {}

class _History extends MockCubit<HistoryState> implements HistoryCubit {}

class _Favorites extends MockCubit<FavState> implements FavCubit {}

class _Pins extends MockCubit<PinState> implements PinCubit {}

// Freeze relative labels as well as the underlying timestamps. Golden files
// must not change because a fixture is one day older on the next CI run.
class _Story extends Story {
  const _Story(int id, String title)
    : super(
        id: id,
        title: title,
        descendants: 24,
        score: 123,
        time: 1700000000,
        by: 'golden_reader',
        type: 'story',
        url: '',
        text: 'A discussion about building thoughtful software.',
        kids: const <int>[],
        parts: const <int>[],
        hidden: false,
      );

  @override
  String get timeAgo => '2 hours ago';

  @override
  String get shortTimeAgo => '2h';
}

class _Comment extends Comment {
  _Comment(int id, String author, String text)
    : super(
        id: id,
        time: 1700000000,
        parent: 100,
        score: 5,
        by: author,
        text: text,
        kids: <int>[],
        dead: false,
        deleted: false,
        hidden: false,
        level: 0,
        isFromCache: false,
      );

  @override
  String get timeAgo => '2 hours ago';

  @override
  String get shortTimeAgo => '2h';
}

const List<Story> _stories = <Story>[
  _Story(100, 'Show HN: A small tool for a quieter internet'),
  _Story(101, 'Designing software that remains useful for a decade'),
  _Story(102, 'Ask HN: What did you learn while building your first app?'),
];

final List<Comment> _comments = <Comment>[
  _Comment(200, 'ada', 'This is a thoughtful approach. Thanks for sharing!'),
  _Comment(201, 'grace', 'The details are available at https://example.com.'),
];

const Set<String> _homeCoverage = <String>{
  'lib/screens/home/home_screen.dart#HomeScreen',
  'lib/screens/home/widgets/mobile_home_screen.dart#MobileHomeScreen',
  'lib/screens/widgets/custom_tab_bar.dart#CustomTabBar',
  'lib/screens/widgets/stories_list_view.dart#StoriesListView',
  'lib/screens/widgets/items_list_view.dart#ItemsListView',
  'lib/screens/widgets/story_tile.dart#StoryTile',
};

const Set<String> _profileCoverage = <String>{
  'lib/screens/profile/profile_screen.dart#ProfileScreen',
  'lib/screens/widgets/custom_chip.dart#CustomChip',
};

Widget _fixture(
  Widget child, {
  bool signedIn = false,
  bool empty = false,
  bool offline = false,
  bool downloading = false,
  bool split = false,
  double? splitWidth,
  FavState? favorites,
  NotificationState? notifications,
  List<Story> pins = const <Story>[],
}) {
  final _Stories stories = _Stories();
  final StoriesState storiesState = const StoriesState.init().copyWith(
    storiesByType: <StoryType, List<Story>>{
      for (final StoryType type in StoryType.values)
        type: empty ? <Story>[] : _stories,
    },
    statusByType: <StoryType, Status>{
      for (final StoryType type in StoryType.values) type: Status.success,
    },
    isOfflineReading: offline,
    downloadStatus: downloading
        ? StoriesDownloadStatus.downloading
        : StoriesDownloadStatus.idle,
    storiesDownloaded: downloading ? 4 : 0,
    storiesToBeDownloaded: downloading ? 10 : 0,
  );
  when(() => stories.state).thenReturn(storiesState);
  when(() => stories.hasRead(any())).thenReturn(false);
  final _Tabs tabs = _Tabs();
  when(() => tabs.state).thenReturn(const TabState(tabs: StoryType.values));
  final _Split splitView = _Split();
  when(() => splitView.state).thenReturn(
    const SplitViewState.init().copyWith(
      enabled: split,
      submissionPanelWidth: splitWidth,
    ),
  );
  final _Reminder reminder = _Reminder();
  when(
    () => reminder.state,
  ).thenReturn(const ReminderState.init().copyWith(hasShown: true));
  final _Review review = _Review();
  when(
    () => review.state,
  ).thenReturn(ReviewRequestState.init().copyWith(hasShown: true));
  final _Auth auth = _Auth();
  when(() => auth.state).thenReturn(
    const AuthState.init().copyWith(
      isLoggedIn: signedIn,
      user: signedIn ? const User.emptyWithId('golden_reader') : null,
    ),
  );
  final _Notifications inbox = _Notifications();
  when(() => inbox.state).thenReturn(
    notifications ??
        NotificationState.init().copyWith(
          comments: empty ? <Comment>[] : _comments,
          unreadCommentsIds: empty ? <int>[] : <int>[200],
          status: Status.success,
        ),
  );
  final _History history = _History();
  when(() => history.state).thenReturn(
    HistoryState.init().copyWith(
      submittedItems: empty ? <Item>[] : <Item>[..._stories, ..._comments],
      status: Status.success,
    ),
  );
  final _Favorites fav = _Favorites();
  when(() => fav.state).thenReturn(
    favorites ??
        FavState.init().copyWith(
          favItems: empty ? <Item>[] : <Item>[..._stories, ..._comments],
          status: Status.success,
        ),
  );
  final _Pins pin = _Pins();
  when(
    () => pin.state,
  ).thenReturn(PinState.init().copyWith(pinnedStories: pins));
  return MultiBlocProvider(
    providers: <BlocProvider<dynamic>>[
      BlocProvider<StoriesBloc>.value(value: stories),
      BlocProvider<TabCubit>.value(value: tabs),
      BlocProvider<SplitViewCubit>.value(value: splitView),
      BlocProvider<ReminderCubit>.value(value: reminder),
      BlocProvider<ReviewRequestCubit>.value(value: review),
      BlocProvider<AuthBloc>.value(value: auth),
      BlocProvider<NotificationCubit>.value(value: inbox),
      BlocProvider<HistoryCubit>.value(value: history),
      BlocProvider<FavCubit>.value(value: fav),
      BlocProvider<PinCubit>.value(value: pin),
    ],
    child: child,
  );
}

Future<void> _selectProfileTab(WidgetTester tester, String label) async {
  final Finder chip = find.text(label);
  await tester.ensureVisible(chip);
  await tester.tap(chip);
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  registerFallbackValue(_stories.first);

  testGoldens('home', <GoldenScenario>[
    for (int i = 0; i < StoryType.values.length; i++)
      GoldenScenario(
        'stories_${StoryType.values[i].name}',
        () => _fixture(const HomeScreen()),
        covers: _homeCoverage,
        exercise: (WidgetTester tester) async {
          tester
                  .widget<CustomTabBar>(find.byType(CustomTabBar))
                  .tabController
                  .index =
              i;
          await tester.pump(const Duration(seconds: 1));
        },
      ),
    GoldenScenario(
      'empty',
      () => _fixture(const HomeScreen(), empty: true),
      covers: <String>{
        ..._homeCoverage.where((String s) => !s.endsWith('#StoryTile')),
      },
    ),
    GoldenScenario(
      'offline',
      () => _fixture(const HomeScreen(), offline: true),
      covers: <String>{
        ..._homeCoverage,
        'lib/screens/widgets/offline_banner.dart#OfflineBanner',
      },
    ),
    GoldenScenario(
      'download_progress',
      () => _fixture(const HomeScreen(), downloading: true),
      covers: <String>{
        ..._homeCoverage,
        'lib/screens/widgets/download_progress_reminder.dart#DownloadProgressReminder',
      },
    ),
    GoldenScenario(
      'adaptive_split_view',
      () => _fixture(const HomeScreen(), split: true),
      covers: <String>{
        ..._homeCoverage.where((String s) => !s.endsWith('#MobileHomeScreen')),
      },
    ),
    GoldenScenario(
      'tablet_split_chrome',
      () => Builder(
        builder: (BuildContext context) => _fixture(
          TabletHomeScreen(
            homeScreen: Scaffold(
              body: StoriesListView(
                storyType: StoryType.top,
                header: const SizedBox.shrink(),
                onStoryTapped: (_) {},
              ),
            ),
          ),
          split: true,
          splitWidth: MediaQuery.sizeOf(context).width * 0.45,
        ),
      ),
      covers: const <String>{
        'lib/screens/home/widgets/tablet_home_screen.dart#TabletHomeScreen',
        'lib/screens/home/widgets/tablet_home_screen.dart#_TabletStoryView',
        'lib/screens/widgets/stories_list_view.dart#StoriesListView',
      },
    ),
    GoldenScenario(
      'pinned_stories',
      () => _fixture(
        SingleChildScrollView(
          child: Builder(
            builder: (BuildContext context) => PinnedStories(
              preferenceState: context.read<PreferenceCubit>().state,
              onStoryTapped: (_) {},
            ),
          ),
        ),
        pins: _stories,
      ),
      covers: const <String>{
        'lib/screens/home/widgets/pinned_stories.dart#PinnedStories',
      },
    ),
    GoldenScenario(
      'review_request',
      () => const Align(
        alignment: Alignment.bottomCenter,
        child: ReviewRequestBottomSheet(),
      ),
      covers: const <String>{
        'lib/screens/home/widgets/review_request_bottom_sheet.dart#ReviewRequestBottomSheet',
      },
    ),
  ]);

  testGoldens('profile', <GoldenScenario>[
    GoldenScenario(
      'guest_favorites_empty',
      () => _fixture(const ProfileScreen(), empty: true),
      covers: <String>{
        ..._profileCoverage,
        'lib/screens/profile/widgets/favorites_screen.dart#FavoritesScreen',
        'lib/screens/profile/widgets/centered_message_view.dart#CenteredMessageView',
      },
    ),
    GoldenScenario(
      'member_inbox',
      () => _fixture(const ProfileScreen(), signedIn: true),
      covers: <String>{
        ..._profileCoverage,
        'lib/screens/profile/widgets/inbox_view.dart#InboxView',
      },
    ),
    GoldenScenario(
      'member_inbox_empty',
      () => _fixture(const ProfileScreen(), signedIn: true, empty: true),
      covers: <String>{
        ..._profileCoverage,
        'lib/screens/profile/widgets/centered_message_view.dart#CenteredMessageView',
      },
    ),
    GoldenScenario(
      'member_favorites',
      () => _fixture(const ProfileScreen(), signedIn: true),
      covers: <String>{
        ..._profileCoverage,
        'lib/screens/profile/widgets/favorites_screen.dart#FavoritesScreen',
      },
      exercise: (WidgetTester tester) => _selectProfileTab(tester, 'Favorite'),
    ),
    GoldenScenario(
      'member_submitted',
      () => _fixture(const ProfileScreen(), signedIn: true),
      covers: _profileCoverage,
      exercise: (WidgetTester tester) => _selectProfileTab(tester, 'Submitted'),
    ),
    GoldenScenario(
      'favorite_comments',
      () => _fixture(
        FavoritesScreen(
          refreshController: RefreshController(),
          authState: const AuthState.init(),
          onItemTap: (_) {},
        ),
        favorites: FavState.init().copyWith(
          favItems: _comments,
          isDisplayingStories: false,
          status: Status.success,
        ),
      ),
      covers: const <String>{
        'lib/screens/profile/widgets/favorites_screen.dart#FavoritesScreen',
      },
    ),
    GoldenScenario(
      'favorites_syncing',
      () => _fixture(
        FavoritesScreen(
          refreshController: RefreshController(),
          authState: const AuthState.init().copyWith(isLoggedIn: true),
          onItemTap: (_) {},
        ),
        favorites: FavState.init().copyWith(mergeStatus: Status.inProgress),
      ),
      covers: const <String>{
        'lib/screens/profile/widgets/favorites_screen.dart#FavoritesScreen',
      },
    ),
    GoldenScenario(
      'inbox_read_and_unread',
      () => _fixture(
        InboxView(
          refreshController: RefreshController(),
          comments: _comments,
          unreadCommentsIds: const <int>[200],
          onCommentTapped: (_) {},
          onMarkAllAsReadTapped: () {},
          onLoadMore: () {},
          onRefresh: () {},
        ),
      ),
      covers: const <String>{
        'lib/screens/profile/widgets/inbox_view.dart#InboxView',
      },
    ),
  ]);
}
