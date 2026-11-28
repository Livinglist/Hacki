import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/screens/widgets/story_tile.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockHistoryCubit extends MockCubit<HistoryState>
    implements HistoryCubit {}

class _MockPreferenceCubit extends MockCubit<PreferenceState>
    implements PreferenceCubit {}

class _MockStoriesBloc extends MockBloc<StoriesEvent, StoriesState>
    implements StoriesBloc {}

void main() {
  final Story story = Story.fromJson(const <String, dynamic>{
    'id': 100,
    'type': 'story',
    'title': 'An article opened directly',
    'by': 'alice',
    'url': 'https://example.com/article',
  });
  late _MockHistoryCubit historyCubit;
  late _MockPreferenceCubit preferenceCubit;
  late _MockStoriesBloc storiesBloc;

  setUp(() {
    historyCubit = _MockHistoryCubit();
    preferenceCubit = _MockPreferenceCubit();
    storiesBloc = _MockStoriesBloc();
    when(() => historyCubit.recordStory(story)).thenAnswer((_) async {});
    when(() => preferenceCubit.state).thenReturn(PreferenceState.init());
    when(() => storiesBloc.state).thenReturn(const StoriesState.init());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          (MethodCall call) async => false,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          null,
        );
  });

  Future<void> pumpTile(WidgetTester tester, {required bool favicon}) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<HistoryCubit>.value(value: historyCubit),
          BlocProvider<PreferenceCubit>.value(value: preferenceCubit),
          BlocProvider<StoriesBloc>.value(value: storiesBloc),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StoryTile(
              story: story,
              onTap: () {},
              shouldShowWebPreview: false,
              shouldShowPreviewImage: false,
              shouldShowMetadata: false,
              shouldShowFavicon: favicon,
              shouldShowUrl: false,
              isExpandedTileEnabled: false,
              isImageLeftAligned: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('long pressing a story records the directly opened article', (
    WidgetTester tester,
  ) async {
    await pumpTile(tester, favicon: false);

    await tester.longPress(find.byType(StoryTile));
    await tester.pumpAndSettle();

    verify(() => historyCubit.recordStory(story)).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a favicon records the directly opened article', (
    WidgetTester tester,
  ) async {
    await pumpTile(tester, favicon: true);
    final Finder favicon = find.byWidgetPredicate(
      (Widget widget) =>
          widget is GestureDetector &&
          widget.behavior == HitTestBehavior.opaque &&
          widget.onTap != null &&
          widget.onLongPress == null,
    );

    await tester.tap(favicon.last);
    await tester.pumpAndSettle();

    verify(() => historyCubit.recordStory(story)).called(1);
    expect(tester.takeException(), isNull);
  });
}
