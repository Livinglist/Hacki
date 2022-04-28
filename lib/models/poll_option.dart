import 'dart:convert';

import 'package:hacki/extensions/extensions.dart';
import 'package:hacki/models/item.dart';

class PollOption extends Item {
  const PollOption({
    required int id,
    required int score,
    required int time,
    required int parent,
    required String by,
    required String title,
    required String text,
    required String type,
    required String url,
    required List<int> kids,
    required List<int> parts,
    required this.ratio,
  }) : super(
          id: id,
          score: score,
          descendants: 0,
          time: time,
          by: by,
          title: title,
          url: url,
          kids: kids,
          type: type,
          dead: false,
          parts: parts,
          deleted: false,
          parent: parent,
          text: text,
        );

  PollOption.empty()
      : ratio = 0,
        super(
          id: 0,
          score: 0,
          descendants: 0,
          time: 0,
          by: '',
          title: '',
          url: '',
          kids: <int>[],
          dead: false,
          parts: <int>[],
          deleted: false,
          parent: 0,
          text: '',
          type: '',
        );

  PollOption.fromJson(Map<String, dynamic> json)
      : ratio = 0,
        super(
          descendants: 0,
          id: json['id'] as int? ?? 0,
          score: json['score'] as int? ?? 0,
          time: json['time'] as int? ?? 0,
          by: json['by'] as String? ?? '',
          title: json['title'] as String? ?? '',
          url: json['url'] as String? ?? '',
          kids: <int>[],
          text: json['text'] as String? ?? '',
          dead: json['dead'] as bool? ?? false,
          deleted: json['deleted'] as bool? ?? false,
          type: json['type'] as String? ?? '',
          parts: <int>[],
          parent: 0,
        );

  final double ratio;

  String get postedDate =>
      DateTime.fromMillisecondsSinceEpoch(time * 1000).toReadableString();

  PollOption copyWith({double? ratio}) {
    return PollOption(
      id: id,
      score: score,
      time: time,
      parent: parent,
      by: by,
      title: title,
      text: text,
      type: type,
      url: url,
      kids: kids,
      parts: parts,
      ratio: ratio ?? this.ratio,
    );
  }

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
      'parts': parts,
      'ratio': ratio,
    };
  }

  @override
  String toString() {
    final String prettyString =
        const JsonEncoder.withIndent('  ').convert(this);
    return 'PollOption $prettyString';
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
