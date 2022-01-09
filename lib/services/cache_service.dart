import 'package:hacki/models/models.dart' show Comment;

class CacheService {
  static final _tappedStories = <int>{};
  static final _comments = <int, Comment>{};

  bool isFirstTimeReading(int storyId) => !_tappedStories.contains(storyId);

  void store(int storyId) => _tappedStories.add(storyId);

  void cacheComment(Comment comment) => _comments[comment.id] = comment;

  Comment? getComment(int id) => _comments[id];
}
