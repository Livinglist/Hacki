import 'package:hacki/models/models.dart' show Comment;

class CacheService {
  static final Set<int> _tappedStories = <int>{};
  static final Map<int, Comment> _comments = <int, Comment>{};
  static final Set<int> _commentsCollapsed = <int>{};
  static final Map<int, String> _drafts = <int, String>{};

  bool isFirstTimeReading(int storyId) => !_tappedStories.contains(storyId);

  bool isCollapsed(int commentId) => _commentsCollapsed.contains(commentId);

  void store(int storyId) => _tappedStories.add(storyId);

  void updateCollapsedComments(int commentId) {
    if (_commentsCollapsed.contains(commentId)) {
      _commentsCollapsed.remove(commentId);
    } else {
      _commentsCollapsed.add(commentId);
    }
  }

  void cacheComment(Comment comment) => _comments[comment.id] = comment;

  Comment? getComment(int id) => _comments[id];

  void resetComments() {
    _comments.clear();
  }

  void removeDraft({required int replyingTo}) => _drafts.remove(replyingTo);

  void cacheDraft({required String text, required int replyingTo}) =>
      _drafts[replyingTo] = text;

  String? getDraft({required int replyingTo}) => _drafts[replyingTo];
}
