import 'dart:async';

import 'package:args/args.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart' hide Comment;
import 'package:html/parser.dart';
import 'package:html_unescape/html_unescape.dart';

Future<void> main(List<String> arguments) async {
  final ArgParser parser = ArgParser()
    ..addFlag('github-token', negatable: false, abbr: 't');
  final ArgResults argResults = parser.parse(arguments);
  final String token = argResults.rest.first;
  const String itemBaseUrl = 'https://news.ycombinator.com/item?id=';
  print('token has Bearer: ${token.length}');
  const Map<String, String> headers = <String, String>{
    'accept': '*/*',
    'user-agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.1 Mobile/15E148 Safari/604.1',
  };
  final Map<String, String> githubHeaders = <String, String>{
    'Accept': 'application/vnd.github+json',
    'Authorization': 'Bearer $token',
    'X-GitHub-Api-Version': '2022-11-28',
    'Content-Type': 'application/x-www-form-urlencoded',
  };
  const Map<String, dynamic> githubIssuePayload = <String, dynamic>{
    'owner': 'livinglist',
    'repo': 'Hacki',
    'title': 'Found a bug',
    'body': 'I\'m having a problem with this.',
    'assignees': ['livinglist'],
    'milestone': 1,
    'labels': ['bug'],
    'headers': {'X-GitHub-Api-Version': '2022-11-28'}
  };
  const String athingComtrSelector =
      '#hnmain > tbody > tr > td > table > tbody > .athing.comtr';
  const String commentTextSelector =
      '''td > table > tbody > tr > td.default > div.comment > div.commtext''';
  const String commentHeadSelector =
      '''td > table > tbody > tr > td.default > div > span > a''';
  const String commentAgeSelector =
      '''td > table > tbody > tr > td.default > div > span > span.age''';
  const String commentIndentSelector = '''td > table > tbody > tr > td.ind''';
  const String text = '''
What does it say about the world we live in where blogs do more basic journalism than CNN? All that one would have had to do is read the report actually provided.

I don't think I'm being too extreme when I say that, apart from maybe PBS, there is no reputable source of news in America. If you don't believe me, pick a random story, watch it as it gets rewritten a million times through Reuters, then check back on the facts of the story one year later. A news story gets twisted to promote some narrative that will sell papers, and when the facts of the story are finally verified (usually not by the news themselves, but lawyers or courts or whoever), the story is dropped and never reported on again.

Again, if the only thing a reporter had to do was read the report to find the facts of the case to verify what is and isn't true, what the fuck is even the point of a news agency?''';
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
  final String data = response.data ?? '';

  final Document document = parse(data);
  final List<Element> elements = document.querySelectorAll(athingComtrSelector);
  if (elements.isNotEmpty) {
    final Element e = elements.first;
    final Element? cmtTextElement = e.querySelector(commentTextSelector);
    final String parsedText =
        await parseCommentTextHtml(cmtTextElement?.innerHtml ?? '');

    if (parsedText != text || true) {
      final Uri url =
          Uri.parse('https://api.github.com/repos/livinglist/hacki/issues');
      final Response<String> response = await dio.postUri(
        url,
        data: githubIssuePayload,
        options: Options(
          headers: githubHeaders,
        ),
      );
      print('response is ${response.data}');
    }
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
