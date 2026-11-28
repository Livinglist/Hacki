import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/extensions/loggable.dart';
import 'package:hacki/models/models.dart';
import 'package:hive/hive.dart';

/// Persists read markers and the latest visited stories.
class HistoryRepository with Loggable {
  HistoryRepository({
    Future<Box<int>>? idBox,
    Future<Box<String>>? visitedStoriesBox,
  }) : _box = idBox ?? Hive.openBox<int>(_boxName),
       _visitedStoriesBox = visitedStoriesBox {
    initialize();
  }

  static const String _boxName = 'readStoryIds';
  static const String _visitedStoriesBoxName = 'visitedStories';
  static const String _visitedStoriesKey = 'stories';
  static const int _maxLength = 1_000;
  static const int maxVisitedStories = 50;
  final Future<Box<int>> _box;
  Future<Box<String>>? _visitedStoriesBox;
  Status _status = .idle;

  final Set<int> _readIds = <int>{};

  Future<Box<String>> _getVisitedStoriesBox() =>
      _visitedStoriesBox ??= Hive.openBox<String>(_visitedStoriesBoxName);

  Future<List<Story>> loadVisitedStories() async {
    final Box<String> box = await _getVisitedStoriesBox();
    final String? saved = box.get(_visitedStoriesKey);
    if (saved == null) return <Story>[];

    final List<dynamic> stories = jsonDecode(saved) as List<dynamic>;
    return _latestUniqueStories(
      stories.map(
        (dynamic json) => Story.fromJson(json as Map<String, dynamic>),
      ),
    );
  }

  Future<void> saveVisitedStories(List<Story> stories) async {
    final Box<String> box = await _getVisitedStoriesBox();
    await box.put(
      _visitedStoriesKey,
      jsonEncode(
        _latestUniqueStories(stories)
            .map(
              (Story story) => <String, dynamic>{
                ...story.toJson(),
                'hidden': story.hidden,
              },
            )
            .toList(),
      ),
    );
  }

  List<Story> _latestUniqueStories(Iterable<Story> stories) {
    final Set<int> ids = <int>{};
    return stories
        .where((Story story) => ids.add(story.id))
        .take(maxVisitedStories)
        .toList();
  }

  Future<void> initialize() async {
    if (_status == .idle) {
      final Iterable<int> res = await loadAll();
      _readIds.addAll(res);
      _status = .success;
    }
  }

  Future<bool> hasRead(int storyId) async {
    if (_readIds.isEmpty) {
      final Box<int> box = await _box;
      return box.containsKey(storyId);
    } else {
      return _readIds.contains(storyId);
    }
  }

  Future<void> saveReadStoryId(int storyId) async {
    _readIds.add(storyId);
    final Box<int> box = await _box;
    return box.put(storyId, storyId);
  }

  Future<void> removeReadStoryId(int storyId) async {
    _readIds.remove(storyId);
    final Box<int> box = await _box;
    return box.delete(storyId);
  }

  Future<void> clearAllReadStoryIds() async {
    _readIds.clear();
    final Box<int> box = await _box;
    await box.clear();
  }

  Future<Iterable<int>> loadAll() async {
    final Box<int> box = await _box;
    final Iterable<int> results = box.keys.cast<int>();

    if (results.length > _maxLength) {
      logInfo('''read ids exceeds limit: ${results.length}''');
      logInfo('''read ids are: $results''');
      final List<int> orderedStoryIds = results.sorted(
        (int lhs, int rhs) => lhs.compareTo(rhs),
      );
      final int end = box.length ~/ 2;
      final List<int> firstHalf = orderedStoryIds.sublist(0, end);
      logInfo('''read ids being removed: ${firstHalf.length}''');
      await box.deleteAll(firstHalf);
    }
    logInfo('''retrieved ${results.length} read ids''');
    return results;
  }

  Future<void> clear() async => (await _box).clear();

  @override
  String get logIdentifier => 'HistoryRepository';
}
