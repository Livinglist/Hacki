import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/history_repository.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

void main() {
  late Directory directory;
  late Box<int> idBox;
  late Box<String> visitedStoriesBox;
  late HistoryRepository repository;

  Story story(int id, {String? title}) => Story.fromJson(<String, dynamic>{
    'id': id,
    'title': title ?? 'Story $id',
    'type': 'story',
    'by': 'alice',
    'time': 100,
    'url': 'https://example.com/$id',
    'text': 'Story text',
    'score': 10,
    'descendants': 2,
    'kids': <int>[id + 100],
  });

  HistoryRepository createRepository() => HistoryRepository(
    idBox: Future<Box<int>>.value(idBox),
    visitedStoriesBox: Future<Box<String>>.value(visitedStoriesBox),
  );

  setUp(() async {
    locator.registerSingleton<Logger>(Logger(level: Level.off));
    directory = await Directory.systemTemp.createTemp('hacki_history_test_');
    Hive.init(directory.path);
    idBox = await Hive.openBox<int>('readStoryIds');
    visitedStoriesBox = await Hive.openBox<String>('visitedStories');
    repository = createRepository();
    await repository.initialize();
  });

  tearDown(() async {
    await Hive.close();
    await directory.delete(recursive: true);
    await locator.reset();
  });

  test('starts with empty visited history', () async {
    expect(await repository.loadVisitedStories(), isEmpty);
  });

  test(
    'restores full stories in visit order after reopening storage',
    () async {
      final List<Story> stories = <Story>[story(3), story(1), story(2)];
      await repository.saveVisitedStories(stories);
      await Hive.close();

      idBox = await Hive.openBox<int>('readStoryIds');
      visitedStoriesBox = await Hive.openBox<String>('visitedStories');
      repository = createRepository();
      await repository.initialize();

      expect(await repository.loadVisitedStories(), stories);
    },
  );

  test('keeps the first snapshot when a story ID occurs again', () async {
    final Story revisited = story(1, title: 'Updated title');
    await repository.saveVisitedStories(<Story>[
      revisited,
      story(2),
      story(1),
      story(3),
    ]);

    expect(await repository.loadVisitedStories(), <Story>[
      revisited,
      story(2),
      story(3),
    ]);
  });

  test('persists only the latest 50 unique stories', () async {
    await repository.saveVisitedStories(
      List<Story>.generate(60, (int index) => story(60 - index)),
    );

    final List<Story> stories = await repository.loadVisitedStories();
    expect(stories, hasLength(50));
    expect(stories.first.id, 60);
    expect(stories.last.id, 11);
  });

  test('visited history and read markers remain independent', () async {
    await repository.saveReadStoryId(100);
    await repository.saveVisitedStories(<Story>[story(1), story(2)]);

    expect(await repository.hasRead(100), isTrue);
    expect(await repository.hasRead(1), isFalse);
    await repository.clearAllReadStoryIds();

    expect(await repository.hasRead(100), isFalse);
    expect(await repository.loadVisitedStories(), <Story>[story(1), story(2)]);

    await repository.saveReadStoryId(200);
    await repository.saveVisitedStories(<Story>[]);
    expect(await repository.loadVisitedStories(), isEmpty);
    expect(await repository.hasRead(200), isTrue);
    await repository.removeReadStoryId(200);
    expect(await repository.hasRead(200), isFalse);
  });
}
