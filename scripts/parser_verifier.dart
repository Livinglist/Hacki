import 'dart:async';

import 'package:args/args.dart';
import 'package:dio/dio.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/repositories/hacker_news_web_repository.dart';
import 'package:html/dom.dart' hide Comment;
import 'package:html/parser.dart';

Future<void> main(List<String> arguments) async {
  final ArgParser parser = ArgParser()
    ..addFlag('github-token', negatable: false, abbr: 't');
  final ArgResults argResults = parser.parse(arguments);
  final String token = argResults.rest.first;
  const String itemBaseUrl = Constants.hackerNewsItemLinkPrefix;
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
    'title': 'Parser error.',
    'body': '',
    'assignees': <String>['livinglist'],
    'milestone': 1,
    'labels': <String>['bug'],
    'headers': <String, String>{'X-GitHub-Api-Version': '2022-11-28'},
  };
  const String athingComtrSelector =
      HackerNewsWebRepository.athingComtrSelector;
  const String commentTextSelector =
      HackerNewsWebRepository.commentTextSelector;
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
        await HackerNewsWebRepository.parseCommentTextHtml(
      cmtTextElement?.innerHtml ?? '',
    );

    if (parsedText != text || true) {
      final Uri url =
          Uri.parse('https://api.github.com/repos/livinglist/hacki/issues');
      await dio.postUri<String>(
        url,
        data: githubIssuePayload,
        options: Options(
          headers: githubHeaders,
        ),
      );
    }
  }
}
