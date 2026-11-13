import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/preference_repository.dart';
import 'package:hacki/screens/item/widgets/custom_app_bar.dart';
import 'package:hacki/screens/widgets/tips/item_screen_tips.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../../../goldens/support/fake_video_platform.dart';

class _Preferences extends Mock implements PreferenceRepository {}

class _Favorites extends MockCubit<FavState> implements FavCubit {}

class _RecordingVideoPlatform extends GoldenVideoPlatform {
  final List<int> played = <int>[];
  final List<int> disposed = <int>[];
  final StreamController<VideoEvent> events =
      StreamController<VideoEvent>.broadcast();

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    scheduleMicrotask(
      () => events.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 30),
          size: const Size(360, 640),
        ),
      ),
    );
    return events.stream;
  }

  @override
  Future<void> play(int playerId) async => played.add(playerId);

  @override
  Future<void> dispose(int playerId) async {
    disposed.add(playerId);
  }
}

void main() {
  testWidgets('keeps the tips video alive until its route closes', (
    WidgetTester tester,
  ) async {
    final VideoPlayerPlatform previousPlatform = VideoPlayerPlatform.instance;
    final _RecordingVideoPlatform video = _RecordingVideoPlatform();
    addTearDown(video.events.close);
    VideoPlayerPlatform.instance = video;
    addTearDown(() => VideoPlayerPlatform.instance = previousPlatform);

    final _Preferences preferences = _Preferences();
    when(() => preferences.getBool(any())).thenAnswer((_) async => false);
    final TipsCubit tips = TipsCubit(preferenceRepository: preferences);
    addTearDown(tips.close);
    final _Favorites favorites = _Favorites();
    when(() => favorites.state).thenReturn(FavState.init());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<TipsCubit>.value(value: tips),
          BlocProvider<FavCubit>.value(value: favorites),
        ],
        child: FeatureDiscovery.withProvider(
          persistenceProvider: const NoPersistenceProvider(),
          child: MaterialApp(
            home: Builder(
              builder: (BuildContext context) => Scaffold(
                appBar: CustomAppBar(
                  context: context,
                  item: Item.empty(),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  onFontSizeTap: () {},
                  fontSizeIconButtonKey: GlobalKey(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final State<ItemScreenTips> owner = tester.state<State<ItemScreenTips>>(
      find.byType(ItemScreenTips),
    );

    await tester.tap(find.byIcon(Icons.tips_and_updates_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(VideoPlayer), findsOneWidget);
    expect(video.played, <int>[1]);
    expect(video.disposed, isEmpty);
    expect(tips.state.isTipsCompleted(Tips.itemScreen), isFalse);
    verifyNever(() => preferences.setBool('itemScreen_tips_completed', true));

    await tester.ensureVisible(find.text('Dismiss'));
    await tester.tap(find.text('Dismiss'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.byType(VideoPlayer), findsNothing);
    expect(find.byType(ItemScreenTips, skipOffstage: false), findsNothing);
    expect(tips.state.isTipsCompleted(Tips.itemScreen), isTrue);
    expect(owner.mounted, isFalse);
    // Stream cancellation can finish outside Flutter's fake async clock.
    // Let that work complete, then flush its widget-test microtasks.
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(video.disposed, <int>[1]);
    verify(
      () => preferences.setBool('itemScreen_tips_completed', true),
    ).called(1);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
