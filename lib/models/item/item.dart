import 'package:equatable/equatable.dart';
import 'package:hacki/extensions/date_time_extension.dart';
import 'package:hacki/models/item/comment.dart';
import 'package:hacki/models/item/poll_option.dart';
import 'package:hacki/models/item/story.dart';

export 'buildable.dart';
export 'buildable_comment.dart';
export 'buildable_story.dart';
export 'comment.dart';
export 'poll_option.dart';
export 'story.dart';

/// [Item] is the base type of [Story], [Comment] and [PollOption].
class Item extends Equatable {
  const Item({
    required this.id,
    required this.deleted,
    required this.by,
    required this.time,
    required this.text,
    required this.dead,
    required this.parent,
    required this.kids,
    required this.url,
    required this.score,
    required this.title,
    required this.type,
    required this.parts,
    required this.descendants,
    required this.hidden,
  });

  Item.empty()
      : id = 0,
        score = 0,
        descendants = 0,
        time = 0,
        by = '',
        title = '',
        url = '',
        kids = <int>[],
        parts = <int>[],
        dead = false,
        deleted = false,
        hidden = false,
        parent = 0,
        text = '',
        type = '';

  Item.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int? ?? 0,
        score = json['score'] as int? ?? 0,
        descendants = json['descendants'] as int? ?? 0,
        time = json['time'] as int? ?? 0,
        by = json['by'] as String? ?? '',
        title = json['title'] as String? ?? '',
        text = json['text'] as String? ?? '',
        url = json['url'] as String? ?? '',
        kids = (json['kids'] as List<dynamic>?)?.cast<int>() ?? <int>[],
        dead = json['dead'] as bool? ?? false,
        deleted = json['deleted'] as bool? ?? false,
        parent = json['parent'] as int? ?? 0,
        parts = (json['parts'] as List<dynamic>?)?.cast<int>() ?? <int>[],
        type = json['type'] as String? ?? '',
        hidden = json['hidden'] as bool? ?? false;

  final int id;
  final int time;
  final int score;
  final int parent;

  /// The total comments count for stories and polls.
  final int descendants;

  final bool deleted;
  final bool dead;

  /// Whether or not the item should be hidden.
  /// true if any of filter keywords set by user presents in [text]
  /// or [title].
  final bool hidden;

  final String by;
  final String text;
  final String url;
  final String title;
  final String type;

  final List<int> kids;
  final List<int> parts;

  String get timeAgo =>
      DateTime.fromMillisecondsSinceEpoch(time * 1000).toTimeAgoString();

  bool get isPoll => type == 'poll';

  bool get isStory => type == 'story';

  bool get isJob => type == 'job';

  bool get isComment => type == 'comment';

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
      'parent': parent,
    };
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        deleted,
        by,
        time,
        text,
        dead,
        parent,
        kids,
        url,
        score,
        title,
        type,
        parts,
        descendants,
        hidden,
      ];
}
