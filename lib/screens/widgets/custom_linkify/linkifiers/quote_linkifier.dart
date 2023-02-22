import 'package:flutter/cupertino.dart';
import 'package:flutter_linkify/flutter_linkify.dart';

/// For details on how this RegEx works, go to this link.
/// https://regex101.com/r/QN046t/1
final RegExp _quoteRegex = RegExp(
  r'(?=^> )(.*?)(?=\n)',
  multiLine: true,
);

class QuoteLinkifier extends Linkifier {
  const QuoteLinkifier();

  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final List<LinkifyElement> list = <LinkifyElement>[];

    for (final LinkifyElement element in elements) {
      if (element is TextElement) {
        final RegExpMatch? match = _quoteRegex.firstMatch(
          element.text.trimLeft(),
        );

        if (match == null) {
          list.add(element);
        } else {
          final String matchedText = match.group(0)!;
          final int pos = element.text.indexOf(matchedText);
          final List<String> splitTexts = element.text.split(matchedText);

          int curPos = 0;
          bool added = false;

          for (final String text in splitTexts) {
            list.addAll(parse(<TextElement>[TextElement(text)], options));
            curPos += text.length;
            if (!added && curPos >= pos) {
              added = true;
              list.add(QuoteElement(matchedText));
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

/// Represents an element containing an user tag
@immutable
class QuoteElement extends LinkifyElement {
  QuoteElement(super.text);

  @override
  String toString() {
    return "QuoteElement: '$text'";
  }

  @override
  bool operator ==(Object other) => equals(other);

  @override
  bool equals(dynamic other) => other is QuoteElement && super.equals(other);

  @override
  int get hashCode => text.hashCode;
}
