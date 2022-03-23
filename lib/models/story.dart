import 'dart:convert';

import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/item.dart';

enum StoryType {
  top,
  latest,
  ask,
  show,
  jobs,
}

class Story extends Item {
  Story({
    required int descendants,
    required int id,
    required int score,
    required int time,
    required String by,
    required String title,
    required String type,
    required String url,
    required List<int> kids,
  }) : super(
          id: id,
          score: score,
          descendants: descendants,
          time: time,
          by: by,
          title: title,
          url: url,
          kids: kids,
          type: type,
          dead: false,
          parts: [],
          deleted: false,
          parent: 0,
          poll: 0,
          text: '',
        );

  Story.empty()
      : super(
          id: 0,
          score: 0,
          descendants: 0,
          time: 0,
          by: '',
          title: '',
          url: '',
          kids: [],
          dead: false,
          parts: [],
          deleted: false,
          parent: 0,
          poll: 0,
          text: '',
          type: '',
        );

  Story.fromJson(Map<String, dynamic> json)
      : super(
          descendants: json['descendants'] as int? ?? 0,
          id: json['id'] as int? ?? 0,
          score: json['score'] as int? ?? 0,
          time: json['time'] as int? ?? 0,
          by: json['by'] as String? ?? '',
          title: json['title'] as String? ?? '',
          url: json['url'] as String? ?? '',
          kids: (json['kids'] as List?)?.cast<int>() ?? [],
          text: json['text'] as String? ?? '',
          dead: json['dead'] as bool? ?? false,
          deleted: json['deleted'] as bool? ?? false,
          type: json['type'] as String? ?? '',
          parts: [],
          parent: 0,
          poll: 0,
        );

  String get postedDate =>
      DateTime.fromMillisecondsSinceEpoch(time * 1000).toReadableString();

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'descendants': descendants,
      'id': id,
      'score': score,
      'time': time,
      'by': by,
      'title': title,
      'url': url,
      'kids': kids,
      'text': text,
      'dead': dead,
      'deleted': deleted,
      'type': type,
    };
  }

  @override
  String toString() {
    final prettyString = const JsonEncoder.withIndent('  ').convert(this);
    return 'Story $prettyString';
  }

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
