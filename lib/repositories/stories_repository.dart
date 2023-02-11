import 'package:flutter/foundation.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/utils/utils.dart';
import 'package:tuple/tuple.dart';

class StoriesRepository {
  StoriesRepository({
    FirebaseClient? firebaseClient,
  }) : _firebaseClient = firebaseClient ?? FirebaseClient.anonymous();

  final FirebaseClient _firebaseClient;
  static const String _baseUrl = 'https://hacker-news.firebaseio.com/v0/';

  Future<User> fetchUser({required String id}) async {
    final User user = await _firebaseClient
        .get('${_baseUrl}user/$id.json')
        .then((dynamic val) {
      final Map<String, dynamic> json = val as Map<String, dynamic>;
      final User user = User.fromJson(json);
      return user;
    });

    return user;
  }

  Future<List<int>> fetchStoryIds({required StoryType type}) async {
    final List<int> ids = await _firebaseClient
        .get('$_baseUrl${type.path}.json')
        .then((dynamic val) {
      final List<int> ids = (val as List<dynamic>).cast<int>();
      return ids;
    });

    return ids;
  }

  Future<Story?> fetchStory({required int id}) async {
    final Story? story = await _firebaseClient
        .get('${_baseUrl}item/$id.json')
        .then((dynamic json) => _parseJson(json as Map<String, dynamic>?))
        .then((Map<String, dynamic>? json) {
      if (json == null) return null;
      final Story story = Story.fromJson(json);
      return story;
    });

    return story;
  }

  Stream<Comment> fetchCommentsStream({
    required List<int> ids,
    int level = 0,
    Comment? Function(int)? getFromCache,
  }) async* {
    for (final int id in ids) {
      Comment? comment = getFromCache?.call(id)?.copyWith(level: level);

      comment ??= await _firebaseClient
          .get('${_baseUrl}item/$id.json')
          .then((dynamic json) => _parseJson(json as Map<String, dynamic>?))
          .then((Map<String, dynamic>? json) async {
        if (json == null) return null;

        final Comment comment = Comment.fromJson(json, level: level);
        return comment;
      });

      if (comment != null) {
        yield comment;
      }
    }
    return;
  }

  Stream<Comment> fetchAllCommentsRecursivelyStream({
    required List<int> ids,
    int level = 0,
    Comment? Function(int)? getFromCache,
  }) async* {
    for (final int id in ids) {
      Comment? comment = getFromCache?.call(id)?.copyWith(level: level);

      comment ??= await _firebaseClient
          .get('${_baseUrl}item/$id.json')
          .then((dynamic json) => _parseJson(json as Map<String, dynamic>?))
          .then((Map<String, dynamic>? json) async {
        if (json == null) return null;

        final Comment comment = Comment.fromJson(json, level: level);
        return comment;
      });

      if (comment != null) {
        yield comment;

        yield* fetchAllCommentsRecursivelyStream(
          ids: comment.kids,
          level: level + 1,
          getFromCache: getFromCache,
        );
      }
    }
    return;
  }

  Stream<Item> fetchItemsStream({required List<int> ids}) async* {
    for (final int id in ids) {
      final Item? item = await _firebaseClient
          .get('${_baseUrl}item/$id.json')
          .then((dynamic json) => _parseJson(json as Map<String, dynamic>?))
          .then((Map<String, dynamic>? json) async {
        if (json == null) return null;

        final String type = json['type'] as String;
        if (type == 'story' || type == 'job') {
          final Story story = Story.fromJson(json);
          return story;
        } else if (json['type'] == 'comment') {
          final Comment comment = Comment.fromJson(json);
          return comment;
        }
        return null;
      });

      if (item != null) {
        yield item;
      }
    }
  }

  Stream<Story> fetchStoriesStream({required List<int> ids}) async* {
    for (final int id in ids) {
      final Story? story = await _firebaseClient
          .get('${_baseUrl}item/$id.json')
          .then((dynamic json) => _parseJson(json as Map<String, dynamic>?))
          .then((Map<String, dynamic>? json) async {
        if (json == null) return null;
        final Story story = Story.fromJson(json);
        return story;
      });

      if (story != null) {
        yield story;
      }
    }
  }

  Stream<PollOption> fetchPollOptionsStream({required List<int> ids}) async* {
    for (final int id in ids) {
      final PollOption? option = await _firebaseClient
          .get('${_baseUrl}item/$id.json')
          .then((dynamic json) async {
        if (json == null) return null;
        final PollOption option =
            PollOption.fromJson(json as Map<String, dynamic>);
        return option;
      });

      if (option != null) {
        yield option;
      }
    }
  }

  Future<Comment?> fetchComment({required int id}) async {
    final Comment? comment = await _firebaseClient
        .get('${_baseUrl}item/$id.json')
        .then((dynamic json) => _parseJson(json as Map<String, dynamic>?))
        .then((Map<String, dynamic>? json) async {
      if (json == null) return null;

      final Comment comment = Comment.fromJson(json);
      return comment;
    });

    return comment;
  }

  Future<Comment?> fetchRawComment({required int id}) async {
    final Comment? comment = await _firebaseClient
        .get('${_baseUrl}item/$id.json')
        .then((dynamic val) async {
      if (val == null) return null;
      final Map<String, dynamic> json = val as Map<String, dynamic>;

      final Comment comment = Comment.fromJson(json);
      return comment;
    });

    return comment;
  }

  Future<Item?> fetchItem({required int id}) async {
    final Item? item = await _firebaseClient
        .get('${_baseUrl}item/$id.json')
        .then((dynamic json) => _parseJson(json as Map<String, dynamic>?))
        .then((Map<String, dynamic>? json) {
      if (json == null) return null;

      final String type = json['type'] as String;
      if (type == 'story' || type == 'job' || type == 'poll') {
        final Story story = Story.fromJson(json);
        return story;
      } else if (json['type'] == 'comment') {
        final Comment comment = Comment.fromJson(json);
        return comment;
      }
      return null;
    });

    return item;
  }

  Future<Item?> fetchRawItem({required int id}) async {
    final Item? item = await _firebaseClient
        .get('${_baseUrl}item/$id.json')
        .then((dynamic val) {
      if (val == null) return null;

      final Map<String, dynamic> json = val as Map<String, dynamic>;

      final String type = json['type'] as String;
      if (type == 'story' || type == 'job' || type == 'poll') {
        final Story story = Story.fromJson(json);
        return story;
      } else if (json['type'] == 'comment') {
        final Comment comment = Comment.fromJson(json);
        return comment;
      }
      return null;
    });

    return item;
  }

  Future<List<int>?> fetchSubmitted({required String of}) async {
    final List<int>? submitted = await _firebaseClient
        .get('${_baseUrl}user/$of.json')
        .then((dynamic val) {
      if (val == null) {
        return null;
      }
      final Map<String, dynamic> json = val as Map<String, dynamic>;
      final List<int> submitted =
          (json['submitted'] as List<dynamic>? ?? <dynamic>[]).cast<int>();
      return submitted;
    });

    return submitted;
  }

  Future<Story?> fetchParentStory({required int id}) async {
    Item? item;

    do {
      item = await fetchItem(id: item?.parent ?? id);
      if (item == null) return null;
    } while (item is Comment);

    return item as Story;
  }

  Future<Story?> fetchRawParentStory({required int id}) async {
    Item? item;

    do {
      item = await fetchRawItem(id: item?.parent ?? id);
      if (item == null) return null;
    } while (item is Comment);

    return item as Story;
  }

  Future<Tuple2<Story, List<Comment>>?> fetchParentStoryWithComments({
    required int id,
  }) async {
    Item? item;
    final List<Comment> parentComments = <Comment>[];

    do {
      item = await fetchItem(id: item?.parent ?? id);
      if (item is Comment) {
        parentComments.add(item);
      }
      if (item == null) return null;
    } while (item is Comment);

    for (int i = 0; i < parentComments.length; i++) {
      parentComments[i] =
          parentComments[i].copyWith(level: parentComments.length - i - 1);
    }

    return Tuple2<Story, List<Comment>>(
      item as Story,
      parentComments.reversed.toList(),
    );
  }

  Stream<Comment?> fetchAllChildrenComments({required List<int> ids}) async* {
    for (final int id in ids) {
      final Comment? comment = await fetchComment(id: id);
      if (comment != null) {
        yield comment;
        yield* fetchAllChildrenComments(ids: comment.kids);
      }
    }
  }

  Future<Map<String, dynamic>?> _parseJson(Map<String, dynamic>? json) async {
    if (json == null) return null;
    final String text = json['text'] as String? ?? '';
    final String parsedText = await compute<String, String>(
      HtmlUtil.parseHtml,
      text,
    );
    json['text'] = parsedText;
    return json;
  }
}
