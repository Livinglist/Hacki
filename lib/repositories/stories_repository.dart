import 'package:flutter/foundation.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/services/services.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:tuple/tuple.dart';

class StoriesRepository {
  StoriesRepository({
    FirebaseClient? firebaseClient,
  }) : _firebaseClient = firebaseClient ?? FirebaseClient.anonymous();

  final FirebaseClient _firebaseClient;
  static const _baseUrl = 'https://hacker-news.firebaseio.com/v0/';

  Future<User> fetchUserById({required String userId}) async {
    final user = await _firebaseClient
        .get('${_baseUrl}user/$userId.json')
        .then((dynamic val) {
      final json = val as Map<String, dynamic>;
      final user = User.fromJson(json);
      return user;
    });

    return user;
  }

  Future<List<int>> fetchStoryIds({required StoryType of}) async {
    final suffix = () {
      switch (of) {
        case StoryType.top:
          return 'topstories.json';
        case StoryType.latest:
          return 'newstories.json';
        case StoryType.ask:
          return 'askstories.json';
        case StoryType.show:
          return 'showstories.json';
        case StoryType.jobs:
          return 'jobstories.json';
      }
    }();
    final ids =
        await _firebaseClient.get('$_baseUrl$suffix').then((dynamic val) {
      final ids = (val as List).cast<int>();
      return ids;
    });

    return ids;
  }

  Future<Story> fetchStoryById(int id) async {
    final story = await _firebaseClient
        .get('${_baseUrl}item/$id.json')
        .then((dynamic val) {
      final json = val as Map<String, dynamic>;
      final story = Story.fromJson(json);
      return story;
    });

    return story;
  }

  Stream<Item> fetchItemsStream({required List<int> ids}) async* {
    for (final id in ids) {
      final item = await _firebaseClient
          .get('${_baseUrl}item/$id.json')
          .then((dynamic val) async {
        if (val == null) {
          return null;
        }
        final json = val as Map<String, dynamic>;
        final type = json['type'] as String;
        if (type == 'story' || type == 'job') {
          final story = Story.fromJson(json);
          return story;
        } else if (json['type'] == 'comment') {
          final text = json['text'] as String? ?? '';
          final parsedText = await compute<String, String>(_parseHtml, text);
          json['text'] = parsedText;
          final comment = Comment.fromJson(json);
          return comment;
        }
      });

      if (item != null) {
        yield item;
      }
    }
  }

  Stream<Story> fetchStoriesStream({required List<int> ids}) async* {
    for (final id in ids) {
      final story = await _firebaseClient
          .get('${_baseUrl}item/$id.json')
          .then((dynamic val) {
        if (val == null) {
          return null;
        }
        final json = val as Map<String, dynamic>;
        final story = Story.fromJson(json);
        return story;
      });

      if (story != null) {
        yield story;
      }
    }
  }

  Future<Comment?> fetchCommentBy({required int id}) async {
    final comment = await _firebaseClient
        .get('${_baseUrl}item/$id.json')
        .then((dynamic val) async {
      if (val == null) {
        return null;
      }
      final json = val as Map<String, dynamic>;
      final text = json['text'] as String? ?? '';
      final parsedText = await compute<String, String>(_parseHtml, text);
      json['text'] = parsedText;

      final comment = Comment.fromJson(json);
      return comment;
    });

    return comment;
  }

  Future<Item?> fetchItemBy({required int id}) async {
    final item = await _firebaseClient
        .get('${_baseUrl}item/$id.json')
        .then((dynamic val) async {
      if (val == null) {
        return null;
      }
      final json = val as Map<String, dynamic>;
      final type = json['type'] as String;
      if (type == 'story' || type == 'job') {
        final story = Story.fromJson(json);
        return story;
      } else if (json['type'] == 'comment') {
        final text = json['text'] as String? ?? '';
        final parsedText = await compute<String, String>(_parseHtml, text);
        json['text'] = parsedText;
        final comment = Comment.fromJson(json);
        return comment;
      }
    });

    return item;
  }

  Future<List<int>?> fetchSubmitted({required String of}) async {
    final submitted = await _firebaseClient
        .get('${_baseUrl}user/$of.json')
        .then((dynamic val) {
      if (val == null) {
        return null;
      }
      final json = val as Map<String, dynamic>;
      final submitted = (json['submitted'] as List? ?? <dynamic>[]).cast<int>();
      return submitted;
    });

    return submitted;
  }

  Future<Story?> fetchParentStory({required int id}) async {
    Item? item;

    do {
      item = await fetchItemBy(id: item?.parent ?? id);
      if (item == null) return null;
    } while (item is Comment);

    return item as Story;
  }

  Future<Tuple2<Story, List<Comment>>?> fetchParentStoryWithComments(
      {required int id}) async {
    Item? item;
    final parentComments = <Comment>[];

    do {
      item = await fetchItemBy(id: item?.parent ?? id);
      if (item is Comment) {
        parentComments.add(item);
      }
      if (item == null) return null;
    } while (item is Comment);

    return Tuple2<Story, List<Comment>>(item as Story, parentComments);
  }

  static String _parseHtml(String text) {
    return HtmlUnescape()
        .convert(text)
        .replaceAll('<p>', '\n')
        .replaceAllMapped(
          RegExp(r'\<i\>(.*?)\<\/i\>'),
          (Match match) => '*${match[1]}*',
        )
        .replaceAllMapped(
          RegExp(r'\<pre\>\<code\>(.*?)\<\/code\>\<\/pre\>', dotAll: true),
          (Match match) => match[1]?.trimRight() ?? '',
        )
        .replaceAllMapped(
          RegExp(r'\<a href=\"(.*?)\".*?\>.*?\<\/a\>'),
          (Match match) => match[1] ?? '',
        )
        .replaceAll('\n', '\n\n');
  }
}
