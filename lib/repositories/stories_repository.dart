import 'package:firebase/firebase_io.dart';
import 'package:hacki/models/models.dart';

class StoriesRepository {
  StoriesRepository({
    FirebaseClient? firebaseClient,
  }) : _firebaseClient = firebaseClient ?? FirebaseClient.anonymous();

  final FirebaseClient _firebaseClient;
  static const _baseUrl = 'https://hacker-news.firebaseio.com/v0/';

  Future<List<int>> fetchTopStoryIds({required StoryType of}) async {
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

  Stream<Story> fetchStoriesStream({required List<int> ids}) async* {
    for (final id in ids) {
      final story = await _firebaseClient
          .get('${_baseUrl}item/$id.json')
          .then((dynamic val) {
        final json = val as Map<String, dynamic>;
        final story = Story.fromJson(json);
        return story;
      });

      yield story;
    }
  }

  Future<Comment> fetchCommentBy({required String commentId}) async {
    final comment = await _firebaseClient
        .get('${_baseUrl}item/$commentId.json')
        .then((dynamic val) {
      final json = val as Map<String, dynamic>;
      final comment = Comment.fromJson(json);
      return comment;
    });

    return comment;
  }
}
