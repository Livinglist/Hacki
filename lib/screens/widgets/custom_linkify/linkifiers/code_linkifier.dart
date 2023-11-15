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
          final List<String> splitTexts = element.text.split(matchedText);

          final String preceding = splitTexts[0];

          list.addAll(
            parse(
              <LinkifyElement>[
                TextElement(preceding == '\n\n' ? '' : preceding),
              ],
              options,
            ),
          );

          String trimmedText = matchedText
              .replaceFirst(_openTag, '')
              .replaceFirst(_closeTag, '');
          trimmedText = '$trimmedText\n\n';

          list
            ..add(CodeElement(trimmedText))
            ..addAll(
              parse(
                <LinkifyElement>[
                  TextElement(splitTexts[1]),
                ],
                options,
              ),
            );
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
