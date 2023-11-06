import 'dart:math';

import 'package:flutter/widgets.dart' show StringCharacters, immutable;
import 'package:linkify/linkify.dart';

final RegExp _urlRegex = RegExp(
  r'''^(.*?)((?:https?:\/\/|www\.)[^\s/$.?#].[\/\\\%:\?=&#@;A-Za-z0-9()+_.,'~-]*)''',
  caseSensitive: false,
  dotAll: true,
);

final RegExp _looseUrlRegex = RegExp(
  r'''^(.*?)((https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,4}\b([-a-zA-Z0-9@:%_\+.~#?&//="'`]*))''',
  caseSensitive: false,
  dotAll: true,
);

final RegExp _protocolIdentifierRegex = RegExp(
  r'^(https?:\/\/)',
  caseSensitive: false,
);

class UrlLinkifier extends Linkifier {
  const UrlLinkifier();

  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final List<LinkifyElement> list = <LinkifyElement>[];

    for (final LinkifyElement element in elements) {
      if (element is TextElement) {
        final RegExpMatch? match = options.looseUrl
            ? _looseUrlRegex.firstMatch(element.text)
            : _urlRegex.firstMatch(element.text);

        if (match == null) {
          list.add(element);
        } else {
          final String text = element.text.replaceFirst(match.group(0)!, '');

          if (match.group(1)?.isNotEmpty ?? false) {
            list.add(TextElement(match.group(1)!));
          }

          if (match.group(2)?.isNotEmpty ?? false) {
            String originalUrl = match.group(2)!;
            String originText = originalUrl;
            String? end;

            if ((options.excludeLastPeriod) &&
                originalUrl[originalUrl.length - 1] == '.') {
              end = '.';
              originText = originText.substring(0, originText.length - 1);
              originalUrl = originalUrl.substring(0, originalUrl.length - 1);
            }

            String url = originalUrl;

            if (!originalUrl.startsWith(_protocolIdentifierRegex)) {
              originalUrl = (options.defaultToHttps ? 'https://' : 'http://') +
                  originalUrl;
            }

            if (url.contains(')')) {
              int openCount = 0;
              int closeCount = 0;
              for (final String c in url.characters) {
                if (c == '(') {
                  openCount++;
                } else if (c == ')') {
                  closeCount++;
                }
              }

              if (openCount != closeCount) {
                final int index = max(0, url.lastIndexOf(')'));
                url = url.substring(0, index);
                end = originalUrl.substring(index);
              }
            }

            if (url.endsWith(',')) {
              url = url.substring(0, max(0, url.length - 1));
              end = '$end,';
            }

            if ((options.humanize) || (options.removeWww)) {
              if (options.humanize) {
                url = url.replaceFirst(RegExp('https?://'), '');
              }
              if (options.removeWww) {
                url = url.replaceFirst(RegExp(r'www\.'), '');
              }

              list.add(UrlElement(originalUrl, url, originText));
            } else {
              list.add(UrlElement(url, url, originText));
            }

            if (end != null) {
              list.add(TextElement(end));
            }
          }

          if (text.isNotEmpty) {
            list.addAll(parse(<LinkifyElement>[TextElement(text)], options));
          }
        }
      } else {
        list.add(element);
      }
    }

    return list;
  }
}

/// Represents an element containing a link
@immutable
class UrlElement extends LinkableElement {
  UrlElement(String url, [String? text, String? originText])
      : super(text, url, originText);

  @override
  String toString() {
    return "LinkElement: '$url' ($text)";
  }

  @override
  bool operator ==(Object other) => equals(other);

  @override
  int get hashCode => Object.hash(text, originText, url);

  @override
  bool equals(dynamic other) => other is UrlElement && super.equals(other);
}
