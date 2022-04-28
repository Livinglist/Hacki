import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;
import 'package:html_unescape/html_unescape.dart';

class HtmlUtil {
  const HtmlUtil._();

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
        for (dom.Element hiddenInput in hiddenInputs)
          hiddenInput.attributes['name']!: hiddenInput.attributes['value']!
    };
  }

  static String parseHtml(String text) {
    return HtmlUnescape()
        .convert(text)
        .replaceAll('<p>', '\n')
        .replaceAllMapped(
          RegExp(r'\<i\>(.*?)\<\/i\>'),
          (Match match) => '*${match[1]}*',
        )
        .replaceAllMapped(
          RegExp(r'\<pre\>\<code\>(.*?)\<\/code\>\<\/pre\>', dotAll: true),
          (Match match) => match[1]?.trimRight() ?? '',
        )
        .replaceAllMapped(
          RegExp(r'\<a href=\"(.*?)\".*?\>.*?\<\/a\>'),
          (Match match) => match[1] ?? '',
        )
        .replaceAll('\n', '\n\n');
  }
}
