import 'package:flutter/material.dart';
import 'package:linkify/linkify.dart';

class HighlightLinkifier extends Linkifier {
  HighlightLinkifier({
    required String highlightedText,
  }) : highlightRegExp = RegExp(
          highlightedText,
          caseSensitive: false,
        );

  final RegExp highlightRegExp;

  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    if (highlightRegExp.pattern.isEmpty) {
      return elements;
    }

    final List<LinkifyElement> list = <LinkifyElement>[];

    for (final LinkifyElement element in elements) {
      if (element is TextElement) {
        final RegExpMatch? match = highlightRegExp.firstMatch(
          element.text.trimLeft(),
        );
        if (match == null || match.group(0) == null) {
          list.add(element);
        } else {
          final String matchedText = match.group(0)!;
          final num pos =
              (element.text.indexOf(matchedText) - 1).clamp(0, double.infinity);
          final List<String> splitTexts = element.text.split(matchedText);

          int curPos = 0;
          bool added = false;

          for (final String text in splitTexts) {
            list.addAll(parse(<LinkifyElement>[TextElement(text)], options));

            curPos += text.length;

            if (!added && curPos >= pos) {
              added = true;
              list.add(HighlightElement(matchedText));
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

/// Represents an element that's highlighted.
@immutable
class HighlightElement extends LinkifyElement {
  HighlightElement(super.text);

  @override
  String toString() {
    return "HighlightElement: '$text'";
  }

  @override
  bool operator ==(Object other) => equals(other);

  @override
  bool equals(dynamic other) =>
      other is HighlightElement && super.equals(other);

  @override
  int get hashCode => text.hashCode;
}
