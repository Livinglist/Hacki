import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hacki/config/locator.dart';
import 'package:hacki/models/models.dart';
import 'package:hacki/repositories/repositories.dart';
import 'package:hacki/services/services.dart';
import 'package:hacki/utils/utils.dart';
import 'package:logger/logger.dart';

/// [HackerNewsRepository] is for fetching
/// [Item] such as [Story], [PollOption], [Comment] or [User].
///
/// You can learn more about the Hacker News API at
/// https://github.com/HackerNews/API.
class HackerNewsRepository {
  HackerNewsRepository({
    FirebaseClient? firebaseClient,
    SembastRepository? sembastRepository,
    Logger? logger,
  })  : _firebaseClient = firebaseClient ?? FirebaseClient.anonymous(),
        _sembastRepository =
            sembastRepository ?? locator.get<SembastRepository>(),
        _logger = logger ?? locator.get<Logger>();

  final FirebaseClient _firebaseClient;
  final SembastRepository _sembastRepository;
  final Logger _logger;
  static const String _baseUrl = 'https://hacker-news.firebaseio.com/v0/';

  Future<Map<String, dynamic>?> _fetchItemJson(int id) async {
    return _firebaseClient
        .get('${_baseUrl}item/$id.json')
        .then((dynamic json) => _parseJson(json as Map<String, dynamic>?));
  }

  Future<Map<String, dynamic>?> _fetchRawItemJson(int id) async {
    return _firebaseClient
        .get('${_baseUrl}item/$id.json')
        .then((dynamic value) => value as Map<String, dynamic>?);
  }

  /// Fetch a [Item] based on its id.
  Future<Item?> fetchItem({required int id}) async {
    final Item? item =
        await _fetchItemJson(id).then((Map<String, dynamic>? json) {
      if (json == null) return null;

      if (json.isStory) {
        final Story story = Story.fromJson(json);
        return story;
      } else if (json.isComment) {
        final Comment comment = Comment.fromJson(json);
        return comment;
      }
      return null;
    });

    return item;
  }

  /// Fetch a raw [Item] based on its id.
  /// The content of [Item] will not be parsed, use this function only if
  /// the format of content doesn't matter, otherwise, use [fetchItem].
  Future<Item?> fetchRawItem({required int id}) async {
    final Item? item = await _fetchRawItemJson(id).then((dynamic val) {
      if (val == null) return null;

      final Map<String, dynamic> json = val as Map<String, dynamic>;

      if (json.isStory) {
        final Story story = Story.fromJson(json);
        return story;
      } else if (json.isComment) {
        final Comment comment = Comment.fromJson(json);
        return comment;
      }
      return null;
    });

    return item;
  }

  /// Fetch a [User] by its [id].
  /// Hacker News uses user's username as [id].
  Future<User?> fetchUser({required String id}) async {
    final User? user = await _firebaseClient
        .get('${_baseUrl}user/$id.json')
        .then((dynamic val) {
      final Map<String, dynamic>? json = val as Map<String, dynamic>?;

      if (json == null) return null;

      final User user = User.fromJson(json);
      return user;
    });

    return user;
  }

  /// Fetch a list of ids of [Story] or [Comment] submitted by the user.
  Future<List<int>?> fetchSubmitted({required String userId}) async {
    final List<int>? submitted = await _firebaseClient
        .get('${_baseUrl}user/$userId.json')
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

  /// Fetch ids of stories of a certain [StoryType].
  Future<List<int>> fetchStoryIds({required StoryType type}) async {
    final List<int> ids = await _firebaseClient
        .get('$_baseUrl${type.path}.json')
        .then((dynamic val) {
      final List<int> ids = (val as List<dynamic>).cast<int>();
      return ids;
    });

    return ids;
  }

  /// Fetch a [Story] based on its id.
  Future<Story?> fetchStory({required int id}) async {
    final Story? story =
        await _fetchItemJson(id).then((Map<String, dynamic>? json) {
      if (json == null) return null;
      final Story story = Story.fromJson(json);
      return story;
    });

    return story;
  }

  /// Fetch a [Comment] based on its id.
  Future<Comment?> fetchComment({required int id}) async {
    final Comment? comment =
        await _fetchItemJson(id).then((Map<String, dynamic>? json) async {
      if (json == null) return null;

      final Comment comment = Comment.fromJson(json);
      return comment;
    });

    return comment;
  }

  /// Fetch a raw [Comment] based on its id.
  /// The content of [Comment] will not be parsed, use this function only if
  /// the format of content doesn't matter, otherwise, use [fetchComment].
  Future<Comment?> fetchRawComment({required int id}) async {
    final Comment? comment =
        await _fetchRawItemJson(id).then((dynamic val) async {
      if (val == null) return null;
      final Map<String, dynamic> json = val as Map<String, dynamic>;

      final Comment comment = Comment.fromJson(json);
      return comment;
    });

    return comment;
  }

  /// Fetch the parent [Story] of a [Comment].
  Future<Story?> fetchParentStory({required int id}) async {
    Item? item;

    do {
      item = await fetchItem(id: item?.parent ?? id);
      if (item == null) return null;
    } while (item is Comment);

    return item as Story;
  }

  /// Fetch the raw parent [Story] of a [Comment].
  /// The content of [Story] will not be parsed, use this function only if
  /// the format of content doesn't matter, otherwise, use [fetchParentStory].
  Future<Story?> fetchRawParentStory({required int id}) async {
    Item? item;

    do {
      item = await fetchRawItem(id: item?.parent ?? id);
      if (item == null) return null;
    } while (item is Comment);

    return item as Story;
  }

  /// Fetch the parent [Story] of a [Comment] as well as
  /// the list of [Comment] traversed in order to reach the parent.
  Future<(Story, List<Comment>)?> fetchParentStoryWithComments({
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

    return (
      item as Story,
      parentComments.reversed.toList(),
    );
  }

  /// Fetch a list of [Comment] based on ids and return results
  /// using a stream.
  Stream<Comment> fetchCommentsStream({
    required List<int> ids,
    int level = 0,
    Comment? Function(int)? getFromCache,
  }) async* {
    for (final int id in ids) {
      Comment? comment = getFromCache?.call(id)?.copyWith(level: level);

      comment ??=
          await _fetchItemJson(id).then((Map<String, dynamic>? json) async {
        if (json == null) return null;

        final Comment comment = Comment.fromJson(json, level: level);

        if (!json.isFromCache) {
          unawaited(_sembastRepository.cacheComment(comment));
        }

        return comment;
      }).onError((Object? error, StackTrace stackTrace) {
        _logger.e(error, stackTrace: stackTrace);
        return _sembastRepository
            .getCachedComment(id: id)
            .then((Comment? value) => value?.copyWith(level: level));
      });

      if (comment != null) {
        yield comment;
      }
    }
    return;
  }

  /// Fetch a list of [Comment] based on ids recursively and
  /// return results using a stream.
  Stream<Comment> fetchAllCommentsRecursivelyStream({
    required List<int> ids,
    int level = 0,
    Comment? Function(int)? getFromCache,
  }) async* {
    for (final int id in ids) {
      Comment? comment = getFromCache?.call(id)?.copyWith(level: level);

      comment ??=
          await _fetchItemJson(id).then((Map<String, dynamic>? json) async {
        if (json == null) return null;

        final Comment comment = Comment.fromJson(json, level: level);

        if (!json.isFromCache) {
          unawaited(_sembastRepository.cacheComment(comment));
        }

        return comment;
      }).onError((Object? error, StackTrace stackTrace) {
        _logger.e(error, stackTrace: stackTrace);
        return _sembastRepository
            .getCachedComment(id: id)
            .then((Comment? value) => value?.copyWith(level: level));
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

  /// Fetch a list of [Item] based on ids and return results
  /// using a stream.
  Stream<Item> fetchItemsStream({required List<int> ids}) async* {
    for (final int id in ids) {
      final Item? item =
          await _fetchItemJson(id).then((Map<String, dynamic>? json) async {
        if (json == null) return null;

        if (json.isStory) {
          final Story story = Story.fromJson(json);
          return story;
        } else if (json.isComment) {
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

  /// Fetch a list of [Story] based on ids and return results
  /// using a stream.
  Stream<Story> fetchStoriesStream({required List<int> ids}) async* {
    for (final int id in ids) {
      final Story? story =
          await _fetchItemJson(id).then((Map<String, dynamic>? json) async {
        if (json == null) return null;
        final Story story = Story.fromJson(json);
        return story;
      });

      if (story != null) {
        yield story;
      }
    }
  }

  /// Fetch a list of [PollOption] based on ids and return results
  /// using a stream.
  Stream<PollOption> fetchPollOptionsStream({required List<int> ids}) async* {
    for (final int id in ids) {
      final PollOption? option =
          await _fetchRawItemJson(id).then((dynamic json) async {
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

  /// Fetch a list of [Comment] based on ids recursively.
  Stream<Comment?> fetchAllChildrenComments({required List<int> ids}) async* {
    for (final int id in ids) {
      final Comment? comment = await fetchComment(id: id);
      if (comment != null) {
        yield comment;
        yield* fetchAllChildrenComments(ids: comment.kids);
      }
    }
  }

  /// Parse the json of an [Item] by removing useless HTML tags.
  static Future<Map<String, dynamic>?> _parseJson(
    Map<String, dynamic>? json,
  ) async {
    if (json == null) return null;
    final int? itemId = json.itemId;

    String? cachedText;
    if (json.isComment && itemId != null) {
      cachedText =
          (await locator.get<SembastRepository>().getCachedComment(id: itemId))
              ?.text;
    }

    bool isValid(String? text) {
      return cachedText != null &&
          cachedText != '[delayed]' &&
          cachedText != '[flagged]';
    }

    if (isValid(cachedText)) {
      json
        ..text = cachedText
        ..isFromCache = true;
    } else {
      final String? text = json.text;
      if (text == null || text.isEmpty) return json;
      final String parsedText = await compute<String, String>(
        HtmlUtil.parseHtml,
        text,
      );
      json.text = parsedText;
    }

    return json;
  }
}

extension on Map<String, dynamic> {
  bool get isFromCache => this['fromCache'] == true;

  set isFromCache(bool value) {
    this['fromCache'] = value;
  }

  String? get text => this['text'] as String?;

  set text(String? value) {
    this['text'] = value;
  }

  int? get itemId => this['id'] as int?;

  String? get type => this['type'] as String?;

  bool get isStory => type == 'story' || type == 'job' || type == 'poll';

  bool get isComment => type == 'comment';
}
