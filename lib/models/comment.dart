import 'dart:convert';

import 'package:hacki/models/item.dart';

class Comment extends Item {
  Comment({
    required super.id,
    required super.time,
    required super.parent,
    required super.score,
    required super.by,
    required super.text,
    required super.kids,
    required super.dead,
    required super.deleted,
    required this.level,
  }) : super(
          descendants: 0,
          parts: <int>[],
          title: '',
          url: '',
          type: '',
        );

  Comment.fromJson(Map<String, dynamic> json, {this.level = 0})
      : super(
          id: json['id'] as int? ?? 0,
          time: json['time'] as int? ?? 0,
          by: json['by'] as String? ?? '',
          text: json['text'] as String? ?? '',
          kids: (json['kids'] as List<dynamic>?)?.cast<int>() ?? <int>[],
          parent: json['parent'] as int? ?? 0,
          deleted: json['deleted'] as bool? ?? false,
          score: json['score'] as int? ?? 0,
          descendants: 0,
          dead: json['dead'] as bool? ?? false,
          parts: <int>[],
          title: '',
          url: '',
          type: '',
        );

  final int level;

  String get metadata => '''by $by $postedDate''';

  Comment copyWith({int? level}) {
    return Comment(
      id: id,
      time: time,
      parent: parent,
      score: score,
      by: by,
      text: text,
      kids: kids,
      dead: dead,
      deleted: deleted,
      level: level ?? this.level,
    );
  }

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'time': time,
        'by': by,
        'text': text,
        'kids': kids,
        'parent': parent,
        'deleted': deleted,
        'dead': dead,
        'score': score,
        'level': level,
      };

  @override
  String toString() {
    final String prettyString =
        const JsonEncoder.withIndent('  ').convert(this);
    return 'Comment $prettyString';
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        score,
        descendants,
        time,
        by,
        title,
        url,
        kids,
        dead,
        parts,
        deleted,
        parent,
        text,
        type,
      ];
}
