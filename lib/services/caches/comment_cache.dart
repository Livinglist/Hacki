import 'package:hacki/models/models.dart' show Comment;

class CommentCache {
  static final Map<int, Comment> _comments = <int, Comment>{};

  void cacheComment(Comment comment) => _comments[comment.id] = comment;

  Comment? getComment(int id) => _comments[id];

  void resetComments() {
    _comments.clear();
  }
}
