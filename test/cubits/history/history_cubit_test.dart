import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/cubits/history/history_cubit.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/history_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockHistoryRepository extends Mock implements HistoryRepository {}

Story _story(int id, {String? title}) => Story.fromJson(<String, dynamic>{
  'id': id,
  'type': 'story',
  'title': title ?? 'Story $id',
  'by': 'alice',
  'time': 0,
});

List<int> _ids(List<Story> stories) =>
    stories.map((Story story) => story.id).toList();

void main() {
  late _MockHistoryRepository repository;
  HistoryCubit? cubit;

  HistoryCubit createCubit() {
    final HistoryCubit result = HistoryCubit(historyRepository: repository);
    cubit = result;
    return result;
  }

  setUp(() {
    repository = _MockHistoryRepository();
    when(
      () => repository.loadVisitedStories(),
    ).thenAnswer((_) async => <Story>[]);
    when(() => repository.saveVisitedStories(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await cubit?.close();
    cubit = null;
  });

  test('restores stories in their saved visit order without writing', () async {
    final List<Story> saved = <Story>[_story(3), _story(1), _story(2)];
    when(() => repository.loadVisitedStories()).thenAnswer((_) async => saved);

    final HistoryCubit historyCubit = createCubit();
    await pumpEventQueue();

    expect(historyCubit.state.stories, saved);
    expect(historyCubit.state.status, Status.success);
    verifyNever(() => repository.saveVisitedStories(any()));
  });

  test('revisiting a story moves its updated snapshot to the front', () async {
    when(
      () => repository.loadVisitedStories(),
    ).thenAnswer((_) async => <Story>[_story(3), _story(2), _story(1)]);
    final HistoryCubit historyCubit = createCubit();
    final Story updated = _story(2, title: 'Updated title');

    await historyCubit.recordStory(updated);

    expect(_ids(historyCubit.state.stories), <int>[2, 3, 1]);
    expect(historyCubit.state.stories.first.title, 'Updated title');
    verify(
      () => repository.saveVisitedStories(historyCubit.state.stories),
    ).called(1);

    await historyCubit.recordStory(updated);

    expect(_ids(historyCubit.state.stories), <int>[2, 3, 1]);
  });

  test(
    'keeps and persists only the latest 50 distinct visited stories',
    () async {
      final HistoryCubit historyCubit = createCubit();

      for (int id = 1; id <= 60; id++) {
        await historyCubit.recordStory(_story(id));
      }

      final List<int> expected = List<int>.generate(
        50,
        (int index) => 60 - index,
      );
      expect(_ids(historyCubit.state.stories), expected);
      final List<List<Story>> snapshots = verify(
        () => repository.saveVisitedStories(captureAny()),
      ).captured.cast<List<Story>>();
      expect(
        snapshots.every((List<Story> stories) => stories.length <= 50),
        isTrue,
      );
      expect(_ids(snapshots.last), expected);
    },
  );

  test('normalizes duplicate and oversized restored history', () async {
    final List<Story> saved = <Story>[
      _story(100, title: 'Latest snapshot'),
      _story(100, title: 'Older snapshot'),
      ...List<Story>.generate(60, (int index) => _story(index + 1)),
    ];
    when(() => repository.loadVisitedStories()).thenAnswer((_) async => saved);

    final HistoryCubit historyCubit = createCubit();
    await pumpEventQueue();

    expect(historyCubit.state.stories, hasLength(50));
    expect(historyCubit.state.stories.first.title, 'Latest snapshot');
    expect(_ids(historyCubit.state.stories).toSet(), hasLength(50));
    expect(historyCubit.state.stories.last.id, 49);
  });

  test(
    'preserves early visits and serializes rapid persistence writes',
    () async {
      final Completer<List<Story>> restoration = Completer<List<Story>>();
      final Completer<void> firstWrite = Completer<void>();
      final List<List<Story>> snapshots = <List<Story>>[];
      List<Story> persisted = <Story>[];
      when(
        () => repository.loadVisitedStories(),
      ).thenAnswer((_) => restoration.future);
      when(() => repository.saveVisitedStories(any())).thenAnswer((
        Invocation invocation,
      ) async {
        final List<Story> snapshot =
            invocation.positionalArguments.single as List<Story>;
        snapshots.add(snapshot);
        if (snapshots.length == 1) await firstWrite.future;
        persisted = snapshot;
      });
      final HistoryCubit historyCubit = createCubit();
      final List<Future<void>> visits = <Future<void>>[
        historyCubit.recordStory(_story(30)),
        historyCubit.recordStory(_story(40)),
        historyCubit.recordStory(_story(10, title: 'Visited again')),
      ];

      try {
        expect(snapshots, isEmpty);
        restoration.complete(<Story>[_story(10), _story(20)]);
        await pumpEventQueue();

        expect(snapshots, hasLength(1));
        expect(_ids(snapshots.single), <int>[30, 10, 20]);
      } finally {
        if (!restoration.isCompleted) restoration.complete(<Story>[]);
        firstWrite.complete();
        await Future.wait(visits);
      }

      expect(snapshots.map(_ids).toList(), <List<int>>[
        <int>[30, 10, 20],
        <int>[40, 30, 10, 20],
        <int>[10, 40, 30, 20],
      ]);
      expect(persisted, historyCubit.state.stories);
      expect(persisted.first.title, 'Visited again');
    },
  );

  test(
    'retains visits after a failed write and persists them on recovery',
    () async {
      int attempts = 0;
      when(() => repository.saveVisitedStories(any())).thenAnswer((_) async {
        if (attempts++ == 0) throw Exception('Disk unavailable');
      });
      final HistoryCubit historyCubit = createCubit();

      await historyCubit.recordStory(_story(1));

      expect(_ids(historyCubit.state.stories), <int>[1]);
      expect(historyCubit.state.status, Status.failure);

      await historyCubit.recordStory(_story(2));

      expect(_ids(historyCubit.state.stories), <int>[2, 1]);
      expect(historyCubit.state.status, Status.success);
      verify(
        () => repository.saveVisitedStories(historyCubit.state.stories),
      ).called(1);
    },
  );

  test(
    'records visits even when initial history could not be loaded',
    () async {
      when(
        () => repository.loadVisitedStories(),
      ).thenThrow(Exception('History unavailable'));
      final HistoryCubit historyCubit = createCubit();

      await historyCubit.recordStory(_story(1));

      expect(_ids(historyCubit.state.stories), <int>[1]);
      expect(historyCubit.state.status, Status.success);
      verify(
        () => repository.saveVisitedStories(historyCubit.state.stories),
      ).called(1);
    },
  );

  test(
    'ignores placeholder stories without changing persisted history',
    () async {
      final HistoryCubit historyCubit = createCubit();
      await pumpEventQueue();

      await historyCubit.recordStory(Story.placeholder());

      expect(historyCubit.state.stories, isEmpty);
      verifyNever(() => repository.saveVisitedStories(any()));
    },
  );
}
