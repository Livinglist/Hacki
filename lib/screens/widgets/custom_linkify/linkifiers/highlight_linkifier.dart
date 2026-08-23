import 'package:linkify/linkify.dart';
import 'package:material_ui/material_ui.dart';

class HighlightLinkifier extends Linkifier {
  HighlightLinkifier({required String highlightedText})
    : highlightRegExp = RegExp(
        RegExp.escape(highlightedText),
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
      if (element is! TextElement) {
        list.add(element);
        continue;
      }

      final String text = element.text;
      int start = 0;
      bool foundMatch = false;

      for (final RegExpMatch match in highlightRegExp.allMatches(text)) {
        final String? matchedText = match.group(0);
        if (matchedText == null || matchedText.isEmpty) {
          continue;
        }

        foundMatch = true;

        if (match.start > start) {
          list.add(TextElement(text.substring(start, match.start)));
        }

        list.add(HighlightElement(matchedText));
        start = match.end;
      }

      if (!foundMatch) {
        list.add(element);
      } else if (start < text.length) {
        list.add(TextElement(text.substring(start)));
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
