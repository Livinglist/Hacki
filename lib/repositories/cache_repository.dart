import 'package:hacki/models/models.dart';
import 'package:hive/hive.dart';

class CacheRepository {
  CacheRepository({
    Future<Box<bool>>? readStoryIdBox,
    Future<Box<List<int>>>? storyIdBox,
    Future<Box<Map<dynamic, dynamic>>>? storyBox,
    Future<LazyBox<Map<dynamic, dynamic>>>? commentBox,
  })  : _readStoryIdBox =
            readStoryIdBox ?? Hive.openBox<bool>(_readStoryIdBoxName),
        _storyIdBox = storyIdBox ?? Hive.openBox<List<int>>(_storyIdBoxName),
        _storyBox =
            storyBox ?? Hive.openBox<Map<dynamic, dynamic>>(_storyBoxName),
        _commentBox = commentBox ??
            Hive.openLazyBox<Map<dynamic, dynamic>>(_commentBoxName);

  static const _readStoryIdBoxName = 'readStoryIdBox';
  static const _storyIdBoxName = 'storyIdBox';
  static const _storyBoxName = 'storyBox';
  static const _commentBoxName = 'commentBox';
  final Future<Box<bool>> _readStoryIdBox;
  final Future<Box<List<int>>> _storyIdBox;
  final Future<Box<Map<dynamic, dynamic>>> _storyBox;
  final Future<LazyBox<Map<dynamic, dynamic>>> _commentBox;

  Future<bool> get hasCachedStories => _storyBox.then((box) => box.isNotEmpty);

  Future<bool> wasRead({required int id}) async {
    final box = await _readStoryIdBox;
    final val = box.get(id.toString());
    return val != null;
  }

  Future<void> cacheReadStoryId({required int id}) async {
    final box = await _readStoryIdBox;
    return box.put(id.toString(), true);
  }

  Future<List<int>> getAllReadStoriesIds() async {
    final box = await _readStoryIdBox;
    final allReads = box.keys.cast<String>().map(int.parse).toList();
    return allReads;
  }

  Future<void> cacheStoryIds(
      {required StoryType of, required List<int> ids}) async {
    final box = await _storyIdBox;
    return box.put(of.name, ids);
  }

  Future<void> cacheStory({required Story story}) async {
    final box = await _storyBox;
    return box.put(story.id.toString(), story.toJson());
  }

  Future<List<int>> getCachedStoryIds({required StoryType of}) async {
    final box = await _storyIdBox;
    final ids = box.get(of.name);
    return ids ?? [];
  }

  Stream<Story> getCachedStoriesStream({required List<int> ids}) async* {
    final box = await _storyBox;

    for (final id in ids) {
      final json = box.get(id.toString());

      if (json == null) {
        continue;
      }

      final story = Story.fromJson(json.cast<String, dynamic>());
      yield story;
    }

    return;
  }

  Future<Story?> getCachedStory({required int id}) async {
    final box = await _storyBox;
    final json = box.get(id.toString());
    if (json == null) {
      return null;
    }
    final story = Story.fromJson(json.cast<String, dynamic>());
    return story;
  }

  Future<void> cacheComment({required Comment comment}) async {
    final box = await _commentBox;
    return box.put(comment.id.toString(), comment.toJson());
  }

  Future<Comment?> getCachedComment({required int id}) async {
    final box = await _commentBox;
    final json = await box.get(id.toString());
    if (json == null) {
      return null;
    }
    final comment = Comment.fromJson(json.cast<String, dynamic>());
    return comment;
  }

  Stream<Comment> getCachedCommentsStream(
      {required List<int> ids, int level = 0}) async* {
    final box = await _commentBox;

    for (final id in ids) {
      final json = await box.get(id.toString());

      if (json != null) {
        final comment =
            Comment.fromJson(json.cast<String, dynamic>(), level: level);

        yield comment;
        yield* getCachedCommentsStream(ids: comment.kids, level: level + 1);
      }
    }
  }

  Future<int> deleteAllReadStoryIds() async {
    final box = await _readStoryIdBox;
    return box.clear();
  }

  Future<int> deleteAllStoryIds() async {
    final box = await _storyIdBox;
    return box.clear();
  }

  Future<int> deleteAllStories() async {
    final box = await _storyBox;
    return box.clear();
  }

  Future<int> deleteAllComments() async {
    final box = await _commentBox;
    return box.clear();
  }
}
