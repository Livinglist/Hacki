import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:html_unescape/html_unescape.dart';

abstract class HtmlUtil {
  static String? getTitle(dynamic input) =>
      parser.parse(input).head?.querySelector('title')?.text;

  static dom.Element? getBody(dynamic input) => parser.parse(input).body;

  static bool hasMatch(dom.Element? element, {required String selector}) =>
      element?.querySelector(selector) != null;

  static Iterable<String>? getIds(
    dom.Element? element, {
    required String selector,
  }) =>
      element
          ?.querySelectorAll(selector)
          .map((dom.Element element) => element.id);

  static Map<String, String>? getHiddenFormValues(dynamic input) {
    final Iterable<dom.Element>? hiddenInputs = getBody(input)
        ?.getElementsByTagName('form')
        .first
        .querySelectorAll("input[type='hidden']");
    return <String, String>{
      if (hiddenInputs != null)
        for (final dom.Element hiddenInput in hiddenInputs)
          hiddenInput.attributes['name']!: hiddenInput.attributes['value']!,
    };
  }

  static String parseHtml(String text) {
    return HtmlUnescape()
        .convert(text)
        .replaceAllMapped(
          RegExp(r'\<pre\>\<code\>(.*?)\<\/code\>\<\/pre\>', dotAll: true),
          (Match match) =>
              '<pre><code>${match[1]?.replaceAll('\n', '[break]')}</code></pre>',
        )
        .replaceAll('\n', '')
        .replaceAllMapped(
          RegExp(r'\<p\>(.*?)\<p\>', dotAll: true),
          (Match match) => '\n${match[1]?.replaceAll('\n', ' ')}\n',
        )
        .replaceAllMapped(
          RegExp(r'\<i\>(.*?)\<\/i\>'),
          (Match match) => '*${match[1]}*',
        )
        .replaceAllMapped(
          RegExp(r'\<a href=\"(.*?)\".*?\>.*?\<\/a\>'),
          (Match match) => match[1] ?? '',
        )
        .replaceAll('\n', '\n\n')
        .replaceAll('<p>', '\n\n')
        .replaceAll('[break]', '\n');
  }
}
