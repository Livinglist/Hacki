import 'package:hacki/models/models.dart' show Comment;

class CommentCache {
  static final Map<int, Comment> _comments = <int, Comment>{};

  void cacheComment(Comment comment) {
    final bool isDelayed = comment.text.trim() == '[delayed]';
    if (!isDelayed) {
      _comments[comment.id] = comment.copyWithoutCollapseState();
    } else {
      return;
    }

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

  Stream<Comment> getCommentsStream({
    required List<int> ids,
    int level = 0,
  }) async* {
    for (final int id in ids) {
      final Comment? comment = getComment(id);

      if (comment != null) {
        yield comment.copyWith(level: level);
        yield* getCommentsStream(ids: comment.kids, level: level + 1);
      }
    }
  }
}
