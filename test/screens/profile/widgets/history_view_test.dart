import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/profile/widgets/history_view.dart';
import 'package:hacki/screens/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

class _MockHistoryCubit extends MockCubit<HistoryState>
    implements HistoryCubit {}

class _MockPreferenceCubit extends MockCubit<PreferenceState>
    implements PreferenceCubit {}

class _MockStoriesBloc extends MockBloc<StoriesEvent, StoriesState>
    implements StoriesBloc {}

class _MockSplitViewCubit extends MockCubit<SplitViewState>
    implements SplitViewCubit {}

final Story _firstStory = Story.fromJson(const <String, dynamic>{
  'id': 1,
  'type': 'story',
  'title': 'First visited story',
  'by': 'alice',
});

final Story _secondStory = Story.fromJson(const <String, dynamic>{
  'id': 2,
  'type': 'story',
  'title': 'Second visited story',
  'by': 'bob',
});

void main() {
  late _MockHistoryCubit historyCubit;
  late StreamController<HistoryState> historyChanges;

  setUpAll(() {
    registerFallbackValue(_firstStory);
  });

  setUp(() {
    historyCubit = _MockHistoryCubit();
    historyChanges = StreamController<HistoryState>.broadcast();
  });

  tearDown(() async {
    await historyChanges.close();
  });

  Future<void> pumpHistory(
    WidgetTester tester, {
    List<Story> stories = const <Story>[],
    ValueChanged<Story>? onItemTap,
  }) async {
    whenListen(
      historyCubit,
      historyChanges.stream,
      initialState: HistoryState(stories: stories, status: Status.success),
    );
    final _MockPreferenceCubit preferenceCubit = _MockPreferenceCubit();
    when(() => preferenceCubit.state).thenReturn(PreferenceState.init());
    final _MockStoriesBloc storiesBloc = _MockStoriesBloc();
    when(() => storiesBloc.hasRead(any())).thenReturn(false);
    final _MockSplitViewCubit splitViewCubit = _MockSplitViewCubit();
    when(() => splitViewCubit.state).thenReturn(const SplitViewState.init());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<HistoryCubit>.value(value: historyCubit),
          BlocProvider<PreferenceCubit>.value(value: preferenceCubit),
          BlocProvider<StoriesBloc>.value(value: storiesBloc),
          BlocProvider<SplitViewCubit>.value(value: splitViewCubit),
        ],
        child: MaterialApp(
          home: Scaffold(body: HistoryView(onItemTap: onItemTap ?? (_) {})),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder titleOf(Story story) => find.byWidgetPredicate(
    (Widget widget) => widget is Linkify && widget.text == story.title,
  );

  testWidgets('shows an empty history message', (WidgetTester tester) async {
    await pumpHistory(tester);

    expect(
      find.text('Your latest 50 visited stories will show up here.'),
      findsOneWidget,
    );
    expect(find.byType(ItemsListView<Story>), findsNothing);
  });

  testWidgets('shows compact story rows in history order', (
    WidgetTester tester,
  ) async {
    await pumpHistory(tester, stories: <Story>[_secondStory, _firstStory]);

    final ItemsListView<Story> list = tester.widget<ItemsListView<Story>>(
      find.byType(ItemsListView<Story>),
    );
    expect(list.shouldUseMinimalTileForStory, isTrue);
    expect(find.byType(StoryTile), findsNothing);
    expect(
      tester.getTopLeft(titleOf(_secondStory)).dy,
      lessThan(tester.getTopLeft(titleOf(_firstStory)).dy),
    );
    final SmartRefresher refresher = tester.widget<SmartRefresher>(
      find.byType(SmartRefresher),
    );
    expect(refresher.enablePullDown, isFalse);
    expect(refresher.controller.footerStatus, LoadStatus.noMore);
    list.onLoadMore!();
    await tester.pumpAndSettle();
    expect(refresher.controller.footerStatus, LoadStatus.noMore);
  });

  testWidgets('opens the story tapped in history', (WidgetTester tester) async {
    Story? openedStory;
    await pumpHistory(
      tester,
      stories: <Story>[_secondStory, _firstStory],
      onItemTap: (Story story) => openedStory = story,
    );

    await tester.tap(titleOf(_firstStory));
    await tester.pumpAndSettle();

    expect(openedStory, _firstStory);
  });

  testWidgets('reorders rows when a story is revisited', (
    WidgetTester tester,
  ) async {
    await pumpHistory(tester, stories: <Story>[_secondStory, _firstStory]);

    historyChanges.add(
      HistoryState(
        stories: <Story>[_firstStory, _secondStory],
        status: Status.success,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(titleOf(_firstStory)).dy,
      lessThan(tester.getTopLeft(titleOf(_secondStory)).dy),
    );
    expect(titleOf(_firstStory), findsOneWidget);
    expect(titleOf(_secondStory), findsOneWidget);
  });
}
