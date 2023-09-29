import 'package:flutter/material.dart';
import 'package:linkify/linkify.dart';

final RegExp _codeRegex =
    RegExp(r'\<pre\>\<code\>(.*?)\<\/code\>\<\/pre\>', dotAll: true);

class CodeLinkifier extends Linkifier {
  const CodeLinkifier();

  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final List<LinkifyElement> list = <LinkifyElement>[];

    for (final LinkifyElement element in elements) {
      if (element is TextElement) {
        const String openTag = '<pre><code>';
        const String closeTag = '</code></pre>';

        final String? match = _codeRegex
            .stringMatch(element.text)
            ?.replaceFirst(openTag, '')
            .replaceFirst(closeTag, '');

        if (match == null) {
          list.add(element);
        } else {
          final String matchedText = match;
          final int pos = element.text.indexOf(matchedText);
          final List<String> splitTexts = element.text.split(matchedText);

          int curPos = 0;
          bool added = false;

          for (String text in splitTexts) {
            if (text.contains(openTag)) {
              text = text.replaceFirst(openTag, '');
              curPos += text.length + openTag.length;
            } else if (text.contains(closeTag)) {
              text = text.replaceFirst(closeTag, '');
              curPos += text.length + closeTag.length;
            } else {
              curPos += text.length;
            }
            list.addAll(parse(<TextElement>[TextElement(text)], options));

            if (!added && curPos >= pos) {
              added = true;
              list.add(CodeElement(matchedText));
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
