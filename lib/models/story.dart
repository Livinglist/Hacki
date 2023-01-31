import 'package:hacki/config/constants.dart';
import 'package:hacki/models/item.dart';

enum StoryType {
  top('topstories'),
  best('beststories'),
  latest('newstories'),
  ask('askstories'),
  show('showstories');

  const StoryType(this.path);

  final String path;

  String get label {
    switch (this) {
      case StoryType.top:
        return 'TOP';
      case StoryType.best:
        return 'BEST';
      case StoryType.latest:
        return 'NEW';
      case StoryType.ask:
        return 'ASK';
      case StoryType.show:
        return 'SHOW';
    }
  }

  static int convertToSettingsValue(List<StoryType> tabs) {
    return int.parse(
      tabs
          .map((StoryType e) => e.index.toString())
          .reduce((String value, String element) => '$value$element'),
    );
  }
}

class Story extends Item {
  const Story({
    required super.descendants,
    required super.id,
    required super.score,
    required super.time,
    required super.by,
    required super.title,
    required super.type,
    required super.url,
    required super.text,
    required super.kids,
    required super.parts,
  }) : super(
          dead: false,
          deleted: false,
          parent: 0,
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
          kids: <int>[],
          dead: false,
          parts: <int>[],
          deleted: false,
          parent: 0,
          text: '',
          type: '',
        );

  Story.placeholder()
      : super(
          id: 0,
          score: 0,
          descendants: 0,
          time: 1171872000,
          by: 'Y Combinator',
          title: 'Hacker News Guidelines',
          url: Constants.guidelineLink,
          kids: <int>[],
          dead: false,
          parts: <int>[],
          deleted: false,
          parent: 0,
          text: '',
          type: '',
        );

  Story.fromJson(super.json) : super.fromJson();

  String get metadata =>
      '''$score point${score > 1 ? 's' : ''} by $by $postedDate | $descendants comment${descendants > 1 ? 's' : ''}''';

  String get simpleMetadata =>
      '''$score point${score > 1 ? 's' : ''} $descendants comment${descendants > 1 ? 's' : ''} $postedDate''';

  String get readableUrl {
    final Uri url = Uri.parse(this.url);
    final String authority = url.authority.replaceFirst('www.', '');
    return authority;
  }

  @override
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
    };
  }

  @override
  String toString() {
    // final String prettyString =
    //     const JsonEncoder.withIndent('  ').convert(this);
    // return 'Story $prettyString';
    return 'Story $id';
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        score,
        descendants,
        time,
        by,
        title,
        text,
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
