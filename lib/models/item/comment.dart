import 'package:hacki/models/item/item.dart';

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
    required super.hidden,
    required this.level,
  }) : super(
          descendants: 0,
          parts: <int>[],
          title: '',
          url: '',
          type: '',
        );

  Comment.fromJson(super.json, {this.level = 0}) : super.fromJson();

  final int level;

  String get metadata => '''by $by $timeAgo''';

  Comment copyWith({
    int? level,
    bool? hidden,
  }) {
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
      hidden: hidden ?? this.hidden,
      level: level ?? this.level,
    );
  }

  @override
  bool? get stringify => false;
}
