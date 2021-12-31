import 'package:firebase/firebase_io.dart';
import 'package:hacki/models/models.dart';

class StoriesRepository {
  StoriesRepository({
    FirebaseClient? firebaseClient,
  }) : _firebaseClient = firebaseClient ?? FirebaseClient.anonymous();

  final FirebaseClient _firebaseClient;
  static const _baseUrl = 'https://hacker-news.firebaseio.com/v0/';

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
          .then((dynamic val) {
        if (val == null) {
          return null;
        }
        final json = val as Map<String, dynamic>;
        final type = json['type'] as String;
        if (type == 'story' || type == 'job') {
          final story = Story.fromJson(json);
          return story;
        } else if (json['type'] == 'comment') {
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

  Future<Comment?> fetchCommentBy({required String commentId}) async {
    final comment = await _firebaseClient
        .get('${_baseUrl}item/$commentId.json')
        .then((dynamic val) {
      if (val == null) {
        return null;
      }
      final json = val as Map<String, dynamic>;
      final comment = Comment.fromJson(json);
      return comment;
    });

    return comment;
  }

  Future<Item?> fetchItemBy({required String id}) async {
    final item = await _firebaseClient
        .get('${_baseUrl}item/$id.json')
        .then((dynamic val) {
      if (val == null) {
        return null;
      }
      final json = val as Map<String, dynamic>;
      final type = json['type'] as String;
      if (type == 'story' || type == 'job') {
        final story = Story.fromJson(json);
        return story;
      } else if (json['type'] == 'comment') {
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
      final submitted = (json['submitted'] as List).cast<int>();
      return submitted;
    });

    return submitted;
  }

  Future<Story?> fetchParentStory({required String id}) async {
    Item? item;

    do {
      item = await fetchItemBy(id: item?.parent.toString() ?? id);
      if (item == null) return null;
    } while (item is Comment);

    return item as Story;
  }
}
