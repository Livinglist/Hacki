import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/screens/settings/widgets/offline_list_tile.dart';
import 'package:hacki/screens/widgets/custom_circular_progress_indicator.dart';
import 'package:material_ui/material_ui.dart';

class _MockStoriesBloc extends MockBloc<StoriesEvent, StoriesState>
    implements StoriesBloc {}

void main() {
  late _MockStoriesBloc storiesBloc;

  setUp(() {
    storiesBloc = _MockStoriesBloc();
  });

  Future<void> pumpTile(
    WidgetTester tester, {
    required StoriesState state,
    Stream<StoriesState> states = const Stream<StoriesState>.empty(),
  }) async {
    whenListen(storiesBloc, states, initialState: state);
    await tester.pumpWidget(
      BlocProvider<StoriesBloc>.value(
        value: storiesBloc,
        child: const MaterialApp(home: Scaffold(body: OfflineListTile())),
      ),
    );
  }

  for (final StoriesDownloadStatus status in <StoriesDownloadStatus>[
    StoriesDownloadStatus.failure,
    StoriesDownloadStatus.canceled,
  ]) {
    testWidgets('$status with partial progress does not display success', (
      WidgetTester tester,
    ) async {
      await pumpTile(
        tester,
        state: const StoriesState.init().copyWith(
          downloadStatus: status,
          storiesDownloaded: 4,
          storiesToBeDownloaded: 10,
        ),
      );

      expect(
        find.text(
          status == StoriesDownloadStatus.failure
              ? 'Story download failed.'
              : 'Story download canceled.',
        ),
        findsOneWidget,
      );
      expect(find.text('4 stories downloaded.'), findsNothing);
      expect(find.byIcon(Icons.download), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byType(CustomCircularProgressIndicator), findsNothing);
    });
  }

  testWidgets('idle with a previous count does not display success', (
    WidgetTester tester,
  ) async {
    await pumpTile(
      tester,
      state: const StoriesState.init().copyWith(storiesDownloaded: 4),
    );

    expect(find.text('Download Stories'), findsOneWidget);
    expect(find.text('4 stories downloaded.'), findsNothing);
    expect(find.byIcon(Icons.download), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  for (final int downloaded in <int>[0, 4]) {
    testWidgets('finished displays $downloaded stories and a check mark', (
      WidgetTester tester,
    ) async {
      await pumpTile(
        tester,
        state: const StoriesState.init().copyWith(
          downloadStatus: StoriesDownloadStatus.finished,
          storiesDownloaded: downloaded,
          storiesToBeDownloaded: downloaded,
        ),
      );

      expect(find.text('$downloaded stories downloaded.'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.download), findsNothing);
      expect(find.byType(CustomCircularProgressIndicator), findsNothing);
    });
  }

  testWidgets('downloading displays progress and updates the count', (
    WidgetTester tester,
  ) async {
    final StreamController<StoriesState> states =
        StreamController<StoriesState>.broadcast(sync: true);
    addTearDown(states.close);
    final StoriesState initialState = const StoriesState.init().copyWith(
      downloadStatus: StoriesDownloadStatus.downloading,
      storiesDownloaded: 4,
      storiesToBeDownloaded: 10,
    );
    await pumpTile(tester, state: initialState, states: states.stream);

    expect(find.text('Downloading Stories (4/10)'), findsOneWidget);
    expect(find.byType(CustomCircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byIcon(Icons.download), findsNothing);

    states.add(initialState.copyWith(storiesDownloaded: 5));
    await tester.pump();

    expect(find.text('Downloading Stories (5/10)'), findsOneWidget);
    expect(find.text('Downloading Stories (4/10)'), findsNothing);
    expect(find.byType(CustomCircularProgressIndicator), findsOneWidget);
  });

  for (final StoriesDownloadStatus status in <StoriesDownloadStatus>[
    StoriesDownloadStatus.finished,
    StoriesDownloadStatus.failure,
    StoriesDownloadStatus.canceled,
  ]) {
    testWidgets('$status releases the download wakelock', (
      WidgetTester tester,
    ) async {
      const String channel =
          'dev.flutter.pigeon.wakelock_plus_platform_interface.'
          'WakelockPlusApi.toggle';
      int wakelockCalls = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(channel, (ByteData? message) async {
            wakelockCalls++;
            return const StandardMessageCodec().encodeMessage(<Object?>[null]);
          });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler(channel, null);
      });
      final StreamController<StoriesState> states =
          StreamController<StoriesState>.broadcast(sync: true);
      addTearDown(states.close);
      final StoriesState initialState = const StoriesState.init().copyWith(
        downloadStatus: StoriesDownloadStatus.downloading,
        storiesDownloaded: 4,
        storiesToBeDownloaded: 10,
      );
      await pumpTile(tester, state: initialState, states: states.stream);
      expect(wakelockCalls, 0);

      states.add(initialState.copyWith(downloadStatus: status));
      await tester.pump();

      expect(wakelockCalls, 1);
      expect(find.byType(CustomCircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
