import 'package:flutter/cupertino.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

final RegExp _emphasisRegex = RegExp(
  r'\*(.*?)\*',
  multiLine: true,
);

class EmphasisLinkifier extends Linkifier {
  const EmphasisLinkifier();

  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final List<LinkifyElement> list = <LinkifyElement>[];

    for (final LinkifyElement element in elements) {
      if (element is TextElement) {
        final RegExpMatch? match = _emphasisRegex.firstMatch(
          element.text.trimLeft(),
        );

        if (element.text == '* * *' ||
            match == null ||
            match.group(0) == null ||
            match.group(1) == null) {
          list.add(element);
        } else {
          final String matchedText = match.group(1)!;
          final num pos =
              (element.text.indexOf(matchedText) - 1).clamp(0, double.infinity);
          final List<String> splitTexts = element.text.split(match.group(0)!);

          int curPos = 0;
          bool added = false;

          for (final String text in splitTexts) {
            list.addAll(parse(<LinkifyElement>[TextElement(text)], options));

            curPos += text.length;

            if (!added && curPos >= pos) {
              added = true;
              list.add(EmphasisElement(matchedText));
            }
          }
        }
      } else {
        list.add(element);
      }
    }

    return list;
  }
}

/// Represents an element wrapped around '*'.
@immutable
class EmphasisElement extends LinkifyElement {
  EmphasisElement(super.text);

  @override
  String toString() {
    return "EmphasisElement: '$text'";
  }

  @override
  bool operator ==(Object other) => equals(other);

  @override
  bool equals(dynamic other) => other is EmphasisElement && super.equals(other);

  @override
  int get hashCode => text.hashCode;
}
