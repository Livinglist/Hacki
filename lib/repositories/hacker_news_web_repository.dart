import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:hacki/config/constants.dart';
import 'package:hacki/models/models.dart';
import 'package:html/dom.dart' hide Comment;
import 'package:html/parser.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart';

/// For fetching anything that cannot be fetched through Hacker News API.
class HackerNewsWebRepository {
  HackerNewsWebRepository();

  static const Map<String, String> _headers = <String, String>{
    'Accept':
        'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Accept-Encoding': 'gzip, deflate, br',
    'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8,zh-TW;q=0.7',
    'Cache-Control': 'max-age=0',
    'Connection': 'keep-alive',
    'Host': 'news.ycombinator.com',
    'Referer': 'https://news.ycombinator.com/',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'same-origin',
    'Sec-Fetch-User': '?1',
    'Upgrade-Insecure-Requests': '1',
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36',
    'sec-ch-ua':
        ''''"Google Chrome";v="119", "Chromium";v="119", "Not?A_Brand";v="24"''',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': 'macOS',
    'X-Originating-IP': '127.0.0.1',
    'X-Forwarded-For': '127.0.0.1',
    'X-Remote-IP': '127.0.0.1',
    'X-Remote-Addr': '127.0.0.1',
  };

  static const String _favoritesBaseUrl =
      'https://news.ycombinator.com/favorites?id=';
  static const String _aThingSelector =
      '#hnmain > tbody > tr:nth-child(3) > td > table > tbody > .athing';

  Future<Iterable<int>> fetchFavorites({required String of}) async {
    final String username = of;
    final List<int> allIds = <int>[];
    int page = 1;

    Future<Iterable<int>> fetchIds(int page, {bool isComment = false}) async {
      final Uri url = Uri.parse(
        '''$_favoritesBaseUrl$username${isComment ? '&comments=t' : ''}&p=$page''',
      );
      final Response response = await get(url, headers: _headers);

      if (response.statusCode == HttpStatus.forbidden) {
        throw RateLimitedException();
      }

      /// Due to rate limiting, we have a short break here.
      await Future<void>.delayed(AppDurations.oneSecond);

      final Document document = parse(response.body);
      final List<Element> elements = document.querySelectorAll(_aThingSelector);
      final Iterable<int> parsedIds = elements
          .map(
            (Element e) => int.tryParse(e.id),
          )
          .whereNotNull();
      return parsedIds;
    }

    Iterable<int> ids;
    while (true) {
      ids = await fetchIds(page);
      if (ids.isEmpty) {
        break;
      }
      allIds.addAll(ids);
      page++;
    }

    page = 1;
    while (true) {
      ids = await fetchIds(page, isComment: true);
      if (ids.isEmpty) {
        break;
      }
      allIds.addAll(ids);
      page++;
    }

    return allIds;
  }

  static const String _itemBaseUrl = 'https://news.ycombinator.com/item?id=';
  static const String _athingComtrSelector =
      '#hnmain > tbody > tr:nth-child(3) > td > table > tbody > .athing.comtr';
  static const String _commentTextSelector =
      '''td > table > tbody > tr > td.default > div.comment''';
  static const String _commentHeadSelector =
      '''td > table > tbody > tr > td.default > div > span > a''';
  static const String _commentAgeSelector =
      '''td > table > tbody > tr > td.default > div > span > span.age''';
  static const String _commentIndentSelector =
      '''td > table > tbody > tr > td.ind''';

  Stream<Comment> fetchCommentsStream(int itemId) async* {
    Future<Iterable<Element>> fetchElements(int page) async {
      final Uri url = Uri.parse('$_itemBaseUrl$itemId&p=$page');
      final Response response = await get(url, headers: _headers);

      if (response.statusCode == HttpStatus.forbidden) {
        throw RateLimitedException();
      }

      final Document document = parse(response.body);
      final List<Element> elements =
          document.querySelectorAll(_athingComtrSelector);
      return elements;
    }

    int page = 1;
    Iterable<Element> elements = await fetchElements(page);
    final Map<int, int> indentToParentId = <int, int>{};

    while (elements.isNotEmpty) {
      for (final Element element in elements) {
        /// Get comment id.
        final String cmtIdString = element.attributes['id'] ?? '';
        final int? cmtId = int.tryParse(cmtIdString);

        /// Get comment text.
        final Element? cmtTextElement =
            element.querySelector(_commentTextSelector);
        final String parsedText = await compute(
          _parseCommentTextHtml,
          cmtTextElement?.innerHtml ?? '',
        );

        /// Get comment author.
        final Element? cmtHeadElement =
            element.querySelector(_commentHeadSelector);
        final String? cmtAuthor = cmtHeadElement?.text;

        /// Get comment age.
        final Element? cmtAgeElement =
            element.querySelector(_commentAgeSelector);
        final String? ageString = cmtAgeElement?.attributes['title'];

        final int? timestamp = ageString == null
            ? null
            : DateTime.parse(ageString)
                .copyWith(isUtc: true)
                .millisecondsSinceEpoch;

        /// Get comment indent.
        final Element? cmtIndentElement =
            element.querySelector(_commentIndentSelector);
        final String? indentString = cmtIndentElement?.attributes['indent'];
        final int indent =
            indentString == null ? 0 : (int.tryParse(indentString) ?? 0);

        indentToParentId[indent] = cmtId ?? 0;
        final int parentId = indentToParentId[indent - 1] ?? -1;

        final Comment cmt = Comment(
          id: cmtId ?? 0,
          time: timestamp ?? 0,
          parent: parentId,
          score: 0,
          by: cmtAuthor ?? '',
          text: parsedText,
          kids: const <int>[],
          dead: false,
          deleted: false,
          hidden: false,
          level: indent,
          isFromCache: false,
        );

        yield cmt;
      }

      /// Due to rate limiting, we have a short break here.
      await Future<void>.delayed(AppDurations.oneSecond);

      page++;
      elements = await fetchElements(page);
    }
  }

  static Future<String> _parseCommentTextHtml(String text) async {
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
}
