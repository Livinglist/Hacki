import 'package:hacki/models/item/buildable.dart';
import 'package:hacki/models/item/comment.dart';
import 'package:linkify/linkify.dart';

/// [BuildableComment] is a subtype of [Comment] which stores
/// the corresponding [LinkifyElement] for faster widget building.
class BuildableComment extends Comment with Buildable {
  BuildableComment({
    required super.id,
    required super.time,
    required super.parent,
    required super.score,
    required super.by,
    required super.text,
    required super.kids,
    required super.dead,
    required super.deleted,
    required super.hidden,
    required super.level,
    required super.isFromCache,
    required this.elements,
  });

  BuildableComment.fromComment(Comment comment, {required this.elements})
      : super(
          id: comment.id,
          time: comment.time,
          parent: comment.parent,
          score: comment.score,
          by: comment.by,
          text: comment.text,
          kids: comment.kids,
          dead: comment.dead,
          deleted: comment.deleted,
          level: comment.level,
          hidden: comment.hidden,
          isFromCache: comment.isFromCache,
        );

  @override
  BuildableComment copyWith({
    int? level,
    bool? hidden,
    int? kid,
  }) {
    return BuildableComment(
      id: id,
      time: time,
      parent: parent,
      score: score,
      by: by,
      text: text,
      kids: kid == null ? kids : <int>[...kids, kid],
      dead: dead,
      deleted: deleted,
      hidden: hidden ?? this.hidden,
      level: level ?? this.level,
      elements: elements,
      isFromCache: isFromCache,
    );
  }

  @override
  final List<LinkifyElement> elements;
}
