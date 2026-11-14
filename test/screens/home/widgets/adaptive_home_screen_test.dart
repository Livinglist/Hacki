import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/home/widgets/adaptive_home_screen.dart';
import 'package:hacki/screens/item/item_screen.dart';
import 'package:hacki/styles/styles.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements Storage {}

class _MockPreferenceCubit extends MockCubit<PreferenceState>
    implements PreferenceCubit {}

class _MockStoriesBloc extends MockBloc<StoriesEvent, StoriesState>
    implements StoriesBloc {}

class _MockReminderCubit extends MockCubit<ReminderState>
    implements ReminderCubit {}

const Key _feedKey = Key('feed-pane');
const Key _detailKey = Key('detail-pane');

class _ReadingPane extends StatefulWidget {
  const _ReadingPane({required this.label, super.key});

  final String label;

  @override
  State<_ReadingPane> createState() => _ReadingPaneState();
}

class _ReadingPaneState extends State<_ReadingPane> {
  final ScrollController controller = ScrollController();
  int count = 0;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: <Widget>[
            Text('${widget.label}: $count'),
            TextButton(
              onPressed: () => setState(() => count++),
              child: Text('Increment ${widget.label}'),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: 40,
                itemExtent: 60,
                itemBuilder: (_, int index) =>
                    Text('${widget.label} row $index'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  late _MockStorage storage;
  late _MockPreferenceCubit preferenceCubit;
  late _MockStoriesBloc storiesBloc;
  late _MockReminderCubit reminderCubit;
  late StreamController<PreferenceState> preferences;
  late SplitViewCubit splitViewCubit;

  PreferenceState preference({required bool splitView}) =>
      PreferenceState.init()
          .copyWithPreference(SplitViewPreference(val: splitView))
          .copyWith(status: Status.success);

  setUp(() {
    storage = _MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
    preferenceCubit = _MockPreferenceCubit();
    preferences = StreamController<PreferenceState>.broadcast(sync: true);
    storiesBloc = _MockStoriesBloc();
    when(() => storiesBloc.state).thenReturn(const StoriesState.init());
    reminderCubit = _MockReminderCubit();
    when(
      () => reminderCubit.state,
    ).thenReturn(const ReminderState(storyId: null, hasShown: true));
  });

  tearDown(() => preferences.close());

  Future<void> resize(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    await tester.pumpAndSettle();
  }

  Future<void> pumpHome(
    WidgetTester tester, {
    Size size = const Size(890, 626),
    bool splitView = true,
    bool asPushedRoute = false,
    double? contentWidth,
    EdgeInsets padding = EdgeInsets.zero,
    Widget Function(BuildContext, ItemScreenArgs)? detailBuilder,
  }) async {
    whenListen(
      preferenceCubit,
      preferences.stream,
      initialState: preference(splitView: splitView),
    );
    splitViewCubit = SplitViewCubit(preferenceCubit: preferenceCubit);
    addTearDown(splitViewCubit.close);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      // The existing countdown widget schedules its start three seconds later.
      await tester.pump(const Duration(seconds: 3));
    });

    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    final Widget home = Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: contentWidth,
          child: AdaptiveHomeScreen(
            homeScreen: const _ReadingPane(label: 'feed', key: _feedKey),
            detailBuilder:
                detailBuilder ??
                (_, ItemScreenArgs args) => _ReadingPane(
                  label: 'thread ${args.item.id}',
                  key: _detailKey,
                ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<PreferenceCubit>.value(value: preferenceCubit),
          BlocProvider<SplitViewCubit>.value(value: splitViewCubit),
          BlocProvider<StoriesBloc>.value(value: storiesBloc),
          BlocProvider<ReminderCubit>.value(value: reminderCubit),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: AppTheme.theme(
            ColorScheme.fromSeed(seedColor: Palette.deepOrange),
            Font.robotoSlab,
            isDarkModeEnabled: false,
            isTrueDarkModeEnabled: false,
          ),
          builder: (BuildContext context, Widget? child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(padding: padding, viewPadding: padding),
            child: child!,
          ),
          home: asPushedRoute
              ? const Scaffold(body: Text('Landing page'))
              : home,
        ),
      ),
    );
    if (asPushedRoute) {
      unawaited(
        navigatorKey.currentState!.push<void>(
          MaterialPageRoute<void>(builder: (_) => home),
        ),
      );
    }
    await tester.pumpAndSettle();
  }

  ItemScreenArgs selectStory() {
    final ItemScreenArgs args = ItemScreenArgs(
      item: Story.fromJson(const <String, dynamic>{
        'id': 42,
        'by': 'author',
        'title': 'A story',
      }),
    );
    splitViewCubit.updateItemScreenArgs(args);
    return args;
  }

  testWidgets('folding preserves the feed and selected thread in one session', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester, size: const Size(466, 678));
    expect(splitViewCubit.state.enabled, isFalse);
    expect(tester.getSize(find.byKey(_feedKey)).width, 466);
    final _ReadingPaneState feedState = tester.state(find.byKey(_feedKey));
    await tester.tap(find.text('Increment feed'));
    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pumpAndSettle();
    final double feedOffset = feedState.controller.offset;
    expect(feedOffset, greaterThan(0));

    await resize(tester, const Size(890, 626));
    expect(splitViewCubit.state.enabled, isTrue);
    expect(tester.state(find.byKey(_feedKey)), same(feedState));
    expect(feedState.controller.offset, closeTo(feedOffset, 0.01));
    expect(tester.getSize(find.byKey(_feedKey)).width, lessThan(890));

    final ItemScreenArgs args = selectStory();
    await tester.pumpAndSettle();
    final _ReadingPaneState detailState = tester.state(find.byKey(_detailKey));
    await tester.tap(find.text('Increment thread 42'));
    final Finder detailList = find.descendant(
      of: find.byKey(_detailKey),
      matching: find.byType(ListView),
    );
    await tester.drag(detailList, const Offset(0, -180));
    await tester.pumpAndSettle();
    final double detailOffset = detailState.controller.offset;
    expect(detailOffset, greaterThan(0));

    await resize(tester, const Size(466, 678));
    expect(splitViewCubit.state.enabled, isFalse);
    expect(splitViewCubit.state.itemScreenArgs, same(args));
    expect(tester.state(find.byKey(_detailKey)), same(detailState));
    expect(tester.getSize(find.byKey(_detailKey)).width, 466);
    expect(find.text('thread 42: 1'), findsOneWidget);
    expect(detailState.controller.offset, closeTo(detailOffset, 0.01));

    await tester.tap(find.byTooltip('Back to stories'));
    await tester.pumpAndSettle();
    expect(find.text('feed: 1'), findsOneWidget);
    expect(tester.state(find.byKey(_feedKey)), same(feedState));
    expect(feedState.controller.offset, closeTo(feedOffset, 0.01));
    expect(splitViewCubit.state.itemScreenArgs, same(args));

    await resize(tester, const Size(890, 626));
    expect(splitViewCubit.state.enabled, isTrue);
    expect(tester.state(find.byKey(_detailKey)), same(detailState));
    expect(find.text('thread 42: 1'), findsOneWidget);
    expect(find.text('feed: 1'), findsOneWidget);
    expect(detailState.controller.offset, closeTo(detailOffset, 0.01));

    await resize(tester, const Size(626, 890));
    expect(splitViewCubit.state.enabled, isTrue);
    expect(
      tester.getSize(find.byKey(_detailKey)).width,
      greaterThanOrEqualTo(280),
    );
    expect(tester.state(find.byKey(_detailKey)), same(detailState));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the split-view preference changes the layout without relaunch', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester, size: const Size(1024, 768), splitView: false);
    expect(splitViewCubit.state.enabled, isFalse);
    expect(tester.getSize(find.byKey(_feedKey)).width, 1024);

    preferences.add(preference(splitView: true));
    await tester.pumpAndSettle();
    expect(splitViewCubit.state.enabled, isTrue);
    expect(tester.getSize(find.byKey(_feedKey)).width, lessThan(1024));

    preferences.add(preference(splitView: false));
    await tester.pumpAndSettle();
    expect(splitViewCubit.state.enabled, isFalse);
    expect(tester.getSize(find.byKey(_feedKey)).width, 1024);

    await resize(tester, const Size(466, 678));
    await resize(tester, const Size(890, 626));
    expect(splitViewCubit.state.enabled, isFalse);
    expect(tester.getSize(find.byKey(_feedKey)).width, 890);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system Back restores split view then the compact feed', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester, asPushedRoute: true);
    final _ReadingPaneState feedState = tester.state(find.byKey(_feedKey));
    await tester.tap(find.text('Increment feed'));
    final ItemScreenArgs args = selectStory();
    await tester.pumpAndSettle();
    final _ReadingPaneState detailState = tester.state(find.byKey(_detailKey));
    await tester.tap(find.text('Increment thread 42'));

    splitViewCubit.zoom();
    await tester.pumpAndSettle();
    expect(splitViewCubit.state.expanded, isTrue);
    expect(tester.getSize(find.byKey(_detailKey)).width, 890);
    expect(find.byKey(_feedKey), findsNothing);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(splitViewCubit.state.expanded, isFalse);
    expect(splitViewCubit.state.itemScreenArgs, same(args));
    expect(tester.state(find.byKey(_detailKey)), same(detailState));
    expect(tester.state(find.byKey(_feedKey)), same(feedState));
    expect(find.text('feed: 1'), findsOneWidget);
    expect(find.text('thread 42: 1'), findsOneWidget);
    expect(find.text('Landing page'), findsNothing);

    await resize(tester, const Size(466, 678));
    expect(splitViewCubit.state.showDetail, isTrue);
    expect(find.text('thread 42: 1'), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(splitViewCubit.state.showDetail, isFalse);
    expect(splitViewCubit.state.itemScreenArgs, same(args));
    expect(tester.state(find.byKey(_feedKey)), same(feedState));
    expect(
      tester.state(find.byKey(_detailKey, skipOffstage: false)),
      same(detailState),
    );
    expect(find.text('feed: 1'), findsOneWidget);
    expect(find.text('Landing page'), findsNothing);

    // The Home route can still pop after its compact feed is restored.
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Landing page'), findsOneWidget);
    expect(find.byType(AdaptiveHomeScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses local window constraints instead of the physical screen', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester, size: const Size(1024, 800), contentWidth: 512);

    expect(splitViewCubit.state.enabled, isFalse);
    expect(tester.getSize(find.byKey(_feedKey)).width, 512);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a thread stack without intrinsic width fills its detail pane', (
    WidgetTester tester,
  ) async {
    await pumpHome(
      tester,
      detailBuilder: (_, _) => const Stack(
        key: _detailKey,
        children: <Widget>[
          Positioned.fill(child: Material(child: Text('Positioned thread'))),
          // ItemScreen has a hidden, non-positioned history-button widget.
          // That overlay supplies no intrinsic width to its surrounding Stack.
          SizedBox.shrink(),
        ],
      ),
    );
    selectStory();
    await tester.pumpAndSettle();

    for (final Size size in <Size>[
      const Size(890, 626),
      const Size(466, 678),
      const Size(626, 890),
      const Size(1024, 768),
    ]) {
      await resize(tester, size);
      final Rect detail = tester.getRect(find.byKey(_detailKey));
      if (splitViewCubit.state.enabled) {
        final Rect feed = tester.getRect(find.byKey(_feedKey));
        expect(detail.left, closeTo(feed.right + 2, 0.01));
        expect(detail.width, closeTo(size.width - feed.width - 2, 0.01));
      } else {
        expect(detail.width, closeTo(size.width, 0.01));
      }
      expect(detail.width, greaterThan(0));
      expect(detail.right, closeTo(size.width, 0.01));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'a restored wide sidebar leaves space for the detail after resize',
    (WidgetTester tester) async {
      when(
        () => storage.read(any()),
      ).thenReturn(<String, dynamic>{'submissionPanelWidth': 2000.0});
      await pumpHome(tester);
      selectStory();
      await tester.pumpAndSettle();

      for (final Size size in <Size>[
        const Size(890, 626),
        const Size(626, 890),
        const Size(1024, 768),
      ]) {
        await resize(tester, size);
        final Rect feed = tester.getRect(find.byKey(_feedKey));
        final Rect detail = tester.getRect(find.byKey(_detailKey));
        expect(feed.width, greaterThanOrEqualTo(280));
        expect(detail.width, greaterThanOrEqualTo(280));
        expect(feed.overlaps(detail), isFalse);
        expect(detail.right, closeTo(size.width, 0.01));
        expect(splitViewCubit.state.submissionPanelWidth, 2000);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('keeps both panes inside the current horizontal safe areas', (
    WidgetTester tester,
  ) async {
    await pumpHome(tester, padding: const EdgeInsets.only(left: 32, right: 44));
    selectStory();
    await tester.pumpAndSettle();

    expect(splitViewCubit.state.enabled, isTrue);
    final Rect feed = tester.getRect(find.byKey(_feedKey));
    final Rect detail = tester.getRect(find.byKey(_detailKey));
    expect(feed.left, 32);
    expect(detail.right, 846);
    expect(feed.overlaps(detail), isFalse);
    expect(tester.takeException(), isNull);
  });
}
