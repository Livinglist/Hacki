import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/item.dart';

class Comment extends Item {
  Comment({
    required int id,
    required int time,
    required int parent,
    required int score,
    required String by,
    required String text,
    required List<int> kids,
    required bool deleted,
  }) : super(
          id: id,
          time: time,
          by: by,
          text: text,
          kids: kids,
          parent: parent,
          deleted: deleted,
          score: score,
          descendants: 0,
          dead: false,
          parts: [],
          poll: 0,
          title: '',
          url: '',
          type: '',
        );

  Comment.fromJson(Map<String, dynamic> json)
      : super(
          id: json['id'] as int? ?? 0,
          time: json['time'] as int? ?? 0,
          by: json['by'] as String? ?? '',
          text: json['text'] as String? ?? '',
          kids: (json['kids'] as List?)?.cast<int>() ?? [],
          parent: json['parent'] as int? ?? 0,
          deleted: json['deleted'] as bool? ?? false,
          score: json['score'] as int? ?? 0,
          descendants: 0,
          dead: json['dead'] as bool? ?? false,
          parts: [],
          poll: 0,
          title: '',
          url: '',
          type: '',
        );

  String get postedDate =>
      DateTime.fromMillisecondsSinceEpoch(time * 1000).toReadableString();

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
      };

  @override
  List<Object?> get props => [
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
        poll,
        text,
        type,
      ];
}
