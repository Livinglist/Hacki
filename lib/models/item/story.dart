import 'package:hacki/config/constants.dart';
import 'package:hacki/models/item/item.dart';

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

  Story.empty() : super.empty();

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
  String toString() {
    // final String prettyString =
    //     const JsonEncoder.withIndent('  ').convert(this);
    // return 'Story $prettyString';
    return 'Story $id';
  }
}
