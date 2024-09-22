import 'package:hacki/models/models.dart' show Comment;

class CommentCache {
  static final Map<int, Comment> _comments = <int, Comment>{};

  void cacheComment(Comment comment) {
    _comments[comment.id] = comment;

    /// Comments fetched from `HackerNewsWebRepository` doesn't have populated
    /// `kids` field, this is why we need to update that of the parent
    /// comment here.
    final int parentId = comment.parent;
    final Comment? parent = _comments[parentId];
    if (parent == null || parent.kids.contains(comment.id)) return;
    final Comment updatedParent = parent.copyWith(kid: comment.id);
    _comments[parentId] = updatedParent;
  }

  Comment? getComment(int id) => _comments[id];

  void resetComments() {
    _comments.clear();
  }
}
