import 'package:flutter/foundation.dart';
import 'package:hacki/models/models.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';

/// [CacheRepository] is for storing stories and comments for offline reading.
/// It's using [Hive] as its database which is being stored in temp directory.
class CacheRepository {
  CacheRepository({
    Future<Box<List<int>>>? storyIdBox,
    Future<Box<Map<dynamic, dynamic>>>? storyBox,
    Future<Box<String>>? webPageBox,
    Future<LazyBox<Map<dynamic, dynamic>>>? commentBox,
  })  : _storyIdBox = storyIdBox ?? Hive.openBox<List<int>>(_storyIdBoxName),
        _storyBox =
            storyBox ?? Hive.openBox<Map<dynamic, dynamic>>(_storyBoxName),
        _webPageBox = webPageBox ?? Hive.openBox<String>(_webPageBoxName),
        _commentBox = commentBox ??
            Hive.openLazyBox<Map<dynamic, dynamic>>(_commentBoxName);

  static const String _storyIdBoxName = 'storyIdBox';
  static const String _storyBoxName = 'storyBox';
  static const String _commentBoxName = 'commentBox';
  static const String _webPageBoxName = 'webPageBox';
  final Future<Box<List<int>>> _storyIdBox;
  final Future<Box<Map<dynamic, dynamic>>> _storyBox;
  final Future<LazyBox<Map<dynamic, dynamic>>> _commentBox;
  final Future<Box<String>> _webPageBox;

  Future<bool> get hasCachedStories =>
      _storyBox.then((Box<Map<dynamic, dynamic>> box) => box.isNotEmpty);

  Future<void> cacheStoryIds({
    required StoryType of,
    required List<int> ids,
  }) async {
    final Box<List<int>> box = await _storyIdBox;
    return box.put(of.name, ids);
  }

  Future<void> cacheStory({required Story story}) async {
    final Box<Map<dynamic, dynamic>> box = await _storyBox;
    return box.put(story.id.toString(), story.toJson());
  }

  Future<void> cacheUrl({required String url}) async {
    final Box<String> box = await _webPageBox;
    final String html = await compute(downloadWebPage, url);
    return box.put(url, html);
  }

  Future<String?> getHtml({required String url}) async {
    final Box<String> box = await _webPageBox;
    return box.get(url);
  }

  Future<bool> hasCachedWebPage({required String url}) async {
    final Box<String> box = await _webPageBox;
    return box.containsKey(url);
  }

  Future<List<int>> getCachedStoryIds({required StoryType of}) async {
    final Box<List<int>> box = await _storyIdBox;
    final List<int>? ids = box.get(of.name);
    return ids ?? <int>[];
  }

  Stream<Story> getCachedStoriesStream({required List<int> ids}) async* {
    final Box<Map<dynamic, dynamic>> box = await _storyBox;

    for (final int id in ids) {
      final Map<dynamic, dynamic>? json = box.get(id.toString());

      if (json == null) {
        continue;
      }

      final Story story = Story.fromJson(json.cast<String, dynamic>());
      yield story;
    }

    return;
  }

  Future<Story?> getCachedStory({required int id}) async {
    final Box<Map<dynamic, dynamic>> box = await _storyBox;
    final Map<dynamic, dynamic>? json = box.get(id.toString());
    if (json == null) {
      return null;
    }
    final Story story = Story.fromJson(json.cast<String, dynamic>());
    return story;
  }

  Future<void> cacheComment({required Comment comment}) async {
    final LazyBox<Map<dynamic, dynamic>> box = await _commentBox;
    return box.put(comment.id.toString(), comment.toJson());
  }

  Future<Comment?> getCachedComment({required int id}) async {
    final LazyBox<Map<dynamic, dynamic>> box = await _commentBox;
    final Map<dynamic, dynamic>? json = await box.get(id.toString());
    if (json == null) {
      return null;
    }
    final Comment comment = Comment.fromJson(json.cast<String, dynamic>());
    return comment;
  }

  Stream<Comment> getCachedCommentsStream({
    required List<int> ids,
    int level = 0,
  }) async* {
    final LazyBox<Map<dynamic, dynamic>> box = await _commentBox;

    for (final int id in ids) {
      final Map<dynamic, dynamic>? json = await box.get(id.toString());

      if (json != null) {
        final Comment comment =
            Comment.fromJson(json.cast<String, dynamic>(), level: level);

        yield comment;
        yield* getCachedCommentsStream(ids: comment.kids, level: level + 1);
      }
    }
  }

  Future<int> deleteAllStoryIds() async {
    final Box<List<int>> box = await _storyIdBox;
    return box.clear();
  }

  Future<int> deleteAllStories() async {
    final Box<Map<dynamic, dynamic>> box = await _storyBox;
    return box.clear();
  }

  Future<int> deleteAllComments() async {
    final LazyBox<Map<dynamic, dynamic>> box = await _commentBox;
    return box.clear();
  }

  Future<int> deleteAllWebPages() async {
    final Box<String> box = await _webPageBox;
    return box.clear();
  }

  Future<int> deleteAll() async {
    return deleteAllStoryIds()
        .whenComplete(deleteAllStories)
        .whenComplete(deleteAllComments)
        .whenComplete(deleteAllWebPages);
  }

  static Future<String> downloadWebPage(String link) async {
    try {
      final Client client = Client();
      final Uri url = Uri.parse(link);
      final Response response = await client.get(url);
      final String body = response.body;
      return body;
    } catch (_) {
      return '''Web page not available.''';
    }
  }
}
