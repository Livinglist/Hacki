import 'dart:async';

import 'package:args/args.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart' hide Comment;
import 'package:html/parser.dart';
import 'package:html_unescape/html_unescape.dart';

Future<void> main(List<String> arguments) async {
  /// Get the GitHub token from args for so that we can create issues if
  /// anything doesn't go as expected.
  final ArgParser parser = ArgParser()
    ..addFlag('github-token', negatable: false, abbr: 't');
  final ArgResults argResults = parser.parse(arguments);
  final String token = argResults.rest.first;

  /// The expected parser result.
  const String text = '''
What does it say about the world we live in where blogs do more basic journalism than CNN? All that one would have had to do is read the report actually provided.

I don't think I'm being too extreme when I say that, apart from maybe PBS, there is no reputable source of news in America. If you don't believe me, pick a random story, watch it as it gets rewritten a million times through Reuters, then check back on the facts of the story one year later. A news story gets twisted to promote some narrative that will sell papers, and when the facts of the story are finally verified (usually not by the news themselves, but lawyers or courts or whoever), the story is dropped and never reported on again.

Again, if the only thing a reporter had to do was read the report to find the facts of the case to verify what is and isn't true, what the fuck is even the point of a news agency?''';

  /// Get HTML of the thread.
  const String itemBaseUrl = 'https://news.ycombinator.com/item?id=';
  const Map<String, String> headers = <String, String>{
    'accept': '*/*',
    'user-agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1',
  };
  const int itemId = 11536543;
  final Dio dio = Dio();
  final Uri url = Uri.parse('$itemBaseUrl$itemId');
  final Options option = Options(
    headers: headers,
    persistentConnection: true,
  );
  final Response<String> response = await dio.getUri<String>(
    url,
    options: option,
  );

  /// Parse the HTML and select all the comment elements.
  final String data = response.data ?? '';
  final Document document = parse(data);
  const String athingComtrSelector =
      '#hnmain > tbody > tr > td > table > tbody > .athing.comtr';
  final List<Element> elements = document.querySelectorAll(athingComtrSelector);

  /// Verify comment text parser using the first comment element.
  if (elements.isNotEmpty) {
    final Element e = elements.first;
    const String commentTextSelector =
        '''td > table > tbody > tr > td.default > div.comment > div.commtext''';
    final Element? cmtTextElement = e.querySelector(commentTextSelector);
    final String parsedText =
        await parseCommentTextHtml(cmtTextElement?.innerHtml ?? '');

    if (parsedText != text || true) {
      final Uri url =
          Uri.parse('https://api.github.com/repos/livinglist/hacki/issues');
      final Map<String, String> githubHeaders = <String, String>{
        'Authorization': 'Bearer $token',
        'X-GitHub-Api-Version': '2022-11-28',
        'Content-Type': 'application/json',
      };
      final Map<String, dynamic> githubIssuePayload = <String, dynamic>{
        'title': 'Parser check failed.',
        'body': '''
| Expected  | Actual |
| ------------- | ------------- |
| ${text.replaceAll('\n', '<br>')} | ${parsedText.replaceAll('\n', '<br>')} |''',
      };
      await dio.postUri<String>(
        url,
        data: githubIssuePayload,
        options: Options(
          headers: githubHeaders,
        ),
      );
    }
  } else {
    throw Exception('No comment from Hacker News.');
  }
}

Future<String> parseCommentTextHtml(String text) async {
  return HtmlUnescape()
      .convert(text)
      .replaceAllMapped(
        RegExp(
          r'\<div class="reply"\>(.*?)\<\/div\>',
          dotAll: true,
        ),
        (Match match) => '',
      )
      .replaceAllMapped(
        RegExp(
          r'\<span class="(.*?)"\>(.*?)\<\/span\>',
          dotAll: true,
        ),
        (Match match) => '${match[2]}',
      )
      .replaceAllMapped(
        RegExp(
          r'\<p\>(.*?)\<\/p\>',
          dotAll: true,
        ),
        (Match match) => '\n\n${match[1]}',
      )
      .replaceAllMapped(
        RegExp(r'\<a href=\"(.*?)\".*?\>.*?\<\/a\>'),
        (Match match) => match[1] ?? '',
      )
      .replaceAllMapped(
        RegExp(r'\<i\>(.*?)\<\/i\>'),
        (Match match) => '*${match[1]}*',
      )
      .trim();
}
