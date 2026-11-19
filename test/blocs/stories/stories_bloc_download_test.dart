import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/blocs/blocs.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/cubits/cubits.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class _MockPreferenceCubit extends MockCubit<PreferenceState>
    implements PreferenceCubit {}

class _MockFilterCubit extends MockCubit<FilterState> implements FilterCubit {}

class _MockHideCubit extends MockCubit<HideState> implements HideCubit {}

class _MockOfflineRepository extends Mock implements OfflineRepository {}

class _MockHackerNewsRepository extends Mock implements HackerNewsRepository {}

class _MockHackerNewsWebRepository extends Mock
    implements HackerNewsWebRepository {}

class _MockHistoryRepository extends Mock implements HistoryRepository {}

class _MockPreferenceRepository extends Mock implements PreferenceRepository {}

class _MockLogger extends Mock implements Logger {}

void main() {
  setUpAll(() {
    registerFallbackValue(StoryType.top);
    registerFallbackValue(Story.empty());
    registerFallbackValue(_comment(101));
  });

  late _DownloadHarness harness;

  setUp(() {
    harness = _DownloadHarness();
  });

  tearDown(() async {
    await harness.close();
    await locator.reset();
  });

  group('StoriesBloc downloads', () {
    test(
      'waits for the final comment write before reporting success',
      () async {
        final Completer<void> writeStarted = Completer<void>();
        final Completer<void> writeFinished = harness.gate();
        when(
          () => harness.offlineRepository.cacheComment(
            comment: any(named: 'comment'),
          ),
        ).thenAnswer((_) async {
          writeStarted.complete();
          await writeFinished.future;
        });

        harness.start();
        await writeStarted.future;
        await pumpEventQueue();

        expect(
          harness.bloc.state.downloadStatus,
          StoriesDownloadStatus.downloading,
        );
        expect(harness.bloc.state.storiesDownloaded, 0);
        expect(harness.bloc.state.downloadTimestamp, isNull);
        verifyNever(
          () => harness.preferenceRepository.setDownloadTimestamp(
            timestamp: any(named: 'timestamp'),
          ),
        );

        writeFinished.complete();
        final StoriesState state = await harness.waitFor(
          StoriesDownloadStatus.finished,
        );

        expect(state.storiesDownloaded, 1);
        expect(state.storiesToBeDownloaded, 1);
        expect(state.downloadTimestamp, isNotNull);
        verify(
          () => harness.preferenceRepository.setDownloadTimestamp(
            timestamp: any(named: 'timestamp'),
          ),
        ).called(1);
      },
    );

    test('downloads overlapping category and latest IDs only once', () async {
      harness.storyIds
        ..[StoryType.top] = <int>[1, 2]
        ..[StoryType.best] = <int>[2, 3]
        ..[StoryType.ask] = <int>[1]
        ..[StoryType.show] = <int>[3]
        ..[StoryType.latest] = <int>[1, 3, 4];

      harness.start();
      final StoriesState state = await harness.waitFor(
        StoriesDownloadStatus.finished,
      );

      expect(state.storiesDownloaded, 4);
      expect(state.storiesToBeDownloaded, 4);
      for (final int id in <int>[1, 2, 3, 4]) {
        verify(() => harness.hackerNewsRepository.fetchStory(id: id)).called(1);
      }
      verify(
        () => harness.offlineRepository.cacheComment(
          comment: any(named: 'comment'),
        ),
      ).called(4);
    });

    test(
      'excludes unavailable and commentless stories from the final total',
      () async {
        harness.storyIds[StoryType.top] = <int>[1, 2, 3];
        when(
          () => harness.hackerNewsRepository.fetchStory(id: 1),
        ).thenAnswer((_) async => null);
        when(() => harness.hackerNewsRepository.fetchStory(id: 2)).thenAnswer(
          (_) async =>
              Story.fromJson(const <String, dynamic>{'id': 2, 'type': 'story'}),
        );

        harness.start();
        final StoriesState state = await harness.waitFor(
          StoriesDownloadStatus.finished,
        );

        expect(state.storiesDownloaded, 1);
        expect(state.storiesToBeDownloaded, 1);
        verify(
          () =>
              harness.offlineRepository.cacheStory(story: any(named: 'story')),
        ).called(1);
      },
    );

    test(
      'keeps the selected limit across prioritized and latest categories',
      () async {
        final MaxOfflineStoriesCount limit =
            MaxOfflineStoriesCount.values.first;
        harness.storyIds
          ..[StoryType.top] = List<int>.generate(
            limit.count! + 1,
            (int index) => index + 1,
          )
          ..[StoryType.latest] = <int>[1000];
        harness.bloc.add(UpdateMaxOfflineStoriesCount(count: limit));
        await pumpEventQueue();

        harness.start();
        final StoriesState state = await harness.waitFor(
          StoriesDownloadStatus.finished,
        );

        expect(state.storiesDownloaded, limit.count);
        expect(state.storiesToBeDownloaded, limit.count);
        verifyNever(
          () => harness.hackerNewsRepository.fetchStory(id: limit.count! + 1),
        );
        verifyNever(() => harness.hackerNewsRepository.fetchStory(id: 1000));
      },
    );

    test('includes unfinished latest stories in the total', () async {
      harness.storyIds[StoryType.latest] = <int>[2];
      final Completer<void> latestWriteStarted = Completer<void>();
      final Completer<void> latestWriteFinished = harness.gate();
      when(
        () => harness.offlineRepository.cacheComment(
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((Invocation invocation) async {
        final Comment comment = invocation.namedArguments[#comment]! as Comment;
        if (comment.id == 102) {
          latestWriteStarted.complete();
          await latestWriteFinished.future;
        }
      });

      harness.start();
      await latestWriteStarted.future;
      await pumpEventQueue();

      expect(harness.bloc.state.storiesDownloaded, 1);
      expect(harness.bloc.state.storiesToBeDownloaded, 2);
      expect(
        harness.bloc.state.downloadStatus,
        StoriesDownloadStatus.downloading,
      );
      expect(
        harness.states.where(
          (StoriesState state) =>
              state.downloadStatus == StoriesDownloadStatus.finished,
        ),
        isEmpty,
      );

      latestWriteFinished.complete();
      final StoriesState state = await harness.waitFor(
        StoriesDownloadStatus.finished,
      );
      expect(state.storiesDownloaded, 2);
      expect(state.storiesToBeDownloaded, 2);
    });

    test('waits for category discovery before completing a download', () async {
      final Completer<void> latestRequested = Completer<void>();
      final Completer<void> latestAvailable = harness.gate();
      when(
        () =>
            harness.hackerNewsRepository.fetchStoryIds(type: StoryType.latest),
      ).thenAnswer((_) async {
        latestRequested.complete();
        await latestAvailable.future;
        return <int>[2];
      });

      harness.start();
      await latestRequested.future;
      await pumpEventQueue();

      expect(
        harness.bloc.state.downloadStatus,
        StoriesDownloadStatus.downloading,
      );
      expect(harness.bloc.state.downloadTimestamp, isNull);

      latestAvailable.complete();
      final StoriesState state = await harness.waitFor(
        StoriesDownloadStatus.finished,
      );
      expect(state.storiesDownloaded, 2);
      expect(state.storiesToBeDownloaded, 2);
    });

    test(
      'reports initial category failures without a success timestamp',
      () async {
        when(
          () => harness.hackerNewsRepository.fetchStoryIds(type: StoryType.top),
        ).thenAnswer((_) async => throw StateError('category request failed'));

        harness.start();
        final StoriesState state = await harness.waitFor(
          StoriesDownloadStatus.failure,
        );

        expect(state.storiesDownloaded, 0);
        expect(state.downloadTimestamp, isNull);
        verifyNever(
          () => harness.preferenceRepository.setDownloadTimestamp(
            timestamp: any(named: 'timestamp'),
          ),
        );
      },
    );

    test(
      'settles in-flight writes before reporting a comment stream error',
      () async {
        harness.storyIds[StoryType.top] = <int>[1, 2];
        final Completer<void> writeStarted = Completer<void>();
        final Completer<void> writeFinished = harness.gate();
        when(
          () => harness.hackerNewsRepository.fetchAllChildrenComments(
            ids: <int>[101],
          ),
        ).thenAnswer((_) => _failingComments(writeStarted.future));
        when(
          () => harness.offlineRepository.cacheComment(
            comment: any(named: 'comment'),
          ),
        ).thenAnswer((_) async {
          writeStarted.complete();
          await writeFinished.future;
        });

        harness.start();
        await writeStarted.future;
        await pumpEventQueue();

        expect(
          harness.bloc.state.downloadStatus,
          StoriesDownloadStatus.downloading,
        );
        expect(harness.bloc.state.downloadTimestamp, isNull);

        writeFinished.complete();
        final StoriesState state = await harness.waitFor(
          StoriesDownloadStatus.failure,
        );
        expect(state.downloadTimestamp, isNull);
        expect(
          harness.states.where(
            (StoriesState state) =>
                state.downloadStatus == StoriesDownloadStatus.finished,
          ),
          isEmpty,
        );
        verifyNever(
          () => harness.preferenceRepository.setDownloadTimestamp(
            timestamp: any(named: 'timestamp'),
          ),
        );
      },
    );

    test('reports a failed comment write without committing success', () async {
      when(
        () => harness.offlineRepository.cacheComment(
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async => throw StateError('cache write failed'));

      harness.start();
      final StoriesState state = await harness.waitFor(
        StoriesDownloadStatus.failure,
      );

      expect(state.storiesDownloaded, 0);
      expect(state.downloadTimestamp, isNull);
      expect(
        harness.states.where(
          (StoriesState state) =>
              state.downloadStatus == StoriesDownloadStatus.finished,
        ),
        isEmpty,
      );
      verifyNever(
        () => harness.preferenceRepository.setDownloadTimestamp(
          timestamp: any(named: 'timestamp'),
        ),
      );
    });

    test(
      'finishes cancellation cleanup before starting a replacement download',
      () async {
        final Completer<void> writeStarted = Completer<void>();
        final Completer<void> writeFinished = harness.gate();
        final List<String> operations = <String>[];
        final StreamController<Comment?> oldComments =
            StreamController<Comment?>();
        addTearDown(oldComments.close);
        when(
          () => harness.hackerNewsRepository.fetchAllChildrenComments(
            ids: <int>[101],
          ),
        ).thenAnswer((_) => oldComments.stream);
        when(
          () => harness.offlineRepository.cacheComment(
            comment: any(named: 'comment'),
          ),
        ).thenAnswer((Invocation invocation) async {
          final Comment comment =
              invocation.namedArguments[#comment]! as Comment;
          if (comment.id == 101) {
            writeStarted.complete();
            await writeFinished.future;
            operations.add('old comment written');
          } else {
            operations.add('new comment written');
          }
        });
        when(() => harness.offlineRepository.deleteAllComments()).thenAnswer((
          _,
        ) async {
          operations.add('comments cleared');
          return 0;
        });

        harness.start();
        oldComments.add(_comment(101));
        await writeStarted.future;

        harness.storyIds[StoryType.top] = <int>[2];
        harness.bloc.add(StoriesCancelDownload());
        harness.start();
        await pumpEventQueue();

        verifyNever(() => harness.hackerNewsRepository.fetchStory(id: 2));
        oldComments.add(_comment(999));
        writeFinished.complete();

        final StoriesState state = await harness.waitFor(
          StoriesDownloadStatus.finished,
        );
        await pumpEventQueue();

        expect(state.storiesDownloaded, 1);
        expect(state.storiesToBeDownloaded, 1);
        expect(
          operations.indexOf('old comment written'),
          lessThan(operations.lastIndexOf('comments cleared')),
        );
        expect(
          operations.lastIndexOf('comments cleared'),
          lessThan(operations.indexOf('new comment written')),
        );
        verifyNever(
          () => harness.offlineRepository.cacheComment(comment: _comment(999)),
        );
        verify(() => harness.hackerNewsRepository.fetchStory(id: 1)).called(1);
        verify(() => harness.hackerNewsRepository.fetchStory(id: 2)).called(1);
        verify(
          () => harness.preferenceRepository.setDownloadTimestamp(
            timestamp: any(named: 'timestamp'),
          ),
        ).called(1);
      },
    );

    test('ignores a duplicate start while a download is active', () async {
      final Completer<void> writeStarted = Completer<void>();
      final Completer<void> writeFinished = harness.gate();
      when(
        () => harness.offlineRepository.cacheComment(
          comment: any(named: 'comment'),
        ),
      ).thenAnswer((_) async {
        writeStarted.complete();
        await writeFinished.future;
      });

      harness.start();
      await writeStarted.future;
      harness.start();
      await pumpEventQueue();

      verify(() => harness.offlineRepository.deleteAllStoryIds()).called(1);
      verify(() => harness.hackerNewsRepository.fetchStory(id: 1)).called(1);
      expect(
        harness.bloc.state.downloadStatus,
        StoriesDownloadStatus.downloading,
      );

      writeFinished.complete();
      await harness.waitFor(StoriesDownloadStatus.finished);
      verify(
        () => harness.preferenceRepository.setDownloadTimestamp(
          timestamp: any(named: 'timestamp'),
        ),
      ).called(1);
    });

    test(
      'cancels a silent comment stream without waiting for another comment',
      () async {
        final Completer<void> listening = Completer<void>();
        final Completer<void> canceled = Completer<void>();
        final StreamController<Comment?> comments = StreamController<Comment?>(
          onListen: listening.complete,
          onCancel: canceled.complete,
        );
        addTearDown(comments.close);
        when(
          () => harness.hackerNewsRepository.fetchAllChildrenComments(
            ids: <int>[101],
          ),
        ).thenAnswer((_) => comments.stream);

        harness.start();
        await listening.future;
        harness.bloc.add(StoriesCancelDownload());
        final StoriesState state = await harness.waitFor(
          StoriesDownloadStatus.canceled,
        );

        expect(canceled.isCompleted, isTrue);
        expect(state.storiesDownloaded, 0);
        expect(state.storiesToBeDownloaded, 0);
        expect(state.downloadTimestamp, isNull);
        verifyNever(
          () => harness.preferenceRepository.setDownloadTimestamp(
            timestamp: any(named: 'timestamp'),
          ),
        );
      },
    );
  });
}

class _DownloadHarness {
  _DownloadHarness() {
    locator.registerSingleton<Logger>(_MockLogger());
    when(() => preferenceCubit.state).thenReturn(PreferenceState.init());
    when(
      () => preferenceCubit.stream,
    ).thenAnswer((_) => const Stream<PreferenceState>.empty());
    when(offlineRepository.deleteAllStoryIds).thenAnswer((_) async => 0);
    when(offlineRepository.deleteAllStories).thenAnswer((_) async => 0);
    when(offlineRepository.deleteAllComments).thenAnswer((_) async => 0);
    when(offlineRepository.deleteAllWebPages).thenAnswer((_) async => 0);
    when(offlineRepository.deleteAll).thenAnswer((_) async => 0);
    when(
      () => offlineRepository.cacheStoryIds(
        type: any(named: 'type'),
        ids: any(named: 'ids'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => offlineRepository.cacheStory(story: any(named: 'story')),
    ).thenAnswer((_) async {});
    when(
      () => offlineRepository.cacheComment(comment: any(named: 'comment')),
    ).thenAnswer((_) async {});
    when(
      () => offlineRepository.cacheUrl(url: any(named: 'url')),
    ).thenAnswer((_) async {});
    when(
      () => preferenceRepository.setDownloadTimestamp(
        timestamp: any(named: 'timestamp'),
      ),
    ).thenAnswer((_) async {});
    when(preferenceRepository.removeDownloadTimestamp).thenAnswer((_) async {});
    when(
      () => hackerNewsRepository.fetchStoryIds(type: any(named: 'type')),
    ).thenAnswer((Invocation invocation) async {
      final StoryType type = invocation.namedArguments[#type]! as StoryType;
      return List<int>.of(storyIds[type] ?? <int>[]);
    });
    when(
      () => hackerNewsRepository.fetchStory(id: any(named: 'id')),
    ).thenAnswer((Invocation invocation) async {
      final int id = invocation.namedArguments[#id]! as int;
      return Story.fromJson(<String, dynamic>{
        'id': id,
        'type': 'story',
        'kids': <int>[id + 100],
      });
    });
    when(
      () =>
          hackerNewsRepository.fetchAllChildrenComments(ids: any(named: 'ids')),
    ).thenAnswer((Invocation invocation) {
      final List<int> ids = invocation.namedArguments[#ids]! as List<int>;
      return Stream<Comment?>.fromIterable(ids.map(_comment));
    });
    bloc = StoriesBloc(
      preferenceCubit: preferenceCubit,
      filterCubit: _MockFilterCubit(),
      hideCubit: _MockHideCubit(),
      offlineRepository: offlineRepository,
      hackerNewsRepository: hackerNewsRepository,
      hackerNewsWebRepository: _MockHackerNewsWebRepository(),
      historyRepository: _MockHistoryRepository(),
      preferenceRepository: preferenceRepository,
    );
    _subscription = bloc.stream.listen(states.add);
  }

  final _MockPreferenceCubit preferenceCubit = _MockPreferenceCubit();
  final _MockOfflineRepository offlineRepository = _MockOfflineRepository();
  final _MockHackerNewsRepository hackerNewsRepository =
      _MockHackerNewsRepository();
  final _MockPreferenceRepository preferenceRepository =
      _MockPreferenceRepository();
  final Map<StoryType, List<int>> storyIds = <StoryType, List<int>>{
    StoryType.top: <int>[1],
  };
  final List<StoriesState> states = <StoriesState>[];
  final List<Completer<void>> _gates = <Completer<void>>[];
  late final StoriesBloc bloc;
  late final StreamSubscription<StoriesState> _subscription;

  Completer<void> gate() {
    final Completer<void> completer = Completer<void>();
    _gates.add(completer);
    return completer;
  }

  void start() => bloc.add(StoriesDownload(includingWebPage: false));

  Future<StoriesState> waitFor(StoriesDownloadStatus status) async {
    if (bloc.state.downloadStatus == status) return bloc.state;
    return bloc.stream
        .firstWhere((StoriesState state) => state.downloadStatus == status)
        .timeout(const Duration(seconds: 5));
  }

  Future<void> close() async {
    for (final Completer<void> completer in _gates) {
      if (!completer.isCompleted) completer.complete();
    }
    await bloc.close();
    await _subscription.cancel();
    await preferenceCubit.close();
  }
}

Comment _comment(int id) => Comment.fromJson(<String, dynamic>{
  'id': id,
  'parent': id - 100,
  'text': 'Comment $id',
});

Stream<Comment?> _failingComments(Future<void> otherWriteStarted) async* {
  await otherWriteStarted;
  throw StateError('comment stream failed');
}
