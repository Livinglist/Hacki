import 'package:flutter/material.dart';
import 'package:linkify/linkify.dart';

final RegExp _codeRegex =
    RegExp(r'\<pre\>\<code\>(.*?)\<\/code\>\<\/pre\>', dotAll: true);

class CodeLinkifier extends Linkifier {
  const CodeLinkifier();

  static const String _openTag = '<pre><code>';
  static const String _closeTag = '</code></pre>';

  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final List<LinkifyElement> list = <LinkifyElement>[];

    for (final LinkifyElement element in elements) {
      if (element is TextElement) {
        final RegExpMatch? match = _codeRegex.firstMatch(
          element.text.trimLeft(),
        );

        if (match == null || match.group(0) == null || match.group(1) == null) {
          list.add(element);
        } else {
          final String matchedText = match.group(0)!;
          final num pos = element.text.indexOf(matchedText);
          final List<String> splitTexts = element.text.split(matchedText);

          int curPos = 0;
          bool added = false;

          for (final String text in splitTexts) {
            list.addAll(parse(<LinkifyElement>[TextElement(text)], options));

            curPos += text.length;

            if (!added && curPos >= pos) {
              added = true;
              final String trimmedText = matchedText
                  .replaceFirst(_openTag, '')
                  .replaceFirst(_closeTag, '')
                  .replaceAll('\n\n', '\n');
              list.add(CodeElement(trimmedText));
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

/// Represents an element that is wrapped by <code> tag.
@immutable
class CodeElement extends LinkifyElement {
  CodeElement(super.text);

  @override
  String toString() {
    return "CodeElement: '$text'";
  }

  @override
  bool operator ==(Object other) => equals(other);

  @override
  bool equals(dynamic other) => other is CodeElement && super.equals(other);

  @override
  int get hashCode => text.hashCode;
}
