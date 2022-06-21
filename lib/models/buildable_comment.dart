import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:hacki/models/comment.dart';
import 'package:hacki/models/models.dart';

class BuildableComment extends Comment {
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
    required super.level,
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
        );

  final List<LinkifyElement> elements;
}
